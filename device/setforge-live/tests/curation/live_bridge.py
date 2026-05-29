"""High-level clip-curation operations against the open Ableton Live set,
driven by AbletonOSC. Exposes the five ops the test suite cares about:

  1. edit_clip_markers — set start/end/loop markers on an existing clip
  2. set_clip_bpm      — set warp_bpm on a clip
  3. move_clip         — move clip from (src_track, src_slot) to (dst_track, dst_slot)
  4. delete_clip       — delete clip in a slot
  5. copy_clip         — duplicate clip from src slot to dst slot

Plus read helpers: get_clip_state, find_track_by_name, list_tracks.
"""

from dataclasses import dataclass
from typing import Optional

from osc_client import AbletonOSC


# Stem-row → expected track name (without -x / -y suffix).
STEMS = ("drums", "bass", "other", "vox")


@dataclass
class ClipState:
    has_clip: bool
    start_marker: Optional[float] = None
    end_marker: Optional[float] = None
    loop_start: Optional[float] = None
    loop_end: Optional[float] = None
    warping: Optional[int] = None
    warp_bpm: Optional[float] = None
    length: Optional[float] = None
    name: Optional[str] = None


class LiveBridge:
    """Thin wrapper around AbletonOSC for clip ops."""

    def __init__(self, osc: AbletonOSC):
        self.osc = osc
        self._track_index_cache: dict[str, int] = {}

    # ── Track discovery ────────────────────────────────────────────

    def list_tracks(self) -> list[tuple[int, str]]:
        n = self.osc.ask("/live/song/get/num_tracks")[0]
        out: list[tuple[int, str]] = []
        for i in range(n):
            (_, name) = self.osc.ask("/live/track/get/name", i)
            out.append((i, name))
        return out

    def find_track(self, name: str) -> int:
        if name in self._track_index_cache:
            return self._track_index_cache[name]
        for (i, t) in self.list_tracks():
            if t == name:
                self._track_index_cache[name] = i
                return i
        raise LookupError(f"no track named {name!r}")

    # ── Clip read ──────────────────────────────────────────────────

    def get_clip_state(self, track: int, slot: int) -> ClipState:
        # Hit the clip_slot has_clip first; if no clip, return early.
        (_, _, has) = self.osc.ask("/live/clip_slot/get/has_clip", track, slot)
        if not has:
            return ClipState(has_clip=False)
        props = {}
        for p in ("start_marker", "end_marker", "loop_start", "loop_end",
                  "warping", "warp_bpm", "length", "name"):
            try:
                (_, _, value) = self.osc.ask(f"/live/clip/get/{p}", track, slot)
                props[p] = value
            except (TimeoutError, ValueError):
                props[p] = None
        return ClipState(has_clip=True, **props)

    # ── Op 1: marker edits ─────────────────────────────────────────

    def edit_clip_markers(self, track: int, slot: int, *,
                          start: Optional[float] = None,
                          end: Optional[float] = None,
                          loop_start: Optional[float] = None,
                          loop_end: Optional[float] = None) -> None:
        if start is not None:
            self.osc.send("/live/clip/set/start_marker", track, slot, float(start))
        if end is not None:
            self.osc.send("/live/clip/set/end_marker", track, slot, float(end))
        if loop_start is not None:
            self.osc.send("/live/clip/set/loop_start", track, slot, float(loop_start))
        if loop_end is not None:
            self.osc.send("/live/clip/set/loop_end", track, slot, float(loop_end))

    # ── Op 2: per-clip BPM ─────────────────────────────────────────

    def set_clip_bpm(self, track: int, slot: int, bpm: float) -> None:
        # AbletonOSC.clip.py was patched to expose warp_bpm in rw props.
        self.osc.send("/live/clip/set/warp_bpm", track, slot, float(bpm))

    # ── Op 3: move ─────────────────────────────────────────────────

    def move_clip(self, src_track: int, src_slot: int,
                  dst_track: int, dst_slot: int) -> None:
        """Move clip from src to dst by duplicate + delete. AbletonOSC's
        duplicate_clip_to copies the clip across slots; we delete the source
        after. duplicate_clip_to handles cross-track too.
        """
        self.osc.send("/live/clip_slot/duplicate_clip_to",
                      src_track, src_slot, dst_track, dst_slot)
        self.osc.send("/live/clip_slot/delete_clip", src_track, src_slot)

    # ── Op 4: delete ───────────────────────────────────────────────

    def delete_clip(self, track: int, slot: int) -> None:
        self.osc.send("/live/clip_slot/delete_clip", track, slot)

    # ── Op 5: copy ─────────────────────────────────────────────────

    def copy_clip(self, src_track: int, src_slot: int,
                  dst_track: int, dst_slot: int) -> None:
        self.osc.send("/live/clip_slot/duplicate_clip_to",
                      src_track, src_slot, dst_track, dst_slot)
