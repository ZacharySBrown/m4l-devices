#!/usr/bin/env python3
"""
Fully automated UAT runner for setforge-live.

Sends MIDI via IAC to activate each preset, waits for the device to
write /tmp/setforge_inspect.json (auto-written on preset activation),
then runs pytest assertions against the clip state.

Prerequisites:
    - Live running with setforge-loader + setforge-grid loaded
    - Set loaded (hiphop_breaks.set.json)
    - IAC Driver enabled (Audio MIDI Setup)
    - setforge-grid MIDI track has IAC Driver Bus 1 as MIDI input
      (in addition to Launchpad — or temporarily instead of it)

Usage:
    python tests/uat/run_uat.py [--preset N] [--all]
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))


import mido

INSPECT_PATH = Path("/tmp/setforge_inspect.json")
MANIFEST_DIR = Path("/Users/zak/zacharysbrown/taste/setlist_out/manifests")
SET_PATH = Path("/Users/zak/Desktop/sets/hiphop_breaks.set.json")
COMBINED_MANIFEST_PATH = Path("/Users/zak/Desktop/sets/hiphop_breaks.manifest.json")

BEATS_PER_BAR = 4
BPM_TOLERANCE = 2.0
BEAT_TOLERANCE = 0.5

EXPECTED_WARP_MODES = {"drums": 0, "bass": 0, "other": 4, "vox": 4}


def find_iac_port():
    for name in mido.get_output_names():
        if 'IAC' in name:
            return name
    return None


def preset_note(slot_index):
    """MIDI note for a preset pad in programmer mode.

    New multi-song layout:
      Row 5 (bank A, slots 0-7): LP row 5 → notes 41-48
      Row 6 (bank B, slots 8-15): LP row 4 → notes 31-38

    LP programmer mode: note = lpRow*10 + col, where lpRow = 9 - specRow.
    Row 5 → lpRow 4 → notes 41-48
    Row 6 → lpRow 3 → notes 31-38
    """
    if slot_index < 8:
        return 41 + slot_index   # Row 5 (bank A): notes 41-48
    else:
        return 31 + (slot_index - 8)  # Row 6 (bank B): notes 31-38


def activate_preset(midi_port, slot_index):
    """Send a pad press via IAC to activate a preset. Auto-inspect fires after."""
    note = preset_note(slot_index)
    print(f"  Sending note {note} (preset slot {slot_index}) via IAC...")
    midi_port.send(mido.Message('note_on', note=note, velocity=100))
    time.sleep(0.05)
    midi_port.send(mido.Message('note_off', note=note, velocity=0))


def wait_for_inspect(timeout=45.0, expect_track_id=None):
    """Wait for /tmp/setforge_inspect.json to be written/updated."""
    start = time.time()
    last_mtime = INSPECT_PATH.stat().st_mtime if INSPECT_PATH.exists() else 0

    while time.time() - start < timeout:
        if INSPECT_PATH.exists():
            mtime = INSPECT_PATH.stat().st_mtime
            if mtime > last_mtime:
                time.sleep(0.5)  # let write finish
                try:
                    with open(INSPECT_PATH) as f:
                        data = json.load(f)
                    if expect_track_id is None or data.get("track_id") == expect_track_id:
                        return data
                except (json.JSONDecodeError, KeyError):
                    pass
        time.sleep(0.5)
    return None


def load_track_manifest(track_id):
    """Load individual track manifest."""
    p = MANIFEST_DIR / f"{track_id}.json"
    if p.exists():
        with open(p) as f:
            return json.load(f)
    return None


# ═══════════════════════════════════════════════════════════
#  Assertions
# ═══════════════════════════════════════════════════════════

def check_clip(stem, clip, manifest_bpm, errors):
    """Run all assertions on a single clip. Appends failures to errors list."""
    slot = clip["slot"]
    chop = clip.get("chop")
    prefix = f"{stem}[{slot}]"

    if not chop:
        return  # no chop metadata, skip

    bars = chop.get("lengthBars", 0)
    label = chop.get("label", "")

    if bars > 0:
        expected_beats = bars * BEATS_PER_BAR

        # Warping should be on
        if clip["warping"] != 1:
            errors.append(f"{prefix} ({label}): warping={clip['warping']}, expected 1")

        # Warp mode
        expected_mode = EXPECTED_WARP_MODES.get(stem, 4)
        if clip["warp_mode"] != expected_mode:
            errors.append(f"{prefix} ({label}): warp_mode={clip['warp_mode']}, expected {expected_mode}")

        # Loop start should be ~0
        if abs(clip["loop_start"]) > BEAT_TOLERANCE:
            errors.append(f"{prefix} ({label}): loop_start={clip['loop_start']:.2f}, expected ~0")

        # Loop end should match bar count
        if abs(clip["loop_end"] - expected_beats) > BEAT_TOLERANCE:
            errors.append(f"{prefix} ({label}): loop_end={clip['loop_end']:.2f}, expected {expected_beats}")

        # start_marker should match loop_start
        if abs(clip["start_marker"] - clip["loop_start"]) > BEAT_TOLERANCE:
            errors.append(f"{prefix} ({label}): start_marker={clip['start_marker']:.2f} != loop_start={clip['loop_start']:.2f}")

        # end_marker should match loop_end
        if abs(clip["end_marker"] - clip["loop_end"]) > BEAT_TOLERANCE:
            errors.append(f"{prefix} ({label}): end_marker={clip['end_marker']:.2f} != loop_end={clip['loop_end']:.2f}")

        # Warp markers
        markers = clip.get("warp_markers", [])
        if len(markers) < 2:
            errors.append(f"{prefix} ({label}): only {len(markers)} warp markers, need >=2")
        else:
            # Check implied BPM
            first, last = markers[0], markers[-1]
            dt_sec = last["sample_time"] - first["sample_time"]
            dt_beat = last["beat_time"] - first["beat_time"]
            if dt_sec > 0 and dt_beat > 0:
                implied_bpm = (dt_beat / dt_sec) * 60
                if abs(implied_bpm - manifest_bpm) > BPM_TOLERANCE:
                    errors.append(f"{prefix} ({label}): implied BPM={implied_bpm:.2f}, expected {manifest_bpm:.2f}")

                # Specific check: not half-tempo
                if implied_bpm < manifest_bpm * 0.6:
                    errors.append(f"{prefix} ({label}): HALF-TEMPO detected ({implied_bpm:.1f} vs {manifest_bpm:.1f})")

            # Check downbeat alignment — marker at sample 0 should be at a
            # negative beat (buffer pad). The marker closest to beat 0 defines
            # the downbeat. Allow up to ~2 bars of negative offset for the pad.
            min_beat = min(m["beat_time"] for m in markers)
            max_pad_beats = 8  # up to 2 bars of padding
            if min_beat < -max_pad_beats:
                errors.append(f"{prefix} ({label}): earliest warp marker at beat {min_beat:.2f}, excessive pad (>{max_pad_beats} beats)")

        # Buffer padding check
        clip_start = chop.get("clipStart", 0)
        one_bar_sec = 4 * 60 / manifest_bpm
        if clip_start > one_bar_sec * 3:
            errors.append(f"{prefix} ({label}): clipStart={clip_start:.2f}s — excessive buffer pad")

        # Loop coverage
        if clip["length"] > 0:
            loop_span = clip["loop_end"] - clip["loop_start"]
            ratio = loop_span / clip["length"]
            if ratio < 0.3:
                errors.append(f"{prefix} ({label}): loop covers {ratio:.0%} of clip — too much padding")

    else:
        # Oneshot
        if clip["warping"] != 0:
            errors.append(f"{prefix} (oneshot): warping={clip['warping']}, expected 0")


def run_preset_test(data, track_id):
    """Run all assertions for a single preset's inspect data."""
    manifest = load_track_manifest(track_id)
    if not manifest:
        return [f"No manifest found for track {track_id}"]

    bpm = manifest["bpm"]
    errors = []

    # Session tempo check (LiveAPI returns tempo as a list sometimes)
    session_tempo = data.get("session_tempo")
    if session_tempo is not None:
        if isinstance(session_tempo, list):
            session_tempo = float(session_tempo[0]) if session_tempo else None
        else:
            session_tempo = float(session_tempo)
    if session_tempo is not None:
        if abs(session_tempo - bpm) > BPM_TOLERANCE:
            errors.append(f"Session tempo {session_tempo:.2f} != track BPM {bpm:.2f}")

    # Check all clips
    for stem in ["drums", "bass", "other", "vox"]:
        clips = data["stems"].get(stem, [])
        if not clips:
            errors.append(f"{stem}: no clips loaded")
            continue

        for clip in clips:
            check_clip(stem, clip, bpm, errors)

    # Cross-stem consistency (bar counts may differ — curator picks per-stem)
    # Only warn, don't fail
    for slot_idx in range(8):
        bar_counts = {}
        for stem in ["drums", "bass", "other", "vox"]:
            for clip in data["stems"].get(stem, []):
                if clip["slot"] == slot_idx and clip.get("chop"):
                    bars = clip["chop"].get("lengthBars", 0)
                    if bars > 0:
                        bar_counts[stem] = bars
        if len(set(bar_counts.values())) > 1:
            print(f"    ⚠ Slot {slot_idx}: bar counts differ across stems: {bar_counts} (OK — curator picks per-stem)")

    return errors


# ═══════════════════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="Automated UAT for setforge-live")
    parser.add_argument("--preset", type=int, help="Test a single preset slot (0-based)")
    parser.add_argument("--all", action="store_true", help="Test all presets in both banks")
    args = parser.parse_args()

    with open(SET_PATH) as f:
        set_data = json.load(f)

    bank_a = set_data.get("preset_bank_A", [])
    bank_b = set_data.get("preset_bank_B", [])
    all_presets = bank_a + bank_b

    if args.preset is not None:
        test_slots = [args.preset]
    elif args.all:
        test_slots = [i for i, p in enumerate(all_presets) if p and p.get("track_id")]
    else:
        test_slots = [0]

    # Connect to IAC
    iac_name = find_iac_port()
    if not iac_name:
        print("ERROR: No IAC Driver port found.")
        print("  1. Open Audio MIDI Setup")
        print("  2. Window > Show MIDI Studio")
        print("  3. Double-click IAC Driver > check 'Device is online'")
        print("  4. In Live, set the grid track's MIDI From to IAC Driver Bus 1")
        sys.exit(1)
    midi_port = mido.open_output(iac_name)
    print(f"Connected: {iac_name}")

    # Run tests
    total_errors = 0
    total_passed = 0
    results = {}

    for slot in test_slots:
        preset = all_presets[slot] if slot < len(all_presets) else None
        if not preset or not preset.get("track_id"):
            print(f"\n⏭  Slot {slot}: empty, skipping")
            continue

        track_id = preset["track_id"]
        manifest = load_track_manifest(track_id)
        track_name = manifest.get("display_name", track_id) if manifest else track_id

        print(f"\n{'='*60}")
        print(f"  Testing slot {slot}: {track_id} ({track_name})")
        print(f"{'='*60}")

        # Clear old inspect file
        if INSPECT_PATH.exists():
            os.remove(INSPECT_PATH)

        # Activate preset via IAC MIDI (auto-inspect fires after)
        activate_preset(midi_port, slot)

        # Wait for inspect file
        print(f"  Waiting for inspect data...")
        data = wait_for_inspect(timeout=30, expect_track_id=track_id)
        if not data:
            print(f"  TIMEOUT: no inspect data received for {track_id}")
            print(f"  (Is IAC routed to the grid track? Is the set loaded?)")
            total_errors += 1
            results[track_id] = ["TIMEOUT: no inspect data"]
            continue

        print(f"  Got inspect data: {len(data.get('stems', {}).get('drums', []))} drum clips")

        # Run assertions
        errors = run_preset_test(data, track_id)
        results[track_id] = errors

        if errors:
            print(f"\n  FAILURES ({len(errors)}):")
            for e in errors:
                print(f"    ✗ {e}")
            total_errors += len(errors)
        else:
            print(f"\n  ✓ All checks passed")
            total_passed += 1

        # Wait for clips to load + deferred warp fix (2s) + inspect write
        time.sleep(5)

    # Summary
    print(f"\n{'='*60}")
    print(f"  UAT SUMMARY")
    print(f"{'='*60}")
    print(f"  Presets tested: {len(results)}")
    print(f"  Passed: {total_passed}")
    print(f"  Total failures: {total_errors}")
    for tid, errs in results.items():
        status = "✓ PASS" if not errs else f"✗ FAIL ({len(errs)} issues)"
        print(f"    {tid}: {status}")
    print()

    midi_port.close()
    sys.exit(0 if total_errors == 0 else 1)


if __name__ == "__main__":
    main()
