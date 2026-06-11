"""Tests for the Setforge contract schemas (L1).

Run:  cd m4l-devices && python3 -m pytest schemas/ -q
"""
from pathlib import Path
from validate import validate_file  # same dir

EX = Path(__file__).resolve().parent / "examples"


def test_real_set_validates():
    ok, name, errors = validate_file(EX / "hiphop_danceable.set.json")
    assert name == "set"
    assert ok, errors


def test_real_manifest_validates():
    ok, name, errors = validate_file(EX / "hiphop_danceable.manifest.json")
    assert name == "manifest"
    assert ok, errors


def test_malformed_set_fails():
    ok, name, errors = validate_file(EX / "bad.set.json")
    assert name == "set"
    assert not ok
    # must flag the missing global_tempo and reject the bank slot missing track_id
    joined = " | ".join(errors)
    assert "global_tempo" in joined
    assert "preset_bank_A" in joined
