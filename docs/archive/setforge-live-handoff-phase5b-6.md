# Coding agent handoff — setforge-live phase 5b + 6

**Date:** 2026-05-24
**Author:** chat-Claude (Zak's planning session)
**Target:** Claude Code, working in the existing setforge-live worktree
**Status:** setforge-live is partially playable on real hardware (MK2 single-Launchpad). Two scoped enhancements needed.

---

## 0. What you're doing (in one paragraph)

setforge-live is partially working. Audio plays, pad presses route correctly, the two-track (MIDI device + audio device) architecture is in place and operational. **Two things still need work:** (a) the Launchpad MK2's RGB colors render as washed-out pastels that don't differentiate stems clearly enough to play by sight, and (b) the device currently only supports "solo mode" (one active preset sourcing all four stem rows) — the design now calls for an additional "per-row mode" that lets each stem row pull chops from a *different* preset simultaneously, enabling genuine cross-song mashups in the MLR/Daedelus tradition. **This handoff covers both.** Each is independently shippable.

---

## 1. Working state — start here (do this first)

The local working state on `worktree-setforge-live` branch is uncertain. Some work is committed, some may be uncommitted. **Before doing any new work**, run a clean-snapshot step:

```bash
cd /Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live
git status
git log --oneline -10                             # see what's committed recently
```

If `git status` shows uncommitted changes:
1. **Inspect them first.** Run `git diff --stat` to see file scope.
2. **Don't commit blindly.** Group related changes; produce one or more commits with descriptive messages.
3. **A reasonable starting commit message** if the changes are the two-track split + initial MK2 work:
   ```
   setforge-live: in-progress snapshot — two-track split + initial MK2 integration

   - MIDI/audio device split into two M4L devices
   - LP MK2 pad press routing works; colors washed out, not yet investigated
   - Audio plays via the audio-device track
   - Single-preset solo mode operational

   Snapshot commit before color-fix + per-row-mode work begins.
   ```
4. **Surface the resulting commit hash(es) to Zak before proceeding** to either work item below. This is a checkpoint.

If `git status` is clean, just confirm with Zak and proceed.

---

## 2. Work item A — Launchpad MK2 color fix

### 2.1 The symptom (Zak's words)

> "It seems to be working, and pads are where they're expected to be, but the colors are almost pastel versions of what I usually see there, and not differentiated enough."

Pads light up. They light up in roughly the right *position* and roughly the right *hue*. But every color looks washed out, and visually distinct colors (drums-orange, vox-green, etc.) end up too similar to each other to read at a glance.

### 2.2 Likely root causes (in priority order)

**Cause 1 — colors are being routed through the palette-index path instead of direct RGB.** Novation's MK2 supports two color modes:
- **Palette mode** (SysEx `F0 00 20 29 02 10 0A <pad> <palette_idx> F7`): one of 128 preset colors, deliberately tuned by Novation to look good in default Live mode. **Pastel-leaning by design.**
- **Direct RGB mode** (SysEx `F0 00 20 29 02 10 0B <pad> <r7> <g7> <b7> F7`): full 7-bit-per-channel RGB. Saturated colors possible.

**If the loader's `launchpad-surface-mk2.js` is sending colors via palette mode, every color gets snapped to the nearest of 128 Novation presets — which would produce exactly the symptom Zak describes.** This is the most likely cause and should be checked first.

**Cause 2 — RGB conversion math is wrong.** The original addendum spec'd `r7 = r >> 1`, which is a linear truncation. The correct math is:

```js
const r7 = Math.round(rgb.r * 127 / 255);
const g7 = Math.round(rgb.g * 127 / 255);
const b7 = Math.round(rgb.b * 127 / 255);
```

The `>> 1` version maps 255 → 127 incorrectly (it would map to 127 too, but loses 1 bit of precision and rounds badly at the bright end). Small effect but visible if combined with cause 3.

**Cause 3 — no gamma correction.** LEDs are non-linear in perceived brightness. A linearly-scaled RGB value of (60, 30, 20) for an "orange" pad will look much dimmer and less saturated than a gamma-corrected version. Novation hardware may or may not gamma-correct internally — needs to be checked empirically.

A safe gamma-correction pass (after the RGB scale):

```js
const gamma = 2.2;
function applyGamma(v7) {
  // v7 is 0..127
  const normalized = v7 / 127;
  const corrected = Math.pow(normalized, 1 / gamma);
  return Math.round(corrected * 127);
}
```

Apply *after* scaling to 0-127. Try with and without; pick whichever looks better on Zak's hardware.

**Cause 4 — the spec color constants themselves are too pale.** The spec uses values like `#ffe5dc` (drums soft) which is intentionally a soft pastel for *idle* state. The *playing* state uses `#e85d3a` (saturated). If both are reaching the LP at full brightness, the idle pads might be drowning out the playing ones. Worth checking that the loader is using the right color constant for each state, not always the soft one.

### 2.3 Diagnostic steps (do these in order)

1. **Locate `launchpad-surface-mk2.js`** (or whatever it's called) in `src/loader/`. Read the color-write code.
2. **Identify which SysEx command is being sent for color writes.** Log a hex dump of one outgoing color message and inspect:
   - Is the command byte `0A` (palette) or `0B` (direct RGB)?
   - If palette: this is almost certainly the bug. Switch to direct RGB.
   - If direct RGB: check the payload bytes against the input RGB values.
3. **Verify the RGB-to-7bit conversion.** Print before/after values for a few known colors:
   - Drums-on `#e85d3a` → `(232, 93, 58)` → 7bit should be roughly `(116, 46, 29)`
   - Bass-on `#3a85ff` → `(58, 133, 255)` → 7bit should be roughly `(29, 66, 127)`
   - Vox-on `#3aaa6e` → `(58, 170, 110)` → 7bit should be roughly `(29, 85, 55)`
4. **Test direct RGB with hardcoded saturated values** to confirm the hardware can produce vivid colors at all:
   - Send pure red `(127, 0, 0)`, pure green `(0, 127, 0)`, pure blue `(0, 0, 127)` to three pads.
   - If they look vivid: the hardware is fine, problem is in our pipeline.
   - If they look pastel: there may be a brightness/dimming setting on the LP itself (front-panel "User" mode brightness can be cycled — physical buttons on the LP).
5. **Add gamma correction if needed** and compare visually with/without.

### 2.4 Acceptance — color fix is done when

- [ ] Direct RGB mode is confirmed in use (not palette mode), with hex dump as evidence.
- [ ] The four stem-color pairs (drums/bass/other/vox in both idle and playing states) are **visually distinguishable across the room in normal room lighting** — Zak's eye test, not a measurement.
- [ ] Specifically, drums-on vs vox-on are clearly different hues (not both leaning grey-green).
- [ ] The "playing" state of any stem is noticeably brighter/more saturated than its "idle" state.
- [ ] The scene row (purple) is distinguishable from both the preset rows (off-white) and the modifier row (off-white).
- [ ] The "panic" pad on Grid 2 (when single-grid mode is implemented) is unmistakably red even from across the room.
- [ ] Pad color updates remain responsive — no perceptible lag introduced by gamma/conversion changes.

### 2.5 What not to do

- Do **not** change the spec color constants in `color-palette.js` to compensate for hardware quirks. The constants define the design; the hardware adapter should make them work, not the other way around. If a color truly can't be reproduced on MK2 hardware (rare), surface to Zak before changing it.
- Do **not** switch back to palette mode "to keep things simple." Palette mode is the bug, not the solution.
- Do **not** add per-color hardware-specific overrides. Use a single conversion pipeline (scale → gamma → output) and trust it.

---

## 3. Work item B — per-row preset mode (Option C)

### 3.1 What this adds

Today the device has **one mode**: solo mode. The four stem rows (rows 2-5 of Grid 1) all source their chops from a single active preset. Tap a different preset → all four rows switch together. Sequential cross-song mashup via preset swap; no simultaneous cross-song layering.

This work adds a **second mode**: per-row mode. Each stem row independently sources from its own preset assignment. Drums row from preset C, bass row from preset F, other from preset A, vox from preset D — all at once, all playing simultaneously. This is the classic MLR/Daedelus mashup capability.

**Both modes coexist.** Solo mode remains the default; per-row mode is a latchable extension.

### 3.2 The two new gestures

**Gesture 1 — toggle per-row mode (latch):**
- **Double-tap the SOLO modifier** (row 6, col 3).
- SOLO pad latches yellow (consistent with how other modifiers latch).
- While latched, the device is in per-row mode.
- Double-tap again to exit and return to solo mode.

When entering per-row mode, the four stem rows initially keep whatever preset assignment they had (typically all pointing at the current active preset). The user then assigns rows individually.

**Gesture 2 — assign a preset to a stem row:**
- **Hold any pad in that stem row, then tap a preset pad** (row 1 or row 7).
- That stem row's source preset is now the tapped preset.
- The held chop pad itself plays normally (don't suppress its press — just also reassign the row).

So to set up a four-song mashup:
1. Double-tap SOLO → per-row mode on
2. Hold drums-chop-5 + tap preset C → drums row sources from C
3. Hold bass-chop-5 + tap preset F → bass row sources from F
4. Hold other-chop-5 + tap preset A → other row sources from A
5. Hold vox-chop-5 + tap preset D → vox row sources from D

Now you're playing four songs simultaneously, one stem at a time.

### 3.3 Visual feedback (what changes on the LP)

The user needs to know, at a glance, which preset each stem row is sourcing from. The cleanest visual is a **per-row source indicator** — a small colored hint at the row's edge.

**Implementation:** when in per-row mode, the **leftmost pad of each stem row (col 1)** shows a thin colored stripe at its top edge matching the source-preset's `color_hue`. In solo mode, all four leftmost-pad stripes are the same color (the active preset). In per-row mode with cross-assignment, they differ.

If "thin colored stripe" isn't feasible on Launchpad hardware (no sub-pad lighting), an alternative: **use the leftmost pad's full color** to show the source-preset hue, brighter than the rest of the row. The chop number "1" is still printed there (it's the bar-1 chop pad), but its background now signals the source preset.

When solo mode is reactivated, all four leftmost pads return to their normal stem-color appearance.

**Additionally**, when entering per-row mode (SOLO latched), give a brief visual confirmation: the SOLO pad flashes yellow once, and the top row of stem-row pads (col 1 of each stem row) pulses once in their source-preset color. Half a second total. This is the "yes, you're now in per-row mode" feedback.

### 3.4 State changes

The internal preset-routing state grows from a single `activePreset` pointer to:
- `mode`: `"solo"` | `"perRow"`
- `activePreset`: still used in solo mode
- `rowSources`: `{ drums, bass, other, vox }` — each holds a preset ID. Used in per-row mode.

On entering per-row mode: `rowSources` is initialized to all four pointing at the current `activePreset`. Held chops continue playing (their audio is already loaded; they're tied to whatever was their source preset at the moment they started, not to the new mode).

On exiting per-row mode: `rowSources` is discarded. `activePreset` becomes whatever the drums row's source was (an arbitrary but deterministic choice; alternative is "whatever was the most-recently-assigned row"). Held chops continue playing.

### 3.5 Interactions with existing features

- **Hot-swap mechanic (spec §2.5):** in per-row mode, swapping the *drums row's* source preset has the same migrate-at-boundary behavior as a full preset swap — held drums chop migrates to the new source's same-column chop. Other rows are untouched. So per-row mode is essentially "the hot-swap mechanic, but applied to one row at a time."
- **Scenes (row 8):** scenes need to capture mode state. A scene snapshot in per-row mode should record `{ mode: "perRow", rowSources: {...}, held: {...} }`. A scene snapshot in solo mode records `{ mode: "solo", activePreset: ..., held: {...} }`. On scene recall, the mode is restored along with everything else. Backward compatibility: if a scene file lacks a `mode` field (older scenes from before this work), assume solo mode.
- **Modifiers (row 6):** modifiers work identically in both modes. They apply to whichever chop is tapped, regardless of which preset sourced it.
- **FX target (Grid 2 row 5):** the four stem targets (drums/bass/other/vox) target whichever audio is in that row, regardless of source preset. This already works correctly because targeting is by stem, not by song.

### 3.6 Acceptance — per-row mode is done when

- [ ] Double-tap SOLO enters per-row mode; SOLO pad latches yellow.
- [ ] Visual confirmation animation fires on mode entry (SOLO flash + leftmost-stem-pads pulse).
- [ ] Hold-chop + tap-preset gesture reassigns the row's source.
- [ ] Once two rows have different sources, the audio confirms: tapping drums-chop-N plays preset-X's drums; tapping bass-chop-N plays preset-Y's bass; both playing simultaneously, on the global grid, in phase.
- [ ] Leftmost pad of each stem row shows source-preset hue (or whatever visual you chose) so user can see at a glance which preset each row pulls from.
- [ ] Held chops survive mode transitions (entering and exiting per-row mode) without audio interruption.
- [ ] Held chops survive per-row source reassignment with the same hot-swap migration as a full preset swap.
- [ ] Scene save in per-row mode captures the rowSources mapping; scene recall restores it.
- [ ] Scene save/recall in solo mode unaffected (regression test).
- [ ] Exiting per-row mode (second double-tap of SOLO) returns to single-active-preset behavior cleanly.

### 3.7 Edge cases to handle

- **What if a row's source preset is unloaded** (e.g. user assigned bass row to preset F, then loaded a different song into slot F)? The row should follow the slot — the new song becomes the source. This is the right behavior because the user thinks of slot F as a slot, not as a specific song.
- **What if the user enters per-row mode with no preset active at all** (e.g. fresh load, nothing tapped yet)? All four rowSources stay null until assigned. Tapping a chop with a null source = silent pad press (no audio, brief error blink).
- **What if the user assigns the same preset to multiple rows?** That's fine — both rows source from the same song's respective stems. This is the degenerate case that equals solo mode for those two stems.
- **What about per-row mode and the launch-quant per-row settings (spec §2.4)?** Quantization is per-row, not per-preset, so it remains unchanged. Drums still quant at 1/16 regardless of which preset it's pulling from.

### 3.8 What this does NOT add (deferred to future work)

- **Pre-authored mashup presets** (Option B from the design conversation): a preset slot could hold a recipe like "drums from C, bass from F, etc." and be tappable as a single unit. The current work enables this *via per-row mode improvisation* but doesn't add the manifest format for pre-authored mashups. Defer.
- **Saving the current per-row state as a new preset slot.** Tempting feature, but adds complexity to the set.json schema. Defer.
- **Visualizing source presets on Grid 2's setlist.** Could light up which setlist tracks are currently sourcing each stem row. Nice-to-have, not essential.

---

## 4. Order of work

Do these in this order:

1. **Snapshot the current state** (§1) — get a clean commit baseline. Surface commit hash to Zak.
2. **Color fix** (§2) — this is more bounded and easier to acceptance-test. Ship it as one commit (or a small series). Get Zak to do the eye test before moving on.
3. **Per-row mode** (§3) — this is the meatier change. Ship it as multiple commits if the work breaks naturally into pieces (e.g. one commit for the state machine, one for the gestures, one for the visual feedback, one for scene-recall integration).

Each numbered acceptance bullet in §2.4 and §3.6 should be verified before declaring the corresponding work item done.

---

## 5. Non-goals for this handoff

- Do not touch the two-track architecture (MIDI device + audio device split). Zak built it; it works; leave it alone.
- Do not add Grid 2 support if it doesn't exist yet. Single-grid mode is fine for this work.
- Do not refactor `color-palette.js` color constants. The constants are right; the hardware adapter is what needs fixing.
- Do not write a new spec document. Updates to behavior should be captured in commit messages and (if Zak asks) folded into the existing spec or addendum afterward.
- Do not push to any remote. Stay on `worktree-setforge-live`.
- Do not modify any other device (`device/tape-loss/`, `device/punch-fx/`).

---

## 6. How to surface questions

If the diagnostic in §2.3 reveals something unexpected (e.g. the loader is already using direct RGB mode, ruling out the most likely cause), or if any part of §3 conflicts with how the current code is structured, **stop and ask Zak rather than guessing**.

Append questions to `docs/exec-plans/active/setforge-live-handoff-questions.md` (create if doesn't exist). Format:

```markdown
## Q1
**Asked:** 2026-MM-DD
**Context:** <one sentence>
**Question:** <the question>
**Blocker?** yes/no
**Default if no answer in 24h:** <what you'll do otherwise>
```

---

## 7. Definition of done — this whole handoff

- [ ] Clean snapshot commit exists at the start (§1)
- [ ] Color fix work is committed; all §2.4 acceptance bullets pass
- [ ] Per-row mode work is committed; all §3.6 acceptance bullets pass
- [ ] Working tree clean (`git status` reports nothing to commit)
- [ ] Zak has done the eye test for colors and the audio test for cross-song mashup
- [ ] Any questions surfaced via §6 have been resolved

Surface the final commit hash(es) and a brief summary of what was done to Zak.

---

*end of handoff doc*
