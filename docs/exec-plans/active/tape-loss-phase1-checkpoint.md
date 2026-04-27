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
