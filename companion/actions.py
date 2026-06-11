"""Companion action dispatcher — POST /action write path.

Proxies interactive commands to the loader (UDP 7422 / CC remote)
and AbletonOSC (127.0.0.1:11000). Persists scene/queue state locally.

Command sink is injectable for testing without Live.
"""
from __future__ import annotations
import json
import socket
import uuid
from pathlib import Path
from typing import Any, Callable

HERE = Path(__file__).resolve().parent
STATE_DIR = HERE / "state"

# ── Injectable command sink ────────────────────────────────────────
# Default sends real commands; tests inject a recording mock.

def _default_sink(command: str, args: dict) -> dict:
    """Send a command to the loader/Live. Returns {ok, ...}."""
    if command == "udp":
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.sendto(args["msg"].encode("utf-8"), ("127.0.0.1", 7422))
            sock.close()
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "error": str(e)}
    if command == "osc":
        try:
            from pythonosc.udp_client import SimpleUDPClient
            cli = SimpleUDPClient("127.0.0.1", 11000)
            cli.send_message(args["address"], args.get("osc_args", []))
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "error": str(e)}
    return {"ok": False, "error": f"unknown command: {command}"}


COMMAND_SINK: Callable = _default_sink


def set_command_sink(fn: Callable):
    global COMMAND_SINK
    COMMAND_SINK = fn


# ── Persistence helpers ────────────────────────────────────────────

def _scenes_path() -> Path:
    return STATE_DIR / "scenes.json"


def _queue_path() -> Path:
    return STATE_DIR / "queue.json"


def _read_scenes() -> list[dict]:
    p = _scenes_path()
    if p.exists():
        try:
            return json.loads(p.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return []


def _write_scenes(scenes: list[dict]):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    _scenes_path().write_text(json.dumps(scenes, indent=2), encoding="utf-8")


def _read_queue() -> list[dict]:
    p = _queue_path()
    if p.exists():
        try:
            return json.loads(p.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    return []


def _write_queue(queue: list[dict]):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    _queue_path().write_text(json.dumps(queue, indent=2), encoding="utf-8")


# ── Action handlers ────────────────────────────────────────────────

def handle_tag_scene(data: dict) -> dict:
    name = data.get("name")
    clips = data.get("clips")
    if not name or not isinstance(clips, list):
        return {"ok": False, "error": "tag_scene requires name (string) and clips (array)"}
    scene_id = f"scene-{uuid.uuid4().hex[:8]}"
    color = data.get("color")
    scenes = _read_scenes()
    scenes.append({"id": scene_id, "name": name, "color": color, "clips": clips})
    _write_scenes(scenes)
    return {"ok": True, "id": scene_id}


def handle_untag_scene(data: dict) -> dict:
    scene_id = data.get("id")
    if not scene_id:
        return {"ok": False, "error": "untag_scene requires id"}
    scenes = _read_scenes()
    before = len(scenes)
    scenes = [s for s in scenes if s.get("id") != scene_id]
    _write_scenes(scenes)
    removed = before - len(scenes)
    return {"ok": True, "removed": removed}


def handle_recall_scene(data: dict) -> dict:
    scene_id = data.get("id")
    if not scene_id:
        return {"ok": False, "error": "recall_scene requires id"}
    scenes = _read_scenes()
    scene = next((s for s in scenes if s.get("id") == scene_id), None)
    if not scene:
        return {"ok": False, "error": f"scene not found: {scene_id}"}
    # Emit fire commands for each clip via the sink
    for clip_ref in scene.get("clips", []):
        COMMAND_SINK("osc", {
            "address": "/live/clip/fire",
            "osc_args": [clip_ref],
        })
    return {"ok": True, "scene": scene["name"], "clips_fired": len(scene.get("clips", []))}


def handle_swap_ab(data: dict) -> dict:
    """Emit the loader swap-AB command."""
    return COMMAND_SINK("udp", {"msg": "swap_ab"})


def handle_queue_set(data: dict) -> dict:
    set_name = data.get("set_name")
    if not set_name:
        return {"ok": False, "error": "queue_set requires set_name"}
    queue = _read_queue()
    queue.append({"set_name": set_name, "queued_at": str(uuid.uuid4().hex[:8])})
    _write_queue(queue)
    return {"ok": True, "queue_length": len(queue)}


def handle_select_clip(data: dict) -> dict:
    deck = data.get("deck")
    stem = data.get("stem")
    chop = data.get("chop")
    if not all([deck, stem, chop is not None]):
        return {"ok": False, "error": "select_clip requires deck, stem, chop"}
    return COMMAND_SINK("osc", {
        "address": "/live/clip/fire",
        "osc_args": [f"{deck}:{stem}:{chop}"],
    })


# ── Arrangement action handlers (Phase 3) ─────────────────────────

ARRANGEMENTS_DIR = STATE_DIR / "arrangements"


def _arrangements_path(name: str) -> Path:
    safe = name.replace("/", "_").replace("..", "_")
    return ARRANGEMENTS_DIR / f"{safe}.arrangement.json"


def handle_place_pair(data: dict) -> dict:
    bar = data.get("timeline_bar")
    if bar is None:
        return {"ok": False, "error": "place_pair requires timeline_bar"}
    return COMMAND_SINK("udp", {"msg": f"place_pair {bar}"})


def handle_save_arrangement(data: dict) -> dict:
    name = data.get("name")
    if not name:
        return {"ok": False, "error": "save_arrangement requires name"}
    ARRANGEMENTS_DIR.mkdir(parents=True, exist_ok=True)
    # Read current arrangement state from sample or live
    arr_data = {"name": name, "saved_at": uuid.uuid4().hex[:8]}
    _arrangements_path(name).write_text(
        json.dumps(arr_data, indent=2), encoding="utf-8"
    )
    return {"ok": True, "path": str(_arrangements_path(name))}


def handle_load_arrangement(data: dict) -> dict:
    name = data.get("name")
    if not name:
        return {"ok": False, "error": "load_arrangement requires name"}
    p = _arrangements_path(name)
    if not p.exists():
        return {"ok": False, "error": f"arrangement not found: {name}"}
    return COMMAND_SINK("udp", {"msg": f"load_arrangement {p}"})


def handle_seek_bar(data: dict) -> dict:
    bar = data.get("bar")
    if bar is None:
        return {"ok": False, "error": "seek_bar requires bar"}
    return COMMAND_SINK("osc", {
        "address": "/live/song/set/current_song_time",
        "osc_args": [float(bar) * 4 * 60 / 120],  # approximate beat→sec
    })


# ── Dispatcher ─────────────────────────────────────────────────────

ACTION_HANDLERS = {
    "tag_scene": handle_tag_scene,
    "untag_scene": handle_untag_scene,
    "recall_scene": handle_recall_scene,
    "swap_ab": handle_swap_ab,
    "queue_set": handle_queue_set,
    "select_clip": handle_select_clip,
    "place_pair": handle_place_pair,
    "save_arrangement": handle_save_arrangement,
    "load_arrangement": handle_load_arrangement,
    "seek_bar": handle_seek_bar,
}


def dispatch_action(body: dict) -> dict:
    """Route an action request to the correct handler."""
    action_type = body.get("type")
    if not action_type:
        return {"ok": False, "error": "missing 'type' field"}
    handler = ACTION_HANDLERS.get(action_type)
    if not handler:
        return {"ok": False, "error": f"unknown action type: {action_type}"}
    try:
        return handler(body)
    except Exception as e:
        return {"ok": False, "error": str(e)}
