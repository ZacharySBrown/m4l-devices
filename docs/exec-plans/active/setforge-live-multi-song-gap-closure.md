# Multi-song mode — gap closure spec

**Status:** follow-up spec for the agent that just implemented phases 1-4 of multi-song mode
**Date:** 2026-05-24
**Scope:** close the five gaps surfaced in your implementation digest, verify one timing assumption, and run the validation passes from the prior conversation.

This spec assumes you have full context on the codebase you just wrote. No re-introduction of the worktree, architecture, or existing state. References to functions, state fields, and files are direct.

---

## 0. What you're closing

Five gaps from the implementation digest, plus one verification:

| # | Gap | Priority |
|---|---|---|
| 1 | Red blink on dual-song entry failure | **Blocker** |
| 2 | MK2 native two-color flash for staging visuals | **Blocker** |
| 3 | Entry animation for per-row mode (§4.5) | Deferral → v0.2 |
| 4 | Invisible-held chops indicator (§6.6) | Deferral → v0.2 |
| 5 | Hot-swap timing for per-row reassign — verify boundary quantization on hardware | **Verification, not a code change** |

Plus: run validation passes 1-5 from the previous conversation to confirm the v0 surface holds together.

---

## 1. Gap 1 — Red blink on dual-song entry failure

### 1.1 The current behavior

`enterDualSongMode()` checks `staging.deckX`, `staging.deckY`, then falls back to `lastActiveBankA`, `lastActiveBankB`. If both fallbacks are null, it logs and returns. Silent no-op.

### 1.2 What to do

When `enterDualSongMode()` fails to resolve a valid deck X **or** deck Y:

1. Flash the dual-song toggle side button (top-right, note 89) **red** for ~500ms, then return to its prior color state (which would be "neither staged" dim white if we're here, but stay defensive — capture the prior state before flashing).
2. Log the reason (`"dual-song entry failed: deckX unresolved"` or similar).
3. Return without entering dual-song mode.

### 1.3 Implementation sketch

```js
function flashSideButtonRed(note, durationMs = 500) {
  const priorColor = currentSideButtonColor(note);  // implement if not already
  queueRgb(note, RED_RGB);  // bright red
  Task.schedule(durationMs, () => queueRgb(note, priorColor));
}
```

If `currentSideButtonColor()` isn't readily available, just default the post-flash state to "dim white" since that's what a fail-to-enter scenario will always land in.

### 1.4 Acceptance

- [ ] Enter dual-song mode with no staging AND no lastActiveBankA/B → toggle button blinks bright red for ~500ms then returns to dim white
- [ ] Stage only deck X (deck Y unresolved, no lastActiveBankB) → still flashes red, doesn't enter
- [ ] Stage both decks → enters normally, no red flash

---

## 2. Gap 2 — MK2 native two-color flash for staging visuals

### 2.1 The current behavior

Staging visuals use `queueRgb` to set solid colors:
- Bank A staged pad → solid white
- Bank B staged pad → solid soft blue

This shows that a pad is staged but doesn't *flash*. The user doesn't get a strong "this is in a special state" visual signal, and there's no distinction between "active preset" (solid bright) and "staged preset" (solid white) other than the color itself.

### 2.2 What to do

Replace `queueRgb` with `queueFlash` (or whichever wrapper calls `buildFlashSysex`) for the staging-pad visuals.

The flash should alternate between:
- **The preset's normal color** (its `color_hue` value mapped to a palette index)
- **The deck marker color** (white for deck X, soft blue for deck Y)

This produces the actual "preset color ↔ marker color" alternation specified in `setforge-live-spec-multi-song-modes.md` §5.4.

### 2.3 Implementation considerations

**Palette index mapping.** MK2 native flash takes palette indices, not direct RGB. You'll need to map two colors per staged pad to palette indices:

- The preset's `color_hue` → nearest palette entry. If you don't already have a `rgbToNearestPalette()` helper, write one now. The map is finite (128 palette entries from Novation's reference table); a brute-force "find nearest in RGB distance" is fine for cold-path use.
- White → palette index 3 (standard MK2 white).
- Soft blue (#7799cc) → find the nearest palette entry once at startup, cache it. There's no exact palette match; pick the closest by RGB Euclidean distance. If the result looks visually wrong on actual hardware (e.g., reads as cyan or pure blue), Zak should eye-test and we can hand-pick a specific palette index instead.

**State transitions.** Make sure the flash state is cleared when:
- The pad is un-staged (restaged to a different slot, or device reset)
- The preset becomes active (active state wins visually — switch to solid bright + slow pulse per spec §5.4)
- Dual-song mode is entered (the pad is no longer relevant; it might still be the source of one of the decks, but the visual encoding inside dual-song mode is different)

### 2.4 The "both decks same preset" edge case

Spec §5.4 mentions a 3-color cycle for same-preset-on-both-decks. **Skip this for now.** If the user stages the same preset on both decks:
- Just show the deck-X flash (preset ↔ white). The side button alternation already shows "both decks staged with same preset" via the same color appearing on both sides.

Surface this as an explicit deferral in your acceptance notes.

### 2.5 Acceptance

- [ ] Stage a preset on row 5 → that pad alternates between its preset color and white (visible flash, not solid)
- [ ] Stage a preset on row 6 → that pad alternates between its preset color and soft blue
- [ ] If the preset is active *and* staged, the active state wins (solid bright + slow pulse, not flash)
- [ ] Restaging clears the prior flash before applying the new one
- [ ] USB bandwidth measurably lower than the software-driven solid-RGB version (sanity check via Live's profiler if possible; otherwise just verify no pad-update lag during heavy chop playback)
- [ ] White looks white (palette 3 is correct); soft blue is in the blue family (not cyan, not purple). If wrong, eye-test with Zak and adjust palette index.

---

## 3. Gap 3 — Per-row mode entry animation (deferral)

### 3.1 What's deferred

Spec §4.5 specifies that entering per-row mode should fire:
- SOLO pad flashes yellow once
- Leftmost pad of each stem row pulses once in its current source-preset color
- Total animation ~500ms

Currently SOLO just latches yellow with no flash; the stem-row leftmost pads don't pulse.

### 3.2 What to do

**Nothing in this batch.** Log to the v0.2 backlog (see §7 for the backlog format).

Rationale: the mode entry works functionally — SOLO latching yellow is itself a visible signal that the mode changed. The animation is pure delight, not core function. v0.1 ships without it.

---

## 4. Gap 4 — Invisible-held chops indicator (deferral)

### 4.1 What's deferred

Spec §6.6 specifies a secondary visual cue on the dual-song toggle side button when held chops are playing but not visible in the current view (e.g., chops held from solo mode while in dual-song mode with different decks staged).

Currently no such cue exists.

### 4.2 What to do

**Nothing in this batch.** Log to the v0.2 backlog.

Rationale: the underlying state tracking (`heldChops[]` with `visibleInCurrentView` field per spec §7.1) isn't wired up either. Both pieces would need to land together. Defer the whole thing rather than half-implementing.

When you do build this in v0.2, the right shape is probably:
- Track held chops via clip handles you already have
- Recompute `visibleInCurrentView` on every view transition
- When any held chop has `visibleInCurrentView = false`, overlay a subtle red tint (or slow pulse) on whatever the dual-song toggle side button is currently showing

But that's for later.

---

## 5. Gap 5 — Hot-swap timing verification (verify, don't change)

### 5.1 The concern

You said per-row reassignment fires the held chop immediately via `launchClipInTrack`. Your reasoning is that Live's `launch_quantization` on the clip handles the boundary — so even though `fire()` is called immediately, Live snaps the actual playback start to the next quant boundary.

This should be true, since:
- `launch_quantization` is a Live clip property that controls when a fired clip actually begins playing
- The existing solo-mode hot-swap (`onPresetPress`) uses the same pattern and presumably works

But we haven't verified on hardware. **Verify before assuming.**

### 5.2 The verification

Do this with real hardware, real ears:

1. Load 2 presets (call them C and F) into bank A
2. Enter per-row mode (double-tap SOLO)
3. With drums row sourcing from C, hold drums chop 5 — it starts playing
4. While drums chop 5 is still playing (so the chop is "held" mid-loop), tap preset F to reassign drums row
5. **Listen carefully for the transition.** Specifically:
   - Does the audio snap from C's drums to F's drums *instantly* (audible flam/click), or
   - Does it migrate cleanly at the next 1/16 boundary (smooth transition, kick stays on grid)?

Smooth transition at boundary = working correctly, no change needed.

Audible flam or instant snap = `launch_quantization` isn't being applied to the new clip, and we need to investigate. Possibilities:
- The new clip slot's `launch_quantization` property isn't set when `loadStemClipsToTrack` writes new clips
- The `fire()` call somehow bypasses the quant (less likely)
- Live's quant treats "currently playing clip on this track gets replaced" differently from "new clip starts on empty track"

### 5.3 What to do if it fails

Don't fix blind. Instead, surface to Zak with:
- Which scenario failed (instant snap vs flam vs something else)
- What `launch_quantization` value the clip has after `loadStemClipsToTrack`
- Whether the solo-mode `onPresetPress` hot-swap has the same problem (regression test: does the original solo-mode hot-swap audibly migrate at boundary?)

The fix path depends on the answer. Most likely: the new clip slot needs its `launch_quantization` set explicitly after load, matching the per-row default (1/16 for drums, 1 bar for bass, etc. per spec §6.4).

### 5.4 Acceptance

- [ ] Per-row reassignment of a held drums chop migrates cleanly at the next 1/16 boundary (audible kick stays on grid)
- [ ] Per-row reassignment of a held bass chop migrates at the next bar boundary
- [ ] If migration is NOT clean, surface the findings (don't auto-fix)

---

## 6. Validation passes (run all)

After gaps 1-2 are closed and gap 5 is verified, run the five validation passes from the prior conversation. They're consolidated here for convenience.

### 6.1 Pass 1 — Smoke test (5 min)

Verify the existing solo-mode path still works. The layout reshuffle alone touched enough code that a regression here is plausible.

- [ ] Load a set with 3-4 presets
- [ ] Tap each preset, verify it goes active (slow pulse on the bank pad)
- [ ] Tap chops in all four stem rows, verify they play
- [ ] Tap each modifier with held chops, verify expected behavior (reverse, stutter, etc.)
- [ ] Save a scene (HOLD + tap scene pad), recall it (tap), verify restoration
- [ ] Triple-tap panic, verify everything stops cleanly

### 6.2 Pass 2 — Per-row mode functional (10 min)

- [ ] Double-tap SOLO → enters per-row mode (SOLO latches yellow)
- [ ] Leftmost pad of each stem row shows source-preset color
- [ ] Hold drums chop pad + tap a different preset → drums row reassigns; chop migrates cleanly (per gap 5 verification)
- [ ] Tap drums chop and bass chop with different sources → audibly plays from different songs, in phase
- [ ] Double-tap SOLO → exits, returns to solo mode cleanly
- [ ] Held chops survive entry AND exit (no audio interruption)
- [ ] Save scene in per-row mode → recall restores `rowSources`

### 6.3 Pass 3 — Staging + dual-song full path (20 min)

This is the load-bearing pass.

- [ ] Hold deck-setup side button → side button lights bright white
- [ ] While held, tap row 5 preset → that pad flashes preset-color ↔ white (after gap 2 fix)
- [ ] While held, tap row 6 preset → that pad flashes preset-color ↔ soft blue
- [ ] Release deck-setup → side button dims; staged pads keep flashing
- [ ] Dual-song toggle (top-right) shows alternating X/Y colors
- [ ] **Wait ~5 seconds, then enter dual-song mode** → view flip is instantaneous (no audible load delay)
- [ ] Stage two new presets and immediately enter dual-song before pre-load completes → either a visible "loading" state on chop pads, or a brief load delay. Verify what actually happens.
- [ ] In dual-song view: tap drums-X chop N + drums-Y chop N at the same time. **Drum-on-drum locks tight, kick-on-kick within ~15ms.**
- [ ] Exit dual-song → return to prior view
- [ ] Re-enter dual-song → still instant (loaded decks persist)
- [ ] Restage a different deck X mid-set, re-enter dual-song → new song plays correctly

### 6.4 Pass 4 — Edge cases and integrity (15 min)

- [ ] Enter dual-song without staging → falls back to last-active bank A/B
- [ ] Enter dual-song with no staging AND no last-active → fails to enter, toggle blinks red (gap 1 fix verifies here)
- [ ] Stage an empty preset slot → brief red flash on the pad, no assignment
- [ ] Held chops from solo mode → enter dual-song → chops keep playing → exit → visible again, still playing
- [ ] Triple-tap panic from dual-song → all audio stops, mode reverts to solo
- [ ] In per-row mode, same preset on multiple rows → behaves like solo for those rows
- [ ] Mode transitions: solo → per-row → dual-song → exit → per-row state restored (rowSources intact, SOLO still latched)
- [ ] Modifier latches survive mode transitions
- [ ] FX target "drums" in dual-song applies to rows 1 and 5 simultaneously; "all" applies to all 8

### 6.5 Pass 5 — Audio integrity (variable time)

- [ ] 8 stems playing simultaneously in dual-song → no dropouts, no buffer underruns, no crackle
- [ ] Watch Live's CPU meter during 8-stem playback → within budget
- [ ] Hot-swap one stem source in per-row mode while three other stems play → no glitches in the other three
- [ ] Connect/disconnect USB mid-session → device handles reconnection cleanly, state preserved

### 6.6 The single load-bearing test

If you only have time for one test from all five passes:

**Drum-on-drum chording in dual-song mode at 1/16 boundaries.** Tap drums-X chop N + drums-Y chop N within the same launch-quant window. Kick-on-kick should lock within ~15 ms with no audible flam. This is the gesture this whole system was built to enable; everything else is supporting infrastructure for this one move.

---

## 7. v0.2 backlog

Create or append to `docs/exec-plans/active/setforge-live-v0.2-backlog.md` with the following entries. (If a different backlog file already exists, use that.)

```markdown
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
```

---

## 8. Order of work

1. **Gap 1 (red blink)** — commit alone, easy to verify
2. **Gap 2 (native flash)** — commit alone, includes the palette mapping helper if needed
3. **Gap 5 (hot-swap verification)** — no code change unless something fails; surface findings if it does
4. **Validation passes 1-5** — run in order; stop and surface any failures
5. **v0.2 backlog** — write the doc, surface to Zak

Each code commit before validation. If validation surfaces a regression, that's a separate fix commit.

---

## 9. Definition of done

- [ ] Gap 1 implemented and committed
- [ ] Gap 2 implemented and committed (with palette mapping if needed)
- [ ] Gap 5 verified — hot-swap migration sounds clean at boundary (or, if not, findings surfaced to Zak)
- [ ] All five validation passes run; results reported (passes, fails with descriptions)
- [ ] v0.2 backlog doc created at `docs/exec-plans/active/setforge-live-v0.2-backlog.md`
- [ ] Final commit hashes + validation summary surfaced to Zak

After this lands, v0.1 of multi-song mode is shippable. Drum-on-drum mashup tightness is the load-bearing test; if that works, the project delivers its musical promise.

---

## 10. Questions to surface (don't guess)

- If `currentSideButtonColor()` doesn't exist and capturing prior color is messy, surface and propose either a state-machine approach or a "always revert to dim white" simplification
- If `buildFlashSysex` doesn't exist at all (you said it does but worth confirming), or takes a different signature than expected, surface
- If the palette table for MK2 isn't already in code, surface — there's a question of whether to inline it from Novation's reference or import from a constants module
- If the soft-blue palette mapping looks visually wrong (reads as cyan, purple, or washed-out), surface with a screenshot/description so Zak can pick a hand-tuned palette index
- If gap 5 verification fails, surface findings before attempting a fix

---

*end of gap-closure spec*
