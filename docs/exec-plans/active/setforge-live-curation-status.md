# setforge-live curation harness — status

**Date:** 2026-05-29 18:30 PDT
**Worktree:** `.claude/worktrees/setforge-live` on `worktree-setforge-live`
**Last commits:** `b6495a5`, `6331af1` (pushed)

---

## Where we are

Goal: enable the curation loop (edit clips in Live's UI → save → reload → changes persist) for the five ops the user listed (markers, BPM, move, delete, copy). Test it programmatically with AbletonOSC.

What landed:

| Piece | Status |
| --- | --- |
| AbletonOSC installed + `warp_bpm` patched in `clip.py` rw list | ✅ files on disk |
| Loader: identity-prefix clip naming `[sf:trackId/stem/idx]` | ✅ shipped, verified at runtime |
| Loader: `chop.bpm` → `warp_bpm` on load (op 2 write) | ✅ shipped |
| Loader: structural sync (positional → identity-based) | ✅ shipped |
| Loader: legacy positional fallback (one-time stamp-on-first-sync) | ✅ shipped |
| Curation harness scaffold (`tests/curation/`) | ✅ scaffolded |
| Smoke test (clip read via OSC) | ✅ passing |
| Op 1 test (loop_end edit → save → reload → assert) | ⚠ failing — see below |
| Op 2 test (per-clip BPM persistence) | not written |
| Op 3 test (move) | not written |
| Op 4 test (delete) | not written |
| Op 5 test (copy) | not written |
| Live restart to load patched AbletonOSC for `warp_bpm` reads | pending |

---

## Outstanding bug

Op 1 test sets `loop_end = 2` on `sf-drums` slot 0 via OSC, confirmed Live accepts the change (read-back returns 2.0), calls `save`. The sync runs (manifest gets rewritten — content changes, file size grows) but `chop[0].length_sec` remains `2.46` (the original full-bar length) instead of being reduced to ~`1.22` (half-bar at ~98 BPM).

Direct OSC probe shows the live state after save:
- slot 0: `warping=True`, `start_marker=0`, `end_marker=2`, `loop_start=0`, `loop_end=2` ✓ (edit persisted in Live)
- manifest after save: `chop[0].length_sec=2.46`, `length_bars=1` ✗ (sync didn't reflect the change)

Also seen: `chop[7]` (the oneshot) writes back as `length_sec=0.241`, `start_sec=29.745` — values that look like they came from the warped-branch math rather than the oneshot branch. This suggests my structural-sync refactor has a bug where:

- Either the warped branch runs for clips Live reports as `warping=0`
- Or the `c = lc.slot` variable I introduced conflicts with the old per-chop-index `c` referenced in `presetChops[c]` / `[sync raw] ... [c]` logging
- Or the fallback path (`if (!mc.length_sec || mc.length_sec <= 0)`) fires unconditionally and produces `2.45 = 1*4*(60/97.98)` regardless of what the warped branch computed

The most likely culprit, in priority order:

1. The fallback at line ~3154 is firing because something in the warped branch leaves `mc.length_sec` undefined (the `mc.start_sec` assignment with a NaN `startSec` may also be involved).
2. The warp-marker computation reads `markers[0].beat_time` as undefined (the first marker is the `[b=?,s=?]` infinity-anchor), making `dtBeat = NaN`, falling back to `secPerBeat`, but `startSec = anchor.sample_time + (loopStart - anchor.beat_time) * secPerBeatFromMarkers` produces NaN → mc gets corrupted.
3. The c-variable confusion makes `presetChops[c]` reach into wrong entries.

---

## What to do next session

1. **Restart Live** so the AbletonOSC `warp_bpm` patch loads. Until then, op 2's OSC read returns `None` and the test can't verify BPM writes via OSC.
2. **Diagnose the sync issue.** Add temporary `post()` lines in `syncPresetClips` that write per-clip state to a file (`/tmp/setforge_sync_trace.json`) so the test harness can read what sync actually did. Then run op 1's test with the trace and walk through the math.
3. **Fix.** Likely candidates:
   - Move the fallback to ONLY fire when neither the warped nor unwarped branch updated `mc.length_sec`.
   - Use a separate variable for the per-chop loop index in logging/preset-chop lookup (or rename `c` to `slotIdx` everywhere in the body and rebuild the manifest-chop index as `mci`).
   - Audit `cloneChop` / `newChops` path for double-mutation.
4. **Write ops 2–5 tests once op 1 is green.**
5. **Hand-curate acceptance pass.**

---

## Build state

- 167/167 JS tests passing on the worktree
- All commits pushed to `origin/worktree-setforge-live`
- Curation harness lives in `device/setforge-live/tests/curation/`
- Sandbox set at `~/Desktop/hiphop_breaks_test/` (recreated per test run by `snapshot.py`)
- Production set at `~/Desktop/hiphop_breaks/` (untouched by tests)
