# setforge-live spec addendum: Launchpad hardware

**Status:** addendum to `setforge-live-spec.md` v0
**Date:** 2026-05-24
**Reason:** Hardware reality differs from spec assumption; capture deltas without invalidating the main spec.

This document is **subordinate** to `setforge-live-spec.md`. When the two disagree, the main spec governs *intent* and this document governs *implementation specifics for current hardware*. If hardware changes, this document changes; the main spec does not.

---

## 1. Hardware reality (vs. spec assumption)

| What the spec assumes | What Zak actually has |
|---|---|
| Two Launchpad Pro MK3 units | One Launchpad Pro MK2 unit |
| Both grids physically present from day one | Grid 1 only for now; Grid 2 sourced later |
| USB-C × 2, RGB at 8-bit per channel | USB-B × 1, RGB at 7-bit per channel |

This addendum captures the implementation consequences. The build still targets the full two-grid UX described in the main spec — we just defer the second-grid integration and adjust the surface layer to handle whatever shows up later.

---

## 2. Architecture delta — surface abstraction

The main spec's §5 lists `src/loader/launchpad-surface.js` as a single file. **Replace that with a small family of files:**

```
src/loader/
├── launchpad-surface.js          ← interface + auto-detect dispatcher
├── launchpad-surface-mk1.js      ← Launchpad Pro original (2015), USB mini-B
├── launchpad-surface-mk2.js      ← Launchpad Pro MK2, USB-B            ← Zak's hardware
└── launchpad-surface-mk3.js      ← Launchpad Pro MK3, USB-C
```

### 2.1 The `LaunchpadSurface` interface

All concrete implementations satisfy this contract. The rest of the device only depends on this interface.

```js
// launchpad-surface.js — interface contract
//
// Lifecycle:
//   const surface = await LaunchpadSurface.connect(midiPortName);
//   surface.enterProgrammerMode();
//   surface.onPadPress((row, col) => { ... });
//   surface.onPadRelease((row, col) => { ... });
//   surface.setPadColor(row, col, { r, g, b });   // r,g,b in 0..255
//   surface.flushColors();                         // batched send
//   surface.disconnect();
//
// Detection:
//   LaunchpadSurface.connect() sends a SysEx device inquiry
//   (F0 7E 7F 06 01 F7) and dispatches to the right concrete class
//   based on the response's manufacturer + family + member ID.
//
//   If the device doesn't respond within 500ms, treat as
//   "unknown Launchpad" and surface an error rather than guessing.
//
// Color space:
//   Interface accepts 8-bit RGB (0..255 per channel).
//   Each concrete implementation handles its native color
//   precision internally. MK1/MK2 right-shift to 7-bit; MK3
//   passes through.
//
// Coalescing:
//   setPadColor() is non-blocking and buffers the change.
//   flushColors() emits all buffered changes in one SysEx
//   burst. Call flushColors() on bar boundaries, not on
//   every pad change. Avoids USB MIDI saturation.
```

### 2.2 Auto-detection dispatch

When the device loads, it enumerates all connected MIDI inputs/outputs. For each candidate:

1. Open the port.
2. Send a SysEx device inquiry: `F0 7E 7F 06 01 F7`.
3. Wait up to 500ms for the response.
4. Match the response's family/model bytes against a known table:

| Manufacturer ID | Family bytes | Model | Concrete class |
|---|---|---|---|
| `00 20 29` (Focusrite/Novation) | `51 00` | Launchpad Pro original | `LaunchpadSurfaceMK1` |
| `00 20 29` | `51 01` | Launchpad Pro MK2 | `LaunchpadSurfaceMK2` |
| `00 20 29` | `51 02` | Launchpad Pro [MK3] | `LaunchpadSurfaceMK3` |

(The MK3 family byte is documented; the MK1/MK2 distinction in the family bytes should be confirmed against actual hardware before relying on it — Novation's docs are inconsistent. If detection is ambiguous between MK1 and MK2, default to MK2 and log a warning.)

5. Instantiate the matching concrete class with the port handle.
6. Return the surface.

### 2.3 Multi-Launchpad assignment

When two Launchpads of any combination of models are connected, the device needs to know which is Grid 1 (performance) and which is Grid 2 (control). Two strategies:

1. **Order of enumeration** — first-found = Grid 1, second-found = Grid 2. Brittle; depends on USB port order.
2. **User assignment via front panel** — device front panel shows discovered Launchpads with a small "assign as Grid 1 / Grid 2" toggle. Persists assignment to a config file by device serial.

**Pick strategy 2.** Strategy 1 will swap on you every time you change USB ports.

---

## 3. MK2 implementation specifics (Zak's hardware)

Notes for whoever writes `launchpad-surface-mk2.js`.

### 3.1 SysEx reference

Authoritative source: **"Launchpad Pro Programmer's Reference Manual"** published by Novation/Focusrite. Public PDF at:

```
https://fael-downloads-prod.focusrite.com/customer/prod/s3fs-public/downloads/Launchpad%20Pro%20Programmer%20Reference%20Guide_0.pdf
```

Despite the file name saying just "Launchpad Pro," this document covers the MK2 SysEx. Novation's naming pre-MK3 was inconsistent; the doc *is* MK2 even though it doesn't say so prominently.

### 3.2 Entering programmer mode

Programmer mode is the "raw MIDI surface" mode where pads no longer have Live-specific default behaviors. Required for setforge-live to drive the grid.

```
SysEx to enter programmer mode:
F0 00 20 29 02 10 2C 03 F7

SysEx to leave programmer mode (return to normal):
F0 00 20 29 02 10 2C 00 F7
```

The device should enter programmer mode on connect and leave it on disconnect. If the device crashes without cleanup, the user can power-cycle the Launchpad to reset; not a hard failure.

### 3.3 Pad numbering in programmer mode

In programmer mode, each pad in the 8×8 grid sends a unique MIDI note number when pressed/released. The mapping is row-column to note number:

```
Pad note number = (row * 10) + col

where row counts from bottom (1 = bottom row, 8 = top row)
and   col counts from left (1 = leftmost, 8 = rightmost)
```

So the bottom-left pad is note `11`, bottom-right is `18`, top-left is `81`, top-right is `88`. The 32 side buttons have their own note numbers in the 10s/90s/100s range; see the programmer's reference for the table.

**Important:** the main spec's row numbering goes top-down (row 1 at top, row 8 at bottom), which is the *opposite* of the Launchpad's native numbering. The MK2 surface implementation must flip rows before sending:

```js
// converting spec-row to launchpad-row
const launchpadRow = 9 - specRow;
const padNote = (launchpadRow * 10) + specCol;
```

This flip is contained inside the surface implementation; the rest of the device thinks in spec-row coordinates.

### 3.4 RGB color writes

MK2 RGB is 7-bit per channel (range 0..127), not 8-bit. The interface accepts 8-bit RGB; the MK2 implementation right-shifts:

```js
const r7 = rgb.r >> 1;  // 0..255 → 0..127
const g7 = rgb.g >> 1;
const b7 = rgb.b >> 1;
```

The compression at the bright end is mostly imperceptible but means some color pairs that look distinct in 8-bit (e.g. the drums-orange `#ffe5dc` vs vox-green `#dcf2e4`) might compress slightly closer. **Action item:** during the calibrator-validator acceptance pass (spec §6.3), eyeball-confirm that all six stem/state colors are distinguishable on actual MK2 hardware in dim stage lighting. If two colors collide, adjust the constants in `color-palette.js`.

### 3.5 RGB write SysEx (direct mode)

```
F0 00 20 29 02 10 0B <pad_note> <r7> <g7> <b7> F7
```

For batched writes (a whole grid update), wrap all triples in a single SysEx:

```
F0 00 20 29 02 10 0B <pad1> <r1> <g1> <b1> <pad2> <r2> <g2> <b2> ... F7
```

Up to roughly 78 pad updates per SysEx packet before hitting USB buffer limits. Spec's `flushColors()` should auto-chunk if more than ~70 pads need updating in one flush.

### 3.6 Pulsing and blinking

MK2 supports built-in pulse and flash modes — you don't need to render these animations in software. Use them for `cued` and `loaded_active` states.

```
Pulse (slow fade in/out at tempo):
F0 00 20 29 02 10 28 <pad_note> <palette_color> F7

Flash (alternate between two palette colors at tempo):
F0 00 20 29 02 10 23 <pad_note> <color_a> <color_b> F7
```

These use the 128-entry **palette colors** (0..127 indexed), not direct RGB. Map the spec's RGB constants to the nearest palette entry at startup; cache the mapping.

The palette table is documented in the programmer's reference appendix. Useful palette entries:

| Spec state | Palette index | Notes |
|---|---|---|
| drums playing (pulse) | 5 (bright red) | Pulses are sync'd to Live's tempo automatically |
| bass playing (pulse) | 41 (bright blue) | |
| cued (flash) | flash between color and 0 (off) | |
| preset active (pulse) | 13 (yellow) | |

### 3.7 Side buttons

The 16 round side buttons (8 left + 8 right) are addressable as MIDI notes in programmer mode. In the main spec the side buttons are unused; the addendum reclaims them for transport (see §4 below).

---

## 4. UX delta — single-Launchpad mode

The main spec assumes both grids exist. While Zak has only one Launchpad, the device must work in **single-grid mode**, with Grid 2's functionality grafted onto Grid 1's surface via mode-switching.

### 4.1 Two-mode toggle on Grid 1

When only one Launchpad is connected, the device runs in **single-grid mode**. The user toggles between *performance view* (Grid 1 layout) and *control view* (Grid 2 layout) via a dedicated side button.

Side button assignment (MK2 left side, top-to-bottom):

| Side button | Function in single-grid mode |
|---|---|
| Left side, top | **Mode toggle**: performance ↔ control |
| Left side, 2nd | Tap tempo |
| Left side, 3rd | Sync |
| Left side, 4th | BPM nudge down |
| Left side, 5th | BPM nudge up |
| Left side, 6th | Loop in |
| Left side, 7th | Loop out |
| Left side, bottom | **PANIC** (triple-tap to confirm) |

This reclaims the entire row 8 of the pad grid that the main spec used for transport. In single-grid mode, **row 8 still shows scenes** (which was already its primary role in the main spec — transport on row 8 was a Grid 2 thing).

The right side buttons stay unused in v0; reserved for future expansion (FX latch toggles, view-mode shortcuts).

### 4.2 Control view layout (single-grid)

When mode-toggled to control view, Grid 1's pads switch to show what Grid 2 normally shows:

```
        col 1   col 2   col 3   col 4   col 5   col 6   col 7   col 8
row 1   T01     T02     T03     T04     T05     T06     T07     T08      setlist 1-8
row 2   T09     T10     T11     T12     T13     T14     T15     T16      setlist 9-16
row 3   T17     T18     T19     T20     T21     T22     T23     T24      setlist 17-24
row 4   T25     T26     T27     T28     T29     T30     T31     T32      setlist 25-32
row 5   DRM     BASS    OTH     VOX     ALL     DECKA   DECKB   MSTR     target
row 6   F1..F8                                                            filter sweep
row 7   X1..X8                                                            throws
row 8   SA..SH                                                            ← scenes still here
```

**Critical:** row 8 stays scenes in both views. The user always has scene access regardless of mode. Transport moved to the left side buttons.

### 4.3 Mode-toggle behavior

- Toggle is **momentary by default**: hold the side button to peek at control view, release to return. Lets you cue a setlist track or fire an FX without committing to a mode switch.
- **Double-tap the toggle** to latch the mode. Solid LED on the side button = latched. Double-tap again to unlatch.
- **Held chops continue playing** through mode swaps. The chops are still active; you just can't see/manipulate them while in control view. Visual continuity is sacrificed for surface real estate.

### 4.4 Visual cue for which mode you're in

When in control view, the **top edge of the grid** (row 1 of the pads) gets a subtle blue tint across all pads as a peripheral-vision cue. When in performance view, no tint (or a subtle stem-color tint based on active preset). This is the "you are here" indicator without consuming a pad.

### 4.5 When the second Launchpad arrives

The device auto-detects two Launchpads, assigns one to Grid 1 / one to Grid 2 via the front panel (§2.3), and **single-grid mode automatically deactivates**. The mode-toggle side button reverts to "unused / reserved." Transport stays on the side buttons (it's already in muscle memory by then; no reason to move it back to row 8 of Grid 2).

**Action item for the spec:** when implementing Phase 5 (Grid 2), check the connected-Launchpads count and branch logic accordingly. Tests should cover both single-grid and dual-grid configurations.

---

## 5. Testing implications

The main spec's §6 testing plan needs two augmentations:

### 5.1 Mock multi-model surface

`mock-launchpad.js` already mocks one Launchpad. Extend it to:

- Mock all three models (MK1, MK2, MK3) so unit tests aren't hardware-specific.
- Mock connecting zero, one, or two Launchpads simultaneously.
- Mock the device-inquiry SysEx round-trip so auto-detection can be unit-tested.

### 5.2 Single-grid mode coverage

Add an integration test: `tests/integration/single-grid-mode.test.js`

- Loads a set with one Launchpad mocked.
- Verifies mode-toggle works (momentary hold + double-tap latch).
- Verifies row 8 stays scenes in both views.
- Verifies side-button transport works.
- Verifies that connecting a second Launchpad mid-test transitions cleanly to dual-grid mode without disrupting held chops.

### 5.3 Acceptance test addition

Add to spec §6.3 acceptance checklist:

- [ ] On MK2 hardware, all six stem/state colors visually distinguishable in dim lighting.
- [ ] Programmer mode is entered cleanly on connect; left cleanly on disconnect.
- [ ] Side-button transport works for tap/sync/BPM/loop/panic.
- [ ] Mode toggle (momentary and latched) doesn't drop held chops.
- [ ] Hot-swapping the USB cable doesn't crash the device (auto-reconnect; surface flushes color state).

---

## 6. Build order delta

The main spec's build order (§7) stands, with one phase tweak:

**Phase 5 — Grid 2** becomes **Phase 5 — Control view (single-grid first, dual-grid second).**

Sub-phases:
- **5a** — Implement control view rendering on Grid 1 (mode toggle, single-grid layout, side-button transport).
- **5b** — Implement Grid 2 dual-mode (only when second Launchpad sourced).

5a is implementable and testable today with Zak's MK2. 5b waits on hardware.

---

## 7. Open hardware questions (not blocking)

1. **Side-button RGB on MK2.** The side buttons have their own RGB LEDs; need to confirm they accept the same color SysEx as pad RGB. If not, the transport side buttons may be monochrome (red/green/off) which is fine but worth knowing.
2. **MK2 firmware version.** Different MK2 firmware revisions had subtle SysEx differences. Worth checking Zak's firmware version via the front panel + diff against the public reference. Action: log the firmware version reported by device inquiry on startup and surface it in the device's status display.
3. **Two-MK2 setup vs MK2+MK3 mixed.** When sourcing the second Launchpad, MK2 (matching pair) is simpler — same SysEx, same color space, same side-button layout. MK3 (newer, more featureful) is more capable but heterogeneous. **Recommendation:** match the existing MK2 unless you have a specific reason to want MK3's added features (the sequencer mode, the larger color gamut). For setforge-live's use case, matched MK2 is the cleaner build.

---

## 8. Glossary additions

| Term | Definition |
|---|---|
| **Programmer mode** | Launchpad firmware mode where pad presses become raw MIDI notes with no Live-specific default behaviors. Required for setforge-live to fully drive the grid. |
| **Palette index** | 7-bit index (0..127) into Novation's preset color palette. Used for pulse/flash modes which sync to Live's tempo automatically. |
| **Single-grid mode** | Operating mode when only one Launchpad is connected. Mode-toggle side button switches Grid 1's pads between performance view and control view. |
| **Mode toggle** | The dedicated side button that switches Grid 1's pad layout between performance and control views. Momentary by default, double-tap to latch. |

---

*end of addendum*
