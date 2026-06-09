# setforge-live spec: multi-song modes

**Status:** consolidated spec · supersedes prior addendums (see §11)
**Date:** 2026-05-24
**Replaces:** `setforge-live-spec-dual-song-addendum.md` and the multi-song / single-grid sections of `setforge-live-spec-launchpad-addendum.md` (§4 of that doc — the hardware reference parts of the Launchpad addendum remain authoritative).

This document is the single authoritative reference for setforge-live's multi-song behavior. It covers the layout reshuffle, all four view modes that coexist on Grid 1, the staging-and-pre-loading model, and the dual-song view itself.

It deliberately includes per-row mode (which was previously described in an implementation handoff rather than a spec doc) so the multi-song story lives in one place.

---

## 1. Motivation

setforge-live's original design (main spec §2.2) is a single-mode, single-song instrument: tap a preset, four stem rows source from that one song, play. That's MLR's classic shape and it works.

But live performance benefits from richer multi-song interactions:

- **Sequential cross-song mashup** (already in solo mode via the hot-swap mechanic — tap a new preset, held chops migrate at boundary)
- **Simultaneous per-stem mashup** — drums from song C while bass plays from song F at the same moment (per-row mode)
- **Full-deck simultaneous playback** — all four of song X's stems plus all four of song Y's stems playable at once, enabling drum-on-drum (dual-song mode)

This spec covers all three, organized as a coherent four-view model on one Launchpad. The layout reshuffle is the foundation that makes the additional views fit cleanly.

---

## 2. The four-view model

Grid 1 has four coexisting views. Only one is active at a time. Held audio survives view transitions per §7.4.

| View | Purpose | Entry gesture |
|---|---|---|
| **Solo mode** | Default. All 4 stem rows source from one active preset. | Default; no gesture needed. |
| **Per-row mode** | Each stem row sources from its own preset (cross-song mashup at the stem level). | Double-tap SOLO modifier (latches yellow). |
| **Dual-song mode** | All 8 rows are stems — rows 1-4 from song X, rows 5-8 from song Y. Drum-on-drum + bass-on-bass possible. | Top-right side button (hold = peek, double-tap = latch). |
| **Control view** | Setlist navigation + FX target + transport. Hijacks Grid 1 when no second Launchpad is connected. | Top-left side button (hold = peek, double-tap = latch). |

Solo and per-row are both *performance* views (where you're playing chops). Dual-song is also a performance view but uses the entire grid for stems. Control view is for navigation between performance moves.

**Per-row mode and dual-song mode are mutually exclusive.** Entering one suspends the other; exiting restores the previous state.

A small visual cue tells the user which view is active. See §3.6.

---

## 3. The new Grid 1 layout

### 3.1 Performance-mode layout (solo and per-row)

```
        col 1   col 2   col 3   col 4   col 5   col 6   col 7   col 8
row 1   D1      D2      D3      D4      D5      D6      D7      D8        drums chops
row 2   B1      B2      B3      B4      B5      B6      B7      B8        bass chops
row 3   O1      O2      O3      O4      O5      O6      O7      O8        other chops
row 4   V1      V2      V3      V4      V5      V6      V7      V8        vox chops
row 5   PA      PB      PC      PD      PE      PF      PG      PH        bank A presets (8 slots)
row 6   PI      PJ      PK      PL      PM      PN      PO      PP        bank B presets (8 slots)
row 7   HOLD    MUTE    SOLO    REV     STUT    HALF    DBL     KILL      modifiers (momentary / dbl-tap latch)
row 8   SA      SB      SC      SD      SE      SF      SG      SH        scenes
```

Stems on top (rows 1-4), control below (rows 5-8). All pad-press semantics from main spec §2.2 transfer **unchanged** — only row positions move.

### 3.2 Rationale

Two reasons for stems-on-top, controls-on-bottom:

1. **Cognitive grouping.** Top half = "what you hear right now." Bottom half = "what you do to change it." The mental model is more legible than the original spec's interleaved layout.

2. **Symmetric extension to dual-song mode.** Dual-song mode hijacks all 8 rows for stems (§6). With stems already on top in performance mode, the dual-song mode flip is conceptually a "mirror the top into the bottom" rather than a structural reorg.

### 3.3 Bank A and bank B adjacency

Bank A (row 5) and bank B (row 6) are adjacent. This differs from the original spec's split (row 1 + row 7). Adjacent banks:

- Let the eye scan all 16 loaded songs as one block
- Make the "current rotation" vs "next-bank-on-deck" mental model visible (row 5 = playing, row 6 = waiting)
- Set up the staging gesture cleanly: hold the deck-setup side button, tap row 5 → deck X, tap row 6 → deck Y. The decks are spatially mapped to the banks.

### 3.4 Modifier and scene rows

Row 7 = modifiers, row 8 = scenes. Behaviors unchanged from the original spec §2.4 and §2.5. The two rows are at the bottom so they're consistent across all four views (modifiers may be hidden in dual-song mode per §6; scenes accessible only via exit-and-re-enter while in dual-song mode).

### 3.5 Dual-song view layout

```
        col 1   col 2   col 3   col 4   col 5   col 6   col 7   col 8
row 1   X·D1    X·D2    X·D3    X·D4    X·D5    X·D6    X·D7    X·D8      song X · drums
row 2   X·B1    X·B2    X·B3    X·B4    X·B5    X·B6    X·B7    X·B8      song X · bass
row 3   X·O1    X·O2    X·O3    X·O4    X·O5    X·O6    X·O7    X·O8      song X · other
row 4   X·V1    X·V2    X·V3    X·V4    X·V5    X·V6    X·V7    X·V8      song X · vox
row 5   Y·D1    Y·D2    Y·D3    Y·D4    Y·D5    Y·D6    Y·D7    Y·D8      song Y · drums
row 6   Y·B1    Y·B2    Y·B3    Y·B4    Y·B5    Y·B6    Y·B7    Y·B8      song Y · bass
row 7   Y·O1    Y·O2    Y·O3    Y·O4    Y·O5    Y·O6    Y·O7    Y·O8      song Y · other
row 8   Y·V1    Y·V2    Y·V3    Y·V4    Y·V5    Y·V6    Y·V7    Y·V8      song Y · vox
```

8 simultaneous voices possible (one per row). Drum-on-drum, bass-on-bass, anything-on-anything.

### 3.6 Control view layout

```
        col 1   col 2   col 3   col 4   col 5   col 6   col 7   col 8
row 1   T01     T02     T03     T04     T05     T06     T07     T08      setlist tracks 1-8
row 2   T09     T10     T11     T12     T13     T14     T15     T16      setlist tracks 9-16
row 3   T17     T18     T19     T20     T21     T22     T23     T24      setlist tracks 17-24
row 4   T25     T26     T27     T28     T29     T30     T31     T32      setlist tracks 25-32
row 5   DRM     BASS    OTH     VOX     ALL     DECKA   DECKB   MSTR     fx target select
row 6   F1      F2      F3      F4      F5      F6      F7      F8       fx-A (filter sweep)
row 7   X1      X2      X3      X4      X5      X6      X7      X8       fx-B (throws)
row 8   SA      SB      SC      SD      SE      SF      SG      SH       scenes (still accessible)
```

Scenes (row 8) appear in both performance views and control view. They're always reachable regardless of mode.

When a second Launchpad is sourced, control view permanently moves to Grid 2 and Grid 1 no longer needs the toggle. Until then, single-grid mode (per the Launchpad hardware addendum) keeps all four views on one device.

---

## 4. Per-row mode

### 4.1 What it does

Each stem row sources from its own preset assignment. Drums row from preset C, bass row from preset F, other from preset A, vox from preset D — all simultaneously. The MLR classic mashup move.

### 4.2 Entry / exit gestures

**Enter:** double-tap **SOLO** (row 7, col 3). SOLO latches yellow.

**Exit:** double-tap SOLO again. Latch releases.

On entry, the four stem rows initially keep whatever preset assignment they had (typically all pointing at the current active preset). The user then assigns rows individually.

### 4.3 Per-row preset assignment

While in per-row mode:

**Hold any pad in a stem row (rows 1-4) + tap a preset pad (rows 5-6).** That stem row's source becomes the tapped preset.

- The held chop continues to play normally (don't suppress its press — just *also* reassign the row).
- The row's stem-color identity is unchanged (drums row stays orange, etc.); only the source song changes.
- The source change takes effect at the next launch-quant boundary for that row (per main spec §2.4). If a chop in that row is held, it migrates per the hot-swap mechanic (main spec §2.5) — same column position, new source preset.

### 4.4 Source indicator

In per-row mode, the **leftmost pad (col 1) of each stem row** shows its source-preset color as a border tint. This tells the user at a glance which preset each row is sourcing from.

MK2 hardware caveat: the MK2 doesn't support actual borders or outlines (one color per pad). The "tint" is implemented as: **the leftmost pad's background is the preset's color hue instead of the stem's color**. So in per-row mode, drums chop 1 (normally soft orange) might be soft yellow if drums row is sourcing from a yellow-hued preset. The chop number "1" still displays; only the background shifts.

The user can read it as: "left edge of each stem row tells me the source preset." Once muscle memory builds, this is fast.

In solo mode, all four leftmost pads use their normal stem colors (no source indicator needed since all rows share one preset).

### 4.5 Mode-entry visual confirmation

When entering per-row mode (SOLO double-tap):
- SOLO pad flashes yellow once
- The leftmost pad of each stem row (col 1 of rows 1-4) pulses once in its current source-preset color

Total animation: ~500ms. This tells the user "yes, you're now in per-row mode."

### 4.6 State changes

```js
deviceState = {
  // ...existing...
  view: "solo" | "perRow" | "dualSong" | "control",
  activePreset: PresetId,           // used in solo mode
  rowSources: {                     // used in per-row mode
    drums: PresetId,
    bass: PresetId,
    other: PresetId,
    vox: PresetId,
  },
}
```

On entering per-row mode: `rowSources` is initialized to all four pointing at the current `activePreset`. Held chops continue playing (tied to their original preset's chops, not to mode).

On exiting per-row mode: `rowSources` is discarded. `activePreset` becomes whatever the drums row's source was (arbitrary but deterministic). Held chops continue playing.

### 4.7 Interactions with other features

- **Hot-swap mechanic:** in per-row mode, swapping a row's source preset has the same migrate-at-boundary behavior as a full preset swap, but applied only to that row. Other rows are untouched.
- **Modifiers (row 7):** work identically in both solo and per-row modes. Applied to whichever chop is tapped.
- **Scenes (row 8):** scenes capture mode state — see §7.6.
- **FX target (Grid 2 row 5 / Control view row 5):** the four stem targets (drums/bass/other/vox) target whichever audio is in that row, regardless of source preset. Targeting is by stem, not by song.

### 4.8 Edge cases

| Scenario | Behavior |
|---|---|
| Row's source preset is unloaded (e.g., user assigned bass row to preset F, then loaded a different song into slot F) | Row follows the slot, not the song. Slot F's new content becomes the source. |
| User enters per-row mode with no preset active at all (fresh load) | All four rowSources stay null until assigned. Tapping a chop with a null source = silent pad press with brief error blink. |
| Same preset assigned to multiple rows | Allowed. Both rows source from the same song's respective stems. Degenerate to solo mode for those rows. |

---

## 5. Staging and pre-loading (for dual-song mode)

### 5.1 What staging is

Staging is the act of explicitly assigning two presets to dual-song decks X and Y **while still in performance view**. Staging is decoupled from entering dual-song mode: you stage in advance, the audio engine pre-loads both songs in the background, and the eventual flip into dual-song view is instantaneous.

The user's mental model: "I'm about to do a layered mashup with C and F. Let me pre-load them now while I'm finishing this solo-mode chop sequence. Then when the musical moment arrives, I flip into dual-song view and they're already there."

### 5.2 The staging gesture

1. **Hold the deck-setup side button** (right side of the Launchpad, position 2 from the top — see §10.2 for full side-button map).
2. While held, the preset rows (rows 5 and 6) enter staging mode.
3. **Tap a preset on row 5 (bank A)** → that preset is staged on **deck X** (the top half of dual-song mode).
4. **Tap a preset on row 6 (bank B)** → that preset is staged on **deck Y** (the bottom half of dual-song mode).
5. **Release the deck-setup side button** to exit staging mode.

Staging is a planning move. The user remains in their current performance view throughout — no view change happens, no chops stop, nothing is interrupted.

### 5.3 Pre-loading semantics

When a preset is staged, the device immediately begins streaming its stems into the audio engine in the background. This typically takes a few seconds and is non-blocking.

By the time the user actually enters dual-song mode (which may be seconds, minutes, or never), both staged songs are already warm. The flip into dual-song view is therefore instantaneous regardless of preset size.

If the user restages mid-set: the previously-staged songs are unloaded from the dual-song audio engine (if they're not also currently held in performance view); the new songs begin pre-loading.

### 5.4 Visual encoding of staging

Because MK2 hardware supports only one color per pad (no outlines, no borders), the staging indicator uses **MK2's native two-color flash** (`F0 00 20 29 02 10 23 <pad> <color_a> <color_b> F7`) to alternate between the preset's normal color and a deck-marker color.

**Visual state encoding for preset pads (rows 5 and 6):**

| State | Visual | MK2 mechanism |
|---|---|---|
| Empty slot | Off | (no SysEx) |
| Loaded, idle | Solid soft preset color | Direct RGB |
| Loaded, active (sourcing chops in performance view) | Solid bright preset color, slow pulse every bar | Palette pulse |
| Staged for **deck X** | Flash between preset color and **white** | Two-color flash |
| Staged for **deck Y** | Flash between preset color and **soft blue (#7799cc)** | Two-color flash |
| Staged for both decks (same preset staged twice) | Software-driven 3-color cycle (preset color, white, soft blue) on slow timer | Custom (direct RGB with timer) |
| Active AND staged | Solid bright + slow pulse (active wins visually; side button conveys staging) | Palette pulse |

**Side-button indicator for deck identity (the primary cue):**

The **dual-song toggle side button (top-right)** shows the currently-staged decks via alternating color:
- Both decks staged → alternates X's preset color and Y's preset color every ~500ms
- Only deck X staged → solid X color (deck Y dim/empty until staged)
- Only deck Y staged → solid Y color
- Neither staged → dim white (no staging applied; entry will use fallback per §5.5)

The **deck-setup side button (right side, position 2)** shows:
- Idle (not held) → dim white
- Held (user is staging) → bright white

**Color choice rationale:** white and soft blue are chosen as deck markers because they're maximally distinct from all stem colors (orange, blue, grey, green) and from the modifier-latch yellow. The user's eye reads them clearly without confusion. Flash (alternation) rather than pulse (breathing) is chosen because pulse is already used for "active preset" — the eye reads alternation vs breathing as fundamentally different signals.

### 5.5 Fallback when nothing is staged

If the user enters dual-song mode without having explicitly staged anything, the device falls back to:
- Deck X = most-recently-active preset on row 5 (bank A)
- Deck Y = most-recently-active preset on row 6 (bank B)

This auto-default exists so that pressing the dual-song button "just works" for users who haven't yet learned the staging gesture. But it incurs the cost of song-load latency at the moment of view entry (1-3 seconds depending on stem size). The explicit staging path is always preferable.

If both fallback presets are also undefined (the user has never tapped a preset on either bank), dual-song mode fails to enter. The toggle side button blinks red briefly to surface the failure.

### 5.6 Edge cases

| Scenario | Behavior |
|---|---|
| Stage an empty preset slot | Brief red flash on that pad; no staging applied |
| Stage a slot, then song in that slot gets swapped | Staging follows the slot, not the song; the pre-loaded stems update accordingly |
| Stage the same preset on both decks | Allowed. Both pads flash with their respective marker colors. The dual-song toggle side button alternates the same color twice (effectively solid). |
| Hold deck-setup but never tap a preset | Releases cleanly; no state change. |
| Tap deck-setup briefly without staging (just a tap, no hold) | No-op. Treated as a press with nothing tapped after. |
| Pre-load fails (file missing, etc.) | Flash red on staged pad; clear that deck's staging; log error; don't crash. |

### 5.7 Restaging mid-set

The staging gesture works any time the device is in performance view. To change which songs are staged, hold deck-setup and tap new presets. The previously-staged songs are unloaded from the dual-song audio engine if no chops from them are currently held; the new songs begin pre-loading.

Restaging is allowed even while dual-song mode is active in another performance view (e.g., if the user popped back to solo mode to restage). However, in v0, **restaging while currently in dual-song mode is not supported** — see §6.7.

---

## 6. Dual-song mode

### 6.1 Entry gesture

**Top-right side button** of the Launchpad is the dual-song mode toggle.

| Gesture | Result |
|---|---|
| Tap (momentary) | Hold-to-peek into dual-song mode. Release returns to whatever performance view you were in (solo or per-row). |
| Double-tap | Latch into dual-song mode. Tap once more to exit. |

Because songs are pre-staged (§5), the audio engine is already warm at the moment the user presses this button. The view flip is instantaneous.

### 6.2 Layout

See §3.5. Rows 1-4 = song X stems, rows 5-8 = song Y stems. Each row keeps its stem color (drums orange, bass blue, other grey, vox green) regardless of which song it's from.

### 6.3 Visual state

**Stem coloring:** each row keeps its stem color. So rows 1 and 5 are both orange (drums-X and drums-Y), rows 2 and 6 are both blue, etc. This makes "which stem is this row" instantly readable.

**Song identity:** the dual-song toggle side button's alternating X/Y color is the primary indicator of which two songs are loaded. Pads tell you what kind of sound; the side button tells you whose song.

**Cross-row chording:** when you play drums-X chop 9 + drums-Y chop 9 simultaneously, both pads light bright orange. They're in different rows so you can tell them apart musically — but a quick glance reveals "I'm chording across decks."

### 6.4 Per-row launch quantization in dual-song mode

Each row keeps its own launch quantization derived from its stem type, regardless of which song it's from:

| Row | Stem | Quant |
|---|---|---|
| 1 (X drums), 5 (Y drums) | drums | 1/16 |
| 2 (X bass), 6 (Y bass) | bass | 1 bar |
| 3 (X other), 7 (Y other) | other | 1/4 |
| 4 (X vox), 8 (Y vox) | vox | 1/2 |

Drum-on-drum chording at 1/16 boundaries (both rows quant the same) locks tight. Cross-stem chording at different quants works fine — each chop fires at its own next boundary.

### 6.5 Modifiers, scenes, and FX in dual-song mode

- **Modifiers (row 7 in performance view, hidden in dual-song):** unavailable while in dual-song mode. To apply a modifier to a chop, exit, apply, re-enter. Deliberate trade-off.
- **Scenes (row 8 in performance view, hidden in dual-song):** unavailable. Exit to save/recall. Scenes capture full state including staging — see §7.6.
- **Preset hot-swap:** no preset swap available in dual-song mode. The two songs are fixed for the duration.
- **Control view:** still accessible. Hold top-left side button to peek at control view from dual-song mode.
- **FX target selector (Control view row 5):** still works. "Drums" target → applies to both drum rows (X and Y) simultaneously. "All" → all 8 rows. No per-song FX target in v0 (deferred).

### 6.6 Invisible held chops

When the user enters dual-song mode, any chops held in the previous view continue playing — but if their source song isn't currently shown on the dual-song grid, they're playing "invisibly."

This can feel disorienting. A small visual cue helps: while in dual-song mode, the **dual-song toggle side button** has a secondary indicator (a subtle red tint or slow pulse overlay on the X/Y color alternation) when invisible-held chops are active. This tells the user "audio is playing that's not visible here."

Same applies in reverse: chops held while in dual-song mode keep playing when the user exits, becoming invisible-held in the performance view if the underlying preset isn't currently visible.

### 6.7 Reassignment while in dual-song mode (deferred to v0.2)

In v0, dual-song mode is "fixed": the songs assigned to decks X and Y at entry remain in place until the user exits. To swap a deck, exit, restage, re-enter.

This is a deliberate simplification. Live mid-mode reassignment (a gesture to temporarily expose preset pads while in dual-song view) is interesting but adds complexity that's not justified until the basic workflow is proven. Revisit in v0.2.

### 6.8 Edge cases

| Scenario | Behavior |
|---|---|
| Enter dual-song with only 1 song loaded total | Fails to enter. Toggle side button blinks red briefly. |
| Enter with staged X but unloaded Y | Falls back to last-active bank B preset. If no such preset, fails to enter. |
| Held chops from per-row mode (4 different songs) when entering dual-song | All 4 keep playing invisibly. Toggle side button shows invisible-held cue. |
| Triple-tap PANIC while in dual-song mode | All audio stops. Mode reverts to solo. |
| USB disconnect mid-dual-song | Audio continues; surface flushes on reconnect; dual-song state preserved. |
| Tap a chop in row 5 (Y drums) immediately after entering | Plays. Y's drums chop. Normal launch quant. |

---

## 7. State model and transitions

### 7.1 Full state shape

```js
deviceState = {
  // current view
  view: "solo" | "perRow" | "dualSong" | "control",
  
  // solo + per-row preset state
  activePreset: PresetId | null,
  rowSources: {                              // used only in perRow
    drums: PresetId | null,
    bass:  PresetId | null,
    other: PresetId | null,
    vox:   PresetId | null,
  },
  
  // staging state (independent of current view)
  staging: {
    deckX: PresetId | null,
    deckY: PresetId | null,
    stagingHeld: boolean,
  },
  
  // what's currently loaded into the dual-song audio engine
  loadedDecks: {
    deckX: PresetId | null,
    deckY: PresetId | null,
  },
  
  // fallback for unstaged dual-song entry
  lastActiveBankA: PresetId | null,
  lastActiveBankB: PresetId | null,
  
  // chops playing across views
  heldChops: Array<{
    presetId: PresetId,
    stem: "drums" | "bass" | "other" | "vox",
    chopIndex: number,
    clipHandle: ClipHandle,
    visibleInCurrentView: boolean,           // computed; for invisible-held indicator
  }>,
  
  // modifier latch state
  modifiers: {
    holdLatched: boolean,
    soloLatched: boolean,                    // true ⇔ view === "perRow"
    // ...other modifiers...
  },
}
```

### 7.2 Mode entry/exit transitions

```
solo ────[double-tap SOLO]────► perRow
    ◄────[double-tap SOLO]────

solo / perRow ────[top-right side btn]────► dualSong
            ◄────[top-right side btn]────

any ────[top-left side btn]────► control
   ◄────[top-left side btn]────
```

Per-row mode and dual-song mode are mutually exclusive. Entering dual-song from per-row temporarily suspends per-row state — when you exit dual-song, per-row state restores (SOLO modifier still latched, row sources still assigned).

### 7.3 What survives transitions

- **Held chops always survive.** Entering any view never stops audio. Some chops may become "invisible-held" if their source preset isn't shown in the new view; they're indicated per §6.6.
- **Staging always survives.** Staging is independent of current view.
- **Modifier latches always survive** (SOLO latch is the per-row mode signal; other latches persist across views).
- **Active preset survives across solo↔perRow transitions** but is implicitly redefined on dualSong entry/exit (deck X / deck Y assignment).

### 7.4 Hot-swap continuity rules

The hot-swap mechanic from main spec §2.5 extends to multi-song scenarios:

- **In solo mode:** tap a new preset → held chops migrate at boundary (existing behavior).
- **In per-row mode:** assigning a new preset to a row → that row's held chops migrate at boundary; other rows untouched.
- **Entering dual-song mode:** held chops from the previous view stay live but are not migrated (they're still tied to their original preset; they continue playing invisibly if their preset isn't on display).
- **Exiting dual-song mode:** chops held in dual-song stay live, same rule in reverse.

### 7.5 Scenes capture view state

Per main spec §2.4, scenes are full-grid snapshots. With multi-song modes, scene snapshots additionally capture:

- Current view (solo / perRow / dualSong)
- `activePreset` (if solo)
- `rowSources` (if perRow)
- `staging.deckX` and `staging.deckY` (always; useful for restoring readiness)
- `heldChops[]` with their source presets

On scene recall, the view itself is restored (recalling a scene saved in dual-song mode will pop you back into dual-song mode automatically).

Backward compatibility: scenes saved before this spec lacks the `view` field. On recall, missing `view` is treated as `"solo"`.

### 7.6 Audio routing implications

Dual-song mode requires **8 simultaneous stem voices** to be ready (not 4). The audio device architecture (currently two-track: MIDI device + audio device) may need extending. Two reasonable shapes:

**Option A:** extend the existing audio device to handle 8 voices (4 for X, 4 for Y). One audio device, two parallel "decks" internally, summed to the master.

**Option B:** add a second audio device (audio-X and audio-Y). The MIDI device routes triggers to the right audio device based on row.

Option B is cleaner conceptually (mirrors the dual-song "two songs" mental model) but adds complexity to the MIDI routing. Option A is more compact. **Implementation should pick whichever fits cleanest with the existing two-track architecture; this is an implementation decision, not a spec decision.**

Either way: pre-loading (§5.3) needs to route staged stems into the right deck slot. The audio engine maintains slots for "deck X" and "deck Y" simultaneously, populated from staging gestures.

---

## 8. Side-button bindings

Updated for the multi-song work. Replaces the assignments in the Launchpad hardware addendum §4.

| Side button position | Function | Phase introduced |
|---|---|---|
| Top-left | Control view toggle | existing |
| Top-right | **Dual-song mode toggle** | new (§6) |
| Right side, position 2 | **Deck-setup (staging)** | new (§5) |
| Left side, all 8 buttons | Transport: tap, sync, BPM-, BPM+, loop-in, loop-out, panic, reserved | existing |
| Right side, positions 3-8 | Reserved for future expansion | n/a |

When the second Launchpad is sourced, the dual-song toggle and deck-setup buttons remain on Grid 1 (because they affect Grid 1's view, not Grid 2's). The control-view toggle becomes redundant since Grid 2 permanently shows the control view.

---

## 9. Acceptance criteria

### 9.1 Layout reshuffle is done when

- [ ] Solo mode: stems in rows 1-4, banks in rows 5-6, modifiers in row 7, scenes in row 8.
- [ ] All existing solo-mode behaviors function identically; only row positions have changed.
- [ ] Per-row mode source-tint indicator (when implemented) appears on col 1 of rows 1-4.
- [ ] Pad reference card updated.

### 9.2 Per-row mode is done when

- [ ] Double-tap SOLO (row 7, col 3) enters per-row mode; SOLO pad latches yellow.
- [ ] Visual confirmation animation fires on entry (SOLO flash + leftmost-stem-pads pulse).
- [ ] Hold-chop + tap-preset gesture reassigns that row's source preset.
- [ ] Once two rows have different sources, audio confirms: tapping drums-chop-N plays preset-X's drums; tapping bass-chop-N plays preset-Y's bass; both simultaneously, on the global grid, in phase.
- [ ] Leftmost pad of each stem row shows source-preset color tint.
- [ ] Held chops survive mode transitions (entering and exiting per-row).
- [ ] Held chops survive per-row source reassignment with the hot-swap migration.
- [ ] Scene save in per-row mode captures `rowSources`; recall restores it.
- [ ] Double-tap SOLO exits cleanly back to solo mode.

### 9.3 Staging is done when

- [ ] Holding the deck-setup side button (right side, position 2) enters staging mode (side button lights bright white).
- [ ] Tapping a preset on row 5 while staging assigns it to deck X.
- [ ] Tapping a preset on row 6 while staging assigns it to deck Y.
- [ ] Staged pads visually distinguish via MK2 two-color flash (preset color ↔ white for X, preset color ↔ soft blue for Y).
- [ ] The dual-song toggle side button alternates X color and Y color when both decks are staged.
- [ ] Audio engine begins pre-loading stems immediately on staging (verify by checking memory state within a few seconds).
- [ ] Restaging unloads the previously-staged song and loads the new one without disrupting current playback.
- [ ] Staging follows slot, not song.
- [ ] Staging an empty slot briefly flashes red; no assignment.
- [ ] Top-right dual-song toggle is bound but no-ops if dual-song view isn't yet implemented (or works correctly if it is).

### 9.4 Dual-song mode is done when

- [ ] Top-right side button hold/double-tap toggles into dual-song mode.
- [ ] If decks were staged in advance, the view flip is instantaneous (no audible load delay).
- [ ] Without staging, falls back to last-active bank A/B with associated load latency.
- [ ] Grid shows 8 rows of stems: rows 1-4 from X, rows 5-8 from Y.
- [ ] Each row colored by stem (drums orange in rows 1 and 5, etc.).
- [ ] Tapping drums-X chop N + drums-Y chop M plays both simultaneously, drum-on-drum, in phase, kick-on-kick locked within ~15ms.
- [ ] Held chops from the previous view continue playing while in dual-song (invisible).
- [ ] Invisible-held indicator visible on dual-song toggle side button.
- [ ] Exiting returns to prior view; chops held in dual-song mode keep playing.
- [ ] Triple-tap PANIC stops all chops and exits dual-song mode.
- [ ] Scenes saved in dual-song mode capture view state; recall restores view.

### 9.5 Audio integrity is done when

- [ ] 8 simultaneous stem voices play without dropouts.
- [ ] No audible swap latency on view transitions (held chops survive cleanly).
- [ ] FX target "drums" applies to both drum rows when in dual-song.
- [ ] FX target "all" applies to all 8 rows.

---

## 10. Glossary

| Term | Definition |
|---|---|
| **Solo mode** | Default performance view. All 4 stem rows source from one active preset. |
| **Per-row mode** | Performance view in which each stem row sources from its own independent preset assignment. Entered via double-tap SOLO. |
| **Dual-song mode** | Performance view in which all 8 rows are stems — rows 1-4 from song X, rows 5-8 from song Y. Entered via top-right side button. |
| **Control view** | Navigation view showing setlist + FX target + transport. Entered via top-left side button. Used in single-grid mode; replaced by Grid 2 when present. |
| **Staging** | Explicit assignment of presets to dual-song decks X and Y in advance of entering dual-song mode. Triggers async pre-loading. |
| **Deck X / Deck Y** | The two songs loaded for dual-song mode. X = top half (rows 1-4), Y = bottom half (rows 5-8). |
| **Deck-setup side button** | Right side, position 2. Held while tapping presets on rows 5/6 to stage. |
| **Pre-loading** | Async background streaming of staged stems into the audio engine. Eliminates entry latency for dual-song mode. |
| **Last-active bank A/B** | Most recently tapped preset on row 5 or row 6. Used as fallback song assignment if dual-song entered without staging. |
| **Invisible held chops** | Chops playing audibly but not visible on any current-view pad due to view change. Indicated by a secondary cue on the relevant side button. |
| **Hot-swap mechanic** | When a preset is tapped (in solo) or a row's source is reassigned (in per-row), held chops migrate to the new preset at the next launch-quant boundary. From main spec §2.5. |

---

## 11. Supersession notes

This document supersedes:

- **`setforge-live-spec-dual-song-addendum.md`** (all sections)
- **`setforge-live-spec-launchpad-addendum.md` §4** (single-grid mode UX — the hardware reference parts of that addendum remain authoritative)

It also formally specifies per-row mode, which was previously described only in the implementation handoff `setforge-live-handoff-phase5b-6.md` §3. That handoff remains as historical context but the spec lives here.

The other addendums remain in force:
- `setforge-live-spec.md` (main spec) — base behaviors and chop math
- `setforge-live-spec-launchpad-addendum.md` §§1-3, 5-9 — MK2 hardware reference
- `setforge-live-spec-structure-analysis-addendum.md` — curated chops format and analysis pipeline
- `setforge-live-spec-related-work-addendum.md` — positioning vs `terms` and MLR

---

*end of multi-song modes spec*
