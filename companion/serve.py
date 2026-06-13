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

# Taste engine — use env vars, fall back to canonical paths
TASTE_DB = Path(os.environ.get("SETFORGE_DB",
                str(Path.home() / ".cache" / "setforge" / "db" / "setforge.db")))
TASTE_DIR = Path(os.environ.get("TASTE_REPO",
                 str(Path.home() / "SETFORGE_TEST" / "taste")))

# Stable source-legend palette (8 colors, one per preset slot per bank)
LEGEND_PALETTE = [
    "#F5A623", "#FF7A3D", "#E85B5B", "#B058CF",
    "#8C7BFF", "#34C8E8", "#3DCC91", "#8BC34A",
]

STEM_NAMES = ("drums", "bass", "other", "vox")


# ── Live data helpers ──────────────────────────────────────────────

def _read_inspect() -> dict | None:
    """Read the loader's inspect JSON if it exists and is fresh (<5min)."""
    if not INSPECT_PATH.exists():
        return None
    try:
        age = time.time() - INSPECT_PATH.stat().st_mtime
        if age > 300:
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

def _load_set_manifest() -> tuple[dict | None, dict | None]:
    """Load the set.json and manifest.json from the last loaded set path."""
    try:
        if not LAST_SET_PATH.exists():
            return None, None
        set_path = Path(LAST_SET_PATH.read_text().strip())
        if not set_path.exists():
            return None, None
        with open(set_path) as f:
            set_data = json.load(f)
        manifest_path = set_path.parent / f"{set_data['name']}.manifest.json"
        manifest = None
        if manifest_path.exists():
            with open(manifest_path) as f:
                manifest = json.load(f)
        return set_data, manifest
    except Exception:
        return None, None


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

    # Load set + manifest for all-preset metadata
    set_data, manifest = _load_set_manifest()

    # Read set name
    set_name = "Unknown Set"
    if set_data:
        set_name = set_data.get("name", "Unknown Set").replace("_", " ").title()
    elif LAST_SET_PATH.exists():
        try:
            raw = LAST_SET_PATH.read_text().strip()
            set_name = Path(raw).stem.replace(".set", "").replace("_", " ").title()
        except Exception:
            pass

    # Active preset info
    active_idx = inspect.get("preset_index", 0)
    active_set = inspect.get("clip_set", "A")  # "A" or "B"
    active_track_id = str(inspect.get("track_id", ""))
    active_bpm = inspect.get("track_bpm") or transport["bpm"]

    # Build a track_id → metadata lookup from the manifest + DB
    setlist = set_data.get("setlist", []) if set_data else []
    track_meta_cache = {}
    for tid_str in setlist:
        if conn:
            track_meta_cache[tid_str] = _track_metadata(conn, tid_str)

    active_meta = track_meta_cache.get(active_track_id,
                    _track_metadata(conn, active_track_id) if conn else {})

    # Build stem info from inspect
    stems_data = inspect.get("stems", {})

    # Determine preset label: A1-A8 or B1-B8
    if active_idx < 8:
        preset_label = f"A{active_idx + 1}"
    else:
        preset_label = f"B{active_idx - 8 + 1}"

    # Build deck stems with clip_id, peaks_ref, chop details, and now_playing
    deck_stems = {}
    now_playing = []

    # Also load manifest for chop labels
    manifest_chops = {}
    if manifest:
        for mt in manifest.get("tracks", []):
            if str(mt.get("id", "")) == active_track_id:
                for sn in STEM_NAMES:
                    sd = mt.get("stems", {}).get(sn, {})
                    manifest_chops[sn] = sd.get("chops", [])
                break

    for stem_name in STEM_NAMES:
        stem_clips = stems_data.get(stem_name, [])
        loaded_chops = len(stem_clips)

        # Build clip_id from first clip (for waveform peaks)
        clip_id = f"sf:{active_track_id}:{stem_name}:0" if loaded_chops > 0 else None
        peaks_ref = f"/peaks?clip={clip_id}" if clip_id else None

        # Build chop list with labels from manifest
        m_chops = manifest_chops.get(stem_name, [])
        chop_details = []
        for ci, clip in enumerate(stem_clips):
            chop = clip.get("chop", {})
            label = chop.get("label", "")
            kind = chop.get("kind", "")
            # Fall back to manifest chop data
            if not label and ci < len(m_chops):
                label = m_chops[ci].get("label", f"chop {ci}")
                kind = m_chops[ci].get("kind", "")
            length_beats = clip.get("length", 0)
            bars = round(length_beats / 4) if length_beats else 0
            chop_details.append({
                "idx": ci, "label": label or f"chop {ci}",
                "kind": kind, "bars": bars,
                "clip_id": f"sf:{active_track_id}:{stem_name}:{ci}",
            })

        stem_entry = {
            "source": preset_label,
            "song": active_meta.get("title"),
            "artist": active_meta.get("artist"),
            "key": active_meta.get("key"),
            "loaded_chops": loaded_chops,
            "live_chop": None,
            "progress": 0,
            "bars_left": 0,
            "clip_id": clip_id,
            "peaks_ref": peaks_ref,
            "chops": chop_details,
        }
        deck_stems[stem_name] = stem_entry

        # Add to now_playing (show all loaded stems for the active preset)
        if loaded_chops > 0:
            now_playing.append({
                "deck": active_set,
                "stem": stem_name,
                "source": preset_label,
                "progress": 0,
                "peaks_ref": peaks_ref,
            })

    # Build the active deck
    active_deck_data = {"stems": deck_stems}

    # Build the other deck (empty if not in dual-song)
    empty_stem = {"source": None, "song": None, "artist": None, "key": None,
                  "loaded_chops": 0, "live_chop": None, "progress": 0,
                  "bars_left": 0, "clip_id": None, "peaks_ref": None}
    other_deck_data = {"stems": {s: dict(empty_stem) for s in STEM_NAMES}}

    if active_set == "A":
        decks = {"A": active_deck_data, "B": other_deck_data}
    else:
        decks = {"A": other_deck_data, "B": active_deck_data}

    # Build presets — populate ALL from setlist, highlight active
    bank_a = []
    bank_b = []
    for i in range(8):
        pid = f"A{i + 1}"
        tid_str = setlist[i] if i < len(setlist) else None
        meta = track_meta_cache.get(tid_str, {}) if tid_str else {}
        is_active = (active_set == "A" and active_idx == i)
        bank_a.append({
            "id": pid,
            "song": meta.get("title"),
            "artist": meta.get("artist"),
            "key": meta.get("key"),
            "sourcing": list(STEM_NAMES) if is_active else None,
            "color": LEGEND_PALETTE[i] if (meta.get("title") or is_active) else None,
        })

    for i in range(8):
        pid = f"B{i + 1}"
        si = 8 + i
        tid_str = setlist[si] if si < len(setlist) else None
        meta = track_meta_cache.get(tid_str, {}) if tid_str else {}
        is_active = (active_set == "B" and active_idx == si)
        bank_b.append({
            "id": pid,
            "song": meta.get("title"),
            "artist": meta.get("artist"),
            "key": meta.get("key"),
            "sourcing": list(STEM_NAMES) if is_active else None,
            "color": LEGEND_PALETTE[i] if (meta.get("title") or is_active) else None,
        })

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
            "is_playing": transport.get("is_playing", False),
        },
        "decks": decks,
        "presets": {"bankA": bank_a, "bankB": bank_b},
        "now_playing": now_playing,
        "recommendations": recommendations,
        "scenes": [],
    }


def _resolve_clip_wav(clip_id: str) -> str | None:
    """Resolve a clip_id (e.g. 'sf:90011:drums:2') to a WAV path.

    Tries inspect data first, falls back to manifest chop_path,
    then falls back to raw stem file in cache.
    """
    parts = clip_id.split(":")
    if len(parts) < 4 or parts[0] != "sf":
        return None
    track_id = parts[1]
    stem_name = parts[2]
    try:
        chop_idx = int(parts[3])
    except (ValueError, IndexError):
        return None

    # 1. Try inspect data
    inspect = _read_inspect()
    if inspect:
        stems = inspect.get("stems", {})
        stem_clips = stems.get(stem_name, [])
        if chop_idx < len(stem_clips):
            chop = stem_clips[chop_idx].get("chop", {})
            sp = chop.get("stemPath")
            if sp and os.path.exists(sp):
                return sp

    # 2. Try manifest chop_path
    manifest_path = MANIFEST_CACHE / f"{track_id}.json"
    if manifest_path.exists():
        try:
            with open(manifest_path) as f:
                m = json.load(f)
            chops = m.get("stems", {}).get(stem_name, {}).get("chops", [])
            if chop_idx < len(chops):
                cp = chops[chop_idx].get("chop_path", "")
                if cp and os.path.exists(cp):
                    return cp
        except Exception:
            pass

    # 3. Try raw stem WAV from cache
    stem_cache = Path.home() / ".cache" / "setforge" / "stems" / track_id
    if stem_cache.exists():
        stem_file = stem_name if stem_name != "vox" else "vocals"
        candidates = list(stem_cache.rglob(f"{stem_file}.wav"))
        if candidates:
            return str(candidates[0])

    return None


def _get_arrangement_slice() -> dict:
    """Return the arrangement slice from live state or sample fallback."""
    state = get_state()
    return state.get("arrangement", {})


def get_state() -> dict:
    """Return the companion state. Live data when available, sample fallback."""
    live = _build_live_state()
    if live is not None:
        return live
    return json.loads(SAMPLE.read_text(encoding="utf-8"))


# ── Setlist timeline (Arrange view) ────────────────────────────────

MANIFEST_CACHE = Path.home() / ".cache" / "setforge" / "manifests"
SETS_DIR = Path.home() / ".cache" / "setforge" / "sets"

LEGEND_PALETTE_FULL = LEGEND_PALETTE + LEGEND_PALETTE  # 16 slots


def _build_setlist_timeline() -> dict | None:
    """Build sequential setlist timeline from the loaded set's manifest."""
    set_data, manifest = _load_set_manifest()
    if not set_data or not manifest:
        return None

    conn = None
    if TASTE_DB.exists():
        try:
            conn = sqlite3.connect(str(TASTE_DB))
            conn.row_factory = sqlite3.Row
        except Exception:
            pass

    setlist = set_data.get("setlist", [])
    manifest_tracks = {str(t.get("id", "")): t for t in manifest.get("tracks", [])}

    tracks = []
    cumulative_bar = 0
    for i, tid_str in enumerate(setlist):
        mt = manifest_tracks.get(tid_str, {})
        bpm = mt.get("bpm", 0)
        bar_grid = mt.get("bar_grid", {})
        bar_starts = bar_grid.get("bar_starts", [])
        bar_count = len(bar_starts) if bar_starts else (
            int(mt.get("downbeat_sec", 0) * bpm / 240) or 64)

        # Get metadata from DB
        meta = {}
        if conn:
            row = conn.execute(
                "SELECT artist, title, camelot FROM tracks WHERE id=?",
                (int(tid_str),)).fetchone()
            if row:
                meta = {"artist": row["artist"], "title": row["title"],
                        "key": row["camelot"]}

        # Build chop info per stem
        stems_info = {}
        for stem_name in STEM_NAMES:
            stem_key = stem_name
            stem_data = mt.get("stems", {}).get(stem_key, {})
            chops = stem_data.get("chops", [])
            stems_info[stem_name] = [{
                "idx": ci,
                "label": c.get("label", f"chop {ci}"),
                "kind": c.get("kind", ""),
                "bars": round(c.get("length_sec", 0) * bpm / 240) or 1,
            } for ci, c in enumerate(chops)]

        preset_id = f"A{i+1}" if i < 8 else f"B{i-7}"
        tracks.append({
            "track_id": tid_str,
            "title": meta.get("title", f"Track {tid_str}"),
            "artist": meta.get("artist", ""),
            "preset_id": preset_id,
            "color": LEGEND_PALETTE_FULL[i % len(LEGEND_PALETTE_FULL)],
            "bpm": bpm,
            "camelot": meta.get("key", ""),
            "start_bar": cumulative_bar,
            "bar_count": bar_count,
            "stems": stems_info,
        })
        cumulative_bar += bar_count

    if conn:
        conn.close()

    return {
        "set_name": set_data.get("name", "Unknown"),
        "total_bars": cumulative_bar,
        "tracks": tracks,
    }


def _get_track_chops(track_id: str) -> dict:
    """Get chop details for a track from its manifest."""
    mf = MANIFEST_CACHE / f"{track_id}.json"
    if not mf.exists():
        return {"error": f"no manifest for track {track_id}"}
    try:
        with open(mf) as f:
            m = json.load(f)
        conn = None
        meta = {}
        if TASTE_DB.exists():
            conn = sqlite3.connect(str(TASTE_DB))
            conn.row_factory = sqlite3.Row
            meta = _track_metadata(conn, track_id)
            conn.close()
        bpm = m.get("bpm", 0)
        stems = {}
        for sn in STEM_NAMES:
            sd = m.get("stems", {}).get(sn, {})
            chops = sd.get("chops", [])
            stems[sn] = [{
                "idx": i,
                "label": c.get("label", f"chop {i}"),
                "kind": c.get("kind", ""),
                "bars": round(c.get("length_sec", 0) * bpm / 240) or 1,
                "length_sec": round(c.get("length_sec", 0), 2),
                "clip_id": f"sf:{track_id}:{sn}:{i}",
                "peaks_ref": f"/peaks?clip=sf:{track_id}:{sn}:{i}",
            } for i, c in enumerate(chops)]
        return {
            "track_id": track_id,
            "title": meta.get("title", f"Track {track_id}"),
            "artist": meta.get("artist", ""),
            "key": meta.get("key", ""),
            "bpm": bpm,
            "stems": stems,
        }
    except Exception as e:
        return {"error": str(e)}


# ── Library / search / forge / assemble endpoints ──────────────────


def _search_tracks(query: str, limit: int = 30) -> list[dict]:
    """Search the taste DB by artist/title. Returns lightweight results."""
    if not TASTE_DB.exists():
        return []
    conn = sqlite3.connect(str(TASTE_DB))
    conn.row_factory = sqlite3.Row
    q = f"%{query}%"
    rows = conn.execute(
        "SELECT id, artist, title, camelot, stem_bpm, tempo, local_path "
        "FROM tracks WHERE (title LIKE ? OR artist LIKE ?) AND "
        "(local_path IS NOT NULL OR stem_bpm IS NOT NULL) "
        "ORDER BY CASE WHEN stem_bpm IS NOT NULL THEN 0 ELSE 1 END, artist "
        "LIMIT ?",
        (q, q, limit)).fetchall()
    results = []
    for r in rows:
        tid = r["id"]
        manifest_exists = (MANIFEST_CACHE / f"{tid}.json").exists()
        results.append({
            "id": tid,
            "artist": r["artist"] or "",
            "title": r["title"] or "",
            "key": r["camelot"] or "",
            "bpm": r["stem_bpm"] or r["tempo"] or 0,
            "has_audio": bool(r["local_path"]),
            "processed": manifest_exists,
        })
    conn.close()
    return results


def _get_library() -> list[dict]:
    """List all processed tracks (those with manifests in cache)."""
    if not MANIFEST_CACHE.exists():
        return []
    conn = None
    if TASTE_DB.exists():
        conn = sqlite3.connect(str(TASTE_DB))
        conn.row_factory = sqlite3.Row
    tracks = []
    for mf in sorted(MANIFEST_CACHE.glob("*.json")):
        try:
            with open(mf) as f:
                m = json.load(f)
            tid = m.get("id", mf.stem)
            bpm = m.get("bpm", 0)
            strategy = m.get("strategy", "default")
            n_chops = sum(len(m.get("stems", {}).get(s, {}).get("chops", []))
                          for s in ("drums", "bass", "other", "vox"))
            meta = {}
            if conn:
                row = conn.execute(
                    "SELECT artist, title, camelot FROM tracks WHERE id=?",
                    (int(tid),)).fetchone()
                if row:
                    meta = {"artist": row["artist"], "title": row["title"],
                            "key": row["camelot"]}
            tracks.append({
                "id": int(tid),
                "artist": meta.get("artist", ""),
                "title": meta.get("title", ""),
                "key": meta.get("key", ""),
                "bpm": bpm,
                "strategy": strategy,
                "chops": n_chops,
            })
        except Exception:
            continue
    if conn:
        conn.close()
    return tracks


def _list_sets() -> list[dict]:
    """List all assembled sets."""
    sets = []
    if not SETS_DIR.exists():
        return sets
    for d in sorted(SETS_DIR.iterdir()):
        if not d.is_dir():
            continue
        set_json = d / f"{d.name}.set.json"
        if set_json.exists():
            try:
                with open(set_json) as f:
                    s = json.load(f)
                sets.append({
                    "name": s.get("name", d.name),
                    "tracks": len(s.get("setlist", [])),
                    "tempo": s.get("global_tempo", 0),
                    "path": str(set_json),
                })
            except Exception:
                continue
    return sets


# Background forge-track runner
_forge_status = {"running": False, "track_id": None, "log": [], "result": None}


def _run_forge_track_bg(file: str = None, track_id: int = None,
                        strategy: str = None):
    """Run forge-track in a background thread."""
    import threading

    def _run():
        _forge_status["running"] = True
        _forge_status["log"] = []
        _forge_status["result"] = None

        def log_fn(msg):
            _forge_status["log"].append(msg)

        try:
            sys.path.insert(0, str(TASTE_DIR))
            from taste.forge_track import run_forge_track
            from taste.schema import connect
            conn = connect(str(TASTE_DB))
            result = run_forge_track(conn, file=file, track_id=track_id,
                                     strategy=strategy, force=False, log=log_fn)
            conn.close()
            _forge_status["result"] = result
        except Exception as e:
            _forge_status["log"].append(f"ERROR: {e}")
            _forge_status["result"] = None
        finally:
            _forge_status["running"] = False

    t = threading.Thread(target=_run, daemon=True)
    t.start()


def _run_assemble_set(name: str, track_ids: list[int],
                      tempo: float = None) -> dict:
    """Run assemble-set synchronously (it's instant)."""
    try:
        sys.path.insert(0, str(TASTE_DIR))
        from taste.assemble_set import assemble_set
        from taste.schema import connect
        conn = connect(str(TASTE_DB))
        logs = []
        set_path = assemble_set(conn, name, track_ids,
                                global_tempo=tempo, log=lambda m: logs.append(m))
        conn.close()
        return {"ok": True, "set_path": set_path, "log": logs}
    except Exception as e:
        return {"ok": False, "error": str(e)}


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
        from urllib.parse import urlparse, parse_qs
        parsed = urlparse(self.path)
        path = parsed.path
        params = parse_qs(parsed.query)

        if path == "/state" or path == "/state/":
            self._send(200, get_state())
        elif path == "/arrangement" or path == "/arrangement/":
            self._send(200, _get_arrangement_slice())
        elif path.startswith("/peaks"):
            self._handle_peaks()
        elif path == "/search" or path == "/search/":
            q = params.get("q", [""])[0]
            limit = int(params.get("limit", [30])[0])
            self._send(200, {"results": _search_tracks(q, limit)})
        elif path == "/library" or path == "/library/":
            self._send(200, {"tracks": _get_library()})
        elif path == "/sets" or path == "/sets/":
            self._send(200, {"sets": _list_sets()})
        elif path == "/forge-status" or path == "/forge-status/":
            self._send(200, dict(_forge_status))
        elif path == "/setlist-timeline" or path == "/setlist-timeline/":
            tl = _build_setlist_timeline()
            self._send(200, tl or {"set_name": "No set loaded", "total_bars": 0, "tracks": []})
        elif path.startswith("/track-chops"):
            tid = params.get("id", [None])[0]
            self._send(200, _get_track_chops(tid) if tid else {"error": "need ?id="})
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
        path = self.path.rstrip("/")
        if path == "/action":
            self._handle_action()
        elif path == "/forge-track":
            self._handle_forge_track()
        elif path == "/assemble-set":
            self._handle_assemble_set()
        else:
            self._send(404, {"error": "not found"})

    def _handle_forge_track(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length).decode("utf-8"))
        except (json.JSONDecodeError, ValueError):
            self._send(400, {"ok": False, "error": "invalid JSON"}); return
        if _forge_status["running"]:
            self._send(409, {"ok": False, "error": "forge-track already running",
                             "track_id": _forge_status.get("track_id")})
            return
        track_id = body.get("track_id")
        file = body.get("file")
        strategy = body.get("strategy")
        if not track_id and not file:
            self._send(400, {"ok": False, "error": "need track_id or file"}); return
        _forge_status["track_id"] = track_id
        _run_forge_track_bg(file=file, track_id=track_id, strategy=strategy)
        self._send(202, {"ok": True, "status": "started",
                         "poll": "/forge-status"})

    def _handle_assemble_set(self):
        try:
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length).decode("utf-8"))
        except (json.JSONDecodeError, ValueError):
            self._send(400, {"ok": False, "error": "invalid JSON"}); return
        name = body.get("name")
        track_ids = body.get("track_ids", [])
        tempo = body.get("tempo")
        if not name or not track_ids:
            self._send(400, {"ok": False, "error": "need name and track_ids"}); return
        result = _run_assemble_set(name, track_ids, tempo)
        self._send(200 if result.get("ok") else 400, result)

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
