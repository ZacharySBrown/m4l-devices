# `tl_volume_mix` — DSP Design Doc

> **Module:** `tl_volume_mix` (Generation Loss MKII "VOLUME" + MISO mode)
> **Spec source:** `specs/tape-loss.pedal.yaml` (module `tl_volume_mix`),
> `specs/tape-loss-spec.md` §"Global Parameters & Routing — VOLUME Knob"
> and §"MISO (Mono In Stereo Out)"
> **Position in chain:** between `tl_aux` and `tl_dry_mix`. Operates on
> the wet signal only — the dry-mix downstream takes the un-modified
> input and adds it post-VOLUME, so VOLUME does NOT scale dry.
> **Sandbox status:** `SANDBOX-OK` — pure multiply + first-order IIR
> smoother. Trivial in Max (`*~` and `slide~` or `line~`).
> **Author:** pedal-dsp (this doc), pedal-engineer takes Phase 2.
> **Reference impl:** `dsp/reference/tl_volume_mix.py`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_volume_mix_*.wav`

---

## 1. Block diagram

```
                    ┌──────────────────────────────────────┐
                    │  volume (0..2)   miso (bool)         │
                    └──────────┬──────────┬────────────────┘
                               │          │
                               ▼          ▼
   x_L[n] ─┐                ┌──────────────────┐
           │                │  MISO mux        │
   x_R[n] ─┼──────────────► │  if miso:        │  ──►  m_L[n], m_R[n]
                            │    m = (L+R)/2   │       (post-MISO stereo)
                            │    m_L = m_R = m │
                            │  else:           │
                            │    m_L=L, m_R=R  │
                            └────────┬─────────┘
                                     │
                                     ▼
                            ┌──────────────────────┐
                  volume ──►│  one-pole smoother   │──► g[n]
                            │  g[n] = (1-α)g[n-1]  │
                            │       + α·v_target   │
                            │  α from τ ≈ 10ms     │
                            └────────┬─────────────┘
                                     │  scalar gain, applied per-sample
                                     ▼
                  m_L[n] · g[n] ──► y_L[n]
                  m_R[n] · g[n] ──► y_R[n]
```

There is one shared smoothed gain `g[n]` driving both channels (no L/R
gain decorrelation). MISO is a 2:1 mono-sum then 1:2 duplicate; the
gain stage is identical regardless of MISO state.

The MISO mux is itself crossfaded over the same ~10ms τ when the
`miso` bool toggles, to avoid clicks (see §3).

---

## 2. MISO mono-sum strategy

**Decision:** sum L+R then divide by 2.

| Strategy | Pros | Cons |
| --- | --- | --- |
| `(L+R)/2` (chosen) | No clipping risk; loudness preserved for uncorrelated content; symmetric in L/R; canonical "mono fold" | Correlated content (mono dupe at input) loses 0 dB but stereo content loses ~3 dB perceived |
| `L+R` (no divide) | Preserves loudness for uncorrelated content | Correlated content (e.g. user's dry that's already mono on a stereo bus) clips at +6 dB |
| `L only` | Matches "guitar in left channel" use case for users who plug a TS into a stereo input | Silently drops half the spectrum if R has any content; surprising |

The Generation Loss MKII is a guitar pedal whose MISO option exists to
help users running a mono guitar into the pedal's stereo path.
Practically, the mono guitar arrives as either:
- L only (TRS unbalanced into a stereo input), or
- L+R correlated dupe (split or balanced to stereo).

`(L+R)/2` handles both cleanly: the L-only case becomes `L/2` (a -6 dB
mono signal — no harm but quieter), and the correlated dupe case
becomes the original mono signal at 0 dB. We accept the L-only
attenuation because the user can compensate with the VOLUME knob (which
goes to +6 dB), and the no-clip guarantee is more important than
preserving the L-only loudness.

**Per-sample formula:**
```
if miso:
    m[n] = 0.5 * (L[n] + R[n])
    m_L[n] = m_R[n] = m[n]
else:
    m_L[n] = L[n]
    m_R[n] = R[n]
```

Note: the MISO output is a perfectly correlated mono pair. Downstream
modules (`tl_dry_mix`, `tl_noise`) MUST handle a correlated stereo
input gracefully — i.e. they should not assume L/R independence. The
dry-mix in particular adds an *uncorrelated* dry path (the original
plugin-input pre-MISO), which means DRY=UNITY + MISO produces a
"mono-wet over stereo-dry" image. Documented here so the dry-mix
designer doesn't have to re-derive it.

---

## 3. Volume smoothing

**Goal:** eliminate zipper noise from parameter automation while
keeping the response feel "instant" (≤ 30ms perceived latency).

**Topology:** first-order IIR (one-pole) lowpass on the gain
coefficient — the simplest stable smoother that exists.

```
g[n] = α · v_target + (1 - α) · g[n-1]
```

with α derived from a time constant τ:

```
α = 1 - exp(-1 / (τ · sr))
```

This is the standard "exponential smoother" — see Steven W. Smith,
*The Scientist and Engineer's Guide to DSP*, Ch. 19 §"The Single-Pole
Recursive Filter". It has a -3 dB cutoff at `1/(2π·τ)` and reaches 99%
of a step input after ≈ 4.6·τ.

**τ = 10 ms** chosen because:
- 10 ms is below the ~20 ms threshold for human transient perception;
  knob movements feel responsive.
- A 10 ms exponential settle suppresses zipper artefacts down to below
  -60 dB even for a hard 0→1 step (verified numerically — see
  `dsp/reference/fixtures/tl_volume_mix_zipper_test_*.wav` and the
  `__main__` numeric assertion).
- 10 ms matches the MISO crossfade τ (single time constant for the
  whole module).

At `sr = 44100`:
```
α = 1 - exp(-1 / (0.010 · 44100)) ≈ 2.265e-3
```

At `sr = 48000`:
```
α = 1 - exp(-1 / (0.010 · 48000)) ≈ 2.082e-3
```

α is recomputed at each `sr` change. The engineer's `[js]` reads `sr`
and emits α. Until the smoother converges, output gain matches the
pre-step `g[n-1]` history; on first sample of a fresh patch, `g[-1]`
is initialized to the current `volume` knob value (NOT zero — that
would force a fade-in on every patch reload).

**Citation:** *RBJ Audio EQ Cookbook* does not cover one-pole
smoothers (it's biquad-only), but Smith Ch. 19 and JOS3
"Introduction to Digital Filters" §"One-Pole Filter" both derive this
formula. The α-from-τ relation is also called out in Wikipedia's
"Exponential smoothing" page and is the same form used by Web Audio
API's `setTargetAtTime`.

### MISO crossfade

When `miso` toggles, we don't hard-switch the mux — we crossfade the
mono-sum and pass-through paths over the same τ = 10 ms:

```
miso_g[n] = α · miso_target + (1 - α) · miso_g[n-1]
m_L[n] = miso_g[n] · ((L[n]+R[n])/2) + (1 - miso_g[n]) · L[n]
m_R[n] = miso_g[n] · ((L[n]+R[n])/2) + (1 - miso_g[n]) · R[n]
```

`miso_target ∈ {0.0, 1.0}` (the user's bool). The blend weight
`miso_g[n]` rides the same one-pole smoother as the volume gain. This
guarantees no click at toggle-time — verified by inspecting
`tl_volume_mix_miso_toggle_test.wav` for transients (none above
-60 dBFS during the toggle window).

---

## 4. Headroom note

`volume = 2.0` is +6.02 dB. Combined with hot upstream signals (e.g.
`tl_saturate` at high drive) this CAN clip in the host's DAW input.
We deliberately do NOT internally limit, because:
- The Generation Loss MKII hardware is a unity-or-louder pedal and is
  expected to feed downstream gain stages that may already include a
  limiter.
- A user's track gain is the appropriate limit point — adding a
  hidden internal limiter would surprise users who expect a clean
  multiply.

The design-doc acknowledges this and the spec author is alerted: the
verifier `verify_no_silent_clipping` (if present) should be relaxed
or absent for this module, because clipping at `volume=2.0` is
intentional and user-controllable.

---

## 5. Sample-rate dependencies

| Quantity | Depends on `sr`? | Recompute strategy |
| --- | --- | --- |
| MISO mono-sum `(L+R)/2` | No | Constant |
| Volume scale `g[n]` | No (gain is a scalar) | Constant |
| Smoother coefficient α | **Yes** | Recompute on `sr` change via `[js]` reading `[sr~]` and emitting α to `[*~]` smoother |
| MISO crossfade coefficient | **Yes** (same α) | Same as above |

This module is therefore tagged `sample_rate_dependent: false` in the
DSL because the *audio operation* is SR-independent, but the smoother
coefficient is SR-dependent. The DSL field captures whether the
module's coefficient table changes; for a single scalar α there's no
table, so we keep `false` and let the engineer wire the α
recomputation as a single `expr` rather than a JSON reload.

---

## 6. Edge cases

| Case | Behavior |
| --- | --- |
| `volume = 0.0` | Output is silence (after smoother converges). Smoother prevents click. |
| `volume = 2.0` | +6 dB; may clip downstream — intentional. |
| `volume` rapid sweeps | Smoother τ = 10 ms attenuates audio-rate variation; no zipper. |
| `miso=True` with mono input (L only, R=0) | Output is `L/2` duplicated to L+R. -6 dB attenuation. User compensates with VOLUME. |
| `miso=True` with anti-correlated input (L = -R) | Output is silence (cancellation). Documented; matches hardware behavior of any mono-sum. |
| `miso` toggle mid-audio | Crossfaded over 10 ms; no click. |
| Denormals | Not a recursive structure on the AUDIO path — the smoother runs on the *control* signal (gain coefficient), not on a feedback audio path. Even if α multiplied a denormal at idle, the audio-path multiplication `signal * g` produces a normal product unless the input itself is denormal. No flush-to-zero needed. |

---

## 7. Tradeoff log

- **Linear taper kept (per spec).** Considered `volume²` for "natural
  ear feel" (loudness is roughly logarithmic). Spec explicitly says
  `taper: linear`, so honored. **Suggestion for v1:** consider an
  exponential/dB taper as a hidden option — at unity (1.0 linear) the
  perceived effect of a small knob nudge near 1.0 is more pronounced
  than near 0.0. A `dB-linear` taper (knob position → dB → 10^(dB/20))
  would feel more uniform across the throw.
- **One-pole smoother chosen over `line~` ramp segments.** A discrete
  ramp re-fired on every parameter change requires explicit knob-move
  detection and gives audible "step staircases" if the parameter
  arrives at audio block rate. The IIR one-pole self-corrects without
  any state machine.
- **τ = 10 ms over τ = 5 ms.** 5 ms also works (and is tighter to
  human perception threshold) but leaves slight zipper at extremely
  fast knob waves. 10 ms is the common pedal-DSP default and matches
  Web Audio's typical `setTargetAtTime` choice.
- **MISO sum-and-halve over sum-only.** Avoids clipping at the cost
  of -6 dB on an L-only input; user has +6 dB of VOLUME headroom to
  recover. The no-clip guarantee is worth more than 6 dB of
  asymmetric loudness.
- **No internal output limiter.** See §4. Trade is potential surprise
  clipping at `volume=2.0` vs. unsurprising linear behavior. We
  prefer the latter; the user's mixer already has a fader.

---

## 8. References

- **Steven W. Smith**, *The Scientist and Engineer's Guide to Digital
  Signal Processing*, Ch. 19 §"The Single-Pole Recursive Filter" —
  derivation of α from τ.
  Local pointer: `~/raindog/harness/references/dsp-book-pointer.md`
- **Julius O. Smith III**, *Introduction to Digital Filters*,
  Stanford CCRMA — one-pole filter section.
  Local pointer: `~/raindog/harness/references/jos-textbook-pointers.md`
- **RBJ Audio EQ Cookbook** —
  `~/raindog/harness/references/audio-eq-cookbook.md`. Cited for
  completeness; this module does not use any biquad recipes (one-pole
  smoother is sub-biquad), but the same coefficient-normalization and
  SR-dependence conventions are followed.
- *Generation Loss MKII* manual — VOLUME and MISO behavioral spec
  (mirrored in `specs/tape-loss-spec.md`).
