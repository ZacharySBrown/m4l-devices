"""Setforge companion-app state endpoint (read-only).

GET /state -> the companion-app state JSON. Contract: state.schema.json + contract.md.
Merges live data from the loader inspect + AbletonOSC + taste DB when available;
falls back to sample_state.json when Live isn't running.

Run:   python3 companion/serve.py [--port 7460]
Test:  curl -s localhost:7460/state | python3 -m json.tool
"""
from __future__ import annotations
import argparse
import json
import os
import sqlite3
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
SAMPLE = HERE / "sample_state.json"
INSPECT_PATH = Path("/tmp/setforge_inspect.json")
LAST_SET_PATH = Path("/tmp/setforge_last_set.txt")

# Taste engine
TASTE_DIR = Path.home() / "zacharysbrown" / "taste"
TASTE_DB = TASTE_DIR / "setforge.db"

# Stable source-legend palette (8 colors, one per preset slot per bank)
LEGEND_PALETTE = [
    "#F5A623", "#FF7A3D", "#E85B5B", "#B058CF",
    "#8C7BFF", "#34C8E8", "#3DCC91", "#8BC34A",
]

STEM_NAMES = ("drums", "bass", "other", "vox")


# ── Live data helpers ──────────────────────────────────────────────

def _read_inspect() -> dict | None:
    """Read the loader's inspect JSON if it exists and is fresh (<30s)."""
    if not INSPECT_PATH.exists():
        return None
    try:
        age = time.time() - INSPECT_PATH.stat().st_mtime
        if age > 30:
            return None
        with open(INSPECT_PATH) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


def _osc_ask(address: str, *args, timeout: float = 1.5) -> tuple | None:
    """One-shot OSC ask (no persistent server). Returns reply args or None."""
    try:
        import queue
        import threading
        from pythonosc.dispatcher import Dispatcher
        from pythonosc.osc_server import ThreadingOSCUDPServer
        from pythonosc.udp_client import SimpleUDPClient

        replies: "queue.Queue[tuple]" = queue.Queue()
        d = Dispatcher()
        d.set_default_handler(lambda addr, *a: replies.put((addr, a)))
        srv = ThreadingOSCUDPServer(("127.0.0.1", 11001), d)
        t = threading.Thread(target=srv.serve_forever, daemon=True)
        t.start()
        cli = SimpleUDPClient("127.0.0.1", 11000)
        if args:
            cli.send_message(address, list(args))
        else:
            cli.send_message(address, [])
        deadline = time.time() + timeout
        result = None
        while time.time() < deadline:
            try:
                ra, rv = replies.get(timeout=0.1)
                if ra == address:
                    result = rv
                    break
            except queue.Empty:
                continue
        srv.shutdown()
        srv.server_close()
        return result
    except Exception:
        return None


def _osc_transport() -> dict:
    """Query AbletonOSC for transport state."""
    info = {"bpm": 120.0, "is_playing": False}
    try:
        r = _osc_ask("/live/song/get/tempo")
        if r:
            info["bpm"] = round(r[0], 2)
        r2 = _osc_ask("/live/song/get/is_playing")
        if r2:
            info["is_playing"] = bool(r2[0])
    except Exception:
        pass
    return info


def _osc_clip_playing(track: int, num_slots: int = 8) -> int | None:
    """Return the slot index of the playing/triggered clip, or None."""
    for slot in range(num_slots):
        try:
            r = _osc_ask("/live/clip/get/is_playing", track, slot)
            if r and r[2]:
                return slot
            r2 = _osc_ask("/live/clip/get/is_triggered", track, slot)
            if r2 and r2[2]:
                return slot
        except Exception:
            continue
    return None


def _track_metadata(conn: sqlite3.Connection, track_id: str) -> dict:
    """Look up title/artist/key from taste DB."""
    try:
        row = conn.execute(
            "SELECT title, artist, camelot FROM tracks WHERE id = ?",
            (int(track_id),)
        ).fetchone()
        if row:
            return {"title": row[0], "artist": row[1], "key": row[2]}
    except (ValueError, TypeError):
        pass
    return {"title": None, "artist": None, "key": None}


def _get_recommendations(conn: sqlite3.Connection,
                         seed_ids: list[int]) -> list[dict]:
    """Get taste-graph recommendations for the current deck songs."""
    if not seed_ids:
        return []
    try:
        sys.path.insert(0, str(TASTE_DIR))
        from taste import taste_recommend
        recs = taste_recommend(conn, seed_ids, limit=8)
        out = []
        for r in recs:
            score_raw = r.get("score", 0)
            score = int(score_raw * 100) if score_raw <= 1.0 else int(score_raw)
            why = r.get("why", {})
            # congruent if high cooccurrence, spicy if mainly adjacency-driven
            rec_type = "congruent" if why.get("cooccur", 0) > 0.6 else "spicy"
            out.append({
                "song": r.get("title", "?"),
                "artist": r.get("artist", "?"),
                "bpm": r.get("tempo") or 0,
                "key": r.get("camelot") or "?",
                "score": score,
                "type": rec_type,
                "action": "cue next",
            })
        return out
    except Exception:
        return []


# ── Main state builder ─────────────────────────────────────────────

def _build_live_state() -> dict | None:
    """Build companion state from live data. Returns None if Live is down."""
    inspect = _read_inspect()
    if not inspect:
        return None

    # Open taste DB for metadata
    conn = None
    if TASTE_DB.exists():
        try:
            conn = sqlite3.connect(str(TASTE_DB))
            conn.row_factory = sqlite3.Row
        except Exception:
            conn = None

    # Transport
    transport = _osc_transport()

    # Read set name from last_set.txt
    set_name = "Unknown Set"
    try:
        if LAST_SET_PATH.exists():
            raw = LAST_SET_PATH.read_text().strip()
            # Extract set name from path: .../hiphop_danceable_v2/hiphop_danceable.set.json
            set_name = Path(raw).stem.replace(".set", "").replace("_", " ").title()
    except Exception:
        pass

    # Active preset info
    active_idx = inspect.get("preset_index", 0)
    active_set = inspect.get("clip_set", "A")  # "A" or "B"
    active_track_id = str(inspect.get("track_id", ""))
    active_bpm = inspect.get("track_bpm") or transport["bpm"]

    # Get metadata from taste DB
    meta = _track_metadata(conn, active_track_id) if conn else {}

    # Build stem info from inspect
    stems_data = inspect.get("stems", {})
    active_deck = active_set  # "A" or "B"

    # Determine preset label: A1-A8 or B1-B8
    if active_idx < 8:
        preset_label = f"A{active_idx + 1}"
    else:
        preset_label = f"B{active_idx - 8 + 1}"

    # Build deck stems
    deck_stems = {}
    now_playing = []
    for stem_name in STEM_NAMES:
        stem_clips = stems_data.get(stem_name, [])
        loaded_chops = len(stem_clips)

        # Check if any clip is playing via OSC (need track index)
        live_chop = None
        progress = 0

        deck_stems[stem_name] = {
            "source": preset_label,
            "song": meta.get("title"),
            "artist": meta.get("artist"),
            "key": meta.get("key"),
            "loaded_chops": loaded_chops,
            "live_chop": live_chop,
            "progress": progress,
            "bars_left": 0,
        }

    # Build the active deck
    active_deck_data = {"stems": deck_stems}

    # Build the other deck (empty if not in dual-song)
    empty_stems = {}
    for stem_name in STEM_NAMES:
        empty_stems[stem_name] = {
            "source": None,
            "song": None,
            "artist": None,
            "key": None,
            "loaded_chops": 0,
            "live_chop": None,
            "progress": 0,
            "bars_left": 0,
        }
    other_deck_data = {"stems": empty_stems}

    if active_set == "A":
        decks = {"A": active_deck_data, "B": other_deck_data}
    else:
        decks = {"A": other_deck_data, "B": active_deck_data}

    # Build presets (8 per bank)
    bank_a = []
    bank_b = []
    # The active preset gets sourcing + color
    for i in range(8):
        pid = f"A{i + 1}"
        p = {"id": pid, "song": None, "artist": None, "key": None,
             "sourcing": None, "color": None}
        if active_set == "A" and active_idx == i:
            p["song"] = meta.get("title")
            p["artist"] = meta.get("artist")
            p["key"] = meta.get("key")
            p["sourcing"] = list(STEM_NAMES)
            p["color"] = LEGEND_PALETTE[i]
        bank_a.append(p)

    for i in range(8):
        pid = f"B{i + 1}"
        p = {"id": pid, "song": None, "artist": None, "key": None,
             "sourcing": None, "color": None}
        if active_set == "B" and (active_idx - 8) == i:
            p["song"] = meta.get("title")
            p["artist"] = meta.get("artist")
            p["key"] = meta.get("key")
            p["sourcing"] = list(STEM_NAMES)
            p["color"] = LEGEND_PALETTE[i]
        bank_b.append(p)

    # Recommendations from taste engine
    seed_ids = []
    try:
        tid = int(active_track_id)
        seed_ids.append(tid)
    except (ValueError, TypeError):
        pass
    recommendations = _get_recommendations(conn, seed_ids) if conn else []

    if conn:
        conn.close()

    return {
        "set": {
            "name": set_name,
            "bpm": round(active_bpm, 2),
            "bar": "1.1.1",
        },
        "decks": decks,
        "presets": {"bankA": bank_a, "bankB": bank_b},
        "now_playing": now_playing,
        "recommendations": recommendations,
        "scenes": [],
    }


def _resolve_clip_wav(clip_id: str) -> str | None:
    """Resolve a clip_id (e.g. 'sf:A1:drums:2') to a WAV path via inspect data."""
    inspect = _read_inspect()
    if not inspect:
        return None
    # clip_id format: "sf:<trackId>:<stem>:<chop_index>"
    parts = clip_id.split(":")
    if len(parts) < 4 or parts[0] != "sf":
        return None
    stem_name = parts[2]
    try:
        chop_idx = int(parts[3])
    except (ValueError, IndexError):
        return None
    stems = inspect.get("stems", {})
    stem_clips = stems.get(stem_name, [])
    for clip in stem_clips:
        if clip.get("slot") == chop_idx:
            chop = clip.get("chop", {})
            return chop.get("stemPath")
    return None


def get_state() -> dict:
    """Return the companion state. Live data when available, sample fallback."""
    live = _build_live_state()
    if live is not None:
        return live
    return json.loads(SAMPLE.read_text(encoding="utf-8"))


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: dict) -> None:
        payload = json.dumps(body).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    CONTENT_TYPES = {
        ".html": "text/html", ".css": "text/css", ".js": "application/javascript",
        ".json": "application/json", ".svg": "image/svg+xml", ".png": "image/png",
    }
    APP_DIR = HERE / "app"

    def do_GET(self):  # noqa: N802
        path = self.path.split("?")[0]
        if path == "/state" or path == "/state/":
            self._send(200, get_state())
        elif path.startswith("/peaks"):
            self._handle_peaks()
        elif path == "/" or path == "":
            self._serve_file("index.html")
        elif path.startswith("/") and not path.startswith("/action"):
            self._serve_file(path.lstrip("/"))
        else:
            self._send(404, {"error": "not found", "try": "/state"})

    def _serve_file(self, rel_path: str):
        """Serve a static file from app/."""
        fp = (self.APP_DIR / rel_path).resolve()
        # Security: ensure it's within APP_DIR
        try:
            fp.relative_to(self.APP_DIR.resolve())
        except ValueError:
            self._send(403, {"error": "forbidden"})
            return
        if not fp.is_file():
            self._send(404, {"error": f"not found: {rel_path}"})
            return
        ct = self.CONTENT_TYPES.get(fp.suffix, "application/octet-stream")
        data = fp.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(data)

    def _handle_peaks(self):
        """GET /peaks?clip=<clip_id> → waveform peaks JSON."""
        from urllib.parse import urlparse, parse_qs
        from peaks_gen import get_peaks_cached

        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        clip_id = params.get("clip", [None])[0]
        if not clip_id:
            self._send(400, {"error": "missing ?clip= parameter"})
            return

        # Resolve clip_id → WAV path from the inspect data
        wav_path = _resolve_clip_wav(clip_id)
        if not wav_path:
            self._send(404, {"error": f"clip not found: {clip_id}"})
            return

        data = get_peaks_cached(clip_id, wav_path)
        if data is None:
            self._send(404, {"error": f"could not generate peaks for {clip_id}"})
            return
        self._send(200, data)

    def do_POST(self):  # noqa: N802
        if self.path.rstrip("/") == "/action":
            self._handle_action()
        else:
            self._send(404, {"error": "not found", "try": "POST /action"})

    def _handle_action(self):
        from actions import dispatch_action
        try:
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length)
            body = json.loads(raw.decode("utf-8"))
        except (json.JSONDecodeError, ValueError):
            self._send(400, {"ok": False, "error": "invalid JSON body"})
            return
        result = dispatch_action(body)
        code = 200 if result.get("ok") else 400
        self._send(code, result)

    def log_message(self, *args):  # quiet
        pass


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=7460)
    args = ap.parse_args(argv)
    print(f"companion state endpoint → http://127.0.0.1:{args.port}/state")
    HTTPServer(("127.0.0.1", args.port), Handler).serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
