# tape-loss — Phase 4 Debrief: First Successful Live Load

**Date:** 2026-04-28
**Status:** Device loads in Ableton Live 12 Beta without crashing. Console reports 7 patchcord OOR errors, 9 "device patcher has no name" warnings, 1 JS resource-load failure (with documented passthrough fallback), and ~50 "adding more than one perform routine to dsp chain" notices. Whether audio actually passes through is **not yet confirmed** — the user reported errors but did not state the audio result.

This document is a self-contained handoff intended for a fresh reviewer (e.g. claude.ai). It assumes no prior context.

---

## 1. What this project is

Boutique-pedal-style Max for Live (M4L) audio effect devices, built spec-first via an autonomous agent harness. The current device, **tape-loss**, models tape-machine artifacts (saturation, EQ, wow, flutter, dropouts, noise). It has 9 module subpatchers wired in series between `[plugin~ 2]` and `[plugout~ 2]`. The build pipeline emits `.maxpat` JSON via Python primitives in `stemforge_bridge`, then packs to `.amxd` with a Max-compatible binary header.

The repo lives at `/Users/zak/zacharysbrown/m4l-devices`. The shared bridge/verifier code lives in `~/raindog/harness/quickstarts/max-plugin/tools/`.

## 2. Trajectory before today

| Phase | Outcome | Errors |
|---|---|---|
| Phase 2.5 | First .amxd structurally built; gen~ codeboxes populated | ~120 console errors |
| Phase 3 (yesterday) | Headless Max load-verifier built; iterated DSL fixes | 7 verifier errors on `tape-loss-debug.maxpat`, all 9 modules clean standalone |
| Phase 4 (today, this debrief) | First successful Live load — no crash | New error mix; see §4 |

Phase 3 left two known categories of unresolved error in the headless verifier output:
- **4 errors** attributed to the debug-harness wrapper (a separate `[p tape-loss]` subpatcher used only for headless testing, not present in the .amxd loaded by Live).
- **3 errors** in the main patcher, hypothesized to be cosmetic warnings Live might tolerate.

## 3. Today's discovery: pitfall #25

**Symptom:** dropping the `.amxd` onto an Ableton track segfaulted Live immediately, before any boxes were created.

**Crash trace (Mach signal SIGSEGV, KERN_INVALID_ADDRESS at 0x0):**
```
0  pthread_mutex_lock + 12
1  dictionary_getkeys_ordered + 60
2  project_deserialize_searchpath + 48
3  project_deserialize + 1116
4  project_newfrompatcherdictionary + 344
5  jpatcher_new + 3884
...
9  lowload_jpatcher_frombuffer + 164
10 lowload_jpatcher_fromamxd_data + 752
```

**Root cause:** `make_patcher_skeleton` in the bridge was emitting a minimal `project: {name: "", amxdtype: 1633771873}`. Live's M4L runtime calls `project_deserialize_searchpath` unconditionally during `lowload_jpatcher_fromamxd_data`. When `project.searchpath` is missing, `dictionary_getkeys_ordered` is invoked on a NULL dict → `pthread_mutex_lock` segfault.

**Fix:** Updated `make_patcher_skeleton` to emit the canonical 19-field `project` block (lifted from Live's bundled `Max Audio Effect.amxd` template, including `"searchpath": {}`). Added new verifier `verify_project_searchpath` to `PATCHER_VERIFIERS`. Pitfall #25 is now codified.

**Why the headless verifier didn't catch it:** The verifier built in Phase 3 (pitfall #24) loads `.maxpat` files via `jpatcher_new` directly, which does NOT route through `lowload_jpatcher_fromamxd_data`. The strict project deserializer is `.amxd`-only. **This is a known limitation of the headless verifier** — it can clear `.maxpat` shape but cannot catch `.amxd`-only deserializer bugs.

**After fix:** Live no longer crashes. Build now passes 73/0 verifiers (was 63/0 — 10 new pass results from `verify_project_searchpath` × 10 patchers).

## 4. Current console output (categorized)

User pasted the following from Live's console after dropping the device:

### Category A — Patchcord out-of-range (7 errors total)

```
plugin~: patchcord outlet out of range: deleting patchcord       ×2
plugout~: patchcord inlet out of range: deleting patchcord       ×1
patcher: patchcord inlet out of range: deleting patchcord        ×2
patcher: patchcord outlet out of range: deleting patchcord       ×2
```

These appeared twice in the console (so 14 total lines). The doubled appearance suggests the device was loaded twice during the test, or the error fires on both initial load and live-DSP-rebuild.

**What we've verified about the structure:**
- `plugin~ 2` box: declares `numinlets=1, numoutlets=2` ✓ correct
- `plugout~ 2` box: declares `numinlets=2, numoutlets=0` ✓ correct
- All 4 patchcords from `plugin-in` go to outlets 0 or 1 (both within range) ✓
- All 2 patchcords to `plugout` go to inlets 0 or 1 (both within range) ✓
- All 9 subpatcher modules: outer-box `numinlets`/`numoutlets` exactly matches the count of inner `[inlet]` / `[outlet]` boxes ✓
  - tl_saturate: 4 in / 2 out
  - tl_model_eq: 4 in / 3 out
  - tl_failure: 8 in / 2 out
  - tl_wow: 4 in / 2 out
  - tl_flutter: 4 in / 2 out
  - tl_aux: 5 in / 3 out
  - tl_volume_mix: 4 in / 2 out
  - tl_dry_mix: 5 in / 2 out
  - tl_noise: 6 in / 2 out

**Mystery:** Static analysis says everything is in range, but Max-at-runtime disagrees. Hypotheses:
1. The inner `[inlet]` / `[outlet]` boxes have wrong **per-box index attributes** (the inlet's `comment` or numerical position field), even though the count is right. We haven't looked at what specific index attribute the bridge emits.
2. The build emits patchcords in `lines[]` that reference inlet/outlet indices that match Max's *box order* but not Max's *expected inlet index numbering*. Max may number subpatcher inlets by inlet-box position-on-canvas, or by some explicit `index` attribute, not by appearance order in `boxes[]`.
3. Some plugin~/plugout~ peculiarity. `[plugin~ 2]` has a left control inlet (index 0 expects messages), with audio outlets 0/1 (or 1/2?). The exact inlet/outlet numbering convention for these boxes deserves verification against a known-good M4L device.

**This is the highest-impact unsolved problem.** Patchcords being deleted means audio routing is partially broken, which likely correlates with whatever audio outcome the user is hearing.

### Category B — JS file load failure (2 errors, repeated on reload)

```
js: model_selector: ERROR loading model_eq_coefficients.json — could not open ../../data/model_eq_coefficients.json
js: model_selector: emitting passthrough coefficients to keep audio alive.
```

**Cause:** `tl_model_eq` includes a `[js model_selector.js]` object that reads model coefficients from `../../data/model_eq_coefficients.json` at runtime. The relative path is resolved against the .amxd's location, which is inside Live's project / user library — NOT the dev repo where the JSON lives.

**Mitigation today:** the JS already has a passthrough fallback (deliberate design: if the EQ coefficients can't load, the EQ becomes unity and audio still flows).

**Fix paths:**
1. Embed the JSON as a `dependency_cache` entry inside the .amxd (Max bundles it on save).
2. Inline the coefficients into the `.js` file at build time — eliminate the runtime fetch entirely. Since coefficients are static and known at build time, this is the cleanest move.
3. Use Max's `[absolutepath]` or `[strippath]` to resolve via Max's search path, then place the JSON alongside the .amxd in Live's User Library.

Recommendation: **(2) inline at build time.** Avoids the resource-resolution mess entirely. The JSON has 5 EQ presets × ~10 biquad coefficients each — small enough to inline.

### Category C — "device patcher has no name" (9 warnings)

```
device project: device patcher has no name!     ×9
```

**Cause:** Each of the 9 module subpatchers (`tl_saturate`, `tl_model_eq`, etc.) is constructed via `make_patcher_skeleton`, which (after today's fix) emits a full 19-field `project` block. But each subpatcher's `project.name` is empty — the bridge sets `name: ""` by default, and the per-module build does not override it.

**Why it's a warning, not an error:** Max tolerates a project with no name; it just complains.

**Why it's worth fixing anyway:** It's noise that hides real errors, and it suggests our bridge is doing something the canonical M4L template does *not* do. Looking at Live's bundled `Max Audio Effect.amxd` template: only the **root** patcher has a `project` block. Subpatchers have none.

**Fix paths:**
1. **Don't emit `project` on subpatchers** — make `make_patcher_skeleton` accept an `is_root: bool = True` parameter, and only emit `project` when root. Matches reference exactly.
2. Set `project.name` on each subpatcher to its module name (cheap, but doesn't match canonical M4L shape).

Recommendation: **(1)**. The reference M4L template is the source of truth.

### Category D — DSP perform-routine warnings (~50)

```
slide~:   adding more than one perform routine to dsp chain is not recommended    ×3
plugin~:  ...                                                                      ×1
gen~:     ...                                                                      ×4–5
biquad~:  ...                                                                      ×12
selector~:...                                                                      ×3
tapin~/tapout~/+~/*~: ...                                                          ×many
receive~/send~/plugout~: ...                                                       ×each
```

**What it means:** Max emits this when the same audio object's `dsp_perform` method gets registered into the DSP graph multiple times in a single audio cycle. It's a **warning**, not an error — Max still runs both perform routines, but it's a hint that the patch may be running redundant DSP.

**Common causes in M4L:**
1. Multiple `[plugin~]` / `[plugout~]` instances in nested patchers (only the root pair should exist).
2. Audio objects wired into two separate signal chains that both feed `[plugout~]`.
3. A subpatcher loaded twice into the DSP graph — sometimes happens when M4L re-evaluates DSP on parameter change.
4. `[gen~]` instances with overlapping audio domains.

**Most likely cause for tape-loss:** the device has many DSP objects in series (it's a big signal chain), and the **dry-mix path** runs in parallel to the main chain (we use `[tapin~]`/`[tapout~]` to delay-match a dry signal pulled from `plugin~` outputs through to `tl_dry_mix`). If the dry path's `tapin~` is reading the same `plugin~` outlet that the main chain's `tl_saturate` is also reading, that's two consumers — and Max may be reporting that as a perform-routine duplication.

The total count (~50) is high but plausible for a 9-module chain plus dry path. Could also be partly from the doubled load.

**Risk:** likely benign (warnings, not errors). Worth investigating only after categories A and B are resolved.

### Category E — Audio result

**Unknown.** The user reported the console output but did not say whether audio is passing through, silent, distorted, or whether the knobs do anything. This is the single most important missing data point.

## 5. What we still need to figure out

| # | Question | Why it matters | How to investigate |
|---|---|---|---|
| 1 | Is audio passing through at all? | Determines whether category-A errors are functional or cosmetic. | User test: drop on track, play clip, listen for output. |
| 2 | What inlet/outlet index attributes does our bridge emit on `[inlet]`/`[outlet]` boxes inside subpatchers? | If these don't carry an explicit `index` attribute matching Max's expectation, that's the cause of the "patcher: patchcord OOR" cluster (4 of the 7 errors). | Diff our emitted `inlet_box`/`outlet_box` JSON against a reference subpatcher saved in Max IDE. |
| 3 | What is the canonical inlet/outlet numbering convention for `[plugin~ 2]` and `[plugout~ 2]`? | If audio outlets are 1-indexed at Max's runtime layer (despite outlet=0 being the leftmost in JSON), our patchcords may be off-by-one. | Save a 4-channel `[plugin~]` test patch by hand, inspect its lines[]. |
| 4 | Does Live actually load `tape-loss.amxd` once or twice on track-drop? | The doubled console output may indicate two load passes (M4L sometimes reloads on first DSP enable). If so, the error counts are halved, not doubled. | Count load events in Live's audit / look at console timing. |
| 5 | Will the "perform routine" warnings cause audible glitches? | Determines priority. | Listen for clicks / artifacts during play; A/B against a single-module device. |
| 6 | Is the JS resource path the actual EQ-silence cause, or are biquad coefficients also wrong? | The fallback claims "passthrough coefficients to keep audio alive" — but the user's previous-session feedback noted EQ behavior. | Inline coefficients (fix path B-2) and re-test. |

## 6. The headless-verifier limitation we should document

Pitfall #24 (the headless Max load-verifier) was the unlock that took us from ~120 errors to 7. But it has a **documented gap**: it loads `.maxpat` files via `jpatcher_new` directly, which bypasses Live's M4L-specific `lowload_jpatcher_fromamxd_data` path. Pitfall #25 (project.searchpath required) only manifests through that M4L-specific path.

**Implication:** The verifier provides a fast inner loop for catching `.maxpat`-shape bugs but cannot catch `.amxd`-only deserializer bugs. A complete iteration loop needs an **`.amxd`-loader verifier** in addition — something that exercises Live's actual loading path. Options:
- Headless Live launch with a known project that triggers .amxd load (probably impractical).
- A Max script that calls `lowload_jpatcher_fromamxd_data` via `[mxj]` or another internal binding.
- Just keep the user-in-the-loop drop-on-track test and accept the latency.

This is a Phase 5 / future-work item and should NOT block tape-loss shipping.

## 7. Recommended next moves (ordered by impact)

1. **Get the audio result** from the user (5 seconds: "do you hear anything? do the knobs do anything?"). This dominates everything below.
2. **Resolve category A** (patchcord OOR) by diffing our emitted subpatcher JSON against a hand-saved reference. The 4 "patcher: ..." errors are likely a single class of bug in `inlet_box` / `outlet_box`. The 3 plugin~/plugout~ errors are likely a separate single class.
3. **Inline the EQ coefficients** at build time (category B). Removes a load-order failure, eliminates the `data/` runtime dependency.
4. **Make `make_patcher_skeleton` is_root-aware** (category C). Cleans 9 warnings; aligns with canonical reference.
5. Defer category D until D-warnings show up after A/B/C are clean. They may resolve on their own if a load-order or duplicate-instantiation bug was their root cause.
6. **Document pitfall #25 formally** in the harness specs (`~/raindog/harness/docs/product-specs/pitfall-25-project-searchpath.md`) once we're confident the fix is complete.

## 8. State pointers for the reviewer

- **Repo:** `/Users/zak/zacharysbrown/m4l-devices`
- **Phase 3 checkpoint (full trajectory):** `docs/exec-plans/active/tape-loss-phase1-checkpoint.md` (Phase 3 section starts at line 319)
- **Build script:** `build/build_tape_loss.py` — deterministic, same-input → same .amxd sha
- **Bridge:** `~/raindog/harness/quickstarts/max-plugin/tools/stemforge_bridge/patcher.py`
- **Verifiers:** `~/raindog/harness/quickstarts/max-plugin/tools/forge_device/verifiers.py`
- **Headless load-verifier:** `tools/verify_max_load.py` (local copy) and `~/raindog/harness/quickstarts/max-plugin/tools/forge_device/load_verifier.py` (promoted)
- **Crash dump from this session:** `dump` (in repo root) — shows the `project_deserialize_searchpath` segfault that pitfall #25 fixes
- **Today's commits:** none yet (uncommitted: edited `~/raindog/harness/`'s patcher.py + verifiers.py; rebuilt .amxd; new memory note `project_pitfall_25_searchpath.md`)
- **Latest .amxd sha256:** `0e160a667ebc2ccfd594bbb861250c70704740d6aa116baf1271b5e39cafb474`

---

*Authored 2026-04-28, end of Phase 4 first-load session. Next step: get audio-result data point from user, then attack category A (patchcord OOR) with a hand-saved reference subpatcher diff.*
