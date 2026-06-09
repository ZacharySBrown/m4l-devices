# setforge-live — Multi-Song Mode Reference

Technical reference for the multi-song features of the deployed `loader-controller.js`
monolith (3,867 lines). Audience: debugging or future implementer.

**Source of truth.** This document describes the **deployed** controller only. All
`(loader-controller.js:NNN)` citations refer to that file. The build concatenates
`launchpad-surface-mk2.js`, `launchpad-surface-mk3.js`, `launchpad-surface.js`,
`loader-controller.js` into a device-root `loader.js`; the `.amxd` js box loads that
monolith. The modular `src/loader/{chop-router,fx-bus,modifier-layer,preset-banks,scene-memory}.js`
and `src/shared/*` are **NOT deployed** (`build_setforge.py:846-851`). The surface is
hardcoded to MK2 via `createSurface("mk2")` (`loader-controller.js:19`); the MK3 surface
is concatenated but dead in deployment.

**Honesty contract.** Where a feature is a stub, inert, partial, broken, or absent, this
doc says so. Do not infer working audio behavior from a pad lighting up.

---

## 1. Pad layout per view

`ROW_STEM = {1:drums, 2:bass, 3:other, 4:vox}`; `STEM_NAMES = [drums,bass,other,vox]`
(`loader-controller.js:34-37`). Rows are 1=top … 8=bottom in controller space (LP rows
are flipped vertically; see §7).

There is **no single `view` enum.** The four conceptual views are emergent from three
independent variables — see §3. "View" below means the emergent rendering/dispatch state.

### Solo / performance view (default) — `updateGrid1Colors` (`:1708-1781`)

| Row | Content | Notes |
|---|---|---|
| 1 | drums chops (8 cols of active preset) | `STEM_COLORS.drums` |
| 2 | bass chops | `STEM_COLORS.bass` |
| 3 | other chops | `STEM_COLORS.other` (yellow/olive) |
| 4 | vox chops | `STEM_COLORS.vox` |
| 5 | bank A presets (slots 0-7) | `presetSlotColor` |
| 6 | bank B presets (slots 8-15) | `presetSlotColor` |
| 7 | modifiers: HOLD MUTE SOLO REV STUT HALF DBL KILL | `MOD_COLORS`; cols 1-8 = modIndex 0-7 |
| 8 | scenes (8) | `SCENE_COLORS` |

This row order is **inverted vs the stale §1.4 base-spec diagram** (which put presets on
rows 1/7 and stems on 2-5). Code at `:1708-1774` is ground truth; the diagram is stale.

### Per-row view — `chopPadColor` swaps source per row (`:1891-1916`)

Same row layout as solo. Difference: each stem row 1-4 sources chops from its own
`rowSources[stem]` slot instead of `activeSlotIndex`. The leftmost pad (col 1) of a
per-row-sourced stem renders the **source preset's palette color** instead of the stem
soft color (`:1911-1912`), so you can see where each row is pulling from.

> CAVEAT: the col-1 source tint is suppressed when a chop is actively playing in col 1.
> `if (playingChops[stem]===col) return STEM_COLORS[stem].bright` (`:1908`) runs **before**
> the col-1 source-tint branch (`:1911`). A held col-1 chop shows bright stem color, not
> the source tint. (Open question §15.7 in the catalog.)

### Dual-song view — `updateDualSongColors` (`:1783-1820`)

All 8 rows are stems; rows split across two decks.

| Rows | Deck | Source | Stems (per row) |
|---|---|---|---|
| 1-4 | deck X | `loadedDecks.deckX`, `stemTrackIdsX` | drums, bass, other, vox |
| 5-8 | deck Y | `loadedDecks.deckY`, `stemTrackIdsY` | drums, bass, other, vox |

Cell states: empty → off `[0,0,0]`; disabled chop → `[40,0,0]`; playable → stem soft;
playing → stem bright. All 8 rows route to `onDualSongChopPress` (`:2354-2359`).

### Control view (single-grid overlay) — `updateControlViewColors` (`:1655-1706`)

Only active when `singleGridMode && viewMode=='control'`. It hijacks Grid 1; press
routing splits row 8 → `handleGrid1Press` (scenes), rows 1-7 → `handleGrid2Press`
(`:2121-2131`).

| Row | Content |
|---|---|
| 1-4 | 32-pad setlist (`i = row*8 + col`, genre-colored; dimmed ×0.5 if not loaded into a slot) |
| 5 | FX target select (`FX_TARGETS`: drums,bass,other,vox,all,deckA,deckB,master; selected bright) |
| 6 | FX-A filter sweep (8 cols; active dim/bright, latched full white) — **visual only** |
| 7 | FX-B throws (active orange `[127,80,0]`) — **visual only** |
| 8 | scenes |

> When a second Launchpad is present (`!singleGridMode`), Grid 2 uses `updateGrid2Colors`
> — similar but row 8 = transport colors instead of scenes (`:1655-1706`, catalog §8).

> The control-view FX rows (5/6/7) and Grid-2 FX bus are **inert**: `fxTarget`,
> `fxFilterCol`, `fxFilterLatched`, `fxThrowCol` drive only pad color + status text. Zero
> LiveAPI/audio. `FILTER_POSITIONS` (lp/hp freq table) is defined but never referenced.
> `punch` has 0 grep hits. (`:609-619`, `:122-131`, `:2834-2873`, `:1684-1699`, `:1851-1870`)

---

## 2. Side button bindings

Notes are MIDI note numbers on the LP's side columns. Left/right indices are top→bottom.

### Left side buttons — `SIDE_BUTTONS_LEFT` / `SIDE_FUNC` (`:49`, `:2105-2109`, `:2167-2217`)

`SIDE_BUTTONS_LEFT = [80,70,60,50,40,30,20,10]`.

| Idx | Function | Note | Behavior | Code |
|---|---|---|---|---|
| 0 | MODE_TOGGLE | 80 | Momentary perf↔control; double-tap (<400ms) latches `viewModeLatched` | `:2170-2183`, release reverts `:2212` |
| 1 | TAP | 70 | `outlet(2,'tap_tempo')` | `:49`, `:2105-2109` |
| 2 | SYNC | 60 | `'sync'` | `:49` |
| 3 | BPM_DOWN | 50 | `bpm_nudge -0.1` | `:49` |
| 4 | BPM_UP | 40 | `bpm_nudge +0.1` | `:49` |
| 5 | LOOP_IN | 30 | `'loop_in'` | `:49` |
| 6 | LOOP_OUT | 20 | `'loop_out'` | `:49` |
| 7 | PANIC | 10 | Triple-tap within 1000ms windows → `executePanic()` | `:2196-2206` |

### Right side buttons — `SIDE_BUTTONS_RIGHT` / `SIDE_FUNC_RIGHT` (`:78-79`, `:2096-2098`, `:2111-2116`, `:2223-2274`)

`SIDE_BUTTONS_RIGHT = [89,79,69,59,49,39,29,19]`;
`SIDE_FUNC_RIGHT = ["DUAL_SONG_TOGGLE", "DECK_SETUP", null, null, null, null, null, null]`.

| Idx | Function | Note | Behavior | Code |
|---|---|---|---|---|
| 0 | DUAL_SONG_TOGGLE | 89 | Single tap+hold = momentary peek; double-tap (<400ms) = latch | `:2226-2247` |
| 1 | DECK_SETUP | 79 | Hold → staging mode; SOLID bright white `[127,127,127]` while held | `:2248-2272` |
| 2-7 | (inert) | 69,59,49,39,29,19 | null / no handler | `:79` |

**There is no SHIFT side-button binding in either array or any handler.** The SHIFT role
is served by the HOLD row-7 pad (see §5). `SHIFT` = 0 grep hits.

---

## 3. State model — the actual shape

The "view" is **three variables, not one enum.** Document and debug accordingly.

### View axis (three independent variables)

| Variable | Decl | Type / values | Controls |
|---|---|---|---|
| `performanceView` | `:59` | string: `"solo"` or `"perRow"` ONLY | Solo vs per-row within performance. Never assigned `"dualSong"` or `"control"`. |
| `dualSongActive` | `:60` | boolean | When true, dual-song dispatch overrides `performanceView` (suspends per-row). |
| `viewMode` | `:52` | string: `"performance"` or `"control"` | Control overlay. Orthogonal to the other two. |

Emergent view resolution:
- **solo** = `performanceView=='solo' && !dualSongActive && viewMode=='performance'`
- **perRow** = `performanceView=='perRow' && !dualSongActive`
- **dualSong** = `dualSongActive` (overrides `performanceView` in dispatch)
- **control** = `viewMode=='control' && singleGridMode` (overlay/hijack of Grid 1)

`viewMode` is **orthogonal**: control view can coexist with `dualSongActive==true` or
`performanceView=='perRow'`. "Only one active" is NOT enforced across the control axis
(`:2170-2183`). The strings `"dualSong"` and `"control"` exist as a unified 4-value field
ONLY in serialized scene snapshots (`:576`), reconstructed into the three live vars on
recall.

### Per-row source state

| Variable | Decl | Shape | Controls |
|---|---|---|---|
| `rowSources` | `:65-66` | `{drums,bass,other,vox}`, each null or int slot (0..TOTAL_SLOTS-1) | Which preset slot each stem row pulls chops from in per-row mode. Read by `getEffectivePreset(stem)` and `chopPadColor` ONLY when `performanceView=='perRow'`. |
| `activeSlotIndex` | (global) | int, `-1` = none | The single active preset used in solo mode and as per-row seed (`:2422`). Also the `isFirstActivation` sentinel (`<0`). |

### Staging state

| Variable | Decl | Shape | Controls |
|---|---|---|---|
| `staging.deckX` | `:66 area` | null or int slot | Slot staged onto deck X tracks (`stemTrackIdsX`, `sf-{stem}-x`). |
| `staging.deckY` | | null or int slot | Slot staged onto deck Y tracks (`stemTrackIdsY`, `sf-{stem}-y`). |
| `staging.stagingHeld` | | boolean | True while DECK_SETUP (note 79) held; diverts row 5/6 preset taps to `onStageDeck`. |
| `loadedDecks.deckX/deckY` | | null or int slot | Decks currently loaded; read by `onDualSongChopPress` and dual-song color paint. Set by `onStageDeck` (`:2672-2685`) and `enterDualSongMode` (`:2333-2334`). |

Staging is **independent of all view vars** and survives every transition except panic
clears nothing of it either (see §4 / §8).

### Playback & gesture state

| Variable | Decl | Shape | Controls |
|---|---|---|---|
| `playingChops` | (global) | `{stem: col}` (int; `-1` = none) | Which column is currently playing per solo/per-row stem. `>=1` means playing; drives bright color and `getHeldChops()` (`:407-418`). |
| `dualSongPlaying` | reset `:2928` | `{ "deck_stem": col }` keyed `deckX_drums` etc. | Which column plays per dual-song deck+stem. Toggled in `onDualSongChopPress` (`:2597-2647`). |
| `heldPads` | `:69` | `{'row,col': true}` | Physically-held grid-1 pads. **Only stem rows 1-4 ever set** (`:2363`/`:2405`). Drives `hasHeldStemPad()` / `getHeldStemRows()` (`:2442-2465`) for the per-row reassign gesture. |
| `modState` | `:63 area` | `{HOLD,MUTE,SOLO,REV,STUT,HALF,DBL,KILL: 'idle'|'held'|'latched'}` | Row-7 modifier latch states. Only HOLD and SOLO are ever read on logic paths (see §5). |
| `activeSlotIndex` | (global) | int | (listed above; the single active preset) |

> There is **no separate `heldChops` tracker.** `getHeldChops()` (`:407-418`) derives a
> snapshot list from `playingChops` entries `>=1`; it is used by scene-save, not by the
> per-row hold gesture.

---

## 4. Mode transitions

Held audio is **never stopped by a view transition** — none of `togglePerRowMode`,
`enterDualSongMode`, `exitDualSongMode`, or the viewMode handlers call `stopAllChops`.

| From → To | Gesture | Code | State preserved |
|---|---|---|---|
| solo → perRow | Double-tap SOLO (row 7 col 3) so `modState.SOLO=='latched'` | `togglePerRowMode :2419-2427` | `activeSlotIndex` (seeds all four `rowSources`) |
| perRow → solo | Double-tap SOLO again (toggle) | `:2428-2440` | Re-activates drums-row source as global active; `rowSources` left in memory but gated off |
| any → dualSong | DUAL_SONG_TOGGLE (note 89) peek or latch | `enterDualSongMode :2312-2339` | `preDualSongView=performanceView` (`:2330`); `rowSources` untouched; per-row suspended via dispatch precedence (`:2354-2360`) |
| dualSong → prev | Release (momentary) or double-tap (latched) | `exitDualSongMode :2343` | Restores `performanceView=preDualSongView`; `rowSources` intact → returns to per-row if that's where you were |
| performance ↔ control | MODE_TOGGLE (note 80) | `:2170-2183`, release reverts `:2212` | `performanceView`, `dualSongActive`, `rowSources` all untouched (orthogonal) |
| any → solo | PANIC triple-tap (note 10 or transport col 8) | `executePanic :2912-2932` | See below |

### Per-row ⇄ dual-song mutual exclusion is by **dispatch precedence**, not state clearing

`handleGrid1Press` checks `if (dualSongActive)` first and returns early (`:2354-2360`),
so while dual-song is active the per-row branches (`:2373`, `:2382`) are unreachable —
per-row is **suspended, not torn down**. `enterDualSongMode` does not modify
`performanceView` or `rowSources`; `exitDualSongMode` restores `performanceView` from
`preDualSongView` (`:2343`).

### PANIC (`executePanic :2912-2932`)

**Gesture:** triple-tap PANIC, **1000ms** reset window (literal `1000`, NOT
`DOUBLE_TAP_WINDOW_MS`). Two entry sites share one global `panicTapCount`/`panicLastTap`
(`:2882-2883`): left side button note 10 (`:2196-2206`) and transport row col 8
(`:2893-2906`). Each press: `if (now - panicLastTap > 1000)` reset to 1 else increment;
at count ≥3 fire `executePanic()`, reset to 0.

> The CC remote path (cc 103) calls `executePanic()` **directly with no tap-count guard**
> (`REMOTE_CC_MAP :2080`, `handleControlChange → handleMessage 'panic' :3145-3146`).

> Naming note: the triple-tap is **PANIC**, not the KILL row-7 modifier. KILL is an inert
> momentary modifier (row 7 col 8) unrelated to the triple-tap.

`executePanic` clears exactly (`:2913-2931`): posts 'PANIC'; `stopAllChops()`;
`clearModifiers()`; `bypassFx()`; `stopAllClips()`. Then if `dualSongActive`:
`dualSongActive=false`, `dualSongLatched=false`. **Unconditionally** `performanceView='solo'`
(`:2924`); all four `rowSources=null` (`:2925-2927`); `dualSongPlaying={}` (`:2928`);
`updateAllPadColors()` + `updateStatus()`.

PANIC does **NOT** reset:
- `viewMode` — control overlay persists through panic.
- `staging.deckX/deckY` or `loadedDecks` — staging survives.
- `activeSlotIndex` — active preset survives.

So "PANIC reverts to solo" is true **only on the performance/dual-song axis**; the control
overlay and staging are not cleared.

---

## 5. Per-modifier behavior (row 7)

`MODIFIERS` order = `HOLD, MUTE, SOLO, REV, STUT, HALF, DBL, KILL` (`:37`), cols 1-8 =
modIndex 0-7. Gesture engine `pressModifier(col-1)` (`:504-521`): if already latched →
toggle to idle; else if `delta < DOUBLE_TAP_WINDOW_MS (400)` → latched; else held.
`releaseModifier` sets held→idle (latched survives release) (`:2403-2411`). **No mutual
exclusion** — multiple modifiers can be latched simultaneously (`:504-521`).

**The only `modState.<X>` reads anywhere in the file are HOLD and SOLO** (exhaustive grep:
HOLD `:443,:2707,:2771`; SOLO `:2392,:2436,:2782,:2796`). The other six appear only in
color/snapshot/debug loops.

| Label / col | Gesture | Implemented behavior | Affects audio? | Test coverage |
|---|---|---|---|---|
| **HOLD** (col 1) | momentary / double-tap latch | **PARTIAL.** Real load-bearing role = **SHIFT**: in `onPresetPress` switches active preset WITHOUT migrating held chops; in `onScenePress` makes the scene pad SAVE instead of recall (`:2771`). The advertised one-shot is **broken**: `pressChop` returns action `one_shot` when HOLD held/latched (`:443`), but `onChopPress` consumes `one_shot` identically to start/replace (same `launchClipInTrack` args, `:2755-2764`) and does NOT update `playingChops` → no play-once-then-stop. | SHIFT path: changes routing/preset selection, indirectly affects audio. One-shot: no auto-stop. | None runnable (modifier set tested only in non-deployed modular `multi-song-modes.test.js`) |
| **MUTE** (col 2) | momentary / latch (gesture works, state stored) | **INERT STUB.** State written by `pressModifier`, read ONLY by pad-color render (`:1766`), `modifierSnapshot`/`restoreModifiers`, debug dump (`:3770-3774`). Never read on any chop/clip/LiveAPI path. | **NO** | None |
| **SOLO** (col 3) | double-tap latch (also set programmatically on scene recall) | **NOT a stem solo.** When SOLO becomes latched, `togglePerRowMode()` runs (`:2391-2394`) — enters/exits per-row mode, inits `rowSources` on entry, re-activates drums source on exit. Does NOT solo/mute any track. Label misleading. | Indirectly (changes routing via per-row), but no stem solo | `loader-e2e.test.js` covers "modifier"; per-row toggle itself uncovered |
| **REV** (col 4) | momentary / latch | **INERT STUB.** No reverse applied. Color/snapshot/debug only. | **NO** | None |
| **STUT** (col 5) | momentary / latch | **INERT STUB.** No retrigger applied. | **NO** | None |
| **HALF** (col 6) | momentary / latch | **INERT STUB.** No half-speed applied. | **NO** | None |
| **DBL** (col 7) | momentary / latch | **INERT STUB.** No double-speed applied. | **NO** | None |
| **KILL** (col 8) | momentary / latch | **INERT STUB.** No kill applied. Unrelated to the triple-tap PANIC gesture. | **NO** | None |

**Verdict: 6 of 8 row-7 modifiers (MUTE, REV, STUT, HALF, DBL, KILL) are fully inert
visual-only stubs.** HOLD is partial (SHIFT works; one-shot does not). SOLO is the per-row
toggle (no stem solo). `executePanic` calls `clearModifiers()` (`:531-536`) — the one place
latches are forcibly reset to idle.

---

## 6. Visual encoding

All values are 7-bit RGB (0-127). The code authors palette constants directly at 0-127; it
does NOT right-shift 8-bit input (`:86-91`).

### Stem colors — `STEM_COLORS` (`:86-91`)

| Stem | Soft | Bright | Hue |
|---|---|---|---|
| drums | `[64,20,0]` | `[127,40,0]` | **ORANGE** |
| bass | `[0,20,64]` | `[0,40,127]` | **BLUE** |
| other | `[50,50,0]` | `[100,100,0]` | **YELLOW / olive (NOT grey)** |
| vox | `[0,50,20]` | `[0,127,40]` | **GREEN** |

Playing chop = bright; playable = soft; disabled = `[40,0,0]`; empty/no-chop = off
`[0,0,0]`. (Grey `[127,127,127]` appears only for the 'all' FX target and the rock genre.)

### State / modifier / scene / preset palettes (`:101-118`, `:154-163`, `:1882-1889`)

- `STATE_COLORS`: empty `[8,8,8]`, error `[127,0,0]`, disabled `[40,0,0]`, off `[0,0,0]`
- `MOD_COLORS`: idle `[16,16,16]`, held `[127,127,127]`, latched `[127,127,0]`
- `SCENE_COLORS`: empty `[0,0,0]`, built `[32,0,48]`, playing `[96,0,127]`
- `PRESET_PALETTE` (8 hues, `slotIndex % 8`): `[127,40,0]`, `[0,40,127]`, `[0,127,40]`,
  `[127,0,80]`, `[127,100,0]`, `[0,100,127]`, `[80,0,127]`, `[127,80,80]`
- `presetSlotColor`: empty `[8,8,8]`, error `[127,0,0]`, loading `[64,64,64]`,
  loaded_active = full preset color, otherwise dimmed ×0.4
- `presetColor(slotIndex) = PRESET_PALETTE[slotIndex % PRESET_PALETTE.length]`

> The base spec claims empty = `[16,16,16]`; actual `STATE_COLORS.empty = [8,8,8]` (`:102`).
> `[16,16,16]` is the modifier-idle color, not empty.

### Genre colors — `GENRE_COLORS` (`:93-99`, `:1922-1948`)

hiphop `[127,50,0]`, idm `[0,60,127]`, ambient `[0,127,50]`, rock `[100,100,100]` (grey),
funk `[127,100,0]`. `genreColor` falls back to `hexToRgb7(color_hue)` (8-bit hex >>2) then
`STATE_COLORS.empty`. `scaleBrightness` ×0.3..1.0 by track energy.

### Per-view color rules

- **Solo / per-row:** stem soft/bright as above. Per-row col-1 pad = source preset's
  `PRESET_PALETTE` color (`:1911-1912`), unless a col-1 chop is playing (then bright stem).
- **Dual-song grid:** rows keep their stem color; empty=off, disabled=`[40,0,0]`,
  playable=soft, playing=bright (`:1783-1820`).
- **Dual-song toggle LED** (note 89, `updateDualSongToggleLed :2288-2298`): **white
  intensity tiers only** — bright white `[127,127,127]` when `dualSongActive`; mid white
  `[40,40,40]` when anything staged; off `[0,0,0]` otherwise. NOT preset colors, NOT
  alternation. The spec'd X/Y preset-color alternation and the invisible-held-chops
  overlay are **absent** (comment at `:2284`: 'full alternation flash deferred').
- **DECK_SETUP button** (note 79): SOLID bright white `[127,127,127]` while held
  (`:2248-2255`, direct RGB). Idle (`deckSetupIdleColor`, `:2278-2281`): dim white
  `[16,16,16]` if either deck staged, else fully OFF `[0,0,0]`.

### Staging two-color FLASH (MK2 native, NOT solid RGB) (`:1726-1761`, `:347-351`, `launchpad-surface-mk2.js:108-113`)

In `updateGrid1Colors`, a staged deck pad pushes a native MK2 flash via
`surface.buildFlashSysex(padNote, colorA, colorB)`:

| Staged pad | Flash colors | Palette indices |
|---|---|---|
| Deck X (row 5, `staging.deckX===slotIdx`) | preset palette color ↔ **WHITE** | `PRESET_PALETTE_INDICES[...]` ↔ `MK2_PALETTE.WHITE` (3) |
| Deck Y (row 6, `staging.deckY===slotIdx`) | preset palette color ↔ **SOFT_BLUE** (~#7799cc) | `PRESET_PALETTE_INDICES[...]` ↔ `MK2_PALETTE.SOFT_BLUE` (41) |

A base RGB is still queued under the flash. Flash SysEx are buffered in
`pendingFlashMessages` and emitted **after** the RGB flush in `sendSurfaceRgb`
(`:347-351`). Staging visuals are MK2 `queueFlash`/`buildFlashSysex`, NOT solid
`queueRgb`/`queueColor`.

### MK2 palette index table (for flash) (`:135-152`)

`MK2_PALETTE`: OFF 0, DIM_WHITE 1, WHITE 3, RED 5, ORANGE 9, YELLOW 13, GREEN 21, CYAN 37,
SOFT_BLUE 41, BLUE 45, PURPLE 49, PINK 53.
`PRESET_PALETTE_INDICES = [9,45,21,53,13,37,49,57]` (8 RGB hues → nearest palette entries).

---

## 7. MIDI / SysEx

### Pad note ↔ row/col mapping (`launchpad-surface-mk2.js:36-46`)

Programmer-mode note = `lpRow*10 + lpCol` (lpRow 1=bottom … 8=top). The code flips
vertically: controller row 1 = top = LP row 8. `noteToRowCol` → `{row: 9-lpRow, col: lpCol}`;
`rowColToNote` → `(9-row)*10 + col`. Valid notes 11-88 (col/row 1-8); col or row 0 or 9 → null.

Side button notes: left `[80,70,60,50,40,30,20,10]`, right `[89,79,69,59,49,39,29,19]` (§2).

### SysEx sequences (`launchpad-surface-mk2.js`)

| Purpose | Bytes (decimal) | Hex | Ref |
|---|---|---|---|
| RGB write header | `[240,0,32,41,2,16,11]` | F0 00 20 29 02 10 0B | `:13` |
| Programmer ENTER | `[240,0,32,41,2,16,44,3,247]` | …2C 03 F7 | `:14` |
| Programmer LEAVE | `[240,0,32,41,2,16,44,0,247]` | …2C 00 F7 | `:15` |
| Pulse header | `[240,0,32,41,2,16,40]` | …28 | `:18` |
| Flash header | `[240,0,32,41,2,16,35]` | …23 | `:19-20` |

- `flushRgb` emits header + per pending `{note,r,g,b}` (7-bit) + 247; batched up to
  `RGB_CHUNK_SIZE=70` per SysEx, chunked into multiple messages (`:73-89`).
- **Programmer ENTER is prepended before EVERY grid-1 flush** (`sendSurfaceRgb`,
  loader-controller.js:`337-340`) to defend against LP USB-reset reverting to Note mode;
  also sent on `bang()` (`:3816-3821`). **`leaveProgrammerMode` is defined but NEVER
  called** (`launchpad-surface-mk2.js:92-98`).
- `buildPulseSysex(note,paletteIndex)` = pulse header + note + paletteIndex + 247.
  **Defined but NO call site in `loader-controller.js`** — pulse is entirely unused in the
  deployed monolith; only flash is used (`:102-106`).
- `buildFlashSysex(note,colorA,colorB)` = flash header + note + colorA + colorB + 247;
  alternates two palette indices at Live tempo. Used for staging (§6). Queued in
  `pendingFlashMessages`, emitted after the RGB flush (`:108-113`).

### MIDI input parsing + CC remote (`:2046-2094`, `:2037`)

`msg_int` (`:2028`): inlet 0 → grid 1, inlet 1 → grid 2. `processMidiByte` (`:2037`) parses
running-status MIDI. `Status & 0xF0`:
- `0x90` note-on → vel>0 `handleNoteOn`, vel==0 `handleNoteOff`
- `0x80` → `handleNoteOff`
- `0xB0` CC → `handleControlChange`

`REMOTE_CC_MAP` → `handleMessage` commands (`value 0` = release no-op):

| CC | Command | Note |
|---|---|---|
| 100 | save | |
| 101 | sync | |
| 102 | inspect | |
| 103 | panic | **No tap-count guard** — fires `executePanic()` directly (`:2080`, `:3145-3146`) |
| 104 | eject | |
| 105 | reload | |
| 106 | debug | |
| 107 | save_manifest | |
| 108 | save_set | |

`handleNoteOn` dispatch order (`:2100-2131`): left side buttons → right side buttons →
`surface.noteToRowCol`; then if `singleGridMode && viewMode=='control'`: row 8 →
`handleGrid1Press` (scenes), rows 1-7 → `handleGrid2Press`; else grid 1 → `handleGrid1Press`,
grid 2 → `handleGrid2Press`.

---

## 8. Edge cases (explicitly handled)

| Edge case | Behavior | Code |
|---|---|---|
| Empty/non-loaded staging slot | Red flash `[127,0,0]`, NO assignment, 500ms revert to empty; `staging[deck]` untouched | `:2655-2670` |
| Empty/non-loaded slot on normal preset press | No-op return (no activation, no load) | `:2688-2690` |
| First activation vs hot-swap | `isFirstActivation` (`activeSlotIndex<0`) → `loadClipsForPreset`; else `stagePreset`→`hotSwapChops`→`commitStagedPreset` | `:2706-2736`, `:459-482`, `:1354-1375` |
| Missing-stem hot-swap | Held chop's missing/disabled column → `stopClipInTrack`, `playingChops[stem]=-1`, no restart | `:466-480`, `:2717-2725` |
| Scene recall mid-mashup | Restores view + active preset + held chops + modifiers; tolerates now-missing chop columns | `:590-603`, `:2770-2828` |
| Empty scene recall | Returns early, no-op | `:590-603` |
| Hold DECK_SETUP, never tap | Clean no-op: `stagingHeld` true→false, `staging` untouched | `:2248-2272` |
| Partial dual-song staging | Falls back to last-active bank preset; both null → fails (red blink **BROKEN**, see below) | `:2312-2339` |
| USB disconnect / programmer-mode revert | `sendSurfaceRgb` prepends programmer-enter on every grid-1 flush; `bang()` re-sends on device-ready. NO explicit reconnect handler — recovery is next-flush / `bar_tick`-driven (`:3147-3149`). JS state survives (MIDI reset doesn't touch it). | `:337-353`, `:3810-3825` |
| Sync all-empty wipe guard | `syncPresetClips`: if `totalLive===0` across all stems×8, ABORT ('sync ABORTED — refusing to wipe'), no manifest mutation | `:3255-3271` |
| Curated-empty stem on reload | `computeTrackChops`: if `stem.chops` empty but `stem.curated` true → emit all 8 cols disabled (load nothing), not blind 4-bar re-grid | `:299-305`, `:3551-3555` |
| Autowatch-reload set restoration | `doInit()` (state only); `loadLastSetPath()` reads `/tmp/setforge_last_set.txt`; 500ms Task re-runs `loadSet`; `saveLastSetPath` on every success | `:3848-3857`, `:1554-1566`, `:3827-3845` |
| Large-file chunked read/write (64KB buffer) | Manifest read loops `readstring(16384)` until eof; `writeStringChunked` 16384-char slices + truncate; set read single `readstring(eof)` | `:1538-1546`, `:3017-3030` |

### FIXED (was: `DUAL_SONG_TOGGLE` ReferenceError on dual-song failure path)

> **✅ Fixed in commit `e6c1d87`.** Both call sites now pass `SIDE_BUTTONS_RIGHT[0]`
> (note 89), `loader.js` was regenerated, and `tests/integration/loader-e2e.test.js`
> now contains a 4-case regression suite for this path (no throw, posts failure, red
> flash on note 89, dual-song not entered). The description below documents the original
> defect for the record.

`enterDualSongMode` (`:2312-2339`) **previously** called `flashSideButtonRed(DUAL_SONG_TOGGLE)` at both
`:2319` (no decks) and `:2326` (one deck unresolved). **`DUAL_SONG_TOGGLE` is never declared
as a variable** — it exists only as the string `SIDE_FUNC_RIGHT[0]` (`:78`). At runtime this
throws a **ReferenceError**, so:

1. The intended red blink on the toggle button never renders.
2. The failure branch crashes — the whole `enterDualSongMode` invocation aborts at the
   `flashSideButtonRed` line. The mode is not entered (which is the intent), but via a
   thrown exception rather than a clean `return`.

The `flashSideButtonRed` helper itself (`:2301-2310`) is correct (queues `STATE_COLORS.error`,
flushes, 500ms revert to dim white `[8,8,8]`); only its call-site argument is wrong.
**Fix applied (`e6c1d87`):** both sites pass `SIDE_BUTTONS_RIGHT[0]` (note 89). This had been
the most severe drift in the device — a runtime crash on a reachable code path (catalog Drift
§1). It is now covered by regression tests against the built monolith.

### Other dead / legacy paths (not strictly edge cases)

- File-based remote command interface (`/tmp/setforge_cmd.txt`, `pollCommandFile`,
  `startCmdPoll`, `cmdPollTask`) is still wired and started via a deferred Task at load,
  but inline comments say remote commands now arrive as MIDI CCs — superseded but still
  running (`:1988-2026`, `:3859-3865`).
- `onSetlistTrackPress` only posts; performs no load/activate (`:2876-2880`).
- Auto-save in `onPresetPress` is commented out (`:2699-2704`).

### Staging pre-load failure — only PARTIALLY handled

`onStageDeck` (`:2655-2685`) guards only on slot STATE (empty/loading/error). It does NOT
check the `loaded` count returned by `loadStemClipsToTrack` (`:894-967`), which swallows
per-chop `create_audio_clip` errors and merely posts them (`:962-964`). So a runtime
file-missing failure leaves the deck marked "loaded" with partial/zero clips, no red flash,
no clearing of `staging[deck]`. Pre-load is **synchronous** clip creation in the press
handler; only the 4000ms-deferred `fixWarpMarkersOnTracks` warp pass is async (`:986-989`,
`:1012-1015`).

---

## 9. Acceptance test mapping

**Caveat applying to every row below:**
- **node is NOT installed in this environment. NO tests were run. No test can be claimed to pass.**
- The JS integration tests (`chop-trigger`, `load-set`, `scene-recall`, `panic`,
  `preset-swap`, `multi-song-modes`) `require('../../src/loader/*')` and `src/shared/*` —
  the **NON-deployed modular files**. Passing them would NOT validate `loader-controller.js`.
- **ONLY `tests/integration/loader-e2e.test.js` loads the device-root `loader.js`** (the
  built monolith) via vm/eval against a mock Max env (`:16`, `:272-495`). It is the only
  runnable test that exercises shipped code.
- The Python UAT needs **live hardware** (Ableton Live + device loaded + Launchpad);
  cannot run headless. UAT assertions were not exhaustively read.

| Behavior | Test file / name | Targets deployed monolith? |
|---|---|---|
| load set, stem-track creation, status outlet, eject, debug, panic, preset activation, chop trigger/replace/stop, modifier, scene save+recall, Grid2 FX target, Grid2 panic triple-tap, hot-swap stage+fire, varying track | `loader-e2e.test.js:272-495` | **YES** (loads built `loader.js`, `:16`) |
| chop trigger | `chop-trigger.test.js:4-10` | NO — modular `src/loader/*` + `src/shared/*` |
| load set | `load-set.test.js` | NO — modular imports |
| scene recall | `scene-recall.test.js` | NO — modular imports |
| panic | `panic.test.js` | NO — modular imports |
| preset swap | `preset-swap.test.js` | NO — modular imports |
| multi-song modes | `multi-song-modes.test.js:4-7` | NO — modular imports |
| full vocal | `full-vocal.test.js` | UNCONFIRMED (not opened) |
| bank/slot mapping | `bank-slot-mapping.test.js` | UNCONFIRMED (not opened) |
| multi-song UAT (live) | `tests/uat/test_multi_song_modes.py:1` | Live hardware only |
| clip properties UAT (live) | `tests/uat/test_clip_properties.py` | Live hardware only |

### Deployed multi-song behaviors with NO runnable automated coverage

- dual-song entry/exit + `onDualSongChopPress` routing into -x/-y tracks (`:2597-2647`)
- staging gesture `onStageDeck` + `loadPresetToDeckX/Y` pre-load (`:2655-2686`)
- per-row mode `togglePerRowMode` / `onPerRowReassign` / `getEffectivePreset` (`:2419-2516`)
- the 6 inert row-7 modifier stubs (no audio path exists to test)
- HOLD one-shot vs SHIFT behavior, SOLO per-row toggle
- dual-song toggle LED tiers, staging two-color flash visuals
- `updateDualSongToggleLed` absence of alternation / held-chop overlay

These are reachable only by the live-hardware Python UAT, which cannot run here.

---

## Appendix — cross-reference to master catalog

Built from `/tmp/setforge-master-catalog.md`: §8 (layout), §9 (side buttons),
§2/§3/§4/§5/§7 (state), §2 (transitions), §6 (modifiers), §10 (palette), §11 (SysEx/MIDI),
§12 (edge cases), §13 (tests), Drift §1 (the `DUAL_SONG_TOGGLE` crash). Open questions
needing Zak: catalog §15.
