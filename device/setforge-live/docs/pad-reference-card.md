# setforge-live — Pad Reference Card

Quick reference for the Launchpad **MK2** grid in all four views, plus the
left/right side buttons. Built directly from the deployed
`loader-controller.js` monolith (the MK3 surface is concatenated but never
activated — `createSurface("mk2")`).

Grids are drawn **row 1 = top, row 8 = bottom**, **col 1 = left, col 8 = right**
(matching the on-screen convention; the surface flips this to the Launchpad's
note grid internally).

There is no single `view` variable in code: the four "views" below are emergent
from `performanceView` (`"solo"`/`"perRow"`), `dualSongActive` (bool), and
`viewMode` (`"performance"`/`"control"`).

---

## Color key

| Element | Color | 7-bit RGB (soft / bright) |
|---|---|---|
| drums | ORANGE | `[64,20,0]` / `[127,40,0]` |
| bass | BLUE | `[0,20,64]` / `[0,40,127]` |
| other | YELLOW / olive (NOT grey) | `[50,50,0]` / `[100,100,0]` |
| vox | GREEN | `[0,50,20]` / `[0,127,40]` |
| playing chop | stem **bright** | — |
| playable chop | stem **soft** | — |
| disabled chop | dim red | `[40,0,0]` |
| empty / no chop | off | `[0,0,0]` |
| preset slot (active) | one of 8 PRESET_PALETTE hues | `slotIndex % 8` |
| preset slot (loaded, inactive) | preset hue × 0.4 | — |
| preset slot (empty) | dim white | `[8,8,8]` |
| modifier idle / held / latched | dim white / white / yellow | `[16,16,16]` / `[127,127,127]` / `[127,127,0]` |
| scene empty / built / playing | off / dim purple / bright purple | `[0,0,0]` / `[32,0,48]` / `[96,0,127]` |
| FX-B throw (active) | orange | `[127,80,0]` |

Staging pads use a **two-color FLASH** (not a solid color): a staged deck-X
pad flashes its preset color ↔ WHITE; a staged deck-Y pad flashes preset
color ↔ SOFT_BLUE.

---

## View entry gestures

| View | Entry gesture | Exit |
|---|---|---|
| **Solo** | Default on load; or exit any other view | n/a |
| **Per-row** | **Double-tap SOLO** (row 7, col 3) so `modState.SOLO` latches | Same gesture (toggle) |
| **Dual-song** | **Right side button note 89** — single tap+hold = momentary peek, double-tap (<400 ms) = latch | Release (momentary) or double-tap (latched) |
| **Control** | **Left side button note 80 (MODE_TOGGLE)** — hold = momentary peek, double-tap = latch | Release (momentary) or double-tap; overlays Grid 1 only when `singleGridMode` |

Notes:
- Control view is an **overlay/hijack of Grid 1**, not a mutually-exclusive
  sibling — it can coexist with dual-song or per-row state.
- **PANIC** = triple-tap (within a 1000 ms reset window) the PANIC pad
  (left side note 10, or transport row col 8). On fire: stops all chops/clips,
  clears modifiers, bypasses FX, reverts to solo. Does NOT reset control view
  or staging. (This is PANIC, not the inert KILL modifier.)

---

## VIEW 1 — Solo (default performance)

`performanceView == "solo" && !dualSongActive && viewMode == "performance"`.
All four stem rows source chops from the single `activeSlotIndex`.

```
        col1     col2     col3     col4     col5     col6     col7     col8
row1 [ DRUM-1 ][ DRUM-2 ][ DRUM-3 ][ DRUM-4 ][ DRUM-5 ][ DRUM-6 ][ DRUM-7 ][ DRUM-8 ]  drums chops (ORANGE)
row2 [ BASS-1 ][ BASS-2 ][ BASS-3 ][ BASS-4 ][ BASS-5 ][ BASS-6 ][ BASS-7 ][ BASS-8 ]  bass chops  (BLUE)
row3 [ OTHR-1 ][ OTHR-2 ][ OTHR-3 ][ OTHR-4 ][ OTHR-5 ][ OTHR-6 ][ OTHR-7 ][ OTHR-8 ]  other chops (YELLOW/olive)
row4 [ VOX-1  ][ VOX-2  ][ VOX-3  ][ VOX-4  ][ VOX-5  ][ VOX-6  ][ VOX-7  ][ VOX-8  ]  vox chops   (GREEN)
row5 [ A:s0   ][ A:s1   ][ A:s2   ][ A:s3   ][ A:s4   ][ A:s5   ][ A:s6   ][ A:s7   ]  bank A presets (slots 0-7)
row6 [ B:s8   ][ B:s9   ][ B:s10  ][ B:s11  ][ B:s12  ][ B:s13  ][ B:s14  ][ B:s15  ]  bank B presets (slots 8-15)
row7 [ HOLD   ][ MUTE   ][ SOLO   ][ REV    ][ STUT   ][ HALF   ][ DBL    ][ KILL   ]  row-7 modifiers
row8 [ SCN-1  ][ SCN-2  ][ SCN-3  ][ SCN-4  ][ SCN-5  ][ SCN-6  ][ SCN-7  ][ SCN-8  ]  scenes
```

**Row-7 modifier truth (important):**
- **HOLD** (col 1) — *partial*. Its real load-bearing role is **SHIFT**: it
  switches the active preset without migrating held chops, and makes a scene
  pad SAVE instead of recall. The "one-shot / play-once-then-stop" behavior is
  **not** implemented.
- **SOLO** (col 3) — does **NOT** solo a stem. Double-tap toggles **per-row
  mode** on/off (per-row latch). Label is misleading vs behavior.
- **MUTE, REV, STUT, HALF, DBL, KILL** (cols 2, 4, 5, 6, 7, 8) — **6 fully inert
  visual-only stubs.** The gesture latches and lights the pad and serializes into
  scenes, but **no audio is affected**. Do not rely on these for performance.

---

## VIEW 2 — Per-row

`performanceView == "perRow" && !dualSongActive`. Same row layout as Solo, but
each stem row 1-4 can source chops from its **own** preset (`rowSources[stem]`).

```
        col1     col2     col3     col4     col5     col6     col7     col8
row1 [ DRUM-1*][ DRUM-2 ][ DRUM-3 ][ DRUM-4 ][ DRUM-5 ][ DRUM-6 ][ DRUM-7 ][ DRUM-8 ]  drums from rowSources.drums
row2 [ BASS-1*][ BASS-2 ][ BASS-3 ][ BASS-4 ][ BASS-5 ][ BASS-6 ][ BASS-7 ][ BASS-8 ]  bass  from rowSources.bass
row3 [ OTHR-1*][ OTHR-2 ][ OTHR-3 ][ OTHR-4 ][ OTHR-5 ][ OTHR-6 ][ OTHR-7 ][ OTHR-8 ]  other from rowSources.other
row4 [ VOX-1* ][ VOX-2  ][ VOX-3  ][ VOX-4  ][ VOX-5  ][ VOX-6  ][ VOX-7  ][ VOX-8  ]  vox   from rowSources.vox
row5 [ A:s0   ][ A:s1   ][ A:s2   ][ A:s3   ][ A:s4   ][ A:s5   ][ A:s6   ][ A:s7   ]  bank A presets
row6 [ B:s8   ][ B:s9   ][ B:s10  ][ B:s11  ][ B:s12  ][ B:s13  ][ B:s14  ][ B:s15  ]  bank B presets
row7 [ HOLD   ][ MUTE   ][ SOLO   ][ REV    ][ STUT   ][ HALF   ][ DBL    ][ KILL   ]  modifiers (SOLO latched)
row8 [ SCN-1  ][ SCN-2  ][ SCN-3  ][ SCN-4  ][ SCN-5  ][ SCN-6  ][ SCN-7  ][ SCN-8  ]  scenes
```

`* col-1` of each stem row is **tinted with its source preset's palette color**
(a static repaint, not an animated pulse), so you can see which preset that row
is drawing from. **Caveat:** this tint is suppressed when a chop is actively
playing in col 1 of that row — a held col-1 chop shows bright stem color instead.

**Row reassignment:** while in per-row, **hold a stem pad (row 1-4) and tap a
preset pad (row 5 or 6)** to reassign that row's source. The held chop hot-swaps
to the matching column in the new preset (or stops if no match). Assignment and
clip loading are **immediate** (only Live's own clip-launch quant applies).

Entry: double-tap SOLO. Exit: double-tap SOLO again — the global active preset
becomes the drums row's source.

---

## VIEW 3 — Dual-song

`dualSongActive` (overrides per-row in dispatch). All 8 rows are stems, split
across two pre-loaded decks. Entered via right side note 89.

```
        col1     col2     col3     col4     col5     col6     col7     col8
row1 [ X-DRM-1][ X-DRM-2][ X-DRM-3][ X-DRM-4][ X-DRM-5][ X-DRM-6][ X-DRM-7][ X-DRM-8]  deck X drums (ORANGE)
row2 [ X-BAS-1][ X-BAS-2][ X-BAS-3][ X-BAS-4][ X-BAS-5][ X-BAS-6][ X-BAS-7][ X-BAS-8]  deck X bass  (BLUE)
row3 [ X-OTH-1][ X-OTH-2][ X-OTH-3][ X-OTH-4][ X-OTH-5][ X-OTH-6][ X-OTH-7][ X-OTH-8]  deck X other (YELLOW)
row4 [ X-VOX-1][ X-VOX-2][ X-VOX-3][ X-VOX-4][ X-VOX-5][ X-VOX-6][ X-VOX-7][ X-VOX-8]  deck X vox   (GREEN)
row5 [ Y-DRM-1][ Y-DRM-2][ Y-DRM-3][ Y-DRM-4][ Y-DRM-5][ Y-DRM-6][ Y-DRM-7][ Y-DRM-8]  deck Y drums (ORANGE)
row6 [ Y-BAS-1][ Y-BAS-2][ Y-BAS-3][ Y-BAS-4][ Y-BAS-5][ Y-BAS-6][ Y-BAS-7][ Y-BAS-8]  deck Y bass  (BLUE)
row7 [ Y-OTH-1][ Y-OTH-2][ Y-OTH-3][ Y-OTH-4][ Y-OTH-5][ Y-OTH-6][ Y-OTH-7][ Y-OTH-8]  deck Y other (YELLOW)
row8 [ Y-VOX-1][ Y-VOX-2][ Y-VOX-3][ Y-VOX-4][ Y-VOX-5][ Y-VOX-6][ Y-VOX-7][ Y-VOX-8]  deck Y vox   (GREEN)
```

- **Rows 1-4 = deck X**, **rows 5-8 = deck Y**. Within each deck the stem order is
  drums, bass, other, vox.
- Decks are resolved at entry from staging (`staging.deckX/Y`) with a fallback to
  the most-recently-active bank-A / bank-B preset. Entry does **not** re-load
  clips — it relies on staging (or last-active) having pre-loaded the X/Y tracks.
- Per-row **launch quantization**: drums = 1/16, bass = 1 bar, other = 1/4,
  vox = 1/2.

> **Known bug:** if both decks are unresolved, the failure branch calls
> `flashSideButtonRed(DUAL_SONG_TOGGLE)` against an undeclared identifier →
> ReferenceError. The intended red blink never renders and the failure path
> crashes. In practice, stage a deck before entering.

---

## VIEW 4 — Control (Grid 1 overlay)

`viewMode == "control" && singleGridMode`. Hijacks Grid 1. Row 8 stays as scenes;
rows 1-7 become the control surface. Entered via left side note 80 (MODE_TOGGLE).

```
        col1     col2     col3     col4     col5     col6     col7     col8
row1 [ SET-0  ][ SET-1  ][ SET-2  ][ SET-3  ][ SET-4  ][ SET-5  ][ SET-6  ][ SET-7  ]  setlist 0-7
row2 [ SET-8  ][ SET-9  ][ SET-10 ][ SET-11 ][ SET-12 ][ SET-13 ][ SET-14 ][ SET-15 ]  setlist 8-15
row3 [ SET-16 ][ SET-17 ][ SET-18 ][ SET-19 ][ SET-20 ][ SET-21 ][ SET-22 ][ SET-23 ]  setlist 16-23
row4 [ SET-24 ][ SET-25 ][ SET-26 ][ SET-27 ][ SET-28 ][ SET-29 ][ SET-30 ][ SET-31 ]  setlist 24-31 (32-pad setlist)
row5 [ drums  ][ bass   ][ other  ][ vox    ][ all    ][ deckA  ][ deckB  ][ master ]  FX target select
row6 [ FXA-1  ][ FXA-2  ][ FXA-3  ][ FXA-4  ][ FXA-5  ][ FXA-6  ][ FXA-7  ][ FXA-8  ]  FX-A filter sweep
row7 [ FXB-1  ][ FXB-2  ][ FXB-3  ][ FXB-4  ][ FXB-5  ][ FXB-6  ][ FXB-7  ][ FXB-8  ]  FX-B throws
row8 [ SCN-1  ][ SCN-2  ][ SCN-3  ][ SCN-4  ][ SCN-5  ][ SCN-6  ][ SCN-7  ][ SCN-8  ]  scenes
```

> **FX bus is visual/status-only.** `fxTarget`, `fxFilterCol`/`fxFilterLatched`,
> and `fxThrowCol` drive only pad colors and the status text — there are **zero**
> LiveAPI / audio calls. No punch-fx device is integrated. The `FILTER_POSITIONS`
> frequency table is defined but never referenced. Setlist pads (rows 1-4) are
> informational — pressing one only posts; it does not load or activate a slot.

---

## Side buttons

### LEFT side buttons (`SIDE_BUTTONS_LEFT`, top → bottom)

| Note | Function | Behavior |
|---|---|---|
| **80** | MODE_TOGGLE | momentary perf↔control; double-tap (<400 ms) latches control view |
| **70** | TAP | outlet `tap_tempo` |
| **60** | SYNC | outlet `sync` |
| **50** | BPM_DOWN | `bpm_nudge -0.1` |
| **40** | BPM_UP | `bpm_nudge +0.1` |
| **30** | LOOP_IN | outlet `loop_in` |
| **20** | LOOP_OUT | outlet `loop_out` |
| **10** | PANIC | triple-tap within 1000 ms windows → `executePanic()` |

### RIGHT side buttons (`SIDE_BUTTONS_RIGHT`, top → bottom)

| Note | Function | Behavior |
|---|---|---|
| **89** | DUAL_SONG_TOGGLE | momentary peek / double-tap latch into dual-song view |
| **79** | DECK_SETUP | hold → staging mode (bright white `[127,127,127]` while held); while held, row 5 taps stage **deck X**, row 6 taps stage **deck Y** |
| **69** | — | unused / inert |
| **59** | — | unused / inert |
| **49** | — | unused / inert |
| **39** | — | unused / inert |
| **29** | — | unused / inert |
| **19** | — | unused / inert |

There is **no SHIFT side button** — the SHIFT role is served by the HOLD row-7 pad.

---

*Source of truth: deployed `src/loader/loader-controller.js` (MK2 surface).
Stubs and known bugs above are documented honestly — do not rely on inert
modifiers or FX-bus pads for audio.*
