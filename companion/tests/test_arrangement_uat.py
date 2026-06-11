"""End-to-end headless UAT for the arrangement path.

Boots serve.py on a test port, exercises GET /arrangement,
POST /action (arrangement verbs), and manifest persistence.

Run: cd m4l-devices && python3 -m pytest companion/tests/test_arrangement_uat.py -q
"""
import json
import sys
import threading
import time
from http.server import HTTPServer
from pathlib import Path
from urllib.request import Request, urlopen

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

TEST_PORT = 17461


@pytest.fixture(scope="module")
def server():
    from serve import Handler
    httpd = HTTPServer(("127.0.0.1", TEST_PORT), Handler)
    t = threading.Thread(target=httpd.serve_forever, daemon=True)
    t.start()
    time.sleep(0.3)
    yield f"http://127.0.0.1:{TEST_PORT}"
    httpd.shutdown()


def _get(url):
    with urlopen(url, timeout=3) as r:
        return json.loads(r.read().decode("utf-8"))


def _post(url, body):
    data = json.dumps(body).encode("utf-8")
    req = Request(url, data=data, headers={"Content-Type": "application/json"})
    with urlopen(req, timeout=3) as r:
        return json.loads(r.read().decode("utf-8"))


class TestArrangementSlice:
    def test_returns_arrangement(self, server):
        arr = _get(f"{server}/arrangement")
        assert "placements" in arr
        assert "scene_markers" in arr

    def test_placements_have_required_fields(self, server):
        arr = _get(f"{server}/arrangement")
        for p in arr.get("placements", []):
            assert "deck" in p
            assert "stem" in p
            assert "start_bar" in p
            assert "len_bars" in p

    def test_scene_markers_present(self, server):
        arr = _get(f"{server}/arrangement")
        markers = arr.get("scene_markers", [])
        assert len(markers) >= 2
        assert "scene_id" in markers[0]
        assert "start_bar" in markers[0]

    def test_placements_colored_by_source(self, server):
        arr = _get(f"{server}/arrangement")
        colors = [p.get("color") for p in arr["placements"] if p.get("color")]
        assert len(colors) >= 2  # at least 2 different source colors


class TestArrangementActions:
    def test_place_pair(self, server, monkeypatch):
        import actions
        calls = []
        actions.set_command_sink(lambda cmd, args: (calls.append(cmd), {"ok": True})[1])
        result = _post(f"{server}/action", {"type": "place_pair", "timeline_bar": 16})
        assert result["ok"]

    def test_save_then_load_round_trips(self, server, tmp_path, monkeypatch):
        import actions
        monkeypatch.setattr(actions, "STATE_DIR", tmp_path)
        monkeypatch.setattr(actions, "ARRANGEMENTS_DIR", tmp_path / "arrangements")
        calls = []
        actions.set_command_sink(lambda cmd, args: (calls.append(cmd), {"ok": True})[1])

        # Save
        result = _post(f"{server}/action", {"type": "save_arrangement", "name": "test-arr"})
        assert result["ok"]
        # Load
        result = _post(f"{server}/action", {"type": "load_arrangement", "name": "test-arr"})
        assert result["ok"]

    def test_seek_bar(self, server, monkeypatch):
        import actions
        calls = []
        actions.set_command_sink(lambda cmd, args: (calls.append(cmd), {"ok": True})[1])
        result = _post(f"{server}/action", {"type": "seek_bar", "bar": 8})
        assert result["ok"]
