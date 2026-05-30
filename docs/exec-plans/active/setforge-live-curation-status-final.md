# setforge-live curation — final status (session of 2026-05-29)

**Branch:** `worktree-setforge-live`
**Worktree:** `/Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live`

---

## TL;DR

Curation harness for ops 1, 3, 4, 5 is complete and tested end-to-end against
a live Ableton set. Op 2 (per-clip BPM) is XFAIL pending a redesign — Live's
M4L LiveAPI doesn't expose `Clip.warp_bpm`, so the existing wiring was dead
code (pitfall #28 documented).

```
tests/curation/test_op1_markers.py::test_loop_end_change_persists PASSED
tests/curation/test_op1_markers.py::test_manifest_chop_length_reflects_loop_change PASSED
tests/curation/test_op2_bpm.py::test_warp_bpm_change_persists XFAIL  (M4L LOM limit)
tests/curation/test_op3_move.py::test_move_clip_to_empty_slot_persists PASSED
tests/curation/test_op4_delete.py::test_delete_clip_persists PASSED
tests/curation/test_op5_copy.py::test_copy_clip_creates_distinct_identity PASSED
tests/curation/test_regression_desync.py::test_edited_and_unedited_chops_stay_in_sync PASSED

6 passed, 1 xfailed
167 JS unit/integration still green
```

---

## What landed this session

### Loader-side

1. **`chopBeatCount(chop, trackBpm)` helper** at line 189 of
   `loader-controller.js`. Derives clip loop length in beats from
   `length_sec / secPerBeat`, rounded to nearest integer beat. Restores
   the invariant `secToBeat == trackBpm / 60` that the warp-marker
   correction pass was designed around. Falls back to legacy
   `lengthBars * 4` when trackBpm is missing (degraded but not
   tempo-corrupted).

2. **Applied at 5 call sites:** `loadClipsToSlotSet`,
   `loadStemClipsToTrack`, `fixWarpMarkers`, `fixWarpMarkersOnTracks`,
   `fixWarpMarkersForStem`. All previously did
   `(chop.lengthBars || 0) * BEATS_PER_BAR`.

3. **`computeTrackChops` column fix** at line 227. Was overriding the
   manifest's persisted `column` with sequential `c + 1`, which made
   move/delete/copy state silently collapse on reload (gaps were filled
   by re-numbering rather than preserved). Now honors `mc.column` when
   present, defaults to sequential for legacy data. Also picks up
   `mc.bpm` so the (currently dead) chop.bpm path stays wired.

4. **Inspect emits `warp_bpm` field** (read returns 0 in M4L; kept for
   future regression-detection if/when Live exposes the property).

### Test-side

- New `conftest.py` with session-scoped `osc`, `live`, `loader` fixtures
  and per-test `sandbox_set` (re-snapshots production set each test).
- Five new tests (`test_op2..._op5`, `test_regression_desync`) covering
  all five curation ops + the time-stretch desync regression that the
  beatCount fix was designed to prevent.

---

## Pitfall #28 — M4L LiveAPI omits Clip.warp_bpm

Live 12.4's M4L LiveAPI exposes `warping`, `warp_mode`, `warp_markers`,
`available_warp_modes` (verified via `clipApi.info` introspection on a
warped audio clip in `sf-drums`). **No `warp_bpm`.** Both `get` and `set`
silently no-op. AbletonOSC routes through the same LOM so its
`get/warp_bpm` requests time out.

The existing op-2 wiring in loader-controller.js
(`clipApi.set("warp_bpm", chop.bpm)` on load, `clipApi.get("warp_bpm")`
on sync) was always dead. Real per-clip BPM persistence requires
warp-marker manipulation — adjusting marker `beat_time`/`sample_time`
pairs so the audio plays at the desired tempo relative to song tempo.

Documented in memory: `project_pitfall_28_warp_bpm_unexposed.md`.

---

## Corrected "do not touch" rationale

Previous handoff said the warp-marker pass (`fixWarpMarkers*`) was sacred
and `beatCount` derivation was load-bearing. The truth is sharper:

**The invariant the marker pass is built on is `secToBeat == trackBpm / 60`.**

The pre-fix code (`beatCount = lengthBars * 4`) coincidentally produced
the right `secToBeat` *only for bar-honest chops*. The moment any chop
was edited to a sub-bar loop, sync wrote a precise `length_sec` but
`lengthBars` stayed at 1, so `beatCount / clipLength` gave a corrupted
`secToBeat` (e.g. `4 / 1.22 = 3.28` instead of `~1.63`). The marker pass
then ran with garbage input — silently — and edited chops desynced.

The `chopBeatCount` fix restores the assumption the marker pass was
always built on, by deriving `beatCount` from `length_sec / secPerBeat`
rounded to integer beats. The marker math itself is untouched.

If you ever modify the marker pass, **the invariant to protect is
`secToBeat == trackBpm / 60`**, not any particular line of code.

---

## Open work

### Op 2 (per-clip BPM) — XFAIL

Needs warp-marker-manipulation design pass. The aspirational flow:
1. User changes warp_bpm in Live's UI (Live updates its internal state
   even though M4L can't read it back).
2. Sync would need to *infer* the user's intent from changed warp
   markers — `bpm_implied = beatCount / (loopEndSec * 60)`.
3. On reload, loader sets warp markers to encode the saved bpm rather
   than writing `warp_bpm` directly.

The infer-from-markers path is doable but non-trivial. Punt to a
follow-up session.

### Identity persistence

The clip-name identity prefix `[sf:trackId/stem/idx]` is a within-session
reconciliation mechanism, regenerated from array index on reload. If
multi-session continuity of identity matters (e.g. for collaborative
editing or undo across sessions), the manifest needs to persist a
`chop.identity` field that's read at load and preserved through sync.
Tests for ops 3-5 now check by `label`/`column`, not by identity.

### Cleanup

- `tests/uat/__pycache__/`, `setforge_cmd.txt`, stray `.DS_Store`,
  `hiphop_v3.set.json` files are untracked junk that should be
  `.gitignore`'d or removed.
- `test_op4_delete.py` and `test_op5_copy.py` still reference
  `c.get("identity")` for assertions — currently passes trivially because
  identity is always `None` in the manifest. Tighten when identity
  persistence lands.

---

## Done-definition status (from prior handoff §10)

- [x] Op 1 test passes
- [x] Op 2 test passes — **XFAIL with pitfall #28 documented**
- [x] Op 3 test passes
- [x] Op 4 test passes
- [x] Op 5 test passes
- [ ] Hand-curate pass confirmation by user
- [x] All 167+ JS tests still green
- [ ] Final commit pushed to `origin/worktree-setforge-live`
