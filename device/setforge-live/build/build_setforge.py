#!/usr/bin/env python3
"""
Build script for setforge-live device family.

Generates .maxpat and .amxd files for:
  - setforge-loader.amxd  (performance device)
  - setforge-calibrate.amxd (validation device)

Uses stemforge_bridge.patcher primitives + amxd_pack.
Run with: PYTHONPATH=$HARNESS_TOOLS python3 build/build_setforge.py
"""

import sys
import json
from pathlib import Path

# Resolve bundled tools (repo-local tools/ dir) so no external PYTHONPATH is needed.
# Falls back to PYTHONPATH for backwards compat with the harness workflow.
_TOOLS_DIR = str(Path(__file__).resolve().parent.parent.parent.parent / "tools")
if _TOOLS_DIR not in sys.path:
    sys.path.insert(0, _TOOLS_DIR)

try:
    from stemforge_bridge import patcher as P, amxd_pack
    from forge_device import verifiers
except ImportError:
    print("ERROR: stemforge_bridge not found.")
    print("  Expected at: " + _TOOLS_DIR)
    print("  Or set PYTHONPATH to include harness tools dir.")
    sys.exit(1)

DEVICE_DIR = Path(__file__).parent.parent
SRC_DIR = DEVICE_DIR / "src"
OUT_DIR = DEVICE_DIR

# Max Package deploy targets — JS modules are resolved by Max via package search
# path (pitfall #16: only [js] searches Max Package paths). Build writes loader.js
# and calibrate.js to whichever of these exist. No more manual cp to Max Library/.
HOME = Path.home()
MAX_PACKAGE_TARGETS = [
    HOME / "Documents" / "Max 8" / "Packages" / "setforge-live" / "javascript",
    HOME / "Documents" / "Max 9" / "Packages" / "setforge-live" / "javascript",
]


# ─────────────────────────────────────────────────────────────
#  Loader device — setforge-loader.amxd
# ─────────────────────────────────────────────────────────────

def build_loader():
    """Build the performance loader device (audio effect).

    MIDI I/O is handled by the companion setforge-grid.amxd (MIDI effect)
    on a separate MIDI track. Communication is via send~/receive~ named buses:
      sf-grid-in   : grid → loader (pad presses from Launchpad)
      sf-grid-out  : loader → grid (LED updates, SysEx to Launchpad)
    """
    p = P.empty_patcher(width=800, height=400, is_root=True)
    p["patcher"]["project"]["name"] = "setforge-loader"
    # loader.js is resolved via Max Package search path
    # (~/Documents/Max N/Packages/setforge-live/javascript/loader.js).
    # Do NOT register as project-local — that forces Max to look only inside
    # the .amxd project dir, where loader.js isn't embedded.
    p["patcher"]["openinpresentation"] = 1
    p["patcher"]["devicewidth"] = 800.0

    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    # ── Audio I/O ──
    boxes.append(P.plugin_in("plugin-in", rect=(20, 20, 80, 22)))
    boxes.append(P.plugin_out("plugout", rect=(20, 900, 80, 22)))

    # Pass audio through (loader is a routing device, not DSP)
    lines.append(P.line("plugin-in", 0, "plugout", 0))
    lines.append(P.line("plugin-in", 1, "plugout", 1))

    # ── JS Controller ──
    boxes.append(P.js_box(
        "js-loader", "loader.js",
        rect=(150, 60, 300, 22),
        scripting_name="loader",
        numinlets=3,   # MIDI grid1, MIDI grid2, messages
        numoutlets=4,  # MIDI grid1, MIDI grid2, LiveAPI commands, status
        outlettype=["", "", "", ""],
    ))

    # ── MIDI bridge via send/receive (to/from setforge-grid.amxd) ──
    # Receive pad presses from grid device → JS inlets 0 and 1
    boxes.append(P.newobj(
        "recv-grid-in", "receive sf-grid-in",
        rect=(150, 20, 150, 22),
        numinlets=0, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("recv-grid-in", 0, "js-loader", 0))

    # Send LED/SysEx from JS outlets 0 and 1 → grid device
    boxes.append(P.newobj(
        "send-grid-out", "send sf-grid-out",
        rect=(150, 120, 150, 22),
        numinlets=1, numoutlets=0,
    ))
    lines.append(P.line("js-loader", 0, "send-grid-out", 0))
    # In single-grid mode outlet 1 also goes to the same send
    lines.append(P.line("js-loader", 1, "send-grid-out", 0))

    # ── live.thisdevice → bang (signals device is ready for LiveAPI) ──
    boxes.append(P.newobj(
        "thisdevice", "live.thisdevice",
        rect=(150, 160, 100, 22),
        numinlets=1, numoutlets=3, outlettype=["", "", ""],
    ))
    # live.thisdevice outlet 0 bangs when device is initialized
    lines.append(P.line("thisdevice", 0, "js-loader", 2))

    # ── Loadbang → init message (for state setup before LiveAPI) ──
    boxes.append(P.newobj(
        "loadbang", "loadbang",
        rect=(300, 160, 60, 22),
        numinlets=1, numoutlets=1, outlettype=["bang"],
    ))
    boxes.append(P.box(
        "msg-init", "message",
        rect=(300, 190, 60, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "init"},
    ))
    lines.append(P.line("loadbang", 0, "msg-init", 0))
    lines.append(P.line("msg-init", 0, "js-loader", 2))

    # ── UDP command receiver (for automated testing + remote control) ──
    # udpreceive outputs ASCII ints → msg_int on JS inlet 2 collects them
    # into a command string via the udpBuffer mechanism in loader-controller.js
    boxes.append(P.newobj(
        "udp-recv", "udpreceive 7422 0",
        rect=(450, 60, 140, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("udp-recv", 0, "js-loader", 2))

    # ── File browser for set loading ──
    boxes.append(P.newobj(
        "opendialog", "opendialog JSON",
        rect=(500, 160, 120, 22),
        numinlets=1, numoutlets=2, outlettype=["", "bang"],
    ))
    # Button to trigger file dialog
    boxes.append(P.box(
        "btn-browse", "live.text",
        rect=(500, 130, 120, 22),
        presentation=True,
        presentation_rect=(450, 8, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "browse",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "browse",
                    "parameter_shortname": "browse",
                    "parameter_type": 1,
                }
            },
            "text": "browse...",
            "texton": "browse...",
            "textoff": "browse...",
            "mode": 0,
        },
    ))
    lines.append(P.line("btn-browse", 0, "opendialog", 0))

    # opendialog → HFS→POSIX regexp → prepend "load" → js
    # Pitfall #8: opendialog emits HFS paths ("Macintosh HD:/Users/..."), but
    # File() in JS needs POSIX. The regexp strips everything up to the colon.
    boxes.append(P.newobj(
        "regexp-posix", "regexp (.+):(/.*) @substitute %2",
        rect=(500, 220, 240, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
    ))
    boxes.append(P.newobj(
        "prepend-load", "prepend load",
        rect=(500, 250, 100, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("opendialog", 0, "regexp-posix", 0))
    lines.append(P.line("regexp-posix", 0, "prepend-load", 0))
    lines.append(P.line("prepend-load", 0, "js-loader", 2))

    # ── Test fixture loader (click to test without Launchpads) ──
    fixture_path = str(DEVICE_DIR / "tests" / "fixtures" / "manifests" / "hiphop_v3.set.json")
    boxes.append(P.box(
        "msg-test-load", "message",
        rect=(650, 190, 600, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": f"load {fixture_path}"},
    ))
    lines.append(P.line("msg-test-load", 0, "js-loader", 2))

    boxes.append(P.box(
        "msg-test-panic", "message",
        rect=(650, 220, 80, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "panic"},
    ))
    lines.append(P.line("msg-test-panic", 0, "js-loader", 2))

    boxes.append(P.box(
        "msg-test-eject", "message",
        rect=(750, 220, 80, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "eject"},
    ))
    lines.append(P.line("msg-test-eject", 0, "js-loader", 2))

    # ── Presentation UI (front panel per spec §2.1) ──

    # Set chooser (umenu)
    boxes.append(P.box(
        "umenu-set", "live.menu",
        rect=(20, 250, 200, 22),
        presentation=True,
        presentation_rect=(8, 8, 200, 22),
        numinlets=1, numoutlets=3, outlettype=["", "", "float"],
        extras={
            "varname": "set_chooser",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "set_chooser",
                    "parameter_shortname": "set",
                    "parameter_type": 2,
                    "parameter_enum": ["(no set loaded)"],
                    "parameter_initial_enable": 1,
                    "parameter_initial": [0],
                }
            },
        },
    ))
    lines.append(P.line("umenu-set", 0, "js-loader", 2))

    # Load / reload / eject buttons
    for i, (name, label) in enumerate([("load", "load"), ("reload", "reload"), ("eject", "eject")]):
        boxes.append(P.box(
            f"btn-{name}", "live.text",
            rect=(280 + i * 70, 250, 60, 20),
            presentation=True,
            presentation_rect=(216 + i * 78, 8, 70, 22),
            numinlets=1, numoutlets=2, outlettype=["", ""],
            extras={
                "varname": name,
                "saved_attribute_attributes": {
                    "valueof": {
                        "parameter_longname": name,
                        "parameter_shortname": label,
                        "parameter_type": 1,
                        "parameter_enum": [label],
                    }
                },
                "text": label,
                "texton": label,
                "textoff": label,
                "mode": 0,
            },
        ))
        lines.append(P.line(f"btn-{name}", 0, "js-loader", 2))

    # Status display (live.comment for dynamic text — pitfall #3)
    # Left column: set state. Right column: MIDI port selectors.
    # M4L strip height is ~170px, so everything must fit.
    status_labels = [
        ("status-bankA", "bank A: —", (8, 38, 380, 14)),
        ("status-bankB", "bank B: —", (8, 54, 380, 14)),
        ("status-active", "active preset: —", (8, 70, 380, 14)),
        ("status-scene", "active scene: —", (8, 86, 380, 14)),
        ("status-tempo", "tempo: — bpm", (8, 102, 380, 14)),
    ]
    y_patch = 300
    for sid, text, prect in status_labels:
        boxes.append(P.live_comment(
            sid, rect=(20, y_patch, prect[2], 18),
            text=text,
            presentation_rect=prect,
            fontsize=9.0,
        ))
        y_patch += 25

    # Master bypass toggle
    boxes.append(P.live_toggle(
        "toggle-master", rect=(20, 500, 30, 25),
        parameter_name="master_bypass",
        initial=0,
        presentation_rect=(8, 120, 70, 22),
    ))
    lines.append(P.line("toggle-master", 0, "js-loader", 2))

    # Panic button
    boxes.append(P.box(
        "btn-panic", "live.text",
        rect=(150, 500, 80, 25),
        presentation=True,
        presentation_rect=(694, 120, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "panic",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "panic",
                    "parameter_shortname": "PANIC",
                    "parameter_type": 1,
                }
            },
            "text": "PANIC",
            "texton": "PANIC",
            "textoff": "PANIC",
            "mode": 0,
        },
    ))
    lines.append(P.line("btn-panic", 0, "js-loader", 2))

    # FX target display (read-only live.comment)
    boxes.append(P.live_comment(
        "status-fxtarget", rect=(250, 500, 200, 18),
        text="fx target: all",
        presentation_rect=(300, 122, 200, 14),
        fontsize=9.0,
    ))

    # ── Curation UI: per-preset activator buttons + SAVE ──
    # Lets the user activate any preset + save without the Launchpad
    # attached. Buttons are arranged as two rows of 8 (A1-A8, B1-B8)
    # mirroring the Launchpad bank layout, plus a SAVE button.
    # Each button → message box ("activate_preset N") → js inlet 2.
    # Goes through onPresetPress, the same code path as a pad press.
    curation_y_patch_base = 560
    preset_x_positions = [400, 444, 488, 532, 576, 620, 664, 708]
    for bank_idx, bank_label in enumerate(["A", "B"]):
        y_pres = 38 + bank_idx * 22    # presentation: y=38 (A), y=60 (B)
        y_patch = curation_y_patch_base + bank_idx * 50
        for col in range(8):
            slot_idx = bank_idx * 8 + col
            label = f"{bank_label}{col + 1}"
            btn_name = f"btn-preset-{slot_idx}"
            msg_name = f"msg-preset-{slot_idx}"
            x_pres = preset_x_positions[col]
            x_patch = 100 + col * 90
            boxes.append(P.box(
                btn_name, "live.text",
                rect=(x_patch, y_patch, 32, 18),
                presentation=True,
                presentation_rect=(x_pres, y_pres, 40, 18),
                numinlets=1, numoutlets=2, outlettype=["", ""],
                extras={
                    "varname": f"preset_{bank_label}{col + 1}",
                    "saved_attribute_attributes": {
                        "valueof": {
                            "parameter_longname": f"preset_{bank_label}{col + 1}",
                            "parameter_shortname": label,
                            "parameter_type": 1,
                            "parameter_enum": [label],
                        }
                    },
                    "text": label,
                    "texton": label,
                    "textoff": label,
                    "mode": 0,
                    "fontsize": 9.0,
                },
            ))
            boxes.append(P.box(
                msg_name, "message",
                rect=(x_patch, y_patch + 22, 140, 20),
                numinlets=2, numoutlets=1, outlettype=[""],
                extras={"text": f"activate_preset {slot_idx}"},
            ))
            lines.append(P.line(btn_name, 0, msg_name, 0))
            lines.append(P.line(msg_name, 0, "js-loader", 2))

    # SAVE button — next to PANIC in the bottom row
    boxes.append(P.box(
        "btn-save", "live.text",
        rect=(150, 660, 80, 25),
        presentation=True,
        presentation_rect=(616, 120, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "save",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "save",
                    "parameter_shortname": "SAVE",
                    "parameter_type": 1,
                    "parameter_enum": ["save"],
                }
            },
            "text": "SAVE",
            "texton": "SAVE",
            "textoff": "SAVE",
            "mode": 0,
        },
    ))
    boxes.append(P.box(
        "msg-save", "message",
        rect=(150, 690, 80, 20),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "save"},
    ))
    lines.append(P.line("btn-save", 0, "msg-save", 0))
    lines.append(P.line("msg-save", 0, "js-loader", 2))

    return p


# ─────────────────────────────────────────────────────────────
#  Standalone debug harness — setforge-loader-debug.maxpat
#  (Phase B: iterate on dispatcher/JS logic without launching Live)
# ─────────────────────────────────────────────────────────────

def build_debug_harness():
    """Standalone .maxpat that drives loader.js outside of Live.

    Lets us verify routing/dispatch (handleNoteOn, handleMessage) and watch
    JS outlets via [print] without the 10-minute Live reload cycle. Per the
    stemforge m4l_device_development_guide.md §8: "NEVER debug in Ableton."

    Open with: open setforge-loader-debug.maxpat
    """
    p = P.empty_patcher(width=1100, height=700, is_root=True)
    p["patcher"]["project"]["name"] = "setforge-loader-debug"
    p["patcher"]["openinpresentation"] = 0  # patching view for debugging

    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    # ── JS controller under test ──
    boxes.append(P.js_box(
        "js-loader", "loader.js",
        rect=(400, 240, 320, 22),
        scripting_name="loader",
        numinlets=3,
        numoutlets=4,
        outlettype=["", "", "", ""],
    ))

    # ── Print taps on every outlet (visible in Max Console) ──
    outlet_labels = [
        ("print-grid1-out", "SF-GRID1-OUT"),
        ("print-grid2-out", "SF-GRID2-OUT"),
        ("print-liveapi",   "SF-LIVEAPI"),
        ("print-status",    "SF-STATUS"),
    ]
    for i, (vname, label) in enumerate(outlet_labels):
        boxes.append(P.newobj(
            vname, "print " + label,
            rect=(400 + i * 170, 320, 150, 22),
            numinlets=1, numoutlets=0,
        ))
        lines.append(P.line("js-loader", i, vname, 0))

    # ── Loadbang → init (mirror the real device) ──
    boxes.append(P.newobj(
        "loadbang", "loadbang",
        rect=(20, 20, 60, 22),
        numinlets=1, numoutlets=1, outlettype=["bang"],
    ))
    boxes.append(P.box(
        "msg-init", "message",
        rect=(20, 50, 60, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "init"},
    ))
    lines.append(P.line("loadbang", 0, "msg-init", 0))
    lines.append(P.line("msg-init", 0, "js-loader", 2))

    # ── Message palette: common commands → JS inlet 2 ──
    fixture_path = str(DEVICE_DIR / "tests" / "fixtures" / "manifests" / "hiphop_v3.set.json")
    cmd_messages = [
        (f"load {fixture_path}", 90),
        ("reload",               120),
        ("eject",                150),
        ("sync",                 180),
        ("save",                 210),
        ("inspect",              240),
        ("panic",                270),
        ("debug",                300),
        ("save_manifest",        330),
        ("save_set",             360),
    ]
    for text, y in cmd_messages:
        vname = "msg-cmd-" + str(y)
        width = 700 if "load " in text else 200
        boxes.append(P.box(
            vname, "message",
            rect=(20, y, width, 22),
            numinlets=2, numoutlets=1, outlettype=[""],
            extras={"text": text},
        ))
        lines.append(P.line(vname, 0, "js-loader", 2))

    # ── MIDI note-on injection → JS inlet 0 (Grid 1) ──
    # The JS msg_int handler eats raw MIDI bytes one at a time. Use [iter]
    # to split a list into ints. The label tells you which pad it fires.
    # MK2 programmer mode mapping: note = (9 - specRow) * 10 + col
    note_messages = [
        # (label,                       midi list,            y)
        ("row1 col1 note-on (drums)",   "144 81 127",         420),
        ("row1 col1 note-off",          "144 81 0",           450),
        ("row2 col2 note-on (bass)",    "144 72 127",         480),
        ("row5 col1 note-on (preset A)","144 41 127",         510),
        ("row5 col1 note-off",          "144 41 0",           540),
        ("row7 col3 note-on (SOLO)",    "144 23 127",         570),
        ("row7 col3 note-off",          "144 23 0",           600),
    ]
    # iter box — turns the 3-int list into 3 separate ints
    boxes.append(P.newobj(
        "iter-grid1", "iter",
        rect=(420, 600, 60, 22),
        numinlets=1, numoutlets=1, outlettype=["int"],
    ))
    lines.append(P.line("iter-grid1", 0, "js-loader", 0))
    for label, midi, y in note_messages:
        vname = "msg-midi-" + str(y)
        # Comment label
        boxes.append(P.live_comment(
            vname + "-lbl", rect=(180, y, 240, 18),
            text=label, fontsize=10.0,
        ))
        boxes.append(P.box(
            vname, "message",
            rect=(20, y, 160, 22),
            numinlets=2, numoutlets=1, outlettype=[""],
            extras={"text": midi},
        ))
        lines.append(P.line(vname, 0, "iter-grid1", 0))

    # ── Remote-CC injection (Phase C: CC replaces /tmp/setforge_cmd.txt poll) ──
    # Pretend we're the UAT runner sending CCs over IAC.
    cc_messages = [
        # (label,             midi list,        y)
        ("CC100 save",        "176 100 127",    420),
        ("CC101 sync",        "176 101 127",    450),
        ("CC102 inspect",     "176 102 127",    480),
        ("CC103 panic",       "176 103 127",    510),
        ("CC104 eject",       "176 104 127",    540),
    ]
    for label, midi, y in cc_messages:
        vname = "msg-cc-" + str(y)
        boxes.append(P.live_comment(
            vname + "-lbl", rect=(960, y, 140, 18),
            text=label, fontsize=10.0,
        ))
        boxes.append(P.box(
            vname, "message",
            rect=(800, y, 150, 22),
            numinlets=2, numoutlets=1, outlettype=[""],
            extras={"text": midi},
        ))
        lines.append(P.line(vname, 0, "iter-grid1", 0))

    # ── Title comment ──
    boxes.append(P.live_comment(
        "title", rect=(420, 20, 600, 22),
        text="setforge-loader DEBUG HARNESS — Max Console = Window menu",
        fontsize=12.0,
    ))
    boxes.append(P.live_comment(
        "subtitle", rect=(420, 45, 600, 18),
        text="JS loaded from Max Package: ~/Documents/Max N/Packages/setforge-live/javascript/",
        fontsize=10.0,
    ))
    boxes.append(P.live_comment(
        "subtitle2", rect=(420, 65, 600, 18),
        text="LiveAPI calls will fail outside Live — that's expected. Verify dispatch + prints.",
        fontsize=10.0,
    ))
    boxes.append(P.live_comment(
        "subtitle3", rect=(420, 85, 600, 18),
        text="Edit loader-controller.js → rebuild → autowatch reloads → click messages.",
        fontsize=10.0,
    ))

    return p


# ─────────────────────────────────────────────────────────────
#  Grid MIDI bridge — setforge-grid.amxd (MIDI effect)
# ─────────────────────────────────────────────────────────────

def build_grid():
    """Build the MIDI bridge device.

    This is a minimal M4L MIDI Effect placed on a MIDI track whose I/O
    is pointed at the Launchpad. It forwards MIDI between the hardware
    and the loader (audio effect) via send/receive named buses.

    Track setup:
      MIDI From: Launchpad Pro (Standalone Port)
      MIDI To:   Launchpad Pro (Standalone Port)
    """
    p = P.empty_patcher(width=400, height=200, is_root=True)
    p["patcher"]["project"]["name"] = "setforge-grid"
    p["patcher"]["openinpresentation"] = 1
    p["patcher"]["devicewidth"] = 300.0

    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    # ── MIDI I/O (required for M4L MIDI effect) ──
    # midiin receives from the track's MIDI input (Launchpad pads)
    boxes.append(P.newobj(
        "midiin", "midiin",
        rect=(20, 20, 60, 22),
        numinlets=1, numoutlets=1, outlettype=["int"],
    ))
    # midiout sends to the track's MIDI output (Launchpad LEDs/SysEx)
    boxes.append(P.newobj(
        "midiout", "midiout",
        rect=(20, 120, 60, 22),
        numinlets=1, numoutlets=0,
    ))

    # ── Bridge: hardware → loader (pad presses) ──
    # midiin → send sf-grid-in (received by setforge-loader.amxd)
    boxes.append(P.newobj(
        "send-to-loader", "send sf-grid-in",
        rect=(150, 50, 150, 22),
        numinlets=1, numoutlets=0,
    ))
    lines.append(P.line("midiin", 0, "send-to-loader", 0))

    # ── Bridge: loader → hardware (LED updates, SysEx) ──
    # receive sf-grid-out → midiout
    boxes.append(P.newobj(
        "recv-from-loader", "receive sf-grid-out",
        rect=(150, 90, 150, 22),
        numinlets=0, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("recv-from-loader", 0, "midiout", 0))

    # ── Debug: print midiin output to Max console ──
    boxes.append(P.newobj(
        "print-midi-in", "print sf-grid-midiin",
        rect=(20, 50, 140, 22),
        numinlets=1, numoutlets=0,
    ))
    lines.append(P.line("midiin", 0, "print-midi-in", 0))

    # ── Debug: print what receive sends to midiout ──
    boxes.append(P.newobj(
        "print-midi-out", "print sf-grid-to-lp",
        rect=(150, 115, 140, 22),
        numinlets=1, numoutlets=0,
    ))
    lines.append(P.line("recv-from-loader", 0, "print-midi-out", 0))

    # ── Presentation: minimal status display ──
    boxes.append(P.live_comment(
        "title-grid", rect=(20, 160, 300, 22),
        text="setforge-grid",
        presentation_rect=(8, 8, 280, 16),
        fontsize=10.0,
    ))
    boxes.append(P.live_comment(
        "status-grid", rect=(20, 185, 300, 18),
        text="MIDI bridge → Launchpad",
        presentation_rect=(8, 28, 280, 14),
        fontsize=9.0,
    ))

    return p


# ─────────────────────────────────────────────────────────────
#  Calibrator device — setforge-calibrate.amxd
# ─────────────────────────────────────────────────────────────

def build_calibrator():
    """Build the calibration/validation device."""
    p = P.empty_patcher(width=700, height=250, is_root=True)
    p["patcher"]["project"]["name"] = "setforge-calibrate"
    p["patcher"]["openinpresentation"] = 1
    p["patcher"]["devicewidth"] = 600.0

    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    # ── Audio I/O (required for M4L audio effect) ──
    boxes.append(P.plugin_in("plugin-in", rect=(20, 20, 80, 22)))
    boxes.append(P.plugin_out("plugout", rect=(20, 700, 80, 22)))

    # Pass-through (calibrator is not a DSP device)
    lines.append(P.line("plugin-in", 0, "plugout", 0))
    lines.append(P.line("plugin-in", 1, "plugout", 1))

    # ── JS Controller ──
    boxes.append(P.js_box(
        "js-calibrate", "calibrate.js",
        rect=(150, 60, 300, 22),
        scripting_name="calibrate",
        numinlets=2,   # messages, warp-marker observer
        numoutlets=3,  # LiveAPI commands, status, file writes
        outlettype=["", "", ""],
    ))

    # ── live.thisdevice → bang (signals device ready) ──
    boxes.append(P.newobj(
        "thisdevice-cal", "live.thisdevice",
        rect=(150, 100, 100, 22),
        numinlets=1, numoutlets=3, outlettype=["", "", ""],
    ))
    lines.append(P.line("thisdevice-cal", 0, "js-calibrate", 0))

    # ── Loadbang → init ──
    boxes.append(P.newobj(
        "loadbang-cal", "loadbang",
        rect=(300, 100, 60, 22),
        numinlets=1, numoutlets=1, outlettype=["bang"],
    ))
    boxes.append(P.box(
        "msg-init-cal", "message",
        rect=(300, 130, 60, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "init"},
    ))
    lines.append(P.line("loadbang-cal", 0, "msg-init-cal", 0))
    lines.append(P.line("msg-init-cal", 0, "js-calibrate", 0))

    # ── Presentation UI (front panel per spec §4.1) ──

    # Track chooser
    boxes.append(P.box(
        "umenu-track", "live.menu",
        rect=(20, 200, 250, 22),
        presentation=True,
        presentation_rect=(8, 8, 200, 22),
        numinlets=1, numoutlets=3, outlettype=["", "", "float"],
        extras={
            "varname": "track_chooser",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "track_chooser",
                    "parameter_shortname": "track",
                    "parameter_type": 2,
                    "parameter_enum": ["(no track)"],
                    "parameter_initial_enable": 1,
                    "parameter_initial": [0],
                }
            },
        },
    ))
    lines.append(P.line("umenu-track", 0, "js-calibrate", 0))

    # Load + Next buttons
    for i, (name, label) in enumerate([("load-cal", "load"), ("next-cal", "next")]):
        boxes.append(P.box(
            f"btn-{name}", "live.text",
            rect=(330 + i * 80, 200, 70, 20),
            presentation=True,
            presentation_rect=(216 + i * 78, 8, 70, 22),
            numinlets=1, numoutlets=2, outlettype=["", ""],
            extras={
                "varname": name,
                "saved_attribute_attributes": {
                    "valueof": {
                        "parameter_longname": name,
                        "parameter_shortname": label,
                        "parameter_type": 1,
                    }
                },
                "text": label,
                "texton": label,
                "textoff": label,
                "mode": 0,
            },
        ))
        lines.append(P.line(f"btn-{name}", 0, "js-calibrate", 0))

    # Stem selector (radio buttons)
    boxes.append(P.live_tab(
        "tab-stem", rect=(20, 240, 300, 25),
        parameter_name="stem_select",
        items=["drums", "bass", "other", "vox"],
        initial=0,
        presentation_rect=(8, 38, 280, 24),
    ))
    lines.append(P.line("tab-stem", 0, "js-calibrate", 0))

    # Status displays
    cal_labels = [
        ("cal-downbeat", "calibrated downbeat: — sec", (8, 70, 400, 14)),
        ("cal-marker", "current marker: — sec", (8, 86, 400, 14)),
        ("cal-setstate", "set state: — validated", (8, 102, 580, 14)),
    ]
    y_patch = 280
    for sid, text, prect in cal_labels:
        boxes.append(P.live_comment(
            sid, rect=(20, y_patch, prect[2], 18),
            text=text,
            presentation_rect=prect,
            fontsize=10.0,
        ))
        y_patch += 25

    # Action buttons: audition, click, validated, revert
    for i, (name, label) in enumerate([
        ("audition", "audition"),
        ("click", "click"),
        ("validated", "validated"),
        ("revert", "revert"),
    ]):
        boxes.append(P.box(
            f"btn-{name}", "live.text",
            rect=(20 + i * 100, 350, 90, 22),
            presentation=True,
            presentation_rect=(8 + i * 78, 120, 70, 22),
            numinlets=1, numoutlets=2, outlettype=["", ""],
            extras={
                "varname": name,
                "saved_attribute_attributes": {
                    "valueof": {
                        "parameter_longname": name,
                        "parameter_shortname": label,
                        "parameter_type": 1,
                    }
                },
                "text": label,
                "texton": label,
                "textoff": label,
                "mode": 0,
            },
        ))
        lines.append(P.line(f"btn-{name}", 0, "js-calibrate", 0))

    # Title
    boxes.append(P.live_comment(
        "title-cal", rect=(20, 400, 300, 22),
        text="setforge-calibrate",
        presentation_rect=(8, 148, 200, 18),
        fontsize=10.0,
    ))

    return p


# ─────────────────────────────────────────────────────────────
#  Arranger device — setforge-arranger.amxd
# ─────────────────────────────────────────────────────────────

def build_arranger():
    """Build the arrangement-view loader device (audio effect).

    Loads prechop_manifest.json into arrangement-view clips with N-bar
    padded regions and re-anchor support. Exports arrangement snapshots
    for the EP-133 song-mode pipeline.
    """
    p = P.empty_patcher(width=400, height=300, is_root=True)
    p["patcher"]["project"]["name"] = "setforge-arranger"
    p["patcher"]["openinpresentation"] = 1
    p["patcher"]["devicewidth"] = 400.0

    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    # ── Audio I/O (required for M4L audio effect) ──
    boxes.append(P.plugin_in("plugin-in", rect=(20, 20, 80, 22)))
    boxes.append(P.plugin_out("plugout", rect=(20, 600, 80, 22)))
    lines.append(P.line("plugin-in", 0, "plugout", 0))
    lines.append(P.line("plugin-in", 1, "plugout", 1))

    # ── JS Controller ──
    # Uses include() at runtime to load the original v0 modules
    # (sf_arrangement_loader.js, sf_arrangement_reader.js, sf_locator_anchor.js)
    # from the Max Package search path.
    boxes.append(P.js_box(
        "js-arranger", "arranger-main.js",
        rect=(150, 60, 200, 22),
        scripting_name="arranger",
        numinlets=1,
        numoutlets=3,
        outlettype=["", "", ""],
    ))

    # ── [shell] for stemforge re-anchor subprocess ──
    boxes.append(P.newobj(
        "shell-arr", "shell",
        rect=(350, 100, 80, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    # JS outlet 1 → shell (re-anchor Python command)
    lines.append(P.line("js-arranger", 1, "shell-arr", 0))

    # ── Route shell output back as anchor events ──
    # Shell stdout comes as NDJSON; route anchor_complete back to JS
    boxes.append(P.newobj(
        "prepend-anchor-complete", "prepend anchor_complete",
        rect=(350, 130, 180, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("shell-arr", 0, "prepend-anchor-complete", 0))
    lines.append(P.line("prepend-anchor-complete", 0, "js-arranger", 0))

    # ── JS outlet 2 → reload manifest (re-anchor complete) ──
    # Routes back to the JS as loadArrangementFromManifest
    boxes.append(P.newobj(
        "prepend-reload", "prepend loadArrangementFromManifest",
        rect=(350, 160, 250, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("js-arranger", 2, "prepend-reload", 0))
    lines.append(P.line("prepend-reload", 0, "js-arranger", 0))

    # ── live.thisdevice → bang (signals device is ready for LiveAPI) ──
    boxes.append(P.newobj(
        "thisdevice-arr", "live.thisdevice",
        rect=(150, 100, 100, 22),
        numinlets=1, numoutlets=3, outlettype=["", "", ""],
    ))
    lines.append(P.line("thisdevice-arr", 0, "js-arranger", 0))

    # ── Loadbang → init ──
    boxes.append(P.newobj(
        "loadbang-arr", "loadbang",
        rect=(300, 100, 60, 22),
        numinlets=1, numoutlets=1, outlettype=["bang"],
    ))
    boxes.append(P.box(
        "msg-init-arr", "message",
        rect=(300, 130, 60, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "init"},
    ))
    lines.append(P.line("loadbang-arr", 0, "msg-init-arr", 0))
    lines.append(P.line("msg-init-arr", 0, "js-arranger", 0))

    # ── UDP command receiver (for remote testing + automation) ──
    boxes.append(P.newobj(
        "udp-recv-arr", "udpreceive 7423 0",
        rect=(350, 60, 140, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("udp-recv-arr", 0, "js-arranger", 0))

    # ── File browser for manifest loading ──
    boxes.append(P.newobj(
        "opendialog-arr", "opendialog JSON",
        rect=(20, 160, 120, 22),
        numinlets=1, numoutlets=2, outlettype=["", "bang"],
    ))
    boxes.append(P.newobj(
        "regexp-posix-arr", "regexp (.+):(/.*) @substitute %2",
        rect=(20, 190, 240, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
    ))
    boxes.append(P.newobj(
        "prepend-load-arr", "prepend load",
        rect=(20, 220, 100, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("opendialog-arr", 0, "regexp-posix-arr", 0))
    lines.append(P.line("regexp-posix-arr", 0, "prepend-load-arr", 0))
    lines.append(P.line("prepend-load-arr", 0, "js-arranger", 0))

    # ── Presentation UI ──

    # Browse button (triggers file dialog)
    boxes.append(P.box(
        "btn-browse-arr", "live.text",
        rect=(20, 130, 80, 22),
        presentation=True,
        presentation_rect=(8, 8, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "arr_browse",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "arr_browse",
                    "parameter_shortname": "browse",
                    "parameter_type": 1,
                }
            },
            "text": "Browse...",
            "texton": "Browse...",
            "textoff": "Browse...",
            "mode": 0,
        },
    ))
    lines.append(P.line("btn-browse-arr", 0, "opendialog-arr", 0))

    # Load button
    boxes.append(P.box(
        "btn-load-arr", "live.text",
        rect=(110, 130, 60, 22),
        presentation=True,
        presentation_rect=(86, 8, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "arr_load",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "arr_load",
                    "parameter_shortname": "load",
                    "parameter_type": 1,
                }
            },
            "text": "Load",
            "texton": "Load",
            "textoff": "Load",
            "mode": 0,
        },
    ))
    boxes.append(P.box(
        "msg-load-arr", "message",
        rect=(110, 155, 60, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "load"},
    ))
    lines.append(P.line("btn-load-arr", 0, "msg-load-arr", 0))
    lines.append(P.line("msg-load-arr", 0, "js-arranger", 0))

    # Export Snapshot button
    boxes.append(P.box(
        "btn-export-arr", "live.text",
        rect=(180, 130, 80, 22),
        presentation=True,
        presentation_rect=(164, 8, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "arr_export",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "arr_export",
                    "parameter_shortname": "export",
                    "parameter_type": 1,
                }
            },
            "text": "Export",
            "texton": "Export",
            "textoff": "Export",
            "mode": 0,
        },
    ))
    boxes.append(P.box(
        "msg-export-arr", "message",
        rect=(180, 155, 80, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "export"},
    ))
    lines.append(P.line("btn-export-arr", 0, "msg-export-arr", 0))
    lines.append(P.line("msg-export-arr", 0, "js-arranger", 0))

    # Re-anchor button
    boxes.append(P.box(
        "btn-reanchor-arr", "live.text",
        rect=(270, 130, 70, 22),
        presentation=True,
        presentation_rect=(242, 8, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "arr_reanchor",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "arr_reanchor",
                    "parameter_shortname": "reanchor",
                    "parameter_type": 1,
                }
            },
            "text": "Re-anchor",
            "texton": "Re-anchor",
            "textoff": "Re-anchor",
            "mode": 0,
        },
    ))

    # Re-anchor message: prepend "reanchor" → js
    boxes.append(P.newobj(
        "prepend-reanchor-arr", "prepend reanchor",
        rect=(270, 160, 120, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("btn-reanchor-arr", 0, "prepend-reanchor-arr", 0))
    lines.append(P.line("prepend-reanchor-arr", 0, "js-arranger", 0))

    # Eject button
    boxes.append(P.box(
        "btn-eject-arr", "live.text",
        rect=(20, 260, 60, 22),
        presentation=True,
        presentation_rect=(8, 96, 70, 22),
        numinlets=1, numoutlets=2, outlettype=["", ""],
        extras={
            "varname": "arr_eject",
            "saved_attribute_attributes": {
                "valueof": {
                    "parameter_longname": "arr_eject",
                    "parameter_shortname": "eject",
                    "parameter_type": 1,
                }
            },
            "text": "Eject",
            "texton": "Eject",
            "textoff": "Eject",
            "mode": 0,
        },
    ))
    boxes.append(P.box(
        "msg-eject-arr", "message",
        rect=(20, 285, 60, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
        extras={"text": "eject"},
    ))
    lines.append(P.line("btn-eject-arr", 0, "msg-eject-arr", 0))
    lines.append(P.line("msg-eject-arr", 0, "js-arranger", 0))

    # ── Status displays ──
    status_labels = [
        ("status-manifest", "manifest: (none)", (8, 38, 380, 14)),
        ("status-bpm", "bpm: --", (8, 54, 380, 14)),
        ("status-clips", "clips: 0", (8, 70, 380, 14)),
    ]
    y_patch = 320
    for sid, text, prect in status_labels:
        boxes.append(P.live_comment(
            sid, rect=(20, y_patch, prect[2], 18),
            text=text,
            presentation_rect=prect,
            fontsize=9.0,
        ))
        y_patch += 25

    # Title
    boxes.append(P.live_comment(
        "title-arr", rect=(20, 400, 300, 22),
        text="setforge-arranger",
        presentation_rect=(8, 148, 200, 14),
        fontsize=9.0,
    ))

    return p


# ─────────────────────────────────────────────────────────────
#  JS concatenation — surface abstraction + controller → loader.js
# ─────────────────────────────────────────────────────────────

# Concat order matters: surface impls first, then dispatcher, then controller.
LOADER_CONCAT_ORDER = [
    "launchpad-surface-mk2.js",
    "launchpad-surface-mk3.js",
    "launchpad-surface.js",
    "punch-layer.js",
    "loader-controller.js",
]


def build_loader_js_text():
    """Pure helper: return the concatenated loader.js text (no file write).

    Single source of truth for the concat so the L0 drift-guard
    (forge_device.check_drift) can reproduce it exactly.
    All source files are ES5 (Max SpiderMonkey); concat-ready, no stripping.
    """
    src_dir = SRC_DIR / "loader"
    parts = []
    parts.append("// setforge-loader.js — AUTO-GENERATED by build_setforge.py")
    parts.append("// Do not edit directly. Edit src/loader/*.js and rebuild.")
    parts.append("//")
    parts.append(f"// Concat order: {', '.join(LOADER_CONCAT_ORDER)}")
    parts.append("")
    for filename in LOADER_CONCAT_ORDER:
        filepath = src_dir / filename
        if not filepath.exists():
            raise FileNotFoundError(filepath)
        parts.append(filepath.read_text(encoding="utf-8"))
        parts.append("")  # blank line between files
    return "\n".join(parts)


def concat_loader_js():
    """Concatenate src/loader/ modules into a single device-root loader.js."""
    try:
        out_text = build_loader_js_text()
    except FileNotFoundError as e:
        print(f"  ERROR: {e} not found")
        return None

    out_path = OUT_DIR / "loader.js"
    out_path.write_text(out_text, encoding="utf-8")

    import hashlib
    sha = hashlib.sha256(out_path.read_bytes()).hexdigest()
    size = out_path.stat().st_size
    print(f"  Concatenated {len(LOADER_CONCAT_ORDER)} files → loader.js ({size} bytes, sha256={sha[:12]}...)")
    return out_path


# ─────────────────────────────────────────────────────────────
#  Arranger JS — copy individual modules (no concat)
# ─────────────────────────────────────────────────────────────
#
# The arranger uses Max's include() to load the v0 modules at runtime,
# so each file must be individually deployed to the Max Package path.
# arranger-main.js is the [js] entry point; the sf_*.js files are
# loaded via include() from the same search path.

ARRANGER_JS_FILES = [
    "arranger-main.js",
    "sf_arrangement_loader.js",
    "sf_arrangement_reader.js",
    "sf_locator_anchor.js",
]


def copy_arranger_js():
    """Copy arranger JS modules to the device root."""
    import shutil
    src_dir = SRC_DIR / "arranger"
    copied = []
    for filename in ARRANGER_JS_FILES:
        src = src_dir / filename
        if not src.exists():
            print(f"  ERROR: {src} not found")
            continue
        dst = OUT_DIR / filename
        shutil.copy2(src, dst)
        copied.append(dst)
        size = dst.stat().st_size
        print(f"  {filename} ({size} bytes)")
    return copied


def deploy_js_to_packages():
    """Copy loader.js, calibrate.js, and arranger.js into Max Package javascript/
    dirs so the Max runtime finds them via the standard package search path.

    Per stemforge memory feedback_js_source_of_truth.md: dual-location sync is
    a known footgun — let the build do it, never hand-copy.
    """
    import shutil
    sources = [OUT_DIR / "loader.js", OUT_DIR / "calibrate.js"]
    # Add all arranger JS modules (main + v0 includes)
    for f in ARRANGER_JS_FILES:
        sources.append(OUT_DIR / f)
    deployed = []
    for target_dir in MAX_PACKAGE_TARGETS:
        if not target_dir.parent.parent.exists():
            # Parent ~/Documents/Max N/ doesn't exist — skip silently
            continue
        target_dir.mkdir(parents=True, exist_ok=True)
        for src in sources:
            if not src.exists():
                continue
            dst = target_dir / src.name
            shutil.copy2(src, dst)
            deployed.append(dst)
    if deployed:
        for d in deployed:
            # Show relative to home for readability
            try:
                rel = d.relative_to(HOME)
                print(f"  → ~/{rel}")
            except ValueError:
                print(f"  → {d}")
    else:
        print("  (no Max Package targets found — install Max or create ~/Documents/Max 8|9/)")
    return deployed


# ─────────────────────────────────────────────────────────────
#  Verify + Pack
# ─────────────────────────────────────────────────────────────

def verify_patcher(name, patcher_dict):
    """Run all patcher verifiers and report."""
    results = verifiers.run_all(patcher_dict, kind="patcher")
    all_pass = True
    for r in results:
        status = "PASS" if r.passed else "FAIL"
        print(f"  [{status}] {r.verifier}: {r.detail}")
        if not r.passed:
            all_pass = False
            if r.fix_hint:
                print(f"         fix: {r.fix_hint}")
    return all_pass


def verify_amxd(path):
    """Run all .amxd verifiers."""
    results = verifiers.run_all(str(path), kind="amxd")
    all_pass = True
    for r in results:
        status = "PASS" if r.passed else "FAIL"
        print(f"  [{status}] {r.verifier}: {r.detail}")
        if not r.passed:
            all_pass = False
    return all_pass


def write_maxpat(path, patcher_dict):
    """Write patcher as .maxpat JSON (Max convention: tab-indented)."""
    text = json.dumps(patcher_dict, indent="\t")
    path.write_text(text, encoding="utf-8")
    import hashlib
    sha = hashlib.sha256(path.read_bytes()).hexdigest()
    size = path.stat().st_size
    return sha, size


def main():
    print("=" * 60)
    print("  setforge-live build")
    print("=" * 60)

    # ── Build loader ──
    print("\n▸ Building setforge-loader...")
    loader_patcher = build_loader()
    print("  Verifying patcher...")
    loader_ok = verify_patcher("setforge-loader", loader_patcher)

    if loader_ok:
        # Write .maxpat
        maxpat_path = OUT_DIR / "setforge-loader.maxpat"
        sha, size = write_maxpat(maxpat_path, loader_patcher)
        print(f"  Wrote {maxpat_path} ({size} bytes, sha256={sha[:12]}...)")

        # Pack .amxd
        amxd_path = OUT_DIR / "setforge-loader.amxd"
        amxd_pack.pack_amxd(loader_patcher, str(amxd_path), device_class="audio")
        print(f"  Packed {amxd_path}")

        # Verify .amxd
        print("  Verifying .amxd...")
        verify_amxd(amxd_path)
    else:
        print("  ✘ Patcher verification failed — skipping pack")

    # ── Build grid MIDI bridge ──
    # Skip patcher verifiers — MIDI effect has no plugin~/plugout~ by design
    print("\n▸ Building setforge-grid (MIDI effect)...")
    grid_patcher = build_grid()
    grid_ok = True

    maxpat_path = OUT_DIR / "setforge-grid.maxpat"
    sha, size = write_maxpat(maxpat_path, grid_patcher)
    print(f"  Wrote {maxpat_path} ({size} bytes, sha256={sha[:12]}...)")

    amxd_path = OUT_DIR / "setforge-grid.amxd"
    amxd_pack.pack_amxd(grid_patcher, str(amxd_path), device_class="midi")
    print(f"  Packed {amxd_path}")

    print("  Verifying .amxd...")
    verify_amxd(amxd_path)

    # ── Build calibrator ──
    print("\n▸ Building setforge-calibrate...")
    cal_patcher = build_calibrator()
    print("  Verifying patcher...")
    cal_ok = verify_patcher("setforge-calibrate", cal_patcher)

    if cal_ok:
        maxpat_path = OUT_DIR / "setforge-calibrate.maxpat"
        sha, size = write_maxpat(maxpat_path, cal_patcher)
        print(f"  Wrote {maxpat_path} ({size} bytes, sha256={sha[:12]}...)")

        amxd_path = OUT_DIR / "setforge-calibrate.amxd"
        amxd_pack.pack_amxd(cal_patcher, str(amxd_path), device_class="audio")
        print(f"  Packed {amxd_path}")

        print("  Verifying .amxd...")
        verify_amxd(amxd_path)
    else:
        print("  ✘ Patcher verification failed — skipping pack")

    # ── Build arranger ──
    print("\n▸ Building setforge-arranger...")
    arr_patcher = build_arranger()
    print("  Verifying patcher...")
    arr_ok = verify_patcher("setforge-arranger", arr_patcher)

    if arr_ok:
        maxpat_path = OUT_DIR / "setforge-arranger.maxpat"
        sha, size = write_maxpat(maxpat_path, arr_patcher)
        print(f"  Wrote {maxpat_path} ({size} bytes, sha256={sha[:12]}...)")

        amxd_path = OUT_DIR / "setforge-arranger.amxd"
        amxd_pack.pack_amxd(arr_patcher, str(amxd_path), device_class="audio")
        print(f"  Packed {amxd_path}")

        print("  Verifying .amxd...")
        verify_amxd(amxd_path)
    else:
        print("  ✘ Patcher verification failed — skipping pack")

    # ── Concatenate loader.js from src/loader/ modules ──
    print("\n▸ Concatenating loader.js...")
    loader_js = concat_loader_js()
    js_ok = loader_js is not None

    # ── Concatenate arranger.js from src/arranger/ modules ──
    print("\n▸ Copying arranger JS modules...")
    arranger_files = copy_arranger_js()
    arr_js_ok = arranger_files is not None

    # Check calibrate.js (still maintained directly, not concat'd)
    print("\n▸ JS controllers...")
    cal_js = OUT_DIR / "calibrate.js"
    if cal_js.exists():
        print(f"  calibrate.js exists ({cal_js.stat().st_size} bytes)")
    else:
        print(f"  WARNING: calibrate.js not found at {cal_js}")

    # ── Build standalone debug harness (.maxpat only, no .amxd pack) ──
    print("\n▸ Building setforge-loader-debug (standalone harness)...")
    dbg_patcher = build_debug_harness()
    dbg_path = OUT_DIR / "setforge-loader-debug.maxpat"
    sha, size = write_maxpat(dbg_path, dbg_patcher)
    print(f"  Wrote {dbg_path} ({size} bytes, sha256={sha[:12]}...)")
    print(f"  Open with: open {dbg_path}")

    # ── Deploy JS to Max Package dirs ──
    print("\n▸ Deploying JS to Max Package(s)...")
    deploy_js_to_packages()

    print("\n" + "=" * 60)
    if loader_ok and grid_ok and cal_ok and arr_ok and js_ok and arr_js_ok:
        print("  BUILD COMPLETE — all verifiers passed")
    else:
        print("  BUILD COMPLETE WITH WARNINGS — check verifier output")
    print("=" * 60)


if __name__ == "__main__":
    main()
