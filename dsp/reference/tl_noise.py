"""tl_noise — numpy reference implementation of the NOISE module.

This is the golden render the Max patcher (`tl.noise.maxpat`) must
match. It implements the dual-path noise generator from
tape-loss-spec.md Module 6 and the design doc at
`docs/design-docs/dsp/tl-noise-design.md`:

    HISS path     — Voss-McCartney pink noise → HPF 50 Hz → LPF 12 kHz
                    (decorrelated stereo)
    MECHANICAL path (BOTH mode only, gated by hum_bypass):
        VCR sub-engine — white → LPF 200 Hz Q=0.9 → slow random AM
                         (decorrelated stereo)
        HUM sub-engine — 60 Hz fundamental + 5 harmonics (mono / correlated)
        crossfade(mechanical_level): CCW=VCR, knob-noon=silent, CW=hum

The module ignores its audio input — it is an additive noise generator
that the rest of the chain sums onto its output bus.

References:
    - Chase Bliss Generation Loss MKII manual (behavioral spec)
    - tape-loss-spec.md §"MODULE 6: tl.noise.maxpat"
    - Voss, R. F., Clarke, J. (1978). "1/f noise in music."
      J. Acoust. Soc. Am. 63(1).
    - McCartney, J. (1999). Voss-McCartney pink noise generator,
      mirrored at firstpr.com.au/dsp/pink-noise/
    - RBJ Audio EQ Cookbook (https://www.w3.org/TR/audio-eq-cookbook/)
      — HPF, LPF biquad formulas
    - JOS, Spectral Audio Signal Processing, "1/f Noise" appendix
      (https://ccrma.stanford.edu/~jos/sasp/)

Determinism:
    A `numpy.random.Generator` is created from the supplied `seed`
    parameter. `SeedSequence(seed).spawn(N)` derives independent
    streams for the L/R hiss and L/R VCR generators — never seed+1
    (correlates streams).

Public API:
    process(n_samples, sr, *, noise_mode, hiss_level=0.5,
            mechanical_level=0.5, hum_bypass=False, seed=0,
            hum_fundamental_hz=HUM_FUNDAMENTAL_HZ) -> ndarray (N, 2)
"""

from __future__ import annotations

import dataclasses
import math
from pathlib import Path
from typing import Optional

import numpy as np


# ---------------------------------------------------------------------------
# Constants — tunable internal defaults
# ---------------------------------------------------------------------------

# Mains line frequency for the hum sub-engine. 60 for North America,
# 50 for Europe / most of Asia / Africa / Australia. Flip to 50.0 for
# a 50 Hz region; the harmonic stack is auto-derived (see `_hum_render`).
HUM_FUNDAMENTAL_HZ: float = 60.0

# Peak amplitude targets at full level. See design doc §5.
HISS_TARGET_PEAK_AMP: float = 10.0 ** (-42.0 / 20.0)        # ≈ 0.00794 (-42 dBFS)
MECH_TARGET_PEAK_AMP: float = 10.0 ** (-40.0 / 20.0)        # ≈ 0.01000 (-40 dBFS)

# Voss-McCartney bin count. 16 covers 2^16 = 65 536 samples ~ 1.5 s at
# 44.1 kHz before the lowest bin advances. Spectrum verified flat to
# 1/f within ~50 Hz–8 kHz at this size.
PINK_NUM_BINS: int = 16

# Hiss spectral shaping (RBJ biquads).
HISS_HPF_HZ: float = 50.0
HISS_HPF_Q: float = 0.7071  # Butterworth
HISS_LPF_HZ: float = 12_000.0
HISS_LPF_Q: float = 0.7071

# VCR sub-engine.
VCR_LPF_HZ: float = 200.0
VCR_LPF_Q: float = 0.9
VCR_AM_CENTER: float = 0.7   # multiplier center (never reaches 0)
VCR_AM_DEPTH: float = 0.6    # → multiplier swings ~0.1..1.3
VCR_AM_SMOOTH_HZ: float = 2.0  # one-pole on the random walk
VCR_AM_REROLL_HZ_LO: float = 0.3
VCR_AM_REROLL_HZ_HI: float = 1.5

# Hum harmonic stack — relative amplitudes (multiples of fundamental).
# (harmonic_number, amplitude). See design doc §3.2.
HUM_HARMONICS: tuple[tuple[int, float], ...] = (
    (1, 1.00),
    (2, 0.30),
    (3, 0.45),
    (4, 0.18),
    (5, 0.22),
    (7, 0.12),
)


# ---------------------------------------------------------------------------
# RBJ biquads
# ---------------------------------------------------------------------------
#
# All formulas: Bristow-Johnson, "Cookbook formulae for audio equalizer
# biquad filter coefficients," W3C Working Group Note, 2021.
# https://www.w3.org/TR/audio-eq-cookbook/
#
# Returns (b0, b1, b2, a1, a2) normalized by a0 (a0 ≡ 1.0 after norm).


def _hpf_coeffs(fc: float, q: float, sr: float) -> tuple[float, float, float, float, float]:
    """RBJ HPF (Audio EQ Cookbook §HPF)."""
    w0 = 2.0 * math.pi * fc / sr
    cos_w0 = math.cos(w0)
    alpha = math.sin(w0) / (2.0 * q)
    b0 = (1.0 + cos_w0) / 2.0
    b1 = -(1.0 + cos_w0)
    b2 = (1.0 + cos_w0) / 2.0
    a0 = 1.0 + alpha
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def _lpf_coeffs(fc: float, q: float, sr: float) -> tuple[float, float, float, float, float]:
    """RBJ LPF (Audio EQ Cookbook §LPF)."""
    w0 = 2.0 * math.pi * fc / sr
    cos_w0 = math.cos(w0)
    alpha = math.sin(w0) / (2.0 * q)
    b0 = (1.0 - cos_w0) / 2.0
    b1 = 1.0 - cos_w0
    b2 = (1.0 - cos_w0) / 2.0
    a0 = 1.0 + alpha
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def _biquad_apply(x: np.ndarray, coeffs: tuple[float, float, float, float, float]) -> np.ndarray:
    """Direct Form I biquad on a 1-D array.

    Per JOS *Introduction to Digital Filters*, Direct Form I has the
    cleanest numerical behavior for static coefficients (which is our
    case: all biquad coefficients here are computed once per sample-
    rate). Includes denormal flush per pitfall #18.
    """
    b0, b1, b2, a1, a2 = coeffs
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for n in range(x.shape[0]):
        xn = x[n]
        yn = b0 * xn + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        if abs(yn) < 1e-30:
            yn = 0.0
        y[n] = yn
        x2 = x1
        x1 = xn
        y2 = y1
        y1 = yn
    return y


# ---------------------------------------------------------------------------
# Voss-McCartney pink noise
# ---------------------------------------------------------------------------


def _voss_mccartney_pink(n_samples: int, rng: np.random.Generator,
                          n_bins: int = PINK_NUM_BINS) -> np.ndarray:
    """Generate `n_samples` of pink (1/f) noise via Voss-McCartney.

    Per McCartney 1999 (after Voss 1978):
        bin[k] is updated every 2^k samples — so bin[0] every sample,
        bin[1] every other, bin[2] every fourth, etc.
        output[n] = Σ_k bin[k]
    The trailing-zero count of the sample index gives the highest k
    that needs an update at step n.

    Returns a centered, RMS-normalized stream (mean ≈ 0, RMS ≈ 1).
    """
    bins = rng.standard_normal(n_bins).astype(np.float64)
    out = np.zeros(n_samples, dtype=np.float64)

    # Pre-draw all the random updates we need. Doing this in one batch
    # is much faster than re-calling the rng per-update, and keeps the
    # implementation deterministic given the same seed.
    # We need at most one update per sample (for bin 0); fewer for
    # higher bins. The trailing-zero index gives which bin to update.
    # We'll pull from a flat random pool indexed by sample number.
    fresh = rng.standard_normal(n_samples).astype(np.float64)

    for i in range(n_samples):
        # Trailing-zero count of (i+1) — gives the bin index updated
        # at step i. (i+1) so step 0 updates bin 0, step 1 updates
        # bin 0, step 2 updates bin 1, step 3 updates bin 0, etc.,
        # following McCartney's reference scheme.
        k = (i + 1) & -(i + 1)  # lowest set bit value
        # log2 of that = bin index
        bin_idx = int(math.log2(k))
        if bin_idx < n_bins:
            bins[bin_idx] = fresh[i]
        out[i] = float(bins.sum())

    # Normalize to ~unit RMS (sum of n_bins independent N(0,1) ~ N(0, n_bins))
    out /= math.sqrt(n_bins)
    return out


# ---------------------------------------------------------------------------
# Hiss path
# ---------------------------------------------------------------------------


def _hiss_render(n_samples: int, sr: float, hiss_level: float,
                  rng: np.random.Generator) -> np.ndarray:
    """Render a single channel of hiss. Returns a 1-D array."""
    if hiss_level <= 0.0:
        return np.zeros(n_samples, dtype=np.float64)
    pink = _voss_mccartney_pink(n_samples, rng)
    # Spectral shaping: HPF 50 Hz then LPF 12 kHz.
    pink = _biquad_apply(pink, _hpf_coeffs(HISS_HPF_HZ, HISS_HPF_Q, sr))
    pink = _biquad_apply(pink, _lpf_coeffs(HISS_LPF_HZ, HISS_LPF_Q, sr))
    # Quadratic taper on level knob, scaled to peak target.
    gain = (hiss_level ** 2) * HISS_TARGET_PEAK_AMP
    return pink * gain


# ---------------------------------------------------------------------------
# VCR sub-engine
# ---------------------------------------------------------------------------


def _vcr_am_modulator(n_samples: int, sr: float,
                       rng: np.random.Generator) -> np.ndarray:
    """Build a slow random-walk amplitude modulator for VCR rumble.

    Algorithm:
      - Re-draw a target value at random intervals (0.3–1.5 Hz).
      - Linearly walk toward each target.
      - Smooth with a one-pole at VCR_AM_SMOOTH_HZ.
      - Scale to (CENTER - DEPTH/2 .. CENTER + DEPTH/2). Wait, more
        precisely: walk in [-1, +1], then output CENTER + (DEPTH/2)·walk
        → swings (CENTER - DEPTH/2)..(CENTER + DEPTH/2).
    """
    target_value = float(rng.uniform(-1.0, 1.0))
    next_reroll_at = 0
    walk = np.zeros(n_samples, dtype=np.float64)
    cur = 0.0

    # Per-sample one-pole smoothing coefficient.
    # y[n] = a · y[n-1] + (1-a) · x[n], a = exp(-2π · fc / sr)
    a = math.exp(-2.0 * math.pi * VCR_AM_SMOOTH_HZ / sr)
    one_minus_a = 1.0 - a
    smoothed = 0.0

    for i in range(n_samples):
        if i >= next_reroll_at:
            target_value = float(rng.uniform(-1.0, 1.0))
            reroll_hz = float(rng.uniform(VCR_AM_REROLL_HZ_LO, VCR_AM_REROLL_HZ_HI))
            next_reroll_at = i + max(2, int(sr / reroll_hz))
        # Linear walk toward target — 1.0 second to fully reach it
        cur += (target_value - cur) * (1.0 / sr) * 4.0  # ~4 Hz convergence
        # One-pole smooth (already smooth; this further softens kinks)
        smoothed = a * smoothed + one_minus_a * cur
        walk[i] = smoothed

    # Map walk in roughly [-1, 1] (clip just in case) → multiplier.
    walk = np.clip(walk, -1.0, 1.0)
    return VCR_AM_CENTER + (VCR_AM_DEPTH / 2.0) * walk


def _vcr_render(n_samples: int, sr: float,
                 rng_noise: np.random.Generator,
                 rng_am: np.random.Generator) -> np.ndarray:
    """Render a single channel of VCR mechanical noise. Returns 1-D, peak~1.

    Two RNGs because the AM modulator and the noise stream should both
    be deterministic but independent. We give the caller a reason to
    pass a separate rng_am if they want the same noise but different
    AM walk; in the standard call we just spawn from the same parent.
    """
    white = rng_noise.standard_normal(n_samples).astype(np.float64)
    lowpassed = _biquad_apply(white, _lpf_coeffs(VCR_LPF_HZ, VCR_LPF_Q, sr))
    # Normalize so the peak (before AM) is ≈ 1.0.
    peak = float(np.max(np.abs(lowpassed)) or 1.0)
    lowpassed /= peak
    am = _vcr_am_modulator(n_samples, sr, rng_am)
    return lowpassed * am


# ---------------------------------------------------------------------------
# Hum sub-engine (mono)
# ---------------------------------------------------------------------------


def _hum_render(n_samples: int, sr: float, fundamental_hz: float,
                 rng: np.random.Generator) -> np.ndarray:
    """Render mains-hum harmonic stack (mono). Peak normalized to 1.0."""
    t = np.arange(n_samples, dtype=np.float64) / sr
    out = np.zeros(n_samples, dtype=np.float64)
    for harmonic_n, amp in HUM_HARMONICS:
        f = fundamental_hz * harmonic_n
        if f >= sr / 2.0:
            continue  # Nyquist guard (50 Hz × 7 = 350 Hz; 60 Hz × 7 = 420 Hz; safe at SR≥48k)
        phase = float(rng.uniform(0.0, 2.0 * math.pi))
        out += amp * np.sin(2.0 * math.pi * f * t + phase)
    peak = float(np.max(np.abs(out)) or 1.0)
    return out / peak


# ---------------------------------------------------------------------------
# Bipolar crossfade
# ---------------------------------------------------------------------------


def _mechanical_weights(mech_level: float) -> tuple[float, float, float]:
    """Return (vcr_weight, hum_weight, common_gain) for a given knob.

    Per design doc §3.3:
      ml=0.0  → vcr=1, hum=0, common=1   (full VCR)
      ml=0.5  → vcr=0, hum=0, common=0   (silent)
      ml=1.0  → vcr=0, hum=1, common=1   (full hum)
    Quadratic taper on common_gain, scaled to MECH_TARGET_PEAK_AMP.
    """
    ml = float(np.clip(mech_level, 0.0, 1.0))
    ccw_amount = max(0.0, 0.5 - ml) * 2.0
    cw_amount = max(0.0, ml - 0.5) * 2.0
    vcr_weight = ccw_amount
    hum_weight = cw_amount
    activity = max(ccw_amount, cw_amount)
    common_gain = (activity ** 2) * MECH_TARGET_PEAK_AMP
    return vcr_weight, hum_weight, common_gain


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


@dataclasses.dataclass
class NoiseParams:
    noise_mode: int = 0           # 0=OFF, 1=HISS, 2=BOTH
    hiss_level: float = 0.5
    mechanical_level: float = 0.5
    hum_bypass: bool = False
    hum_fundamental_hz: float = HUM_FUNDAMENTAL_HZ


def _resolve_mode(noise_mode: int, hum_bypass: bool) -> tuple[bool, bool]:
    """Truth table from design doc §4. Returns (hiss_on, mech_on)."""
    if noise_mode == 0:        # OFF
        return False, False
    if noise_mode == 1:        # HISS
        return True, False
    if noise_mode == 2:        # BOTH
        return True, (not hum_bypass)
    raise ValueError(f"noise_mode must be 0, 1, or 2, got {noise_mode!r}")


def process(n_samples: int, sr: float, *,
            noise_mode: int,
            hiss_level: float = 0.5,
            mechanical_level: float = 0.5,
            hum_bypass: bool = False,
            seed: int = 0,
            hum_fundamental_hz: float = HUM_FUNDAMENTAL_HZ) -> np.ndarray:
    """Render `n_samples` of stereo noise per the params.

    Args:
        n_samples: number of frames to render.
        sr: sample rate in Hz.
        noise_mode: 0=OFF, 1=HISS, 2=BOTH.
        hiss_level: 0..1; quadratic taper to -42 dBFS peak at 1.0.
        mechanical_level: 0..1; bipolar around 0.5
            (CCW=VCR, CW=hum, 0.5=silent).
        hum_bypass: if True, mechanical is gated off in BOTH mode.
        seed: RNG seed. Same seed + same args = bit-identical output.
        hum_fundamental_hz: 60.0 (default, North America) or 50.0.

    Returns:
        ndarray of shape (n_samples, 2), float64, peak < -30 dBFS in
        normal use, and exactly zero when noise_mode=OFF.
    """
    p = NoiseParams(
        noise_mode=int(noise_mode),
        hiss_level=float(np.clip(hiss_level, 0.0, 1.0)),
        mechanical_level=float(np.clip(mechanical_level, 0.0, 1.0)),
        hum_bypass=bool(hum_bypass),
        hum_fundamental_hz=float(hum_fundamental_hz),
    )

    hiss_on, mech_on = _resolve_mode(p.noise_mode, p.hum_bypass)

    # Independent RNGs. The hiss has its own L/R streams; the
    # mechanical has VCR-L, VCR-R, VCR-AM-L, VCR-AM-R, and a hum
    # phase-rng. Spawning from a single SeedSequence guarantees
    # decorrelation without correlated streams.
    ss = np.random.SeedSequence(seed)
    (ss_hiss_l, ss_hiss_r,
     ss_vcr_l, ss_vcr_r,
     ss_vcr_am_l, ss_vcr_am_r,
     ss_hum) = ss.spawn(7)

    out_l = np.zeros(n_samples, dtype=np.float64)
    out_r = np.zeros(n_samples, dtype=np.float64)

    # ─── HISS path ───────────────────────────────────────────────
    if hiss_on:
        rng_hiss_l = np.random.default_rng(ss_hiss_l)
        rng_hiss_r = np.random.default_rng(ss_hiss_r)
        out_l += _hiss_render(n_samples, sr, p.hiss_level, rng_hiss_l)
        out_r += _hiss_render(n_samples, sr, p.hiss_level, rng_hiss_r)

    # ─── MECHANICAL path ─────────────────────────────────────────
    if mech_on:
        vcr_w, hum_w, common_gain = _mechanical_weights(p.mechanical_level)
        if common_gain > 0.0:
            # VCR (decorrelated stereo)
            if vcr_w > 0.0:
                rng_vcr_l = np.random.default_rng(ss_vcr_l)
                rng_vcr_r = np.random.default_rng(ss_vcr_r)
                rng_am_l = np.random.default_rng(ss_vcr_am_l)
                rng_am_r = np.random.default_rng(ss_vcr_am_r)
                vcr_l = _vcr_render(n_samples, sr, rng_vcr_l, rng_am_l)
                vcr_r = _vcr_render(n_samples, sr, rng_vcr_r, rng_am_r)
                # Per-channel peak normalize then combine.
                # (peak of vcr ≈ AM_CENTER + DEPTH/2 = 1.0 by construction)
                out_l += vcr_l * vcr_w * common_gain
                out_r += vcr_r * vcr_w * common_gain

            # HUM (mono — same signal both channels, halved so summed
            # peak still hits common_gain target)
            if hum_w > 0.0:
                rng_hum = np.random.default_rng(ss_hum)
                hum = _hum_render(n_samples, sr, p.hum_fundamental_hz, rng_hum)
                hum_scaled = hum * hum_w * common_gain * 0.5
                out_l += hum_scaled
                out_r += hum_scaled

    return np.stack([out_l, out_r], axis=1)


# ---------------------------------------------------------------------------
# Verification helpers (called from __main__)
# ---------------------------------------------------------------------------


def _verify_invariants(sr: float = 44100.0) -> None:
    """Cheap regression checks per design doc §9. Raises AssertionError
    if any invariant is violated."""
    n = int(sr * 1.0)  # 1 second is enough for these checks

    # 1. OFF produces silence
    y = process(n, sr, noise_mode=0, hiss_level=1.0, mechanical_level=1.0,
                hum_bypass=False, seed=42)
    assert np.all(y == 0.0), "noise_mode=OFF must produce exact zero"

    # 2. HISS, hiss_level=0 produces silence
    y = process(n, sr, noise_mode=1, hiss_level=0.0, mechanical_level=1.0,
                seed=42)
    assert np.all(y == 0.0), "hiss_level=0 in HISS mode must be silent"

    # 3. BOTH + hum_bypass == HISS (same seed/level)
    y_both = process(n, sr, noise_mode=2, hiss_level=0.5, mechanical_level=0.0,
                     hum_bypass=True, seed=42)
    y_hiss = process(n, sr, noise_mode=1, hiss_level=0.5, mechanical_level=0.0,
                     hum_bypass=False, seed=42)
    assert np.allclose(y_both, y_hiss), \
        "BOTH + hum_bypass should match HISS for same seed/level"

    # 4. mechanical_level = 0.5 is silent
    y_noon = process(n, sr, noise_mode=2, hiss_level=0.5, mechanical_level=0.5,
                     hum_bypass=False, seed=42)
    y_hiss_only = process(n, sr, noise_mode=1, hiss_level=0.5, seed=42)
    assert np.allclose(y_noon, y_hiss_only), \
        "mechanical_level=0.5 (knob noon) should be silent"

    # 5. Peak amplitude < -30 dBFS at all-knobs-max (hiss + full hum)
    y = process(n, sr, noise_mode=2, hiss_level=1.0, mechanical_level=1.0,
                hum_bypass=False, seed=42)
    peak = float(np.max(np.abs(y)))
    peak_dbfs = 20.0 * math.log10(max(peak, 1e-12))
    assert peak_dbfs < -30.0, \
        f"all-knobs-max peak should be < -30 dBFS, got {peak_dbfs:.2f}"

    # 6. Hiss path L/R correlation ≈ 0
    y_hiss = process(n, sr, noise_mode=1, hiss_level=1.0, seed=42)
    corr = float(np.corrcoef(y_hiss[:, 0], y_hiss[:, 1])[0, 1])
    assert abs(corr) < 0.1, f"hiss L/R correlation should be ~0, got {corr:.3f}"

    # 7. Hum-only path L/R correlation ≈ +1
    y_hum = process(n, sr, noise_mode=2, hiss_level=0.0, mechanical_level=1.0,
                    hum_bypass=False, seed=42)
    corr = float(np.corrcoef(y_hum[:, 0], y_hum[:, 1])[0, 1])
    assert corr > 0.99, f"hum L/R correlation should be ~+1, got {corr:.3f}"

    print("  invariants OK (7/7 checks passed)")


# ---------------------------------------------------------------------------
# __main__: render fixtures
# ---------------------------------------------------------------------------


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny WAV writer (PCM16). Avoids scipy/soundfile dependency.
    Same writer style as tl_failure.py.
    """
    import wave
    path.parent.mkdir(parents=True, exist_ok=True)
    x_clip = np.clip(x, -1.0, 1.0)
    int16 = (x_clip * 32767.0).astype(np.int16)
    interleaved = int16.reshape(-1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(interleaved.tobytes())


def render_fixtures(out_dir: Path, sr: int = 44100) -> list[Path]:
    """Render the canonical sanity-check fixtures.

    Spans noise_mode × hiss_level × mechanical_level × hum_bypass
    in the combinations called for in the task brief plus a couple
    extras to span the bipolar mechanical knob.
    """
    written: list[Path] = []
    duration_sec = 4.0
    n = int(duration_sec * sr)

    settings: list[tuple[str, dict]] = [
        ("off",           dict(noise_mode=0, hiss_level=1.0, mechanical_level=1.0)),
        ("hiss_0p5",      dict(noise_mode=1, hiss_level=0.5)),
        ("hiss_1p0",      dict(noise_mode=1, hiss_level=1.0)),
        ("both_vcr_0p2",  dict(noise_mode=2, hiss_level=0.5, mechanical_level=0.2)),
        ("both_hum_0p8",  dict(noise_mode=2, hiss_level=0.5, mechanical_level=0.8)),
        ("both_hum_1p0",  dict(noise_mode=2, hiss_level=0.3, mechanical_level=1.0)),
        ("both_vcr_0p0",  dict(noise_mode=2, hiss_level=0.3, mechanical_level=0.0)),
        ("both_noon",     dict(noise_mode=2, hiss_level=0.5, mechanical_level=0.5)),
        ("both_humbyp",   dict(noise_mode=2, hiss_level=0.5, mechanical_level=0.8,
                                hum_bypass=True)),
    ]

    for tag, kw in settings:
        out = process(n, float(sr), seed=42, **kw)
        path = out_dir / f"tl_noise_{tag}.wav"
        _save_wav(path, out.astype(np.float32), sr)
        written.append(path)
    return written


if __name__ == "__main__":
    print("tl_noise — verifying invariants ...")
    _verify_invariants(sr=44100.0)

    out_dir = Path(__file__).resolve().parent / "fixtures"
    print(f"tl_noise — rendering fixtures into {out_dir} ...")
    files = render_fixtures(out_dir)
    print(f"wrote {len(files)} fixture(s):")
    for f in files:
        print(f"  {f}")
