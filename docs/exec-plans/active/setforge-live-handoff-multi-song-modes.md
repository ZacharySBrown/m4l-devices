# Coding agent handoff — multi-song modes (full implementation)

**Date:** 2026-05-24
**Author:** chat-Claude (Zak's planning session)
**Target:** Claude Code, working in the existing setforge-live worktree
**Status:** color fix + per-row mode design exist; song-structure work is done. This handoff covers ALL the multi-song mode implementation in one work stream: layout reshuffle, per-row mode, staging+pre-loading, and the dual-song view.

---

## 0. What you're doing (in one paragraph)

Implement everything in the multi-song modes spec, in four internal phases: (1) reshuffle the Grid 1 layout to put stems on top and controls below, (2) build per-row mode (each stem row sources from its own preset, entered via double-tap SOLO), (3) build the staging gesture and audio pre-loading pipeline (hold deck-setup side button + tap presets to stage decks X and Y, async stem loading in background), (4) build the dual-song view itself (top-right side button toggles into a view where all 8 rows are stems, X on top half, Y on bottom half, with 8 simultaneous voices). Each phase commits separately with an acceptance pass before moving to the next. The end state: all four views (solo, per-row, dual-song, control) coexist cleanly on the single Launchpad MK2.

---

## 1. Working state — start here

The worktree should be at `/Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live` on branch `worktree-setforge-live`. Per recent work, the color fix and the layout state machine should already be in code. Per-row mode was specified in a previous handoff but **not actually implemented** — confirm this is still the case before proceeding.

```bash
cd /Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live
git status
git log --oneline -15
```

**If `git status` shows uncommitted changes:** inspect with `git diff --stat`. If they're related to ongoing setforge-live work, commit them as a snapshot before starting this handoff. Use a descriptive message. Surface the commit hash to Zak.

**If working tree is clean:** proceed.

**Do not start implementation until Zak has acknowledged the starting state.**

---

## 2. Inputs (read before you start)

### 2.1 Primary spec — the authoritative contract

**`device/setforge-live/spec/setforge-live-spec-multi-song-modes.md`** — the consolidated multi-song spec. This is your design contract. Read it in full.

Section map for this handoff:

| Phase | Spec sections to read |
|---|---|
| Phase 1 (layout) | §3.1, §3.2, §3.3, §3.4, §9.1 |
| Phase 2 (per-row mode) | §4 (all subsections), §7.2, §9.2 |
| Phase 3 (staging + pre-loading) | §5 (all subsections), §7.6, §9.3 |
| Phase 4 (dual-song view) | §6 (all subsections), §3.5, §7 (transitions), §9.4, §9.5 |
| Throughout | §2 (four-view model), §8 (side button bindings), §10 (glossary) |

### 2.2 Supporting docs — read for context

- **`device/setforge-live/spec/setforge-live-spec.md`** — main spec. Skim §2.2 (current layout, which you're replacing) and §2.5 (hot-swap mechanic, which extends to multi-song scenarios).
- **`device/setforge-live/spec/setforge-live-spec-launchpad-addendum.md`** — MK2 hardware reference. §3 (SysEx commands) is load-bearing for staging visuals; specifically §3.6 (palette pulse + two-color flash). The multi-song spec supersedes §4 of this addendum but the rest remains authoritative.

### 2.3 Not relevant to this handoff

- `setforge-live-spec-structure-analysis-addendum.md` — structure analysis is upstream in taste, doesn't affect this work.
- `setforge-live-spec-related-work-addendum.md` — positioning context, not behavioral.
- Older handoffs in `docs/exec-plans/active/` — historical context only.

### 2.4 What's already built

Per recent conversations:
- Two-track architecture (MIDI device + audio device) is in place. Don't touch it as a whole; only extend its audio routing for dual-song mode.
- LP MK2 colors fixed (color fix work from phase 5b-6).
- Song-structure analysis pipeline is built in `taste`. Manifests should now include `chops[]` per stem (or fall back to blind grid if not). The loader should read `chops[col-1]` for pad fires. **Don't re-implement this** — assume it works.

If anything in this list turns out to be incomplete, surface to Zak immediately. Don't try to backfill.

---

## 3. Phase 1 — Layout reshuffle

Per multi-song spec §3.1-3.4. Smaller, lower-risk piece. Ship as its own commit before starting per-row mode.

### 3.1 What changes

Move rows around. No behavior changes.

**Old layout:**
```
row 1   preset A
row 2-5 stems (drums, bass, other, vox)
row 6   modifiers
row 7   preset B
row 8   scenes
```

**New layout:**
```
row 1   drums
row 2   bass
row 3   other
row 4   vox
row 5   preset A (bank A, slots 1-8)
row 6   preset B (bank B, slots 9-16)
row 7   modifiers
row 8   scenes
```

### 3.2 What stays the same

All pad-press semantics. Specifically:
- Per-stem launch quant (drums 1/16, bass 1 bar, other 1/4, vox 1/2)
- Modifier semantics (hold/mute/solo/rev/stut/half/dbl/kill)
- Preset hot-swap (tap preset, held chops migrate at boundary)
- Scene save (HOLD + tap) and recall (tap)
- Curated `chops[]` reads from the manifest if present, blind-grid fallback if not

### 3.3 Implementation

1. Locate the row-numbering logic in `launchpad-surface-mk2.js` (or wherever spec rows are mapped to launchpad notes).
2. Update the spec→pad mapping for the new positions. Be careful with the row-flip math (launchpad rows count from bottom, spec rows from top — `launchpadRow = 9 - specRow`).
3. Update any tests with hardcoded row positions.
4. Update `device/setforge-live/docs/pad-reference-card.md` (if it exists in the repo). If not, surface to Zak — the reference card lives elsewhere and might need updating manually.

### 3.4 Acceptance — phase 1

Per spec §9.1:
- [ ] Solo mode: stems rows 1-4, banks rows 5-6, modifiers row 7, scenes row 8
- [ ] All existing solo-mode behaviors functionally unchanged
- [ ] Existing test suite passes (with any hardcoded row references updated)

**Commit before phase 2.** Suggested message:

```
setforge-live: multi-song phase 1 — layout reshuffle

Move stems to rows 1-4 (top of grid), group control rows (preset
banks adjacent at 5-6, modifiers at 7, scenes at 8) below.

No behavior changes. Pad-press semantics, chop math, hot-swap,
modifiers, and scenes all work identically; only row positions move.

See device/setforge-live/spec/setforge-live-spec-multi-song-modes.md §3.
```

Surface commit hash to Zak. **Wait for acknowledgment before starting phase 2.**

---

## 4. Phase 2 — Per-row mode

Per multi-song spec §4.

### 4.1 What this builds

The second performance view: each stem row sources from its own independent preset. The four stem rows can simultaneously play chops from four different songs.

### 4.2 Entry / exit

- **Enter:** double-tap SOLO (row 7, col 3). SOLO pad latches yellow.
- **Exit:** double-tap SOLO again.

### 4.3 Per-row preset assignment

**Hold any pad in a stem row (rows 1-4) + tap a preset pad (rows 5-6).** That stem row's source becomes the tapped preset. Held chop plays normally; row reassigns.

Per spec §4.7: source change takes effect at the next launch-quant boundary. If a chop is held in that row, it migrates per the hot-swap mechanic.

### 4.4 State changes

Add to deviceState (or wherever state lives):

```js
view: "solo" | "perRow",                  // extend the existing view enum
rowSources: {                              // new
  drums: PresetId | null,
  bass:  PresetId | null,
  other: PresetId | null,
  vox:   PresetId | null,
}
```

On entering per-row mode: initialize `rowSources` to all four pointing at the current `activePreset`. On exiting: discard `rowSources`; `activePreset` becomes whatever the drums row's source was.

### 4.5 Source indicator visual

Per spec §4.4: the leftmost pad (col 1) of each stem row shows its source-preset color. Since MK2 doesn't support per-pad outlines, the leftmost pad's *background* becomes the preset's color hue (not the stem's). The chop number "1" still displays.

In solo mode: all four leftmost pads use their stem colors (no source indicator needed).

### 4.6 Mode-entry visual confirmation

Per spec §4.5: when entering per-row mode:
- SOLO pad flashes yellow once (~250ms)
- Leftmost pad of each stem row pulses once in its current source-preset color (~500ms total)

This is the "yes, you're in per-row mode" feedback.

### 4.7 Interactions

- **Hot-swap** in per-row mode: reassigning a row's source migrates held chops in that row at boundary; other rows untouched.
- **Modifiers** work identically in both modes.
- **Scenes** capture mode state — see §6.6 below.
- **FX targets** target by stem regardless of source preset.

### 4.8 Edge cases (from spec §4.8)

| Scenario | Behavior |
|---|---|
| Row's source preset unloaded | Row follows the slot; new content becomes source |
| Per-row entered with no active preset | All rowSources stay null; chop taps are silent with brief error blink |
| Same preset on multiple rows | Allowed; degenerates to solo for those rows |

### 4.9 Acceptance — phase 2

Per spec §9.2:
- [ ] Double-tap SOLO enters per-row mode; SOLO latches yellow
- [ ] Visual confirmation animation fires on entry
- [ ] Hold-chop + tap-preset reassigns row source
- [ ] Cross-song audio confirmed: tapping drums-N + bass-N plays them from different presets simultaneously, in phase
- [ ] Leftmost pad source-tint indicator visible per spec §4.4
- [ ] Held chops survive mode transitions in both directions
- [ ] Held chops survive per-row source reassignment with hot-swap migration
- [ ] Scene save/recall captures rowSources
- [ ] Exit via second double-tap returns to solo mode cleanly

**Commit before phase 3.** Suggested message:

```
setforge-live: multi-song phase 2 — per-row mode

Each stem row (rows 1-4) can independently source from its own
preset assignment. Entered via double-tap SOLO (row 7, col 3),
latches yellow. Exit via second double-tap.

Gesture for reassignment: hold any pad in a stem row + tap a
preset pad (rows 5-6). Held chops migrate per hot-swap mechanic.
Source indicator on col 1 of each stem row shows source-preset hue.

State: rowSources: { drums, bass, other, vox } extends device state.

See device/setforge-live/spec/setforge-live-spec-multi-song-modes.md §4.
```

Surface commit hash and demo summary to Zak. **Wait for acknowledgment before starting phase 3.** Zak should ear-test cross-song mashup before phase 3 begins.

---

## 5. Phase 3 — Staging + pre-loading

Per multi-song spec §5. This is the foundation for dual-song mode but ships standalone; pressing the dual-song toggle in phase 3 should no-op since the view doesn't exist yet.

### 5.1 The staging gesture

1. **Hold deck-setup side button** (right side, position 2). Side button lights bright white. `staging.stagingHeld = true`.
2. **Tap a preset on row 5** → `staging.deckX = thatPresetId`. Begin async pre-load of that preset's stems into deck-X audio slots. Begin flashing that preset pad with the X marker (preset color ↔ white).
3. **Tap a preset on row 6** → same for deck Y, marker color is soft blue (#7799cc).
4. **Release deck-setup** → `staging.stagingHeld = false`. Side button dims to dim white.

Staged pads continue flashing until restaged or reset. The dual-song toggle side button (top-right) updates to show alternating X/Y color.

### 5.2 Pre-load pipeline

When a preset is staged:
1. Look up its stem paths from the manifest.
2. Schedule async loads of all 4 stems into the deck-X (or deck-Y) audio slots.
3. **Do not block the UI thread.** Use whatever async mechanism the existing audio device supports.
4. When all 4 stems for a deck complete loading: `loadedDecks.deckX = staging.deckX` (or Y).
5. **If restaged before load completes:** cancel the in-flight load; start the new one. Don't strand half-loaded songs in memory.
6. **If load fails:** brief red flash on staged pad; clear `staging.deckX`; log error; don't crash.

Note: the actual 8-stem audio routing for dual-song playback doesn't need to be wired up in this phase — phase 4 will do that. For now, just get stems loaded into memory and ready in the deck slots.

### 5.3 State changes

```js
staging: {
  deckX: PresetId | null,
  deckY: PresetId | null,
  stagingHeld: boolean,
},
loadedDecks: {
  deckX: PresetId | null,
  deckY: PresetId | null,
},
lastActiveBankA: PresetId | null,         // update on every row-5 preset tap
lastActiveBankB: PresetId | null,         // update on every row-6 preset tap
```

### 5.4 Visual encoding

Per spec §5.4. Use MK2 native two-color flash (`F0 00 20 29 02 10 23 <pad> <color_a> <color_b> F7`).

Preset pads on rows 5/6:
- **Staged for deck X:** flash between preset color and white (palette index 3)
- **Staged for deck Y:** flash between preset color and soft blue (palette index TBD — find nearest palette match for #7799cc; if no clean match, fall back to software-driven direct-RGB flash on a timer)
- **Staged on both decks:** software-driven 3-color cycle (out of scope for v0 if too complex; can disallow same-preset-on-both-decks as simpler fallback)

Dual-song toggle side button (top-right):
- **Both decks staged:** alternates X's preset color and Y's preset color every ~500ms
- **Only deck X:** solid X color
- **Only deck Y:** solid Y color
- **Neither:** dim white

### 5.5 Side button bindings

Per spec §8. Bind the new buttons:

- **Right side, position 2 = deck-setup** (this phase)
- **Top-right = dual-song toggle** (bind, but no-op until phase 4)

Make sure neither conflicts with existing bindings. The transport side buttons (left side) stay unchanged.

### 5.6 Edge cases (from spec §5.6)

| Scenario | Behavior |
|---|---|
| Stage empty slot | Brief red flash; no assignment |
| Stage a slot whose song gets swapped later | Staging follows slot; pre-loaded stems update |
| Stage same preset on both decks | Allowed; degenerate visual case (see spec) |
| Hold deck-setup, release without tapping | Cleanly exits staging mode, no state change |
| Pre-load fails | Red flash; clear staging for that deck; log; don't crash |

### 5.7 Acceptance — phase 3

Per spec §9.3:
- [ ] Holding deck-setup lights the side button bright white
- [ ] Tapping row 5 preset while staging assigns deck X
- [ ] Tapping row 6 preset while staging assigns deck Y
- [ ] Staged pads flash with MK2 two-color flash (white for X, soft blue for Y)
- [ ] Dual-song toggle side button alternates X/Y when both staged
- [ ] Pre-load completes within a few seconds (verify by inspecting audio engine memory state)
- [ ] Restaging cleanly unloads previous and loads new
- [ ] Staging follows slot, not song
- [ ] Empty slot staging triggers red flash with no assignment
- [ ] Dual-song toggle no-ops correctly (will be wired up next phase)

**Commit before phase 4.** Suggested message:

```
setforge-live: multi-song phase 3 — staging + pre-loading

Adds deck-setup side button (right side, position 2) for staging
presets onto dual-song decks X and Y from performance view.

- State: staging.{deckX, deckY, stagingHeld}, loadedDecks.{deckX, deckY}
- Async pre-load pipeline streams staged stems into deck slots
- MK2 two-color flash visuals: white = X marker, soft blue = Y marker
- Dual-song toggle side button (top-right) bound but no-ops (phase 4)

See device/setforge-live/spec/setforge-live-spec-multi-song-modes.md §5.
```

Surface commit hash and demo summary. **Wait for acknowledgment before starting phase 4.** Zak should verify visually that the staging visuals look right on hardware.

---

## 6. Phase 4 — Dual-song view

Per multi-song spec §6. The actual view flip plus 8-simultaneous-stem audio routing.

### 6.1 Entry / exit gesture

Top-right side button:
- **Hold (momentary):** peek into dual-song mode; release returns to prior view.
- **Double-tap:** latch. Tap once more to exit.

Songs are loaded from `loadedDecks` if populated (from phase 3 staging); otherwise fall back to `lastActiveBankA` and `lastActiveBankB`. If both unstaged AND last-active are undefined → blink red on the toggle; fail to enter.

### 6.2 Layout

Per spec §3.5:

```
row 1-4   song X stems (drums, bass, other, vox)
row 5-8   song Y stems (drums, bass, other, vox)
```

Stem-colored per row regardless of song. Rows 1 and 5 both orange (drums), rows 2 and 6 both blue (bass), etc.

### 6.3 8-stem audio routing

This is the meatiest implementation work in this handoff.

The current architecture has audio device handling 4 voices (the active preset's 4 stems). Dual-song mode needs 8 (X's 4 + Y's 4). Two implementation shapes per spec §7.6:

- **Option A:** extend existing audio device to 8 voices internally, route by row
- **Option B:** add a second audio device for deck Y; existing device becomes deck X

**Pick whichever fits cleanest with your existing two-track architecture.** Surface the decision to Zak with rationale, then proceed.

Either way: pre-loaded stems from phase 3 (sitting in `loadedDecks`) need to be wired up so that tapping a chop in row N of dual-song view fires the correct stem from the correct deck at the correct chop offset.

Chop firing in dual-song view:
```
on_pad_press(launchpad_row, col):
    if launchpad_row in [1,2,3,4]:
        deck = "deckX"
        stem = ["drums","bass","other","vox"][launchpad_row - 1]
    else:  # launchpad_row in [5,6,7,8]
        deck = "deckY"
        stem = ["drums","bass","other","vox"][launchpad_row - 5]
    
    preset_id = loadedDecks[deck]
    chop = manifest[preset_id].stems[stem].chops[col - 1]
    fire_clip(deck, stem, chop.start_sec, chop.length_sec)
```

(Note: chop lookup assumes the curated `chops[]` format from structure analysis is in place. If a preset lacks curated chops, fall back to blind-grid math per the structure-analysis addendum §6.)

### 6.4 Per-row launch quantization

Per spec §6.4. Each row keeps its stem-typed quant regardless of song:
- Rows 1 (X drums), 5 (Y drums) → 1/16
- Rows 2 (X bass), 6 (Y bass) → 1 bar
- Rows 3 (X other), 7 (Y other) → 1/4
- Rows 4 (X vox), 8 (Y vox) → 1/2

Drum-on-drum chording (rows 1 + 5 at same column) locks tight at 1/16 boundaries.

### 6.5 Visual state

- Each row colored by stem (not by song)
- Playing pads: bright/saturated as usual
- Dual-song toggle side button continues showing X/Y color alternation (the same indicator that was active during staging)

### 6.6 Invisible held chops

Per spec §6.6. Held chops from the previous view continue playing but may be invisible in dual-song view if their source preset isn't X or Y.

Add a secondary visual cue on the dual-song toggle side button when invisible-held chops are active. A subtle red overlay on the X/Y alternation, or a slow pulse — pick whichever reads clearly on MK2 hardware and surface to Zak.

### 6.7 Modifiers, scenes, FX in dual-song mode

Per spec §6.5:
- **Modifiers (row 7):** hidden in dual-song view. Modifier presses while in dual-song view are no-ops.
- **Scenes (row 8):** hidden in dual-song view. To save/recall, exit first.
- **FX target:** still works. "Drums" target applies to both row 1 and row 5. "All" applies to all 8 rows.
- **Control view:** still accessible. Hold top-left side button to peek at control view from dual-song.

### 6.8 Exit behavior

When exiting dual-song mode:
- Held chops in dual-song mode keep playing
- Mode reverts to whichever view the user was in before entering (solo or perRow)
- `loadedDecks` stays populated (so re-entering dual-song is still instant)
- `staging` stays populated

### 6.9 Scenes capture view state

Per spec §7.5. Extend the scene-save logic to capture:
- `view` ("solo", "perRow", or "dualSong")
- `activePreset` if solo
- `rowSources` if perRow
- `staging.deckX` and `staging.deckY` always (so recall restores readiness)
- `heldChops[]` with their source presets

On recall: restore view, restore state, retrigger held chops at next bar boundary in their correct positions. Missing `view` field (legacy scenes) → assume `"solo"`.

### 6.10 Acceptance — phase 4

Per spec §9.4 and §9.5:
- [ ] Top-right hold/double-tap toggles dual-song view
- [ ] If staged, entry is instantaneous (no load delay)
- [ ] Without staging, falls back to last-active bank A/B with load latency
- [ ] Grid shows 8 stem rows (X on top, Y on bottom), colored by stem
- [ ] Tapping drums-X chop N + drums-Y chop M plays both simultaneously, in phase, locked within 15ms
- [ ] 8 simultaneous voices play without dropouts
- [ ] Held chops from prior view keep playing (invisible if their preset isn't on display)
- [ ] Invisible-held indicator visible on toggle side button when applicable
- [ ] Exit returns to prior view; chops held in dual-song keep playing
- [ ] Triple-tap PANIC stops everything and exits to solo
- [ ] Scene save in dual-song captures view + staging; recall restores view
- [ ] FX "drums" target applies to rows 1 and 5; "all" applies to all 8

**Commit phase 4.** Suggested message:

```
setforge-live: multi-song phase 4 — dual-song view

The view flip itself. Top-right side button toggles into a view
where all 8 grid rows are stems: rows 1-4 from deck X, rows 5-8
from deck Y. Pre-staged decks make entry instantaneous.

- 8 simultaneous stem voices via [extended audio device | second audio device]
- Stem-typed launch quant preserved across decks
- Scenes capture view state including staging
- Modifiers and scenes hidden in dual-song; control view still peekable
- Invisible-held indicator on toggle side button

See device/setforge-live/spec/setforge-live-spec-multi-song-modes.md §6.
```

Surface final commit hash and full demo summary to Zak. Zak does the load-bearing acceptance test: actually play a drum-on-drum mashup with two real songs and confirm it sounds tight.

---

## 7. Non-goals for this handoff

- **Don't implement v0.2 features:** live mid-mode reassignment in dual-song view (spec §6.7), per-song FX targets (spec §6.5 final paragraph), three-way flash for same-preset-on-both-decks (spec §5.4 footnote).
- Don't touch the structure-analysis pipeline (it's in `taste`, already shipped).
- Don't touch `device/tape-loss/` or `device/punch-fx/`.
- Don't push to remote.
- Don't merge to main.
- Don't change spec docs — they're authoritative. If you find a spec error or ambiguity, surface to Zak rather than working around it.

---

## 8. Ordering — strict

1. Snapshot working state (§1) — surface hash before any phase begins
2. **Phase 1** layout reshuffle → commit → surface hash → wait for ack
3. **Phase 2** per-row mode → commit → surface hash + demo → wait for ack + ear-test
4. **Phase 3** staging + pre-loading → commit → surface hash + demo → wait for ack + visual check
5. **Phase 4** dual-song view → commit → surface hash + demo → final ack

Each phase has its own commit. Each phase's acceptance is verified before the next begins. Skipping ahead is not allowed; the checkpoints catch problems early before they compound.

If any phase fails acceptance, fix and re-commit before moving on.

---

## 9. How to surface questions

Append to `docs/exec-plans/active/setforge-live-handoff-questions.md` (in the main tree). Format consistent with previous handoffs.

Surface (don't guess) if:
- The audio device architecture decision in phase 4 (Option A vs B) isn't clear from the existing code
- MK2 palette colors don't have clean matches for white or soft blue (#7799cc)
- The existing row-flip math doesn't cleanly support the new layout
- Any spec ambiguity blocks implementation
- Acceptance criteria can't be met as written (and you have a proposed adjustment)

---

## 10. Definition of done — entire handoff

- [ ] Working state snapshot committed (if needed)
- [ ] Phase 1 committed; §9.1 acceptance bullets pass
- [ ] Phase 2 committed; §9.2 acceptance bullets pass; Zak ear-tested cross-song mashup
- [ ] Phase 3 committed; §9.3 acceptance bullets pass; staging visuals confirmed on hardware
- [ ] Phase 4 committed; §9.4 + §9.5 acceptance bullets pass; drum-on-drum mashup sounds tight
- [ ] Working tree clean
- [ ] All four views (solo, per-row, dual-song, control) coexist cleanly on the single Launchpad
- [ ] All questions resolved

Surface final commit hashes and a brief summary of each phase to Zak.

---

*end of handoff doc*
