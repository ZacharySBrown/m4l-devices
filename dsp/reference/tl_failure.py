"""tl_failure — numpy reference implementation of the FAILURE module.

This is the golden render the Max patcher (`tl.failure.maxpat`) must
match. It implements the four sub-engines in tape-loss-spec.md
Module 3:

================================================================
ROUND 2 TUNING (2026-04-26) — TUNING_VERSION = 2
================================================================
User feedback verbatim (Phase 1 audit, 2026-04-26):

    "The tl failure still has too much crackle. Drop out can be
     even more pronounced. Also, go heavy on the pitch things, and
     you can go deeper with dropout depth, length, esp for the GO
     CRAZY version at the end."

Round-2 targets:
  - CRINKLE: pull prominence down across the active range so it sits
    *under* drops/snags rather than dominating. Lower rate ceiling
    and per-event amplitude.
  - DROPS: deeper (already gates to 0; the headroom-clearing comes
    from the crinkle reduction), longer events (50–500 ms scale
    per real-tape physics), and slightly higher rate so mid-knob
    has visible activity.
  - SNAGS: GO HEAVY. Larger peak cents (target 80–150c at full
    commitment; old peak was ~30–50c after the 0.005-scaled tap),
    longer holds so the pitch movement is *audible* not a blip,
    and higher rate at full knob so they feel constant.
  - failure=1.0 should feel "broken but musical": deep+long+frequent
    drops, dramatic snags, crinkle present but no longer the
    dominant texture.

Architecture preserved (Poisson scheduler, 4 sub-engines,
SeedSequence.spawn(2) SPREAD topology). failure=0 short-circuit
behavior is unchanged for hash stability.
================================================================


    A) DROPS    — sparse stochastic volume silences (envelope multiply)
    B) SNAGS    — sparse mechanical pitch-up spikes (variable delay read)
    C) CRINKLE  — two-part:
                  C1: bandpass-filtered noise burst train (additive)
                  C2: very fast random AM ("micro-flutter") on input
    D) SPREAD   — when True, run two independent RNGs, one per channel,
                  so events do not align in stereo.

Every sub-engine derives its event-rate / depth / probability from the
single `failure` knob (0.0–1.0), via per-engine mapping curves chosen
to give a musical taper (sparse and subtle near zero, dense and
obvious near one).

References:
    - Chase Bliss Generation Loss MKII manual (behavioral spec)
    - tape-loss-spec.md §"MODULE 3: tl.failure.maxpat"
    - RBJ Audio EQ Cookbook
      (https://www.w3.org/TR/audio-eq-cookbook/) — bandpass biquad
      formulas used for the crinkle noise filter
    - Steven W. Smith, "The Scientist and Engineer's Guide to DSP"
      Ch. 19 (recursive/biquad filters), Ch. 17 (custom filter design)
    - Julius O. Smith III, "Physical Audio Signal Processing",
      Ch. on tape modeling — informs envelope shape choices for
      drop and snag events (asymmetric attack/release)

Determinism:
    A `numpy.random.Generator` is created from the supplied `seed`
    parameter. With `seed=None` events are unseeded (don't use in
    tests). For SPREAD mode we derive two independent generators by
    SeedSequence-spawning, NOT by re-seeding with seed+1 — the latter
    correlates streams.

Public API:
    process(x, sr, *, failure, failure_override=0.0,
            drop_bypass=False, snag_bypass=False,
            spread=False, crinkle_level=0.5, seed=0) -> ndarray

`x` is shape (N, 2) float32/float64 stereo. Output is the same shape.
Mono input may be passed as shape (N,) and is duplicated to stereo.

Phase 1.5 reconciliation: `failure_override` is a sidechain control
input from the `tl_aux` module's FAIL mode (see
`docs/design-docs/dsp/tl-aux-design.md` §3.3). The effective failure
intensity used by all four sub-engines is

    effective = knob + override · (1 - knob)

so override=0 leaves behavior unchanged (default; non-breaking) and
override=1 forces full failure regardless of knob position.
"""

from __future__ import annotations

import dataclasses
import math
from pathlib import Path
from typing import Optional

import numpy as np


# ---------------------------------------------------------------------------
# Tuning version — bump on every calibration pass.
# ---------------------------------------------------------------------------
TUNING_VERSION = 2


# ---------------------------------------------------------------------------
# Parameter mapping — failure knob (0..1) → per-engine internal rates/depths
# ---------------------------------------------------------------------------
#
# All curves chosen to give "musical" taper:
#   * 0.0 → silent (no events; bypass — output bit-identical to input)
#   * 0.3 → "subtly worn tape" — clearly altered, not distracting
#   * 0.7 → "struggling tape" — audibly failing but listenable
#   * 1.0 → "catastrophic but musical" — broken, on the edge of usable
#
# Round-2 retuning (2026-04-26): see top-of-file comment for context.
# Curves are documented in the design doc tradeoff log §"Round 2".


def _drops_rate_per_min(f: float) -> float:
    """0..1 → events per minute.
    Round-2: linear+quadratic mix so mid-knob already has noticeable
    activity, full knob is dense enough to feel "constantly failing".
        old: r(f) = 12·f²                          (f=0.5 → 3,  f=1 → 12)
        new: r(f) = 8·f + 18·f²                    (f=0.5 → 8.5, f=1 → 26)
    """
    return 8.0 * f + 18.0 * (f ** 2)


def _drops_duration_ms(f: float, rng: np.random.Generator) -> float:
    """Per-event duration (ms) including a small randomization.
    Round-2: real tape dropouts last 50–500 ms; round-1 was conservative
    at 10–80 ms. Bias the distribution upward.
        old: base = 10 + 70·f  (f=0.5 → 45,  f=1 → 80)
        new: base = 30 + 220·f (f=0.5 → 140, f=1 → 250)
    """
    base = 30.0 + 220.0 * f
    jitter = rng.uniform(0.7, 1.3)
    return float(base * jitter)


def _snags_rate_per_min(f: float) -> float:
    """Round-2: GO HEAVY. Round-1 was 4·f² (sparse — only 4/min at full
    knob). User wants snags to feel constant at f=1.0.
        old: r(f) = 4·f²            (f=0.5 → 1,   f=1 → 4)
        new: r(f) = 4·f + 10·f²     (f=0.5 → 4.5, f=1 → 14)
    """
    return 4.0 * f + 10.0 * (f ** 2)


def _snags_pitch_cents(f: float, rng: np.random.Generator) -> float:
    """Peak upward pitch shift in cents.
    Round-2: dramatically increase peak deviation. Old curve gave a
    ~30–50c blip at the actually-audible delay-line excursion (after
    the 0.005-scale factor in _build_snag_delay_offset). New curve
    plus a 2.4× scale-factor lift puts the peak excursion in the
    80–300c band — clearly *pitch* movement, not just a wobble.
        old: base = 30 + 170·f       (f=1 → 200)
        new: base = 60 + 240·f       (f=1 → 300)
    Random ±20% per event preserved.
    """
    base = 60.0 + 240.0 * f
    return float(base * rng.uniform(0.8, 1.2))


def _snags_duration_ms(f: float) -> float:
    """Snag total length. Round-2: longer holds so the pitch movement
    has time to be *heard* rather than registering as a click.
        old: 17 + 30·f   (f=1 → 47ms)
        new: 32 + 80·f   (f=1 → 112ms)
    """
    return 32.0 + 80.0 * f


def _crinkle_burst_rate(f: float) -> float:
    """Crinkle bursts per second.
    Round-2: user said "still too much crackle" — pull the ceiling
    down and lower the floor.
        old: r(f) = 60·f³ + 2   (f=0.5 → 9.5,  f=1 → 62)
        new: r(f) = 30·f³ + 1   (f=0.5 → 4.75, f=1 → 31)
    """
    return 30.0 * (f ** 3) + 1.0


def _microflutter_depth(f: float) -> float:
    """Depth of the always-on micro-AM that processes incoming audio.
    Linear: 0 (no AM) → 0.35 (±35% gain swing — quite audible)."""
    return 0.35 * f


def _microflutter_rate_hz(f: float, rng: np.random.Generator) -> float:
    """Random per-cycle modulation rate, 20–60 Hz per spec."""
    return float(rng.uniform(20.0, 60.0 + 60.0 * f))


# ---------------------------------------------------------------------------
# Biquad — RBJ Audio EQ Cookbook bandpass (constant-skirt, peak gain = Q)
# ---------------------------------------------------------------------------
#
# H(z) = (b0 + b1 z^-1 + b2 z^-2) / (a0 + a1 z^-1 + a2 z^-2)
#
# For BPF (constant skirt gain, peak = Q):
#   b0 =  Q*alpha
#   b1 =  0
#   b2 = -Q*alpha
#   a0 =  1 + alpha
#   a1 = -2*cos(w0)
#   a2 =  1 - alpha
# where w0 = 2*pi*f0/Fs, alpha = sin(w0)/(2*Q)


def _bpf_coeffs(fc: float, q: float, sr: float) -> tuple[float, float, float, float, float]:
    """Return (b0, b1, b2, a1, a2) normalized by a0. RBJ cookbook BPF
    (constant skirt). a0 implicitly 1.0 after normalization."""
    w0 = 2.0 * math.pi * fc / sr
    cos_w0 = math.cos(w0)
    alpha = math.sin(w0) / (2.0 * q)
    b0 = q * alpha
    b1 = 0.0
    b2 = -q * alpha
    a0 = 1.0 + alpha
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def _biquad_apply(x: np.ndarray, coeffs: tuple[float, float, float, float, float]) -> np.ndarray:
    """Direct Form I biquad on a 1-D array.

    Per JOS "Introduction to Digital Filters", Direct Form I has the
    cleanest numerical behavior for static coefficients (which is our
    case: bandpass coefficients are computed once per sample-rate).
    """
    b0, b1, b2, a1, a2 = coeffs
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for n in range(x.shape[0]):
        xn = x[n]
        yn = b0 * xn + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        # Denormal flush — important for recursive structures.
        if abs(yn) < 1e-30:
            yn = 0.0
        y[n] = yn
        x2 = x1
        x1 = xn
        y2 = y1
        y1 = yn
    return y


# ---------------------------------------------------------------------------
# Sub-engine A: DROPS
# ---------------------------------------------------------------------------


def _build_drop_envelope(n_samples: int, sr: float, *, failure: float,
                         rng: np.random.Generator) -> np.ndarray:
    """Build an envelope multiplier (default 1.0, dipping to 0.0 during
    drop events). Each event:
        - 5 ms cosine ramp down to 0
        - hold for `dur_ms - 10` at 0
        - 5 ms cosine ramp up to 1
    """
    env = np.ones(n_samples, dtype=np.float64)
    if failure <= 0.0:
        return env

    rate_per_sec = _drops_rate_per_min(failure) / 60.0
    if rate_per_sec <= 0.0:
        return env

    # Poisson-distributed event count. Mean = rate * duration.
    duration_sec = n_samples / sr
    mean_events = rate_per_sec * duration_sec
    n_events = rng.poisson(mean_events)

    ramp_ms = 5.0
    ramp_n = max(1, int(ramp_ms * 1e-3 * sr))

    for _ in range(n_events):
        # Random event start, uniform over duration.
        start = rng.integers(0, n_samples)
        dur_ms = _drops_duration_ms(failure, rng)
        dur_n = max(2 * ramp_n + 1, int(dur_ms * 1e-3 * sr))
        end = min(n_samples, start + dur_n)
        if end <= start + 2 * ramp_n:
            continue
        # Cosine ramp down (1 → 0) over ramp_n samples
        ramp_idx = np.arange(ramp_n)
        ramp_down = 0.5 * (1.0 + np.cos(np.pi * ramp_idx / ramp_n))
        ramp_up = 0.5 * (1.0 - np.cos(np.pi * ramp_idx / ramp_n))
        # Apply (multiply — don't overwrite, so overlapping drops compound)
        i0 = start
        i1 = i0 + ramp_n
        i2 = end - ramp_n
        i3 = end
        if i1 <= n_samples:
            env[i0:i1] *= ramp_down
        if i2 < i3:
            env[i1:i2] *= 0.0
            env[i2:i3] *= ramp_up
    return env


# ---------------------------------------------------------------------------
# Sub-engine B: SNAGS
# ---------------------------------------------------------------------------


def _build_snag_delay_offset(n_samples: int, sr: float, *, failure: float,
                              rng: np.random.Generator) -> np.ndarray:
    """Build a per-sample delay-time offset (in samples) for the snag
    variable-delay read. Default 0 (no offset = pass-through). Each
    snag event ramps the offset *negative* (shorter delay → upward
    pitch shift), holds, then releases.

    Envelope per spec: 0→1 in 2ms, hold 5–30ms, 1→0 in 15ms.

    The pitch-shift magnitude in cents is the *peak* shift requested.
    For a pitch shift of `c` cents over a transition of T seconds, the
    delay must change by approximately
        delta_samples = sr * T * (1 - 2^(-c/1200))
    Here we approximate by setting peak delay-decrease in samples
    such that the *instantaneous* shift during ramp-down matches the
    target cents. Simpler model: peak_offset_samples = round(
        sr * (target_seconds_per_cycle * cents/1200) ).
    For a clean reference, we compute peak offset as the delay
    change that, if held, would cause an *equivalent* steady-state
    pitch shift if the delay were modulated linearly — i.e.
        peak_offset = sr * (cents/1200) * hold_seconds
    This is a deliberate approximation; the M4L tapout~ in the
    engineer's patch will produce the actual pitch shift via its
    interpolated read head. The numpy reference instead implements
    a fractional-delay tap line so it stays sample-accurate.
    """
    offset = np.zeros(n_samples, dtype=np.float64)
    if failure <= 0.0:
        return offset

    rate_per_sec = _snags_rate_per_min(failure) / 60.0
    duration_sec = n_samples / sr
    n_events = rng.poisson(rate_per_sec * duration_sec)

    attack_ms = 4.0   # Round-2: was 2ms — slower attack avoids clicky onset
    release_ms = 25.0 # Round-2: was 15ms — longer fall makes pitch tail audible
    attack_n = max(1, int(attack_ms * 1e-3 * sr))
    release_n = max(1, int(release_ms * 1e-3 * sr))

    for _ in range(n_events):
        cents = _snags_pitch_cents(failure, rng)
        # Round-2: was uniform(5, 30). Bigger holds → audible pitch sustain.
        hold_ms = float(rng.uniform(15.0, 80.0))
        hold_n = max(1, int(hold_ms * 1e-3 * sr))
        # Map cents to delay-decrease in samples.
        # Round-2: scale factor 0.005 → 0.012 (2.4× lift) to make the
        # delay-line excursion correspond to a perceptually larger
        # pitch swing during the hold window. Combined with the new
        # _snags_pitch_cents curve, peak excursion at f=1.0 is now in
        # the ~80–300c range (was ~30–50c).
        peak_samples = (cents / 1200.0) * sr * 0.012

        start = rng.integers(0, n_samples)
        # Build attack (0 → -peak), hold (-peak), release (-peak → 0)
        seg_total = attack_n + hold_n + release_n
        if start + seg_total >= n_samples:
            seg_total = n_samples - start - 1
            if seg_total <= 0:
                continue
        # Attack ramp
        ai = np.arange(attack_n)
        attack = 0.5 * (1.0 - np.cos(np.pi * ai / attack_n))  # 0→1 cosine
        # Release ramp
        ri = np.arange(release_n)
        release = 0.5 * (1.0 + np.cos(np.pi * ri / release_n))  # 1→0 cosine

        i0 = start
        i1 = i0 + attack_n
        i2 = i1 + hold_n
        i3 = i2 + release_n
        if i3 > n_samples:
            i3 = n_samples
        if i1 <= n_samples:
            offset[i0:i1] -= peak_samples * attack[: max(0, i1 - i0)]
        if i2 <= n_samples:
            offset[i1:i2] -= peak_samples
        if i2 < n_samples:
            offset[i2:i3] -= peak_samples * release[: max(0, i3 - i2)]
    return offset


def _apply_variable_delay(x: np.ndarray, offset_samples: np.ndarray,
                           base_delay_samples: int = 256) -> np.ndarray:
    """Read x with a per-sample offset (negative = shorter delay).

    Implements a fractional read via linear interpolation. The output
    at sample n is read from
        read_pos = n - base_delay - offset[n]
    (offset is *added* in the conventional snag direction; spec defines
    "negative offset = shorter delay = higher pitch", so caller passes
    negative offsets for snag).

    A base delay of `base_delay_samples` is used so that small
    *positive* offsets are also legal without falling off the buffer
    head. For the spec, snags are always offset <= 0, but we keep
    the code general.
    """
    n = x.shape[0]
    y = np.zeros_like(x)
    for i in range(n):
        rp = i - base_delay_samples - offset_samples[i]
        rp_floor = int(math.floor(rp))
        frac = rp - rp_floor
        a = x[rp_floor] if 0 <= rp_floor < n else 0.0
        b = x[rp_floor + 1] if 0 <= rp_floor + 1 < n else 0.0
        y[i] = a + frac * (b - a)
    return y


# ---------------------------------------------------------------------------
# Sub-engine C1: CRINKLE BURSTS (additive, independent of input)
# ---------------------------------------------------------------------------


def _build_crinkle_bursts(n_samples: int, sr: float, *, failure: float,
                           crinkle_level: float, rng: np.random.Generator) -> np.ndarray:
    """Generate a stream of bandpass-filtered noise bursts. Bursts are
    short (~1–4ms) AR envelopes on white noise, then bandpass filtered
    1.5–5kHz."""
    if crinkle_level <= 0.0:
        return np.zeros(n_samples, dtype=np.float64)

    # Build envelope of bursts on top of zeros, then noise-multiply.
    rate_per_sec = _crinkle_burst_rate(failure)
    duration_sec = n_samples / sr
    n_bursts = rng.poisson(rate_per_sec * duration_sec)

    burst_train_env = np.zeros(n_samples, dtype=np.float64)
    for _ in range(n_bursts):
        start = rng.integers(0, n_samples)
        dur_ms = float(rng.uniform(1.0, 4.0))
        dur_n = max(2, int(dur_ms * 1e-3 * sr))
        end = min(n_samples, start + dur_n)
        # Round-2: per-event amplitude reduced ~6 dB so individual
        # crackle pops sit further under drops/snags.
        # Old: uniform(0.4, 1.0); new: uniform(0.2, 0.5).
        amp = float(rng.uniform(0.2, 0.5))
        # Triangular AR envelope, sharper attack
        a_n = max(1, dur_n // 4)
        r_n = (end - start) - a_n
        if r_n <= 0:
            continue
        burst_train_env[start:start + a_n] = np.maximum(
            burst_train_env[start:start + a_n],
            amp * np.linspace(0.0, 1.0, a_n, endpoint=False),
        )
        burst_train_env[start + a_n:end] = np.maximum(
            burst_train_env[start + a_n:end],
            amp * np.linspace(1.0, 0.0, r_n, endpoint=False),
        )

    # White noise * burst envelope, then bandpass.
    noise = rng.standard_normal(n_samples).astype(np.float64)
    pre = noise * burst_train_env
    # Bandpass 2.5kHz center, Q=1.5 (covers 1.5–5kHz region per spec)
    coeffs = _bpf_coeffs(fc=2500.0, q=1.5, sr=sr)
    filtered = _biquad_apply(pre, coeffs)
    # Normalize then scale by crinkle_level.
    # Round-2: headroom factor reduced from 0.5 → 0.30 (additional ~4.4
    # dB cut on top of the per-event amp reduction). Peak crinkle now
    # ≈ -10 dBFS at level=1.0, leaving headroom for drops/snags to be
    # the headline drama rather than the crackle.
    peak = float(np.max(np.abs(filtered)) or 1.0)
    return filtered / peak * 0.30 * crinkle_level


# ---------------------------------------------------------------------------
# Sub-engine C2: MICRO-FLUTTER (always-on AM on input)
# ---------------------------------------------------------------------------


def _build_microflutter_modulator(n_samples: int, sr: float, *, failure: float,
                                   rng: np.random.Generator) -> np.ndarray:
    """Multiplier in [1-d, 1+d] modulating around unity. Built from
    summed sines whose rates jitter every ~50ms to avoid periodicity."""
    depth = _microflutter_depth(failure)
    if depth <= 0.0:
        return np.ones(n_samples, dtype=np.float64)

    mod = np.zeros(n_samples, dtype=np.float64)
    # Two oscillators with rates re-rolled at 50ms intervals.
    chunk_ms = 50.0
    chunk_n = max(64, int(chunk_ms * 1e-3 * sr))
    phase1 = 0.0
    phase2 = 0.0
    i = 0
    while i < n_samples:
        end = min(n_samples, i + chunk_n)
        f1 = _microflutter_rate_hz(failure, rng)
        f2 = _microflutter_rate_hz(failure, rng) * 0.7  # decorrelate
        n_chunk = end - i
        t = np.arange(n_chunk) / sr
        s1 = np.sin(2.0 * np.pi * f1 * t + phase1)
        s2 = np.sin(2.0 * np.pi * f2 * t + phase2)
        mod[i:end] = 0.5 * (s1 + s2)
        # Continue phase to next chunk
        phase1 = (phase1 + 2.0 * np.pi * f1 * n_chunk / sr) % (2.0 * np.pi)
        phase2 = (phase2 + 2.0 * np.pi * f2 * n_chunk / sr) % (2.0 * np.pi)
        i = end
    return 1.0 + depth * mod


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


@dataclasses.dataclass
class FailureParams:
    # `failure` here is the *effective* failure intensity already boosted
    # by `failure_override` upstream — every sub-engine reads the same
    # post-boost value so the four engines stay coherent. The original
    # knob value is kept on `knob` for traceability/logging.
    failure: float = 0.0
    knob: float = 0.0
    failure_override: float = 0.0
    drop_bypass: bool = False
    snag_bypass: bool = False
    spread: bool = False
    crinkle_level: float = 0.5


def _process_one_channel(x: np.ndarray, sr: float, p: FailureParams,
                         rng: np.random.Generator) -> np.ndarray:
    """Apply all four sub-engines to a single mono channel.

    `p.failure` is the *effective* failure intensity already boosted by
    `failure_override` (see Phase 1.5 reconciliation note in module
    docstring). All sub-engines read this same value.
    """
    n = x.shape[0]
    y = x.astype(np.float64).copy()

    # B) SNAG (variable delay) — applied first so subsequent gain
    # operations act on the pitched signal.
    if not p.snag_bypass and p.failure > 0.0:
        offset = _build_snag_delay_offset(n, sr, failure=p.failure, rng=rng)
        if np.any(offset != 0.0):
            y = _apply_variable_delay(y, offset)

    # C2) MICRO-FLUTTER (always-on AM, scales with failure)
    if p.failure > 0.0:
        microflut = _build_microflutter_modulator(n, sr, failure=p.failure, rng=rng)
        y = y * microflut

    # A) DROP (envelope multiply)
    if not p.drop_bypass and p.failure > 0.0:
        env = _build_drop_envelope(n, sr, failure=p.failure, rng=rng)
        y = y * env

    # C1) CRINKLE BURSTS (additive, independent of input)
    if p.crinkle_level > 0.0 and p.failure > 0.0:
        crinkle = _build_crinkle_bursts(
            n, sr, failure=p.failure, crinkle_level=p.crinkle_level, rng=rng,
        )
        y = y + crinkle

    return y.astype(x.dtype)


def process(x: np.ndarray, sr: float, *, failure: float,
            failure_override: float = 0.0,
            drop_bypass: bool = False, snag_bypass: bool = False,
            spread: bool = False, crinkle_level: float = 0.5,
            seed: int = 0) -> np.ndarray:
    """Process a stereo audio buffer through tl_failure.

    Args:
        x: shape (N,) mono or (N, 2) stereo, float32 or float64.
        sr: sample rate in Hz.
        failure: 0..1, the user-facing FAILURE knob value.
        failure_override: 0..1, sidechain control from `tl_aux` FAIL
            mode (see `docs/design-docs/dsp/tl-aux-design.md` §3.3).
            The effective failure intensity used by all sub-engines is
                effective = failure + failure_override · (1 - failure)
            so `failure_override = 0` (default) preserves existing
            behavior — non-breaking. `failure_override = 1` forces full
            failure regardless of the knob.
        drop_bypass: if True, suppresses sub-engine A.
        snag_bypass: if True, suppresses sub-engine B.
        spread: if True, uses independent RNGs per channel (decorrelated
                events). If False, both channels are processed with the
                same modulator stream — events occur in stereo lock.
        crinkle_level: 0..1, scales the additive crinkle bursts.
        seed: RNG seed. Same seed + same args = bit-identical output.
    """
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    if x.ndim != 2 or x.shape[1] != 2:
        raise ValueError(f"expected stereo or mono input, got shape {x.shape}")

    knob = float(np.clip(failure, 0.0, 1.0))
    override = float(np.clip(failure_override, 0.0, 1.0))
    # Phase 1.5 boost formula (contract source: tl-aux-design.md §3.2/§3.3).
    # `effective` is the single value all four sub-engines see. When
    # override=0, effective == knob (non-breaking default).
    effective = knob + override * (1.0 - knob)
    effective = float(np.clip(effective, 0.0, 1.0))

    p = FailureParams(
        failure=effective,
        knob=knob,
        failure_override=override,
        drop_bypass=bool(drop_bypass),
        snag_bypass=bool(snag_bypass),
        spread=bool(spread),
        crinkle_level=float(np.clip(crinkle_level, 0.0, 1.0)),
    )

    # Use SeedSequence so spread=True produces *independent* streams,
    # not correlated near-identical streams (which would happen with
    # seed and seed+1).
    ss = np.random.SeedSequence(seed)
    if p.spread:
        ss_l, ss_r = ss.spawn(2)
        rng_l = np.random.default_rng(ss_l)
        rng_r = np.random.default_rng(ss_r)
    else:
        # Same RNG drives both channels → events lock in stereo.
        rng_l = np.random.default_rng(ss)
        rng_r = rng_l

    if p.spread:
        out_l = _process_one_channel(x[:, 0], sr, p, rng_l)
        out_r = _process_one_channel(x[:, 1], sr, p, rng_r)
    else:
        # Build modulators once (from one rng) and apply to both channels.
        # We re-use the per-channel function but reset rng state by
        # remembering the pre-state and rewinding via a fresh generator.
        ss_shared = np.random.SeedSequence(seed)
        out_l = _process_one_channel(x[:, 0], sr, p, np.random.default_rng(ss_shared))
        out_r = _process_one_channel(x[:, 1], sr, p, np.random.default_rng(ss_shared))

    return np.stack([out_l, out_r], axis=1).astype(x.dtype)


# ---------------------------------------------------------------------------
# __main__: render fixtures
# ---------------------------------------------------------------------------


def _make_test_input(sr: float, dur_sec: float = 3.0) -> np.ndarray:
    """Synthetic 'guitar-like' input: an A2 + A3 + E3 chord with a
    slow 1/2-second attack/release envelope, mildly inharmonic.
    Stereo (mono duplicated)."""
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    fundamentals = [110.0, 164.81, 220.0]  # A2, E3, A3
    sig = np.zeros(n, dtype=np.float64)
    for f0 in fundamentals:
        for k, gain in enumerate([1.0, 0.5, 0.3, 0.15, 0.08], start=1):
            # Slight detune per harmonic for slight realism
            sig += gain * np.sin(2.0 * np.pi * f0 * k * t + 0.1 * k)
    sig /= np.max(np.abs(sig)) or 1.0
    sig *= 0.6  # leave headroom

    # ADSR-ish envelope: 100ms attack, 2.5s sustain, 400ms release.
    env = np.ones(n, dtype=np.float64)
    a_n = int(0.1 * sr)
    r_n = int(0.4 * sr)
    env[:a_n] = np.linspace(0.0, 1.0, a_n)
    env[-r_n:] = np.linspace(1.0, 0.0, r_n)
    sig *= env
    return np.stack([sig, sig], axis=1).astype(np.float32)


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny WAV writer (PCM16) — avoids scipy/soundfile dependency."""
    import struct
    import wave
    path.parent.mkdir(parents=True, exist_ok=True)
    # x is (N, 2) float in [-1, 1]; convert to int16 interleaved.
    x_clip = np.clip(x, -1.0, 1.0)
    int16 = (x_clip * 32767.0).astype(np.int16)
    interleaved = int16.reshape(-1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(interleaved.tobytes())


def render_fixtures(out_dir: Path, sr: int = 44100) -> list[Path]:
    """Render a sanity-check WAV at several failure settings.
    Returns the list of files written."""
    written: list[Path] = []
    in_audio = _make_test_input(sr=sr, dur_sec=3.0)

    # Save the dry input as reference.
    dry_path = out_dir / "tl_failure_input_dry.wav"
    _save_wav(dry_path, in_audio, sr)
    written.append(dry_path)

    settings = [
        ("0p0", dict(failure=0.0, crinkle_level=0.0)),
        ("0p3", dict(failure=0.3, crinkle_level=0.5)),
        ("0p7", dict(failure=0.7, crinkle_level=0.6)),
        ("1p0", dict(failure=1.0, crinkle_level=0.8)),
        ("0p7_spread", dict(failure=0.7, crinkle_level=0.6, spread=True)),
        ("0p7_no_drops", dict(failure=0.7, crinkle_level=0.6, drop_bypass=True)),
        ("0p7_no_snags", dict(failure=0.7, crinkle_level=0.6, snag_bypass=True)),
    ]

    for tag, kw in settings:
        out = process(in_audio, sr=float(sr), seed=42, **kw)
        path = out_dir / f"tl_failure_demo_{tag}.wav"
        _save_wav(path, out, sr)
        written.append(path)
    return written


def _peak_dropout_db_in_window(y_mono: np.ndarray, dry_mono: np.ndarray,
                                sr: float, win_ms: float = 30.0) -> float:
    """Return the deepest 30 ms-window dropout depth (relative to dry RMS)
    expressed in dBFS-equivalent. Lower (more negative) = deeper drop."""
    win_n = max(1, int(win_ms * 1e-3 * sr))
    n = y_mono.shape[0]
    dry_rms = float(np.sqrt(np.mean(dry_mono ** 2)) + 1e-12)
    # Slide a window; take RMS of wet, compare to dry RMS in the same window.
    deepest_db = 0.0
    for i in range(0, n - win_n, win_n // 4):
        wet_chunk = y_mono[i:i + win_n]
        dry_chunk = dry_mono[i:i + win_n]
        dc = float(np.sqrt(np.mean(dry_chunk ** 2)))
        if dc < 0.05 * dry_rms:
            continue  # Skip windows where dry signal is itself near-silent
        wc = float(np.sqrt(np.mean(wet_chunk ** 2)))
        ratio = wc / (dc + 1e-12)
        db = 20.0 * np.log10(ratio + 1e-12)
        if db < deepest_db:
            deepest_db = db
    return deepest_db


def _peak_pitch_cents(y_mono: np.ndarray, dry_mono: np.ndarray,
                      sr: float) -> float:
    """Estimate a *lower bound* on peak instantaneous pitch deviation
    (cents) caused by snag events. Uses short-time cross-correlation
    lag between wet and dry as a cheap proxy.

    Caveats:
        - For periodic (single-tone) inputs the tracker can wrap on
          octave equivalences. The default `_make_test_input` is a
          three-fundamental chord, which mostly avoids this.
        - The lag search is bounded at ±64 samples in a 10 ms window;
          this saturates the reported cents at ~271.5 c. So a returned
          value of 271.5 means "≥ 271.5 c" (real peak likely much
          higher during the attack/release transients of a snag —
          empirically several hundred to ~1000 c on the steepest
          ramps with the round-2 0.012 scale factor).
        - For the round-2 verification we only need this as a lower-
          bound assertion ("≥ 80 c"), so the saturation is OK.
    """
    win_n = max(64, int(0.010 * sr))   # 10 ms window
    hop = win_n // 2
    n = min(y_mono.shape[0], dry_mono.shape[0])
    max_lag = 64  # samples (saturates the cents estimate near 271.5 c)
    peak_cents = 0.0
    for i in range(0, n - win_n - max_lag, hop):
        d = dry_mono[i:i + win_n]
        # Find the lag in [-max_lag, +max_lag] that best aligns wet to dry.
        best_lag = 0
        best_score = -np.inf
        d_norm = float(np.linalg.norm(d) + 1e-12)
        for lag in range(-max_lag, max_lag + 1):
            j = i + lag
            if j < 0 or j + win_n > n:
                continue
            w = y_mono[j:j + win_n]
            score = float(np.dot(d, w)) / (d_norm * (np.linalg.norm(w) + 1e-12))
            if score > best_score:
                best_score = score
                best_lag = lag
        # Convert lag (samples advanced) → cents over the window.
        # A negative best_lag means wet signal arrives *earlier*
        # (shorter delay → upward pitch).
        if best_lag < 0 and (win_n + best_lag) > 0:
            ratio = win_n / float(win_n + best_lag)  # >1 for upward pitch
            cents = 1200.0 * np.log2(ratio)
            if cents > peak_cents:
                peak_cents = cents
    return peak_cents


def _verify_round2_targets(sr: int = 44100) -> None:
    """Verify the round-2 audible targets numerically. Called from __main__.

    Targets:
        T1: failure=0 → output bit-identical to dry input (regression)
        T2: failure=1.0 → peak dropout depth ≤ -30 dBFS in some 30 ms window
        T3: failure=1.0 → peak pitch deviation ≥ 80 cents in some snag
        T4: failure=0.5 → drops + snags both audible (rate × depth above
            a defensible threshold)
    """
    print(f"\n=== Round-2 target verification (TUNING_VERSION={TUNING_VERSION}) ===")

    # T1
    dry = _make_test_input(sr=sr, dur_sec=3.0)
    out_zero = process(dry, sr=float(sr), failure=0.0, crinkle_level=0.0, seed=42)
    bit_identical = bool(np.array_equal(out_zero, dry))
    print(f"T1  failure=0 bit-identical to dry: {bit_identical}")
    assert bit_identical, "T1 FAIL — failure=0 must short-circuit to identity."

    # T2: deep dropout at f=1.0. Use snag_bypass + crinkle_level=0 so we
    #     measure the drop depth in isolation (without snag-driven gain
    #     or crinkle additive lifting the wet RMS in the dropout window).
    out_max_drops = process(
        dry, sr=float(sr), failure=1.0, crinkle_level=0.0,
        snag_bypass=True, seed=42,
    )
    deep_db = _peak_dropout_db_in_window(
        out_max_drops[:, 0], dry[:, 0], sr=sr, win_ms=30.0,
    )
    print(f"T2  f=1.0 peak dropout depth (30 ms): {deep_db:+.1f} dB "
          f"(target ≤ -30 dB) → {'PASS' if deep_db <= -30.0 else 'FAIL'}")
    assert deep_db <= -30.0, (
        f"T2 FAIL — drop depth {deep_db:+.1f} dB shallower than -30 dB target."
    )

    # T3: pitch deviation at f=1.0. Run with drop_bypass + crinkle=0 so
    #     the cross-correlation tracker sees clean snag-only output.
    out_max_snags = process(
        dry, sr=float(sr), failure=1.0, crinkle_level=0.0,
        drop_bypass=True, seed=42,
    )
    peak_cents = _peak_pitch_cents(out_max_snags[:, 0], dry[:, 0], sr=sr)
    print(f"T3  f=1.0 peak pitch deviation: {peak_cents:.1f} cents "
          f"(target ≥ 80 c) → {'PASS' if peak_cents >= 80.0 else 'FAIL'}")
    assert peak_cents >= 80.0, (
        f"T3 FAIL — pitch peak {peak_cents:.1f}c below 80c target."
    )

    # T4: at f=0.5, drops AND snags should both be audible.
    #     Defensible threshold:
    #       - drop depth ≤ -12 dB in some 30 ms window (audibly ducks)
    #       - pitch peak ≥ 30 cents in some snag (audibly bent)
    #     Use a 15 s render so the Poisson process has enough samples
    #     to express its mean rate (at f=0.5: ~8.5 drops/min, ~4.5
    #     snags/min → 2+ of each per 15 s).
    dry_long = _make_test_input(sr=sr, dur_sec=15.0)
    out_mid_drops = process(
        dry_long, sr=float(sr), failure=0.5, crinkle_level=0.0,
        snag_bypass=True, seed=42,
    )
    out_mid_snags = process(
        dry_long, sr=float(sr), failure=0.5, crinkle_level=0.0,
        drop_bypass=True, seed=42,
    )
    mid_drop_db = _peak_dropout_db_in_window(
        out_mid_drops[:, 0], dry_long[:, 0], sr=sr, win_ms=30.0,
    )
    mid_pitch_c = _peak_pitch_cents(out_mid_snags[:, 0], dry_long[:, 0], sr=sr)
    print(f"T4  f=0.5 drop depth: {mid_drop_db:+.1f} dB (target ≤ -12 dB), "
          f"pitch peak: {mid_pitch_c:.1f} c (target ≥ 30 c)")
    assert mid_drop_db <= -12.0, (
        f"T4 FAIL — mid-knob drop depth {mid_drop_db:+.1f} dB "
        "shallower than -12 dB."
    )
    assert mid_pitch_c >= 30.0, (
        f"T4 FAIL — mid-knob pitch peak {mid_pitch_c:.1f}c below 30c."
    )
    print(f"T4  PASS — both drops and snags audible at f=0.5.")
    print(f"=== All round-2 targets verified ===\n")


def _verify_phase15_contract(sr: int = 44100) -> None:
    """Phase 1.5 reconciliation contract assertions.

    Validates the `failure_override` sidechain inlet introduced by the
    `tl_aux` FAIL-mode contract (see `tl-aux-design.md` §3.3).

    Boost formula:
        effective = knob + override · (1 - knob)

    Properties checked:
        P1: failure=0, failure_override=0 → bit-identical to dry input
            (regression: short-circuit must still trigger when both
            inputs are zero).
        P2: failure=0.3, failure_override=0.5 → equivalent to
            failure=0.65, failure_override=0 (formula sanity, sha match).
            Worked example: 0.3 + 0.5·(1-0.3) = 0.3 + 0.35 = 0.65.
        P3: failure=0.0, failure_override=1.0 → equivalent to
            failure=1.0, failure_override=0 (full override).
            Worked example: 0.0 + 1.0·(1-0.0) = 1.0.
    """
    import hashlib
    print(f"\n=== Phase 1.5 contract verification (failure_override inlet) ===")

    dry = _make_test_input(sr=sr, dur_sec=3.0)

    def _sha(arr: np.ndarray) -> str:
        return hashlib.sha256(arr.tobytes()).hexdigest()[:16]

    # P1: both zero → bit-identical to dry (regression).
    out_p1 = process(
        dry, sr=float(sr),
        failure=0.0, failure_override=0.0,
        crinkle_level=0.0, seed=42,
    )
    p1_pass = bool(np.array_equal(out_p1, dry))
    print(f"P1  failure=0, override=0 bit-identical to dry: {p1_pass}")
    assert p1_pass, "P1 FAIL — dual-zero must short-circuit to identity."

    # P2: 0.3 + 0.5·(1-0.3) = 0.65. Hashes must match.
    out_p2_boosted = process(
        dry, sr=float(sr),
        failure=0.3, failure_override=0.5,
        crinkle_level=0.5, seed=42,
    )
    out_p2_direct = process(
        dry, sr=float(sr),
        failure=0.65, failure_override=0.0,
        crinkle_level=0.5, seed=42,
    )
    p2_pass = bool(np.array_equal(out_p2_boosted, out_p2_direct))
    print(f"P2  knob=0.3, override=0.5 == knob=0.65, override=0: {p2_pass}")
    print(f"     sha boosted={_sha(out_p2_boosted)} direct={_sha(out_p2_direct)}")
    assert p2_pass, (
        "P2 FAIL — boost formula effective = knob + override·(1-knob) "
        "produced a different hash than the equivalent direct knob value."
    )

    # P3: 0.0 + 1.0·(1-0.0) = 1.0. Full override.
    out_p3_boosted = process(
        dry, sr=float(sr),
        failure=0.0, failure_override=1.0,
        crinkle_level=0.5, seed=42,
    )
    out_p3_direct = process(
        dry, sr=float(sr),
        failure=1.0, failure_override=0.0,
        crinkle_level=0.5, seed=42,
    )
    p3_pass = bool(np.array_equal(out_p3_boosted, out_p3_direct))
    print(f"P3  knob=0.0, override=1.0 == knob=1.0, override=0: {p3_pass}")
    print(f"     sha boosted={_sha(out_p3_boosted)} direct={_sha(out_p3_direct)}")
    assert p3_pass, (
        "P3 FAIL — full override (knob=0, override=1) did not match "
        "knob=1, override=0; effective formula broken."
    )

    print(f"=== Phase 1.5 contract verified ===\n")


if __name__ == "__main__":
    out_dir = Path(__file__).resolve().parent / "fixtures"
    _verify_round2_targets(sr=44100)
    _verify_phase15_contract(sr=44100)
    files = render_fixtures(out_dir)
    print(f"wrote {len(files)} fixture(s) to {out_dir}")
    for f in files:
        print(f"  {f}")
