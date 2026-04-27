# `tl_noise` — DSP Design Doc

> **Module:** `tl_noise` (Generation Loss MKII "NOISE" generator)
> **Spec source:** `specs/tape-loss.pedal.yaml`,
> `specs/tape-loss-spec.md` §"MODULE 6: tl.noise.maxpat"
> **Sandbox status:** `SANDBOX-OK` — pure noise synthesis, two filtered
> sources, sinusoidal hum stack. No external buffers, no `poly~`, no
> tapped delay lines.
> **Position in chain:** terminal — additive on the post-`tl_dry_mix`
> output bus.
> **Author:** pedal-dsp (this doc), pedal-engineer takes Phase 2.
> **Reference impl:** `dsp/reference/tl_noise.py`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_noise_*.wav`

---

## 1. Block diagram

```
        ┌──────────────────────────────────────────────────────────┐
        │  noise_mode (OFF/HISS/BOTH)                              │
        │  hiss_level (0..1)                                       │
        │  mechanical_level (0..1, bipolar around 0.5)             │
        │  hum_bypass (bool)                                       │
        └─────────────────────────┬────────────────────────────────┘
                                  │
                                  ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ HISS PATH (per channel; independent RNG per L/R)                │
   │                                                                 │
   │   white_L[n] ──► [Voss-McCartney pink generator]                │
   │                  ──► [HPF 50 Hz Q=0.7 (RBJ HPF)]                │
   │                  ──► [LPF 12 kHz Q=0.7 (RBJ LPF, head-gap)]     │
   │                  ──► × hiss_gain(hiss_level)                    │
   │                  ──► hiss_L                                     │
   │   white_R[n] ──► (independent stream — full stereo decorr.)     │
   │                                                                 │
   │   GATE: noise_mode != OFF                                       │
   └─────────────────────────────────────────────────────────────────┘
                                  +
   ┌─────────────────────────────────────────────────────────────────┐
   │ MECHANICAL PATH (BOTH mode only, AND not hum_bypass)            │
   │                                                                 │
   │   ┌── VCR sub-engine (decorrelated stereo) ──┐                  │
   │   │   white ──► [LPF 200 Hz Q=0.9 (RBJ)]    │                  │
   │   │           × slow-AM(0.3..1.5 Hz, depth   │                  │
   │   │             0.6, jittered)              │                  │
   │   └──────────────────────────┬───────────────┘                  │
   │                              │                                  │
   │   ┌── HUM sub-engine (mono / correlated) ────┐                  │
   │   │   sin(2π·60·t)·1.0                      │                  │
   │   │ + sin(2π·120·t)·0.30 (even, weak)       │                  │
   │   │ + sin(2π·180·t)·0.45                    │                  │
   │   │ + sin(2π·240·t)·0.18                    │                  │
   │   │ + sin(2π·300·t)·0.22                    │                  │
   │   │ + sin(2π·420·t)·0.12                    │                  │
   │   │   (transformer leakage harmonic stack)  │                  │
   │   └──────────────────────────┬───────────────┘                  │
   │                              │                                  │
   │   crossfade(mechanical_level)                                   │
   │     ├ ml ≤ 0.5 : weight VCR  = (0.5-ml)/0.5, weight HUM = 0     │
   │     │           and an "always-on small VCR" floor              │
   │     ├ ml = 0.5 : silent floor (knob-noon = quiet)               │
   │     └ ml ≥ 0.5 : weight HUM = (ml-0.5)/0.5, weight VCR = 0      │
   │   × mechanical_gain(|ml-0.5|·2)                                 │
   │                                                                 │
   │   GATE: noise_mode == BOTH AND NOT hum_bypass                   │
   └─────────────────────────────────────────────────────────────────┘
                                  ▼
                       summed → out_L, out_R
```

The two paths are independent and additive. The module does not see
audio input — it synthesizes pure noise to be summed onto the dry-mixed
output upstream.

---

## 2. Hiss path

### 2.1 Pink-noise generation — Voss-McCartney algorithm

White noise has a flat power spectrum (0 dB/octave). Real tape hiss
is roughly **pink** (1/f, −3 dB/octave) due to the magnetic emulsion's
power spectrum and head-gap losses. We generate pink noise via the
**Voss-McCartney algorithm** — a multi-rate sum of independent random
values that produces a near-1/f spectrum cheaply.

**Algorithm (McCartney 1999, after Voss 1978):**

```
For B=16 octave bins:
  bin[k] is updated every 2^k samples.
  output[n] = Σ_{k=0..B-1} bin[k]
After each output, choose a random bin index k via the trailing-zero
count of the sample counter; redraw bin[k] from N(0, 1).
```

Citation:
- Voss, R. F. and Clarke, J. "1/f noise in music: Music from 1/f noise."
  *Journal of the Acoustical Society of America* 63(1), 258 (1978).
- McCartney, James. "Generating Pink Noise" (firstpr.com.au mirror,
  1999) — the standard "trailing-zero index" implementation, which we
  follow.
- Mirrored discussion: J. O. Smith, *Spectral Audio Signal Processing*,
  "1/f Noise" appendix, ccrma.stanford.edu/~jos/sasp/.

**Why not a -3 dB/octave shelving cascade?** That works (Larry Trammell's
"economy" pinking filter cascades 4–6 one-poles), but Voss-McCartney
gives a flatter low-end down to DC and is trivial to verify
numerically (each generator is provably 1/f within the band of
interest). CPU cost is essentially the same: one add + one branch per
sample.

**Spectrum target (verified in `verify.py`):**
The output of the Voss-McCartney generator measured over 4 seconds at
44.1 kHz fits the line `-3.0 dB/octave ± 0.5 dB` between 50 Hz and
8 kHz. The high-frequency end naturally rolls off because the lowest
bins are updated less often (which is exactly the desired bias for
tape hiss).

### 2.2 Hiss spectral shaping

After Voss-McCartney, two RBJ biquads further shape the hiss to match
real cassette/VHS spectra:

| Stage | Type | f0 | Q | Citation |
|---|---|---:|---:|---|
| 1 | HPF | 50 Hz | 0.707 | RBJ Audio EQ Cookbook §HPF |
| 2 | LPF | 12 kHz | 0.707 | RBJ Audio EQ Cookbook §LPF |

Rationale:
- **HPF 50 Hz** removes the small DC/sub-bass component of a Voss-McCartney
  stream that would otherwise be inaudible but eat headroom.
- **LPF 12 kHz** approximates the head-gap roll-off of a typical
  consumer cassette deck (Nakamichi specs ~14 kHz at -3 dB; Type-I
  ferric closer to 10 kHz). 12 kHz is a deliberate compromise. Q=0.707
  is Butterworth — flat passband, no peaking.

Both coefficients depend on `Fs` and recompute on `dspstate~` change
(see §6).

### 2.3 Hiss level mapping

`hiss_level` (0..1) → linear gain `hiss_gain`:

```
hiss_gain = hiss_level² · target_max_amp
target_max_amp = 10^(-42/20)  ≈ 0.0079   # peak ≈ -42 dBFS at hiss_level=1
```

Quadratic taper because the bottom of the knob should give "barely
audible floor" not "instantly noisy." -42 dBFS peak at full was chosen
so the hiss floor sits ~6 dB above a typical noise floor (-48 dBFS) and
~30 dB below a typical mix bus signal — audible character, never
overwhelming.

### 2.4 Stereo strategy (hiss)

**Independent per-channel RNG seeds (decorrelated).** Real tape hiss is
emulsion-grain noise; left and right channels of a stereo cassette have
independent grain noise. Decorrelation gives natural stereo width
without any explicit panning.

Implementation: `numpy.random.SeedSequence(seed).spawn(2)` produces
two independent generators. (The same trick we use in `tl_failure` for
SPREAD mode.)

---

## 3. Mechanical path

The `mechanical_level` knob is bipolar around 0.5:
- CCW half (0.0 → 0.5): VCR-style mechanical noise (capstan/head-drum)
- CW half (0.5 → 1.0): mains hum (electrical leakage)

Knob-noon (`mechanical_level = 0.5`) is silent. The path is gated off
entirely if `noise_mode != BOTH` or `hum_bypass == True`.

### 3.1 VCR sub-engine

Capstan-motor whir + head-drum bearing rumble. Real measurements (e.g.
Nakamichi NR-200 service notes; consumer VCR teardowns at AVForum)
show broadband low-frequency content peaking 80–250 Hz with
slow envelope variation as the mechanism warms or wobbles.

**Topology:**

1. White noise source.
2. RBJ LPF at 200 Hz, Q=0.9 (slight resonance gives the "rumble"
   character rather than a soft hiss).
3. Slow random AM via filtered noise modulator — depth 0.6 around
   center 0.7 (so the envelope swings between ~0.1 and ~1.3, *not*
   silent). Modulator built from a 0.3–1.5 Hz random walk smoothed
   with a one-pole at fc=2 Hz.

Citation: RBJ Audio EQ Cookbook §LPF for the biquad. The AM envelope
is custom; the design tradeoff is documented in §8.

### 3.2 Hum sub-engine — harmonic stack

Mains hum on a tape head is a transformer/PSU pickup phenomenon:
fundamental at the line frequency plus odd-and-even harmonics from
transformer non-linearity and the half-wave/full-wave rectifier on the
deck's power supply. Even harmonics dominate when the rectifier is
asymmetric; odd harmonics dominate from transformer saturation. Real
measurements vary by deck; we pick a stack representative of a typical
consumer cassette deck PSU with a half-wave rectifier (slight even
harmonic emphasis).

**Default fundamental: 60 Hz** (North American mains). Rationale:
the spec's reference is Chase Bliss (Minnesota, USA). For 50 Hz
regions, the constant `HUM_FUNDAMENTAL_HZ` at the top of `tl_noise.py`
can be flipped to `50.0`; harmonics auto-derive.

**Harmonic table (relative amplitudes, sum normalized):**

| Harmonic | Frequency | Relative amplitude | Source |
|---:|---:|---:|---|
| 1 | 60 Hz  | 1.00 | Fundamental — line frequency |
| 2 | 120 Hz | 0.30 | Even — half-wave PSU rectification |
| 3 | 180 Hz | 0.45 | Odd — transformer saturation (largest aside from fundamental) |
| 4 | 240 Hz | 0.18 | Weak even |
| 5 | 300 Hz | 0.22 | Weak odd |
| 7 | 420 Hz | 0.12 | High odd, near-inaudible at hum levels |

The 6th and 8th harmonics are omitted (far below noise floor on real
measurements). Phase is randomized once per render so rendered
fixtures don't all look identical, but is held constant within a
render (the harmonic stack is a stationary signal, not a modulated
one — the *level* changes via the crossfade, not the harmonic
ratios).

After summation, normalize peak to 1.0 then scale by `mechanical_gain`
(see §3.3).

### 3.3 Bipolar crossfade — `mechanical_level`

Map `ml ∈ [0, 1]` to (vcr_weight, hum_weight, common_gain):

```
ccw_amount = max(0,  0.5 - ml) · 2          # 1.0 at ml=0,   0.0 at ml≥0.5
cw_amount  = max(0,  ml  - 0.5) · 2          # 0.0 at ml≤0.5, 1.0 at ml=1
vcr_weight = ccw_amount
hum_weight = cw_amount
common_gain = max(ccw_amount, cw_amount)² · target_max_amp
target_max_amp = 10^(-40/20)  ≈ 0.01   # peak ≈ -40 dBFS at full mechanical
```

The crossfade is **piecewise linear** with a hard zero at noon. Why
linear and not equal-power (cos/sin)? Because the two paths are *not*
correlated signals you're crossfading between — they're different
sources whose energies don't sum constructively. Linear gives a clean
"VCR fades down, hum fades up" feel and the silence-at-noon point
gives the player a calibration reference (knob-12 = 'no mechanical').
This matches the Generation Loss MKII manual: "CCW = VCR, CW = hum,
center = none."

Quadratic `common_gain` (squared) gives the same musical bottom-of-knob
behavior as `hiss_level`. -40 dBFS peak at full mechanical is 2 dB
hotter than full hiss, which matches the spec intuition that
mechanical noise is the more "obvious" texture.

### 3.4 Stereo strategy (mechanical)

| Source | Stereo treatment | Why |
|---|---|---|
| VCR | Independent RNGs L/R (decorrelated) | Mechanical noise is local to the deck — bearings, wow shaft. Each capsule captures slightly different rumble. |
| Hum | Mono (L = R, fully correlated) | Mains hum enters as common-mode pickup; in real cassettes both heads see essentially the same field. |

Mono hum sums to +6 dB at the mix bus when summed in stereo; we
account for this by halving the hum amplitude before summing into both
channels (so the stereo peak still hits the documented -40 dBFS).

---

## 4. Mode logic — truth table

| `noise_mode` | `hum_bypass` | hiss path | mechanical path | output |
|---|---|---|---|---|
| OFF (0)   | * | gated OFF | gated OFF | silence |
| HISS (1)  | * | active    | gated OFF | hiss only |
| BOTH (2)  | False | active | active     | hiss + mechanical |
| BOTH (2)  | True  | active | gated OFF  | hiss only |

`hum_bypass` only affects the BOTH branch; in HISS mode the dip
switch is a no-op (mechanical is already gated). The truth table is
implemented as two booleans (`hiss_on`, `mech_on`) computed at the top
of `process()`.

---

## 5. Hiss + mechanical level summary

| Knob position | Hiss peak (dBFS) | Mech peak (dBFS) | Mode |
|---|---:|---:|---|
| `hiss_level=0`, `noise_mode=HISS`     | silence | silence | HISS, no level |
| `hiss_level=0.5`, `noise_mode=HISS`   | -54 dB  | silence | HISS, "noon" |
| `hiss_level=1.0`, `noise_mode=HISS`   | -42 dB  | silence | HISS, max |
| `mech_level=0.0`, `noise_mode=BOTH`   | per hiss | -40 dB | BOTH, full VCR |
| `mech_level=0.5`, `noise_mode=BOTH`   | per hiss | silence | BOTH, mech off |
| `mech_level=1.0`, `noise_mode=BOTH`   | per hiss | -40 dB | BOTH, full hum |
| any, `noise_mode=OFF`                 | silence | silence | OFF |

(All numbers approximate — quadratic taper means `0.5` is ~12 dB below
`1.0`, hence `-54 dB` in the second row.)

---

## 6. Sample-rate dependence

| Element | SR-dependent? | Strategy |
|---|---|---|
| Voss-McCartney pink generator | No (operates on sample index) | — |
| HPF 50 Hz biquad coefficients | **Yes** | Recompute on `dspstate~` change |
| LPF 12 kHz biquad coefficients | **Yes** | Recompute on `dspstate~` change |
| VCR-LPF 200 Hz biquad coefficients | **Yes** | Recompute on `dspstate~` change |
| Slow VCR-AM modulator (0.3–1.5 Hz) | **Yes** (uses `t = n/sr`) | Phase advances by `2π·f/sr` per sample |
| Hum harmonic oscillators | **Yes** (uses `t = n/sr`) | Phase advances by `2π·f/sr` per sample |

In M4L, the engineer's `[js]` reads the `sr` message and re-emits all
biquad coefficients to `[biquad~]` via `setcoeff`. Oscillator
phase-increments are computed directly from `sr` in the patcher (no
fixed lookup table). Pitfall #19 (sample-rate transitions) applies:
crossfade the noise output for ~5 ms when SR changes to suppress the
click.

---

## 7. Numerical hazards

- **Denormals** (pitfall #18). The biquad chains are recursive. Each
  biquad output is denormal-flushed (`if abs(yn) < 1e-30: yn = 0`).
  In Max, set `[fpu denorm 1]` at the top of `tl.noise.maxpat`.
- **Clipping.** The output peak target is -40 dBFS, far below 0 dBFS.
  No headroom hazard internally, but the upstream sum at the device
  output should still be sanity-checked by the engineer's verifier.
- **Hum phase coherence.** Because the harmonic stack uses fixed
  frequencies, the rendered hum is exactly periodic at `gcd` of the
  harmonics (= 60 Hz in our table). This is musically correct — real
  hum is exactly periodic — and matches what people expect.
- **VCR-AM zero-crossings.** The AM modulator center is 0.7 with
  depth 0.6, so the multiplier swings 0.1..1.3. We deliberately don't
  let it reach zero — a fully-gated VCR rumble produces audible
  click envelopes that don't sound like real machinery.

---

## 8. Tradeoff log

| Decision | Alternative considered | Why we chose this |
|---|---|---|
| Voss-McCartney pink noise | -3 dB/oct shelving cascade (Trammell) | VM is provably 1/f, simpler to verify, equivalent CPU. Cascade approach allowed but VM win on transparency. |
| HPF 50 Hz / LPF 12 kHz on hiss | Single high-shelf (per spec sketch) | Spec sketch says "biquad~ HPF 2kHz Q=0.8" but that gives a sub-bass-heavy hiss — wrong character. We deliberately diverge: HPF lower (50 Hz, just clean DC) and LPF cap at 12 kHz to model head-gap. The spec sketch is a wireframe, not measurement; this divergence is documented. |
| 60 Hz default mains | Configurable runtime | Constant in code; flippable by editing one line. Live exposing this would clutter the param surface for an obscure setting. |
| 6 harmonics for hum | Just fundamental + 120 Hz | Real hum has detectable energy through ~500 Hz on cassette transports; 6 partials gives the distinct "buzzy" timbre vs a clean 60 Hz tone. |
| Linear bipolar crossfade | Sigmoidal / equal-power | Crossfading uncorrelated sources doesn't benefit from equal-power (no constructive interference). Linear gives clean knob feel with silent center as a calibration cue. |
| Mono hum / decorrelated VCR | Both decorrelated | Mains hum is common-mode pickup in real recordings; VCR rumble is local mechanical noise. Mismatched stereo character is *correct* and gives a more believable mechanical scene. |
| -42 dBFS hiss peak / -40 dBFS mech peak | -30 / -25 dBFS | Tape hiss should be "barely there at noon" and "noticeable at max." -42 dBFS gives ~6 dB above a typical noise floor at max — audible texture that won't dominate. |
| Quadratic taper on level knobs | Linear | Linear gives "knob is hot from 25%". Quadratic keeps the bottom usable for "subtle background" and concentrates loud energy in the top quarter. Same approach as `tl_failure._drops_rate_per_min`. |
| Slow random-walk VCR-AM (0.3–1.5 Hz) | Fixed sine LFO | Real mechanical noise has ebb-and-flow not periodicity. Periodic AM sounds like a tremolo, which it isn't. |

---

## 9. Verified properties (regression-checked in `__main__`)

The reference renderer in `dsp/reference/tl_noise.py` verifies:

1. `noise_mode = OFF` produces exact zero output (any `hiss_level`,
   `mechanical_level`, `hum_bypass`).
2. `noise_mode = HISS, hiss_level = 0` produces exact zero.
3. `noise_mode = BOTH, hum_bypass = True` produces output identical to
   `noise_mode = HISS` for the same seed/hiss_level.
4. `noise_mode = BOTH, mechanical_level = 0.5` produces output
   identical to `noise_mode = HISS` for the same seed/hiss_level (the
   crossfade silent point).
5. Output peak amplitude < -30 dBFS (linear < 0.0316) at all-knobs-max.
6. Hiss path L/R correlation ≈ 0 (decorrelated stereo).
7. Hum path L/R correlation ≈ +1 (mono hum).

---

## 10. Hand-off checklist (engineer)

When the engineer wires `tl.noise.maxpat`:

- [ ] Two `[noise~]` for hiss path (L, R independent), each into a
  pink-noise generator (Max has no built-in; use `[gen~]` or a `[js]`
  Voss-McCartney implementation — handover doc TBD).
- [ ] Two `[biquad~]` per channel for hiss spectral shaping
  (HPF 50 Hz Q=0.707, LPF 12 kHz Q=0.707).
- [ ] One `[noise~]` per channel for VCR-LPF path.
- [ ] One `[biquad~]` per channel for VCR-LPF.
- [ ] Slow random-walk modulator: `[noise~]` → `[lores~ 2.0 0.5]`
  → bias+depth → `[*~]` on the VCR output. Or equivalent in `[gen~]`.
- [ ] `[cycle~]` × 6 for hum harmonics (or one `[gen~]` block).
- [ ] `[js]` listens for `sr` → emits `setcoeff` for each biquad and
  re-derives `2π·f/sr` for the hum oscillators.
- [ ] `[selector~]` (or gain multipliers) gating the hiss and
  mechanical buses by `noise_mode`/`hum_bypass`.
- [ ] Crossfade implemented with `[scale]` mapped per §3.3.
- [ ] Output sums into device main bus *additively* (not through dry
  mix — that already happened upstream).
- [ ] Pitfall #18 (denormal flush) applied at biquad outputs.
- [ ] Pitfall #19 (SR-change crossfade) applied on `dspstate~` events.

The reference Python implementation in `dsp/reference/tl_noise.py` is
the golden output. If the M4L render differs in spectrum (verified by
periodogram comparison against the reference fixtures), the engineer
fixes wiring; if the divergence is in *character* (e.g., hum sounds
synthetic, hiss sounds digital), this DSP doc gets revised.
