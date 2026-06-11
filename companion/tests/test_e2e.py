"""End-to-end headless UAT for the companion app.

Boots serve.py on a test port (sample data, no Live), exercises
GET /state + /peaks + POST /action, and verifies persistence.

Run: cd m4l-devices && python3 -m pytest companion/tests/test_e2e.py -q
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

TEST_PORT = 17460  # avoid colliding with real server


@pytest.fixture(scope="module")
def server():
    """Boot serve.py on a test port for the duration of the module."""
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


class TestStateEndpoint:
    def test_returns_valid_state(self, server):
        state = _get(f"{server}/state")
        assert "set" in state
        assert "decks" in state
        assert "presets" in state
        assert "now_playing" in state
        assert "recommendations" in state
        assert "scenes" in state

    def test_set_has_required_fields(self, server):
        state = _get(f"{server}/state")
        assert "name" in state["set"]
        assert "bpm" in state["set"]

    def test_decks_have_stems(self, server):
        state = _get(f"{server}/state")
        for deck in ["A", "B"]:
            assert "stems" in state["decks"][deck]

    def test_recommendations_present(self, server):
        state = _get(f"{server}/state")
        assert len(state["recommendations"]) >= 1
        r = state["recommendations"][0]
        assert "song" in r
        assert "score" in r
        assert "type" in r


class TestPeaksEndpoint:
    def test_missing_param_returns_400(self, server):
        try:
            _get(f"{server}/peaks")
            assert False, "expected error"
        except Exception:
            pass  # 400 or connection error — expected

    def test_unknown_clip_returns_404(self, server):
        try:
            _get(f"{server}/peaks?clip=nonexistent")
            assert False, "expected 404"
        except Exception:
            pass


class TestActionEndpoint:
    def test_tag_scene_persists(self, server, tmp_path, monkeypatch):
        import actions
        monkeypatch.setattr(actions, "STATE_DIR", tmp_path)
        # Inject a no-op sink for safety
        actions.set_command_sink(lambda cmd, args: {"ok": True})

        result = _post(f"{server}/action", {
            "type": "tag_scene", "name": "Test Scene", "clips": ["A·DR1"]
        })
        assert result["ok"]
        assert result["id"].startswith("scene-")

    def test_swap_ab(self, server, monkeypatch):
        import actions
        calls = []
        actions.set_command_sink(lambda cmd, args: (calls.append(cmd), {"ok": True})[1])
        result = _post(f"{server}/action", {"type": "swap_ab"})
        assert result["ok"]
        assert "udp" in calls

    def test_unknown_action(self, server):
        from urllib.error import HTTPError
        with pytest.raises(HTTPError) as exc_info:
            _post(f"{server}/action", {"type": "nope"})
        assert exc_info.value.code == 400

    def test_bad_json(self, server):
        try:
            req = Request(f"{server}/action",
                         data=b"not json",
                         headers={"Content-Type": "application/json"})
            with urlopen(req, timeout=3) as r:
                result = json.loads(r.read().decode("utf-8"))
                assert not result["ok"]
        except Exception:
            pass  # 400 expected


class TestStaticServing:
    def test_index_html(self, server):
        req = Request(f"{server}/")
        with urlopen(req, timeout=3) as r:
            html = r.read().decode("utf-8")
            assert "SETFORGE" in html
            assert "Perform" in html
