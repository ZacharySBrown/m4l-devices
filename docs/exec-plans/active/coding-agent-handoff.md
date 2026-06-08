# tape-loss — Phase 5 Coding-Agent Handoff

**Author:** Reviewer (claude.ai), 2026-04-28
**Audience:** the coding agent driving the next implementation pass
**Status of investigation:** External research complete. Root cause of category A is now strongly hypothesized (was unknown in the Phase 4 debrief). All other categories have concrete prescribed fixes. Audio-result data point obtained.

---

## 0. New data point since Phase 4

User dropped `tape-loss.amxd` on a Live track and got: **silence on the main path, hiss when one knob is turned, knobs react but don't do much.**

This rules out "category A is cosmetic." Audio is not flowing from `plugin~ 2` → modules → `plugout~ 2`. The hiss-on-knob is `tl_noise` — the only module whose output reaches `plugout~` doesn't depend on the broken main-chain cords (it generates its own signal). So `tl_noise`'s outlets and at least one path to `plugout~` are intact, but the `plugin~ → tl_saturate → ... → plugout~` chain is severed by the deleted patchcords.

This means category A (patchcord OOR, deleting cords) is THE blocker. Everything else is secondary.

---

## 1. Root cause hypothesis for category A: missing `index` attribute on inlet/outlet boxes

The Phase 4 debrief listed three hypotheses for the patchcord OOR errors. Research strongly supports hypothesis #1, and rules out #3.

### What the Cycling '74 docs say

- Subpatcher inlets/outlets are numbered "**arrayed spatially in relation to how they are in the subpatch (e.g. the leftmost inlet object will correspond to the leftmost inlet on the patcher)**" (Max 5 Tutorial 14: Encapsulation). In other words, X-coordinate of the `[inlet]` / `[outlet]` box determines the port number on the parent.
- For `[plugin~ 2]` and `[plugout~ 2]`: plain stereo, audio outlets/inlets at indices 0 (left) and 1 (right). No control inlet/outlet at index 0 in the audio-effect case. M4L is hard-stereo regardless of the `2` argument behavior.

### What real-world `.maxpat` files show

Surveying inlet boxes saved by Max itself in real patches (Hetrick `ht.LFO.maxpat`, Cella `modal_synth_module2.maxpat`, and others), modern Max 8/9 saves include an **explicit `index` attribute** on `[inlet]` and `[outlet]` boxes:

```json
{
  "box": {
    "comment": "Phase",
    "id": "obj-112",
    "index": 0,
    "maxclass": "inlet",
    "numinlets": 0,
    "numoutlets": 1,
    "outlettype": [ "" ],
    "patching_rect": [ 1024.0, 30.0, 30.0, 30.0 ]
  }
}
```

Older patches (Max 6/7-era) often omit `index` and rely purely on `patching_rect[0]` X-position. **Both forms exist in the wild, but modern Max writes `index` explicitly, and the safest behavior is to emit both.**

### Why this matches the error pattern

The Phase 4 debrief reports:
- 4 errors at the `patcher:` (subpatcher boundary) layer
- 3 errors at the `plugin~ / plugout~` layer
- The bridge declares correct `numinlets`/`numoutlets` on every subpatcher box; the *count* is right
- Static analysis of `lines[]` shows every cord referencing in-range port numbers

If our `[inlet]` / `[outlet]` boxes have no `index` attribute AND identical-or-near-identical `patching_rect[0]` X-coords (very likely, given a deterministic build script that probably stacks boxes at identical X), Max can't tell which inlet is index 0 vs index 1 vs index 2. It assigns indices arbitrarily (or to the first one and rejects the rest), so cords referencing port 1+ get classified as out-of-range and deleted.

The `plugin~ / plugout~` errors are then a separate but related issue: those root-level OOR errors mean cords from `plugin~` outlet 1 (or to `plugout~` inlet 1) are also being rejected. This is unlikely to be a `plugin~`-specific quirk — the docs are unambiguous that `plugin~ 2` has audio outlets 0 and 1. More likely: those root-level cords reference the same broken subpatcher port indices (i.e., they fail because the *destination* subpatcher's inlet 1 is not resolving, not because `plugin~`'s outlet is wrong).

**The 4 + 3 split makes sense if the root cause is shared.** Once the subpatcher index issue is fixed, both clusters should resolve.

### Confidence

Strong but not 100%. The remaining uncertainty is:

- It's possible the bridge does set sensible `patching_rect[0]` values and the issue is purely the missing `index` attribute, in which case adding `index` alone fixes it.
- It's possible `patching_rect[0]` values are also bad (all identical, or not in left-to-right order matching the intended port numbering), in which case `index` alone wouldn't fix it without also fixing the rects.

**Both should be fixed together for safety** (see step 2A below).

---

## 2. Prescribed fixes, in priority order

### Step 2A — FIX CATEGORY A (the blocker)

**Where:** `~/raindog/harness/quickstarts/max-plugin/tools/stemforge_bridge/patcher.py`, in whatever function emits `[inlet]` / `[outlet]` boxes for subpatchers (look for `make_inlet_box`, `make_outlet_box`, or wherever `"maxclass": "inlet"` / `"outlet"` strings are written).

**Two changes, both required:**

1. **Add an explicit `index` attribute** to every `[inlet]` and `[outlet]` box. Indexing is per-direction: inlets are 0..(N-1), outlets are 0..(M-1), assigned in the intended port order.

2. **Set `patching_rect[0]` to monotonically increasing X-coordinates** matching the intended index order. A safe convention: `x = base_x + index * 35.0`. The `[inlet]`/`[outlet]` box width is conventionally 25–30px, so 35px spacing avoids overlap. Y-coordinate: inlets near the top of the subpatcher canvas (e.g. `y = 30.0`), outlets near the bottom (e.g. `y = 400.0`).

**Reference inlet box shape (the bridge should emit this exactly):**

```json
{
  "box": {
    "comment": "",
    "id": "obj-N",
    "index": 0,
    "maxclass": "inlet",
    "numinlets": 0,
    "numoutlets": 1,
    "outlettype": [ "signal" ],
    "patching_rect": [ 30.0, 30.0, 30.0, 30.0 ]
  }
}
```

**Reference outlet box shape:**

```json
{
  "box": {
    "comment": "",
    "id": "obj-M",
    "index": 0,
    "maxclass": "outlet",
    "numinlets": 1,
    "numoutlets": 0,
    "patching_rect": [ 30.0, 400.0, 30.0, 30.0 ]
  }
}
```

**Notes:**
- `outlettype` for an inlet that carries audio should be `["signal"]`; for a non-signal/messaging inlet, `[""]`. If unsure, `["signal"]` is correct for tape-loss because every subpatcher inlet receives audio or audio-rate parameter signals.
- `comment` should always be present (even if empty string) — Max sometimes warns when it's missing.
- The `id` must remain unique within the patcher and must match what `lines[]` references.

### Step 2B — Inline EQ coefficients (category B)

**Where:** the build pipeline. Find where `tl_model_eq` is generated and where `model_eq_coefficients.json` is read by `model_selector.js`.

**What:** at build time, read `model_eq_coefficients.json` and inline the entire JSON object as a JS literal directly inside `model_selector.js`, replacing the runtime `open(...)` / fetch call. The 5 EQ presets × ~10 biquad coefs each is small (a few KB) — inlining is cheap and removes an entire category of failure mode.

**Why this matters now:** even after step 2A, if EQ is silent-fallback (passthrough), the user won't hear the Generation Loss Mk2's "Generations" tonal character. The pedal's signature lives in this stage. Confirming audio passes through the chain AND sounds like a tape machine requires the EQ working.

**Validation after this fix:** the `js: model_selector: ERROR loading...` message should disappear from console. The `js: model_selector: emitting passthrough coefficients...` message should also disappear.

### Step 2C — Make `make_patcher_skeleton` is_root-aware (category C)

**Where:** `make_patcher_skeleton` in `patcher.py`.

**What:** add `is_root: bool = True` parameter. When `is_root=False`, skip emitting the `project` block entirely (subpatcher patcher dicts have no `project`). When `is_root=True`, emit the full canonical 19-field block including `searchpath: {}` (already done in pitfall #25 fix).

**Then update callers:** every per-module subpatcher build should pass `is_root=False`. Only the top-level device patcher passes `is_root=True`.

**Validation:** the 9× `device project: device patcher has no name!` warnings disappear.

### Step 2D — Defer category D (DSP perform-routine warnings)

After 2A/B/C land, re-test and look at the new console. If the ~50 perform-routine warnings persist, investigate `tl_model_eq` first — `biquad~ ×12` is suspicious for an EQ that should be switching between presets via `[selector~]`, not running all 5 presets in parallel. If that's the cause, restructure to use a single biquad chain whose coefficients update on preset change.

If counts drop substantially (e.g. <15) after 2A/B/C, treat as benign and ship.

---

## 3. Verification steps after each fix

The Phase 4 debrief notes the headless verifier (`tools/verify_max_load.py`) cannot catch `.amxd`-only deserializer bugs. That's still true. But it CAN catch shape regressions in the `.maxpat` JSON, and that's where step 2A's bug lives. Recommended verifier additions:

### 3.1 Add `verify_inlet_outlet_indices` to `PATCHER_VERIFIERS`

For each patcher in the device:
1. Collect all `[inlet]` boxes; collect all `[outlet]` boxes.
2. For each list, assert that:
   - Every box has an `index` field that is a non-negative integer.
   - The set of `index` values is exactly `{0, 1, ..., N-1}` with no gaps and no duplicates.
   - When boxes are sorted by `index`, the `patching_rect[0]` values are strictly monotonically increasing (left-to-right ordering matches the index order).
3. Cross-check `lines[]`: for every patchcord whose source/destination is an `[inlet]` / `[outlet]` box's parent subpatcher, the referenced port index must be `< N`.

This verifier would have caught the bug pre-build.

### 3.2 Manual diff against a known-good reference

Before committing the bridge fix, save a hand-built 3-inlet/2-outlet test subpatcher in Max IDE, dump its `.maxpat` JSON, and diff against what the bridge emits for the same shape. Any structural difference is suspect. (This is also a good regression artifact to keep in the repo.)

### 3.3 Audio-thru smoke test

After dropping the rebuilt `.amxd` on a track, the test sequence is:
1. Console clean of patchcord OOR? (Category A check.)
2. Play a clip — is dry signal audible? If yes, signal flow is intact.
3. Bypass `tl_failure` (or set its dropout/glitch params to neutral) — confirm clean audio passes through.
4. Engage modules one at a time, confirm each adds the expected character.
5. Compare A/B against the actual Generation Loss Mk2 hardware on a clean signal — same source, same level, switch in/out.

---

## 4. The plugin~/plugout~ category-A errors

These should resolve as a side effect of step 2A. If they don't, the bridge's emission of the `plugin~ 2` / `plugout~ 2` boxes themselves needs auditing. Specifically:

- `plugin~ 2`: should declare `numinlets=1`, `numoutlets=2`. The `1` numinlet is a control/messages inlet, not an audio inlet — but its index in the box is 0. Audio outlets are indices 0 (left) and 1 (right). M4L is fundamentally stereo regardless of the `2` argument.
- `plugout~ 2`: should declare `numinlets=2`, `numoutlets=0`. Audio inlets are 0 (left) and 1 (right).

If the bridge currently emits `plugin~ 2` with `numinlets=1, numoutlets=2`, that's correct. If the patchcords from `plugin~` reference outlet 0 and outlet 1, that's also correct. So if these errors persist after 2A, check whether the bridge confused `plugin~ 2` with `plugin~ @chans 2` (different syntax). Just `plugin~ 2` is right.

---

## 5. Pitfall #26 to codify after this lands

Once 2A is verified:

**Pitfall #26: subpatcher inlets/outlets need explicit `index` attribute AND monotonic patching_rect X-coords.**

Without `index`, Max falls back to position-based ordering, which fails when X-coords are not strictly increasing left-to-right matching intended port numbering. Symptom: `patcher: patchcord [in|out]let out of range` errors at runtime, despite `numinlets` / `numoutlets` declarations being correct and `lines[]` references being within declared range. The headless `.maxpat` verifier as currently written does not catch this because Max's position-based fallback is permissive enough to load the patcher; the runtime DSP-graph build is where it fails.

**Documentation location:** `~/raindog/harness/docs/product-specs/pitfall-26-inlet-outlet-indices.md`.

---

## 6. Orthogonal concern flagged for future work

The Phase 4 debrief says the headless verifier can't catch `.amxd`-only deserializer bugs (pitfall #25 surfaced only at Live load). Pitfall #26 may also evade the current verifier even with `verify_inlet_outlet_indices` added (because Max's `jpatcher_new` is more permissive than the M4L runtime DSP-graph build). The proper long-term solution is a verifier that exercises Max's actual DSP-chain build path, not just structural load.

Options:
- A Max script (loaded via `mxj` or the JS object) that calls `loadbang`-equivalent and inspects the DSP graph for OOR-deleted cords. Would need to be invoked from a headless Max launch.
- Continue with user-in-the-loop drop-on-track testing for the final-mile verification.

This is a Phase 5+ item. Don't block tape-loss shipping on it.

---

## 7. Summary for the coding agent

**Do, in this order:**

1. **Fix `make_inlet_box` / `make_outlet_box` (or equivalent) in `patcher.py`** to emit `index` attribute and monotonic `patching_rect[0]` X-coords. Add `verify_inlet_outlet_indices` to `PATCHER_VERIFIERS`.
2. **Inline EQ coefficients** in `model_selector.js` at build time. Remove the `data/model_eq_coefficients.json` runtime fetch.
3. **Add `is_root` parameter to `make_patcher_skeleton`**, pass `False` for all subpatcher builds, only emit `project` block at root.
4. **Rebuild `tape-loss.amxd`**, drop on Live track, get the audio result from user.
5. If audio is clean: profile category D warnings, fix only if count > 15 or audio glitches present.
6. If audio is still broken: capture new console output, check whether category A errors persisted (means step 1 was incomplete) or new errors emerged.
7. **Document pitfall #26** in `~/raindog/harness/docs/product-specs/pitfall-26-inlet-outlet-indices.md`.
8. **Commit everything** — currently uncommitted changes from Phase 4 are still sitting in the working tree per the debrief.

**Do not:**
- Ship without re-testing audio-thru on a real Live track.
- Investigate category D before A/B/C land — its likely root cause is upstream.
- Assume `plugin~ 2` has a control outlet at index 0. It doesn't, in the audio-effect case. Audio outlets are 0 and 1.

**Expected end state:** clean console (or near-clean — D warnings may persist), audio passes through tape-loss, dry signal audible with bypass-style settings, full Generation Loss Mk2 character audible with engaged modules. `.amxd` sha256 will change from `0e160a667...`.

---

*Phase 5 priorities derived from Phase 4 debrief + external Cycling '74 / Ableton documentation research + survey of real-world `.maxpat` JSON shapes (Hetrick, Cella, Stine, others). Strong-confidence root-cause hypothesis for category A; high-confidence prescribed fixes for B and C; deferred D pending re-test.*