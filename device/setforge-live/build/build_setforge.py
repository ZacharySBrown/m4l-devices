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

# Harness tools must be on PYTHONPATH
try:
    from stemforge_bridge import patcher as P, amxd_pack
    from forge_device import verifiers
except ImportError:
    print("ERROR: stemforge_bridge not found. Set PYTHONPATH to include harness tools dir.")
    print("  PYTHONPATH=~/raindog/harness/quickstarts/max-plugin/tools python3 build/build_setforge.py")
    sys.exit(1)

DEVICE_DIR = Path(__file__).parent.parent
SRC_DIR = DEVICE_DIR / "src"
OUT_DIR = DEVICE_DIR


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
        presentation_rect=(500, 10, 80, 20),
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

    # opendialog → prepend "load" → js
    boxes.append(P.newobj(
        "prepend-load", "prepend load",
        rect=(500, 190, 100, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("opendialog", 0, "prepend-load", 0))
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
        presentation_rect=(70, 10, 200, 20),
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
            presentation_rect=(280 + i * 70, 10, 60, 20),
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
        ("status-bankA", "bank A: —", (10, 35, 400, 16)),
        ("status-bankB", "bank B: —", (10, 50, 400, 16)),
        ("status-active", "active preset: —", (10, 65, 400, 16)),
        ("status-scene", "active scene: —", (10, 80, 400, 16)),
        ("status-tempo", "tempo: — bpm", (10, 95, 400, 16)),
    ]
    y_patch = 300
    for sid, text, prect in status_labels:
        boxes.append(P.live_comment(
            sid, rect=(20, y_patch, prect[2], 18),
            text=text,
            presentation_rect=prect,
            fontsize=10.0,
        ))
        y_patch += 25

    # Master bypass toggle
    boxes.append(P.live_toggle(
        "toggle-master", rect=(20, 500, 30, 25),
        parameter_name="master_bypass",
        initial=0,
        presentation_rect=(10, 115, 80, 20),
    ))
    lines.append(P.line("toggle-master", 0, "js-loader", 2))

    # Panic button
    boxes.append(P.box(
        "btn-panic", "live.text",
        rect=(150, 500, 80, 25),
        presentation=True,
        presentation_rect=(700, 115, 80, 20),
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
        presentation_rect=(400, 115, 200, 18),
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
    p["patcher"]["devicewidth"] = 400.0

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
        text="setforge-grid — MIDI bridge to Launchpad",
        presentation_rect=(10, 10, 380, 18),
        fontsize=10.0,
    ))
    boxes.append(P.live_comment(
        "status-grid", rect=(20, 185, 300, 18),
        text="Set track I/O to Launchpad Standalone Port",
        presentation_rect=(10, 28, 380, 16),
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
    p["patcher"]["devicewidth"] = 700.0

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
        presentation_rect=(70, 10, 250, 20),
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
            presentation_rect=(330 + i * 80, 10, 70, 20),
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
        presentation_rect=(10, 40, 300, 25),
    ))
    lines.append(P.line("tab-stem", 0, "js-calibrate", 0))

    # Status displays
    cal_labels = [
        ("cal-downbeat", "calibrated downbeat: — sec", (10, 75, 400, 18)),
        ("cal-marker", "current marker: — sec", (10, 93, 400, 18)),
        ("cal-setstate", "set state: — validated", (10, 155, 600, 18)),
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
            presentation_rect=(10 + i * 100, 120, 90, 22),
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
        presentation_rect=(10, 180, 300, 22),
        fontsize=14.0,
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
    "loader-controller.js",
]


def concat_loader_js():
    """Concatenate src/loader/ modules into a single device-root loader.js.

    All source files are ES5 (Max SpiderMonkey). No require/exports stripping
    needed — files are written concat-ready.
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
            print(f"  ERROR: {filepath} not found")
            return None
        content = filepath.read_text(encoding="utf-8")
        parts.append(content)
        parts.append("")  # blank line between files

    out_path = OUT_DIR / "loader.js"
    out_text = "\n".join(parts)
    out_path.write_text(out_text, encoding="utf-8")

    import hashlib
    sha = hashlib.sha256(out_path.read_bytes()).hexdigest()
    size = out_path.stat().st_size
    print(f"  Concatenated {len(LOADER_CONCAT_ORDER)} files → loader.js ({size} bytes, sha256={sha[:12]}...)")
    return out_path


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

    # ── Concatenate loader.js from src/loader/ modules ──
    print("\n▸ Concatenating loader.js...")
    loader_js = concat_loader_js()
    js_ok = loader_js is not None

    # Check calibrate.js (still maintained directly, not concat'd)
    print("\n▸ JS controllers...")
    cal_js = OUT_DIR / "calibrate.js"
    if cal_js.exists():
        print(f"  calibrate.js exists ({cal_js.stat().st_size} bytes)")
    else:
        print(f"  WARNING: calibrate.js not found at {cal_js}")

    print("\n" + "=" * 60)
    if loader_ok and grid_ok and cal_ok and js_ok:
        print("  BUILD COMPLETE — all verifiers passed")
    else:
        print("  BUILD COMPLETE WITH WARNINGS — check verifier output")
    print("=" * 60)


if __name__ == "__main__":
    main()
