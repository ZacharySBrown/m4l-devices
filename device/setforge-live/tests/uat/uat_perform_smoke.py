#!/usr/bin/env python3
"""Headless perform-a-set UAT smoke test (IAC + OSC).

Exercises the full signal path: set grid input routing via AbletonOSC,
fire pad notes/CCs via mido→IAC, verify clip state via OSC.

Requires: Ableton Live running with AbletonOSC, setforge-live devices loaded,
a set already loaded in the loader (e.g. hiphop_danceable_v2).

Usage:
    python3 tests/uat/uat_perform_smoke.py
"""

import os
import sys
import time

# ── Path setup: bring sibling test dirs into scope ─────────────────
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
_CURATION_DIR = os.path.join(os.path.dirname(_THIS_DIR), "curation")
sys.path.insert(0, _THIS_DIR)
sys.path.insert(0, _CURATION_DIR)

import mido
from osc_client import AbletonOSC
from live_bridge import LiveBridge
from loader_bridge import LoaderBridge

# ── Pad-note layout (Launchpad: note = (9-row)*10 + col) ──────────
# Row 1 = drums, Row 2 = bass, Row 3 = other, Row 4 = vox
# Row 5 = bank A presets, Row 6 = bank B presets
DRUM_CHOP_1 = 81   # row 1, col 1
BASS_CHOP_1 = 71   # row 2, col 1
BANK_A_COL1 = 41   # row 5, col 1  (preset A1 / slot 0)

STEM_TRACKS = ("sf-drums", "sf-bass", "sf-other", "sf-vox")
SLOTS = range(8)


class SmokeResult:
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


def count_clips(osc: AbletonOSC, track: int) -> int:
    """Count clips in slots 0-7 on a track."""
    count = 0
    for slot in SLOTS:
        try:
            (_, _, has) = osc.ask("/live/clip_slot/get/has_clip", track, slot)
            if has:
                count += 1
        except TimeoutError:
            pass
    return count


def count_playing(osc: AbletonOSC, track: int) -> int:
    """Count clips currently playing or triggered in slots 0-7 on a track.

    Checks both is_playing and is_triggered because clips may be waiting
    for launch quantization (triggered but not yet playing).
    """
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


def send_note(port: mido.ports.BaseOutput, note: int, velocity: int = 100,
              duration: float = 0.12):
    """Send note on/off to IAC."""
    port.send(mido.Message("note_on", note=note, velocity=velocity, channel=0))
    time.sleep(duration)
    port.send(mido.Message("note_off", note=note, velocity=0, channel=0))


def main():
    result = SmokeResult()

    # ── Setup ──────────────────────────────────────────────────────
    print("── Setup ──")
    osc = AbletonOSC(default_timeout=3.0)
    live = LiveBridge(osc)
    loader = LoaderBridge()

    # Map tracks by name
    tracks = live.list_tracks()
    track_map = {name: idx for idx, name in tracks}
    print(f"  Tracks: {[(i, n) for i, n in tracks]}")

    stem_indices = {}
    for stem in STEM_TRACKS:
        if stem not in track_map:
            print(f"  ERROR: stem track {stem!r} not found")
            osc.close()
            sys.exit(2)
        stem_indices[stem] = track_map[stem]

    # Find grid track (has setforge-grid device)
    grid_track = None
    for idx, name in tracks:
        try:
            (_, num) = osc.ask("/live/track/get/num_devices", idx)
            if num > 0:
                (_, _, dev_name) = osc.ask("/live/device/get/name", idx, 0)
                if dev_name == "setforge-grid":
                    grid_track = idx
                    print(f"  Grid track: {idx} ({name})")
                    break
        except TimeoutError:
            continue

    if grid_track is None:
        print("  ERROR: no track with setforge-grid found")
        osc.close()
        sys.exit(2)

    # Set grid track input routing to IAC + monitor In
    osc.send("/live/track/set/input_routing_type", grid_track,
             "IAC Driver (Bus 1)")
    time.sleep(0.3)
    osc.send("/live/track/set/current_monitoring_state", grid_track, 1)
    time.sleep(0.3)
    (_, routing) = osc.ask("/live/track/get/input_routing_type", grid_track)
    print(f"  Grid routing: {routing}")

    # PANIC to start clean
    loader.panic(settle_secs=1.5)
    print("  Sent PANIC (CC 103)")

    # ── Step A — activate preset A1 ────────────────────────────────
    print("\n── Step A: activate preset A1 ──")
    send_note(loader.port, BANK_A_COL1, velocity=100)
    time.sleep(5.0)  # allow clip creation to complete

    clip_counts = {}
    for stem in STEM_TRACKS:
        clip_counts[stem] = count_clips(osc, stem_indices[stem])

    detail = " | ".join(f"{s}: {clip_counts[s]}/8" for s in STEM_TRACKS)
    drums_ok = clip_counts["sf-drums"] == 8
    bass_ok = clip_counts["sf-bass"] == 8
    other_ok = clip_counts["sf-other"] == 8
    vox_ok = clip_counts["sf-vox"] >= 1
    passed = drums_ok and bass_ok and other_ok and vox_ok
    result.record("A: clip counts after A1", passed, detail)

    if not passed:
        # Still continue with remaining steps for diagnostics
        pass

    # ── Step B — trigger drums chop 1 ──────────────────────────────
    print("\n── Step B: trigger drums chop 1 ──")
    send_note(loader.port, DRUM_CHOP_1, velocity=100)
    time.sleep(1.5)

    drums_playing = count_playing(osc, stem_indices["sf-drums"])
    passed_b = drums_playing == 1
    result.record("B: drums chop 1 playing", passed_b,
                  f"sf-drums playing={drums_playing} (expected 1)")

    # ── Step C — trigger bass chop 1 ───────────────────────────────
    print("\n── Step C: trigger bass chop 1 ──")
    send_note(loader.port, BASS_CHOP_1, velocity=100)
    time.sleep(1.5)

    bass_playing = count_playing(osc, stem_indices["sf-bass"])
    passed_c = bass_playing == 1
    result.record("C: bass chop 1 playing", passed_c,
                  f"sf-bass playing={bass_playing} (expected 1)")

    # ── Step D — PANIC (CC 103) ────────────────────────────────────
    print("\n── Step D: PANIC ──")
    loader.panic(settle_secs=3.0)

    total_playing = 0
    per_stem = {}
    for stem in STEM_TRACKS:
        n = count_playing(osc, stem_indices[stem])
        per_stem[stem] = n
        total_playing += n

    detail_d = " | ".join(f"{s}: {per_stem[s]}" for s in STEM_TRACKS)
    passed_d = total_playing == 0
    result.record("D: PANIC stops all clips", passed_d,
                  f"playing after PANIC: {detail_d} (expected all 0)")

    # ── Done ───────────────────────────────────────────────────────
    result.summary()
    osc.close()
    loader.port.close()
    sys.exit(0 if result.all_passed else 1)


if __name__ == "__main__":
    main()
