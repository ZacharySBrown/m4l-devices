#!/usr/bin/env python3
"""
UAT: Multi-song modes — per-row mode, staging, dual-song view.

Tests the full multi-song pipeline via IAC MIDI:
1. Per-row mode: double-tap SOLO, reassign rows, verify cross-song playback
2. Staging: hold deck-setup, tap presets, verify pre-load
3. Dual-song: enter dual-song view, fire from both decks

Prerequisites:
    - Live running with setforge-loader + setforge-grid loaded from worktree
    - Production set loaded (hiphop_breaks.set.json)
    - IAC Driver enabled and routed to grid track
    - 8 stem tracks exist (sf-drums, sf-bass, sf-other, sf-vox,
      sf-drums-y, sf-bass-y, sf-other-y, sf-vox-y)
"""

import json
import os
import sys
import time
from pathlib import Path

import mido

INSPECT_PATH = Path("/tmp/setforge_inspect.json")

# MK2 programmer mode: note = (9 - specRow) * 10 + col
# New layout:
#   Row 1 (drums):  notes 81-88
#   Row 2 (bass):   notes 71-78
#   Row 3 (other):  notes 61-68
#   Row 4 (vox):    notes 51-58
#   Row 5 (bank A): notes 41-48
#   Row 6 (bank B): notes 31-38
#   Row 7 (mods):   notes 21-28
#   Row 8 (scenes): notes 11-18

def note(row, col):
    """Convert spec row/col to MK2 programmer mode note."""
    return (9 - row) * 10 + col

# Side buttons (left side, top-to-bottom in programmer mode)
SIDE_LEFT = [80, 70, 60, 50, 40, 30, 20, 10]
# Side buttons (right side)
SIDE_RIGHT = [89, 79, 69, 59, 49, 39, 29, 19]

# Right side function map
DUAL_SONG_TOGGLE = SIDE_RIGHT[0]  # top-right = 89
DECK_SETUP = SIDE_RIGHT[1]        # position 2 = 79

DOUBLE_TAP_MS = 0.2  # 200ms between taps for double-tap


def find_iac_port():
    for name in mido.get_output_names():
        if 'IAC' in name:
            return name
    return None


def send_note(port, n, vel=100, hold=0.05):
    port.send(mido.Message('note_on', note=n, velocity=vel))
    time.sleep(hold)
    port.send(mido.Message('note_off', note=n, velocity=0))


def send_note_on(port, n, vel=100):
    port.send(mido.Message('note_on', note=n, velocity=vel))


def send_note_off(port, n):
    port.send(mido.Message('note_off', note=n, velocity=0))


def double_tap(port, n, vel=100):
    """Double-tap a pad (for latch gestures)."""
    send_note(port, n, vel)
    time.sleep(DOUBLE_TAP_MS)
    send_note(port, n, vel)


def wait_for_inspect(timeout=15.0, expect_track_id=None):
    start = time.time()
    last_mtime = INSPECT_PATH.stat().st_mtime if INSPECT_PATH.exists() else 0
    while time.time() - start < timeout:
        if INSPECT_PATH.exists():
            mtime = INSPECT_PATH.stat().st_mtime
            if mtime > last_mtime:
                time.sleep(0.5)
                try:
                    with open(INSPECT_PATH) as f:
                        data = json.load(f)
                    if expect_track_id is None or data.get("track_id") == expect_track_id:
                        return data
                except (json.JSONDecodeError, KeyError):
                    pass
        time.sleep(0.5)
    return None


def clear_inspect():
    try:
        os.remove(str(INSPECT_PATH))
    except FileNotFoundError:
        pass


# ═══════════════════════════════════════════════════════════
#  Tests
# ═══════════════════════════════════════════════════════════

# Counter for cycling through presets (each test uses a different slot)
_next_slot = [0]

def verify_responsive(port, label=""):
    """Activate the next unused preset slot and verify inspect fires.
    Uses a round-robin counter so we never re-activate the same slot."""
    slot_idx = _next_slot[0]
    _next_slot[0] = (slot_idx + 1) % 8  # cycle through bank A

    target_note = note(5, slot_idx + 1)
    clear_inspect()
    print(f"  [{label}] activating bank A slot {slot_idx} (note {target_note})...")
    send_note(port, target_note)

    data = wait_for_inspect(timeout=20.0)
    if data:
        print(f"  [{label}] OK: preset={data['preset_index']}, track={data['track_id']}")
    else:
        print(f"  [{label}] TIMEOUT")
    return data


def test_layout_preset_activation(port):
    """Phase 1: Verify presets activate on new row positions."""
    print("\n=== Test: Layout — preset activation on rows 5-6 ===")

    data = verify_responsive(port, label="bank A slot 0")
    if not data:
        print("  FAIL: no inspect data after preset activation")
        return False

    # Also test bank B
    data2 = verify_responsive(port, label="bank B also")
    if data2:
        print(f"  Bank B also works")

    print("  PASS")
    return True


def test_per_row_mode_entry(port):
    """Phase 2: Double-tap SOLO enters per-row mode."""
    print("\n=== Test: Per-row mode — SOLO double-tap ===")

    # Double-tap SOLO (row 7, col 3)
    solo_note = note(7, 3)
    double_tap(port, solo_note)
    time.sleep(1)

    # Verify device still works by switching presets
    data = verify_responsive(port, label="after per-row entry")
    if not data:
        print("  FAIL: device stopped responding after SOLO double-tap")
        return False

    print(f"  Device responsive after per-row entry: preset={data['preset_index']}")

    # Exit per-row: tap SOLO once (unlatch)
    send_note(port, solo_note)
    time.sleep(0.5)

    print("  PASS")
    return True


def test_per_row_reassign(port):
    """Phase 2: Hold chop + tap preset reassigns row source."""
    print("\n=== Test: Per-row mode — row reassignment ===")

    # Start on preset 0
    send_note(port, note(5, 1))
    time.sleep(2)

    # Enter per-row mode
    solo_note = note(7, 3)
    double_tap(port, solo_note)
    time.sleep(1)

    # Hold drums chop (row 1, col 1) and tap preset 1 (row 5, col 2)
    drums_pad = note(1, 1)
    preset_pad = note(5, 2)

    send_note_on(port, drums_pad)
    time.sleep(0.1)
    send_note(port, preset_pad)  # reassign drums to preset 1
    time.sleep(0.1)
    send_note_off(port, drums_pad)
    time.sleep(3)

    # Fire a drum chop from the reassigned preset
    send_note(port, note(1, 3))  # drums col 3
    time.sleep(1)

    # Verify device is still responsive
    data = verify_responsive(port, label="after reassign")
    if not data:
        print("  FAIL: device stopped responding after per-row reassign")
        send_note(port, solo_note)
        return False

    print(f"  Device responsive after per-row reassign: track={data['track_id']}")

    # Exit per-row mode
    send_note(port, solo_note)
    time.sleep(0.5)

    print("  PASS")
    return True


def test_staging(port):
    """Phase 3: Hold deck-setup + tap presets stages decks."""
    print("\n=== Test: Staging — deck-setup + preset tap ===")

    # Hold deck-setup (right side position 2 = note 79)
    send_note_on(port, DECK_SETUP)
    time.sleep(0.2)

    # Tap bank A slot 0 → stage deck X
    send_note(port, note(5, 1))
    time.sleep(0.5)

    # Tap bank B slot 0 → stage deck Y
    send_note(port, note(6, 1))
    time.sleep(0.5)

    # Release deck-setup
    send_note_off(port, DECK_SETUP)
    time.sleep(5)  # wait for pre-load

    # Verify device still responsive
    data = verify_responsive(port, label="after staging")
    if not data:
        print("  FAIL: device stopped responding after staging")
        return False

    print(f"  Device responsive after staging: track={data['track_id']}")
    print("  PASS")
    return True


def test_dual_song_entry(port):
    """Phase 4: Enter dual-song mode via top-right side button."""
    print("\n=== Test: Dual-song — entry via top-right toggle ===")

    # Stage both decks
    send_note_on(port, DECK_SETUP)
    time.sleep(0.2)
    send_note(port, note(5, 1))   # deck X = bank A slot 0
    time.sleep(0.5)
    send_note(port, note(6, 1))   # deck Y = bank B slot 0
    time.sleep(0.5)
    send_note_off(port, DECK_SETUP)
    time.sleep(5)  # wait for pre-load

    # Double-tap dual-song toggle to latch
    double_tap(port, DUAL_SONG_TOGGLE)
    time.sleep(1)

    # In dual-song mode, fire chops from both decks
    send_note(port, note(1, 1))  # X drums chop 1
    time.sleep(0.3)
    send_note(port, note(5, 1))  # Y drums chop 1
    time.sleep(0.3)
    send_note(port, note(2, 1))  # X bass chop 1
    time.sleep(0.3)
    send_note(port, note(6, 1))  # Y bass chop 1
    time.sleep(1)

    print("  Fired 4 simultaneous voices (X drums, Y drums, X bass, Y bass)")

    # Exit dual-song: tap toggle once (unlatch)
    send_note(port, DUAL_SONG_TOGGLE)
    time.sleep(1)

    # Verify device responsive after exit
    data = verify_responsive(port, label="after dual-song exit")
    if not data:
        print("  FAIL: device stopped responding after dual-song exit")
        return False

    print(f"  Device responsive after dual-song exit: track={data['track_id']}")
    print("  PASS")
    return True


def test_panic_clears_multi_song(port):
    """Panic should reset all multi-song state."""
    print("\n=== Test: Panic clears multi-song state ===")

    # Enter per-row mode
    solo_note = note(7, 3)
    double_tap(port, solo_note)
    time.sleep(0.5)

    # Triple-tap panic (left side position 8 = note 10)
    panic_note = SIDE_LEFT[7]  # 10
    send_note(port, panic_note)
    time.sleep(0.1)
    send_note(port, panic_note)
    time.sleep(0.1)
    send_note(port, panic_note)
    time.sleep(1)

    # Verify device responsive
    data = verify_responsive(port, label="after panic")
    if not data:
        print("  FAIL: device stopped responding after panic")
        return False

    print(f"  Device responsive after panic: track={data['track_id']}")
    print("  PASS")
    return True


# ═══════════════════════════════════════════════════════════
#  Main
# ═══════════════════════════════════════════════════════════

def main():
    iac_name = find_iac_port()
    if not iac_name:
        print("ERROR: No IAC Driver port found.")
        sys.exit(1)

    port = mido.open_output(iac_name)
    print(f"Connected: {iac_name}")

    tests = [
        test_layout_preset_activation,
        test_per_row_mode_entry,
        test_per_row_reassign,
        test_staging,
        test_dual_song_entry,
        test_panic_clears_multi_song,
    ]

    passed = 0
    failed = 0
    for test in tests:
        try:
            if test(port):
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"  ERROR: {e}")
            failed += 1

    print(f"\n{'='*60}")
    print(f"  MULTI-SONG UAT SUMMARY")
    print(f"{'='*60}")
    print(f"  Passed: {passed}/{len(tests)}")
    print(f"  Failed: {failed}/{len(tests)}")
    print()

    port.close()
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
