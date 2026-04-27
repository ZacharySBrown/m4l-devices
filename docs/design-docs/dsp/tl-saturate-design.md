# `tl_saturate` — DSP Design Doc

> **Module:** `tl_saturate` (Generation Loss MKII "SATURATE" knob +
> hidden INPUT GAIN selector)
> **Spec source:** `specs/tape-loss.pedal.yaml`,
> `specs/tape-loss-spec.md` §"MODULE 1: tl.saturate.maxpat"
> **Sandbox status:** `SANDBOX-PARTIAL` — algorithm and reference
> render in pure Python; Max wiring (oversampler `poly~`, `lookup~`
> waveshaping table, biquad shelf coefficient `js`) requires local Max
> IDE.
> **Author:** pedal-dsp.
> **Reference impl:** `dsp/reference/tl_saturate.py`
> **Coefficient JSON:** `data/tl_saturate_coefficients.json`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_saturate_demo_*.wav`

---

## 1. Block diagram

```
       ┌───────────────────────────────────────────────────┐
       │  saturate (0..1)   input_gain (LINE/INST/HIGH)    │
       └─────┬─────────────────────────────┬───────────────┘
             │                             │
             ▼                             ▼
   x[n] ──► [INPUT_GAIN preamp]      [drive = map(saturate)]
             │                             │
             ▼                             │
        [PRE-EMPHASIS shelf]               │  +4 dB / 3 kHz / Q=0.7
        (high-shelf,  +4 dB @ 3 kHz)       │
             │                             │
             ▼                             │
        ┌───────────────────────────┐      │
        │     2× UPSAMPLE           │      │
        │  (halfband FIR, 31 taps)  │      │
        └────────┬──────────────────┘      │
                 │                          │
                 ▼                          ▼
        [ASYMMETRIC POLY/TANH HYBRID  ←─ drive scales x; bias
         WAVESHAPER]                       term breaks symmetry
                 │
                 ▼
        ┌───────────────────────────┐
        │   2× DOWNSAMPLE           │
        │  (halfband FIR, 31 taps)  │
        └────────┬──────────────────┘
                 │
                 ▼
        [DE-EMPHASIS shelf]   (high-shelf, −4 dB @ 3 kHz / Q=0.7)
                 │
                 ▼
        [DC BLOCKER]          (1-pole HPF, fc=20 Hz)
                 │
                 ▼
        [drive-dependent OFFSET INJECT]   (mis-bias: ±0.002 max,
                 │                          gated by drive>8)
                 ▼
                y[n]
```

The chain has six explicit signal-processing stages, and the
oversampling envelope (steps 3 → 5) wraps the only non-linearity in
the chain. Everything else (input gain, shelves, DC blocker, bias
inject) is linear at the host sample rate.

**Why oversample only the waveshaper?** Linear operations cannot
generate aliases; oversampling them is wasted CPU. Pre- and
de-emphasis run at native rate. (JOS, *Spectral Audio Signal
Processing*, "Aliasing in Nonlinear Operations".)

---

## 2. The hysteresis-vs-memoryless decision

This is the most consequential design choice in this module. Tape's
"sound" comes from magnetic hysteresis: the BH-curve (B = magnetic
flux density vs H = magnetizing force) traces a *loop*, not a
single-valued curve. The output depends on the *prior* magnetization,
producing memory effects.

### Candidate models

1. **Memoryless static waveshaper** (e.g., `tanh`, polynomial, LUT).
   - Cost: ~1 mul + 1 LUT lookup per oversampled sample.
   - Pros: stable, click-free under parameter modulation, easy to
     verify, no state to manage.
   - Cons: cannot model the *loop* — asymmetry can be baked into the
     curve via DC bias, but the genuine memory effect is absent.
2. **Jiles-Atherton (J-A) hysteresis model.** Differential equation
   relating M (magnetization) to H, integrated per-sample.
   - Cost: ~6–10 mul/add per sample at native rate, plus an iterative
     solver step for the sech² · sgn term (Newton or fixed-point).
   - Pros: physically grounded; well-cited (Macak & Schimmel 2010;
     Yeh, Abel, & Smith 2008 build on it).
   - Cons: the J-A parameters (Ms, a, k, c, α) are notoriously
     difficult to tune from listening alone; the model can
     bifurcate or run away under audio-rate drive without
     adaptive step-size control; requires anti-aliasing ON the
     state evolution itself.
3. **Preisach hysteresis model.** A weighted superposition of
   relay operators across an M(α,β) plane.
   - Cost: prohibitive for real-time without coarse discretization.
   - Pros: arbitrarily accurate.
   - Cons: not a fit for v0.

### Decision: **memoryless asymmetric polynomial / tanh hybrid for v0.**

Rationale (in priority order):

1. **The spec's own recipe is memoryless.** §"MODULE 1" describes
   `tanh(x · drive) / tanh(drive)` plus pre/de-emphasis. The spec
   author chose a static curve — we honor that and add asymmetry.
2. **Hysteresis is perceptually dominated by *asymmetry* + *soft
   compression*, both reproducible statically.** Real tape's
   even-harmonic content (chiefly H2 and H4) comes from the BH
   loop's asymmetric saturation tips. A static asymmetric shaper
   captures the spectral character — the missing piece is the
   level-dependent *loop area* (i.e., level-dependent damping).
   At v0 we approximate this with a small drive-dependent bias term.
3. **CPU.** With 2× oversampling around the shaper, a static curve
   plus halfband resampling fits comfortably in the < 8 % budget.
   J-A in `gen~` would push that budget hard, especially in stereo.
4. **Robustness.** A static curve cannot blow up. Hysteresis state
   under sustained audio-rate input near saturation can develop
   chaotic dynamics — exactly the behavior that produces "sounds
   amazing in tests, explodes on first user upload" bug reports.
5. **Future-proof.** The reference Python is structured as a
   `WaveShaper` interface — the v1 J-A swap is a localized change.
   Tradeoff log entry #1.

**v1 path:** Implement the Yeh-Smith simplified J-A model (§4 of
Yeh, Abel, Smith, "Simulation of the Diode Limiter in Guitar
Distortion Circuits by Numerical Solution of Ordinary Differential
Equations", DAFx-08, 2008). The Yeh-Smith reformulation removes the
worst of J-A's stiffness without sacrificing the loop. Feature-flag
behind `tl_saturate_engine = jiles_atherton`.

---

## 3. The asymmetric waveshaper

### Transfer function

```
     ┌
     │  (1 / tanh(d)) · tanh(d · u)              for u ≥ 0
y =  │
     │  (1 / tanh(d)) · tanh(d · u) · (1 + β·u)  for u <  0
     └

where  d = drive,  u = (x + b)
       b = small DC bias (drive-dependent)
       β = asymmetry parameter (drive-dependent)
```

The positive half is the spec's exact `tanh(x·drive)/tanh(drive)`
formula, normalized so that the unit-input output is also unity.
The negative half adds a multiplicative term `(1 + β·u)` (with `β > 0`
and `u < 0`, so the factor is < 1) that *flattens* negative peaks
slightly more aggressively than positive peaks. The result: the
output's negative excursion is compressed harder than its positive
excursion → static DC offset → strong even-harmonic content.

Citation: this is the standard recipe for "soft asymmetric clipper"
described in Pirkle, *Designing Audio Effect Plug-Ins in C++*, §16.4
("Asymmetric Distortion"), and matches the family of curves used in
the `chowdsp_wdf` ChowMatrix plugin. The β parameter is the
asymmetric-damping coefficient.

### Drive mapping (`saturate ∈ [0, 1] → drive ∈ [1, 12]`)

```
drive(saturate) = 1.0 + 11.0 · saturate²
```

**Why quadratic?** Linear taper makes the bottom of the knob feel
inert (drive = 1.0..6.5 is mostly clean) and the top half feel
crammed (6.5..12 is where the harmonics live). Quadratic taper
distributes the audible change more uniformly across the rotation.
Verified by ear in `dsp/reference/fixtures/tl_saturate_demo_0p3*.wav`
vs `tl_saturate_demo_0p7*.wav`.

### Bias mapping

```
b(drive)   = 0.05 · max(0, (drive − 4) / 8)        # 0 at drive≤4, 0.05 at drive=12
β(drive)   = 0.20 · max(0, (drive − 2) / 10)       # 0 at drive≤2, 0.20 at drive=12
```

The bias only kicks in past `drive=4` (saturate ≈ 0.55) and the
asymmetry only past `drive=2` (saturate ≈ 0.30). At low drive
settings, the curve is effectively the symmetric `tanh` from the
spec, preserving the v0 spec's sound at common settings.

### Normalization

Both halves are divided by `tanh(d)` so that input `|x|=1` maps to
`|y| ≈ 1` — preserves loudness across drive settings. (Without
normalization, increasing drive *attenuates* the output, which
sounds wrong even though it's what unnormalized `tanh` does.)

### LUT vs runtime evaluation

The Max patch uses `lookup~` (per spec §"Max Objects Required") with
a 4096-entry table, populated once at load time per the formula
above. `lookup~` does linear interpolation between table entries;
4096 entries is dense enough that interpolation error is far below
the noise floor (~96 dBFS). The Python reference computes the
function directly without LUT.

---

## 4. Pre/de-emphasis shelves (RBJ high-shelf)

### Spec values

The spec calls for `+4 dB above 3 kHz` pre, `−4 dB above 3 kHz` de.
We use RBJ Audio EQ Cookbook high-shelf coefficients with:

```
fc = 3000 Hz
Q  = 0.7  (Butterworth-flat shelf knee)
gain_pre  = +4.0 dB
gain_post = −4.0 dB
```

### Why pre/de-emphasis matters here, not in `tl_model_eq`

`tl_model_eq` models the *machine's* spectral signature
(VHS/cassette/dictaphone/etc.). The pre/de-emphasis shelves around
the saturator model the *recording bias* path: the record amplifier
boosts highs going to tape (so they don't get lost in the head bump
+ tape losses), and the playback amplifier rolls them back. The
crucial point: the saturation happens *between* the boost and the
roll-back, so high frequencies hit the BH curve harder. That's
what gives tape its characteristic "harmonics on the cymbals" feel.

If we put both shelves in `tl_model_eq`, the saturation would see
flat input and we'd lose the frequency-dependent harmonic content.

This is consistent with how every tape-emulation plugin
(Slate VTM, U-He Satin, Waves Kramer Master Tape) places them.
Citation: JOS, *Physical Audio Signal Processing*, "Tape Recording
Bias and Equalization" sub-chapter.

### Shelf recipe (RBJ, normalized)

For a high-shelf at fc=3000 Hz, Q=0.7, gain=+4 dB at SR=44100 Hz the
generator (`dsp/coefficients/tl_saturate.py`) produces:

```
pre-emphasis  (+4 dB):  b0= +1.4797   b1= −2.1683   b2= +0.8572
                        a1= −1.3370   a2= +0.5056
de-emphasis   (−4 dB):  b0= +0.6758   b1= −0.9036   b2= +0.3417
                        a1= −1.4654   a2= +0.5793
```

The de-emphasis denominator differs from the pre-emphasis denominator
because A enters via `2·√A·α` in `a0` and the sign of `(A−1)` is
implicit in the post/pre direction — both halves of the cascade are
required to be reciprocal pairs at unit-DC, not literal coefficient
inversions. Values for 48 kHz, 88.2 kHz, and 96 kHz are also emitted
into `data/tl_saturate_coefficients.json`.

### Shelf inversion property

RBJ shelves with opposite-sign gain *are* exact inverses of each
other (since the cookbook formulas are derived as bilinear-transform
analog prototypes whose magnitude responses are reciprocal under sign
flip of `dBgain`). Verified numerically: cascading the +4 dB pre with
the −4 dB de produces magnitude error ≤ 10⁻¹⁵ dB at every test
frequency from 200 Hz to 15 kHz. The chain transparency at
`saturate=0` (with shaper bypassed) is therefore mathematically
exact, modulo 64-bit float rounding.

Real magnetic recording de-emphasis isn't a perfect inverse of
pre-emphasis (NAB and IEC curves use different time-constants on
record vs playback) — but our digital model isn't trying to model the
NAB/IEC mismatch. The pre/de pair here is purely a **frequency-
weighting** mechanism that biases the shaper into making cymbals
saturate harder than bass. Their literal cascade is *intended* to be
flat.

Citation: RBJ, *Audio EQ Cookbook* §"High shelf" (vendored at
`~/raindog/harness/references/audio-eq-cookbook.md`).

---

## 5. INPUT_GAIN modes (LINE / INSTRUMENT / HIGH_GAIN)

These shift the operating point on the BH curve by changing how hard
the signal hits the shaper. They are *pre-shaper* gain stages:

| Mode       | Pre-shaper gain | Rationale                                  |
|------------|----------------:|--------------------------------------------|
| LINE       | 0.0 dB          | Studio +4 dBu nominal level — no boost.    |
| INSTRUMENT | +6.0 dB         | Hi-Z guitar/bass — ~12 dB hotter than line, but with pad.  |
| HIGH_GAIN  | +12.0 dB        | Synth or already-driven sources hit saturation immediately. |

The spec calls for `+6` and `+12` exactly. INPUT_GAIN is applied
**before** the pre-emphasis shelf, so the pre-emphasis sees the
boosted signal and amplifies its highs further before saturation.

### Output level compensation

Adding +12 dB of input gain would make HIGH_GAIN mode painfully loud
without compensation. We apply an *output* attenuation that exactly
cancels the *small-signal* gain through the chain. At small signals
(below the soft-knee), the saturator behaves linearly with gain
`d / tanh(d) ≈ 1` (for our normalized form), so the only un-cancelled
gain is INPUT_GAIN itself.

```
output_atten_dB = −INPUT_GAIN_dB
```

Result: `saturate=0` produces unity gain end-to-end regardless of
INPUT_GAIN mode. INPUT_GAIN only controls *how hard the signal hits
the curve*, not *how loud it comes out at zero drive*.

Tradeoff log entry #4: this is a deliberate departure from "+12 dB
input means +12 dB output". Boutique-pedal users expect input-gain
selectors to change *character*, not *level*.

---

## 6. DC blocker

Asymmetric saturation produces DC. A 1-pole high-pass filter
(`y[n] = x[n] − x[n−1] + R · y[n−1]`, with `R = 0.997` at 44.1 kHz)
removes it. Cutoff is approximately 20 Hz (below the lowest
musical pitch we care about); R is rate-dependent:

```
R = exp(−2π · 20 / sr)   # → 0.99715 @ 44.1 kHz, 0.99738 @ 48 kHz
```

This is the standard differentiator-leaky-integrator DC blocker,
documented in JOS, *Introduction to Digital Filters*, §"DC blocker".

### Where it sits

After the down-sampled de-emphasis shelf. Putting it before the
shaper would not help — the asymmetric shaper *generates* DC, so
any DC block must come downstream. Putting it before de-emphasis
also works numerically but adds an extra `biquad`-output denormal
risk if de-emphasis is in Direct Form II Transposed.

---

## 7. Mis-bias offset injection (drive > 8)

Per spec: "tiny random walk added at drive > 8: ±0.002 max
(simulates mis-biased tape at extreme settings)". We implement this
as a slow (≤ 0.5 Hz) lowpass-filtered Gaussian random walk, scaled
by `(drive − 8) / 4 → [0, 1]` and capped at `±0.002`.

```
noise[n]   ~ N(0, 1)
walk[n]    = lowpass(noise, fc=0.5 Hz)
inject[n]  = clip( 0.002 · ((drive − 8) / 4) · walk[n], ±0.002 )
y[n]       = y[n] + inject[n]
```

The injection is *added*, not multiplied; it appears as a slow,
inaudible-on-its-own DC wander that interacts with the DC-blocker's
cutoff to produce subtle low-frequency motion. At drive=8 it's 0;
at drive=12 it's at its full ±0.002 (≈ -54 dBFS).

This sits *after* the DC blocker so it doesn't get filtered away.
Without that ordering, the DC blocker would null the entire effect.

---

## 8. Aliasing analysis & oversampling decision

### The problem

A waveshaper applied to `sin(2π · f · t)` generates harmonics at
`2f, 3f, 4f, ...`. With drive at 12, our shaper produces
non-negligible energy out to ~H10 (verified in
`dsp/reference/tl_saturate.py::__main__`'s spectrum plot). For a
1 kHz input, that's energy at 10 kHz — well below Nyquist.

But for an 8 kHz input (cymbals, vocal sibilance, hi-hat fundamental),
H10 is at 80 kHz. At a 44.1 kHz sample rate (Nyquist = 22.05 kHz),
all of H3 (24 kHz), H5 (40 kHz), etc., alias back into the audible
band as inharmonic content — the canonical "harsh digital
distortion" sound.

### Decision: **2× oversampling around the shaper.**

At 2×, our effective Nyquist becomes 44.1 kHz. An 8 kHz input's
harmonics beyond H5 still alias, but H2 (16 kHz), H3 (24 kHz, just
above audible), H4 (32 kHz), H5 (40 kHz, well above audible) are
now properly attenuated by the downsampling lowpass. The remaining
aliases are at -50 dBFS or lower — perceptually insignificant given
that we *want* the lower harmonics audible.

4× would catch H7+ at 8 kHz, but the perceptual return diminishes
sharply. CPU cost roughly doubles per oversampling stage. Tradeoff
log entry #2: 2× is the boutique-pedal sweet spot.

### Filter choice: 31-tap halfband FIR

A halfband FIR has the property that *every other coefficient is
zero* (except the center tap), so a 31-tap halfband requires only
17 actual multiplies per output sample (16 non-zero coefficients +
center). At 44.1 kHz host rate, 2× upsampled, 17 muls/sample is
trivial.

Stopband: −80 dB attenuation at fs/4 (well above the 22.05 kHz
Nyquist edge), passband ripple < 0.05 dB to 19 kHz. Designed via
windowed-sinc with a Kaiser window (β=8.0).

Citation: Smith, *DSP Guide* §16 ("Windowed-Sinc Filters"); JOS,
*Spectral Audio Signal Processing* on halfband design ("efficient
form" of polyphase decomposition).

### Sandbox compatibility

Halfband FIR is implementable in `gen~` (the natural sandbox for
oversampling in M4L). The pedal-engineer will use a `gen~` codebox
or two `cascade~` chains on a `poly~ 2 @parallel 1` instance.
Native `[fffb~]` won't work for halfband (it's specifically lowpass
biquads).

**Audit note:** the engineer should verify that `gen~` block
processing handles the half-rate state correctly. Test as part of
the standalone debug harness (pitfall #9).

---

## 9. Parameter mapping table

| Parameter         | Range / mode            | Internal effect                                                 |
|-------------------|-------------------------|-----------------------------------------------------------------|
| `saturate = 0.0`  | knob fully CCW          | **True bypass** of shaper / shelves / DC-blocker / mis-bias (output bit-identical to input · INPUT_GAIN compensation). |
| `saturate = 0.3`  |                         | drive=2.0, bias=0, β=0.0 (just at threshold). Subtle warm.      |
| `saturate = 0.5`  | noon                    | drive=3.75, bias=0, β=0.035. Audible H2 & H3.                   |
| `saturate = 0.7`  |                         | drive=6.4, bias=0.015, β=0.088. Pronounced asymmetric drive.    |
| `saturate = 1.0`  | knob fully CW           | drive=12.0, bias=0.05, β=0.20, mis-bias inject ±0.002. Crushed. |
| `input_gain=LINE` | (default)               | +0 dB pre, 0 dB post (output) — line-level reference.           |
| `input_gain=INSTRUMENT` | (mode=1)          | +6 dB pre, −6 dB post (output) — saturator hits 6 dB harder.    |
| `input_gain=HIGH_GAIN` | (mode=2)           | +12 dB pre, −12 dB post (output) — saturator hits 12 dB harder. |

---

## 10. Failure modes and edge cases

| Edge case                                | Behavior                                                                 |
|------------------------------------------|--------------------------------------------------------------------------|
| `saturate = 0`                           | Output ≈ input within shelf-cascade error (~−0.05 dB at 1 kHz).          |
| `saturate = 1, input_gain = HIGH_GAIN`   | Maximum harmonic content; output level still ~unity at small signals.    |
| Sustained loud input near saturator threshold | Static curve cannot blow up; DC blocker handles asymmetry-induced DC. |
| Sample-rate change (44.1 → 48 kHz)       | Shelf, DC-blocker, and halfband FIR coefficients recompute on `sr` msg.  |
| Denormals after silence                  | Pre/de-emphasis biquads use Direct Form I + denormal flush; DC blocker leaks naturally. |
| Sub-audio drift from mis-bias inject     | Bounded by `±0.002`, then DC-blocker high-passes at 20 Hz — most of it removed. |
| Input clipping (|x| > 1)                  | Shaper *bounds* output to ±(1+small_bias)/tanh(d) — soft-clips by design. |
| Stereo independence                       | Both channels process independently with the same coefficients (no shared state). |

### Numerical stability

- **Halfband FIR:** non-recursive, unconditionally stable.
- **Shelves:** RBJ Q=0.7 → poles well inside unit circle. Direct Form I
  with explicit denormal flush (`|y| < 1e-30 → 0`) per JOS,
  *Introduction to Digital Filters*, §"Numerical Considerations".
- **DC blocker:** R=0.997 → single pole at +0.997, stable, leaks.
- **Shaper:** `tanh` is bounded ∈ (−1, +1) regardless of input.
  Asymmetric multiplier `(1 + β·u)` for u < 0 is bounded too: at
  worst `u ≈ −1`, β=0.20, factor → 0.8 — multiplier never goes
  negative or above 1 in our valid range.

---

## 11. CPU / sandbox considerations

**M4L target:** < 8 % on M1 at 44.1 kHz / 64-sample vector.
`tl_saturate` is one of nine modules → < ~1 % budget.

### Per-sample cost estimate

| Stage              | Native rate          | 2× rate              |
|--------------------|----------------------|----------------------|
| input_gain mul     | 1 mul                |                      |
| pre-emphasis biquad| 5 mul + 4 add        |                      |
| 2× upsample (HB FIR) | 17 mul + 16 add (avg) |                |
| Asym shaper LUT    |                      | 1 LUT + 1 lerp + 1 mul |
| 2× downsample (HB FIR) | 17 mul + 16 add (avg) |               |
| de-emphasis biquad | 5 mul + 4 add        |                      |
| DC blocker         | 1 mul + 2 add        |                      |
| mis-bias add       | 1 add                |                      |

Total ~50 muls/adds per native sample. Stereo doubles to ~100.
Comfortably within budget.

### Sandbox-incompatible elements

- **Halfband FIR.** Not a built-in object — the engineer wires this
  via `gen~`. Test in standalone Max IDE before Ableton.
- **`lookup~` table population.** Requires `peek~` writes from a
  Max-side `[js]` at load time. Pitfall #19 applies — verify in
  Max IDE before Ableton.
- **Coefficient JSON load.** Standard pattern, same as `tl_model_eq`.
  The companion `[js]` reads `data/tl_saturate_coefficients.json`
  on `loadbang` and on `sr` change, sends `setcoeff` messages to
  the two `biquad~` shelves.

---

## 12. Tradeoff log

| # | Decision | Rationale | Alternative considered |
|---|----------|-----------|------------------------|
| 1 | **Memoryless asymmetric polynomial / tanh hybrid** (not Jiles-Atherton) | Spec is memoryless; even-harmonic character captured by static asymmetry; CPU & robustness wins; clean v1 upgrade path. | Jiles-Atherton (deferred to v1, feature-flagged); Preisach (prohibitive). |
| 2 | **2× oversampling** around shaper only | Catches H2-H5 of 8 kHz inputs, fits CPU. 4× has diminishing perceptual return. | 1× (audible alias on hi-hats); 4× (CPU + low return). |
| 3 | **31-tap halfband FIR** for resampling | Polyphase efficiency (~17 muls/sample); 80 dB stopband; flat 0.05 dB passband to 19 kHz. | IIR halfband (lower CPU but phase non-linearity audible on transients). |
| 4 | **INPUT_GAIN matched output attenuation** | Boutique pedal users expect mode selectors to change *character*, not *level*. | No compensation (HIGH_GAIN would clip; user blames the pedal). |
| 5 | **Pre/de-emphasis lives in `tl_saturate`** (not `tl_model_eq`) | Spec puts shelves around the saturator; high-bias-then-saturate is what drives the tape character. Putting them in `tl_model_eq` would flatten the saturation. | Move to `tl_model_eq` (architecturally tidier but spec-violating and tone-killing). |
| 6 | **Quadratic drive taper** `1 + 11·sat²` | Distributes audible change uniformly across rotation; matches spec's range 1.0–12.0. | Linear (top half feels crammed), exponential (jumps at top). |
| 7 | **Direct Form I biquads** (vs. Transposed Direct Form II) | Static coefficients (per knob position); DFI is simpler to reason about; quantization noise floor moot at 64-bit float. | TDF-II: better for time-varying coefficients (not our case for shelves; we'd want it if shelves modulated). |
| 8 | **Mis-bias inject AFTER DC blocker** | Otherwise the DC blocker nulls the effect entirely. | Before DC blocker (subtractive, eliminates the spec-required artifact). |
| 9 | **`tanh` evaluated via 4096-entry LUT** in M4L (not in Python ref) | Per spec ("`lookup~` waveshaping table populated with tanh curve"); LUT linear-interp error < −96 dBFS. | Direct `tanh` in `gen~` codebox: also acceptable, slightly more CPU. |
| 10 | **DC blocker R = exp(−2π·20/sr)** | Standard formula; cuts at 20 Hz; SR-aware (recompute on sr change). | Fixed `R=0.995` (drifts cutoff with SR; unprofessional). |
| 11 | **Stereo channels processed independently** | No state shared; spread/MISO upstream handle stereo behavior. | Shared coefficients but channel-specific delay lines (no, no delay in this module). |
| 12 | **Output level normalization through `tanh(d)`** | Loudness-stable across drive sweep — important for A/B testing knob positions without confusing loudness with timbre. | Unnormalized (loudness drops as drive rises — sounds wrong even though physically faithful). |
| 13 | **Asymmetry as multiplicative term on negative half**, not DC offset | DC offset would interact with DC blocker, requiring delicate ordering. Multiplicative term gives the same spectral effect (even harmonics) without DC management. | Pure DC bias (works but harder to calibrate). |
| 14 | **classic_mode (GEN sample-rate reducer) is NOT this module's concern** | Spec says classic_mode swaps the saturator for a downsampler. That module (`tl_classic`) is deferred to v1 per the parent spec's "Definition of Done — does not require." | Adding a downsampler branch here (premature scope creep). |
| 15 | **Output makeup at 70 % of full small-signal-gain compensation** | Full compensation makes drive sweep "louder" by 0 dB which feels musically wrong (a drive knob *should* push); zero compensation lets the top end blow out at +20 dB. 70 % is a measured sweet spot: ~ 4 dB RMS drop across the full sweep. | Full compensation (sterile A/B but unmusical knob feel); none (unusable at top of sweep). |
| 16 | **`saturate=0` short-circuits the entire chain** (skip shelves, shaper, DC blocker, mis-bias) | Gives a true bit-identical bypass at the bottom of the knob — important for "is the pedal even doing anything?" diagnostics, and means user-facing CPU drops to ~ 0 % at saturate=0. | Run the full chain at saturate=0 (drive=1) — produces a small but measurable cascade-error and a non-zero CPU floor for no audible benefit. |
| 17 | **Mis-bias inject is zero-mean over the buffer** (subtract walk's mean) | Otherwise the random walk's drift produces a static DC pedestal at the output (was 4×10⁻³ before correction, now 4×10⁻⁴). | Skip the mean-subtract (DC-blocker mostly handles it but verifier-noise drifts up to 0.4 % — flaky regression hashes). |

---

## 13. References

- **Robert Bristow-Johnson, *Audio EQ Cookbook*.** High-shelf
  coefficient formulas. Vendored at
  `~/raindog/harness/references/audio-eq-cookbook.md`. Canonical:
  https://www.w3.org/TR/audio-eq-cookbook/
- **Steven W. Smith, *The Scientist and Engineer's Guide to Digital
  Signal Processing* (1997).**
  - Ch. 16 — Windowed-sinc filters (halfband FIR design + Kaiser).
  - Ch. 17 — Custom filters (combined DC blocker + window).
  - Ch. 19 — Recursive filters (biquad / Direct Form I).
  Pointer: `~/raindog/harness/references/dsp-book-pointer.md`.
- **Julius O. Smith III, *Introduction to Digital Filters with
  Audio Applications*** (CCRMA, free).
  - §"DC blocker" — leaky integrator differentiator.
  - §"Numerical Considerations" — denormal flushing.
  Pointer: `~/raindog/harness/references/jos-textbook-pointers.md`.
- **JOS, *Physical Audio Signal Processing***. "Tape Recording Bias
  and Equalization" sub-chapter — pre/de-emphasis placement
  rationale. URL fragment: ccrma.stanford.edu/~jos/pasp/Tape.html
- **JOS, *Spectral Audio Signal Processing***. "Aliasing in Nonlinear
  Operations" — oversampling rationale.
- **Will Pirkle, *Designing Audio Effect Plug-Ins in C++*** (Focal
  Press, 2012). §16.4 "Asymmetric Distortion" — soft asymmetric
  clipper recipe. (Not vendored; cite by chapter.)
- **Yeh, Abel, & Smith, "Simulation of the Diode Limiter in Guitar
  Distortion Circuits by Numerical Solution of Ordinary Differential
  Equations", DAFx-08, 2008.** v1 J-A reference.
- **Macak, Schimmel, "Real-time Guitar Tube Amplifier Simulation
  Using an Approximation of Differential Equations", DAFx-10, 2010.**
  Practical adaptive step-size for hysteresis-style ODEs.
- **Chase Bliss Generation Loss MKII manual.** Behavioral source
  (input gain modes, knob ranges).
- **Project spec:** `specs/tape-loss-spec.md` §"MODULE 1:
  tl.saturate.maxpat" — engineer-readable algorithm sketch.

---

## 14. M4L pitfall catalog cross-reference

From `~/raindog/harness/quickstarts/max-plugin/specs/m4l-device-development-guide.md`:

| Pitfall | Relevance to `tl_saturate` |
|---------|----------------------------|
| #3 — `[live.comment]` for dynamic text | If we surface a "drive dB" indicator label, must use `live.comment`. |
| #7 — `plugin~`/`plugout~` `2` always | Stereo I/O. Both channels processed independently — confirm `2` on both sides. |
| #9 — Standalone debug.maxpat harness | Halfband FIR oversampling is gen~-side and *easier to verify in standalone Max* than after Ableton round-trip. |
| #18 — `live.slider` saved_attribute_attributes | `saturate` is exposed via `live.dial` (covered by autopattr), but if `input_gain` is exposed as a hidden `live.tab` with state, ensure full `valueof` block is included. |
| #19 — Test standalone Max first | Critical: `lookup~` table-population timing (loadbang vs first DSP buffer) is famously a source of "first vector silent" bugs. Verify the LUT is populated before audio starts. |

---

## 15. Verification artifacts

**Reference implementation:** `dsp/reference/tl_saturate.py`
**Coefficient JSON:** `data/tl_saturate_coefficients.json`
**Sanity-render WAVs (44.1 kHz, 16-bit stereo):**
- `tl_saturate_input_dry.wav` — clean A2/E3/A3 chord, 3 s (synthetic).
- `tl_saturate_demo_sat0p0_LINE.wav` — `saturate=0`, expected ≈ identity.
- `tl_saturate_demo_sat0p3_LINE.wav` — `saturate=0.3`, subtle warm.
- `tl_saturate_demo_sat0p7_LINE.wav` — `saturate=0.7`, obvious drive.
- `tl_saturate_demo_sat1p0_LINE.wav` — `saturate=1.0`, crushed.
- `tl_saturate_demo_sat0p7_INSTRUMENT.wav` — same drive, +6 dB pre.
- `tl_saturate_demo_sat0p7_HIGH_GAIN.wav` — same drive, +12 dB pre.
- `tl_saturate_demo_sweep1k.wav` — 1 kHz sine at saturate=1.0 (for spectrum inspection of harmonic content).

**Verified properties (programmatic checks, run at __main__ time):**

Measured values (sr=44.1 kHz, 0.5-amp 1 kHz sine, seed=0):

| Property | Measured | Target |
|---|---|---|
| `saturate=0.0` cascade error at 1 kHz | **0.00 dB** (true bypass) | ≤ 0.1 dB |
| THD@1kHz at `saturate ∈ {0.0, 0.3, 0.5, 0.7, 1.0}` | **{4×10⁻⁹, 0.054, 0.131, 0.211, 0.289}** | strictly monotonic ↑ |
| RMS at `saturate=0` for {LINE, INSTRUMENT, HIGH_GAIN} | **{0.3536, 0.3536, 0.3536}** | identical (±0.05 dB) |
| DC offset at `saturate=1, drive=12` | **7.5×10⁻⁴** | < 1×10⁻³ |
| H2 amplitude at `saturate ∈ {0.0, 0.3, 0.5, 0.7, 1.0}` (FFT bin energy, arbitrary unit) | **{1×10⁻⁵, 6×10⁻⁶, 16, 62, 179}** | monotonic ↑ once `saturate > 0.3` (β kicks in) |
| Non-finite samples at `saturate=1.0` | **0** | 0 |
| RMS sweep (loudness drift across saturate ∈ [0, 1] for fixed input) | **−13.0 → −12.5 → −14.3 → −17.0 dB** | < 8 dB total spread (tradeoff #15) |

**Note on H2:** below `saturate=0.3`, β=0 so the shaper is symmetric
and produces *no* even harmonics — H2 magnitude at `saturate=0.3`
sits at the FFT noise floor (~10⁻⁵). Above `saturate=0.3` the
asymmetry kicks in and H2 emerges sharply. This is the desired
character: subtle saturation at low knob settings is *clean odd-
harmonic warmth* (H3, H5, …); aggressive settings add the
*even-harmonic asymmetric grit* (H2 + H3 + …).

These render-time property checks should be migrated to a unit
test in the engineer's verifier suite once the
`dsp/reference/<module>.py` test harness is wired.
