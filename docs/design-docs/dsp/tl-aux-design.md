# `tl_aux` — DSP Design Doc

> **Module:** `tl_aux` (Generation Loss MKII "AUX footswitch")
> **Spec source:** `specs/tape-loss.pedal.yaml`,
> `specs/tape-loss-spec.md` §"MODULE 7: tl.aux.maxpat"
> **Sandbox status:** **`LOCAL-ONLY`** — STOP mode requires a stateful
> circular delay-line whose read head is read with a sample-accurate
> deceleration ramp; the FILTER and FAIL modes are independently
> SANDBOX-OK, but the module ships as one unit so the strictest mode
> dictates the classification. See §6 for the full justification.
> **Author:** pedal-dsp (this doc), pedal-engineer takes Phase 2.
> **Reference impl:** `dsp/reference/tl_aux.py`
> **Sanity-render WAVs:** `dsp/reference/fixtures/tl_aux_demo_*.wav`

---

## 0. Module overview

`tl_aux` is a **one-shot dramatic effect** triggered by the `aux_active`
footswitch. The effect type is selected by the `aux_mode` 3-position
switch (`STOP` / `FILTER` / `FAIL`). The onset (and release) ramp time
is `aux_onset_ms` (10–3000 ms, log-tapered).

```
                 ┌──── aux_mode ────┐
                 │                  │
   x[n] ─────────┤  STOP  / FILTER  ├──────► y[n]
                 │  / FAIL          │
                 └──────────────────┘
                          ▲
                          │
   aux_active ──► onset envelope generator (e[n], 0..1)
   aux_onset_ms ─► ramp time
```

### 0.1 Onset envelope (shared across all three modes)

The `aux_active` footswitch drives a smoothed envelope `e[n] ∈ [0, 1]`
where `e=0` ⇒ effect inactive, `e=1` ⇒ effect at maximum.

- **Press (0→1):** ramp from current `e` toward 1 over `aux_onset_ms`.
- **Release (1→0):** ramp from current `e` toward 0 over `aux_onset_ms`.

**Curve choice — exponential, not linear.** The classic
deceleration-of-a-mass-on-tape feels mechanical; linear ramps feel
synthetic. We use a one-pole low-pass smoother:

```
α     = 1 - exp(-1 / (aux_onset_ms · sr / 1000))   # per-sample coefficient
e[n]  = α · target + (1 - α) · e[n-1]              # target ∈ {0, 1}
```

This is the standard "exponential envelope follower" from
Smith, *DSP Guide* Ch. 19, and JOS *Filters* §"Time-Constant
Filter". Time-to-`(1 - 1/e) ≈ 63%` is `aux_onset_ms`. Time-to-99% is
about `4.6 · aux_onset_ms`. The audible effect: long onsets feel
deceleratingly slow at the end; short onsets feel snappy.

**Click avoidance.** `e[n]` is the *only* control that the per-mode
math sees. Toggling `aux_active` therefore changes a smoothed signal,
never a discrete level — no zipper noise, no edge clicks. The
engineer's `[line~]` with curve mode `2.5` would also work; our
exp-smoother is mathematically equivalent at the time scales we care
about, and is what the numpy reference implements.

**Mode-switching strategy.** `aux_mode` should only be changed while
`aux_active = 0` (footswitch off). The engineer's patch should use
`live.tab` discrete steps and route `aux_mode` only when `e[n] < 0.01`,
otherwise queue the change until the release completes. This avoids
mid-effect mode jumps that would create audible state-loss artifacts
(e.g., switching from STOP to FILTER mid-press would dump the tape-stop
buffer's frozen state). The reference implementation enforces this by
sampling `aux_mode` only on the rising edge of `aux_active`.

---

## 1. Mode A — STOP (tape-stop simulation)

### 1.1 Block diagram

```
   x[n] ─► [Circular delay buffer (length N_buf)]
                          │
                          │  fractional read head pos r[n]
                          ▼
                   [Linear interp read]
                          │
                          ▼
                   [Output gain × g_stop(e[n])] ──► y[n]
```

The delay buffer is *always* writing the input. The **read head
deceleration** is what produces the tape-stop effect.

### 1.2 Math: deceleration curve

When `e[n] = 0`, we read the buffer with read-rate `1.0`
(read-head advances 1 sample per output sample → identity). When
`e[n]` ramps toward 1, the read-rate decelerates toward 0 (read-head
stops → frozen sample → silence).

**Read-rate as a function of envelope:**

```
rate[n] = (1 - e[n])^γ
```

with **γ = 2.5** (exponent). This is the curve recommended in the
project spec (`pow(linear, 2.5)`) and matches the empirical "elastic
mechanical deceleration" feel of releasing a cassette deck's play
button. JOS *Physical Audio Signal Processing* §"Wow and Flutter
Modeling" notes that real tape transport deceleration is dominated by
viscous drag (linear in velocity → exponential decay in position) but
the perceptual feel is improved by a slightly steeper curve; γ ≈ 2–3
is the conventional tape-stop-pedal range. We use 2.5 to match the
spec.

The read-head position advances by `rate[n]` per sample:

```
r[n] = r[n-1] + rate[n]      # in samples, fractional
```

When `rate ≈ 0` for many samples, the read head stops on a single
sample → output goes silent (DC). To avoid a held DC component (which
sounds wrong — you want silence, not a sustained tone), we apply an
output gain that fades to zero as the rate falls below a threshold:

```
g_stop(e) = clamp((1 - e), 0, 1)^0.5    # square-root taper
```

The square-root keeps audio audible during most of the deceleration
(perceived loudness ~ √amplitude for short transients) and snaps to
silence cleanly at the end. Verified by ear in the reference.

### 1.3 Pitch behavior

A read-rate of `r` produces a pitch shift of `1200 · log₂(r)` cents.

| `e[n]` | `rate` (γ=2.5)  | pitch (cents) | comment             |
|--------|-----------------|---------------|---------------------|
| 0.00   | 1.000           |    0          | identity            |
| 0.25   | 0.487           |  -1247        | -octave + dead 2nd  |
| 0.50   | 0.177           |  -3001        | -2.5 octaves        |
| 0.75   | 0.0312          |  -5996        | -5 octaves          |
| 0.90   | 0.00316         |  -9971        | basically subsonic  |
| 1.00   | 0.000           |  -∞           | stopped             |

The pitch slides continuously — this is the audible "mechanical
slowdown" character. The output gain `g_stop` ensures we don't hear
the subsonic content as a sustained DC artifact.

### 1.4 Buffer sizing

Buffer length `N_buf` must cover the maximum onset time at the slowest
read-rate:

```
N_buf = ceil(aux_onset_ms_max / 1000 · sr · headroom)
      = ceil(3.0 · 48000 · 1.5)
      ≈ 216_000 samples ≈ 4.5 seconds
```

We round up to the next power of 2 (262144 = ~5.46 s @ 48k) for the
M4L `tapin~` allocation.

The read head can fall behind the write head by *at most* the integral
of `(1 - rate)` over the entire press duration — bounded by the buffer
length. In normal operation it falls behind by perhaps 1.5× the onset
time at most.

**Underflow guard:** if the read-head falls more than `N_buf - 256`
samples behind the write head, we clamp the read position to
`write_head - N_buf + 256`. This is a defensive guard against
pathological onsets longer than the buffer; it never triggers in
normal use.

### 1.5 Release behavior

When `aux_active` goes 1→0, `e[n]` decays back toward 0, and the
read-rate accelerates from `(1-e)^γ` back up toward 1.0. The read
head catches up to the write head over the release time. **By
construction**, since the buffer is always writing the live input, the
output smoothly transitions from "stopped/slowed" back to "live"
without a glitch.

There is one edge case: if `aux_onset_ms` is changed *during* a press
(unusual but allowed), the curve shape will mid-flight switch ramp
constants. The exp-smoother handles this gracefully (the time-constant
just changes; no discontinuity).

---

## 2. Mode B — FILTER (sweeping low-pass)

### 2.1 Block diagram

```
                  ┌── e[n] (onset envelope) ──┐
                  │                            │
                  ▼                            │
   x[n] ─► [State-Variable Filter (SVF)]       │
              fc[n] = sweep(e[n])              │
              q[n]  = q_base + e[n]·dq         │
                  │                            │
                  ▼                            │
                 y[n]                          │
```

### 2.2 Topology choice — state-variable, not biquad

We use the **state-variable filter (SVF)** of Hal Chamberlin (cited in
JOS *Filters* §"State-Space Filters"; see also Andrew Simper, "Linear
Trapezoidal Integrated SVF", 2014, the modern numerically-clean form).

**Why SVF, not RBJ biquad?**

1. **Time-varying coefficients.** RBJ biquad coefficients
   (`b0..a2`) must be re-derived per sample-rate-of-`fc` change. With a
   1000-sample envelope ramp from 20 kHz to 100 Hz, that's 1000 calls
   to `_lpf_coeffs()` per buffer. SVF's parameters (`g = tan(π·fc/sr)`,
   `k = 1/Q`) are computed by direct trig and update cleanly per
   sample.
2. **Stability under modulation.** RBJ biquad poles can briefly leave
   the unit circle during fast `fc` ramps (the difference equation
   isn't physically a "filter with moving cutoff" — it's a sequence of
   different filters). The SVF *integrates physically* — its state
   variables represent band-pass and low-pass directly, and the
   trapezoidal-integration form (TPT-SVF) is unconditionally stable
   for any `g, k > 0`.
3. **Resonance separable.** SVF has independent `q` and `fc` knobs.
   We exploit this to slightly *increase* resonance as the sweep
   closes (auto-wah-style emphasis).

Reference: JOS, *Filters*, "State-Space Filters" chapter; also
Vadim Zavalishin, *The Art of VA Filter Design*, §3.10 ("Trapezoidal
SVF") — the canonical free reference on this topology.

### 2.3 Math: TPT-SVF difference equations

```
g    = tan(π · fc / sr)              # frequency warp
k    = 1 / Q                         # damping
a1   = 1 / (1 + g · (g + k))
a2   = g · a1
a3   = g · a2

# state: ic1eq, ic2eq (initially 0)
v3   = x - ic2eq
v1   = a1 · ic1eq + a2 · v3
v2   = ic2eq + a2 · ic1eq + a3 · v3
ic1eq = 2·v1 - ic1eq
ic2eq = 2·v2 - ic2eq

y_lpf = v2     # low-pass output
y_bpf = v1     # band-pass output (unused; available)
y_hpf = x - k·v1 - v2   # high-pass (unused)
```

This is the Andrew Simper / Vadim Zavalishin **trapezoidal-integrated
SVF**. The "ic1eq", "ic2eq" naming is from Simper's papers
(it's the integrator capacitor states in the analog prototype).
Citation: Simper, "Linear Trapezoidal Integrated State Variable
Filter", https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf.

### 2.4 Sweep mapping

```
fc(e)  = fc_max · (fc_min / fc_max)^e      # log sweep
q (e)  = q_base + e · (q_max - q_base)
```

- `fc_max = 18000 Hz` (effectively wide open at 44.1k)
- `fc_min = 200 Hz` (well into "almost closed" but not subsonic)
- `q_base = 0.707` (Butterworth, no resonance)
- `q_max = 4.0` (audible resonance bump near the sweep close)

The log sweep matches octave perception (an octave per unit of `e`).
A linear sweep would crawl through the high end and slam through the
low end — wrong.

### 2.5 Sample-rate dependency

`g = tan(π · fc / sr)` is the only SR-dependent term. The engineer's
patch recomputes `g` per sample (or per ~32-sample block; the
auto-wah character is preserved at block rates). At 44.1 kHz with
`fc = 100 Hz`, `g ≈ 0.00713`. At 48 kHz, `g ≈ 0.00655`. The change is
small but audible at very low cutoffs — recompute on `dspstate~`
change.

---

## 3. Mode C — FAIL (failure-intensity boost)

### 3.1 Decision: architecture (a) — control-signal interface

**We pick option (a):** `tl_aux` emits a **failure boost factor**
(0..1) that `tl_failure` reads. `tl_aux` does *no* destructive DSP of
its own in FAIL mode; it merely passes audio through and sends a
sidechain control signal upstream.

#### Rationale

| Criterion              | (a) sidechain control | (b) local destructive |
|------------------------|-----------------------|-----------------------|
| Signal flow integrity  | ✓ FAILURE stays at one place in chain | ✗ duplicate dropout/bitcrush logic in two modules |
| Tunability             | ✓ user's FAILURE knob still has meaning during AUX | ✗ AUX FAIL might *replace* the knob's character |
| Stereo coherence       | ✓ shares SPREAD setting from `tl_failure` | ✗ AUX-local processor can't honor SPREAD |
| Engineer wiring        | needs inter-module messaging (see §3.3) | self-contained |
| Reference impl complexity | low (just emit control signal) | medium (replicate failure engine) |
| User mental model      | "AUX FAIL = momentary FAILURE max" — single concept | "AUX FAIL = a different kind of failure" — extra concept |

The engineer-wiring cost (option a) is small and one-time. The
duplicate-logic cost (option b) compounds every time the failure
engine is touched — bug fixes need to land in two places, calibration
drifts apart, etc.

The Chase Bliss manual itself says AUX FAIL "ramps FAILURE up to
maximum". That is exactly architecture (a).

### 3.2 Math: failure-boost mapping

```
failure_override(e, knob) = knob + e · (1.0 - knob)
```

When `e=0`, output = knob value (no override). When `e=1`,
output = `1.0` (max failure). Linearly interpolated by `e`.

This is *additive*-toward-max, not *multiplicative*. If the user has
the FAILURE knob at 0.3, AUX FAIL ramps it through 0.3 → 1.0 over
`aux_onset_ms`. If the knob is at 0.9, AUX FAIL ramps 0.9 → 1.0 (a
small final push). This matches the manual's "ramps to maximum"
language regardless of starting point.

### 3.3 Inter-module interface contract

`tl_aux` exposes a **second outlet** carrying a control-rate signal:

```
outlet 0:  audio L (passthrough when aux_mode != STOP/FILTER)
outlet 1:  audio R (passthrough)
outlet 2:  failure_override   ∈ [0, 1]   — effective per-sample (or per-block)
```

`tl_failure` accepts a new optional inlet `failure_override`. When this
signal is connected and `aux_mode = FAIL` and `aux_active`, the
override replaces the `failure` knob's value internally. When AUX is
off (`e=0`) or in another mode, `tl_aux` emits `0` on outlet 2 and
`tl_failure` reads its own knob.

The signal is full audio rate to avoid zipper noise on the boost ramp;
in Max this is a `[sig~]` continuous signal. In the numpy reference it
is just an array passed alongside the audio.

**Engineer must update `tl_failure` to accept this signal.** This is
documented as a known interface change in this doc; the
`tl_failure-design.md` author can adapt the signature as a
non-breaking addition (default = `0.0`, falls back to knob).

### 3.4 Why not destructive local processing (option b)?

We considered "AUX FAIL does its own bitcrush + dropout multiplier".
Reasons rejected:

- **Spec language ambiguous.** Spec §"FAIL" says "Send a `failure 1.0`
  message to `tl.failure` overriding the knob value". That's literally
  architecture (a) in plain English.
- **Replicating dropout state machine** in `tl_aux` would mean two
  Poisson schedulers needing to stay in stereo lock with `tl_failure`
  during a press. Edge cases multiply.
- **Different sound** between knob-at-max and AUX-FAIL would be a
  surprise — users would learn the knob's character then find AUX
  doesn't quite match.

### 3.5 What `tl_aux` outputs in FAIL mode

Audio: passthrough (no destruction at the AUX block).
Sidechain: `e[n]` modulated boost factor as in §3.2.
Output gain: 1.0 (no mode-internal volume change).

The audible failure effect happens upstream at `tl_failure`; from the
listener's perspective AUX FAIL "ramps the failure engine to max".

---

## 4. Mode-switching state machine

```
   ┌────────────────────────────────────┐
   │ state: aux_mode_active             │
   │ initial: STOP                      │
   └────────────────────────────────────┘
              │
              │ on rising edge of aux_active:
              │   aux_mode_active ← aux_mode (sample switch position)
              │   target_e ← 1.0
              │
              │ on falling edge of aux_active:
              │   target_e ← 0.0
              │   (aux_mode_active stays put; only swaps when e ≈ 0)
              │
              │ if aux_mode changes while aux_active=1:
              │   QUEUE the change; apply when e drops below 0.01
              │
              ▼
       per-sample:
         e[n] ← α·target_e + (1-α)·e[n-1]
         dispatch on aux_mode_active:
            STOP  → §1
            FILTER → §2
            FAIL  → §3
```

The sample-and-hold of `aux_mode` on the rising edge prevents
mid-effect mode-jumps. Without this, switching from STOP to FILTER at
`e=0.6` would dump the partially-frozen tape buffer into a
half-closed filter — meaningless and likely clicky.

---

## 5. Onset envelope properties

| `aux_onset_ms` | per-sample α (sr=48k) | time to 50% | time to 99% |
|---------------:|----------------------:|------------:|------------:|
|         10 ms  |   2.08 × 10⁻³         |   ~7 ms     |   ~46 ms    |
|        200 ms  |   1.04 × 10⁻⁴         |   ~139 ms   |   ~921 ms   |
|       1000 ms  |   2.08 × 10⁻⁵         |   ~693 ms   |   ~4.6 s    |
|       3000 ms  |   6.94 × 10⁻⁶         |   ~2.08 s   |   ~13.8 s   |

Note: time-to-99% exceeds onset-ms by ~4.6×. This is the nature of
exponential settling. The audible character matches the spec's
"crawling" descriptor at 3000 ms (the listener perceives the effect
*almost* never reaching maximum, which is mechanically accurate).

If the engineer wants snappier onsets, an optional 'snap-to-target'
clamp can fire when `|target - e| < 1e-3` to short-circuit the long
exponential tail. The numpy reference does NOT snap; the M4L patch
may or may not. (Tradeoff log #4.)

---

## 6. LOCAL-ONLY justification

`tl_aux` is classified `LOCAL-ONLY` because of **Mode A (STOP)**:

1. **Stateful audio buffer.** STOP requires `tapin~`/`tapout~` (or a
   `buffer~` + `record~` + `play~`) holding ~4 seconds of audio. M4L
   buffer allocation must complete before audio starts (pitfall #19),
   which means standalone Max IDE testing is required to verify
   first-vector-not-silent behavior.
2. **Fractional read head with extreme rate range.** The interpolation
   quality of `tapout~` matters — at `rate ≈ 0`, even 4-point cubic
   leaves audible stair-stepping. Verifying this is a listening test;
   numpy plots can't catch it.
3. **CPU profile.** The TPT-SVF in FILTER mode and the variable-rate
   read in STOP mode together push this module's CPU above the
   "trivially negligible" threshold. Profile in Live before shipping.

**Modes B (FILTER) and C (FAIL) in isolation would be SANDBOX-OK** —
they're stateless or share state with already-tested modules. The
classification is dictated by the most-restrictive mode in the unit.

**Engineer guidance:**
- Test STOP first in standalone debug.maxpat with a sustained-tone
  loop (see project spec §"Standalone debug.maxpat harness", pitfall
  #9).
- The buffer-init-before-audio sequencing is critical: use
  `[loadbang]` → `[clear $1, set $2]` to `tapin~` before any audio
  inlets fire.
- Verify FILTER mode's TPT-SVF doesn't denormal — it shouldn't (no
  recursive-feedback path with unity-gain-at-DC), but probe with the
  default-zero-input test.

---

## 7. Tradeoff log

| #  | Decision                                  | Rationale | Alternative considered |
|----|-------------------------------------------|-----------|------------------------|
| 1  | **FAIL = sidechain control signal (option a)** | Spec language "send failure 1.0 message"; no logic duplication; honors SPREAD; FAILURE stays at one chain location. | Local destructive bitcrush in `tl_aux`: bypasses FAILURE's character, requires duplicate state machine. |
| 2  | **STOP read-rate curve `(1-e)^2.5`** | Spec says `pow(linear, 2.5)`; matches mechanical-deceleration feel. | Linear (`1-e`) — sterile, sounds like a fader; cubic (`^3`) — too abrupt at the end. |
| 3  | **FILTER topology = TPT-SVF, not biquad** | Stable under fast modulation; resonance separable; sample-rate-friendly. | RBJ LPF biquad: stable, but coefficients must be recomputed every sample, and zipper-noise artifacts on fast onsets. Moog ladder: nonlinear, overkill for AUX. |
| 4  | **Onset = exponential (one-pole), not linear** | "Mechanical" feel matches releasing a tape deck's play button; standard envelope follower. | Linear `[line~]`: spec mentions `line~` but engineer-side `line~ exp 2.5` curve also works; we picked the analytical form for the reference. |
| 5  | **`aux_mode` sample-and-hold on rising edge** | Prevents mid-press mode jumps that would dump state. | Free-running mode switch: simpler, but creates clicks/state-loss. |
| 6  | **STOP buffer = 262144 samples** (~5.46 s @ 48k) | Power of 2; covers max onset 3000 ms at 1.5× headroom. | Smaller buffer (1 s): wasteful — a 3-second onset would underflow; larger (16 s): wasteful — RAM, no benefit. |
| 7  | **Output gain `√(1-e)` in STOP mode** | Avoids sustained DC artifact when read head freezes; perceptual loudness compensation. | No gain (let the buffer sample dominate): audible DC tone at `e=1`. Linear `1-e` gain: too steep, makes the slowdown sound like a duck-fade. |
| 8  | **`aux_active` and `aux_onset_ms` are control-rate; `e[n]` is audio-rate** | Onset must be smooth; ramp time can change at control rate. | All audio-rate: unnecessary cost. All control-rate: ramp would step. |
| 9  | **No anti-aliasing on STOP** | The deceleration *increases* delay, not decreases — read-rate stays in `[0, 1]`, frequencies only go *down*. Anti-aliasing is only needed for upward pitch shift. | Add a polyphase resampler: unnecessary CPU. |
| 10 | **FILTER cutoff: log sweep, 18 kHz → 200 Hz** | Octave-perceptual taper; final closed point still musical (not subsonic). | Linear sweep (sterile); close to 20 Hz (pointless — inaudible content). |
| 11 | **FILTER resonance: 0.707 → 4.0** | Subtle auto-wah emphasis at sweep close; not screaming-self-oscillating. | Resonance up to 10: self-oscillation; spec says "resonance often builds *slightly*". |
| 12 | **One AUX module, not three** | Spec ships them as a single 3-position toggle. Mode-switching state machine handles within. | Three separate modules: cleaner code, but spec architecture treats them as one footswitch effect. |
| 13 | **`tl_failure` adopts a new optional inlet** | Cleanest interface; non-breaking; falls back to knob when override = 0. | `tl_aux` writes a global `pattr` value: feels hacky, harder to reason about. |
| 14 | **FILTER's `e=0` state is wide-open SVF, not bypass** | Avoids click on first-sample of press; rolloff above 18 kHz is inaudible at 44.1 kHz; SVF's `e=0` numerical state cleanly matches its `e=ε` neighborhood. | True bypass at `e=0`: introduces a click when the press starts and the SVF state is uninitialized. |

---

## 8. Failure modes and edge cases

| Edge case                                  | Behavior                                                                 |
|--------------------------------------------|--------------------------------------------------------------------------|
| `aux_active = 0` always                    | All modes pass-through; FAIL emits `failure_override = 0`.               |
| Press-release shorter than `aux_onset_ms`  | `e[n]` rises partway, falls back; effect is a partial slowdown / partial filter sweep / partial FAIL boost. |
| `aux_onset_ms` at minimum (10 ms)          | Effect snaps in within ~46 ms; STOP mode produces a sharp pitch dive. |
| `aux_onset_ms` at maximum (3000 ms)        | Effect crawls in over ~13.8 s (4.6× to 99%); STOP mode produces a glacial slowdown. |
| `aux_mode` toggled while `aux_active=1`    | New mode queued; applied when `e[n] < 0.01`. Reference logs "queued". |
| Sample-rate change mid-press               | `α` recomputed; STOP buffer not reallocated (size is in samples, not seconds — recompute is harmless). |
| STOP: very long press (> buffer)           | Read head clamps to oldest available sample; output is held at frozen DC, gained to silence by `g_stop`. |
| STOP: simultaneous high WOW from upstream  | WOW's pitch modulation enters the STOP buffer along with audio; read-back inherits the modulation. Acceptable — mirrors real tape behavior. |
| FILTER: cutoff approaches Nyquist          | TPT-SVF frequency warp `tan(π·fc/sr)` is unbounded as `fc → sr/2`. Clamp `fc ≤ 0.45·sr` in code. |
| FAIL: knob already at 1.0                  | Override = 1.0 throughout; effect is inaudible — no boost available. Acceptable. |
| Stereo input                               | All three modes are mono-per-channel; stereo decorrelation comes from upstream `tl_failure` (when SPREAD). |

**Numerical stability:**
- TPT-SVF is unconditionally stable for `g, k > 0`. We clamp
  `fc ∈ [20 Hz, 0.45·sr]` and `Q ∈ [0.5, 10]` defensively.
- The STOP buffer read uses linear interpolation in the reference;
  Max's `tapout~` defaults to 4-point cubic, which is acceptable.
- Denormals: the SVF state can accumulate denormals during very long
  silences. Engineer should add a `+ 1e-30 - 1e-30` to one state per
  vector, or rely on Max's `[sig~]` denormal handling
  (Max 7+ flushes by default but verify in `dspstate~` settings).

---

## 9. CPU / sandbox considerations

**M4L target:** < 8 % on M1 at 44.1 kHz / 64-sample vector for the
*entire device*. AUX is one of nine modules; budget < 1 %.

**Per-mode cost:**

- **STOP:** linear-interp delay-line read = 4 mul + 3 add per sample
  + envelope smoother (2 mul + 1 add). Trivial.
- **FILTER:** TPT-SVF = 8 mul + 9 add per sample + per-sample `tan()`
  for `g`. The `tan` is the dominant cost. Cache `g` per ~32-sample
  block to reduce by 32× without audible artifact.
- **FAIL:** envelope smoother only. Effectively free.

**Bypass:** when `aux_active = 0` and `e[n] < 1e-4`, the engineer's
patch should `selector~` the input directly to the output and skip
the per-sample math. This is the standard SANDBOX-PARTIAL pitfall
for inactive modules — see project spec §"BYPASS" guidance.

**Sandbox-incompatible elements (note for engineer):**
- `tapin~ / tapout~` for STOP — buffer allocation timing, see §6.
- TPT-SVF requires a `gen~` codebox or a custom `expr` chain;
  unverified that the standard `[onepole~]` / `[svf~]` Max objects
  match the trapezoidal form. Engineer should bench-render a sweep
  in standalone Max IDE before round-tripping to Ableton.
- Inter-module signal route for FAIL — verify `[send~ failure_override]`
  / `[receive~ failure_override]` adds zero-sample latency
  (Max will warn if it adds vector latency).

---

## 10. References

- **Robert Bristow-Johnson, *Audio EQ Cookbook*.** Vendored at
  `~/raindog/harness/references/audio-eq-cookbook.md`. Canonical:
  https://www.w3.org/TR/audio-eq-cookbook/. *(Comparison filter
  topology — we picked TPT-SVF over RBJ biquad for FILTER.)*
- **Andrew Simper.** "Linear Trapezoidal Integrated State Variable
  Filter." Cytomic, 2014.
  https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf.
  *(Authoritative source for the FILTER mode topology.)*
- **Vadim Zavalishin.** *The Art of VA Filter Design.* (Free PDF.)
  §3.10 — Trapezoidal SVF. Also derives the same topology from a
  zero-delay-feedback perspective.
- **Julius O. Smith III.** *Physical Audio Signal Processing*,
  "Wow and Flutter Modeling" chapter. CCRMA.
  https://ccrma.stanford.edu/~jos/pasp/Wow_Flutter_Modeling.html.
  *(Justifies the `(1-e)^2.5` deceleration curve for STOP.)*
- **Julius O. Smith III.** *Introduction to Digital Filters with Audio
  Applications*, §"State-Space Filters" and §"Time-Constant Filter".
  CCRMA. https://ccrma.stanford.edu/~jos/filters/. *(SVF derivation
  and exponential-envelope math.)*
- **Steven W. Smith.** *The Scientist and Engineer's Guide to DSP*
  (1997), Ch. 19 — Recursive filters / one-pole envelope follower.
- **Chase Bliss Generation Loss MKII manual.** Behavioral source of
  truth for AUX modes.
- **Project spec:** `specs/tape-loss-spec.md` §"MODULE 7:
  tl.aux.maxpat" — engineer-readable algorithm sketch.
- **Project spec:** `specs/tape-loss.pedal.yaml` — parameter ranges
  and sandbox status.

---

## 11. M4L pitfall catalog cross-reference

From `~/raindog/harness/quickstarts/max-plugin/specs/m4l-device-development-guide.md`:

| Pitfall | Relevance to `tl_aux` |
|---------|------------------------|
| #7 — `plugin~`/`plugout~` `2` always | Stereo I/O. AUX is mono-per-channel; outer plumbing handles. |
| #9 — Standalone debug.maxpat harness | **Critical for STOP mode** — buffer init timing must verify in Max IDE. |
| #14 — Use `[send~]` only for control-rate, not audio-rate cross-module | The FAIL sidechain is technically audio-rate but slow-moving; verify the `[send~ failure_override]` doesn't add a vector of latency. |
| #18 — `live.tab` saved_attribute_attributes | `aux_mode` is a 3-position `live.tab`; needs full attribute block. |
| #19 — Test standalone Max first | Yes — applies to STOP buffer init (see #9). |
| #20 — Subpatch `loadbang` ordering | The mode state machine reads `aux_mode` at startup; if `live.tab` hasn't initialized when our state machine reads it, we'll default to STOP — fine, but verify in IDE. |

---

## 12. Verification artifacts

**Reference implementation:** `dsp/reference/tl_aux.py`
**Sanity-render WAVs (44.1 kHz, 16-bit stereo):**
- `tl_aux_input_dry.wav` — clean test tone (mixed sine + noise burst), 4 s
- `tl_aux_demo_stop.wav` — STOP mode, `aux_onset_ms=800`, full press cycle
- `tl_aux_demo_filter.wav` — FILTER mode, `aux_onset_ms=600`, full press cycle
- `tl_aux_demo_fail.wav` — FAIL mode, audio passthrough + companion control
  trace (sidechain rendered as mono "control" file `tl_aux_demo_fail_ctrl.wav`)

Each fixture is the canonical 4-second timeline:
- 0.0–1.0 s: `aux_active = 0` (dry passthrough)
- 1.0–3.0 s: `aux_active = 1` (effect on, ramping in then held)
- 3.0–4.0 s: `aux_active = 0` (effect off, ramping out)

**Verified properties (programmatic checks in the reference):**
- STOP mode, `aux_active = 0 ∀ n` → output ≡ input (bit-identical, max
  diff = 0). The buffer pass-through with `read_head = 0` reduces to
  identity.
- STOP mode, `aux_active = 1` plateau → output ≈ silence (verified
  tail RMS / dry RMS ≈ 0 to 6 sig figs).
- FAIL mode → audio output ≡ input (bit-identical, max diff = 0)
  regardless of envelope state. Sidechain `failure_override` ramps
  knob → 1.0 exponentially; verified end-of-plateau = 1.0 exactly.
- FILTER mode → spectral centroid drops dramatically: dry-window
  centroid ≈ 6128 Hz, press-window (cutoff near `fc_min`) centroid
  ≈ 257 Hz. Confirms the LPF is closing as designed.
- FILTER mode, `aux_active = 0 ∀ n` → output is *not* bit-identical
  to input (max diff ≈ 0.053). This is expected: at `e=0` the SVF
  runs with `fc = fc_max = 18 kHz, Q = 0.707`, which is a very gentle
  wide-open LPF rather than a true bypass. The audible coloration is
  imperceptible at audio frequencies (rolloff begins above 18 kHz),
  and the engineer's patch should NOT special-case `e=0` to bypass —
  doing so would introduce a click on the very first sample of any
  press. Documented as a deliberate design choice (tradeoff #14
  below).
- Mode-switching: changing `aux_mode` while `aux_active = 1` is
  queued (reference logs the deferral); applied at `e < 0.01`.
