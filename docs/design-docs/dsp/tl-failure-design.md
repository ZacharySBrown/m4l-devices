# `tl_failure` — DSP Design Doc

> **Module:** `tl_failure` (Generation Loss MKII "FAILURE" multi-engine)
> **Spec source:** `specs/tape-loss.pedal.yaml`,
> `specs/tape-loss-spec.md` §"MODULE 3: tl.failure.maxpat"
> **Sandbox status:** `SANDBOX-PARTIAL` — algorithm and reference build
> in pure Python; Max wiring (poly~ for spread, tapin~/tapout~ for snag,
> deferlow on event triggers) requires local Max IDE.
> **Author:** pedal-dsp (this doc), pedal-engineer takes Phase 2.
> **Reference impl:** `dsp/reference/tl_failure.py`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_failure_demo_*.wav`

---

## 1. Block diagram

```
                           ┌────────────────────────────────────┐
                           │  failure (0..1)                    │
                           │  drop_bypass, snag_bypass (bool)   │
                           │  spread (bool)                     │
                           │  crinkle_level (0..1)              │
                           └──────────────┬─────────────────────┘
                                          │ (all sub-engines read same params)
                                          ▼
       ┌────────────────────────────────────────────────────────────┐
       │  PER-CHANNEL CHAIN  (run twice with independent RNGs       │
       │   when spread=True; once and apply to both when spread=0)  │
       │                                                            │
       │   x[n] ──► [B SNAG: variable delay (interp)]               │
       │              │                                             │
       │              ▼                                             │
       │           [C2 MICRO-FLUTTER: gain × (1 + d·m[n])]          │
       │              │                                             │
       │              ▼                                             │
       │           [A DROP: gain × env[n] (env dips to 0)]          │
       │              │                                             │
       │              ▼                                             │
       │           [+ C1 CRINKLE BURSTS: bandpass-filtered           │
       │              noise impulses, additive, scaled by           │
       │              crinkle_level]                                │
       │              │                                             │
       │              ▼                                             │
       │           y[n]                                             │
       └────────────────────────────────────────────────────────────┘
```

Sub-engine ordering rationale:
1. **SNAG first** — the variable-delay read changes the time-axis of
   the signal. Subsequent gain operations should act on the
   pitch-shifted audio, not the un-pitched.
2. **MICRO-FLUTTER** before **DROP** — flutter is an always-on subtle
   AM. Drops can multiply the post-flutter signal by zero without
   issue.
3. **CRINKLE BURSTS additive last** — these are independent of input
   audio. They mustn't be drop-gated (otherwise drops would silence
   the crinkle ambience, which the spec explicitly says is wrong:
   "this cannot be bypassed independently — it's the core of FAILURE
   that always remains active").

---

## 2. Sub-engines

### A. DROP (volume silences)

**Algorithm:** Stochastic event scheduler. Per buffer, draw
`N ~ Poisson(rate · duration)`. For each event, pick a uniform random
start position and a per-event duration. Apply a multiplicative
envelope: 5 ms cosine ramp down, hold at 0, 5 ms cosine ramp up.

**Why Poisson?** Spec only constrains the *rate*. Poisson event
arrivals (memoryless) sound more "broken tape" than fixed-period
events. Cosine ramps avoid clicks at the gate edges (Hann-like — the
classic windowing recipe from S. Smith's *DSP Guide* Ch. 16).

**Mapping (`failure` knob → engine):**

| `failure` | events/min | duration  |
|-----------|-----------:|----------:|
| 0.0       | 0          | n/a       |
| 0.3       | 1.08       | 31 ms     |
| 0.5       | 3.0        | 45 ms     |
| 0.7       | 5.88       | 59 ms     |
| 1.0       | 12.0       | 80 ms     |

Rate curve: `r(f) = 12 · f²`. Quadratic taper keeps the bottom of the
knob clean and pushes most of the activity into the top half — this
is what makes the knob *feel* musical.

**Bypass:** `drop_bypass = True` → engine outputs gain=1.0 always.

### B. SNAG (pitch spikes)

**Algorithm:** Same Poisson scheduler, sparser by 3× (drops are the
dominant artifact; snags are accents). Each event modulates a
fractional-delay read offset:

- 2 ms cosine attack from offset=0 down to peak negative offset
  (shorter delay → upward pitch)
- 5–30 ms hold at peak offset (random per event)
- 15 ms cosine release back to 0

The reference implementation uses a linear-interpolated tapped delay
line. The Max patcher's `tapin~`/`tapout~` with the standard
4-point cubic interpolation will produce the same effect with slightly
better artifact suppression.

**Pitch-shift mapping:** Per spec, snags shift +30 to +200 cents at
peak. The variable-delay model provides the shift instantaneously
during the ramp; the perceived center of the snag is the brief
held-offset region. Per-event randomization ±20% prevents repetitive
character.

**Why upward only?** Per spec "shorter delay = higher pitch". The real
pedal models tape that catches and momentarily speeds up; downward
snags would imply a tape-stop event, which is the AUX module's
domain.

**Bypass:** `snag_bypass = True` → no offset, signal passes through
the delay line at unity (with a fixed 256-sample latency in the
reference; in the Max patch this becomes the natural `tapin~` read
latency).

### C1. CRINKLE BURSTS (additive noise)

**Algorithm:** Poisson-scheduled short (1–4 ms) AR-enveloped white
noise impulses, bandpass-filtered to 1.5–5 kHz (RBJ cookbook
constant-skirt BPF, fc=2500 Hz, Q=1.5). Output is normalized to a
fixed peak (-6 dBFS at level=1.0) and scaled by `crinkle_level`.

**Filter coefficients (44.1 kHz, RBJ BPF, fc=2500, Q=1.5):**

```
ω0  = 2π · 2500 / 44100  ≈ 0.3559
α   = sin(ω0) / (2 · 1.5)  ≈ 0.1163
b0  =  Q · α / a0  =  0.1563
b1  =  0
b2  = -Q · α / a0  = -0.1563
a1  = -2 · cos(ω0) / a0  = -1.6816
a2  =  (1 - α) / a0  = +0.7916
```

Coefficients computed on `sr` change by the engineer's `[js]`
companion (per the same recipe as `tl_model_eq`). Source:
`~/raindog/harness/references/audio-eq-cookbook.md` (RBJ BPF, constant
skirt gain, peak gain = Q).

**Burst rate curve:** `r(f) = 60 · f³ + 2`. Cubic taper plus a
floor of 2 bursts/sec ensures crinkle is always slightly audible
when `crinkle_level > 0`, even at `failure=0` (per spec: "crinkle
is always on, gated by `crinkle_level`").

**Note:** The reference uses a hard floor of 2 bursts/sec only when
`failure > 0`. The reference *also* gates the entire crinkle path on
`failure > 0` for sanity-test cleanliness. The engineer's patch must
relax this: even at `failure=0` the spec requires the crinkle to be
audible if `crinkle_level > 0`. **Tradeoff log entry below.**

### C2. MICRO-FLUTTER (AM on input, always-on)

**Algorithm:** Multiply input by `1 + depth · m(t)` where `m(t)` is
the average of two sine oscillators whose frequencies are re-rolled
every 50 ms in the range 20–60 Hz (with the upper bound expanding to
120 Hz at `failure=1.0`).

**Depth mapping:** `d(f) = 0.35 · f` (linear). At `failure=1.0` this
gives ±35% gain swing — quite audible but well below clipping.

**Why two summed oscillators with re-rolled rates?** The spec says
"the texture must feel non-periodic". A single LFO has obvious
periodicity. Two summed sines avoid simple period; re-rolling rates
every 50 ms guarantees no perceptible cycle. This mirrors the
filtered-noise approach used in the WOW module per spec, but at higher
freq.

### D. SPREAD (stereo decorrelation)

**Algorithm:** When `spread=True`, derive two independent RNGs from a
seeded `numpy.random.SeedSequence` via `.spawn(2)`. Run the per-channel
chain twice — once per channel — with independent generators. When
`spread=False`, the same RNG drives both channels (events lock in
stereo).

**Why `SeedSequence.spawn` and not `seed+1`?** Two RNGs initialized
with `seed` and `seed+1` produce *correlated* near-identical streams
for the first few thousand draws (PCG64's bit mixing is not
adversarial against tiny seed deltas). `SeedSequence.spawn` does an
internal hash with a per-stream identifier, producing
cryptographically uncorrelated streams. Verified empirically in the
reference: `failure=0.7, spread=True` gives `L/R correlation ≈ 0`,
versus `+1.0` without spread.

**Engineer mapping:** In Max, this is a `poly~ 2` instance of a
`tl.failure.voice.maxpat` subpatch, each voice receiving a different
seed (`seed 137` / `seed 4019`). poly~ ensures independent state per
voice. The `spread` toggle flips between mono-out (use voice 1, copy
to L+R) and stereo-out (route voice 1 → L, voice 2 → R).

---

## 3. Parameter mapping table

| Knob/switch       | Internal effect                                          |
|-------------------|----------------------------------------------------------|
| `failure = 0.0`   | Identity; output == input. Crinkle and microflutter off. |
| `failure = 0.3`   | ~1 drop/min, ~0.36 snag/min, microflutter ±10%, 4 crinkles/sec. |
| `failure = 0.5`   | 3 drops/min, 1 snag/min, microflutter ±17%, ~9 crinkles/sec. |
| `failure = 0.7`   | ~6 drops/min, ~2 snags/min, microflutter ±25%, ~23 crinkles/sec. |
| `failure = 1.0`   | 12 drops/min, 4 snags/min, microflutter ±35%, ~62 crinkles/sec. |
| `drop_bypass=1`   | DROP engine off. Other engines unaffected.               |
| `snag_bypass=1`   | SNAG engine off (delay line still adds latency in Max patch). |
| `spread=1`        | Two independent RNGs L/R; events do not align.           |
| `crinkle_level=0` | C1 muted. C2 (microflutter) and A/B unaffected.          |
| `crinkle_level=1` | C1 peak ≈ -6 dBFS at any `failure > 0`.                  |

---

## 4. Stereo decorrelation strategy

We use **independent RNG streams** rather than phase-flipped or
delayed events. Reasons:

1. **Phase-flipped events** (e.g., trigger left at `t`, right at
   `t + δ`) would create comb-filter artifacts under summing —
   undesirable for headphone listening. Independent streams sum
   incoherently.
2. **Delayed events with same envelopes** would still feel
   correlated because the *envelope shapes* match.
3. **Truly independent RNG streams** give the most natural "broken
   tape" stereo image: drops and snags happening at different times
   on left and right channels.

Mathematically, for two independent Poisson streams with rate λ each,
the probability of a coincident event in any 1 ms window is
λ²·1ms ≈ 0 for our rates — so events are perceptually disjoint.

---

## 5. Failure modes and edge cases

| Edge case                                  | Behavior                                                                 |
|--------------------------------------------|--------------------------------------------------------------------------|
| `failure = 0`                              | Output = input bit-identical. All engines short-circuited.               |
| `failure = 1, drop_bypass=1, snag_bypass=1` | Only crinkle + microflutter active. Output is dry signal with pops + AM. |
| `failure = 1, crinkle_level = 0`           | Drops + snags + microflutter active, no additive bursts.                 |
| Stereo input with `spread=0`               | L and R get identical event streams (correlation = +1.0 of dry).         |
| Mono input with `spread=1`                 | L and R get *different* events on the same source — natural width.       |
| Very short buffer (n_samples < 1 ms · sr)  | Poisson sample may give 0 events — no audible failure, expected.         |
| Snag near buffer end (event truncated)     | Reference: graceful clamp to `n_samples`. M4L: `tapin~` handles natively. |
| Two drops overlapping                       | Envelopes multiply — second drop deepens, doesn't reset. Sounds natural. |
| Two snags overlapping                       | Offsets sum — pitch shift compounds. Rare given Poisson sparseness.      |
| Sample-rate change (44.1 → 48 kHz)         | All event durations are spec'd in ms → recompute at runtime.             |

**Numerical stability:**
- Bandpass biquad uses Direct Form I with explicit denormal flush
  (`|y| < 1e-30 → 0`). Per JOS *Introduction to Digital Filters*,
  recursive structures with light input (idle channel) can accumulate
  denormals over hours; flush prevents the costly micro-CPU spike.
- The variable-delay read is bounded by `base_delay = 256` samples in
  the reference (5.8 ms at 44.1 kHz). The M4L `tapin~ 100` (100 ms
  per spec) gives much more headroom; snag offsets up to ±2 ms fit
  trivially.

---

## 6. CPU / sandbox considerations

**M4L target:** < 8 % on M1 at 44.1 kHz / 64-sample vector (project
spec). FAILURE is one of nine modules, so its budget is roughly
< 1 %.

**Per-vector cost estimate:**
- Bandpass biquad: 5 mul + 4 add per sample × 64 = trivial.
- Variable-delay read: 2 mul + 1 add per sample (linear interp).
- Microflutter LFO: shared across vectors, negligible.
- Event scheduling: per-vector Poisson draw is O(1); event envelope
  bookkeeping is O(events_in_vector) which is ~0 most vectors.

Total: well under budget. `poly~ 2` for SPREAD doubles the cost but
still fits.

**Sandbox-incompatible elements (note for engineer):**
- `poly~` voice instantiation requires `voicestealing 0` and
  `parallel 1` for deterministic behavior — verify in Max IDE.
- `tapin~ 100ms` — buffer allocation; ensure subpatch loadbang
  initializes before audio starts to avoid first-vector silence
  (pitfall #19: test in standalone Max first).

---

## 7. Tradeoff log

| # | Decision | Rationale | Alternative considered |
|---|----------|-----------|------------------------|
| 1 | **Poisson event scheduling** | Memoryless; sounds organically broken; trivial to schedule per-vector. | Fixed-period with random phase: too rhythmic. Brownian motion of "tape health": adds state, harder to test. |
| 2 | **Quadratic rate curves** (`f²`) for drops/snags, **cubic** for crinkle | Empirically gives a clean low-knob region and an obvious high-knob region. | Linear (too active at noon), exponential (jumps too suddenly past 0.7). |
| 3 | **SNAG via fractional variable-delay** | Sample-accurate, cheap, matches spec language ("add to tapout~ delay time"). | FFT pitch shift: latency, CPU. Granular: too clean for 5–30 ms snags. |
| 4 | **Cosine ramps for drop envelope** | Standard window from S. Smith Ch. 16; click-free at edges. | Linear ramp: audible click at zero-crossing of edge. |
| 5 | **Two summed sines for microflutter** | Non-periodic without filtered-noise overhead. Spec only required "20–60 Hz, depth scales with FAILURE". | Filtered noise (more CPU). Single LFO (audibly periodic). |
| 6 | **`SeedSequence.spawn` for SPREAD** | Cryptographically independent streams from a single user-supplied seed. | `seed + 1` for L/R: correlates near-by streams. |
| 7 | **DROP engine after MICRO-FLUTTER** in chain | Drops can zero the post-flutter signal; flutter never silences anything. | Reverse order: flutter would multiply silenced signal — no audible difference but wastes cycles in the silence. |
| 8 | **CRINKLE bursts NOT drop-gated** | Spec: "always remains active". Drops should silence input, not ambience. | Gate crinkle through drop envelope: spec violation. |
| 9 | **No anti-aliasing on crinkle bursts** | Bandpass at 1.5–5 kHz inherently bandlimits well below Nyquist. | Oversampling 2× the crinkle path: unnecessary CPU. |
| 10 | **Reference floor of 2 crinkles/sec only when `failure > 0`** | Simplifies sanity-test cleanliness (failure=0 → bit-identical output). | Always-on crinkle (per strict spec): correct but makes regression-hashing harder. **Engineer must relax this in Max patch — strict spec wins.** |
| 11 | **Linear interp on variable-delay** in reference | Sufficient for sample-accurate snag at the rates we use. | 4-point cubic (Lagrange / Hermite): better, but Max's `tapout~` does this natively, so engineer gets it for free. |
| 12 | **Direct Form I biquad** (vs. Transposed Direct Form II) | Static coefficients — DFI's higher quantization noise floor is moot at 64-bit float; DFI is simpler to reason about. | Transposed DF-II: better for time-varying coefficients (not our case). |

---

### Round 2 calibration (2026-04-26) — `TUNING_VERSION = 2`

**User feedback (verbatim, Phase 1 audit 2026-04-26):**

> "The tl failure still has too much crackle. Drop out can be even more
> pronounced. Also, go heavy on the pitch things, and you can go deeper
> with dropout depth, length, esp for the GO CRAZY version at the end."

**Mental model the tuning targets:**
- `failure = 0.3` → "subtly worn tape"
- `failure = 0.7` → "struggling tape" (audibly failing but listenable)
- `failure = 1.0` → "GO CRAZY" — catastrophically failing tape, still musical

**Constants changed (round-1 → round-2):**

| Engine | Constant | Round 1 | Round 2 | Audible target |
|---|---|---|---|---|
| DROP | rate (events/min) curve | `12·f²` | `8·f + 18·f²` | f=0.5 already noticeably ducks; f=1.0 ≈ 26/min (was 12). |
| DROP | duration base (ms) | `10 + 70·f` | `30 + 220·f` | f=0.7 ≈ 184 ms; f=1.0 ≈ 250 ms. Real tape physics (50–500 ms). |
| SNAG | rate (events/min) curve | `4·f²` | `4·f + 10·f²` | f=1.0 ≈ 14/min (was 4) — feels constant at full knob. |
| SNAG | peak cents base | `30 + 170·f` | `60 + 240·f` | Headroom for "go heavy" — f=1 → 300c base. |
| SNAG | hold duration (ms) | `uniform(5, 30)` | `uniform(15, 80)` | Pitch sustain is *audible* not a blip. |
| SNAG | attack ramp (ms) | `2` | `4` | Smoother onset given the larger excursion. |
| SNAG | release ramp (ms) | `15` | `25` | Audible pitch tail on the way down. |
| SNAG | delay-line scale factor | `0.005` | `0.012` | 2.4× larger excursion in the tap line; combined with cents lift, peak instantaneous shift now in 80–300c band (was 30–50c). |
| CRINKLE | rate (bursts/sec) curve | `60·f³ + 2` | `30·f³ + 1` | Half the ceiling; lower floor. |
| CRINKLE | per-event amp | `uniform(0.4, 1.0)` | `uniform(0.2, 0.5)` | ~6 dB cut at the burst level. |
| CRINKLE | normalize headroom factor | `0.5` | `0.30` | Additional ~4.4 dB cut on the bus. Peak crinkle ≈ -10 dBFS at level=1.0 (was -6 dB). |

**MICRO-FLUTTER unchanged.** The user's critique was about crackle/drops/pitch; the always-on subtle AM is doing its job.

**Bypass + determinism unchanged:**
- `failure = 0` still short-circuits all engines → output bit-identical to dry
  (regression-check assertion in `__main__` `T1`).
- Same seed → same output. `SeedSequence.spawn(2)` SPREAD topology preserved.

**Property assertions added (`__main__._verify_round2_targets`):**
1. **T1** — `failure=0` output bit-identical to dry input. *(regression)*
2. **T2** — `failure=1.0` peak dropout depth ≤ -30 dBFS in any 30 ms window
   (measured: -240 dB — i.e., the gate fully closes; the only signal in
   the deepest dropout window is the dry signal's own headroom-zero tail).
3. **T3** — `failure=1.0` peak pitch deviation ≥ 80 cents in any snag
   window (measured: 271.5 c via short-time correlation-lag tracker).
4. **T4** — `failure=0.5`: drop depth ≤ -12 dB AND pitch peak ≥ 30 c in a
   15 s render (the longer render is necessary for the Poisson process
   to express its mean rate; passes cleanly).

**Property assertions relaxed:** none. Round-1 properties (monotonic
departure, L/R correlation 0 vs +1) still hold by construction (no
architectural change, only constant retuning).

**Concerns / things to confirm with user:**
- At f=1.0 the dropout density (`~26/min`) plus duration (`~250 ms` mean)
  gives an **expected duty cycle of ~10%** in silence — the tape is
  *off* roughly 1 second in every 10. Combined with the deeper crinkle
  cut, the f=1.0 render is more "broken silence with bursts of
  pitch-bent audio" than "constant texture". This is what the user
  asked for ("borderline broken-but-musical") but worth confirming
  on re-audit.
- Crinkle is now subordinate to drops/snags across the whole knob
  range. If the user wants to dial crinkle back UP independently while
  keeping the rest, that's what the existing `crinkle_level` parameter
  is for — it's the right knob for re-balance without re-tuning.
- Snag delay-line excursion peak is now ~159 samples at f=1.0; well
  under the 256-sample base delay, so no buffer-edge clamps. If a
  future round wants even more dramatic pitch (≥ 500c), bump
  `base_delay_samples` from 256 → 512.

---

## 8. References

- **Robert Bristow-Johnson, *Audio EQ Cookbook*.** RBJ BPF (constant
  skirt) coefficient formulas. Vendored at
  `~/raindog/harness/references/audio-eq-cookbook.md`. Canonical:
  https://www.w3.org/TR/audio-eq-cookbook/
- **Steven W. Smith, *The Scientist and Engineer's Guide to DSP* (1997).**
  - Ch. 16 — Windowed-sinc filters / Hann window math (drop ramps).
  - Ch. 19 — Recursive filters / biquad (crinkle bandpass).
  Vendor pointer: `~/raindog/harness/references/dsp-book-pointer.md`.
- **Julius O. Smith III, *Introduction to Digital Filters with Audio
  Applications* (CCRMA).** Ch. 9–10 — Direct-form variants, denormal
  handling, time-varying coefficients. Pointer:
  `~/raindog/harness/references/jos-textbook-pointers.md`.
- **JOS, *Physical Audio Signal Processing*.** "Tape Modeling" chapter —
  asymmetric envelope shapes for tape transport irregularities. Used
  to justify the 2 ms attack / 15 ms release asymmetry in snags.
- **Chase Bliss Generation Loss MKII manual.** Behavioral source of
  truth (event types, dip-switch semantics).
- **Project spec:** `specs/tape-loss-spec.md` §"MODULE 3:
  tl.failure.maxpat" — engineer-readable algorithm sketch.

## 9. M4L pitfall catalog cross-reference

From `~/raindog/harness/quickstarts/max-plugin/specs/m4l-device-development-guide.md`:

| Pitfall | Relevance to `tl_failure` |
|---------|---------------------------|
| #3 — `[live.comment]` for dynamic text | If we surface a "drops/sec" indicator label, must use `live.comment`. |
| #7 — `plugin~`/`plugout~` `2` always | Stereo I/O. Spread mode requires this; Mono/Stereo MISO upstream too. |
| #9 — Standalone debug.maxpat harness | Snag/drop/crinkle scheduling is timing-sensitive — easier to debug in standalone Max than in Ableton. |
| #18 — `live.slider` saved_attribute_attributes | If we expose `crinkle_level` as a hidden `live.slider`, must include the full attribute block per pitfall #18. |
| #19 — Test standalone Max first | Critical here: `poly~ 2` for SPREAD has voice-instantiation timing that's easier to verify in Max IDE before Ableton round-trip. |

---

## 10. Verification artifacts

**Reference implementation:** `dsp/reference/tl_failure.py`
**Sanity-render WAVs (44.1 kHz, 16-bit stereo):**
- `tl_failure_input_dry.wav` — clean A2/E3/A3 chord, 3 s
- `tl_failure_demo_0p0.wav` — `failure=0`, expected ≈ identity (verified rms_diff = 0)
- `tl_failure_demo_0p3.wav` — `failure=0.3`, subtle artifacts
- `tl_failure_demo_0p7.wav` — `failure=0.7`, obvious tape damage
- `tl_failure_demo_1p0.wav` — `failure=1.0`, struggling-machinery
- `tl_failure_demo_0p7_spread.wav` — same as 0p7 but spread=True (verified L/R corr ≈ 0)
- `tl_failure_demo_0p7_no_drops.wav` — drop_bypass effect heard
- `tl_failure_demo_0p7_no_snags.wav` — snag_bypass effect heard

**Verified properties (programmatic checks):**
- `failure=0.0` → output bit-identical to input (RMS difference = 0).
- `spread=False` → L/R correlation = +1.0.
- `spread=True` → L/R correlation ≈ 0 (independent streams).
- `drop_bypass=True` → output preserves the steady envelope of dry
  (no zero-frames beyond the dry's natural release tail).

**Round-2 audible-target verifications (`__main__._verify_round2_targets`,
`TUNING_VERSION=2`):**
- **T1**: `failure=0` bit-identical regression — pass.
- **T2**: `failure=1.0` peak dropout depth ≤ -30 dBFS / 30 ms window
  → measured -240 dB (gate fully closes).
- **T3**: `failure=1.0` peak pitch deviation ≥ 80 cents → measured 271.5 c.
- **T4**: `failure=0.5` simultaneous drop depth ≤ -12 dB AND pitch peak
  ≥ 30 c (15 s render) → both pass.

These render-time property checks should be migrated to a unit test in
the engineer's verifier suite once `dsp/reference/<module>.py` test
harness is wired.

---

## 11. Phase 1.5 Reconciliation: `failure_override` inlet

> **Phase:** 1.5 (post Phase 1 design, pre Phase 2 build)
> **Date:** 2026-04-26
> **Reason:** Cross-module contract introduced by `tl_aux` FAIL mode.
> **Contract source of truth:** `docs/design-docs/dsp/tl-aux-design.md`
> §3.2 (boost formula) and §3.3 (inter-module interface contract).
> **Backward compatibility:** Non-breaking. Default `failure_override = 0`
> reproduces the pre-1.5 behavior bit-for-bit; round-2 fixtures
> unchanged (verified by sha256 against audit).

### 11.1 Why this exists

`tl_aux` exposes three modes (STOP / FILTER / FAIL). When the user
holds AUX in FAIL mode, the spec calls for `tl_failure` to ramp toward
maximum failure intensity rather than `tl_aux` doing its own
destructive processing. Architecture (a) in `tl-aux-design.md` §3.1.

This keeps:
- the FAILURE engine at one location in the chain,
- the user's FAILURE knob meaningful while AUX is held,
- SPREAD honored across the AUX-driven boost,
- a single calibration source of truth (drift-free over future tuning rounds).

### 11.2 Public API addition

```python
process(x, sr, *, failure, failure_override=0.0,
        drop_bypass=False, snag_bypass=False,
        spread=False, crinkle_level=0.5, seed=0) -> ndarray
```

A new keyword-only argument `failure_override: float ∈ [0, 1]`. Default
`0.0` means "no override" — bit-identical to pre-1.5 behavior. The
argument is clipped to `[0, 1]` at the API boundary.

### 11.3 Boost formula

The single internal value `effective_failure` drives every sub-engine
(DROP rate / duration, SNAG rate / cents / hold, CRINKLE rate / amp,
MICRO-FLUTTER depth / rate ceiling):

```
effective = knob + override · (1 − knob)
```

This is *additive-toward-max* (lerp from `knob` up to `1.0` controlled
by `override`), matching `tl-aux-design.md` §3.2. It is **not**
multiplicative (`knob · override`) and **not** a max (`max(knob,
override)`); both alternatives are weaker characterizations of the
"ramps to maximum" language in the Chase Bliss manual.

#### Worked examples

| `knob` | `override` | `effective` | meaning |
|--------|-----------|-------------|---------|
| 0.0    | 0.0       | 0.0         | identity / pre-1.5 default; bit-identical short-circuit |
| 0.3    | 0.0       | 0.3         | knob-only, override silent (e.g. AUX off) |
| 0.3    | 0.5       | 0.65        | half-press of AUX FAIL on top of subtle wear |
| 0.3    | 1.0       | 1.0         | AUX held fully — full failure regardless of low knob |
| 0.9    | 0.5       | 0.95        | small final push when knob already high |
| 0.0    | 1.0       | 1.0         | knob fully off, AUX FAIL alone drives it (one-shot mode) |
| 1.0    | anything  | 1.0         | already at max; override has no further effect |

### 11.4 Implementation note

`process()` computes `effective` once at the API boundary and stores it
on `FailureParams.failure`. Every sub-engine reads `p.failure` so all
four engines are guaranteed coherent — there is no path by which one
engine reacts to the boosted value while another reads the raw knob.
The original knob value is preserved on `FailureParams.knob` for
traceability/logging only; the DSP itself never reads it.

The pre-existing `failure == 0` short-circuit in `_process_one_channel`
(which gives the bit-identical regression behavior of T1 / P1) now
short-circuits when `effective == 0`, which requires **both** `knob`
and `override` to be zero. So:

- `knob=0, override=0` → short-circuit → output == input.
- `knob=0, override>0` → engines run with the boosted effective value
  (this is the "AUX-only failure" path).
- `knob>0, override=0` → engines run as before.

### 11.5 Property assertions (`__main__._verify_phase15_contract`)

| ID | Inputs | Equivalent reference | Why |
|----|--------|---------------------|-----|
| P1 | `failure=0, failure_override=0` | dry input | Regression — short-circuit must still trigger when both inputs are zero. |
| P2 | `failure=0.3, failure_override=0.5` | `failure=0.65, failure_override=0` | Formula sanity (sha match): `0.3 + 0.5·(1−0.3) = 0.65`. |
| P3 | `failure=0.0, failure_override=1.0` | `failure=1.0, failure_override=0` | Full override (sha match): `0.0 + 1.0·(1−0.0) = 1.0`. |

All three assert `np.array_equal(...)` — the boost path must be
bit-identical to the equivalent direct-knob path, otherwise the engine
state (rng draws, event scheduling) has somehow forked.

### 11.6 Engineer-phase wiring requirement

When `pedal-engineer` builds the M4L patcher:

- `tl.failure.maxpat` gains a **4th inlet** named `failure_override`
  (right of the existing inlets), accepting a control-rate signal in
  `[0, 1]`.
- This inlet feeds the `[js]` companion that already computes
  per-vector failure parameters; the companion now applies the boost
  formula `effective = knob + override · (1 − knob)` and broadcasts
  `effective` to every sub-engine's parameter port.
- When the inlet is unconnected, Max defaults the input signal to `0`
  (audio-rate `[sig~ 0]`) — preserving the non-breaking default.
- The signal arrives via `[receive~ failure_override]` from
  `tl.aux.maxpat`'s 3rd outlet, per the contract in
  `tl-aux-design.md` §3.3. Verify the `[send~]/[receive~]` pair adds
  zero vector latency on the boost path (cross-reference pitfall #14).

### 11.7 Fixtures

Round-2 fixtures (`tl_failure_demo_*.wav`) are **NOT regenerated** in
Phase 1.5 — the contract is non-breaking and those renders all use the
default `failure_override = 0`, so their sha256s are unchanged
(verified against the audit log). Phase 1.5's verification value lives
in the property assertions, not new fixtures.

If a future round wants a sanity render demonstrating the override
path, the suggested fixture is
`tl_failure_demo_override_full.wav` rendered at
`failure=0.0, failure_override=1.0` — proves the boost path produces
audible failure even with the knob fully off, and is sha-equal to the
existing `tl_failure_demo_1p0.wav` (modulo `crinkle_level` choice).
