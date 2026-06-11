# Pro MK2 Surface Implementation Spec

**Status:** Design spec — NO code changes yet.
**Hardware:** Novation Launchpad Pro (original / "MK2"), registers as "Launchpad Pro" in Live.
**Scope:** New button→function layout per the locked product definition. Same hardware, new mapping.

## 1. Current State

The current `launchpad-surface-mk2.js` implements:
- 8×8 grid: `note = (9-row)*10 + col` (rows 1-8 top-to-bottom, cols 1-8 left-to-right)
- Left side buttons: notes `[80, 70, 60, 50, 40, 30, 20, 10]` (top→bottom)
- Right side buttons: notes `[89, 79, 69, 59, 49, 39, 29, 19]` (hardcoded in controller, not surface)
- Top row CC buttons: CC `[91, 92, 93, 94, 95, 96, 97, 98]` — currently unused by loader
- Bottom row CC buttons: CC `[1, 2, 3, 4, 5, 6, 7, 8]` — currently unused by loader
- SysEx: `F0 00 20 29 02 10 ...` (device ID `0x10`)
- RGB: 7-bit per channel (0-127), batched up to 70 pads per SysEx

### Current Layout (being replaced)

```
         [CC91] [CC92] [CC93] [CC94] [CC95] [CC96] [CC97] [CC98]   ← top CCs (unused)
[80]      81     82     83     84     85     86     87     88   [89]
[70]      71     72     73     74     75     76     77     78   [79]
[60]      61     62     63     64     65     66     67     68   [69]
[50]      51     52     53     54     55     56     57     58   [59]
[40]      41     42     43     44     45     46     47     48   [49]
[30]      31     32     33     34     35     36     37     38   [39]
[20]      21     22     23     24     25     26     27     28   [29]
[10]      11     12     13     14     15     16     17     18   [19]
         [CC1]  [CC2]  [CC3]  [CC4]  [CC5]  [CC6]  [CC7]  [CC8]    ← bottom CCs (unused)
```

Current mapping: rows 1-4 = stem chops, rows 5-6 = presets A/B, row 7 = modifiers, row 8 = scenes.

## 2. New Layout (Locked Design)

### Design Principles
- **8×8 grid = 8 stem rows × 8 chop columns** (all grid pads are chops)
- **Side buttons carry all non-chop functions** (presets, modifiers, stem-assign)
- **Per-source-preset coloring** throughout (grid rows + side buttons lit by source preset color)

### Button→Function Map

```
          [T1:A1] [T2:A2] [T3:A3] [T4:A4] [T5:A5] [T6:A6] [T7:A7] [T8:A8]  ← Top = Bank A presets
[L1:DR]    81      82      83      84      85      86      87      88   [R1:HOLD]
[L2:BA]    71      72      73      74      75      76      77      78   [R2:SOLO]
[L3:OT]    61      62      63      64      65      66      67      68   [R3:MUTE]
[L4:VX]    51      52      53      54      55      56      57      58   [R4:PANIC]
[L5:DRx]   41      42      43      44      45      46      47      48   [R5:SCENE_A]
[L6:BAx]   31      32      33      34      35      36      37      38   [R6:SCENE_B]
[L7:OTx]   21      22      23      24      25      26      27      28   [R7:DUAL]
[L8:VXx]   11      12      13      14      15      16      17      18   [R8:spare]
          [B1:B1] [B2:B2] [B3:B3] [B4:B4] [B5:B5] [B6:B6] [B7:B7] [B8:B8]  ← Bottom = Bank B presets
```

### Side Buttons

| Position | Notes | Function |
|----------|-------|----------|
| **Top 1-8** | CC `[91,92,93,94,95,96,97,98]` | Bank A presets (A1-A8) |
| **Bottom 1-8** | CC `[1,2,3,4,5,6,7,8]` | Bank B presets (B1-B8) |
| **Left 1-8** | `[80,70,60,50,40,30,20,10]` | Stem-assign triggers: drums, bass, other, vox, drums-x, bass-x, other-x, vox-x |
| **Right 1-8** | `[89,79,69,59,49,39,29,19]` | **REPEAT, STUTTER, SLICER, OCT−, PANIC, SCN◀, SCN▶, (free)** — punch-FX grouped, see below |

**TODO: confirm on hardware** — The top/bottom CC buttons may or may not send note-on/note-off vs CC messages in programmer mode. The MK2 programmer reference says they send CCs (not notes). The controller's `msg_int` handler processes raw MIDI bytes, so CC messages arrive via `processMidiByte` as status `0xB0`. Currently the controller only handles `0x90` (note-on), `0x80` (note-off), and `0xB0` (CC → `handleControlChange` for remote commands). **The top/bottom buttons will need CC routing to preset activation, separate from the remote CC map (100-108).**

### Right side — punch-FX + utility (updated 2026-06-10)
The 4 momentary **punch-fx** triggers (the EP-133-style M4L device at `device/punch-fx`: Beat Repeat, Stutter, Mute Slicer, Octave Down) replace HOLD / SOLO / MUTE / spare:

The 4 punch triggers are **grouped contiguously at the top**, then PANIC + scene cycle, with the freed slot at the bottom:

| Note | Function |
|------|----------|
| 89 (R1) | **REPEAT** — Beat Repeat (punch-fx trigger 1) |
| 79 (R2) | **STUTTER** — Stutter (trigger 2) |
| 69 (R3) | **SLICER** — Mute Slicer (trigger 3) |
| 59 (R4) | **OCT−** — Octave Down (trigger 4) |
| 49 (R5) | PANIC |
| 39 (R6) | **SCENE ◀** — recall previous vetted scene |
| 29 (R7) | **SCENE ▶** — recall next vetted scene |
| 19 (R8) | *(free)* — was DUAL; unset for now (always-dual makes the toggle obsolete) |

**Gesture (hold-FX → press pad):** the round punch buttons are **momentary mode-shifts**, not fire-and-forget triggers.

1. **Hold** a punch button (REPEAT / STUTTER / SLICER / OCT−) → grid enters **FX-APPLY** mode; the 8×8 grid's chop-trigger function is overridden.
2. **Press a pad** → the effect engages on the **clip/stem under that pad**, and the pad's **polyphonic aftertouch** (the Pro MK2 grid pads *do* sense per-pad pressure) drives the **0–1 FX amount**. Multiple pads held = multiple stems FX'd, each with independent pressure (punch-fx supports simultaneous effects).
3. Release pad = effect off for that stem · release the FX button = grid returns to chop-triggering (back to IDLE).

This solves the pressure problem cleanly — **pressure comes from the grid pad, not the round button** (so the side-button on/off limitation no longer matters).

**Build implications:**
- **Routing → per-stem (Phase 1).** The set already has **8 individual stem tracks** (`sf-{drums,bass,other,vox}-{x,y}`) and **no deck group/bus tracks**, so per-stem is the *easier* path: drop a `punch-fx` on each existing stem track — no new routing. (Per-deck would require *creating* group/bus tracks + re-routing, and a summed bus can't isolate a single stem, so the per-pad gesture would lose meaning within a deck.) **Leave the door open to configuration:** isolate target resolution behind a single `resolveFxTarget(pad, mode)`; ship `mode="per-stem"`; a future `"deckA"/"deckB"/"master"` mode is then just a settings toggle (the loader already declares `FX_TARGETS = [drums,bass,other,vox,all,deckA,deckB,master]`). Control code is mode-agnostic.
- **Poly-aftertouch (`0xA0`)** — the controller must handle polyphonic key pressure while in FX-APPLY mode; today `processMidiByte` only handles `0x90` / `0x80` / `0xB0`. Add `0xA0`.
- **Two FX buttons at once** — start **one-at-a-time** (last press wins); revisit stacking later.
- **State machine** — add `FX_APPLY` alongside `IDLE` / `ASSIGNING`: `IDLE → (hold punch btn) → FX_APPLY → (pad down) engage + (poly-AT) set amount → (pad up) disengage → (btn up) IDLE`.
- **Stretch (Phase 2):** option to route the punch triggers to a dedicated Ableton **send** with its own VST chain.

**SCENE ◀/▶** cycle through the vetted clip pairings ("scenes"), recalling each — the manual-trigger model (single-button recall stays deferred). **Slot 19 (free)** — DUAL is obsolete under always-dual; left unset for now (TBD).

### 8×8 Grid (Chops)

| Row | Spec Row | Notes | Stem |
|-----|----------|-------|------|
| 1 (top) | 1 | 81-88 | drums (deck A / default) |
| 2 | 2 | 71-78 | bass |
| 3 | 3 | 61-68 | other |
| 4 | 4 | 51-58 | vox |
| 5 | 5 | 41-48 | drums (deck B / extended) |
| 6 | 6 | 31-38 | bass (extended) |
| 7 | 7 | 21-28 | other (extended) |
| 8 (bottom) | 8 | 11-18 | vox (extended) |

In single-deck mode, rows 5-8 mirror rows 1-4 (same stem, same source).
In dual-song mode, rows 1-4 = deck X, rows 5-8 = deck Y.

## 3. Stem-Assign Gesture

**Hold left stem-assign button → tap a preset (top=A / bottom=B) → that row sources from that preset.**

### State Machine

```
IDLE
  │
  ├── left_press(stem_idx) → ASSIGNING(stem_idx)
  │     └── lit: left button pulses white; grid row[stem_idx] dims
  │
  ├── preset_press(bank, slot) → normal preset activation (existing flow)
  │
  └── grid_press(row, col) → normal chop trigger (existing flow)

ASSIGNING(stem_idx)
  │
  ├── preset_press(bank, slot) → ASSIGN stem_idx to preset[bank][slot]
  │     └── row[stem_idx] now shows chops from that preset
  │     └── left button[stem_idx] lit with preset's source color
  │     └── → IDLE
  │
  ├── left_release(stem_idx) → IDLE (cancel)
  │
  └── same_left_press(stem_idx) → RESET row to default source → IDLE
```

### Constraints
- Max 1 stem per type per bank (e.g., only one drums row can source from A3)
- Assigning a stem from a new preset stops any playing chop on that row, loads the new chops, re-colors the row

## 4. Per-Source LED Coloring

Each loaded preset gets a stable color from a shared palette (same as companion app `LEGEND_PALETTE`):

```javascript
LEGEND_PALETTE = [
    "#F5A623",  // slot 0 — warm amber
    "#FF7A3D",  // slot 1 — orange
    "#E85B5B",  // slot 2 — red
    "#B058CF",  // slot 3 — purple
    "#8C7BFF",  // slot 4 — indigo
    "#34C8E8",  // slot 5 — cyan
    "#3DCC91",  // slot 6 — green
    "#8BC34A",  // slot 7 — lime
];
```

Conversion to 7-bit RGB for MK2: `r7 = Math.round(r8 * 127 / 255)`.

| Element | Color rule |
|---------|-----------|
| Grid row pads (chops) | Source preset's color; dim if no clip, bright if loaded, flash if playing |
| Left side button (stem-assign) | Source preset's color for that row |
| Top side button (bank A preset) | Preset's color if loaded; off if empty |
| Bottom side button (bank B preset) | Preset's color if loaded; off if empty |
| Right side button (modifier) | White when idle; modifier-specific color when active |

## 5. SysEx Reference (Launchpad Pro MK2)

All confirmed from the current working `launchpad-surface-mk2.js`:

| Function | SysEx |
|----------|-------|
| Programmer mode enter | `F0 00 20 29 02 10 2C 03 F7` |
| Programmer mode leave | `F0 00 20 29 02 10 2C 00 F7` |
| RGB LED (batch) | `F0 00 20 29 02 10 0B <note r g b>... F7` (max 70 pads, 7-bit RGB) |
| Pulse (palette) | `F0 00 20 29 02 10 28 <note> <palette_idx> F7` |
| Flash (palette) | `F0 00 20 29 02 10 23 <note> <colorA> <colorB> F7` |

**TODO: confirm on hardware** — Can RGB SysEx address the CC buttons (top row CC91-98, bottom row CC1-8)? The MK2 programmer ref may require a different addressing mode for CC buttons vs grid pads. If CC buttons can't be RGB-addressed, fall back to palette colors via the flash/pulse SysEx.

## 6. Implementation Plan

### File Changes

1. **New file: `src/loader/launchpad-surface-pro-mk2.js`**
   - Implements the full surface interface
   - Adds `topButtonIndex(cc)` and `bottomButtonIndex(cc)` methods for CC-based preset buttons
   - Same note mapping as MK2 for the 8×8 grid and left/right side buttons
   - May need new interface methods: `queueRgbCC(grid, cc, [r,g,b])` if CC buttons use different SysEx addressing

2. **Modified: `src/loader/launchpad-surface.js` (factory)**
   - Add `"pro-mk2"` case to `createSurface(model)`

3. **Modified: `src/loader/loader-controller.js`**
   - Replace hardcoded `createSurface("mk2")` with runtime detection or config
   - Add CC routing for top/bottom preset buttons (new `handlePresetCC` or extend `handleControlChange`)
   - Implement stem-assign gesture state machine
   - Move `SIDE_BUTTONS_RIGHT` into the surface interface (currently hardcoded in controller)
   - Add `SIDE_BUTTONS_TOP`, `SIDE_BUTTONS_BOTTOM` handling
   - Replace `handleGrid1Press` row-based dispatch (currently: rows 1-4=chops, 5-6=presets, 7=modifiers, 8=scenes) with all-chops dispatch + side-button routing
   - Update `updateAllPadColors` for per-source coloring

4. **Modified: `build/build_setforge.py`**
   - Add `launchpad-surface-pro-mk2.js` to the JS concat list

### Runtime Hardware Detection

```javascript
// Option A: config-driven (simplest)
var SURFACE_MODEL = "pro-mk2";  // or read from device parameter / pattr

// Option B: MIDI identity query (robust)
// Send SysEx Identity Request: F0 7E 7F 06 01 F7
// Parse response for device ID → pick surface
```

**Recommendation:** Start with config-driven (Option A). Hardware detection can be added later.

### Surface Verifier (new test)

Add to `tools/forge_device/verifiers.py`:
- `verify_surface_note_map`: round-trip `noteToRowCol` ↔ `rowColToNote` for all 64 pads
- `verify_surface_side_buttons`: all 4 banks (left/right/top/bottom) have 8 entries, no overlap with grid
- `verify_surface_sysex`: programmer mode enter/leave are valid SysEx (start F0, end F7)

## 7. Build + UAT Acceptance Checklist

### Build
- [ ] `launchpad-surface-pro-mk2.js` implements full interface contract
- [ ] `createSurface("pro-mk2")` returns a valid surface
- [ ] `build_setforge.py` concatenates the new file into `loader.js`
- [ ] All existing verifiers pass (`make test`)
- [ ] New surface verifier passes
- [ ] 23/23 e2e tests still green (existing behavior preserved when model != "pro-mk2")

### UAT (on hardware)
- [ ] Programmer mode enters correctly (grid lights up)
- [ ] Top buttons activate bank A presets (A1-A8)
- [ ] Bottom buttons activate bank B presets (B1-B8)
- [ ] Left buttons trigger stem-assign mode (hold + preset tap)
- [ ] Right buttons trigger modifiers (HOLD, SOLO, MUTE, PANIC, scenes, dual-song)
- [ ] 8×8 grid triggers chops (all 8 rows)
- [ ] Per-source coloring: rows show their source preset's color
- [ ] Stem-assign: hold L1(drums) + tap T3(A3) → drums row sources from A3
- [ ] Dual-song: rows 1-4 = deck X, rows 5-8 = deck Y
- [ ] Flash/pulse animations work for preset staging
- [ ] `uat_perform_smoke.py` still passes (note numbers unchanged for basic chop/preset flow)

## 8. Provisional Hardware Profile  (assume now — verify 2026-06-11 PM)

zak can't reach the hardware until ~PM 2026-06-11. To stay unblocked we **build against a single provisional profile**, isolated in named tables, so verification = a one-file diff. Rationale below; nothing here is a blocker.

**Profile: original Launchpad Pro, all-notes programmer-mode layout** — this is what the *existing working surface code already encodes* (`launchpad-surface-mk2.js` + `SIDE_BUTTONS_LEFT/RIGHT`), and it has been exercised live (grid load, dual-song flash on note 89). The "round buttons send CC" wording in Novation docs is from the **MK3 / Launchpad X** reference, not this unit.

| Item | Provisional value | Confidence | Why |
|------|-------------------|-----------|-----|
| Grid pads | Notes **11–88** (`note=(9-row)*10+col`) | **High** | Working code + Novation Pro ref ("square buttons send Note On/Off") |
| Left / Right side buttons | **Notes** `80…10` / `89…19` | **High** | Already in working code; LED-by-note + note-89 flash exercised live |
| Top / Bottom preset buttons | **Notes** `91–98` / `1–8` (NOT CC) | **Med** | Consistent with the all-notes Pro layout; supersedes the earlier "treat as CC" guess. *Highest-value thing to verify PM.* |
| Punch buttons (right top 4) | Notes `89,79,69,59` | **Med** | Right-column notes; → cc handles both note **and** CC at these numbers as belt-and-suspenders |
| Pad pressure message | **Polyphonic aftertouch `0xA0`** | **Med-High** | Pro supports it; **user step:** set Pressure Mode = *Polyphonic Aftertouch* in the Launchpad Setup page. Code already handles `0xD0` fallback too. |
| RGB / pulse / flash addressing | By **note number**, SysEx as in `launchpad-surface-mk2.js` | **High** | Working code; if all buttons are notes, no separate CC-RGB path needed |
| Max SysEx batch | 70 pads | **Confirmed** | Already implemented |

**Residual risks to check PM (ranked):** (1) top/bottom presets note-vs-CC; (2) AT poly-vs-channel (handled both); (3) punch buttons note-vs-CC (handled both). All isolated in named tables → flipping any is a small edit, no logic rework.
