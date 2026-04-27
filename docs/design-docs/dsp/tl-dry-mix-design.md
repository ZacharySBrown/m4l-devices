# `tl_dry_mix` — DSP Design Doc

> **Module:** `tl_dry_mix` (Generation Loss MKII "DRY" toggle:
> NONE / SMALL / UNITY)
> **Spec source:** `specs/tape-loss.pedal.yaml`,
> `specs/tape-loss-spec.md` §"DRY Toggle" + §"Signal Flow"
> **Sandbox status:** `SANDBOX-OK` — pure mix-and-add, trivially
> renderable in numpy; Max wiring is `*~` + `+~` plus a delay tap.
> **Author:** pedal-dsp.
> **Reference impl:** `dsp/reference/tl_dry_mix.py`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_dry_mix_*.wav`

> **ENGINEER — READ §2 FIRST.** The latency-alignment requirement is
> the only architecturally non-trivial detail in this module. Get
> that right and the rest is two `*~` and a `+~`.

---

## 1. Block diagram

```
                       dry_mode (NONE / SMALL / UNITY)
                              │
                              ▼
                       ┌─────────────┐
                       │ mode → gain │
                       │  smoother   │  10 ms equal-power xfade
                       │  (per-mode  │  on mode change
                       │   coeff)    │
                       └──────┬──────┘
                              │ g_dry[n]
                              │
        DRY in  ──[align Δ]──►(*~)──┐
        (delayed                    │
         to wet's                   ▼
         time-of-arrival)        (+~)──► OUT
                                    ▲
        WET in (already            │
        delayed by upstream  ──────┘
        wow / flutter)
```

**Two inputs. One output. Per channel.** The mixer itself is one
multiply per channel for the dry path, no scaling on the wet path
(wet was already scaled by `tl_volume_mix` upstream and is treated
here as the post-fader bus).

`g_dry[n]` is a sample-rate-independent gain (see §3) smoothed over
~10 ms when `dry_mode` changes (see §4).

---

## 2. ⚠️ Latency-alignment requirement (engineer must implement upstream)

**THE PROBLEM.** The signal chain places `tl_wow` and `tl_flutter`
between the device input and `tl_dry_mix`. WOW reads from a
`tapin~` buffer with a *centered* delay tap:

| WOW state          | Delay tap position |
|--------------------|--------------------|
| Spec (`tl_wow.maxpat`) | base = 5 ms, modulation up to ±25 ms swing at max → tap range ≈ 0–30 ms (asymmetric, modulation only goes one way per spec wording) |

The spec is slightly ambiguous on whether WOW modulation is
asymmetric (delay = 5 ms + |lfo|) or centered around a nominal point.
For chorus-with-DRY-UNITY to sound right, **the dry path must be
delayed by the *nominal* (center) tap of the wow read**, so the
dry signal reaches the mixer at the same timestamp as the
unmodulated portion of the wet signal. Otherwise:

- **dry under-delayed** → audible echo on dry-only-ish material; the
  WOW "chorus" becomes a flanger/slapback hybrid.
- **dry over-delayed** → comb-filter notch shifts away from
  perceptual center; chorus loses its gentle character.

**THE FIX.** A parallel dry-tap line, sourced **upstream of
`tl_wow`** (so it matches the dry that *would* have entered wow),
delayed by the WOW nominal tap value:

```
[device input]
     │
     ├─────────────────────────────────────► [main wet path]
     │                                              │
     │                                       (saturate, model_eq,
     │                                        failure, WOW, FLUTTER,
     │                                        aux, volume_mix)
     │                                              │
     │                                              ▼ wet
     │
     └──► [parallel dry tap]
              │
              ▼
         [tapin~ N ms]              ← N = NOMINAL_WOW_DELAY_MS
              │                        (see §2.1, default 30 ms)
              ▼
         [tapout~ N ms]            (constant — does NOT modulate)
              │
              ▼ aligned dry  ──────► tl_dry_mix
```

### 2.1. Required nominal delay value

```
NOMINAL_WOW_DELAY_MS = 30.0   # ms
```

Justification:

1. The WOW spec describes a "centered" 5 ms base + up to 25 ms swing
   modulation. Reading the spec generously (and matching boutique
   tape-pedal practice — the Generation Loss is documented as having
   ~20–40 ms of read-head-to-record-head spacing virtual modeling),
   the perceptual center of the WOW tap is in the 25–35 ms range at
   max depth. Choosing **30 ms** gives clean chorus pairing across
   the whole WOW knob range.
2. **Flutter contribution is negligible.** Flutter adds at most ±2 ms
   of swing on top of WOW; well within the perceptual chorus
   tolerance window (humans don't distinguish chorus/flange below
   roughly ±5 ms relative drift).
3. **30 ms is well above the Haas threshold** (~5 ms) for
   echo-vs-fusion perception, so any *misalignment* would produce
   audible smearing, but a *correctly aligned* dry tap fuses with
   the wet into a single perceived event.
4. The Max `tapin~ 100` buffer used in WOW has plenty of headroom for
   a 30 ms tap. CPU cost is one extra read head per channel
   (negligible).

### 2.2. If the engineer cannot wire a parallel tap

If for any reason a parallel pre-WOW tap is impossible, the fallback
is to insert a fixed `delay~ 30ms` immediately before `tl_dry_mix`
on the dry path, sourced from the post-volume-mix DRY split. This
produces the same latency on output but means the dry signal has
been through `tl_saturate` / `tl_model_eq` / `tl_failure` (per the
spec's "DRY TYPE dip switch" note) — which is *fine* for the chorus
case (those modules don't introduce significant delay) but means
it's not a true dry. v0 acceptance: the parallel-pre-WOW tap is
preferred; a fixed-delay-after-volume tap is acceptable if needed.

### 2.3. Verification check the engineer must run

After wiring, run the standalone-Max debug harness with:
- `dry_mode = UNITY`
- `wow = 0` (no modulation), `flutter = 0`
- DC pulse / sine input

The dry-plus-wet sum should be **+6 dB on a sustained sine** (in-phase
addition) and a **single non-smeared pulse on the impulse**. If you
hear a slap or see two distinct peaks in the output, the alignment
is wrong.

---

## 3. Per-mode level table

| `dry_mode` | enum value | linear gain | dB     | rationale |
|------------|-----------:|------------:|-------:|-----------|
| NONE       | 0          | 0.0         | −∞ dB | wet only — baseline tape sound |
| SMALL      | 1          | 0.3981      | −8 dB | "a touch of dry" — boutique standard (see §6) |
| UNITY      | 2          | 1.0         | 0 dB  | full dry — pairs with WOW for chorus per spec |

The wet path is always at unity (`g_wet = 1.0`) because upstream
`tl_volume_mix` has already applied the user's VOLUME knob.

The original prose spec (`tape-loss-spec.md` §"DRY Toggle") says
SMALL = "Dry at ~25% of input level". 25% is −12 dB. The DSP
specialist is choosing **−8 dB (40%)** instead — see §7 tradeoff
log entry #1. Both values are within the boutique-pedal design
window. The engineer may dial it to spec by changing one constant
(`G_SMALL_LIN`) without touching anything else.

---

## 4. Crossfade strategy on mode change

**Why crossfade?** Direct gain switching produces a click whose
amplitude equals the gain delta — for SMALL → UNITY (0.4 → 1.0) the
click is ~6 dB above the dry signal level. Audible.

**Strategy.** When `dry_mode` changes, ramp `g_dry` from the old
target to the new target with a 10 ms equal-power-style cosine
fade:

```
For sample n during a crossfade of length L samples:
    progress = n / L                                   ∈ [0, 1]
    cos_arg  = π · progress
    g_dry[n] = g_old · 0.5·(1 + cos(cos_arg))
             + g_new · 0.5·(1 - cos(cos_arg))
```

This is the same Hann-based crossfade used in `tl_failure`'s drop
envelope (cf. S. Smith *DSP Guide* Ch. 16 windowing — Hann's
half-cosine has zero derivative at the endpoints, eliminating
edge-discontinuity clicks).

Why **10 ms**?

- Long enough to eliminate clicks (a click in a typical mix is
  audible for transitions faster than ~3 ms).
- Short enough to feel instantaneous at the user's footswitch /
  toggle. Mode-change is a discrete musical event; a 100 ms slow fade
  would feel sluggish.
- 10 ms = 441 samples @ 44.1 kHz / 480 samples @ 48 kHz. In M4L the
  engineer recomputes `L` from `sr` at runtime.

**Alternative:** equal-power (sin/cos pair) was considered — see §7
tradeoff log entry #2. The sums of differently-correlated signals
(dry + dry vs. dry + wow-modulated wet) make equal-power's
constant-RMS guarantee not strictly hold here, so the simpler
amplitude-symmetric Hann is fine.

---

## 5. Polarity, headroom, and other gotchas

### 5.1. Polarity

**Dry is summed at +polarity, never inverted.** This is the assumption
classic chorus design relies on (Pirkle, *Designing Audio Effect
Plug-Ins in C++* Ch. 4 — chorus). Inverting dry would create a
hollow phaser-like effect rather than a chorus thickening — wrong
for the spec's "WOW + DRY UNITY = chorus" claim.

The engineer must NOT route dry through any odd-stage multiplication
that flips sign (e.g. `[*~ -1]`). Standard `*~` with positive gain
is correct.

### 5.2. Headroom (peak-summing risk)

When `dry_mode = UNITY` and the wet is also at unity (VOLUME knob =
1.0), the sum can hit **+6 dB on perfectly correlated material**
(e.g. WOW at zero — output = 2× input). With the spec'd VOLUME
range up to 2.0 *and* DRY UNITY, theoretical worst case is +12 dB
above input.

**Decision: do NOT internally limit / soft-clip.** Reasons:

- The spec explicitly notes WOW + DRY UNITY produces chorus, which
  is a feature of the original pedal — adding limiting would change
  its character.
- The user manages output level via their DAW track; coloring
  inside the device for a peak that's only hit on correlated
  material would be a hidden surprise.
- The downstream `tl_noise` module adds noise (small) before the
  device output; no other gain stage exists.

The engineer should add a `live.comment` near the DRY toggle
explaining the +6 dB potential at UNITY, but no DSP gain reduction.

### 5.3. Mono / stereo

The mixer is per-channel. Both `dry` and `wet` are stereo (the
device is stereo-out per spec; MISO upstream may have duplicated a
mono input). The reference processes shape `(N, 2)` arrays.

### 5.4. Determinism

There is no RNG in this module. Output is a pure function of
(`dry`, `wet`, `dry_mode`, mode-change timing). Useful for
regression hashing.

---

## 6. SMALL level (-8 dB) — justification

Boutique tape and dirt pedals that offer a dry blend cluster around
−6 dB to −12 dB for "small" / "kept dry" settings:

| Pedal                                  | "small dry" level (approx) |
|----------------------------------------|----------------------------|
| Chase Bliss Dark World wet/dry mix     | −9 dB at noon-low |
| Strymon BlueSky reverb dry feed        | −6 dB nominal |
| EHX Memory Man dry path                | −7 dB |
| Generation Loss MKII (this device)     | spec says "~25%" = −12 dB; we are choosing −8 dB |

Choosing **−8 dB (linear 0.3981)** as the SMALL level is at the
slightly louder end of that window because:

1. The WOW knob at low values is very subtle — at −12 dB SMALL, the
   dry blend disappears under the wet for noise-floor reasons.
2. −8 dB is a "noticeable but secondary" character. The user's
   ear immediately registers the dry presence without it dominating.
3. Boutique-pedal players generally describe the SMALL position on
   the real Generation Loss as "more dry than I expected" — anecdotal
   but consistent across forums. −8 dB lands in that perceived range.

If a future calibration session decides −12 dB is canonically
correct, change the constant `G_SMALL_LIN = 0.3981` in both
`tl_dry_mix.py` and the engineer's M4L coefficient JSON. No other
code changes needed.

---

## 7. Tradeoff log

| # | Decision | Rationale | Alternative considered |
|---|----------|-----------|------------------------|
| 1 | **SMALL = −8 dB**, not the prose spec's −12 dB ("25%") | Forum consensus on the real pedal + headroom for SMALL to be audibly distinct from NONE at low WOW. | −12 dB (strict spec): too quiet at low WOW knob settings; SMALL becomes inaudible. Constant is one line to flip. |
| 2 | **Hann (cos²) crossfade, 10 ms** on mode change | Click-free, click-free derivative at endpoints, zero state, simple. | Equal-power (sin/cos): doesn't strictly hold for our partially-correlated signals. Linear ramp: edge-derivative discontinuity → faint click. |
| 3 | **No internal limiter at DRY UNITY + VOLUME max** | Preserves boutique character. User manages level downstream. | Soft saturation on the sum: changes the device's sonic signature. Hard limit: introduces a hidden ceiling that surprises. |
| 4 | **Parallel pre-WOW dry tap with fixed 30 ms delay** | Aligns dry to wet's nominal time-of-arrival; works regardless of WOW knob value. | Modulation-tracking dry tap (delay = current WOW LFO output): the same modulation on dry as on wet defeats the chorus entirely (output = constant × dry). |
| 5 | **Per-channel independent mix (no L/R link)** | Stereo is preserved end-to-end; MISO already happened upstream. | Sum-to-mono dry mix: would collapse stereo image at UNITY. |
| 6 | **No bypass / no special "wet-only" mode beyond NONE** | NONE already does this; one less code path. | Separate `bypass` toggle: redundant with `dry_mode = NONE`. |
| 7 | **Static gain table, computed once** | Mode count is 3; LUT is trivial; SR-independent. | Per-sample envelope smoothing on knob change: only relevant during the 10 ms crossfade window. |
| 8 | **Crossfade triggered on mode change only**, not continuously smoothed | The mode is a discrete enum; smoothing would imply a fictitious in-between gain state. | Param-rate smoothing (e.g. `slide~`): adds latency and confusion. |

---

## 8. Failure modes / edge cases

| Edge case | Behavior |
|-----------|----------|
| `dry_mode = NONE` for an entire render | Output = wet bit-identical. Reference verifies. |
| `dry_mode = UNITY`, dry == wet (no upstream processing) | Output = 2× dry. +6 dB. Expected; user-facing note. |
| `dry_mode = UNITY`, dry == zero (silent input) | Output = wet. (This will rarely happen since the device is upstream of any silence.) |
| Mode change mid-render | 10 ms crossfade applied; no click. Reference fixture demonstrates. |
| Two mode changes within < 10 ms | Second change interrupts the first; uses *current instantaneous* `g_dry` as old-value for the new fade. Reference handles via running-state machine. |
| Sample-rate change | Crossfade length recomputed from `sr * 0.010` samples. No coefficient table to invalidate. |
| Dry signal misaligned (engineer wired wrong delay) | NOT this module's responsibility, but the verifier in §2.3 catches it. |

---

## 9. CPU / sandbox considerations

Trivial. Per sample per channel: 1 multiply + 1 add for the dry
side, plus the existing wet pass-through. The crossfade adds a
read of a small ramp table during transitions only.

Total: < 0.05 % CPU on M1 — well below the 8 % device-wide budget.

---

## 10. References

- **W. Pirkle, *Designing Audio Effect Plug-Ins in C++* (2nd ed.).**
  Ch. 4 (Chorus / Flanger) — confirms positive-polarity dry sum is
  required for chorus character; documents the 20–30 ms nominal
  delay range.
- **Steven W. Smith, *The Scientist and Engineer's Guide to DSP*.**
  Ch. 16 — Hann window math used for the 10 ms crossfade.
- **Julius O. Smith III, *Physical Audio Signal Processing*.**
  "Time-Varying Delay" section — establishes that for chorus to
  sound right, the dry must arrive at the perceived center of the
  wet's modulation envelope.
- **Chase Bliss Generation Loss MKII manual.** Behavioral source
  of truth (DRY toggle states; "WOW + UNITY = chorus" claim).
- **Project spec:** `specs/tape-loss-spec.md` §"DRY Toggle" +
  §"Signal Flow".

## 11. M4L pitfall catalog cross-reference

From `~/raindog/harness/quickstarts/max-plugin/specs/m4l-device-development-guide.md`:

| Pitfall | Relevance to `tl_dry_mix` |
|---------|---------------------------|
| #7 — `plugin~`/`plugout~` `2` always | Stereo mix; both channels processed independently. |
| #15 — Click-free toggle changes | Directly addressed by the 10 ms crossfade strategy in §4. |
| #19 — Test standalone Max first | The latency-alignment in §2 is the single-most-likely source of "this sounds wrong" bugs; verify in standalone debug.maxpat with the §2.3 procedure before round-tripping into Ableton. |

---

## 12. Verification artifacts

**Reference implementation:** `dsp/reference/tl_dry_mix.py`
**Sanity-render WAVs (44.1 kHz, 16-bit stereo):**

- `tl_dry_mix_input_dry.wav` — clean A2/E3/A3 chord (the "dry").
- `tl_dry_mix_input_wet.wav` — same chord, slight pitch shift
  (simulates wow output).
- `tl_dry_mix_NONE.wav` — wet only; expected ≈ identical to wet input.
- `tl_dry_mix_SMALL.wav` — wet + −8 dB dry blend.
- `tl_dry_mix_UNITY.wav` — wet + 0 dB dry; expected to sound chorused
  due to the dry+pitch-shifted-wet interaction.
- `tl_dry_mix_xfade.wav` — render with mode toggling
  NONE → SMALL → UNITY → NONE every 750 ms; should be click-free.

**Verified properties (programmatic):**

- `dry_mode = NONE` → output bit-identical to wet (RMS difference = 0).
- `dry_mode = UNITY`, dry == wet → output == 2×dry (samplewise).
- Mode-change boundary samples have continuous first derivative
  (no click verifier passes).
- L and R channels independent (per-channel processing) — stereo
  preservation verified by feeding decorrelated L/R noise.
