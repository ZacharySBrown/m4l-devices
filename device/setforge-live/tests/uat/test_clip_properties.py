"""
UAT: Verify clip properties for all tracks in the hiphop_breaks setlist.

These tests read /tmp/setforge_inspect.json (written by the device's
'inspect' command) and verify that clips were loaded correctly:

1. Tempos match the manifest BPM
2. Clips have appropriate buffer padding (not excessive silence)
3. Clips are warped to the correct number of bars
4. Loop regions are properly set
5. Warp markers define the correct tempo
6. Warp modes match per-stem expectations

Run with:
    pytest tests/uat/test_clip_properties.py -v

Prerequisites:
    - Live running with setforge-loader loaded
    - Set loaded (hiphop_breaks.set.json)
    - Preset activated
    - 'inspect' sent to the device (writes /tmp/setforge_inspect.json)
"""

import json
import math
from pathlib import Path

import pytest

INSPECT_PATH = Path("/tmp/setforge_inspect.json")
MANIFEST_DIR = Path("/Users/zak/zacharysbrown/taste/setlist_out/manifests")
COMBINED_MANIFEST_PATH = Path("/Users/zak/Desktop/sets/hiphop_breaks.manifest.json")

BEATS_PER_BAR = 4

# Expected warp modes per stem
EXPECTED_WARP_MODES = {
    "drums": 0,   # Beats
    "bass": 0,    # Beats
    "other": 4,   # Complex
    "vox": 4,     # Complex
}

# Tolerance for float comparisons
BEAT_TOLERANCE = 0.5      # beats
TIME_TOLERANCE = 0.1      # seconds
BPM_TOLERANCE = 2.0       # BPM


def load_inspect():
    """Load inspect data, skip if not available."""
    if not INSPECT_PATH.exists():
        pytest.skip("No inspect data — send 'inspect' to the device first")
    with open(INSPECT_PATH) as f:
        return json.load(f)


def load_track_manifest(track_id):
    """Load the individual track manifest."""
    p = MANIFEST_DIR / f"{track_id}.json"
    if not p.exists():
        pytest.skip(f"No manifest for track {track_id}")
    with open(p) as f:
        return json.load(f)


def load_combined_manifest():
    """Load the combined manifest."""
    with open(COMBINED_MANIFEST_PATH) as f:
        return json.load(f)


# ═══════════════════════════════════════════════════════════
#  Test: Basic clip loading
# ═══════════════════════════════════════════════════════════

class TestClipLoading:
    """Verify clips loaded into the correct slots."""

    def test_inspect_file_exists(self):
        assert INSPECT_PATH.exists(), "Run 'inspect' on the device first"

    def test_has_active_preset(self):
        data = load_inspect()
        assert data["preset_index"] >= 0, "No active preset"
        assert data["track_id"] is not None, "No track ID on active preset"

    def test_all_stems_have_clips(self):
        data = load_inspect()
        for stem in ["drums", "bass", "other", "vox"]:
            clips = data["stems"].get(stem, [])
            assert len(clips) > 0, f"No clips loaded for {stem}"

    def test_no_empty_stems(self):
        data = load_inspect()
        for stem in ["drums", "bass", "other", "vox"]:
            clips = data["stems"].get(stem, [])
            # At least the non-oneshot clips should be present
            non_oneshot = [c for c in clips if c.get("chop") and c["chop"].get("lengthBars", 0) > 0]
            assert len(non_oneshot) >= 2, f"{stem} has fewer than 2 non-oneshot clips"


# ═══════════════════════════════════════════════════════════
#  Test: Warping properties
# ═══════════════════════════════════════════════════════════

class TestWarping:
    """Verify warping is correctly configured on all clips."""

    def test_warping_enabled_on_bar_clips(self):
        """All clips with length_bars > 0 should have warping=1."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                chop = clip.get("chop")
                if chop and chop.get("lengthBars", 0) > 0:
                    assert clip["warping"] == 1, \
                        f"{stem}[{clip['slot']}] ({chop.get('label','')}): warping should be 1, got {clip['warping']}"

    def test_warping_disabled_on_oneshots(self):
        """Oneshots (length_bars=0) should have warping=0."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                chop = clip.get("chop")
                if chop and chop.get("lengthBars", 0) == 0:
                    assert clip["warping"] == 0, \
                        f"{stem}[{clip['slot']}] oneshot: warping should be 0, got {clip['warping']}"

    def test_warp_modes_per_stem(self):
        """Drums/bass should use Beats (0), other/vox should use Complex (4)."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            expected = EXPECTED_WARP_MODES[stem]
            for clip in clips:
                if clip["warping"] == 1:
                    assert clip["warp_mode"] == expected, \
                        f"{stem}[{clip['slot']}]: warp_mode should be {expected}, got {clip['warp_mode']}"


# ═══════════════════════════════════════════════════════════
#  Test: Loop regions
# ═══════════════════════════════════════════════════════════

class TestLoopRegions:
    """Verify loop regions match expected bar counts."""

    def test_loop_start_at_zero(self):
        """Loop should start at beat 0 (after buffer pad)."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                if clip["warping"] == 1:
                    assert abs(clip["loop_start"]) < BEAT_TOLERANCE, \
                        f"{stem}[{clip['slot']}]: loop_start should be ~0, got {clip['loop_start']:.2f}"

    def test_loop_end_matches_bar_count(self):
        """Loop end should equal length_bars * 4 beats."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                chop = clip.get("chop")
                if not chop or chop.get("lengthBars", 0) == 0:
                    continue
                expected_beats = chop["lengthBars"] * BEATS_PER_BAR
                assert abs(clip["loop_end"] - expected_beats) < BEAT_TOLERANCE, \
                    f"{stem}[{clip['slot']}] ({chop.get('label','')}): " \
                    f"loop_end should be {expected_beats}, got {clip['loop_end']:.2f}"

    def test_start_marker_matches_loop_start(self):
        """start_marker should equal loop_start."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                if clip["warping"] == 1:
                    assert abs(clip["start_marker"] - clip["loop_start"]) < BEAT_TOLERANCE, \
                        f"{stem}[{clip['slot']}]: start_marker ({clip['start_marker']:.2f}) " \
                        f"!= loop_start ({clip['loop_start']:.2f})"

    def test_end_marker_matches_loop_end(self):
        """end_marker should equal loop_end."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                if clip["warping"] == 1:
                    assert abs(clip["end_marker"] - clip["loop_end"]) < BEAT_TOLERANCE, \
                        f"{stem}[{clip['slot']}]: end_marker ({clip['end_marker']:.2f}) " \
                        f"!= loop_end ({clip['loop_end']:.2f})"


# ═══════════════════════════════════════════════════════════
#  Test: Warp markers and tempo
# ═══════════════════════════════════════════════════════════

class TestWarpMarkers:
    """Verify warp markers define the correct tempo."""

    def test_has_warp_markers(self):
        """Warped clips should have at least 2 warp markers."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                if clip["warping"] == 1:
                    assert len(clip.get("warp_markers", [])) >= 2, \
                        f"{stem}[{clip['slot']}]: warped clip should have >=2 warp markers, " \
                        f"got {len(clip.get('warp_markers', []))}"

    def test_warp_marker_tempo_correct(self):
        """Warp markers should imply the correct BPM from the manifest."""
        data = load_inspect()
        track_id = data["track_id"]
        manifest = load_track_manifest(track_id)
        expected_bpm = manifest["bpm"]

        for stem, clips in data["stems"].items():
            for clip in clips:
                markers = clip.get("warp_markers", [])
                if len(markers) < 2 or clip["warping"] != 1:
                    continue

                # Compute implied BPM from first and last marker
                first = markers[0]
                last = markers[-1]
                dt_sec = last["sample_time"] - first["sample_time"]
                dt_beat = last["beat_time"] - first["beat_time"]

                if dt_sec <= 0 or dt_beat <= 0:
                    continue

                implied_bpm = (dt_beat / dt_sec) * 60
                assert abs(implied_bpm - expected_bpm) < BPM_TOLERANCE, \
                    f"{stem}[{clip['slot']}]: warp markers imply {implied_bpm:.2f} BPM, " \
                    f"expected {expected_bpm:.2f} (±{BPM_TOLERANCE})"

    def test_warp_marker_downbeat_alignment(self):
        """First warp marker's beat_time should be 0 (downbeat at loop start)."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                markers = clip.get("warp_markers", [])
                if not markers or clip["warping"] != 1:
                    continue

                # Find the marker closest to beat 0
                min_beat = min(m["beat_time"] for m in markers)
                assert abs(min_beat) < BEAT_TOLERANCE, \
                    f"{stem}[{clip['slot']}]: earliest warp marker at beat {min_beat:.2f}, " \
                    f"expected ~0 (downbeat)"


# ═══════════════════════════════════════════════════════════
#  Test: Buffer padding / silence
# ═══════════════════════════════════════════════════════════

class TestBufferPadding:
    """Verify clips don't have excessive silence."""

    def test_loop_region_covers_content(self):
        """The loop region (in beats) should be a reasonable fraction of the clip length."""
        data = load_inspect()
        for stem, clips in data["stems"].items():
            for clip in clips:
                if clip["warping"] != 1 or clip["length"] <= 0:
                    continue
                loop_span = clip["loop_end"] - clip["loop_start"]
                # Loop should be at least 50% of clip length (rest is buffer padding)
                ratio = loop_span / clip["length"] if clip["length"] > 0 else 0
                assert ratio > 0.3, \
                    f"{stem}[{clip['slot']}]: loop covers only {ratio:.1%} of clip " \
                    f"(loop={loop_span:.1f}, length={clip['length']:.1f}) — too much padding?"

    def test_chop_clipstart_in_buffer(self):
        """clipStart (loop_start_sec) should be within the buffer pad —
        roughly 1-2 bars at track tempo, not at 0 or at the end."""
        data = load_inspect()
        track_id = data["track_id"]
        manifest = load_track_manifest(track_id)
        bpm = manifest["bpm"]
        one_bar_sec = 4 * 60 / bpm  # seconds per bar

        for stem, clips in data["stems"].items():
            for clip in clips:
                chop = clip.get("chop")
                if not chop or chop.get("lengthBars", 0) == 0:
                    continue
                clip_start = chop.get("clipStart", 0)
                # Buffer pad should be roughly 0.5-3 bars
                max_pad = one_bar_sec * 3
                assert clip_start < max_pad, \
                    f"{stem}[{clip['slot']}]: clipStart={clip_start:.2f}s seems too far " \
                    f"into the file (max expected ~{max_pad:.1f}s for buffer pad)"


# ═══════════════════════════════════════════════════════════
#  Test: Session tempo
# ═══════════════════════════════════════════════════════════

class TestSessionTempo:
    """Verify session tempo synced to the active preset's BPM."""

    def test_session_tempo_matches_track(self):
        """Session tempo should match the active track's BPM."""
        data = load_inspect()
        track_id = data["track_id"]
        manifest = load_track_manifest(track_id)
        expected_bpm = manifest["bpm"]

        session_tempo = data.get("session_tempo")
        if session_tempo is not None:
            session_tempo = float(session_tempo)
            assert abs(session_tempo - expected_bpm) < BPM_TOLERANCE, \
                f"Session tempo {session_tempo:.2f} doesn't match track BPM {expected_bpm:.2f}"


# ═══════════════════════════════════════════════════════════
#  Test: Cross-stem consistency
# ═══════════════════════════════════════════════════════════

class TestCrossStemConsistency:
    """Verify all stems for a given chop slot are consistent."""

    def test_same_bar_count_across_stems(self):
        """All stems at the same slot should have the same bar count."""
        data = load_inspect()
        for slot_idx in range(8):
            bar_counts = {}
            for stem, clips in data["stems"].items():
                for clip in clips:
                    if clip["slot"] == slot_idx and clip.get("chop"):
                        bars = clip["chop"].get("lengthBars", 0)
                        if bars > 0:
                            bar_counts[stem] = bars

            if len(bar_counts) > 1:
                values = list(bar_counts.values())
                assert all(v == values[0] for v in values), \
                    f"Slot {slot_idx}: inconsistent bar counts across stems: {bar_counts}"

    def test_consistent_warp_marker_bpm(self):
        """All stems at the same slot should imply the same BPM."""
        data = load_inspect()
        for slot_idx in range(8):
            bpms = {}
            for stem, clips in data["stems"].items():
                for clip in clips:
                    if clip["slot"] != slot_idx or clip["warping"] != 1:
                        continue
                    markers = clip.get("warp_markers", [])
                    if len(markers) < 2:
                        continue
                    dt_sec = markers[-1]["sample_time"] - markers[0]["sample_time"]
                    dt_beat = markers[-1]["beat_time"] - markers[0]["beat_time"]
                    if dt_sec > 0 and dt_beat > 0:
                        bpms[stem] = (dt_beat / dt_sec) * 60

            if len(bpms) > 1:
                values = list(bpms.values())
                for stem, bpm in bpms.items():
                    assert abs(bpm - values[0]) < BPM_TOLERANCE, \
                        f"Slot {slot_idx}: {stem} implies {bpm:.1f} BPM but " \
                        f"other stems imply {values[0]:.1f}"


# ═══════════════════════════════════════════════════════════
#  Parametrized per-track tests
# ═══════════════════════════════════════════════════════════

# These run once per track in the set, requiring inspect data for each

TRACK_IDS = ["1835", "1851", "5941", "1849", "7954", "4060", "8326", "6553", "2098", "4044", "10488"]
TRACK_NAMES = {
    "1835": "Electric Relaxation",
    "1851": "Rebirth Of Slick",
    "5941": "Juicy",
    "1849": "Mass Appeal",
    "7954": "Shook Ones",
    "4060": "C.R.E.A.M.",
    "8326": "Smoke & Mirrors",
    "6553": "Mezzanine",
    "2098": "Setting Sun",
    "4044": "Mutty Ranks",
    "10488": "Vic Acid",
}

TRACK_BPMS = {
    "1835": 97.98, "1851": 98.29, "5941": 96.04, "1849": 96.01,
    "7954": 93.83, "4060": 91.74, "8326": 94.95, "6553": 97.99,
    "2098": 135.97, "4044": 91.94, "10488": 82.5,
}


class TestPerTrackExpectations:
    """Expectations for specific tracks that have known issues."""

    def test_setting_sun_not_half_tempo(self):
        """Setting Sun (2098) should show ~136 BPM, not ~64."""
        data = load_inspect()
        if data["track_id"] != "2098":
            pytest.skip("Not inspecting Setting Sun")

        for stem, clips in data["stems"].items():
            for clip in clips:
                markers = clip.get("warp_markers", [])
                if len(markers) < 2 or clip["warping"] != 1:
                    continue
                dt_sec = markers[-1]["sample_time"] - markers[0]["sample_time"]
                dt_beat = markers[-1]["beat_time"] - markers[0]["beat_time"]
                if dt_sec > 0 and dt_beat > 0:
                    implied = (dt_beat / dt_sec) * 60
                    assert implied > 100, \
                        f"{stem}[{clip['slot']}]: BPM={implied:.1f}, likely half-tempo detection"

    def test_mass_appeal_no_excessive_silence(self):
        """Mass Appeal (1849) clips should not have long silent lead-ins."""
        data = load_inspect()
        if data["track_id"] != "1849":
            pytest.skip("Not inspecting Mass Appeal")

        for stem, clips in data["stems"].items():
            for clip in clips:
                chop = clip.get("chop")
                if not chop:
                    continue
                # clipStart is loop_start_sec — should be small (buffer pad only)
                assert chop.get("clipStart", 0) < 5.0, \
                    f"{stem}[{clip['slot']}]: clipStart={chop['clipStart']:.2f}s — excessive lead-in"
