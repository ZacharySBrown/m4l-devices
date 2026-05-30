# setforge-live v0.2 backlog

Deferred from multi-song modes v0.1. See setforge-live-spec-multi-song-modes.md
and setforge-live-multi-song-gap-closure.md for context.

## Per-row mode entry animation
- Spec ref: §4.5
- What: SOLO pad flashes yellow once + leftmost stem-row pads pulse once in
  source-preset color on per-row mode entry (~500ms total)
- Why deferred: pure delight; functional state change is already visible via
  SOLO latching yellow

## Invisible-held chops indicator
- Spec ref: §6.6, §7.1 (visibleInCurrentView state field)
- What: secondary visual cue on dual-song toggle side button when held chops
  are playing but not visible in current view (subtle red overlay or slow pulse
  on top of the X/Y color alternation)
- Why deferred: requires wiring up `visibleInCurrentView` tracking across all
  held chops, which is a non-trivial state extension; absence is unclear but
  not dangerous

## Live mid-mode reassignment in dual-song view
- Spec ref: §6.7
- What: gesture to change deck X or deck Y assignment while in dual-song view
  without exiting first
- Why deferred: spec explicitly defers this to v0.2; basic exit-restage-re-enter
  flow is sufficient for v0.1

## Per-song FX targets
- Spec ref: §6.5 final paragraph
- What: "drums-X-only" and "drums-Y-only" as FX target options in dual-song
  mode (currently only "drums" which hits both)
- Why deferred: requires adding pads to the FX target row; out of scope for
  v0.1

## Three-color flash for same-preset-on-both-decks
- Spec ref: §5.4 final row of staging visual table
- What: when the same preset is staged for both X and Y, show a 3-color cycle
  (preset color, white, soft blue) instead of just deck-X flash
- Why deferred: rare edge case; gap 2 fix uses the simpler deck-X-flash
  fallback for v0.1
