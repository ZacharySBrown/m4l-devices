"""Tests for the POST /action write path.

Run: cd m4l-devices && python3 -m pytest companion/tests/test_action.py -q
"""
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import actions


@pytest.fixture(autouse=True)
def isolated_state(tmp_path, monkeypatch):
    """Redirect scene/queue persistence to a tmp dir."""
    monkeypatch.setattr(actions, "STATE_DIR", tmp_path)
    # Install a recording mock sink
    calls = []
    def mock_sink(command, args):
        calls.append({"command": command, "args": args})
        return {"ok": True}
    actions.set_command_sink(mock_sink)
    yield {"calls": calls, "state_dir": tmp_path}


class TestTagScene:
    def test_creates_scene_with_id(self, isolated_state):
        result = actions.handle_tag_scene({"name": "Drop", "clips": ["A·DR1", "B·VX3"]})
        assert result["ok"]
        assert result["id"].startswith("scene-")

    def test_persists_to_scenes_json(self, isolated_state):
        actions.handle_tag_scene({"name": "Drop", "clips": ["A·DR1"]})
        scenes = json.loads((isolated_state["state_dir"] / "scenes.json").read_text())
        assert len(scenes) == 1
        assert scenes[0]["name"] == "Drop"

    def test_rejects_missing_name(self):
        result = actions.handle_tag_scene({"clips": ["A·DR1"]})
        assert not result["ok"]

    def test_rejects_missing_clips(self):
        result = actions.handle_tag_scene({"name": "Drop"})
        assert not result["ok"]


class TestUntagScene:
    def test_removes_scene_by_id(self, isolated_state):
        r1 = actions.handle_tag_scene({"name": "A", "clips": ["x"]})
        r2 = actions.handle_tag_scene({"name": "B", "clips": ["y"]})
        result = actions.handle_untag_scene({"id": r1["id"]})
        assert result["ok"]
        assert result["removed"] == 1
        scenes = json.loads((isolated_state["state_dir"] / "scenes.json").read_text())
        assert len(scenes) == 1
        assert scenes[0]["name"] == "B"

    def test_rejects_missing_id(self):
        result = actions.handle_untag_scene({})
        assert not result["ok"]


class TestRecallScene:
    def test_fires_clips_via_sink(self, isolated_state):
        r = actions.handle_tag_scene({"name": "Drop", "clips": ["A·DR1", "B·VX3"]})
        calls = isolated_state["calls"]
        calls.clear()
        result = actions.handle_recall_scene({"id": r["id"]})
        assert result["ok"]
        assert result["clips_fired"] == 2
        assert len(calls) == 2
        assert calls[0]["command"] == "osc"

    def test_rejects_unknown_scene(self, isolated_state):
        result = actions.handle_recall_scene({"id": "nonexistent"})
        assert not result["ok"]


class TestSwapAb:
    def test_emits_udp_command(self, isolated_state):
        result = actions.handle_swap_ab({})
        assert result["ok"]
        calls = isolated_state["calls"]
        assert calls[-1]["command"] == "udp"
        assert calls[-1]["args"]["msg"] == "swap_ab"


class TestQueueSet:
    def test_appends_to_queue(self, isolated_state):
        actions.handle_queue_set({"set_name": "Set 2"})
        actions.handle_queue_set({"set_name": "Set 3"})
        queue = json.loads((isolated_state["state_dir"] / "queue.json").read_text())
        assert len(queue) == 2
        assert queue[0]["set_name"] == "Set 2"

    def test_rejects_missing_name(self):
        result = actions.handle_queue_set({})
        assert not result["ok"]


class TestSelectClip:
    def test_emits_osc_fire(self, isolated_state):
        result = actions.handle_select_clip({"deck": "A", "stem": "drums", "chop": 2})
        assert result["ok"]
        calls = isolated_state["calls"]
        assert calls[-1]["command"] == "osc"
        assert "A:drums:2" in calls[-1]["args"]["osc_args"][0]

    def test_rejects_missing_fields(self):
        result = actions.handle_select_clip({"deck": "A"})
        assert not result["ok"]


class TestDispatcher:
    def test_unknown_type(self):
        result = actions.dispatch_action({"type": "destroy_everything"})
        assert not result["ok"]
        assert "unknown" in result["error"]

    def test_missing_type(self):
        result = actions.dispatch_action({})
        assert not result["ok"]
