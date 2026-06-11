"""Tests for arrangement /action verbs (Phase 3).

Run: cd m4l-devices && python3 -m pytest companion/tests/test_arrangement_action.py -q
"""
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import actions


@pytest.fixture(autouse=True)
def isolated(tmp_path, monkeypatch):
    monkeypatch.setattr(actions, "STATE_DIR", tmp_path)
    monkeypatch.setattr(actions, "ARRANGEMENTS_DIR", tmp_path / "arrangements")
    calls = []
    actions.set_command_sink(lambda cmd, args: (calls.append({"cmd": cmd, "args": args}), {"ok": True})[1])
    yield {"calls": calls, "state_dir": tmp_path}


class TestPlacePair:
    def test_emits_udp_command(self, isolated):
        result = actions.handle_place_pair({"timeline_bar": 16})
        assert result["ok"]
        assert isolated["calls"][-1]["cmd"] == "udp"
        assert "place_pair 16" in isolated["calls"][-1]["args"]["msg"]

    def test_rejects_missing_bar(self):
        result = actions.handle_place_pair({})
        assert not result["ok"]


class TestSaveArrangement:
    def test_saves_to_file(self, isolated):
        result = actions.handle_save_arrangement({"name": "Friday Set"})
        assert result["ok"]
        p = isolated["state_dir"] / "arrangements" / "Friday Set.arrangement.json"
        assert p.exists()
        data = json.loads(p.read_text())
        assert data["name"] == "Friday Set"

    def test_rejects_missing_name(self):
        result = actions.handle_save_arrangement({})
        assert not result["ok"]


class TestLoadArrangement:
    def test_emits_udp_load(self, isolated):
        # Save first
        actions.handle_save_arrangement({"name": "test"})
        result = actions.handle_load_arrangement({"name": "test"})
        assert result["ok"]
        assert "load_arrangement" in isolated["calls"][-1]["args"]["msg"]

    def test_rejects_unknown(self, isolated):
        result = actions.handle_load_arrangement({"name": "nonexistent"})
        assert not result["ok"]

    def test_rejects_missing_name(self):
        result = actions.handle_load_arrangement({})
        assert not result["ok"]


class TestSeekBar:
    def test_emits_osc_seek(self, isolated):
        result = actions.handle_seek_bar({"bar": 8})
        assert result["ok"]
        assert isolated["calls"][-1]["cmd"] == "osc"

    def test_rejects_missing_bar(self):
        result = actions.handle_seek_bar({})
        assert not result["ok"]
