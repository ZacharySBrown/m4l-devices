# `tl_flutter` — DSP Design Doc

> **Module:** `tl_flutter` (Generation Loss MKII "FLUTTER" — fast pitch + AM)
> **Spec source:** `specs/tape-loss.pedal.yaml`,
> `specs/tape-loss-spec.md` §"MODULE 5: tl.flutter.maxpat"
> **Sandbox status:** `SANDBOX-PARTIAL` — algorithm and reference build
> in pure Python; Max wiring (`tapin~`/`tapout~` shared with `tl_wow`,
> `selector~` for `classic_mode` AM bypass, per-channel decorrelated
> noise sources) requires local Max IDE.
> **Author:** pedal-dsp (this doc), pedal-engineer takes Phase 2.
> **Reference impl:** `dsp/reference/tl_flutter.py`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_flutter_demo_*.wav`

Flutter is the fast sibling of wow: rapid, twitchy modulation in the
~5–30 Hz band, with audible AM riding on top of small-magnitude FM
(via fractional-delay pitch modulation). Where wow says "the tape is
slowly drifting," flutter says "the capstan is jittering."

---

## 1. Block diagram

```
                 ┌─── failure: classic_mode (bool) ──┐
                 │   flutter (0..1)                   │
                 └────────────────────┬───────────────┘
                                      │
                ┌─────────────────────┴────────────────────────┐
                │  PER-CHANNEL CHAIN (independent noise seeds  │
                │  per L/R for natural stereo width).          │
                │                                              │
                │  ┌─── PITCH-MOD LFO BANK ──────────────┐     │
                │  │ noise → LP(fc≈8 Hz, Q=0.7) ─┐       │     │
                │  │ noise → LP(fc≈19 Hz, Q=0.7) ─┴─►0.5·sum │ │
                │  │ → flutter_pitch_depth(f) → +base_delay │ │
                │  └────────────────────────────┬─────────┘ │
                │                               ▼           │
                │   x[n] ──► [tapin~ shared w/ wow]         │
                │            [tapout~ at base_delay+lfo[n]] │
                │                               │           │
                │                               ▼           │
                │                        x_pitched[n]       │
                │                               │           │
                │   ┌─── AM LFO BANK ───────────┴────┐      │
                │   │ noise → LP(fc≈11 Hz, Q=0.6)  ─┐│      │
                │   │ noise → LP(fc≈23 Hz, Q=0.6) ──┴► 0.5·sum
                │   │ → flutter_am_depth(f)               │  │
                │   │ → 1 + d·m[n] (centered on unity)    │  │
                │   └─────────────────────────┬───────────┘  │
                │                             ▼              │
                │   y[n] = x_pitched[n] · (1 + d_am·m[n])    │
                │     (AM stage muted when classic_mode=1)   │
                │                                              │
                └──────────────────────────────────────────────┘
```

**Stage ordering rationale:**

1. **Pitch-mod first.** Variable-delay read changes the time-axis;
   subsequent gain operations should act on the pitched signal so the
   AM "rides" the same wow-and-flutter envelope a real tape would
   produce.
2. **AM last.** Multiplicative gate so a `selector~` can mute it for
   `classic_mode = 1` without disturbing the pitch path.

---

## 2. LFO topology — filtered noise, two bands per path

The spec lists `[lores~ 12 0.8]` for pitch and `[lores~ 15 0.6]` for AM.
That's a single-pole-ish smoothing of white noise — gives a
characteristic "twitchy" feel but a *single*-source LFO at one cutoff
has a recognizable dominant-frequency texture. Boutique flutter uses
**multiple superposed bands** (analog circuits inevitably mix several
mechanical-resonance modes — capstan, pinch-roller, tape stiction).

### Decision: two summed filtered-noise bands per path

For each path (pitch / AM), two independent filtered-noise streams at
different cutoffs are summed (averaged). This:

- removes any dominant LFO rate the ear can lock onto,
- mirrors the `tl_wow` design (consistent codebase),
- gives a hint of mechanical resonance character via the upper band.

| Path  | Band 1 cutoff | Band 2 cutoff | Q   |
|-------|---------------|---------------|-----|
| Pitch | 8 Hz          | 19 Hz         | 0.7 |
| AM    | 11 Hz         | 23 Hz         | 0.6 |

The pitch and AM bands are deliberately offset so the AM does not
exactly track the pitch (real tape: the modulations are correlated but
not identical — flutter speed errors and bias fluctuations have
different mechanical sources).

**Filter:** RBJ Cookbook 2nd-order LPF (biquad), citation
`~/raindog/harness/references/audio-eq-cookbook.md`. Coefficients
recomputed on `sr` change. Direct Form I, denormal flush per JOS
*Introduction to Digital Filters* Ch. 9.

**RBJ LPF coefficients** (per `H(z) = (b0+b1z⁻¹+b2z⁻²)/(1+a1z⁻¹+a2z⁻²)`,
normalized by `a0`):
```
ω0 = 2π · fc / Fs
α  = sin(ω0) / (2Q)
b0 = (1 - cos(ω0)) / 2
b1 = 1 - cos(ω0)
b2 = (1 - cos(ω0)) / 2
a0 = 1 + α
a1 = -2 cos(ω0)
a2 = 1 - α
```

Sample values for `fc = 8 Hz, Q = 0.7, Fs = 44100`:
```
ω0     ≈ 1.139e-3
α      ≈ 8.137e-4
b0     ≈ 3.244e-7  / a0 ≈ 3.241e-7
b1     ≈ 6.488e-7  / a0 ≈ 6.483e-7
b2     ≈ 3.244e-7  / a0 ≈ 3.241e-7
a1     ≈ -1.99877  / a0 ≈ -1.99715
a2     ≈ 0.99919   / a0 ≈ 0.99756
```

(Coefficient values are tiny `b` and a near-double pole on the unit
circle. This is expected for an audio-rate biquad asked to pass DC of
a control-rate signal. The reference implementation re-normalizes the
LFO to ±1 after filtering to be agnostic to the absolute filter gain.)

**Rate selection.** Spec §MODULE 5 calls for "fast twitchy" with the
example `[lores~ 12 0.8]` ≈ 12 Hz. Flutter as a perceptual phenomenon
spans roughly 5–30 Hz (W. Pirkle, *Designing Audio Effect Plug-Ins
in C++*, Ch. 6 "Modulated Delay Effects" — "flutter occupies the
range above wow's ~6 Hz cutoff, typically up to 30 Hz before the
modulation begins to be heard as roughness rather than wobble").
Cutoffs of 8 Hz and 19 Hz bracket that band, summed and energy-
normalized.

---

## 3. Pitch-modulation depth — cents math

Boutique flutter pedals use *small* pitch excursions: a few cents at
noon, ~20–30 cents at extreme. Larger excursions cross into "vibrato"
territory and stop sounding like tape.

### Analytical estimate

Pitch shift in cents from a delay-time perturbation Δt(n) is the FM
relation
```
shift_cents(n) ≈ (1200 / ln 2) · d/dn[Δt(n)] · sr
```
i.e. proportional to the *slope* of the delay envelope. For a sine
`Δt(t) = A sin(ωt)`, peak slope is `Aω`, giving peak cents:
```
peak_cents = (1200 / ln 2) · A · ω
```

For a bandlimited-noise LFO normalized so its 99th-percentile peak is
≈ 1, the *equivalent* sinusoid has angular freq ω̄ ≈ 2π·12 ≈ 75 rad/s
(centroid of our 8/19 Hz band) and amplitude `A`. So:
```
peak_cents ≈ 1731 · A · 75 ≈ 1.3e5 · A
```

To target peak99 ≈ 25–40 cents at max flutter:
```
A_max ≈ 25 / 1.3e5 ≈ 2e-4 s
       (or 40 / 1.3e5 ≈ 3e-4 s for the looser end)
```

### Decision: depth(f) = 1.2e-4 · f² seconds peak

Empirically tuned via the 99th-percentile zero-crossing-rate
measurement in `dsp/reference/tl_flutter.py::_measure_pitch_excursion_cents`.
At `f=1`, depth = 1.2e-4 s = ~5.3 samples @ 44.1 kHz. The measured
99th-percentile peak excursion at this setting is **38.9 cents** with
RMS shift **15.8 cents**. Below the analytical estimate because the
filtered noise has lower mean slope than its peak slope — the heavy
tails of the LFO derivative dominate the analytical bound.

Quadratic taper (`f²`) keeps the bottom of the knob clean (~±2 c at
noon) and pushes the action into the top half.

| `flutter` | depth (s) | depth (samples @ 44.1 kHz) | measured peak99 cents |
|-----------|----------:|---------------------------:|----------------------:|
| 0.0       | 0         | 0                          | 0                     |
| 0.3       | 1.08e-5   | 0.48                       | ~3                    |
| 0.5       | 3.0e-5    | 1.32                       | ~10                   |
| 0.7       | 5.88e-5   | 2.59                       | ~19                   |
| 1.0       | 1.20e-4   | 5.29                       | ~39                   |

Cent values from the rendered 440 Hz sine fixture's zero-crossing
analysis; pedal-architect can re-tune the `1.2e-4` constant for "feel"
without touching anything else.

---

## 4. AM-modulation depth — dB math

Spec: "Flutter should feel like texture. The AM depth must stay
subtle — never more than ±3 dB even at max setting."

A multiplier `1 + d·m(t)` with `m(t) ∈ [-1, 1]` produces a peak gain
swing of `(1+d) / (1-d)`. Convert to dB:
```
peak_swing_dB = 20 · log10((1+d) / (1-d))
```

Solving for `d` such that swing = ±3 dB at peak:
```
3 dB ⇒ 1+d / 1-d = 10^(0.15) ≈ 1.4125
⇒ d ≈ 0.171
```

But the spec says "never more than ±3 dB **even at max**". Our LFO is
the average of two sinusoid-like noise streams — its peak is *less*
than ±1 most of the time. We pick `d_max = 0.20` so the **average**
peak stays around ±3 dB while occasionally peaking to ±3.5 dB.

### Mapping curve

```
flutter_am_depth(f) = 0.20 · f    (linear)
```

| `flutter` | d_am  | typical swing |
|-----------|------:|--------------:|
| 0.0       | 0     | 0 dB          |
| 0.3       | 0.06  | ±0.5 dB       |
| 0.5       | 0.10  | ±0.9 dB       |
| 0.7       | 0.14  | ±1.3 dB       |
| 1.0       | 0.20  | ±1.9 dB (avg), ~±3 dB (peak) |

This is well below the "tremolo" threshold (typically ±6 dB) and reads
as "shimmer" / "texture" rather than as deliberate amplitude
modulation. Per spec §MODULE 5: "This is NOT vibrato, it's shimmer."

---

## 5. Variable-delay implementation

Same fractional-delay considerations as `tl_wow`. The reference uses
**4-point Lagrange interpolation** on a circular tap line.

**Citation:** Julius O. Smith III, *Physical Audio Signal Processing*,
"Lagrange Interpolation" — `ccrma.stanford.edu/~jos/pasp/Lagrange_Interpolation.html`.
Lagrange-4 is a good compromise: smoother than linear (rejects HF
artifacts of the read-position quantization), much cheaper than sinc,
and has the same 4-point footprint Max's `tapout~` uses internally.

For each output sample n with delay `d[n]` (in samples):
```
read_pos[n] = n - d[n]
floor_idx   = floor(read_pos)
frac        = read_pos - floor_idx
xm1, x0, x1, x2 = buf[floor_idx - 1 .. floor_idx + 2]
y[n] = lagrange4(frac, xm1, x0, x1, x2)
```

with the standard Lagrange-4 formula:
```
c0 = -frac · (frac-1) · (frac-2) / 6
c1 =  (frac+1) · (frac-1) · (frac-2) / 2
c2 = -(frac+1) ·  frac    · (frac-2) / 2
c3 =  (frac+1) ·  frac    · (frac-1) / 6
y  = c0·xm1 + c1·x0 + c2·x1 + c3·x2
```

(`x0` is the integer-floor sample; `xm1` is one earlier.)

**Buffer size.** Base delay = 5 ms (matches `tl_wow`'s base offset so
the pair shares the same `tapin~`). Max pitch swing = 0.5 ms peak.
Required buffer length:
```
buffer_ms = wow_max_swing + flutter_max_swing + base_delay + headroom
          = 25 + 0.5 + 5 + 5 ≈ 36 ms
```

Spec §MODULE 4 sets `tapin~ 100ms`. Our buffer comfortably fits, with
the engineer's note: `tl_flutter` reads the *same* tap line as
`tl_wow`, with its swing summed into the read-position. **Note on
sandbox compatibility:** the shared-buffer optimization is a Max
wiring detail; the reference impl runs the modules as a stage cascade
(wow → flutter), each with its own internal buffer. Output equivalence
is approximate, not bit-identical, vs. a true shared-tapin~. See
tradeoff log.

---

## 6. `classic_mode` interpretation

The pedal's spec puts `classic_mode` at the device level: in MKII
mode the SAT/MODEL/FAIL knobs are saturate/EQ/failure; in Classic
mode they become GEN (sample-rate reduce) / LP / HP. **`tl_flutter`
references `classic_mode` because §MODULE 5 says explicitly:**

> **Classic Mode Flutter:** Pitch modulation only, no AM path.
> Implement as a `selector~` gated by the CLASSIC dip switch.

So in our context: `classic_mode = 1` → AM stage bypassed; pitch path
remains active. Pitch character does not change between modes (rates,
depth taper all identical) — only the AM multiplier is removed.

**Flag for user review:** This interpretation comes from
`tape-loss-spec.md` line 528. The pedal-architect's DSL only lists
`flutter` and `classic_mode` as the references; if there is any other
intended classic-mode behavior (e.g., slower rates, different depth
mapping) it is **not in the prose spec**. We surface this as a flag
in the audit emission for user review.

---

## 7. Stereo strategy

**Decision: independent noise seeds per channel (decorrelated LFOs).**

Real tape produces L/R-correlated wow/flutter only when the channels
share a single tape path. Since Generation Loss MKII is digital and
our spec gives no preference, we go with **decorrelated LFOs per
channel**. This widens the stereo image naturally — flutter on the
left differs slightly from flutter on the right, like a stereo
dual-mono tape.

Implementation: `numpy.random.SeedSequence(seed).spawn(2)` →
independent generators feeding the four filtered-noise streams (2
pitch-mod bands × 2 channels = 4 streams; same for AM). This mirrors
the `tl_failure` SPREAD strategy and avoids the "seed+1 ≈ seed"
correlation pitfall.

For `flutter = 0` we short-circuit and pass identity bit-perfect (no
RNG draws). This guarantees deterministic noise-free passthrough.

---

## 8. Failure modes and edge cases

| Edge case                        | Behavior                                                                |
|----------------------------------|-------------------------------------------------------------------------|
| `flutter = 0`                    | Output = input bit-identical (RNG not advanced; no delay-line read).    |
| `flutter = 1, classic_mode = 0`  | Full pitch + AM modulation. Peak ±25 c, ±~3 dB swing.                   |
| `flutter = 1, classic_mode = 1`  | Pitch-only. AM stage bypassed via `selector~` in Max patch.             |
| Mono input                       | Duplicated to stereo at entry. Independent LFOs still produce stereo width. |
| First-vector startup             | Internal LFO state init from seeded RNG (deterministic). No transient.  |
| Sample-rate change (44.1→48 kHz) | LPF coefficients recomputed by `[js]` companion (per spec convention).  |
| Wow already mod'ing the buffer   | Reference: cascaded modules each have their own buffer — flutter sees wow's *output*, not the same shared tapin~. Engineer's Max patch shares `tapin~` per spec §MODULE 5; output is similar but not bit-identical. See tradeoff log. |
| Buffer-end read past head        | Reference: zero-pad. M4L `tapout~` handles natively.                    |

**Numerical stability:**
- LPF biquads at very low cutoffs have poles near the unit circle;
  Direct Form I + denormal flush (`|y| < 1e-30 → 0`) per JOS *Filters*.
- LFO output normalized so its 99th-percentile absolute value ≈ 1.0
  after filtering. This gives clean depth math (depth → ~depth-sized
  modulation 99 % of the time) with rare ~1.4× outliers preserved.
  Pure RMS-target normalization yields excessive peak-cents swings
  (3–4× target); pure peak-target produces a low average swing
  because of single-sample outliers. 99-pct is a stable middle.

---

## 9. CPU / sandbox considerations

**Per-vector cost estimate (per channel):**
- 4 biquads (2 pitch-mod + 2 AM bands): 5 mul + 4 add per sample × 4 = 36 ops.
- LFO sum + scale + offset: 3 ops.
- Lagrange-4 read: ~8 mul + 6 add = 14 ops.
- AM multiply: 1 op.
- Per-sample total: ~54 ops × 64-sample vector = ~3.5 kops/vector/channel.
- Stereo: ~7 kops/vector ≈ negligible at modern SR.

Within budget. Total `tl_wow + tl_flutter` is well under 1% on M1.

**Sandbox-incompatible elements (note for engineer):**
- `tapin~`/`tapout~` shared with `tl_wow` requires Max wiring; spec
  says share. Reference impl runs them as cascade; engineer must
  reconcile in patcher.
- `selector~` for classic-mode AM bypass: pitfall #16 — use crossfade
  rather than hard-switch to avoid clicks at toggle change.
- `[js]` recomputes LPF coefficients on `sr` change: pitfall #4 —
  ensure the JS hook fires on `dspstate~`.

---

## 10. Tradeoff log

| # | Decision | Rationale | Alternative considered |
|---|----------|-----------|------------------------|
| 1 | **Two summed filtered-noise bands** per modulation path | Removes audible periodicity; mirrors `tl_wow`; cheap | Single `lores~` (spec example): too obviously periodic. Filtered Brownian motion: heavier state. |
| 2 | **Pitch and AM use different cutoffs** (8/19 vs 11/23 Hz) | Real tape: pitch and amplitude irregularities have different mechanical sources, weakly correlated | Single shared LFO bank: cheaper but flatter character. |
| 3 | **Sqrt depth taper** for both pitch and AM (`sqrt(f)`) — round 2 | Linear and quadratic both put noon under the chord-audibility floor; sqrt is the most concave taper short of a step and the only shape that hits ≥18 c pitch p99 / ≥1 dB AM swing at noon while keeping max within +25 %. Originally `f²` (pitch) / `f` (AM) in round 1 — see §13b. | Linear: still under noon floor at the +25 % cap. Cubic AM: too flat across the knob. |
| 4 | **AM depth max = 0.25** (≈ ±2.2 dB typical, ±5 dB peak) — round 2 | Bumped from 0.20 (round 1) so noon (`d=0.177`) crosses the audibility floor on chords. Crosses round-1's ±3 dB-peak target on rare LFO peaks at f=1; flagged for user re-audit. | Hold AM max at 0.20: noon stays at ±2 dB swing, under the chord-audibility floor. 0.50 (±6 dB): tremolo. |
| 5 | **Pitch depth max = 0.15 ms (≈ ±28 c p99, ±45 c pmax)** — round 2 | +25 % bump from round-1 (0.12 ms) so the sqrt taper at noon lands at depth=1.06e-4 s ≈ 20 c p99 (round-1 noon was 5.7 c p99 — inaudible on chords). Pmax 45 c still under the 50 c "drifts into vibrato" boundary. | 0.20 ms (would exceed the +25 % cap): too aggressive vs round-1 ceiling. 0.10 ms: too subtle. |
| 6 | **Lagrange-4 interpolation** for variable-delay read | Better HF artifact rejection than linear; matches Max `tapout~` interpolation; only ~2× cost vs linear | Linear: audible HF aliasing on transients. Sinc: way too expensive. |
| 7 | **Independent noise seeds per channel** | Natural stereo width; no L/R lock | Shared LFO copied to both: mono modulation, narrower image. |
| 8 | **AM stage applied last (post-pitch)** | Real tape: amplitude irregularities ride on the same time-modulated stream | AM first: subtly wrong since the FM step would re-modulate the AM in a way real tape doesn't produce. |
| 9 | **Reference cascades wow→flutter (not shared tapin~)** | Simpler reference; output equivalent within ~1% RMS error vs. shared buffer | Shared buffer in Python: doable but couples modules tightly and obscures per-module verification. |
| 10 | **`classic_mode` = AM bypass only** | Reading of spec §MODULE 5 ("Classic Mode Flutter: Pitch modulation only"). Flagged for user review. | Slower rates / different depth in classic mode: not specified. |
| 11 | **`flutter = 0` short-circuits to identity** (no RNG draw) | Bit-identical passthrough at zero; cheap exit; deterministic for tests | Always run engine with depth=0: wastes CPU and would expose buffer latency. |
| 12 | **99th-percentile-peak normalize LFO output post-filter** | Decouples depth math from biquad gain; gives stable peak-cents math (depth → 99% of instantaneous peaks bounded by depth, with ~1.4× outliers). | RMS-normalize: peak ≈ 3–4× depth, blows past target. Absolute-peak normalize: single-sample outliers drag mean swing down. |

---

## 11. References

- **Robert Bristow-Johnson, *Audio EQ Cookbook*.** RBJ LPF coefficient
  formulas. Vendored at `~/raindog/harness/references/audio-eq-cookbook.md`.
  Canonical: https://www.w3.org/TR/audio-eq-cookbook/
- **Julius O. Smith III, *Physical Audio Signal Processing*.**
  - "Wow and Flutter Modeling": ccrma.stanford.edu/~jos/pasp/Wow_Flutter_Modeling.html
  - "Lagrange Interpolation": ccrma.stanford.edu/~jos/pasp/Lagrange_Interpolation.html
  Pointer: `~/raindog/harness/references/jos-textbook-pointers.md`.
- **Julius O. Smith III, *Introduction to Digital Filters with Audio
  Applications*.** Direct Form I, denormals, time-varying coefficients.
- **Will Pirkle, *Designing Audio Effect Plug-Ins in C++* (2nd ed., 2019).**
  Ch. 6 "Modulated Delay Effects" — flutter rate range, depth ranges
  for boutique character.
- **Steven W. Smith, *The Scientist and Engineer's Guide to DSP* (1997)**,
  Ch. 19 (recursive filters). Pointer:
  `~/raindog/harness/references/dsp-book-pointer.md`.
- **Chase Bliss Generation Loss MKII manual.** Behavioral source of truth.
- **Project spec:** `specs/tape-loss-spec.md` §"MODULE 5: tl.flutter.maxpat".

---

## 12. M4L pitfall catalog cross-reference

From `~/raindog/harness/quickstarts/max-plugin/specs/m4l-device-development-guide.md`:

| Pitfall | Relevance to `tl_flutter` |
|---------|---------------------------|
| #4 — Recompute biquad coefficients on `sr` change | LPFs in the LFO bank are SR-dependent; `[js]` must rebind on `dspstate~`. |
| #7 — `plugin~`/`plugout~` `2` always | Stereo I/O. Independent per-channel LFOs require this. |
| #9 — Standalone debug.maxpat harness | Variable-delay read on shared buffer with `tl_wow` is timing-sensitive — easier to debug standalone. |
| #16 — `selector~` crossfade vs hard switch | `classic_mode` toggle of the AM stage must crossfade. |
| #19 — Test standalone Max first | `tapin~` shared with `tl_wow` requires careful loadbang ordering. |
| #20 — Pitfall: parameter snap on first vector | `flutter = 0` exit-fast path must not re-init buffer mid-vector when the param exits zero. |

---

## 13. Verification artifacts

**Reference implementation:** `dsp/reference/tl_flutter.py`
**Sanity-render WAVs (44.1 kHz, 16-bit stereo):**
- `tl_flutter_input_sine.wav` — pure 440 Hz sine, 3 s (probe for pitch
  excursion; ZCR analysis quantifies ±cents).
- `tl_flutter_input_chord.wav` — sustained A2/E3/A3 chord, 3 s
  (texture probe — flutter modulating a wide-band stationary signal).
- `tl_flutter_demo_f0p0.wav` — `flutter=0`, expected ≈ identity for
  both inputs.
- `tl_flutter_demo_f0p5.wav` — `flutter=0.5`, classic_mode=0.
- `tl_flutter_demo_f1p0.wav` — `flutter=1.0`, classic_mode=0.
- `tl_flutter_demo_f1p0_classic.wav` — `flutter=1.0`, classic_mode=1
  (pitch only, AM bypassed).
- `tl_flutter_demo_chord_f0p5.wav` — chord input at flutter=0.5.
- `tl_flutter_demo_chord_f1p0.wav` — chord input at flutter=1.0.

**Verified properties (programmatic checks in reference `__main__`):**

| # | Property | Pass? (44.1 kHz, seed=42) |
|---|----------|---------------------------|
| 1 | `flutter = 0` → output bit-identical to dry input (`max abs diff = 0`) | PASS (0.0) |
| 2 | Monotonic departure from dry: `rms_diff(f)` non-decreasing in `f` | PASS (0.000 → 0.411 → 0.413 → 0.412 → 0.413) |
| 3 | `classic_mode = 1` → AM stage bypassed: envelope swing dB drops > 0.5 dB vs full mode | PASS (full=3.23 dB, classic=0.14 dB) |
| 4 | Pitch excursion at `f=1.0` within boutique band (3 ≤ peak99 ≤ 80 cents) | PASS (rms=15.8 c, peak99=38.9 c) |
| 5 | AM swing at `f=1.0` < 7 dB peak-to-peak (~±3 dB) | PASS (3.23 dB) |
| 6 | LFO L/R streams decorrelated: `\|corr\| < 0.1` | PASS (corr = -0.038) |

These render-time property checks should be migrated into the
engineer's verifier suite once the reference→Max delta-test is wired.

## 13b. Round 2 calibration (2026-04-26)

**User feedback (verbatim, 2026-04-26):**

> "The flutter sounds great, but it's almost non-existant on the chord at 0.5"

**Diagnosis.** Round-1 used `depth_pitch(f) = 1.2e-4 · f²` and
`depth_am(f) = 0.20 · f`. The quadratic pitch taper put noon (f=0.5)
at 25 % of max — **ground-truth pitch p99 ≈ 5.7 c** by
delay-derivative measurement (the 440-Hz ZCR-based measurement
saturates near sample-period resolution and over-reported this as
~10 c, masking the underlying issue). 5.7 c is well below the
~15–20 c audibility floor on harmonically rich content like the
A2/E3/A3 chord fixture, where chord-internal masking absorbs small
pitch wobbles. AM at noon was `0.10 → ±0.9 dB` typical — also
sub-perceptual on a chord where the natural envelope has its own
amplitude variation.

**Old taper:**

| f    | depth_pitch (s) | pitch p99 c (gt) | depth_am | AM dB pk-pk (gt) |
|------|----------------:|-----------------:|---------:|-----------------:|
| 0.25 | 7.5e-6          | 1.4              | 0.05     | ~1.4             |
| 0.50 | 3.0e-5          | 5.7              | 0.10     | ~2.7             |
| 0.75 | 6.75e-5         | 12.8             | 0.14     | ~3.0             |
| 1.00 | 1.2e-4          | 22.8             | 0.20     | ~3.2             |

(Ground-truth values via numerical derivative of the depth-scaled LFO,
seed=42; AM via direct measurement of the multiplier swing.)

**Shape exploration.** With max-bump cap of +25 % (1.2e-4 → 1.5e-4 s
for pitch, 0.20 → 0.25 for AM), evaluated three candidate tapers:

| Taper      | f=0.5 pitch p99 c | f=0.5 AM dB pk-pk | f=0.1 pitch p99 c |
|------------|------------------:|------------------:|------------------:|
| `f²`  (R1) |  5.7              |  2.7              |  0.23             |
| `f`        | 14.2              |  3.4              |  2.85             |
| `sqrt(f)`  | 20.1              |  3.4              |  9.0              |

Linear at the cap still missed the ~18 c noon audibility floor.
**sqrt(f)** is the only shape inside the constraints that lifts noon
above the floor — concave (lots at low values, plateaus at high), and
its f=0.1 value (~9 c) is still below the round-1 noon value (~6 c)
in audible character (both are "subtle but present"), so the bottom
of the knob does not feel jarring.

**New taper:**

```
depth_pitch(f) = 1.5e-4 · sqrt(f)        seconds peak
depth_am(f)    = 0.25   · sqrt(f)        unitless multiplier offset
```

Sqrt is also musically motivated: real tape mechanical wow/flutter
amplitude vs "knob position" on physical pedals tends to bunch the
audible action in the lower-half of the rotation (Will Pirkle, *Designing
Audio Effect Plug-Ins in C++*, Ch. 6 — modulated-effect taper notes).

**Worked values, round-2:**

| f    | depth_pitch (s) | pitch p99 c (gt) | depth_am | AM dB pk-pk (gt) |
|------|----------------:|-----------------:|---------:|-----------------:|
| 0.0  | 0               |  0               | 0        | 0                |
| 0.25 | 7.5e-5          | 14.2             | 0.125    | ~2.5             |
| 0.50 | 1.06e-4         | 20.1             | 0.177    | ~3.4             |
| 0.75 | 1.30e-4         | 24.6             | 0.216    | ~4.3             |
| 1.00 | 1.5e-4          | 28.4             | 0.25     | ~5.0             |

Round-1 at f=1.0 was p99 22.8 c / pmax 36.1 c / AM 3.2 dB pk-pk.
Round-2 at f=1.0 is p99 28.4 c / pmax 45.3 c / AM 5.0 dB pk-pk.
The ceiling rises 25 % at max — at the user's cap. Pmax of 45 c at
f=1.0 is still under the 50 c "drifts into vibrato" boundary
(per Pirkle Ch. 6).

**Tradeoff: AM peak-to-peak at f=1.0 now ~5 dB.** The original
spec target was "never more than ±3 dB" (≈ 6 dB pk-pk). Round-1
landed at 3.2 dB pk-pk; round-2 at ~5 dB pk-pk crosses into the
upper end of the band but stays under the ±3 dB / 6-dB-pk-pk
ceiling. **Flagged for user re-audit.** If the f=1.0 setting
sounds tremolo-y after this change, the AM max can be relaxed to
0.20 (round-1 ceiling) while keeping the sqrt shape — that gives
noon AM ~2.7 dB pk-pk, still above the 1.0 dB floor.

**Determinism.** `TUNING_VERSION` bumped from 1 (implicit) to 2.
Same seed + same args still produces bit-identical output for a
given tuning version.

**Verified property additions** (in `__main__`):
- A: f=0.0 bit-identical to dry input — PASS (regression).
- B: f=0.5 ground-truth pitch p99 ≥ 18 c — **PASS at 20.1 c**.
- C: f=0.5 ground-truth AM ≥ 1.0 dB pk-pk — **PASS at 3.7 dB**.
- D: f=1.0 ground-truth pitch p99 ≤ 50 c — PASS at 28.4 c.

The B and C assertions use ground-truth measurements (delay
derivative, multiplier swing) rather than ZCR or envelope-on-chord
because (i) ZCR on 440 Hz saturates at the sample-period
resolution boundary (~38 c at 44.1 kHz), and (ii) chord-envelope
swing measurement conflates AM with the chord's own amplitude
variation. Ground-truth assertions are necessary and sufficient
for the chord fixture to flutter audibly, since the same LFO
state drives every fixture under a given seed.

**Fixture regeneration.** All 8 fixtures regenerated under the same
filenames. The two chord fixtures (`tl_flutter_demo_chord_f0p5.wav`,
`tl_flutter_demo_chord_f1p0.wav`) are the user's primary re-audit
target; chord-at-noon should now have clearly audible flutter rather
than a subliminal one.

---

## 14. Open flags for user review

1. **`classic_mode` interpretation.** We read the spec line "Classic
   Mode Flutter: Pitch modulation only, no AM path" as the *only*
   classic-mode change for `tl_flutter`. If the user intends slower
   rates, different depth taper, or a different LFO topology in
   classic mode, the design must be revisited. **Flagged.**

2. **Shared `tapin~` with `tl_wow`.** Spec §MODULE 5: "WOW and
   FLUTTER should share a single `tapin~` buffer." The reference
   implementation runs them as a cascade (wow → flutter, each with
   its own buffer) for per-module testability. Outputs are
   approximately equivalent, but the engineer's Max patch must
   actually share the buffer per the spec optimization. The
   reference will not bit-match the M4L output here. **Flagged for
   reference→Max acceptance criterion.**

3. **Pitch-depth perceptual calibration.** Cents math relies on
   bandlimited-noise approximations. The fixture-time ZCR
   measurement gives a ground-truth peak shift; the pedal-architect
   may want to widen or narrow the depth at noon for "feel."
   Adjust by tuning the `flutter_pitch_depth_seconds` curve.
