# tape-loss — Phase 1 Checkpoint

**Date:** 2026-04-26
**Status:** Phase 1 (DSP design) complete. Phase 2 (pedal-engineer patch generation) blocked on a 9-item reconciliation pass.
**Spec hash:** `5f6a62295b7e2f8627c2bc6a8b5410d0178a9beee73e0e0a37585d8394aadeb9`

---

## At-a-glance metrics

| Metric | Value |
|---|---|
| Modules designed | **9 / 9** (`tl_saturate`, `tl_model_eq`, `tl_failure`, `tl_wow`, `tl_flutter`, `tl_aux`, `tl_volume_mix`, `tl_dry_mix`, `tl_noise`) |
| Design docs | 9 (~276 KB total) at `docs/design-docs/dsp/` |
| Numpy reference impls | 9 (~185 KB total) at `dsp/reference/` |
| Coefficient JSONs | 2 (`model_eq_coefficients.json`, `tl_saturate_coefficients.json`) at `data/` |
| Sanity-render fixtures | 72 WAVs (~43 MB) at `dsp/reference/fixtures/` |
| Audit ndjson events | 123 lines at `docs/exec-plans/active/tape-loss-audit.ndjson` |
| Subagent runs | 9 `pedal-dsp` instances (1 sequential first, then 8 parallel) |
| User-audit fixture-viewer hits | Live at `http://localhost:8000/docs/fixtures-viewer/` |

---

## What was built

### Per-module DSP highlights

| Module | DSP kind | Key choice | Status |
|---|---|---|---|
| `tl_saturate` | waveshaper | Memoryless asymmetric tanh + drive-gated even-harmonic multiplier; **2× oversampling** (31-tap halfband Kaiser-β=8) bracketed by NAB/IEC pre/de-emphasis shelves; J-A swap path documented for v1 | Audit ✓ "looks good" |
| `tl_model_eq` | biquad_chain | All 12 profiles taken verbatim from prose spec (CPR-3300 gens / Portamax / CAM-8 / Dictatron / FISHY 60 / MS-Walker / AMU-2 / M-PEX); 12 ms equal-power crossfade between parallel chains; runtime-recomputed coefficients per SR | Audit ✓ "sound pretty good" |
| `tl_failure` | custom multi-engine | Poisson event scheduler with quadratic/cubic rate tapers across drop / snag / crinkle / micro-flutter; `SeedSequence.spawn(2)` for L/R decorrelation under SPREAD | **Needs round-2 calibration** |
| `tl_wow` | variable_delay | Filtered-noise LFO (0.5+0.7 Hz, double 1-pole LP); 4-point Hermite cubic interp; calibrated to ±13.1c at noon, ±69.8c at max | Audit ✓ "AWESOME" — locked |
| `tl_flutter` | variable_delay + AM | Two summed filtered-noise bands per path; 99th-percentile-peak normalization; 4-point Lagrange interp; classic_mode = AM-bypass-only | **Needs taper retune at f=0.5** |
| `tl_aux` | custom (3 modes) | STOP = (1-e)^2.5 read-rate × √(1-e) gain comp; FILTER = TPT-SVF log sweep 18kHz→200Hz; **FAIL = sidechain control** (3rd outlet to tl_failure) | Audit ✓ — STOP loved; spawned slowdown-styles backlog |
| `tl_volume_mix` | custom | Volume scale + (L+R)/2 MISO; one-pole zipper smoother (τ=10 ms) | Audit ✓ — blurbs improved post-audit |
| `tl_dry_mix` | custom | NONE/SMALL=-8dB/UNITY; 10 ms Hann mode crossfade; **30 ms pre-WOW dry-tap latency requirement** for engineer | **Fixture regen needed** (wet ≈ dry currently) |
| `tl_noise` | custom | Voss-McCartney pink noise (50Hz HPF / 12kHz LPF); bipolar VCR↔hum mech crossfade with hard silent center at 0.5; 60Hz hum + 6-harmonic stack with half-wave-rectified PSU character | Audit ✓ "sounds good!!!" — locked |

### Tooling deliverables

- **`tools/render_fixtures.py`** — single-file generator. Walks `dsp/reference/fixtures/`, groups by module in signal-chain order, pairs dry inputs with outputs, emits static HTML with `<audio>` controls + per-fixture "what to listen for" blurbs. 72/72 fixtures blurbed. Re-run any time fixtures change.
- **Fixture viewer site** at `docs/fixtures-viewer/index.html`. Sidebar nav, per-module preamble, dry-input cards highlighted above output groups, bold-red callouts inside blurbs flag specific verifications.
- **Server invocation:** `python3 -m http.server 8000` from repo root → `http://localhost:8000/docs/fixtures-viewer/`. (Server dies on laptop sleep — relaunch from repo root.)

---

## Cross-module contracts (emerged from parallel design — none in original spec)

These are inter-module APIs the agents introduced independently. None blocks Phase 1, all need engineer-phase wiring. Reconcile before Phase 2.

| # | Contract | Origin | Receiver | Required action |
|---|---|---|---|---|
| 1 | `failure_override` (4th inlet, default 0) | `tl_aux` FAIL mode emits [0,1] | `tl_failure` | Add inlet to tl_failure; non-breaking. Mapping: `override = knob + e·(1-knob)`. |
| 2 | AMU-2 ±0.3c pitch-drift floor | `tl_model_eq` profile 11 marked it as out-of-scope | `tl_wow` | Per-profile pitch-floor hook; tl_wow currently has no such API. |
| 3 | AUX FILTER ramp authority | `tl_aux` recommends owning the ramp | `tl_model_eq` | tl_model_eq exposes only the boolean; tl_aux owns timing. Trivial; just document. |
| 4 | Shared `tapin~` buffer | `tl_flutter` references tl_wow's buffer per spec | `tl_wow` ↔ `tl_flutter` | Engineer must wire single shared buffer; reference cascades the modules. |
| 5 | Pre/de-emphasis ownership | `tl_saturate` claims NAB/IEC shelves bracket the shaper | `tl_model_eq` | Need to confirm tl_model_eq doesn't double-EQ. Likely fine (different curves) but spot-check. |

---

## Spec divergences (need user sign-off)

| # | Divergence | Module | Justification | Status |
|---|---|---|---|---|
| 1 | `saturate=0` is a true short-circuit (bit-identical to dry); strict spec would still run drive=1 through chain | `tl_saturate` | Cleaner; pitfall-friendly | Pending |
| 2 | Wow base delay = **25 ms** (spec says 5 ms) | `tl_wow` | Required headroom for A_max=6 ms peak excursion; bypass at wow=0 preserves passthrough | Pending |
| 3 | Flutter `classic_mode` = AM-bypass-only | `tl_flutter` | One-line spec; agent's interpretation | Pending |

---

## Spec interpretations agents had to make (no escalation)

These are smaller calls the agents made and documented in tradeoff logs. Listed for completeness:

- `tl_dry_mix` SMALL = **-8 dB** (forum consensus over spec's -12 dB / 25%). Single-constant override exists.
- `tl_aux` STOP curve = `(1-e)^2.5` exponent (matches spec's `pow(linear, 2.5)`).
- `tl_aux` FILTER = TPT-SVF, not RBJ biquad (stable under fast time-varying cutoff).
- `tl_noise` pink noise via Voss-McCartney; HPF/LPF at 50 Hz / 12 kHz (deliberate diverge from spec sketch's 2 kHz HPF — spec sketch was wrong-shaped).
- `tl_noise` mains hum default = **60 Hz** (NA), via flippable constant.
- `tl_noise` mechanical_level bipolar with **hard silent center at 0.5**.
- `tl_failure` saw `SeedSequence.spawn(2)` for SPREAD instead of seed/seed+1 (PCG64 with adjacent seeds gives near-correlated streams; spawn does proper hashing).
- `tl_failure` short-circuits crinkle path at `failure=0` for hash stability — Max patch should NOT match this byte-for-byte at `failure=0, crinkle_level>0`.

---

## User audit feedback (2026-04-26)

| Module | Verdict | Action |
|---|---|---|
| `tl_saturate` | "Look good" | Locked |
| `tl_model_eq` | "Sound pretty good" | Locked |
| `tl_failure` | **Crackle still too prominent; dropouts can be MORE pronounced; pitch effects should go HEAVY; failure=1.0 should be 'GO CRAZY'** | Round-2 calibration queued |
| `tl_wow` | "AWESOME" | Locked |
| `tl_flutter` | Sounds great BUT "almost non-existent on the chord at f=0.5" | Taper retune queued |
| `tl_aux` | Works as expected, "love" the STOP demo | Locked + slowdown-styles backlog item |
| `tl_volume_mix` | "Don't understand what I'm looking for"; smooth MISO toggle confirmed working | Blurbs improved post-audit (math → directive) |
| `tl_dry_mix` | "Wet signal is exactly the same as dry"; only obvious phasing/chorus audible | Fixture regen queued (use real tl_wow output as wet probe) |
| `tl_noise` | "Sounds good!!!" | Locked |

Captured as project memory: [`project_tape_loss_character_preferences.md`](../../../.claude/projects/-Users-zak-zacharysbrown-m4l-devices/memory/project_tape_loss_character_preferences.md) (path is in `~/.claude` — not in repo, but referenced here for context).

---

## Backlog (deferred; not blocking)

- **IR captures** — full Phase 5 IR-capture session deferred to a post-v0 extension. Base device ships on synthetic DSP only.
- **Slowdown-style variants** — six tape-format STOP variants (cassette / reel-to-reel / VHS / 8mm / dictaphone / microcassette) with proposed `aux_stop_style` selector under hidden options. See [`project_slowdown_modes_backlog.md`](../../../.claude/projects/-Users-zak-zacharysbrown-m4l-devices/memory/project_slowdown_modes_backlog.md).
- **Fixture A/B renderer formalization** — current prototype works; should become a standard `forge-device` deliverable when next pedal starts.
- **Harness `vst-plugin` quickstart** — proposal lodged at `~/raindog/harness/docs/product-specs/vst-plugin-quickstart-proposal.md`. JUCE-first investigation, then design before build.

---

## Harness evolution observations (for code-as-harness analysis)

These are process-level lessons that should evolve the harness itself, per the CLAUDE.md directive ("New pitfalls discovered during development MUST get a verifier added"):

1. **Cross-module contracts emerge under parallel design.** With 8 agents working concurrently in isolated module scopes, 5 distinct cross-module APIs emerged (failure_override, AMU-2 pitch hook, FILTER ramp auth, shared tapin~, pre/de-emphasis ownership). The harness's spec DSL has no `module_interfaces:` field; agents documented contracts inside design docs, requiring a manual reconciliation pass at Phase 1→2 boundary. **Proposal:** add `module_interfaces:` to the pedal schema OR add an explicit "Phase 1.5 — Reconciliation" step to forge-device's plan generator.
2. **Parallel `pedal-dsp` dispatch worked cleanly.** 8 simultaneous agents, one sequential first. No file-collision (each owned a module dir + appended-only audit). Each used a fresh `run_id`. **Proposal:** formalize parallel-dispatch as a first-class forge-device mode for any pedal with ≥4 independent DSP modules.
3. **Subjective-character feedback is irreducibly human.** All 9 modules passed numeric verification; 3 modules drew character feedback that no automated test caught (failure crackle prominence, flutter taper at noon, dry-mix fixture construction). The manual-step budget (~30s/build) covers go/no-go but not tuning. **Proposal:** keep the fixture A/B viewer as a permanent harness deliverable; consider a "calibration round" budget separate from manual steps.
4. **Fixture construction itself can hide issues.** `tl_dry_mix`'s wet probe was the dry signal cosmetically modified — it didn't actually exercise the module's purpose. **Proposal:** add a verifier that diffs the wet probe against the dry probe; if they're too similar (cosine > 0.99 or so), warn that the demo will be uninformative.
5. **Per-fixture blurbs need to be directive, not descriptive.** First-pass blurbs described the math being verified; user couldn't tell what to listen for on `tl_volume_mix`. Rewriting them as "should sound like X; bug if Y" instantly closed the gap. **Proposal:** the renderer's blurb template should require a "what to listen for" line as a separate field, not free-form prose.
6. **Spec gaps surface most loudly in event-driven / multi-engine modules.** `tl_failure` was the hardest design (spec gave behavior targets, not implementation), and it's the one needing round-2 calibration. The hard-DSP modules (saturate, model_eq) had clearer specs and passed first try. **Proposal:** spec template should require a `calibration_targets:` field for any `kind: custom` module — explicit ear-test acceptance criteria.

These observations should be considered for inclusion in the harness's pitfall catalog and/or the `pedal-architect` persona's checklist.

---

## Next session entry point

When resuming, the immediate-next list:

**Calibration / fixture (3 items, do these before reconciliation):**
1. `tl_failure` round-2 calibration (less crackle, deeper/longer dropouts, heavier pitch, GO CRAZY at 1.0)
2. `tl_flutter` taper retune (clearly audible at f=0.5 on chord textures)
3. `tl_dry_mix` fixture regen (wet probe via real tl_wow(0.5) output)

**Reconciliation pass (5 cross-module + 3 spec-divergence items):** see tables above.

**Then:** Phase 1.5 reconciliation summary → greenlight Phase 2 (pedal-engineer dispatch).

To resume the audit:
```bash
cd /Users/zak/zacharysbrown/m4l-devices
python3 -m http.server 8000  # then open http://localhost:8000/docs/fixtures-viewer/
```

---

## Audit-trail pointer

Full ndjson at [`docs/exec-plans/active/tape-loss-audit.ndjson`](tape-loss-audit.ndjson) — 123 events covering every artifact's sha256, every module's start/complete, every manual-step requirement. Regenerate summary with:

```bash
PYTHONPATH=$HARNESS_TOOLS python3 -m forge_device summary docs/exec-plans/active/tape-loss-audit.ndjson
```

---

*Checkpoint generated 2026-04-26. To extend: append to this file rather than replacing — keeps the trajectory legible for future evolution analysis.*

---

# tape-loss — Phase 2 / 2.5 Checkpoint

**Date:** 2026-04-27
**Status:** `.amxd` structurally and functionally complete. Awaiting manual smoke tests in Max IDE + Ableton (~40 s of human time) before Phase 5 release.
**Spec hash (unchanged):** `5f6a62295b7e2f8627c2bc6a8b5410d0178a9beee73e0e0a37585d8394aadeb9`
**Final `.amxd` sha256:** `a5ed9d6f5223d22fce67b108499858b85724e9238866291cdca0e590db67ed74`
**Repo commit:** `bff7716` (entire build snapshot)

---

## Phase ledger (Phase 2 → Phase 2.5)

| Step | Run id | When (UTC) | Outcome |
|---|---|---|---|
| Phase 2 — engineer dispatch | `1777295240-engineer-phase2` | 2026-04-27 13:07 | 9 module `.maxpat` + main + debug + packed `.amxd`. **gen~ codeboxes were stubs.** sha `d992777f…`, 117 KB. 63/0 verifiers (structural). |
| Harness — bridge extension | `1777296439-harness-bridge-extension` | 2026-04-27 13:27 | `gen_codebox` primitive + 5 bonus primitives (`subpatcher_box`, `inlet_box`, `outlet_box`, `newobj`, `comment_box`) promoted into `stemforge_bridge.patcher`. 14 tests passed, backward-compat verified. Addresses pitfall #22. |
| Phase 2.5 — gen DSL authoring | (offline; 6 module-agent runs) | 2026-04-27 13:30–13:42 | 6 `.gendsp` source files written, 3,430 lines total: `tl_saturate` (563), `tl_wow` (287), `tl_failure` (1,035), `tl_flutter` (470), `tl_aux` (374), `tl_noise` (701). |
| Phase 2.5 — JS companion | (same window) | 2026-04-27 ~13:40 | `model_selector.js` 339 lines / 13,305 B. Loads `data/model_eq_coefficients.json`, emits `setcoeff` per profile, gates `pitch_floor_cents` on AMU-2. |
| Phase 2.5 — integration | `1777297347-engineer-phase2p5` then `1777297386-engineer-phase2p5` | 2026-04-27 13:42–13:43 | 147,913 B of gen~ DSL embedded into the 6 stubbed codeboxes; `.amxd` repacked to 275,448 B / sha `a5ed9d6f…`. Re-run yields identical sha (deterministic). 63/0 verifiers. |

`tl_model_eq`, `tl_volume_mix`, `tl_dry_mix` are biquad / mixer / crossfade modules that the bridge expresses with native Max objects, so they have no `.gendsp` source — by design.

---

## Build artifacts (final)

| Artifact | Path | Size | sha256 |
|---|---|---|---|
| Packed device | `device/tape-loss/tape-loss.amxd` | 275,448 B | `a5ed9d6f…` |
| Main patcher | `device/tape-loss/tape-loss.maxpat` | 275,415 B | (in audit) |
| Debug harness | `device/tape-loss/tape-loss-debug.maxpat` | 306,150 B | `1aabde43…` |
| Module patches | `device/tape-loss/tl_*.maxpat` | 9 files | (in audit) |
| Gen DSL sources | `device/tape-loss/gen/*.gendsp` | 6 files, 147,913 B embedded | (in audit) |
| JS companion | `device/tape-loss/js/model_selector.js` | 13,305 B | `e0d85960…` |
| Audit ndjson | `docs/exec-plans/active/tape-loss-audit.ndjson` | 556 events | — |

---

## Cross-module contracts — Phase 1.5 reconciliation outcome

All five contracts and three spec divergences from the Phase-1 emergence list were resolved before Phase 2 build. Full record in [`tape-loss-phase1.5-reconciliation.md`](tape-loss-phase1.5-reconciliation.md).

| # | Contract | Resolution | Implementation status |
|---|---|---|---|
| 1 | `failure_override` (tl_aux→tl_failure) | Code change: 4th inlet on tl_failure | ✓ wired in main patch |
| 2 | AMU-2 ±0.3c pitch floor (tl_model_eq→tl_wow) | Code change: `pitch_floor_cents` param | ✓ gated by `model_selector.js` on profile 11 |
| 3 | AUX FILTER ramp authority | Doc: tl_aux owns timing | ✓ no double-ramp |
| 4 | Shared `tapin~` buffer (wow↔flutter) | Doc: single `tape_loss_delay` buffer | **DIVERGED — see flag below** |
| 5 | Pre/de-emphasis ownership | Doc: tl_saturate owns NAB/IEC; tl_model_eq doesn't double-EQ | ✓ verified |

### Phase 1.5 contract divergence flag

The audit emitted one `phase15.contract.flag` event during Phase 2.5 integration:

```
contract: shared_tapin_wow_flutter
original_phase15_status: signed_off_shared
current_implementation: private_per_module
rationale: bit_identity_to_numpy_unreachable_real_time
revisit_when: v1_or_when_audible_diff_surfaces
```

Each of `tl_wow` and `tl_flutter` allocates its own delay buffer in their `.gendsp` rather than sharing `[buffer~ tape_loss_delay 1024]`. The numpy reference impls also cascade rather than share, so the divergence was already present in Phase 1; Phase 1.5 documented the *intent* to share at engineer time, but the realtime gen~ implementation didn't follow through. **User decision pending** — listed under "Open decisions" below.

---

## What changed in the build script

`build/build_tape_loss.py` between Phase 2 and Phase 2.5:

- 6 stub `newobj("gen~ @title …")` calls → `gen_codebox(title=, code=dsl, …)` with matching `numinlets` / `outlettype`
- ~85 lines of inline primitive definitions (`subpatcher_box`, `inlet_box`, `outlet_box`, generic `newobj`, `comment_box`) **deleted** — promoted to `stemforge_bridge.patcher`
- New helpers: `sha256_bytes`, `load_gen_dsl(module)` (reads `device/tape-loss/gen/<module>.gendsp` and inlines into the codebox)

The `gen_codebox` primitive worked first try with no rough edges. Multi-line DSL round-trips exactly. Inner `classnamespace="dsp.gen"` is correctly applied (the gotcha the bridge agent flagged when promoting it).

---

## Three new harness pitfalls (filed separately)

Surfaced during Phase 2 / 2.5; written up as proposals in the harness repo for verifier evolution. Captured here as a pointer; full text lives in `~/raindog/harness/docs/product-specs/`:

1. **Pitfall #21 — Subpatcher verifier exemption.** `verify_plugin_pair_for_audio` flags every subpatcher as missing `plugin~`/`plugout~`. Fix: typed verifier registry (`top_level_audio` vs `subpatcher`); subpatcher verifier asserts `[inlet]`/`[outlet]` count matches declared `numinlets`/`numoutlets`.
2. **Pitfall #22 — Bridge primitive gap.** `stemforge_bridge.patcher` was missing `subpatcher_box`, `inlet_box`, `outlet_box`, generic `newobj`, `comment_box`. **Already addressed** during Phase 2.5 (audit `harness.bridge_extended` event); needs a follow-on `verify_inlet_outlet_indices` to keep the inlet/outlet counts from drifting from declared values.
3. **Pitfall #23 — Cross-module contract verifier.** No verifier today checks that signal-rate cross-module wires (e.g. `tl_aux` outlet 2 → `tl_failure` inlet 7) actually exist in the main patch. Fix: add `cross_module_contracts:` to `pedal.schema.yaml` + a spec-driven verifier — the verifier-equivalent of the Phase 1.5 reconciliation doc.

---

## Open decisions (user input wanted)

### A. `tl_flutter` buffer sharing — private (current) vs shared (`tape_loss_delay`)

- **Private (current build):** each module owns its own `tapin~`/`tapout~` pair inside its `.gendsp`. Diverges from Phase 1.5 sign-off; matches numpy reference cascade behavior.
- **Shared (Phase 1.5 intent):** allocate one `[buffer~ tape_loss_delay 1024]` at the main-patch level; both modules read/write the same buffer.

**Recommend:** keep private until/unless an audible diff surfaces or v1 begins. The realtime constraint (read-write race avoidance, samplerate-change handling for both consumers off one buffer) was the unspoken cost the Phase 1.5 sign-off didn't price.

### B. Calibration round 2 — defer until after Max-IDE smoke test passes

The Phase 1 character-feedback list (failure too crackly, flutter weak at noon, dry-mix wet probe regen) is still queued. Don't burn cycles on it until we know the device loads and produces sound — calibration on a non-loading device is wasted work.

---

## Manual steps remaining (pre-Phase-5)

| # | Step | Time | Catches |
|---|---|---|---|
| 1 | Open [`tape-loss-debug.maxpat`](../../../device/tape-loss/tape-loss-debug.maxpat) in Max IDE → click loadbang → verify zero console errors | ~10 s | gen~ JIT-compile errors (pitfall #9) before Ableton sees the device |
| 2 | Drop [`tape-loss.amxd`](../../../device/tape-loss/tape-loss.amxd) on an Ableton track → play test audio | ~30 s | runtime crashes / clicks / silence-passthrough |

Manual budget remains within the project convention's ≤30 s/build excluding the IR-capture phase (Phase 5, deferred).

---

## Harness evolution observations (additions to the Phase-1 list)

7. **Stub-vs-functional distinction is project-relevant.** Phase 2 produced a verifier-passing `.amxd` (63/0) that was structurally complete but audibly silent. The verifier suite has no concept of "this module's body has actual DSP." **Proposal:** add a heuristic verifier that flags `gen~` codeboxes whose source body length is below a threshold (e.g. < 200 bytes after stripping comments) — catches stubs that pass syntactic checks.

8. **Bridge primitive promotion is a healthy harness signal.** Phase 2 inlined ~85 LOC of patcher primitives that Phase 2.5 then promoted into `stemforge_bridge.patcher`. **Proposal:** the engineer persona's checklist should include "list any inline patcher helpers added to the build script — these are bridge-promotion candidates" so this surfaces routinely rather than only when a follow-up phase notices.

9. **Phase 1.5 contract drift is a real risk.** A signed-off contract (shared buffer) was implemented differently in Phase 2.5 with an explicit flag event. The flag survived because the auditor explicitly emitted it; without that discipline it would have been silent. **Proposal:** make `phase15.contract.flag` a first-class event the verifier suite *requires* the engineer to either resolve or explicitly defer — and surface unresolved flags in `forge-device summary`.

10. **`gen_codebox` was a high-leverage primitive.** Once the bridge had it, the entire stub→functional transition was 6 calls + 1 helper (`load_gen_dsl`). **Proposal:** treat "what's the smallest set of primitives that turns hand-authored DSL into an embedded codebox" as a design question for any future runtime (vst-plugin quickstart, etc.) — the `.gendsp` → embedded-codebox pattern generalizes.

---

## Phase 5 entry conditions

When manual steps 1 + 2 above succeed:

- [ ] Tag a release commit
- [ ] Move `docs/exec-plans/active/tape-loss-*` → `docs/exec-plans/shipped/`
- [ ] Update repo `README.md` with the user-facing pedal description + install instructions
- [ ] Decide whether to begin tape-loss V1 (calibration round 2 + flutter taper retune + dry-mix fixture regen) or move on to a second pedal

---

## Audit-trail pointer (Phase 2 / 2.5)

Audit ndjson has grown from 123 events at Phase-1 close to **556 events** total. New event types added in this phase:

- `phase15.contract.flag` — divergence from a signed-off Phase 1.5 contract
- `phase2p5.integration.start` / `phase2p5.integration.complete` — wraps the gen-DSL embedding pass
- `harness.bridge_extended` — emitted from the bridge-extension run; records primitive name + bonus promotions + tests-passed

```bash
PYTHONPATH=$HARNESS_TOOLS python3 -m forge_device summary docs/exec-plans/active/tape-loss-audit.ndjson
```

---

*Phase 2 / 2.5 checkpoint generated 2026-04-27. Continues the Phase 1 trajectory above. Next checkpoint: Phase 5 (release) once manual smoke tests pass.*
