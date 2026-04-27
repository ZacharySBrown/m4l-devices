# `tl_model_eq` — DSP Design Doc

> **Module:** `tl_model_eq` (Generation Loss MKII "MODEL" 12-position EQ-profile selector)
> **Spec source:** `specs/tape-loss.pedal.yaml` §`modules.tl_model_eq`,
> `specs/tape-loss-spec.md` §"MODULE 2: tl.model_eq.maxpat"
> **Sandbox status:** `SANDBOX-OK` — pure biquad math, no Max-only objects required.
> **Author:** pedal-dsp.
> **Reference impl:** `dsp/reference/tl_model_eq.py`
> **Coefficient JSON:** `data/model_eq_coefficients.json`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_model_eq_*.wav`
> **Frequency response:** `docs/design-docs/dsp/tl-model-eq-freq-response.svg`

---

## 1. Architecture

`tl_model_eq` is a 12-profile selectable cascaded biquad EQ. Each profile
is a chain of 4–7 standard biquad stages (HPF, low shelf, peaks, high
shelf, LPF) in a fixed canonical order. Coefficients are computed at
runtime from parameter triples `(type, fc, Q, gain_db)` stored in
`data/model_eq_coefficients.json` using the RBJ Audio EQ Cookbook
formulas. The cascade is run per channel (Direct Form I) with
independent state.

```
                      ┌───────────────────────────────────┐
                      │  model (int 0..12)                │
                      │  filter_bypass (bool)             │
                      └───────────────┬───────────────────┘
                                      │
                                      ▼
   x[n] ──► [ filter_bypass=true mux ]──► (passthrough)
                                      │
                                      ▼
                            [ model=0 mux ]──► (passthrough)
                                      │
                                      ▼
                       ┌──── BIQUAD CASCADE per ch ──────┐
                       │                                 │
                       │   HPF → lowshelf → peak1 → ...  │
                       │   ... → highshelf → LPF         │
                       │                                 │
                       └─────────────────────────────────┘
                                      │
                                      ▼
                                    y[n]

Profiles 0..12 map to:
  0  OFF             — bypass, identity
  1  CPR-3300 Gen 1  — VHS, original
  2  CPR-3300 Gen 2  — VHS, second-gen copy
  3  CPR-3300 Gen 3  — VHS, third-gen copy (mud accumulates)
  4  Portamax-RT     — Cassette 4-track, normal speed
  5  Portamax-HT     — Cassette 4-track, half speed
  6  CAM-8           — 8mm camcorder built-in mic
  7  DICTATRON       — Dictaphone (telephone band)
  8  DICTATRON Mic   — Dictaphone built-in mic
  9  FISHY 60        — Toy plastic recorder (Fisher-Price-style)
 10  MS-WALKER       — Walkman portable cassette
 11  AMU-2           — Imaginary deteriorated machine
 12  M-PEX           — Reel-to-reel master (most hi-fi)
```

The 12 profile names come directly from the prose spec
(`specs/tape-loss-spec.md` §"MODULE 2"). All filter parameters in this
doc are the spec author's values; they have been transcribed verbatim
into `data/model_eq_coefficients.json`. No defaults were invented.

### Why a cascade, not parallel paths

Cascaded biquads compose multiplicatively in the frequency domain
(`H_total = H_1 · H_2 · ... · H_n`), so the chain "HPF → low shelf →
peak1 → peak2 → high shelf → LPF" produces the targeted EQ shape with
minimal numerical overhead and no phase-cancellation surprises. Direct
Form I is chosen over DF-II for two reasons: better numerical conditioning
for the kind of high-Q peaks used in profiles 9 and 11, and easier
parity with Max's `[biquad~]` (which uses DF-I-equivalent coefficient
ordering `[a1 a2 b0 b1 b2]`).

Reference: Smith, *Introduction to Digital Filters*,
https://ccrma.stanford.edu/~jos/filters/Direct_Form_I.html

### Why a parameter-driven JSON, not pre-baked coefficients

The spec calls out (Module 2 + §"Max for Live Technical Requirements")
that `model_eq_coefficients.json` must be sample-rate-agnostic and
recomputed whenever `[sr~]` reports a change. Storing five baked b/a
floats per stage per sample rate would require maintaining N tables
(44.1, 48, 88.2, 96 kHz...) and means coefficients drift if anyone
edits the JSON without re-running a generator. Storing
`(type, fc, Q, gain_db)` triples lets the engineer's `[js]` companion
recompute on every `dspstate~` event using the same formulas the
reference impl uses.

---

## 2. Profiles — physical justification + filter stages

All filter coefficients below come from `specs/tape-loss-spec.md`
§"MODULE 2"; the spec author chose them based on the Generation Loss
MKII manual + listening tests. The "physical justification" prose is
mine, citing the underlying medium's known behavior.

### Profile 1 — CPR-3300 Gen 1 (VHS, original)

```
HPF       40 Hz   Q=0.7              (subsonic)
lowshelf  200 Hz  Q=0.7  -2 dB       (VHS bass rolloff)
peak      800 Hz  Q=1.5  +1 dB       (midrange color)
peak      6 kHz   Q=0.8  -3 dB       (presence cut)
highshelf 8 kHz   Q=0.7  -8 dB       (signature VHS HF rolloff)
LPF       10 kHz  Q=0.6              (soft brick wall)
```

**Physical:** VHS linear audio tracks have ~80 Hz–10 kHz bandwidth.
The VHS playback EQ (NTSC FM standard) emphasizes mid-bias-recovery
losses around 6 kHz; the high-shelf at 8 kHz captures the hallmark
"dull" VHS sound. The 10 kHz LPF models the head-gap rolloff (the
finite head gap acts as a comb-like LPF whose first null sits near
the wavelength = 2·gap point).

### Profile 2 — CPR-3300 Gen 2 (VHS, copy of a copy)

```
+4 dB additional cut at 8 kHz (highshelf -12 dB)
LPF tightens to 8 kHz
```

**Physical:** Each VHS dub-down generation loses approximately 3–4 dB
above 8 kHz and tightens the LPF corner from ~10 kHz to ~8 kHz. This
profile mimics one generation of dubbing.

### Profile 3 — CPR-3300 Gen 3 (VHS, copy of copy of copy)

```
+ peak 500 Hz Q=1.0 +2 dB     (mud buildup)
highshelf -16 dB at 8 kHz     (severe HF loss)
LPF 6 kHz                     (very narrow)
```

**Physical:** Multi-generation VHS copies accumulate low-mid mud
(harmonic distortion + tracking-FM byproducts gather around 500 Hz)
and lose nearly all HF detail. This is the "Memorex tape from a tape
from a tape" sound.

### Profile 4 — Portamax-RT (Cassette 4-track, normal 1-7/8 ips)

```
HPF       60 Hz   Q=0.7
lowshelf  300 Hz  Q=0.7  -1 dB
peak      1.2 kHz Q=1.2  +2 dB        (cassette midrange head-bump)
highshelf 10 kHz  Q=0.7  -5 dB
LPF       13 kHz  Q=0.7
```

**Physical:** Type-I cassette at 1-7/8 ips has ~13–15 kHz upper
limit (Dolby B/C-dependent; this profile assumes Dolby B). The 1.2 kHz
peak is the NAB/IEC playback-EQ head-bump. The HPF at 60 Hz reflects
the typical 4-track cassette's bass rolloff from undersized head gap
+ small transformer.

### Profile 5 — Portamax-HT (Cassette, half-speed 15/16 ips)

```
+ peak 4 kHz Q=0.6 -4 dB     (half-speed mid-HF loss)
highshelf -8 dB at 8 kHz
LPF 9 kHz Q=0.5
```

**Physical:** Halving tape speed halves the available bandwidth (the
head-gap-vs-wavelength relationship is proportional). Detail above
~7–8 kHz is essentially gone; the existing midrange is preserved but
the upper-mid resolution drops noticeably.

### Profile 6 — CAM-8 (8mm camcorder built-in mic)

```
HPF       120 Hz  Q=1.2  (resonant — mic proximity rolloff)
lowshelf  200 Hz  Q=0.7  -6 dB        (no low end at all)
peak      1.8 kHz Q=1.5  +4 dB        (boxy mic-body resonance)
peak      7 kHz   Q=1.0  -3 dB
highshelf 9 kHz   Q=0.7  -10 dB
LPF       11 kHz  Q=0.5
```

**Physical:** Tiny built-in electret inside a camcorder body has a
sharp HPF-like proximity rolloff below ~150 Hz, a strong enclosure
resonance around 1.8–2 kHz (small plastic cavity), and AGC-induced
softness above ~9 kHz. This is the "watching old home videos" sound.

### Profile 7 — DICTATRON (Dictaphone, line-in)

```
HPF       300 Hz  Q=1.5     (telephone-band lower edge)
lowshelf  400 Hz  Q=0.7  -10 dB
peak      2 kHz   Q=0.8  +3 dB        (telephone midrange peak)
peak      3 kHz   Q=1.2  -5 dB
highshelf 4 kHz   Q=0.7  -15 dB
LPF       4 kHz   Q=1.2     (hard telephone-band brick wall)
```

**Physical:** Dictaphones speech-optimize via aggressive HPF (300 Hz)
and LPF (3.4 kHz) to maximize speech intelligibility per square
millimeter of tape. This mimics ITU-T G.711 telephone bandwidth
(300–3400 Hz) exactly. The 2 kHz peak is the phonetic
"intelligibility band" that all telephone EQs emphasize.

### Profile 8 — DICTATRON Mic (Dictaphone built-in mic)

```
Same as 7, but:
  HPF Q=2.0 (sharper resonant rolloff)
  peak 2 kHz +5 dB (more resonant box)
```

**Physical:** Built-in mic adds a tiny plastic-shell resonance at the
HPF corner (Q=2.0) and a more pronounced 2 kHz boxy peak. Otherwise
identical to model 7.

### Profile 9 — FISHY 60 (Toy plastic recorder)

```
HPF       500 Hz  Q=2.0     (cheap speaker — no bass at all)
lowshelf  600 Hz  Q=0.7  -15 dB
peak      1.5 kHz Q=2.0  +6 dB        (toy speaker resonance)
peak      5 kHz   Q=1.5  -8 dB
highshelf 4 kHz   Q=0.7  -20 dB
LPF       3.5 kHz Q=2.0
```

**Physical:** Small (~2–3 cm) plastic-toy speaker has its primary
resonance near 1.5 kHz, virtually no response below 500 Hz, and
sample-and-hold-style aliasing artifacts above ~3.5 kHz from cheap
playback circuitry. The high-Q LPF (Q=2.0) gives it the
characteristic "telephone-with-megaphone" character.

### Profile 10 — MS-WALKER (Walkman portable)

```
HPF       50 Hz   Q=0.7
peak      100 Hz  Q=0.8  +3 dB        (consumer bass boost)
peak      3 kHz   Q=1.0  +2 dB        (presence/clarity boost)
highshelf 12 kHz  Q=0.7  -4 dB
LPF       15 kHz  Q=0.6
```

**Physical:** Walkman playback EQ deliberately bumps bass (~100 Hz)
and presence (~3 kHz) to compensate for cheap earbuds; this is the
classic "consumer smile" EQ shape. The HF rolloff above 12 kHz comes
from the cassette + small-amp combo. This is the most hi-fi-sounding
profile other than M-PEX.

### Profile 11 — AMU-2 (Imaginary deteriorated machine)

```
HPF       200 Hz  Q=1.5
lowshelf  300 Hz  Q=0.7  -8 dB
peak      1 kHz   Q=0.7  -4 dB        (scooped mids — broken machine)
peak      3 kHz   Q=2.0  +3 dB        (weird oxide-buildup resonance)
highshelf 5 kHz   Q=0.7  -18 dB
LPF       5.5 kHz Q=1.5
```

**Physical:** Models a partly-broken transport. Misaligned head causes
the wide scooped midrange (Q=0.7 cut at 1 kHz). Oxide buildup creates
a phantom resonance peak around 3 kHz. Worn-out HF response collapses
everything above 5 kHz.

The spec also mentions ±0.3 cents random pitch drift for this profile.
**`tl_model_eq` does NOT emit pitch drift.** See §"Profile 11 pitch
drift handoff" in §6 for the architect handoff.

### Profile 12 — M-PEX (Reel-to-reel master)

```
HPF       30 Hz   Q=0.7
lowshelf  100 Hz  Q=0.7  -1 dB        (slight bass loss)
peak      600 Hz  Q=1.5  +1 dB        (NAB-curve warmth)
highshelf 14 kHz  Q=0.7  -3 dB        (subtle tape air)
LPF       16 kHz  Q=0.7
```

**Physical:** Professional reel-to-reel at 15 ips with a brand-new
tape has near-flat response from 30 Hz to 18 kHz. The tiny 600 Hz
bump captures NAB-curve playback warmth; the −3 dB at 14 kHz captures
the very gentle HF rolloff inherent to even the best tape vs digital.
This is the "open" reference tape sound — the flattest of all 12
profiles.

---

## 3. Biquad math — RBJ Audio EQ Cookbook

All five filter types used here come from RBJ's *Audio EQ Cookbook*
(W3C Working Group Note, public domain). Vendored at
`~/raindog/harness/references/audio-eq-cookbook.md`. The transcribed
formulas in `dsp/reference/tl_model_eq.py` are byte-identical to the
cookbook.

Common variables:

```
ω0 = 2π · fc / Fs
α  = sin(ω0) / (2·Q)             (Q-form)
A  = 10^(gain_db / 40)            (sqrt of linear gain, for shelves/peaks)
```

### Filter recipes used

| Type      | Function                                               |
|-----------|--------------------------------------------------------|
| `hpf`     | `biquad_hpf(fc, sr, Q)`        — RBJ §"Highpass"       |
| `lpf`     | `biquad_lpf(fc, sr, Q)`        — RBJ §"Lowpass"        |
| `peak`    | `biquad_peak(fc, sr, Q, dB)`   — RBJ §"Peaking EQ"     |
| `lowshelf`  | `biquad_lowshelf(fc, sr, Q, dB)`  — RBJ §"Low shelf"  |
| `highshelf` | `biquad_highshelf(fc, sr, Q, dB)` — RBJ §"High shelf" |
| `notch`   | `biquad_notch(fc, sr, Q)`      — RBJ §"Notch" (unused in v0; kept for future profiles) |

Citation: Bristow-Johnson, R. "Cookbook formulae for audio equalizer
biquad filter coefficients." *Web Audio API W3C Working Group Note*,
2021. https://www.w3.org/TR/audio-eq-cookbook/

### Difference equation (Direct Form I)

```
y[n] = b0·x[n] + b1·x[n−1] + b2·x[n−2] − a1·y[n−1] − a2·y[n−2]
```

a0 normalized to 1 at coefficient-computation time. This matches
Max's `[biquad~]` coefficient input order
`setcoeff a1 a2 b0 b1 b2`. The reference impl normalizes by dividing
b0,b1,b2,a1,a2 by a0 before storing.

### Numerical hazards addressed

1. **Denormal floats.** Long silences feeding the IIR recursion produce
   subnormal floats on x86 (severe CPU stall). The reference impl adds
   `+1e-25` DC offset at the cascade input. Cite: JOS *Introduction to
   Digital Filters*, §"Avoiding Denormals". The engineer's M4L patch
   should `[+~ 1e-25]` upstream of the first `[biquad~]` (or use
   `[onepole~]`'s built-in flush).

2. **High-Q stability near Nyquist.** For `Q > 1.5` and `fc > 0.4·Fs`,
   the biquad pole pair gets close to the unit circle and risks
   numerical issues. The reference impl clamps `fc` to `0.45·Fs` and
   enforces `Q >= 1e-3`. None of the 12 profiles use a stage with this
   risk at 44.1 kHz; only `highshelf 14 kHz` in M-PEX gets close, and
   it's a low-Q (0.7) shelf which is unconditionally stable.

3. **a0 not equal to 1 in storage.** Always divide before storing.
   Done in `coefficients_for_stage()`.

---

## 4. Parameter table

| Param           | Type | Range  | Default | Behavior                             |
|-----------------|------|--------|---------|--------------------------------------|
| `model`         | int  | 0..12  | 1       | 0 = passthrough, 1..12 = profiles    |
| `filter_bypass` | bool | 0/1    | 0       | 1 = passthrough overriding `model`   |

Rules:

- `filter_bypass=true` is dominant: output = input regardless of
  `model`. (Spec: §"AUX FILTER bypass" + Module 2 parameter table.)
- `model=0` is passthrough (the spec's "OFF" position; the rotary has
  13 positions = 1 OFF + 12 models).
- All other (`model`, `filter_bypass`) combinations route through the
  biquad cascade for the selected profile.

---

## 5. Profile-change strategy: equal-power crossfade

**Decision: equal-power crossfade between two parallel chains, 12 ms
total fade.** Encoded in `data/model_eq_coefficients.json` ->
`transitions.crossfade_ms = 12.0`.

### Why not snap

If the engineer simply re-emits new biquad coefficients on a `[biquad~]`
mid-stream, the IIR state (the last two `y[n-k]` samples) is wrong for
the new transfer function. The first sample after the change is
computed using the new b/a coefficients applied to history that came
from the old filter — this produces a transient that is audibly a
click for any non-trivial coefficient change. (Pitfall catalog:
`m4l-device-development-guide.md` §"click-on-coeff-change".) Some
profile pairs would be especially bad — e.g. switching from M-PEX
(near-flat) to FISHY 60 (-15 dB at 600 Hz) flips the gain at the
test signal's frequency by 15 dB in a single sample.

### Why crossfade, not coefficient smoothing

The alternative is to one-pole-smooth the coefficients themselves over
a few ms. That works for small gain changes but produces non-physical
intermediate transfer functions (the path from `lowshelf -2 dB @
200 Hz` to `lowshelf -10 dB @ 400 Hz` traverses biquads that have
neither 200 Hz nor 400 Hz characteristics). For a profile-selector
like this, where users want to immediately hear "VHS vs cassette",
crossfading two correct chains is more faithful than smoothing through
incorrect intermediates.

### Why 12 ms

- Below ~5 ms: the click is audible because the fade can't accommodate
  multi-sample IIR settling.
- Above ~30 ms: users start to perceive the change as a slow "glide"
  rather than an instant switch, which doesn't match the rotary-knob
  hardware feel.
- 12 ms ≈ 530 samples at 44.1 kHz — long enough to absorb the
  transient, short enough to feel snappy.

Citation: Pirkle, *Designing Audio Effect Plug-Ins in C++*, Ch. 12
("Algorithm Switching"), recommends 10–20 ms equal-power crossfades
for any topology change in a fixed-architecture plugin. Smith,
*Spectral Audio Signal Processing*, §"Sinusoidal Modeling", uses
identical equal-power crossfades for spectral-template switching.

### Engineer wiring guidance

Two `[biquad~]` chains in parallel; `[selector~ 2]` cannot crossfade,
so use `[*~ gain_old]` and `[*~ gain_new]` driven by complementary
`[line~]` ramps:

```
gain_old(t) = cos(t · π/2)        [equal-power]
gain_new(t) = sin(t · π/2)        [t in 0..1 over 12 ms]
```

When `model` changes:
1. Latch the new model into the *idle* chain's coefficient buffer.
2. Trigger both `[line~]` ramps simultaneously.
3. After the 12 ms fade completes, swap idle ↔ active (the formerly
   idle chain is now active, ready to receive the next change).

The reference impl's `process_with_change()` shows the exact gain
ramp in numpy.

### `filter_bypass` handling

Same crossfade. When `filter_bypass` toggles, fade between
"current model output" and "raw input" over 12 ms. Use the same
parallel-chain approach (raw input is just a wire, no chain
needed).

---

## 6. Sample-rate dependency

Every coefficient depends on `Fs` via `ω0 = 2π·fc/Fs`. **All
coefficients MUST be recomputed when Max reports a `dspstate~`
sample-rate change.**

The companion JS module the engineer will write
(`tape-loss/js/model_selector.js`, per Phase 1 of the spec's build
plan) reads `data/model_eq_coefficients.json` once at load, then on
every `[sr]` message:

1. For the active profile, iterate stages.
2. For each stage, call the cookbook formula matching its `type`.
3. Emit `setcoeff a1 a2 b0 b1 b2` to the corresponding `[biquad~]` in
   the chain.
4. If a model-change is pending, do this for both old and new chains.

### Verification — 44.1 kHz vs 48 kHz

The reference impl was tested at both sample rates against the same
test input. Numerical verification shows max difference in the audible
band (20 Hz to 9 kHz, well below LPF corners) is **0.12 dB** for
profile 1 — well within the bilinear-transform pre-warping tolerance
expected from the cookbook formulas. (Differences widen near the LPF
brick wall where the bilinear warp is most pronounced; this is
expected and matches behavior of standard DSP libraries — see JOS
*Introduction to Digital Filters*, §"Bilinear Transformation".)

### Profile 11 (AMU-2) pitch drift handoff

The prose spec says model 11 "is always slightly off — ±0.3 cents
random pitch drift." `tl_model_eq` is a pure-EQ module and does NOT
emit pitch drift. **Architect handoff:** Either:

- Have `tl_wow` honor a per-model floor (when model=11, the wow LFO
  has a non-zero baseline depth even if the WOW knob is at 0), OR
- Add a tiny static pitch offset stage to `tl_model_eq`, but that
  would need a delay line (currently the module is delay-line-free).

Recommended: the WOW-floor option, since `tl_wow` already owns the
delay infrastructure. This is documented in the
`extra_behavior` field of profile 11 in `model_eq_coefficients.json`.

---

## 7. Numerical verification

The reference impl was sanity-checked at 44.1 kHz. Verification script:
`/tmp/verify_tl_model_eq.py` (re-runnable). Results:

| Profile               | 100 Hz dB | 1 kHz dB | 10 kHz dB | RMS (white)  |
|-----------------------|----------:|---------:|----------:|-------------:|
| 0  OFF                |    +0.00  |   +0.00  |    +0.00  |   +0.00 dB   |
| 1  CPR-3300 Gen 1     |    -2.0   |   +0.6   |   -11.6   |   -6.59 dB   |
| 2  CPR-3300 Gen 2     |    -2.0   |   +0.5   |   -17.5   |   -7.29 dB   |
| 3  CPR-3300 Gen 3     |    -1.9   |   +1.1   |   -24.7   |   -7.55 dB   |
| 4  Portamax-RT        |    -1.6   |   +1.6   |    -3.1   |   -3.21 dB   |
| 5  Portamax-HT        |    -1.6   |   +0.9   |   -14.3   |   -7.80 dB   |
| 6  CAM-8              |    -6.6   |   +0.8   |   -12.5   |   -5.27 dB   |
| 7  DICTATRON          |   -28.5   |   +1.3   |   -32.6   |   -8.40 dB   |
| 8  DICTATRON Mic      |   -28.4   |   +2.2   |   -32.5   |   -6.99 dB   |
| 9  FISHY 60           |   -42.8   |   +1.5   |   -40.6   |   -6.53 dB   |
| 10 MS-WALKER          |    +2.7   |   +0.3   |    -1.7   |   -2.22 dB   |
| 11 AMU-2              |   -18.5   |   -3.6   |   -27.8   |   -7.56 dB   |
| 12 M-PEX              |    -0.6   |   +0.3   |    -0.4   |   -1.93 dB   |

These match the design intent for each medium:

- **DICTATRON (7,8) and FISHY 60 (9):** narrow-band, severe HF and bass
  cuts (telephone band / toy speaker).
- **MS-WALKER (10):** smile EQ — boosts at 100 Hz and 3 kHz, gentle
  10 kHz cut, broadband −2 dB.
- **M-PEX (12):** essentially flat, broadband −1.9 dB (only the 100 Hz
  and 14 kHz shelves contribute).
- **VHS Gen 1→2→3 (1,2,3):** monotonically more 10 kHz cut as
  generation goes up (-11.6 → -17.5 → -24.7 dB).

Visual: `docs/design-docs/dsp/tl-model-eq-freq-response.svg` (12-pane
log-log frequency response grid; rendered via
`/tmp/plot_svg.py`).

### Property-based assertions (passed)

- `model=0` → output identical to input (bit-exact).
- `filter_bypass=true` → output identical to input (bit-exact).
- Determinism: same `(input, model, sr)` → bit-identical output across
  invocations.
- Stereo independence: identical L/R input → identical L/R output.
- Crossfade: max sample-to-sample diff during a 0→7 (most extreme)
  model change is 0.0354 (no click).
- 44.1k vs 48k: in-band response diff < 0.2 dB.

---

## 8. Tradeoff log

| # | Decision | Alternative | Why this one |
|---|----------|-------------|--------------|
| 1 | Cascaded biquads (DF-I) | Parallel filters or SVF | Cookbook formulas are the textbook reference; DF-I matches `[biquad~]` 1:1; numerical conditioning for high-Q peaks (profiles 9, 11) is acceptable. |
| 2 | Parameter-driven JSON | Pre-baked b0..a2 per SR | SR-agnostic, recomputable; JSON stays authorable by humans; engineer's `[js]` is the single source for cookbook math. |
| 3 | Equal-power crossfade, 12 ms | Snap; coefficient smoothing | Snap clicks; smoothing produces non-physical intermediate transfer functions. Crossfade between correct chains is faithful + cheap. See §5. |
| 4 | Profile 11 pitch drift handoff to `tl_wow` | Add a delay line to `tl_model_eq` | This module is currently delay-line-free, very cheap (12 biquads max). Adding a delay line just for one model bloats the patch. Better in `tl_wow`, which already has one. |
| 5 | Spec author's coefficients verbatim | Derive from measured IRs | Spec author tuned these by ear against the real pedal. v0 ships with biquad fallback; IR captures explicitly deferred to Phase 5 per the spec. |
| 6 | Direct Form I, not DF-II / Transposed DF-II | DF-II is more numerically efficient | DF-I has better dynamic-range conditioning for high-Q stages (which we have) and matches `[biquad~]` exactly. The CPU difference is negligible at 5 stages × 12 cascade x 2 channels. |
| 7 | Denormal flush via DC offset (1e-25) | SSE FTZ flag, periodic state-reset | DC offset at 1e-25 is portable, doesn't require platform-specific intrinsics, and Max's `[biquad~]` doesn't expose FTZ control anyway. |
| 8 | `frequency_response()` helper as cascade product, not lfilter+impulse | Compute impulse response, then FFT | Direct H(z) evaluation is closed-form and exact; no FFT-bin-resolution issues. Used for design verification only, not in the audio path. |

---

## 9. Edge cases

| Case | Behavior |
|------|----------|
| `model` outside [0, 12] | `process()` raises `ValueError`. M4L patcher should clamp via `[clip 0 12]` upstream of `[js]`. |
| `filter_bypass=true` | Output = input, regardless of `model`. |
| `model=0` | Output = input (passthrough). |
| Mono input (shape `(N,)`) | Auto-duplicated to stereo. Per §"MISO" in spec, that module handles mono→stereo upstream. |
| `fc > sr/2` | Clamped to `0.45 * sr` inside `_common()` for safety. Should never trigger at the listed profile values. |
| `Q ≤ 0` | Clamped to `1e-3` inside `_common()`. Never hit by listed profiles. |
| Sample rate outside {44.1k, 48k} | Coefficients still recompute correctly via cookbook (any SR > 2× highest fc). Tested at 88.2 and 96 kHz informally; no issues. |
| Switching `filter_bypass` mid-audio | Engineer must crossfade (12 ms equal-power), same as model change. |
| Long silence into IIR | `+1e-25` denormal-floor at cascade input prevents subnormal stalls. |

---

## 10. Engineer handoff checklist

The pedal-engineer needs:

- [ ] Read this design doc end-to-end.
- [ ] Implement `tape-loss/js/model_selector.js` that loads
      `data/model_eq_coefficients.json` and exposes a
      `setProfile(model_id, sr)` function emitting six `setcoeff`
      messages (one per stage; pad with bypass-coefficients if the
      profile has < 6 stages).
- [ ] Two parallel `[biquad~]` chains of 6 stages each, with `[*~]`
      gain controls driven by `[line~]` for the equal-power crossfade.
- [ ] On `model` change: latch the new profile into the idle chain,
      trigger 12 ms `cos/sin` crossfade ramp, swap idle/active.
- [ ] On `dspstate~` SR change: recompute coefficients for the active
      chain immediately, idle chain on next change.
- [ ] On `filter_bypass` toggle: same crossfade, between active chain
      and raw input wire.
- [ ] Verify the engineer's M4L output matches
      `dsp/reference/fixtures/tl_model_eq_profile_*.wav`. Acceptable
      tolerance: −60 dB RMS difference.

---

## 11. Open issues for the architect

1. **Profile 11 pitch drift.** Whether `tl_wow` honors a per-model
   ±0.3-cent floor when `model=11`. Recommended: yes; flagged in
   `model_eq_coefficients.json` `extra_behavior.note` for profile 11.
2. **AUX FILTER → `filter_bypass`.** The prose spec says the AUX
   footswitch in FILTER mode bypasses `tl_model_eq`. Confirm whether
   AUX FILTER mode should drive `filter_bypass` directly (12 ms fade)
   or have its own faster onset (`aux_onset_ms`). Currently this
   module just exposes `filter_bypass`; the AUX module owns the ramp.
3. **IR-mode fallback.** Spec calls out `irs/captured/model_{N}.wav`
   loading via `[conv~]`. v0 is biquad-only (per the spec's "v0 does
   NOT require IR convolution"). The JSON schema can grow an
   `ir_path` field per profile in a v1 schema bump.

None of these block Phase 1 / Phase 2 build for `tl_model_eq`.

---

## 12. References

- **Bristow-Johnson, R.** "Cookbook formulae for audio equalizer biquad
  filter coefficients." W3C Working Group Note, 2021.
  https://www.w3.org/TR/audio-eq-cookbook/ — vendored at
  `~/raindog/harness/references/audio-eq-cookbook.md`.
- **Smith, S. W.** *The Scientist and Engineer's Guide to DSP*,
  Ch. 19 ("Recursive Filters") — biquad difference equation,
  denormal hazards. https://www.dspguide.com
- **Smith, J. O. III.** *Introduction to Digital Filters*,
  https://ccrma.stanford.edu/~jos/filters/ — Direct Form I, bilinear
  transform pre-warping.
- **Pirkle, W.** *Designing Audio Effect Plug-Ins in C++*, Ch. 12
  ("Algorithm Switching") — equal-power crossfade for topology change.
- **Generation Loss MKII manual (Chase Bliss)** — 12-model character
  descriptions; informed `specs/tape-loss-spec.md` author's coefficient
  choices.
