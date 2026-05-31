# setforge-live — known issues / deferred items

## DEFERRED — A/B preset banks should map to fixed slot ranges (raised 2026-05-31)
Expectation: **Bank A presets always load on clip slots 1–8, Bank B presets always
on 9–16.** Today they don't — the loader uses a *dual slot-set* staging model where
the ACTIVE set alternates between slots 0–7 and 8–15 to allow gapless preset swaps
(`activeSetOffset()` / `stagingSetOffset()`). So the same preset (e.g. A1) can land on
0–7 one time and 8–15 the next, depending on staging state. Making A→1–8 / B→9–16
fixed is a change to the staging architecture (decouple bank identity from the
active/staging slot-set). Deferred; note for a later pass.

## DEFERRED — vocal intro grid (deep first bar) — gibberish at song starts (2026-05-31)
Some tracks' taste bar_grid starts deep (e.g. 29679 first bar at 44.64s though the
downbeat is ~23.5s; Digable Planets 1851 at 11.82s). beat-this missed the intro bars,
so the warp grid doesn't cover the start. Effect: vocal regions whose start_sec falls
before the grid's first anchor get clamped/misplaced (wrong offsets, gibberish intros).
Fix class (deferred): extend the warp grid backward over the intro at the detected
tempo (in taste `_build_beat_grid`), or re-detect the bar grid. Does NOT affect the
curated *layout* (columns/counts), only vocal playback offsets.

## FIXED 2026-05-31
- `reload` now re-reads the saved set from disk (was rebuilding from stale memory).
- `full_stem` vocals now restore saved chop regions (was collapsing to one full clip).
- Both load paths honor saved per-clip `column` so moved clips restore to their slot.
