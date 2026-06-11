"""Tests for the Setforge contract schemas (L1).

Run:  cd m4l-devices && python3 -m pytest schemas/ -q
"""
from pathlib import Path
from validate import validate_file

EX = Path(__file__).resolve().parent / "examples"


# ── Set schema ─────────────────────────────────────────────────────

def test_real_set_validates():
    ok, name, errors = validate_file(EX / "hiphop_danceable.set.json")
    assert name == "set"
    assert ok, errors


def test_hiphop_v3_set_validates():
    ok, name, errors = validate_file(EX / "hiphop_v3.set.json")
    assert name == "set"
    assert ok, errors


def test_full_vocal_set_validates():
    ok, name, errors = validate_file(EX / "full_vocal.set.json")
    assert name == "set"
    assert ok, errors


def test_malformed_set_fails():
    ok, name, errors = validate_file(EX / "bad.set.json")
    assert name == "set"
    assert not ok
    joined = " | ".join(errors)
    assert "global_tempo" in joined
    assert "preset_bank_A" in joined


# ── Manifest schema ────────────────────────────────────────────────

def test_real_manifest_validates():
    ok, name, errors = validate_file(EX / "hiphop_danceable.manifest.json")
    assert name == "manifest"
    assert ok, errors


def test_hiphop_v3_manifest_validates():
    ok, name, errors = validate_file(EX / "hiphop_v3.manifest.json")
    assert name == "manifest"
    assert ok, errors


def test_varying_track_manifest_validates():
    ok, name, errors = validate_file(EX / "varying_track.manifest.json")
    assert name == "manifest"
    assert ok, errors


def test_invalid_bpm_manifest_fails():
    """The schema's bpm > 0 constraint catches zero-BPM tracks."""
    ok, name, errors = validate_file(EX / "invalid_bpm.manifest.json")
    assert name == "manifest"
    assert not ok
    joined = " | ".join(errors)
    assert "bpm" in joined.lower()


# ── Arrangement schema ─────────────────────────────────────────────

def test_arrangement_validates():
    ok, name, errors = validate_file(EX / "breaks-n-beats.arrangement.json")
    assert name == "arrangement"
    assert ok, errors


def test_dual_deck_arrangement_validates():
    ok, name, errors = validate_file(EX / "dual-deck.arrangement.json")
    assert name == "arrangement"
    assert ok, errors


# ── Calib override schema ──────────────────────────────────────────

def test_calib_override_validates():
    ok, name, errors = validate_file(EX / "sample.calib_override.json")
    assert name == "calib_override"
    assert ok, errors


# ── State (companion) schema ───────────────────────────────────────

COMPANION = Path(__file__).resolve().parent.parent / "companion"


def test_state_v2_validates():
    ok, name, errors = validate_file(COMPANION / "sample_state.json")
    assert name == "state"
    assert ok, errors


def test_malformed_state_fails():
    ok, name, errors = validate_file(EX / "bad.state.json")
    assert name == "state"
    assert not ok
    joined = " | ".join(errors)
    # Should fail on missing bpm in set, missing B in decks, missing bankB in presets, etc.
    assert "bpm" in joined.lower() or "B" in joined or "bankB" in joined
