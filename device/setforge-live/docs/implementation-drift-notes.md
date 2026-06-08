# setforge-live — Implementation Drift Notes

**Code is the source of truth.** This document logs every place where the deployed
controller `src/loader/loader-controller.js` (the concatenated monolith that actually
ships in the `.amxd`) disagrees with the historical local spec documents. Where the
spec and code conflict, **trust the code** — these entries exist to record the gap so
the specs can eventually be reconciled, not to imply the code is wrong.

All `:NNN` line references below are `loader-controller.js:<line>`, derived from the
verified master behavior catalog (`/tmp/setforge-master-catalog.md`, §14 drift ledger).

## Spec documents compared

The following spec / handoff docs were used as the drift baseline:

- `spec/setforge-live-spec.md` — base device spec (**present on disk**)
- `spec/setforge-live-spec-multi-song-modes.md` — multi-song modes spec (**present on disk**)
- base-spec handoff / multi-song handoff notes — cited in the catalog (e.g. handoff line 105)
- launchpad addendum — cited in the catalog (e.g. addendum §3.2, §3.7, §4.1, §4.4)

**Two spec docs referenced by the documentation-generation spec are ABSENT on disk:**

- `setforge-live-multi-song-gap-closure.md` — **not found** in `spec/` or repo root
- `setforge-live-spec-row7-modifiers.md` — **not found** in `spec/` or repo root

Their absence is recorded here so that any drift those docs might have described cannot
be claimed against current code; nothing below is sourced from them.

## How to read severity

- **breaks-spec** — code does NOT do what the spec promises; a real functional gap
  (including the runtime crash in item 1). Items 1–5.
- **minor-divergence** — code does something close to, but not exactly, the spec;
  usually a v0 simplification or a cosmetic difference. Items 6–23.
- **spec-was-updated** — the base spec was superseded by a later (multi-song / addendum)
  spec, and the code follows the newer one; the base spec is simply stale. Items 24–27.
- **unclear** — premise can't be tied to either code or a cited spec. Item 28.

There are **28 drift entries** total: 5 breaks-spec, 18 minor-divergence, 4 spec-was-updated,
1 unclear. The breaks-spec items lead.

---

## Dual-song-entry-failure red blink (DUAL_SONG_TOGGLE ReferenceError)

**Spec source:** setforge-live-spec-multi-song-modes.md §5.5 / §6.8
**Spec says:** The dual-song toggle side button blinks red briefly when entry fails (no
deck staged / only partial staging).
**Code does:** `enterDualSongMode` calls `flashSideButtonRed(DUAL_SONG_TOGGLE)` at
`loader-controller.js:2319` and `loader-controller.js:2326`. The identifier
`DUAL_SONG_TOGGLE` is **never declared** — it exists only as a string literal inside
`SIDE_FUNC_RIGHT[0]` (`:78`). Referencing it throws a **ReferenceError at runtime**, so
the failure branch crashes outright and the red blink never renders. This is the single
most severe drift item: the dual-song no-deck / partial-deck path is broken, not merely
cosmetically wrong.
**Severity:** breaks-spec (most severe — runtime crash)
**Recommendation:** Update code. Pass `SIDE_BUTTONS_RIGHT[0]` (note 89) instead of the
undeclared identifier. Add a verifier for undeclared identifiers and a smoke test of the
failure path. (See Open Question 1: it is unverified whether this branch was ever hit on
hardware — if the button is only pressed after staging, it may have been masked. Fix
regardless.)

## REV / STUT / HALF / DBL / MUTE / KILL row-7 modifiers apply audio effects

**Spec source:** setforge-live-spec.md §2.4 (lines 199–205); multi-song handoff line 105
**Spec says:** REV reverses the chop, STUT does 1/8 retrigger, DBL doubles speed, HALF
halves it, MUTE mutes, KILL kills — each acts on the chop's audio.
**Code does:** These 6 modifier states are **never read on any audio / LiveAPI path**.
They are written by `pressModifier` and read only by pad-color render, scene
snapshot/restore, and the debug dump. The **only** `modState.<X>` reads anywhere in the
file are HOLD and SOLO. So 6 of the 8 row-7 modifiers (MUTE, REV, STUT, HALF, DBL, KILL)
are fully **inert, visual-only stubs** — they light a pad and serialize into scenes but
produce no audio change.
**Severity:** breaks-spec
**Recommendation:** Document divergence. Present these 6 modifiers explicitly as
visual-only stubs; do NOT present them as functional in any user-facing doc.

## HOLD one-shot (play once full length then stop)

**Spec source:** setforge-live-spec.md §2.4 (line 199 / 188)
**Spec says:** One-shot — the chop plays once for its full length (4 bars) and then
stops, regardless of quant.
**Code does:** `pressChop` returns action `one_shot` when HOLD is held/latched (`:443`),
but `onChopPress` consumes `one_shot` **identically** to start/replace (same
`launchClipInTrack` arguments, `:2758–2759`) and does NOT update `playingChops` — so
there is no play-once-then-stop and no auto-stop. HOLD's real, load-bearing role is
**SHIFT**: in `onPresetPress` it switches the active preset WITHOUT migrating held
chops, and in `onScenePress` it makes the scene pad SAVE instead of recall.
**Severity:** breaks-spec
**Recommendation:** Update spec / document divergence. Describe HOLD's real effect
(SHIFT for preset-no-migrate and scene-save, plus an untracked launch branch) — it is
NOT a true one-shot.

## FX bus / punch-fx affects audio

**Spec source:** setforge-live-spec.md FX sections (lines 265, 339) + `FILTER_POSITIONS`;
multi-song handoff reference to `device/punch-fx`
**Spec says:** FX targets, a filter sweep with real cutoff frequencies, and FX-B "throws"
act as live audio effects.
**Code does:** `fxTarget`, `fxFilterCol`, `fxFilterLatched`, and `fxThrowCol` drive
**only** pad colors and status text — **zero LiveAPI calls**. `FILTER_POSITIONS` (the
lp/hp frequency table) is defined but **never referenced**. A grep for `punch` returns
**0 hits**; there is no punch-fx device integration in the deployed monolith.
**Severity:** breaks-spec
**Recommendation:** Document divergence. Present the FX bus (Grid 2 rows 5/6/7) as a
visual/status-only stub; there is no punch-fx integration in the shipped device.

## Grid 1 performance-view row layout

**Spec source:** setforge-live-spec.md §1.4 (lines 110–117)
**Spec says:** Row 1 = bank A, rows 2–5 = stems, row 6 = modifiers, row 7 = bank B,
row 8 = scenes.
**Code does:** `updateGrid1Colors` (`:1708–1774`) renders the **inverted** layout:
rows 1–4 = stems (drums/bass/other/vox), row 5 = bank A (slots 0–7), row 6 = bank B
(slots 8–15), row 7 = modifiers, row 8 = scenes.
**Severity:** breaks-spec
**Recommendation:** Update spec. Treat the code layout as ground truth; the §1.4 diagram
is stale and should be regenerated from `updateGrid1Colors`.

## Pre-load file-missing → flash red + clear deck staging

**Spec source:** setforge-live-spec-multi-song-modes.md §5.6
**Spec says:** When a deck pre-load fails (file missing), flash the staged pad red, clear
that deck's staging, log it, and don't crash.
**Code does:** `onStageDeck` guards only on slot **state** (empty/loading/error → red
flash + 500ms revert, no staging — this part works). For a runtime `create_audio_clip`
failure it does NOT check the returned `loaded` count: it sets `staging[deck]` /
`loadedDecks[deck]` and proceeds to load. `loadStemClipsToTrack` swallows per-clip errors
and just posts them (`:962–964`); it never clears staging or flashes red on a file-missing
failure (`:2672–2685`, `:894–967`).
**Severity:** minor-divergence
**Recommendation:** Update code. After `loadPresetToDeckX/Y`, if the loaded count is
0 / a sentinel, flash the pad red and reset that deck to null.

## Per-row entry pulse animation (~500ms)

**Spec source:** setforge-live-spec-multi-song-modes.md §4.5
**Spec says:** On entering per-row mode, SOLO flashes yellow once and col-1 of each stem
row pulses once in its source-preset color, ~500ms.
**Code does:** `togglePerRowMode` only sets state and calls `updateAllPadColors()` once
(`:2439`). The col-1 source color is a **static** repaint, not a timed Task — there is no
~500ms pulse animation.
**Severity:** minor-divergence
**Recommendation:** Document divergence. Describe the col-1 tint as a persistent static
indicator; the ~500ms entry animation is unimplemented.

## Per-row source change at next launch-quant boundary

**Spec source:** setforge-live-spec-multi-song-modes.md §4.3
**Spec says:** A per-row source change takes effect at the next launch-quant boundary for
that row.
**Code does:** `onPerRowReassign` sets `rowSources` and then **immediately** calls
`loadStemClipsToTrack` and immediately migrates any held chop (`:2476–2510`). Only Live's
own clip-launch quantization applies — there is no JS-enforced boundary defer.
**Severity:** minor-divergence
**Recommendation:** Document divergence. Clarify that assignment and clip load are
immediate; quantization is Live's clip-launch quant, not a controller-enforced boundary.

## Per-row exit discards rowSources

**Spec source:** setforge-live-spec-multi-song-modes.md §4.6 / §7.2
**Spec says:** On per-row exit, `rowSources` is discarded and the active preset becomes
the drums-row source.
**Code does:** Exit re-activates the drums source (matches) but does NOT clear
`rowSources` — the values persist in memory and are simply gated off by the
`performanceView==='perRow'` check (`:2428–2438`). A separate reset path at `:2926`
(panic) does null them out.
**Severity:** minor-divergence
**Recommendation:** Document divergence. Note `rowSources` is effectively (gated-off) not
literally discarded on exit; only the panic reset path at `:2926` clears it.

## Dual-song toggle X/Y preset-color alternation

**Spec source:** setforge-live-spec-multi-song-modes.md §5.4 / §6.3
**Spec says:** Both decks staged → toggle LED alternates X and Y preset colors ~500ms;
one staged → solid that color; neither → dim white.
**Code does:** `updateDualSongToggleLed` (`:2288–2298`) uses **white intensity tiers
only**: bright white when dual-song active, mid white when anything staged, OFF when
nothing staged. No preset color, no alternation; the "neither" state is OFF, not dim
white. A code comment at `:2284` notes "alternation flash deferred."
**Severity:** minor-divergence
**Recommendation:** Update code or document divergence. Implement per-deck color
alternation, or document the white-tier v0 behavior.

## Invisible-held-chops indicator on toggle

**Spec source:** setforge-live-spec-multi-song-modes.md §6.6 / §6.8
**Spec says:** A red tint / slow-pulse overlay appears on the toggle when invisible
held chops are active across the view flip.
**Code does:** There is no held-chop tracking across the dual-song flip, and
`updateDualSongToggleLed` has no such branch. The indicator is **ABSENT**.
**Severity:** minor-divergence
**Recommendation:** Update code or mark deferred. Implement cross-view held-chop
detection + overlay, or mark §6.6 as deferred.

## "Staged for both decks" 3-color cycle

**Spec source:** setforge-live-spec-multi-song-modes.md §5.4 / §5.6
**Spec says:** If the same preset is staged onto both decks, its pad runs a 3-color cycle
(preset color, white, soft blue).
**Code does:** Staging is **bank-mapped**: a given slot lives in only one row (row 5 =
bank A → deck X, row 6 = bank B → deck Y), so one pad maps to exactly one deck.
`updateGrid1Colors` emits a single 2-color flash; there is no 3-color cycle and no
shared-slot detection.
**Severity:** minor-divergence
**Recommendation:** Document divergence. Clarify that bank-mapping precludes a single pad
from being on both decks, or implement a shared-slot 3-color cycle.

## Deck-setup side-button idle color

**Spec source:** setforge-live-spec-multi-song-modes.md §5.4
**Spec says:** Deck-setup button idle (not held) = dim white; held = bright white.
**Code does:** Held = bright white (matches). Idle = dim white `[16,16,16]` **only when
something is staged**, and fully OFF `[0,0,0]` when nothing is staged (`:2278–2281`).
**Severity:** minor-divergence
**Recommendation:** Update code or document. Return `[16,16,16]` unconditionally when
idle, or document the staging-dependent idle color.

## Pre-load as non-blocking background stream

**Spec source:** setforge-live-spec-multi-song-modes.md §5.3
**Spec says:** Staging immediately streams stems into the audio engine in the background;
non-blocking.
**Code does:** `onStageDeck` → `loadPresetToDeckX/Y` → `loadStemClipsToTrack` creates all
clips **synchronously** inside the press handler (`:894–967`). The only deferred work is
the warp-marker fix via `Task.schedule(4000)`; clip creation blocks the handler.
**Severity:** minor-divergence
**Recommendation:** Document divergence or update code. Document v0 pre-load as
synchronous clip creation + a deferred warp pass, or move clip creation into a Task.

## Unified four-value `view` variable

**Spec source:** setforge-live-spec-multi-song-modes.md §2 (lines 27–29), §7.6 (line 167)
**Spec says:** A single 4-valued variable `view: "solo" | "perRow" | "dualSong" |
"control"`.
**Code does:** There is no single variable. State is split across `performanceView`
(holds only `"solo"` / `"perRow"`), `dualSongActive` (boolean), and `viewMode`
(`"performance"` / `"control"`). The 4-valued string exists only in scene serialization
(`:576`), reconstructed into the three live vars on recall.
**Severity:** minor-divergence
**Recommendation:** Document divergence. Document the tri-variable implementation; the
unified enum exists only at the scene-serialization boundary.

## Control view as a mutually-exclusive 4th view

**Spec source:** setforge-live-spec-multi-song-modes.md §2 (lines 29, 38)
**Spec says:** Control is one of four views, with only one active at a time.
**Code does:** `viewMode` is **orthogonal** — control view can coexist with
`dualSongActive` or `performanceView==='perRow'`. Entering control doesn't change those
vars (`:2170–2183`); it is an overlay/hijack of Grid 1, not a mutually-exclusive sibling.
**Severity:** minor-divergence
**Recommendation:** Document divergence. Document control view as an overlay/hijack of
Grid 1 rather than a sibling of the performance views.

## PANIC tap-count window

**Spec source:** setforge-live-spec.md §2.3 (line 367)
**Spec says:** "Triple-tap to confirm." No window duration is stated.
**Code does:** A hardcoded **1000ms** reset window governs the triple-tap (`:2198`,
`:2895`), which is distinct from `DOUBLE_TAP_WINDOW_MS` (400ms).
**Severity:** minor-divergence
**Recommendation:** Update spec (additive). Document the 1000ms PANIC window; the spec is
silent on it.

## PANIC does not reset control view / staging

**Spec source:** setforge-live-spec-multi-song-modes.md §6.x (line 351)
**Spec says:** Triple-tap PANIC in dual-song → all audio stops and the mode reverts to
solo.
**Code does:** `executePanic` reverts `performanceView='solo'` (`:2924`) and clears
`dualSongActive` (`:2921`), but leaves `viewMode` (control overlay), `staging.deckX/Y`,
and `loadedDecks` intact.
**Severity:** minor-divergence
**Recommendation:** Document divergence. Note that "reverts to solo" applies only to the
performance / dual-song axis; the control overlay and staging are NOT cleared by panic.

## Only one modifier latched at a time (mutual exclusion)

**Spec source:** setforge-live-spec.md (line 659, test table)
**Spec says:** Modifier latches are mutually exclusive — only one can be latched.
**Code does:** `pressModifier` has no exclusion logic (`:504–521`); multiple modifiers can
be latched simultaneously. (Any single-latch logic in the reference-only
`modifier-layer.js` is NOT deployed.)
**Severity:** minor-divergence
**Recommendation:** Document divergence. The deployed monolith does not enforce
single-latch.

## 'other' stem color

**Spec source:** setforge-live-spec.md §1.4 (~line 177) + prompt assumption
**Spec says:** The 'other' stem soft color is `#f0efe9` (near-white / grey).
**Code does:** `STEM_COLORS.other` = soft `[50,50,0]` / bright `[100,100,0]` =
**olive / yellow** (`:89`), not grey.
**Severity:** minor-divergence
**Recommendation:** Update spec. Document 'other' as yellow/olive; the grey assumption is
wrong. (Stem colors overall: drums = ORANGE, bass = BLUE, other = YELLOW/olive, vox =
GREEN.)

## Empty-slot color brightness

**Spec source:** setforge-live-spec.md §1.4 (line 128)
**Spec says:** Empty slots = dim white `[16,16,16]`.
**Code does:** `STATE_COLORS.empty = [8,8,8]` (`:102`) — half that brightness.
`[16,16,16]` is actually the modifier-idle color.
**Severity:** minor-divergence
**Recommendation:** Update spec. Note actual empty color = `[8,8,8]`.

## Control-view 'you are here' blue tint

**Spec source:** launchpad-addendum §4.4 (lines 258–260)
**Spec says:** Row 1 gets a subtle blue tint across all pads as a peripheral cue.
**Code does:** `updateControlViewColors` (`:1655–1677`) renders row 1 as a
genre-colored setlist; there is no blue-tint logic.
**Severity:** minor-divergence
**Recommendation:** Document divergence. The blue-tint cue was never implemented.

## USB reconnect triggers surface flush

**Spec source:** setforge-live-spec-multi-song-modes.md §6 (table)
**Spec says:** On USB disconnect mid-dual-song, audio continues; on reconnect the surface
flushes; state is preserved.
**Code does:** There is no reconnect listener. Recovery is per-flush programmer-enter
re-assertion (`:337–353`) plus `bar_tick`-driven repaint (`:3147–3149`) — i.e. on the
next event / bar, not "on reconnect." JS state IS preserved (untouched by the MIDI reset).
**Severity:** minor-divergence
**Recommendation:** Document divergence. Recovery is event/bar-driven; the
state-preservation and programmer-mode re-assert are real, but there is no explicit
reconnect handler.

## SOLO modifier soloes a stem

**Spec source:** setforge-live-spec.md §2.4 (line 201) vs setforge-live-spec-multi-song-modes.md (line 58)
**Spec says:** Base spec: SOLO acts on the chop (soloes a stem). Multi-song: SOLO appears
in the row-7 modifier set.
**Code does:** SOLO does **not** solo or mute any track. A double-tap on SOLO toggles
per-row mode (`:2391–2394`, `:2419–2436`); the label is misleading vs the behavior.
**Severity:** spec-was-updated
**Recommendation:** Document divergence. The multi-song spec repurposes the SOLO
double-tap as the per-row toggle; the base "solo-a-stem" semantic is superseded.

## Modifiers on row 6

**Spec source:** setforge-live-spec.md (lines 105 / 115 / 193) vs setforge-live-spec-multi-song-modes.md (line 58)
**Spec says:** Base spec: row 6 = modifiers, row 7 = bank B. Multi-song: modifiers on
row 7.
**Code does:** Code places modifiers on **row 7** (matches the multi-song layout).
**Severity:** spec-was-updated
**Recommendation:** Update spec. Use the multi-song layout (row 7) as canonical; flag the
base spec's row-6 references as stale.

## Right side buttons unused in v0

**Spec source:** launchpad-addendum §3.7 / §4.1 (lines 205, 232)
**Spec says:** The right side buttons stay unused in v0; reserved.
**Code does:** Note 89 = DUAL_SONG_TOGGLE, note 79 = DECK_SETUP; notes 69–19 are inert
(`:78`, `:2223–2274`).
**Severity:** spec-was-updated
**Recommendation:** Update spec. Superseded by the multi-song spec; document 89 =
dual-song, 79 = deck-setup, the rest inert.

## Test stack validates `src/loader/*.js` at 80% coverage

**Spec source:** setforge-live-spec.md §6.1 / §6.2
**Spec says:** The JS modules in `src/loader/*` are pure importable functions with
coverage targets (e.g. 80%).
**Code does:** The deployed device runs the concatenated monolith built from
`loader-controller.js`; the modular files are NOT deployed. The integration tests import
that reference code, not the shipped monolith. Only `loader-e2e.test.js` targets the
built device-root `loader.js`. (Caveat: node is not installed — nothing was run, no pass
can be claimed.)
**Severity:** spec-was-updated
**Recommendation:** Update spec. Treat §6.1 / §6.2 as historical; only
`loader-e2e.test.js` (plus the live-hardware Python UAT) exercise the monolith.

## punch-fx integration premise (HOLD dropped, DBL relabeled, SHIFT on side button)

**Spec source:** task premise referencing §5.5 / §5.6 (the real §5.5/§5.6 cover staging
fallback and dual-song edges, NOT punch-fx)
**Spec says:** A premise that HOLD was dropped, DBL relabeled, and SHIFT moved to a side
button as part of punch-fx integration. No actual spec describes these changes.
**Code does:** There is no punch-fx, no SHIFT side button; both HOLD and DBL are still
present. The premise's integration exists in **neither** the code **nor** any cited spec.
The real §5.5 / §5.6 cover staging fallback, which IS implemented.
**Severity:** unclear
**Recommendation:** Investigate further / treat as never-specified, never-implemented. The
real §5.5 / §5.6 (staging) is implemented; the punch-fx premise should not be documented
as a behavior.

---

## Open questions for Zak

These are unverified items from the catalog (§15) that need a human / hardware decision:

1. **Was the `DUAL_SONG_TOGGLE` ReferenceError (`:2319` / `:2326`) ever hit on hardware?**
   If the dual-song button is only ever pressed after staging, the failure branch may
   never have executed, masking the bug. (Recommend fixing regardless.)
2. **Is the file-based command poll (`/tmp/setforge_cmd.txt`, deferred Task at load,
   `:3859–3865`) still intended in production, or fully superseded by the MIDI-CC remote
   map?** Inline comments say CCs replaced it, yet `startCmdPoll` is still scheduled.
3. **Restaging unload (§5.3 / §5.7):** `onStageDeck` overwrites `staging[deck]` /
   `loadedDecks[deck]` and reloads clips into the same X/Y tracks. No explicit unload of
   the prior song nor a "held in performance view" check before unloading. Overwrite may
   functionally replace old clips, but the conditional-unload logic the spec describes is
   absent. Confirm intent.
4. **Does the 4000ms / 2000ms deferred warp-fix Task race with a rapid restage** before
   markers are read? No guard observed against overlapping `fixWarpMarkers` tasks for the
   same slot-set.
5. **Scene recall calls `restoreModifiers` AFTER setting SOLO from the view**
   (`:2770–2828`) — intended? It can re-introduce a saved `SOLO=held` that conflicts with
   the freshly-restored view.
6. **`FILTER_POSITIONS` lp/hp frequency table is dead code** (defined, never referenced).
   Was an audio filter implementation intended and dropped, or never wired?
7. **Per-row col-1 source tint is suppressed when col-1 chop is playing** (`:1908`
   precedes `:1911`), so the source indicator is invisible for a row whose chop 1 is held.
   Spec §4.4 doesn't address this; intended?
8. **`leaveProgrammerMode` defined but never called** — the device never explicitly leaves
   programmer mode on disconnect, contrary to addendum §3.2 intent. Intended?
9. **`buildPulseSysex` has no call site** — pulse appears entirely unused in the deployed
   monolith (only flash is used). Confirm before documenting pulse as a live feature.
10. **`full-vocal.test.js` and `bank-slot-mapping.test.js` import targets unconfirmed**
    (not opened) — monolith or modular?
11. **`tests/uat` assertions not exhaustively read** — whether they cover dual-song /
    staging audio routing specifically is unconfirmed.
12. **Did NOT trace** whether `executePanic`'s `stopAllClips` / `bypassFx` affect
    control-view (Grid 2) FX-target state; only view-state mutations were verified.
13. **SOLO double-tap latch timing** lives in `pressModifier`; assumed to use
    `DOUBLE_TAP_WINDOW_MS` (400ms) like other modifiers but not separately re-verified.
14. **Whether a genuinely missing file surfaces the §5.6 red-flash-and-clear behavior is
    unverified** — `onStageDeck` only red-flashes for slot STATE, not runtime
    `create_audio_clip` failure.
