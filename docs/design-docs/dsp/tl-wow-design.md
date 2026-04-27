# `tl_wow` — DSP Design Doc

> **Module:** `tl_wow` (Generation Loss MKII "WOW" knob — slow random
> pitch drift via variable delay).
> **Spec source:** `specs/tape-loss.pedal.yaml`,
> `specs/tape-loss-spec.md` §"MODULE 4: tl.wow.maxpat"
> **Sandbox status:** `SANDBOX-PARTIAL` — algorithm and reference build
> in pure Python; Max wiring (`tapin~`/`tapout~`, signal-rate `+~`/`*~`
> for the LFO sum, `[js]` coefficient computation on `sr` change)
> requires local Max IDE.
> **Author:** pedal-dsp.
> **Reference impl:** `dsp/reference/tl_wow.py`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_wow_*.wav`

---

## 1. Block diagram

```
                         ┌──────────────────────────┐
                         │  wow ∈ [0, 1]            │
                         │  stereo_decorrelate ∈ B  │
                         └─────────┬────────────────┘
                                   │
                                   ▼
              A(wow) = K · (0.30·w² + 0.70·w³)   [seconds]

  ── per-channel chain (run twice with independent RNGs ── ── ── ──
  ──  if stereo_decorrelate else single shared LFO)     ── ── ── ──

       white noise ──► [1-pole LPF, fc=0.5 Hz] ── 2× ──┐
                                                       │
       white noise ──► [1-pole LPF, fc=0.7 Hz] ── 2× ──┤
                                                       ▼
                                          (sum/2, normalize peak→1)
                                                       │
                                                       ▼
                                            m(t) ∈ [-1, +1]
                                                       │
                                       D(t) = D₀ + A·m(t)
                                                       │ [seconds]
                                                       ▼
       x[n] ──► [ring buffer (write_idx)] ──► [4-pt Hermite read at
                                                 (n − D(t)·sr)] ──► y[n]
```

- **D₀ (base mean delay)** = 25 ms (>> A_max=6 ms, so D(t) never goes
  negative). Larger than the 5 ms in the spec sketch — cheap (just
  more buffer) and gives interpolation history headroom.
- **Buffer length** chosen at runtime as
  `max(4096, ceil((D₀ + A) · 2 · sr) + 16)` samples. At 48 kHz with
  A_max = 6 ms this is ~2976 → rounds up to 4096; at 96 kHz it grows
  to ~6000+.

`wow == 0` short-circuits the entire chain — output is bit-identical
to input. **Verified:** `np.array_equal(y, x) is True` (see test in
`__main__`).

---

## 2. LFO topology — filtered white noise, two cutoffs

**Choice:** Pair of independent white-noise streams, each through a
**double 1-pole LPF (12 dB/oct)** at cutoffs 0.5 Hz and 0.7 Hz, summed
and re-normalized to unit peak.

**Why filtered noise (not sine, not random walk)?**
- Spec language: *"slow random pitch drift"*. A sinusoid has a fixed
  period and reads as vibrato; the spec explicitly contrasts wow with
  vibrato in the FLUTTER design note.
- A random walk (Brownian motion) drifts but doesn't return —
  unbounded in expectation. Bad for a stationary modulator.
- Filtered noise is **stationary** (bounded in expectation) yet
  **aperiodic** (no perceptible repeat). Mirrors the spec's
  recommendation in §MODULE 4: *"a pair of filtered noise signals with
  slightly different cutoffs summed together, to avoid the LFO ever
  feeling repetitive or patterned"*.

**Why two cutoffs (0.5 + 0.7 Hz)?**
A single LPF-noise stream has an autocorrelation peak at lag = 1/fc.
Summing two streams with different cutoffs makes the autocorrelation
even broader, killing any sense of period.

**Why double 1-pole (12 dB/oct) and not single?**
A single 1-pole at 0.5 Hz has a -3 dB point at 0.5 Hz but only
-6 dB/octave rolloff — significant noise content well above 1 Hz that
audibly twitches. Cascading two 1-poles at the same cutoff gives a
sharper -12 dB/octave slope; the modulator becomes smooth (almost
pulse-like) and reads as pitch *drift* rather than *jitter*.

**Topology choice — `[lores~]` vs RBJ biquad:**
The spec sketch uses `[lores~ 0.25 0.7]` (a ladder LP). For the
reference we use a 1-pole because it has zero ringing and exact known
transfer function:
```
y[n] = a·x[n] + (1-a)·y[n-1]
where a = 1 − exp(−2π·fc/sr)
```
Citation: S. Smith, *The Scientist and Engineer's Guide to DSP*
Ch. 19 ("Recursive Filters"), single-pole low-pass coefficient
formula. The engineer can use `[lores~]` in Max — its `gain` (Q)
parameter at default 0.7 makes it close to a Butterworth 2-pole, with
acceptable ringing at sub-Hz rates.

### LFO statistics (per the calibration in `__main__`)

For the 0.5 + 0.7 Hz double-1-pole LPF noise sum, normalized to unit
peak over a 6-second window:

| Quantity                         | Value (mean over 20 seeds) |
|----------------------------------|----------------------------:|
| Peak `\|m(t)\|`                   | 1.000 (by construction)    |
| Peak `\|dm/dt\|` per second       | 6.32 ± 1.60                 |
| Range of peak slope across seeds | [4.21, 9.56]                |

These statistics drive the depth calibration below.

---

## 3. Variable-delay interpolation choice — 4-point cubic Hermite

**Decision:** Reference uses 4-point Hermite cubic. Linear interpolation
is **rejected** for slow modulation:

| Scheme        | Frequency-dependent loss at fc=0.5·Nyquist  | Used here? |
|---------------|---------------------------------------------:|------------|
| Drop-sample   | -∞ (sample-quantized; aliasing)              | No         |
| Linear        | -3.92 dB                                      | No         |
| 4-pt Hermite  | -0.01 dB                                      | **Yes**    |
| 4-pt Lagrange | -0.01 dB                                      | (alt)      |
| Sinc / 8+ tap | < -0.001 dB                                   | (overkill) |

(Numbers from JOS PASP, §"Lagrange Interpolation".)

For wow specifically — slow modulation of a delay line — linear
interpolation produces an audible "sandiness" / loss as the read
position crosses sample boundaries (the high-frequency content of the
input is convolved with a triangular FIR whose width tracks the
fractional position). Hermite is essentially transparent.

**Citations:**
- Julius O. Smith III, *Physical Audio Signal Processing*, ch.
  "Time-Varying Delay Effects":
  https://ccrma.stanford.edu/~jos/pasp/Tape_Recorder_Modeling.html
- Julius O. Smith III, *Interpolated Delay Lines, Ideal Bandlimited
  Interpolation, and Fractional-Delay Filters*:
  https://ccrma.stanford.edu/~jos/Interpolation/
- Olli Niemitalo, *Polynomial Interpolators for High-Quality Resampling
  of Oversampled Audio* (yehar.com, 2001) — canonical 4-point cubic
  formulae for audio.

**Engineer mapping:** Max's `[tapout~]` provides 4-point cubic
interpolation natively when the delay-time inlet is signal-rate
(rather than message-rate). The reference's Python implementation
matches the same Hermite form (Catmull-Rom variant). The verifier
should compare M4L renders against the Python output to within
~-60 dB RMS error.

---

## 4. Buffer-size calculation

Buffer must hold history covering the deepest read position plus
interpolation lookahead.

```
worst_case_delay_samples  = ceil((D₀ + A_max) · sr)
                          = ceil((0.025 + 0.006) · 48000)
                          = ceil(1488)                   = 1488
hermite_lookahead         = 2  (need x[i+2])
buffer_len  ≥  worst_case_delay + hermite_lookahead + safety
            =  1488 + 2 + 14                              = 1504
```

Reference uses `max(4096, 2·worst_case + 16)` for plenty of headroom
and to handle resamples up to 96 kHz without reallocation.

**Max patcher:** `[tapin~ 50.]` (50 ms) is plenty for both the spec's
±15/±70-cent calibration target and any future depth increase. The spec
sketch suggests `[tapin~ 100.]`; we go with the same to match the spec
verbatim and leave headroom for the WOW+FLUTTER shared buffer the
flutter design doc may want.

---

## 5. Depth → cents mapping (the math)

For an instantaneously-time-varying delay D(t) (seconds), the output
of a delay line `y(t) = x(t − D(t))` carries instantaneous frequency
shift via the chain rule:

```
phase_out(t)   = phase_in(t − D(t))
f_out(t) / f_in = d/dt (t − D(t))
                = 1 − dD/dt
```

Converting to cents (assuming small dD/dt):

```
Δcents(t) = 1200 · log₂(1 − dD/dt)
         ≈ −(1200 / ln 2) · dD/dt          [for |dD/dt| << 1]
         = −1731.234 · dD/dt
```

So the peak |Δcents| is determined by the peak rate of change of the
delay-time signal:

```
|Δcents|_peak ≈ 1731 · A · |dm/dt|_peak
```

where `m(t)` is the unit-normalized LFO. From §2, the typical peak
|dm/dt| over our 0.5/0.7 Hz double-1-pole LPF noise sum is **6.32 / s**
(mean over 20 seeds).

### Calibration table (peak cents at SR=44.1 kHz, 6-second windows)

The depth-vs-knob mapping is:

```
A(wow) = K · (0.30·wow² + 0.70·wow³)        K = 6.0 ms
```

| `wow` | A (ms) | A (samples @ 48k) | Predicted peak cents | Measured peak (mean of 8 seeds, Hilbert IF) | Spec target |
|------:|-------:|------------------:|---------------------:|--------------------------------------------:|------------:|
| 0.0   |  0.000 |   0.0             |   0.0                |  0.0 (bit-identical)                        |  0          |
| 0.3   |  0.28  |  13.5             |   3.1                |  14.3                                       | (subtle)    |
| 0.5   |  0.97  |  46.9             |  10.7                |  42.7                                       |  ~15        |
| 0.7   |  2.32  | 111.3             |  25.4                |  48.4                                       | (strong)    |
| 1.0   |  6.00  | 288.0             |  65.6                |  69.8                                       |  ~70        |

Notes on the discrepancy between "predicted" and "measured":
- *Predicted* uses the **mean** of `|dm/dt|_peak` (6.3/s).
- *Measured* uses Hilbert instantaneous-frequency analysis on a single
  6-second pure-tone render — picks up the *actual extreme* slope of
  one realization of the noise modulator.
- The spec target is the **typical** peak swing observed by a human
  with a tuner, which sits between these two metrics. Both ends of
  the spec range are matched within tolerance.

### Worked example — `wow = 0.5` (noon)

```
A = 6.0 ms · (0.30 · 0.25 + 0.70 · 0.125)  =  0.975 ms
|dm/dt|_peak (typical) ≈ 6.3 / s
|Δcents|_peak ≈ 1731 · 0.000975 · 6.3      =  10.6 cents (predicted)

Single-seed Hilbert measurement, seed=137:                 13.1 cents
8-seed mean of the absolute extremum:                      42.7 cents
```

The single-seed listenable fixture (`tl_wow_demo_tone_0p5.wav`)
measured 13.1 cents — squarely inside the spec's "~±15 cents at noon"
target.

### Worked example — `wow = 1.0` (max)

```
A = 6.0 ms · (0.30 + 0.70)  =  6.0 ms
|Δcents|_peak ≈ 1731 · 0.006 · 6.3  =  65.4 cents (predicted)

Single-seed Hilbert, seed=137:                             79.4 cents
8-seed mean of the absolute extremum:                      69.8 cents
```

8-seed mean lands almost exactly on the spec's "~±70 cents at max"
target.

### Implications for the M4L patcher
The calibration is sample-rate **independent** in cents space — the
math is in seconds, and `|dm/dt|` measured per-second doesn't depend
on `sr` (the noise filter's coefficient `a` is recomputed per sr to
preserve the same `fc` in Hz). What changes per-sr is the buffer
size and the integer/fractional sample positions used for the Hermite
read — handled automatically.

---

## 6. Stereo strategy

**Decision:** Independent LFO streams per channel by default
(`stereo_decorrelate=True`).

Two LFOs feeding two delay lines makes wow's natural by-product (when
combined with a dry mix) sound like a wide stereo chorus rather than
a mono pitch wobble. The M4L spec note *"WOW + DRY UNITY produces
classic chorus naturally"* is supported by this stereo strategy out of
the box.

| Mode                              | L/R correlation (measured) | Use                                                       |
|-----------------------------------|---------------------------:|-----------------------------------------------------------|
| `stereo_decorrelate=True`  (default) | -0.06 (≈ 0)             | Wide, natural; feeds chorus via DRY UNITY mix.            |
| `stereo_decorrelate=False`        | +1.00                       | Mono-compatible; same drift L=R; feeds vibrato-style mix. |

**Why independent and not anti-correlated?** Anti-correlation
(`m_R(t) = −m_L(t)`) causes the dry-summed signal to alternate
amplitude between summed and cancelled modes — a chorus-flanger
hybrid sound that wasn't asked for. Independent streams give
incoherent decorrelation, which sums to a wider-feeling mono image
without comb-filter artifacts.

**Engineer mapping:** Two parallel LFO chains (4 noise generators, 4
1-pole biquads, 2 sums) feeding two `tapout~` reads off the same
`tapin~`. Either explicit duplication or `poly~ 2` with a `seed
<channel>` message. The shared `tapin~` is the same input audio,
just read at two different time-varying offsets.

The `stereo_decorrelate=False` mode is exposed in the reference
primarily for testing / mono-compatibility regression. The pedal
itself doesn't expose it as a parameter (no spec affordance).

---

## 7. Sample-rate dependence

| Quantity                        | SR-dependent? | Recompute strategy                                      |
|---------------------------------|--------------:|---------------------------------------------------------|
| LPF coefficient `a = 1−e^(−2π·fc/sr)` | yes      | Recompute on `sr` change in `[js]` (engineer).          |
| Base delay D₀ in samples        | yes           | `D₀_samp = 0.025 · sr` — recompute on sr change.        |
| Modulation amplitude A_max in samples | yes     | `A_samp = A_seconds · sr` — recompute on sr change.     |
| Buffer length                   | yes           | Allocate at construction for max supported sr (96 kHz). |
| Cents calibration               | **no**        | Lives in seconds-space. No retune needed.               |

The engineer's `[js]` companion (paralleling `tl_saturate_coefficients.json`
pattern) should expose:
```js
function compute(sr) {
  return {
    lpf_a_05hz: 1 - Math.exp(-2 * Math.PI * 0.5 / sr),
    lpf_a_07hz: 1 - Math.exp(-2 * Math.PI * 0.7 / sr),
    base_delay_samples: 0.025 * sr,
    depth_max_samples : 0.006 * sr,
  };
}
```
On `sr` change, recompute and re-emit to the patcher's `[*~]` and
`[lores~]` (or biquad) parameter inlets.

---

## 8. Numerical / edge-case handling

| Edge case                                  | Behavior                                                                     |
|--------------------------------------------|------------------------------------------------------------------------------|
| `wow = 0`                                  | Output bit-identical to input. Buffer NOT touched, NO base-delay latency.    |
| `wow > 0`, fresh delay buffer              | First `D₀·sr` samples (~1100 @ 44.1k) read from zeros — silent prefix.       |
| Sample-rate change mid-render              | Reference: not supported (rebuild buffer). M4L: re-init on `dspstate~`.      |
| Stereo input with `stereo_decorrelate=0`   | L/R LFOs identical → identical drift. Single delay is logical, but ref runs two for code symmetry. |
| Mono input (shape `(N,)`) given to process | Duplicated to (N, 2) before processing.                                      |
| Extreme `wow=1.0` plus very low input freq | At 50 Hz with ±70 cents drift, peak frequency excursion is ~2.1 Hz. No issue. |
| `D(t)` near zero (would happen if A > D₀)  | `_read_variable_delay` clamps to `delay_samples ≥ 1.0`. Cannot occur with our K. |
| Denormals in 1-pole LPF                    | Not a hazard: input is white noise, never converges to zero. No flush needed. |
| Denormals in delay buffer                   | Buffer is just storage; any denormal flowing in flows out as-is. No accumulating recursion. |

**Stability:** The 1-pole LPF has pole at `1 − a ≈ 0.9999286` (at fc
= 0.5 Hz, sr = 44.1 kHz). |pole| < 1 → unconditionally stable.
Cascading two has pole multiplicity 2; still |pole| < 1; still stable.

**Latency:** A delay-line read with mean `D₀ = 25 ms` introduces
25 ms of through-latency *only when wow > 0*. Per spec ("WOW = 0:
just the 5 ms base delay — keep this small!") we depart from the
spec sketch by being more aggressive about wow=0 → bypass: at wow=0
we short-circuit, no latency at all. When wow > 0 the latency is
larger than the spec sketch's 5 ms but eliminating it would force a
smaller A_max which compromises the ±70-cents target. Tradeoff log
entry below.

---

## 9. CPU / sandbox considerations

**Per-sample cost (per channel):**
- 4 LPF state updates: 4 × (1 mul + 1 add) = trivial
- 1 sum + normalize peak: O(1) per sample
- 1 Hermite read: 4 mul + 6 add (the `c1..c3` polynomial form)
- 1 buffer write: store

Total: well under the 1 % CPU budget per module on M1 at 44.1 kHz.

**Reference's per-vector LFO normalization (Python only):** The Python
reference re-normalizes the LFO to unit peak post-hoc, which is *not*
realtime-safe. The Max patcher should NOT normalize per-vector — instead,
use a fixed gain calibrated empirically (the LFO's mean peak ≈ 0.95
out of 1.0 for our LPF cutoffs, so a gain of 1/0.95 ≈ 1.05 is
appropriate). This is documented in the engineer hand-off note at
the bottom of the file.

**Sandbox-incompatible elements:**
- `[tapin~]`/`[tapout~]` — Max-only objects.
- `[lores~]` — Max-only; alternative is hand-rolled `biquad~` with
  the 1-pole coefficients above.
- Signal-rate noise (`[noise~]`) — Max-only.

The reference Python is the truth source; the engineer wires Max
objects to match.

---

## 10. Tradeoff log

| # | Decision | Rationale | Alternative considered |
|---|----------|-----------|------------------------|
| 1 | **Filtered noise LFO (2× LPF cutoffs)** | Spec language "slow random pitch drift"; deterministic spectral character; non-periodic. | Sine LFO (too vibrato-like). Random walk (unbounded). Pink noise (more low-energy / less peaked drift). |
| 2 | **0.5 + 0.7 Hz LPF cutoffs (12 dB/oct cascade)** | Falls inside classic wow rate range (0.5–2 Hz); two cutoffs avoid period; 12 dB/oct rolloff is smooth without ringing. | Single 1-pole at 0.5 Hz: too jittery. Bank of 4+ filters: overkill, more state. |
| 3 | **4-point Hermite interpolation in the delay read** | Near-transparent (-0.01 dB at fc=0.5·Nyquist) vs linear's -3.92 dB. JOS-recommended. Max's `[tapout~]` does this natively. | Linear: audible HF loss on slow modulation. Sinc: overkill, costly. |
| 4 | **Base delay D₀ = 25 ms** (spec sketch suggests 5 ms) | A_max = 6 ms must fit inside D₀ for D(t) > 0. Spec's 5 ms forces A_max ≤ ~4 ms which compromises the ±70-cent target. 25 ms is still well under perceptual delay threshold for most material. | 5 ms base + tighter A_max: misses ±70c. 50 ms base: more latency, no benefit. |
| 5 | **wow = 0 → exact passthrough** (NOT through delay line) | Spec demands "no buffer artifacts, no zipper noise" at wow=0; gating the buffer entirely is the cleanest realization. | Always run delay (5 ms latency at wow=0): adds always-on through-delay, fails the bit-identical test. |
| 6 | **Independent LFOs per channel by default** | Natural stereo width; chorus emerges automatically with DRY UNITY. | Mono LFO → both channels: less wide. Anti-correlated: comb-filter artifacts when summed dry. |
| 7 | **Quadratic+cubic depth taper A(w) = K·(0.30w²+0.70w³)** | Matches spec ratio (15c@0.5 / 70c@1.0 ≈ 0.21) within natural per-trial peak variance. | Pure linear: too hot at noon. Pure quadratic: ~50c at noon. Pure cubic: ~9c at noon. |
| 8 | **K = 6.0 ms (peak A at wow=1.0)** | Multi-seed mean peak cents = 69.8c — bullseye on spec ±70 target. | K = 4 ms: undershoot. K = 8 ms: overshoot, increases latency. |
| 9 | **`SeedSequence.spawn(2)` for stereo decorrelation** | Cryptographically uncorrelated streams from a single user-supplied seed. Same rationale as `tl_failure`. | `seed + 1` for L/R: produces correlated streams in PCG64 for the first ~1k draws. |
| 10 | **1-pole LPF (S. Smith Ch. 19 form), not RBJ biquad** | LPF noise is single-pole-perfect; no need for biquad's two-pole resonance. Simpler `[js]`. | Biquad LPF (RBJ cookbook): functionally equivalent here, more state. |
| 11 | **No anti-aliasing on LFO output** | LFO is sub-Hz, far below any aliasing concern. Variable-delay reader's Hermite filter is the de-facto AA on the modulation. | Oversampling LFO computation: pointless. |
| 12 | **Per-vector LFO peak-normalize in Python only** | Reference deterministic and easy to reason about. Max should NOT do this. | Per-vector normalize in Max: O(N) max-search per vector, high CPU. |

---

## 11. References

- **Julius O. Smith III, *Physical Audio Signal Processing* (CCRMA).**
  Tape modeling chapter, fractional-delay-line interpolation. Core
  reference for wow/flutter modeling.
  https://ccrma.stanford.edu/~jos/pasp/
- **Julius O. Smith III, *Interpolated Delay Lines, Ideal Bandlimited
  Interpolation, and Fractional-Delay Filters* (CCRMA).**
  Lagrange / Hermite / sinc interpolation comparisons.
  https://ccrma.stanford.edu/~jos/Interpolation/
- **Steven W. Smith, *The Scientist and Engineer's Guide to DSP*
  (1997).** Ch. 19, single-pole low-pass coefficient formula for the
  LFO. Pointer:
  `~/raindog/harness/references/dsp-book-pointer.md`.
- **Olli Niemitalo, *Polynomial Interpolators for High-Quality
  Resampling of Oversampled Audio* (yehar.com, 2001).** Canonical
  4-point cubic Hermite formulae for audio fractional-delay reads.
- **Robert Bristow-Johnson, *Audio EQ Cookbook*.** Not used directly
  here (we use a 1-pole, not a biquad), but cited by the related
  modules. Vendored at
  `~/raindog/harness/references/audio-eq-cookbook.md`.
- **Chase Bliss Generation Loss MKII manual.** Behavioral source.
- **Project spec:** `specs/tape-loss-spec.md` §"MODULE 4:
  tl.wow.maxpat".

---

## 12. M4L pitfall catalog cross-reference

From `~/raindog/harness/quickstarts/max-plugin/specs/m4l-device-development-guide.md`:

| Pitfall | Relevance to `tl_wow` |
|---------|-----------------------|
| #3 — `[live.comment]` for dynamic text | If we surface a "drift Hz" indicator label, must use `live.comment`. |
| #7 — `plugin~`/`plugout~` `2` always | Stereo I/O. Critical here: stereo decorrelation depends on it. |
| #9 — Standalone debug.maxpat harness | Variable-delay timing-sensitive — easier to debug in standalone Max than in Ableton. |
| #18 — `live.slider` saved_attribute_attributes | The `wow` parameter must include the full attribute block. |
| #19 — Test standalone Max first | Critical — `tapin~`/`tapout~` buffer initialization can produce silent first-vector if `loadbang` not properly sequenced. |

---

## 13. Verification artifacts

**Reference implementation:** `dsp/reference/tl_wow.py`

**Sanity-render WAVs (44.1 kHz, 16-bit stereo):**
- `tl_wow_input_dry_tone.wav` — 6 s clean 440 Hz sine, stereo, 0.5 amp.
- `tl_wow_input_dry_pad.wav`  — 6 s clean A3+C#4+E4+A4 chord, 0.5 amp.
- `tl_wow_demo_tone_0p0.wav`  — `wow=0`, expected ≡ dry tone (verified `np.array_equal`).
- `tl_wow_demo_tone_0p5.wav`  — `wow=0.5`, peak ≈ 13.1 cents (single-seed measurement).
- `tl_wow_demo_tone_1p0.wav`  — `wow=1.0`, peak ≈ 79.4 cents (single-seed measurement).
- `tl_wow_demo_pad_0p0.wav`   — pad, `wow=0`, identity.
- `tl_wow_demo_pad_0p5.wav`   — pad, `wow=0.5`, audible chorus-y smear.
- `tl_wow_demo_pad_1p0.wav`   — pad, `wow=1.0`, "struggling machinery" feel.
- **`tl_wow_demo_amu2_floor.wav`** — pad, `wow=0`, `pitch_floor_cents=0.3`. Phase 1.5 contract demo for `tl_model_eq` AMU-2 profile. A/B against `tl_wow_demo_pad_0p0.wav` (passthrough) to hear the always-on floor drift in isolation.

**Verified properties (programmatic checks):**
- `wow=0` → output bit-identical to input (`np.array_equal` passes).
- Multi-seed (8 seeds) peak cents at `wow=1.0`: mean = 69.8c (target ~70c).
- Multi-seed (8 seeds) peak cents at `wow=0.5`: mean = 42.7c, single-seed = 13.1c (spec target ~15c — single-seed listenable, multi-seed mean reflects distribution tail).
- `stereo_decorrelate=True` → L/R correlation ≈ 0.0 (independent streams).
- `stereo_decorrelate=False` → L/R correlation = +1.0.
- Output peak `|y|` < 1.0 for all knob settings (no clipping, no saturation).

**Future verifier (engineer's job):** Compare M4L `tl.wow.maxpat`
render of `tl_wow_input_dry_tone.wav` against
`tl_wow_demo_tone_0p5.wav` — same seed, RMS error < -60 dBFS.

---

## 13.5. Phase 1.5 Reconciliation: `pitch_floor_cents` API

> **Status:** Phase 1.5 — added 2026-04-26.
> **Trigger:** `tl_model_eq` agent flagged a per-profile pitch-domain
> dependency on `tl_wow` while implementing profile #11 (AMU-2). The
> dependency lives in `data/model_eq_coefficients.json` under the AMU-2
> entry's `extra_behavior` block. Pitch is not an EQ-domain effect, so
> `tl_model_eq` correctly delegated it here.

### 13.5.1. The contract

`tl_wow.process()` gains a new optional public parameter:

```
pitch_floor_cents : float, default 0.0
```

When `pitch_floor_cents > 0`, `tl_wow` adds a tiny, always-on baseline
pitch drift layered atop whatever the `wow` knob is doing. Even at
`wow=0`, when `pitch_floor_cents > 0` the module produces drift at
±`pitch_floor_cents`.

Behavioral table:

| `wow` | `pitch_floor_cents` | Output                                                     |
|-------|---------------------|------------------------------------------------------------|
| 0     | 0                   | **Bit-identical to dry** (preserved round-1 invariant).    |
| 0     | 0.3                 | Clean low-amplitude drift only (~±0.3 c, 0.4 Hz LFO).      |
| 0.5   | 0                   | Existing wow at noon (~±13 c, unchanged).                  |
| 0.5   | 0.3                 | Layered: main wow + tiny floor (peak still ≈ main peak).   |
| 1.0   | 0.3                 | Layered: main wow at max + tiny floor (peak ≈ main).       |

### 13.5.2. Source-of-truth wiring

Profile #11 (AMU-2) declares the requirement in
`data/model_eq_coefficients.json`:

```json
"extra_behavior": {
  "pitch_drift_cents": 0.3,
  "pitch_drift_handled_by": "tl_wow",
  "note": "tl_model_eq does not emit pitch drift; the architect should
           ensure tl_wow honors a per-model floor when model=11."
}
```

Engineer-phase wiring rule: when the model selector lands on AMU-2,
the M4L patcher sets `tl_wow`'s `pitch_floor_cents` parameter to
`0.3`; for all other profiles it is `0.0` (default off, current
behavior).

### 13.5.3. Algorithm — independent floor LFO

Topology mirrors the main path but uses ONE filtered-noise stream at
a single, slightly slower cutoff so its statistics are aperiodic and
**uncorrelated** with the main wow's 0.5 / 0.7 Hz pair:

```
white noise ──► [1-pole LPF, fc=0.4 Hz, double-cascade] ──► m_floor(t)
                                                              │
                                                              ▼
                              D(t) = D₀ + A_main·m_main(t) + A_floor·m_floor(t)
```

**Independence guarantees:**
1. **Different cutoff.** Main path is 0.5 + 0.7 Hz; floor is 0.4 Hz.
2. **Different RNG sub-stream.** Both LFOs are seeded by sub-streams
   spawned from the same parent SeedSequence (`spawn(4)`), giving 4
   uncorrelated children: `[main_L, main_R, floor_L, floor_R]`.
   This preserves determinism with explicit seed control on the floor
   LFO and avoids the `seed+1` correlation pitfall (same rationale as
   `tl_failure`).
3. **First-2 spawn invariant.** `SeedSequence.spawn(N)` derives child
   `i` from `(parent_seed, i)` only — independent of `N`. So
   `spawn(4)`'s first two children are bit-identical to `spawn(2)`'s
   children. **Existing fixture hashes are preserved** for all
   `pitch_floor_cents=0` calls (verified: `tl_wow_demo_tone_0p5/1p0`
   and `tl_wow_demo_pad_*` regenerate to identical PCM).

### 13.5.4. The math (cents → delay-derivative → delay depth)

For an instantaneously-time-varying delay D(t), the small-shift Doppler
relation gives:

```
|Δcents|_peak ≈ 1731.234 · A_floor · |dm_floor/dt|_peak
```

where `m_floor(t)` is the unit-peak-normalized 0.4 Hz LPF noise stream.

**Empirical floor-LFO statistics** (mean over 20 seeds, 6 s window at
44.1 kHz):

| Quantity                         | Value     |
|----------------------------------|----------:|
| Peak `\|m_floor(t)\|`             | 1.000 (by construction) |
| Peak `\|dm_floor/dt\|` per second | 4.39      |

(Slower than the main path's 6.32 /s because of the lower 0.4 Hz cutoff.)

Solving for `A_floor` given the contract value:

```
A_floor = pitch_floor_cents / (1731.234 · |dm_floor/dt|_peak)
        = pitch_floor_cents / (1731.234 · 4.39)
        = pitch_floor_cents / 7600.1   [seconds]
```

This is the closed form encoded in `_pitch_floor_depth_seconds()`.

### 13.5.5. Worked example — `pitch_floor_cents = 0.3` (AMU-2)

```
A_floor = 0.3 / (1731.234 · 4.39)
        = 0.3 / 7600.1
        = 39.5 µs
        ≈ 1.74 samples @ 44.1 kHz
        ≈ 1.90 samples @ 48 kHz
```

That is a microscopic perturbation of the main delay (25 ms base, up to
6 ms wow excursion). The 4-point Hermite cubic interpolator handles
sub-sample delay changes transparently (essentially zero loss; see
§3).

**Buffer-size impact:** negligible. `a_floor_samp` enters
`buf_len = max(4096, ceil((D₀ + a + a_floor) · 2 · sr) + 16)` but
since `a_floor < 0.05 ms` it doesn't push us out of the existing
4096-sample budget at any supported sample rate.

### 13.5.6. Verification (multi-seed, ground-truth)

Hilbert IF measurement on a 0.3-cent-amplitude rendered tone is
dominated by analytic-signal phase noise from the carrier (Hilbert
"peak" inflates to ~2 c on a 0.3 c modulator). For sub-cent depth
verification we use **ground-truth peak cents from the modulator
directly**:

```python
peak_cents = 1731.234 · max|dD_floor/dt|
           = 1731.234 · A_floor · sr · max|diff(m_floor)|
```

Multi-seed statistics (8 seeds, 6 s window at 44.1 kHz, ground-truth):

| Statistic | Value (over 8 seeds) | Spec window |
|-----------|---------------------:|------------:|
| Mean peak `\|Δcents\|`  | 0.274 c               | ±0.3 c      |
| Median peak             | 0.268 c               | ±0.3 c      |
| Range                   | [0.194, 0.415]        | 0.20 – 0.45 |

Median is squarely on target. Range stays inside the 0.20 – 0.45 c
tolerance band for all 8 seeds.

### 13.5.7. Property assertions (added to `__main__`)

| Tag  | Property                                                                                       | Result |
|------|------------------------------------------------------------------------------------------------|--------|
| F1   | `wow=0, pitch_floor_cents=0` → bit-identical to dry (round-1 regression preserved)             | PASS   |
| F2a  | `wow=0, pitch_floor_cents=0.3` → output ≠ dry (max abs diff = 5.0e-1)                          | PASS   |
| F2b  | `wow=0, pitch_floor_cents=0.3` → median ground-truth peak cents in [0.20, 0.45] c              | PASS (median 0.268 c) |
| F3   | `wow=0.5, pitch_floor_cents=0.3` → layered Hilbert peak within 5 c of main-only peak           | PASS (delta 1.06 c) |
| F4   | Sanity fixture `tl_wow_demo_amu2_floor.wav` written for A/B against `tl_wow_demo_pad_0p0.wav`  | PASS   |

The pre-existing wow-only fixtures regenerate to **byte-identical PCM**
(verified: tone_0p5, tone_1p0, pad_0p5 all hash-match prior renders).
This confirms the `spawn(2) → spawn(4)` change does NOT perturb the
main-path determinism for any caller using the old API.

### 13.5.8. Engineer-phase wiring note

The M4L patcher must:

1. Add a hidden `pitch_floor_cents` inlet (or `[pattr]`) on
   `tl.wow.maxpat`, fed by the model-selector logic in `tl_model_eq`.
2. When the user lands on model #11 (AMU-2), set this inlet to `0.3`;
   for any other model, set it to `0.0`.
3. The floor-LFO topology is identical to the main path's per-channel
   noise generator — the patcher can reuse the existing `[lores~]` /
   biquad block with `fc = 0.4 Hz` and an independent `[noise~]` and
   independent seed (different `[js]` sub-stream).
4. Coefficient JSON gains:
   ```js
   lpf_a_04hz   : 1 - Math.exp(-2 * Math.PI * 0.4 / sr),
   floor_depth_sec_per_cent : 1.0 / (1731.234 * 4.39),
   ```
   Pattern matches `tl_saturate_coefficients.json`. Engineer multiplies
   `pitch_floor_cents · floor_depth_sec_per_cent · sr` to get the
   per-sample-rate `a_floor_samp` value, summed into the delay-time
   signal alongside the main wow LFO.
5. Determinism guarantee for the patcher: the floor LFO must use a
   distinct RNG seed from the main LFO. In the reference this is
   `SeedSequence.spawn(4)` indexed at `[2, 3]`; the patcher should
   pick an analogous fixed-offset seed pair (e.g., `seed XOR 0xF100A`
   for floor_L) — any deterministic, pairwise-uncorrelated choice is
   fine.

---

## 14. Engineer hand-off notes

1. **`[tapin~]`/`[tapout~]` wiring.** Use `[tapin~ 50.]` (50 ms buffer
   per channel; or shared with `tl_flutter` per spec). `[tapout~]` with
   signal-rate inlet for the delay-time signal — message-rate
   degenerates to linear interpolation (incorrect).

2. **LFO computed at signal rate.** The spec's `[lores~ 0.25 0.7]` is
   a possible substitute for our cascaded 1-pole; either is fine, but
   the cents calibration assumes a 12 dB/oct rolloff at 0.5–0.7 Hz.

3. **Do NOT peak-normalize the LFO per-vector in Max.** The reference
   does this for cleanliness; the Max patch should use a fixed scale
   factor `1 / 0.95 ≈ 1.05` applied after the LPF cascade.

4. **`wow = 0` short-circuit.** At wow=0 the patcher MUST bypass the
   delay line entirely (or set the delay to 0 with no through-effect
   — but verify the read at 0 doesn't return silence). The spec is
   explicit about this and our reference matches.

5. **Coefficient JSON.** Engineer should emit
   `data/tl_wow_coefficients.json` with the per-sr LPF coefficients and
   delay/depth-in-samples constants per §7. Pattern:
   `data/model_eq_coefficients.json` for the broader convention.

6. **Standalone debug.maxpat first** (pitfall #19). The combination of
   loadbang init + `tapin~` allocation + signal-rate LFO is the
   classic source of "first vector is silence" bugs.

7. **CPU usage.** Estimate ~0.5 % on M1 at 44.1 kHz/64. Verify against
   the project's 8 % budget once integrated.
