# tape-loss — Phase 1.5 Reconciliation

**Date:** 2026-04-26
**Purpose:** Resolve the cross-module contracts and spec divergences that emerged from parallel Phase 1 design. **Read this before starting Phase 2 (pedal-engineer).**

---

## Cross-module contracts (5)

### 1. `failure_override` — `tl_aux` FAIL → `tl_failure`

**Status:** Resolved by code change (Phase 1.5 agent run; see audit `module.tl_failure.contract_added`).

**Contract:**
- `tl_failure` accepts a new optional 4th inlet, `failure_override ∈ [0.0, 1.0]`, default 0.
- Internal calculation: `effective_failure = failure + failure_override · (1 - failure)`.
- All four sub-engines (drop / snag / crinkle / micro-flutter) read `effective_failure`.

**Engineer wiring:**
```
[tl_aux] outlet_3 (failure_override) ─→ [tl_failure] inlet_4
```
- The signal is sample-rate when AUX active, 0 when not.
- Smoothed envelope is already applied inside tl_aux; tl_failure does not need additional smoothing.
- When AUX mode is not FAIL, outlet_3 emits 0 — non-destructive.

**Origin:** `tl_aux` design doc §3.3 (FAIL architecture (a) — sidechain control vs local destruction).

---

### 2. AMU-2 pitch-drift floor — `tl_model_eq` profile 11 → `tl_wow`

**Status:** Resolved by code change (Phase 1.5 agent run; see audit `module.tl_wow.contract_added`).

**Contract:**
- `tl_wow` accepts a new optional parameter `pitch_floor_cents: float = 0.0`.
- When `pitch_floor_cents > 0`, an independent low-amplitude filtered-noise LFO (separate seed) drives a tiny baseline drift, summed into the main delay-time signal.
- When `wow=0` AND `pitch_floor_cents=0`, bit-identical passthrough preserved.
- When `wow=0` AND `pitch_floor_cents>0`, only the floor drift is heard.

**Engineer wiring:**
- The `model` knob value gates this. When `model == 11` (AMU-2 profile), engineer code sets `pitch_floor_cents = 0.3`. For all other models, 0.0.
- Practically: `[tl_model_eq]` (or a sibling logic block) emits a parameter message → `[tl_wow]`'s pitch_floor_cents inlet.
- Source of truth: `data/model_eq_coefficients.json` profile 11 has `extra_behavior` flag noting `pitch_drift_cents: 0.3`.

**Origin:** `tl_model_eq` design doc — agent flagged that AMU-2's pitch character is pitch-domain, not EQ.

---

### 3. AUX FILTER ramp authority — `tl_aux` ↔ `tl_model_eq`

**Status:** Resolved by documentation (this doc).

**Decision:** `tl_aux` owns the FILTER ramp timing. `tl_model_eq` exposes only the boolean `filter_bypass` and does not implement its own ramp.

**Rationale:** `tl_aux` already owns the `aux_onset_ms` parameter (10-3000 ms log-tapered). Putting another ramp inside `tl_model_eq` would double-ramp on toggle. `tl_model_eq`'s 12 ms equal-power crossfade still applies on `model` changes — that's a different, faster ramp for profile selection, and runs independently.

**Engineer wiring:**
- `tl_aux` FILTER mode emits its filter cutoff/Q sweep on outlets that drive a wet/dry mixer wrapping `tl_model_eq`'s output, OR (cleaner) drives a dedicated `[svf~]` block placed in parallel with `tl_model_eq`. The latter is the design intent — see `tl_aux` design doc §4.
- `tl_model_eq`'s `filter_bypass` is a UI/dip-switch, gated separately from AUX.

---

### 4. Shared `tapin~` buffer — `tl_wow` ↔ `tl_flutter`

**Status:** Resolved by documentation (this doc).

**Constraint:** Per spec, `tl_wow` and `tl_flutter` should share a single `[buffer~]` for their delay-line reads. Reasons: (a) memory efficiency, (b) gives the engineer one location for samplerate-change + buffer-resize handling.

**Reference impls cascade the modules** — they don't share state. The reference output will NOT be bit-identical to the M4L patch output; both are correct.

**Engineer wiring:**
- Allocate ONE `[buffer~ tape_loss_delay 1024]` (or sized to peak excursion + 1 power of 2 — `tl_flutter` design doc §6 has the math).
- `[tl_wow]`: writes the input via `[record~]` or `[tapin~]`, reads via `[tapout~]` with its delay-time signal.
- `[tl_flutter]`: reads from the SAME buffer with its own `[tapout~]` and delay-time signal.
- The write path goes through wow's input; flutter reads downstream of wow's read tap, but reads the same physical buffer.
- Pitfall: read-write race — verify the buffer is large enough that flutter's read position never overtakes wow's write position even at maximum modulation.

---

### 5. Pre/de-emphasis ownership — `tl_saturate` vs `tl_model_eq`

**Status:** Resolved by inspection (this doc).

**Verification:** `tl_saturate` owns NAB/IEC pre/de-emphasis shelves bracketing the shaper. `tl_model_eq` profiles do NOT replicate these — its shelves are medium-fingerprint EQ (head-gap rolloff, head-bump, etc.), serving a different physical role.

From [`tl-saturate-design.md`](../../design-docs/dsp/tl-saturate-design.md) §4:
> *"tl_model_eq models the machine's spectral signature. The pre/de-emphasis shelves around the saturator model the recording bias path: the record amplifier boosts highs going to tape so they get saturated harder."*

The pre/de-emphasis pair is verified flat to <1e-15 dB cascade error when the shaper is bypassed. **No double-EQ.** Engineer can implement both modules' shelves without conflict.

---

## Spec divergences (3)

### 6. `tl_saturate=0` short-circuit bypass

**Decision:** **KEEP** the short-circuit (bit-identical to dry). User signoff 2026-04-27 (recommended 2026-04-26).

**Rationale:** Cleaner, pitfall-friendly (no zipper noise on parameter sweep), no audible loss. Strict spec interpretation would still run drive=1 through the chain, but provides no perceptual benefit and risks subtle DC/aliasing artifacts.

---

### 7. `tl_wow` base delay 25 ms (vs spec's 5 ms)

**Decision:** **KEEP** 25 ms. User signoff 2026-04-27 (recommended 2026-04-26).

**Rationale:** Required headroom for A_max=6 ms peak excursion at wow=1.0. Spec sketch was wrong-shaped. Latency is masked by the 30 ms pre-WOW dry-tap latency-alignment requirement that `tl_dry_mix` already imposes (engineer wires the dry-tap upstream of wow at +30 ms compensating delay). Bypass at wow=0 preserves bit-identical passthrough.

---

### 8. `tl_flutter` `classic_mode` = AM-bypass-only

**Decision:** **KEEP** the AM-bypass interpretation. User signoff 2026-04-27 (recommended 2026-04-26).

**Rationale:** Spec gave only a one-line description; this matches Chase Bliss's "classic mode" convention on similar pedals (pitch-only, no AM). The pitch character is unchanged between modes. If a different interpretation surfaces in V1, redirect — for now, AM-bypass-only.

---

## Phase 2 entry conditions

All 5 cross-module contracts are either resolved by code or documented above. All 3 spec divergences have user signoff. Calibration round 2 is in place for `tl_failure` and `tl_flutter`. Fixture corpus is consistent.

**Phase 2 (pedal-engineer) can start.** The engineer's pre-flight reading order:

1. `specs/tape-loss-spec.md` (prose source of truth)
2. `specs/tape-loss.pedal.yaml` (DSL)
3. This document (Phase 1.5 reconciliation)
4. `docs/design-docs/dsp/tl-*-design.md` per module, in signal-chain order
5. `data/*.json` (coefficient files)
6. `dsp/reference/*.py` (golden-render references for verification)
7. `~/raindog/harness/quickstarts/max-plugin/specs/m4l-device-development-guide.md` (the 20-pitfall catalog)

**Phase 2 deliverables (preview):**
- Per-module `device/<name>/<module>.maxpat` via `stemforge_bridge.patcher`
- Main `device/<name>/<name>.maxpat` wiring all modules in signal-chain order
- Standalone debug harness `device/<name>/<name>-debug.maxpat`
- Packed `device/<name>/<name>.amxd` via `amxd_pack.pack_amxd(..., device_class='audio')`
- All `PATCHER_VERIFIERS` + `AMXD_VERIFIERS` passing
- Audit events covering every module patch + verifier run

---

## Backlog acknowledged but not addressed in Phase 1.5

- **tl_aux multi-style STOP variants** (cassette/reel/VHS/8mm/dictaphone/microcassette) — see `~/.claude/projects/-Users-zak-zacharysbrown-m4l-devices/memory/project_slowdown_modes_backlog.md`. Post-v0.
- **IR captures** — Phase 5 deferred to extension. Synthetic DSP only for v0.
- **Fixture A/B renderer formalization** — current prototype works; promote to standard forge-device deliverable on next pedal.
- **Harness `vst-plugin` quickstart** — proposal at `~/raindog/harness/docs/product-specs/vst-plugin-quickstart-proposal.md`. Separate track.
