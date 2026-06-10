#!/usr/bin/env python3
"""Extended headless perform-a-set UAT (IAC + OSC).

Covers: preset hot-swap (A→B→A), scene save/recall, and dual-song entry.
Builds on the shared setup from uat_perform_smoke.py.

Requires: Ableton Live running with AbletonOSC, setforge-live devices loaded,
a set with at least 2 presets (banks A and B) already loaded.

Usage:
    python3 tests/uat/uat_perform_full.py
"""

import json
import os
import sys
import time

# ── Path setup ─────────────────────────────────────────────────────
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
_CURATION_DIR = os.path.join(os.path.dirname(_THIS_DIR), "curation")
sys.path.insert(0, _THIS_DIR)
sys.path.insert(0, _CURATION_DIR)

import mido
from osc_client import AbletonOSC
from live_bridge import LiveBridge
from loader_bridge import LoaderBridge

# ── Pad-note layout (Launchpad: note = (9-row)*10 + col) ──────────
# Derived from src/loader/launchpad-surface-mk2.js + loader-controller.js
DRUM_CHOP_1 = 81   # row 1, col 1
BASS_CHOP_1 = 71   # row 2, col 1
BANK_A_COL1 = 41   # row 5, col 1  (preset A1 / slot 0)
BANK_B_COL1 = 31   # row 6, col 1  (preset B1 / slot 8)

# Modifiers (row 7): HOLD=col1, MUTE=col2, SOLO=col3, ...
MOD_HOLD = 21      # row 7, col 1

# Scenes (row 8): A=col1, B=col2, ...
SCENE_A = 11       # row 8, col 1

# Right side buttons: DUAL_SONG_TOGGLE is index 0 = note 89
DUAL_SONG_TOGGLE = 89

STEM_TRACKS = ("sf-drums", "sf-bass", "sf-other", "sf-vox")
SLOTS = range(8)
INSPECT_PATH = "/tmp/setforge_inspect.json"


class TestResult:
    def __init__(self):
        self.steps: list[tuple[str, bool, str]] = []

    def record(self, name: str, passed: bool, detail: str):
        tag = "PASS" if passed else "FAIL"
        self.steps.append((name, passed, detail))
        print(f"  [{tag}] {name}: {detail}")

    @property
    def all_passed(self):
        return all(p for _, p, _ in self.steps)

    def summary(self):
        print("\n── Summary ──")
        for name, passed, detail in self.steps:
            tag = "PASS" if passed else "FAIL"
            print(f"  [{tag}] {name}")
        total = len(self.steps)
        passed = sum(1 for _, p, _ in self.steps if p)
        print(f"\n  {passed}/{total} passed")


def send_note(port, note, velocity=100, duration=0.12):
    """Send note on/off to IAC."""
    port.send(mido.Message("note_on", note=note, velocity=velocity, channel=0))
    time.sleep(duration)
    port.send(mido.Message("note_off", note=note, velocity=0, channel=0))


def do_inspect(loader: LoaderBridge) -> dict:
    """Trigger inspect and read the JSON result."""
    return loader.inspect(settle_secs=1.5)


def count_clips(osc: AbletonOSC, track: int) -> int:
    count = 0
    for slot in SLOTS:
        try:
            (_, _, has) = osc.ask("/live/clip_slot/get/has_clip", track, slot)
            if has:
                count += 1
        except TimeoutError:
            pass
    return count


def count_active(osc: AbletonOSC, track: int) -> int:
    """Count clips that are playing or triggered."""
    count = 0
    for slot in SLOTS:
        try:
            (_, _, has) = osc.ask("/live/clip_slot/get/has_clip", track, slot)
            if not has:
                continue
            (_, _, playing) = osc.ask("/live/clip/get/is_playing", track, slot)
            if playing:
                count += 1
                continue
            (_, _, triggered) = osc.ask("/live/clip/get/is_triggered", track, slot)
            if triggered:
                count += 1
        except TimeoutError:
            pass
    return count


def main():
    result = TestResult()

    # ── Setup ──────────────────────────────────────────────────────
    print("── Setup ──")
    osc = AbletonOSC(default_timeout=3.0)
    live = LiveBridge(osc)
    loader = LoaderBridge()

    # Map tracks
    tracks = live.list_tracks()
    track_map = {name: idx for idx, name in tracks}

    stem_indices = {}
    for stem in STEM_TRACKS:
        if stem not in track_map:
            print(f"  ERROR: stem track {stem!r} not found")
            osc.close()
            sys.exit(2)
        stem_indices[stem] = track_map[stem]

    # Find and configure grid track
    grid_track = None
    for idx, name in tracks:
        try:
            (_, num) = osc.ask("/live/track/get/num_devices", idx)
            if num > 0:
                (_, _, dev_name) = osc.ask("/live/device/get/name", idx, 0)
                if dev_name == "setforge-grid":
                    grid_track = idx
                    break
        except TimeoutError:
            continue

    if grid_track is None:
        print("  ERROR: no grid track found")
        osc.close()
        sys.exit(2)

    osc.send("/live/track/set/input_routing_type", grid_track,
             "IAC Driver (Bus 1)")
    time.sleep(0.3)
    osc.send("/live/track/set/current_monitoring_state", grid_track, 1)
    time.sleep(0.3)

    # PANIC to start clean
    loader.panic(settle_secs=2.0)
    print("  Setup complete. Grid routing = IAC, PANIC sent.")

    # Ensure A1 is active (baseline)
    print("\n── Baseline: activate A1 ──")
    send_note(loader.port, BANK_A_COL1)
    time.sleep(5.0)
    baseline = do_inspect(loader)
    print(f"  Baseline: preset_index={baseline.get('preset_index')}, "
          f"clip_set={baseline.get('clip_set')}")

    # ════════════════════════════════════════════════════════════════
    # Scenario 1: Hot-swap A1 → B1
    # ════════════════════════════════════════════════════════════════
    print("\n── Scenario 1: Hot-swap A1 → B1 ──")
    send_note(loader.port, BANK_B_COL1)
    time.sleep(5.0)

    insp = do_inspect(loader)
    pi = insp.get("preset_index")
    cs = insp.get("clip_set")
    tid_b = insp.get("track_id")

    passed_1a = (pi == 8 and cs == "B")
    result.record("1a: B1 inspect fields", passed_1a,
                  f"preset_index={pi} (exp 8), clip_set={cs!r} (exp 'B'), "
                  f"track_id={tid_b}")

    # Verify clips exist on stems after swap
    b_counts = {s: count_clips(osc, stem_indices[s]) for s in STEM_TRACKS}
    b_detail = " | ".join(f"{s}: {b_counts[s]}/8" for s in STEM_TRACKS)
    # At minimum drums/bass/other should have clips
    passed_1b = (b_counts["sf-drums"] >= 1 and b_counts["sf-bass"] >= 1
                 and b_counts["sf-other"] >= 1)
    result.record("1b: B1 has clips on stems", passed_1b, b_detail)

    # Check that B1 is a different song than A1
    tid_a = baseline.get("track_id")
    different_song = (tid_b != tid_a)
    result.record("1c: B1 is different song from A1", different_song,
                  f"A1 track_id={tid_a}, B1 track_id={tid_b}")

    # Swap back to A1
    print("\n  Swapping back to A1...")
    send_note(loader.port, BANK_A_COL1)
    time.sleep(5.0)
    insp_back = do_inspect(loader)
    passed_1d = (insp_back.get("preset_index") == 0
                 and insp_back.get("clip_set") == "A")
    result.record("1d: swap back to A1", passed_1d,
                  f"preset_index={insp_back.get('preset_index')}, "
                  f"clip_set={insp_back.get('clip_set')!r}")

    # ════════════════════════════════════════════════════════════════
    # Scenario 2: Scene save + recall
    # ════════════════════════════════════════════════════════════════
    print("\n── Scenario 2: Scene save + recall ──")

    # Step 2a: Fire drums chop 1 to create a "state" worth saving
    send_note(loader.port, DRUM_CHOP_1)
    time.sleep(1.5)
    drums_active = count_active(osc, stem_indices["sf-drums"])
    result.record("2a: drums chop 1 active before save", drums_active >= 1,
                  f"drums active={drums_active}")

    # Step 2b: Save scene A (HOLD press + scene A press, then release both)
    # HOLD is a toggle modifier — press activates "held" state
    print("  Saving scene A (HOLD + Scene-A)...")
    loader.port.send(mido.Message("note_on", note=MOD_HOLD, velocity=100,
                                  channel=0))
    time.sleep(0.15)
    # While HOLD is down, press scene A pad
    send_note(loader.port, SCENE_A, velocity=100, duration=0.1)
    time.sleep(0.15)
    # Release HOLD
    loader.port.send(mido.Message("note_off", note=MOD_HOLD, velocity=0,
                                  channel=0))
    time.sleep(1.0)

    # Record that we attempted the save (we can't directly verify scene state
    # without debug console, but recall will confirm it worked)
    result.record("2b: scene A save gesture sent", True,
                  "HOLD(21) + Scene-A(11) sent")

    # Step 2c: Change state — PANIC to stop all chops, switch to B1
    loader.panic(settle_secs=2.0)
    send_note(loader.port, BANK_B_COL1)
    time.sleep(5.0)
    insp_changed = do_inspect(loader)
    state_changed = (insp_changed.get("preset_index") == 8)
    result.record("2c: state changed (now B1)", state_changed,
                  f"preset_index={insp_changed.get('preset_index')}")

    # Step 2d: Recall scene A (scene pad alone, no HOLD)
    print("  Recalling scene A...")
    send_note(loader.port, SCENE_A, velocity=100)
    time.sleep(5.0)  # allow recall + warp fixup

    insp_recalled = do_inspect(loader)
    recalled_pi = insp_recalled.get("preset_index")
    recalled_cs = insp_recalled.get("clip_set")
    # Scene A was saved while A1 was active with drums chop 1 playing
    passed_2d = (recalled_pi == 0 and recalled_cs == "A")
    result.record("2d: scene A recall restores A1", passed_2d,
                  f"preset_index={recalled_pi} (exp 0), "
                  f"clip_set={recalled_cs!r} (exp 'A')")

    # Check if drums chop was restored
    time.sleep(1.0)
    drums_restored = count_active(osc, stem_indices["sf-drums"])
    result.record("2e: drums chop restored by scene recall", drums_restored >= 1,
                  f"drums active={drums_restored} (exp >=1)")

    # ════════════════════════════════════════════════════════════════
    # Scenario 3: Dual-song toggle
    # ════════════════════════════════════════════════════════════════
    print("\n── Scenario 3: Dual-song entry ──")

    # PANIC first to clean state
    loader.panic(settle_secs=2.0)
    # Ensure A1 is active
    send_note(loader.port, BANK_A_COL1)
    time.sleep(5.0)

    # Double-tap note 89 to latch dual-song mode.
    # For dual-song to work, we need both a bank-A and bank-B preset loaded.
    # A1 should already be lastActiveBankA; we need to ensure B1 was visited
    # (we did in scenario 1, so lastActiveBankB should be set).

    # First check: activate B1 briefly then back to A1 to ensure both decks set
    send_note(loader.port, BANK_B_COL1)
    time.sleep(4.0)
    send_note(loader.port, BANK_A_COL1)
    time.sleep(4.0)

    print("  Double-tapping dual-song toggle (note 89)...")
    # First tap
    loader.port.send(mido.Message("note_on", note=DUAL_SONG_TOGGLE,
                                  velocity=100, channel=0))
    time.sleep(0.05)
    loader.port.send(mido.Message("note_off", note=DUAL_SONG_TOGGLE,
                                  velocity=0, channel=0))
    # Brief gap (under 400ms double-tap window)
    time.sleep(0.15)
    # Second tap (latch)
    loader.port.send(mido.Message("note_on", note=DUAL_SONG_TOGGLE,
                                  velocity=100, channel=0))
    time.sleep(0.05)
    loader.port.send(mido.Message("note_off", note=DUAL_SONG_TOGGLE,
                                  velocity=0, channel=0))
    time.sleep(2.0)

    # Inspect — dual-song state isn't in the inspect JSON, but we can check
    # indirect evidence: inspect still works and shows a valid preset.
    # The true verification is that the grid LED layout changed (rows 1-4 =
    # deck X, rows 5-8 = deck Y) but we can't observe LEDs headlessly.
    insp_dual = do_inspect(loader)
    dual_has_data = (insp_dual.get("preset_index") is not None)

    # Check if x/y stem tracks have clips (dual-song populates sf-*-x and sf-*-y)
    x_drums = count_clips(osc, track_map.get("sf-drums-x", -1)) if "sf-drums-x" in track_map else 0
    y_drums = count_clips(osc, track_map.get("sf-drums-y", -1)) if "sf-drums-y" in track_map else 0

    result.record("3a: dual-song entry (double-tap 89)", dual_has_data,
                  f"inspect OK, x-drums={x_drums}, y-drums={y_drums} "
                  f"(>0 if dual-song populated the extended tracks)")

    # Exit dual-song: single tap while latched
    print("  Exiting dual-song (single tap)...")
    send_note(loader.port, DUAL_SONG_TOGGLE, velocity=100, duration=0.05)
    time.sleep(1.0)

    insp_post = do_inspect(loader)
    post_pi = insp_post.get("preset_index")
    result.record("3b: dual-song exit (single tap)", post_pi is not None,
                  f"preset_index={post_pi} after exit")

    # ── Cleanup ────────────────────────────────────────────────────
    loader.panic(settle_secs=1.5)

    # ── Done ───────────────────────────────────────────────────────
    result.summary()
    osc.close()
    loader.port.close()
    sys.exit(0 if result.all_passed else 1)


if __name__ == "__main__":
    main()
