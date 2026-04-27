"""tl_model_eq — numpy reference implementation of the MODEL EQ module.

Loads the parameter-driven coefficient JSON at
`data/model_eq_coefficients.json`, computes biquad coefficients per
(profile_stage, sample_rate) using RBJ Audio EQ Cookbook formulas, and
processes a stereo input through a cascade of Direct Form I biquads —
one cascade per channel.

This file IS the golden render the engineer's `[biquad~]` chain in
`tl.model_eq.maxpat` must match. If the M4L implementation produces
different audio than this file's `process()` does for the same
(model, filter_bypass, sr, input) tuple, the M4L wiring is wrong.

References
----------
- RBJ Audio EQ Cookbook (https://www.w3.org/TR/audio-eq-cookbook/)
  Coefficient formulas for HPF, LPF, peaking EQ, and shelves are
  copied verbatim from the cookbook (mirrored at
  `~/raindog/harness/references/audio-eq-cookbook.md`).
- Steven W. Smith, "The Scientist and Engineer's Guide to DSP",
  Ch. 19 (recursive/biquad filters) — Direct Form I difference
  equation, denormal hazard discussion.
- Julius O. Smith III, "Introduction to Digital Filters",
  https://ccrma.stanford.edu/~jos/filters/ — biquad cascade stability.
- specs/tape-loss-spec.md §"MODULE 2: tl.model_eq.maxpat" — profile
  stage definitions.

Determinism
-----------
This module is deterministic. Same (input, model, filter_bypass, sr,
crossfade settings) yields bit-identical output.

Public API
----------
    process(x, sr, *, model, filter_bypass=False) -> ndarray
    process_with_change(x, sr, *, model_schedule, ...) -> ndarray
        (lower-level: handle a mid-buffer model change with crossfade)

`x` is shape (N,) mono or (N, 2) stereo, float32 or float64.
"""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np


# ---------------------------------------------------------------------------
# Coefficient JSON loading
# ---------------------------------------------------------------------------

_DEFAULT_JSON_PATH = (
    Path(__file__).resolve().parents[2] / "data" / "model_eq_coefficients.json"
)


def load_coefficient_table(path: Path | str | None = None) -> dict:
    """Load the parameter-driven coefficient JSON.

    Returns the parsed dict. Validates the schema_version and
    that profiles "0".."12" are present.
    """
    p = Path(path) if path is not None else _DEFAULT_JSON_PATH
    with open(p, "r", encoding="utf-8") as f:
        data = json.load(f)
    if data.get("schema_version") != "1.0":
        raise ValueError(
            f"unsupported schema_version: {data.get('schema_version')!r}"
        )
    profiles = data.get("profiles", {})
    for k in (str(i) for i in range(13)):
        if k not in profiles:
            raise ValueError(f"missing profile '{k}' in {p}")
    return data


# ---------------------------------------------------------------------------
# RBJ Audio EQ Cookbook biquad coefficient computation
# ---------------------------------------------------------------------------
#
# All formulas verbatim from
# https://www.w3.org/TR/audio-eq-cookbook/
#
# Returns (b0, b1, b2, a1, a2) with a0 normalized to 1.0.
# (Max's [biquad~] takes [a1, a2, b0, b1, b2]; same convention.)


def _common(fc: float, sr: float, q: float) -> tuple[float, float, float]:
    """Compute (w0, cos_w0, alpha) for a given center freq, SR, Q."""
    # Clamp fc to a safe Nyquist margin to keep stability.
    fc = max(1.0, min(fc, 0.45 * sr))
    q = max(1e-3, q)
    w0 = 2.0 * math.pi * fc / sr
    cos_w0 = math.cos(w0)
    sin_w0 = math.sin(w0)
    alpha = sin_w0 / (2.0 * q)
    return w0, cos_w0, alpha


def biquad_lpf(fc: float, sr: float, q: float) -> tuple[float, float, float, float, float]:
    """RBJ Cookbook LPF."""
    _, cos_w0, alpha = _common(fc, sr, q)
    b0 = (1.0 - cos_w0) / 2.0
    b1 = 1.0 - cos_w0
    b2 = (1.0 - cos_w0) / 2.0
    a0 = 1.0 + alpha
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def biquad_hpf(fc: float, sr: float, q: float) -> tuple[float, float, float, float, float]:
    """RBJ Cookbook HPF."""
    _, cos_w0, alpha = _common(fc, sr, q)
    b0 = (1.0 + cos_w0) / 2.0
    b1 = -(1.0 + cos_w0)
    b2 = (1.0 + cos_w0) / 2.0
    a0 = 1.0 + alpha
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def biquad_peak(
    fc: float, sr: float, q: float, gain_db: float
) -> tuple[float, float, float, float, float]:
    """RBJ Cookbook peaking EQ."""
    _, cos_w0, alpha = _common(fc, sr, q)
    A = 10.0 ** (gain_db / 40.0)  # sqrt of linear gain
    b0 = 1.0 + alpha * A
    b1 = -2.0 * cos_w0
    b2 = 1.0 - alpha * A
    a0 = 1.0 + alpha / A
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha / A
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def biquad_lowshelf(
    fc: float, sr: float, q: float, gain_db: float
) -> tuple[float, float, float, float, float]:
    """RBJ Cookbook low shelf (Q-form)."""
    _, cos_w0, alpha = _common(fc, sr, q)
    A = 10.0 ** (gain_db / 40.0)
    sqrtA_2alpha = 2.0 * math.sqrt(A) * alpha
    b0 = A * ((A + 1) - (A - 1) * cos_w0 + sqrtA_2alpha)
    b1 = 2.0 * A * ((A - 1) - (A + 1) * cos_w0)
    b2 = A * ((A + 1) - (A - 1) * cos_w0 - sqrtA_2alpha)
    a0 = (A + 1) + (A - 1) * cos_w0 + sqrtA_2alpha
    a1 = -2.0 * ((A - 1) + (A + 1) * cos_w0)
    a2 = (A + 1) + (A - 1) * cos_w0 - sqrtA_2alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def biquad_highshelf(
    fc: float, sr: float, q: float, gain_db: float
) -> tuple[float, float, float, float, float]:
    """RBJ Cookbook high shelf (Q-form)."""
    _, cos_w0, alpha = _common(fc, sr, q)
    A = 10.0 ** (gain_db / 40.0)
    sqrtA_2alpha = 2.0 * math.sqrt(A) * alpha
    b0 = A * ((A + 1) + (A - 1) * cos_w0 + sqrtA_2alpha)
    b1 = -2.0 * A * ((A - 1) + (A + 1) * cos_w0)
    b2 = A * ((A + 1) + (A - 1) * cos_w0 - sqrtA_2alpha)
    a0 = (A + 1) - (A - 1) * cos_w0 + sqrtA_2alpha
    a1 = 2.0 * ((A - 1) - (A + 1) * cos_w0)
    a2 = (A + 1) - (A - 1) * cos_w0 - sqrtA_2alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def biquad_notch(
    fc: float, sr: float, q: float
) -> tuple[float, float, float, float, float]:
    """RBJ Cookbook notch (included for completeness; unused in v0)."""
    _, cos_w0, alpha = _common(fc, sr, q)
    b0 = 1.0
    b1 = -2.0 * cos_w0
    b2 = 1.0
    a0 = 1.0 + alpha
    a1 = -2.0 * cos_w0
    a2 = 1.0 - alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


_TYPE_DISPATCH = {
    "lpf": biquad_lpf,
    "hpf": biquad_hpf,
    "peak": biquad_peak,
    "lowshelf": biquad_lowshelf,
    "highshelf": biquad_highshelf,
    "notch": biquad_notch,
}


def coefficients_for_stage(stage: dict, sr: float) -> tuple[float, float, float, float, float]:
    """Return (b0, b1, b2, a1, a2) for a single stage at the given sample rate."""
    t = str(stage["type"]).lower()
    fc = float(stage["fc"])
    q = float(stage.get("q", 0.707))
    gain_db = float(stage.get("gain_db", 0.0))
    if t in ("peak", "lowshelf", "highshelf"):
        return _TYPE_DISPATCH[t](fc, sr, q, gain_db)
    if t in ("lpf", "hpf", "notch"):
        return _TYPE_DISPATCH[t](fc, sr, q)
    raise ValueError(f"unknown stage type {t!r}")


def coefficients_for_profile(
    profile: dict, sr: float
) -> list[tuple[float, float, float, float, float]]:
    """Return a list of biquad coefficient tuples for one profile."""
    return [coefficients_for_stage(s, sr) for s in profile.get("stages", [])]


# ---------------------------------------------------------------------------
# Direct Form I biquad cascade
# ---------------------------------------------------------------------------
#
# y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
#
# Implemented as a tight loop; vectorized scipy.signal.lfilter would
# be faster but we keep this verbatim so the engineer can match the
# Max [biquad~] sample-by-sample if needed for debugging.
#
# Denormal hazard: long silences feeding biquad recursion produce
# subnormal floats on x86. We add a tiny "anti-denormal" DC offset
# (1e-25) at the cascade input — too small to hear, large enough to
# keep the IIR state above the subnormal threshold. See JOS
# "Introduction to Digital Filters" §denormal-handling.


_DENORMAL_FLOOR = 1e-25


@dataclass
class _BiquadState:
    """Per-stage state for Direct Form I."""
    x1: float = 0.0
    x2: float = 0.0
    y1: float = 0.0
    y2: float = 0.0


def _process_cascade(
    x: np.ndarray, coeffs: list[tuple[float, float, float, float, float]]
) -> np.ndarray:
    """Run a sequence of biquad stages over a 1-D float array."""
    if len(coeffs) == 0:
        return x.copy()

    states = [_BiquadState() for _ in coeffs]
    out = np.empty_like(x)
    n = x.shape[0]
    # Precompute coeff tuples to avoid attribute lookups in inner loop.
    cs = coeffs

    for i in range(n):
        v = float(x[i]) + _DENORMAL_FLOOR
        for k, (b0, b1, b2, a1, a2) in enumerate(cs):
            s = states[k]
            y = b0 * v + b1 * s.x1 + b2 * s.x2 - a1 * s.y1 - a2 * s.y2
            s.x2 = s.x1
            s.x1 = v
            s.y2 = s.y1
            s.y1 = y
            v = y
        out[i] = v
    return out


# ---------------------------------------------------------------------------
# Crossfade helpers (model-change anti-click)
# ---------------------------------------------------------------------------


def _equal_power_crossfade_ramp(n_samples: int) -> tuple[np.ndarray, np.ndarray]:
    """Return (gain_old, gain_new) ramps of length n_samples.
    Equal-power: gain_old^2 + gain_new^2 ≈ 1 throughout."""
    if n_samples <= 0:
        return np.zeros(0), np.zeros(0)
    t = np.linspace(0.0, 1.0, n_samples, endpoint=True)
    gain_old = np.cos(t * 0.5 * np.pi)
    gain_new = np.sin(t * 0.5 * np.pi)
    return gain_old, gain_new


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def _validate_input(x: np.ndarray) -> np.ndarray:
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    if x.ndim != 2 or x.shape[1] != 2:
        raise ValueError(f"expected stereo or mono input, got shape {x.shape}")
    return x


def _validate_model(model: int) -> int:
    m = int(model)
    if not (0 <= m <= 12):
        raise ValueError(f"model out of range [0..12]: {m}")
    return m


def _process_one_channel(
    x: np.ndarray,
    sr: float,
    profile: dict,
) -> np.ndarray:
    coeffs = coefficients_for_profile(profile, sr)
    return _process_cascade(x, coeffs)


def process(
    x: np.ndarray,
    sr: float,
    *,
    model: int,
    filter_bypass: bool = False,
    table: dict | None = None,
) -> np.ndarray:
    """Process audio through the EQ profile selected by `model`.

    Args:
        x: shape (N,) mono or (N, 2) stereo, float32 or float64.
        sr: sample rate in Hz (e.g. 44100, 48000).
        model: int in [0, 12]. 0 → passthrough.
        filter_bypass: if True, output == input regardless of `model`.
        table: optional pre-loaded coefficient table dict (skips disk).

    Returns:
        Same shape and dtype as `x`.
    """
    x = _validate_input(x)
    m = _validate_model(model)

    if filter_bypass:
        return x.copy()

    if table is None:
        table = load_coefficient_table()
    profile = table["profiles"][str(m)]

    if profile.get("kind") == "bypass" or len(profile.get("stages", [])) == 0:
        return x.copy()

    # Stereo: process channels independently with separate filter state.
    out_l = _process_one_channel(x[:, 0].astype(np.float64), sr, profile)
    out_r = _process_one_channel(x[:, 1].astype(np.float64), sr, profile)
    return np.stack([out_l, out_r], axis=1).astype(x.dtype)


def process_with_change(
    x: np.ndarray,
    sr: float,
    *,
    model_old: int,
    model_new: int,
    change_sample: int,
    crossfade_ms: float = 12.0,
    filter_bypass_old: bool = False,
    filter_bypass_new: bool = False,
    table: dict | None = None,
) -> np.ndarray:
    """Process audio that contains exactly one model-change event.

    The "old" chain processes the entire buffer; a "new" chain (with
    its own filter state, warmed up from `change_sample - warmup_n`)
    processes from `change_sample` onward; the two are crossfaded
    over `crossfade_ms` to avoid clicks.

    This mirrors the approach the M4L patch will take: two parallel
    biquad chains in [poly~] voices, equal-power crossfade gain ramps
    on a [line~] driven by the model-change event.
    """
    x = _validate_input(x)
    if table is None:
        table = load_coefficient_table()
    n = x.shape[0]

    if filter_bypass_old:
        old = x.copy()
    else:
        old = process(x, sr, model=model_old, table=table)

    if filter_bypass_new:
        new = x.copy()
    else:
        new = process(x, sr, model=model_new, table=table)

    fade_n = max(1, int(round(crossfade_ms * 1e-3 * sr)))
    fade_n = min(fade_n, max(0, n - change_sample))
    if fade_n == 0:
        return old

    g_old, g_new = _equal_power_crossfade_ramp(fade_n)
    out = old.copy()
    end = change_sample + fade_n
    out[change_sample:end, 0] = (
        old[change_sample:end, 0] * g_old + new[change_sample:end, 0] * g_new
    )
    out[change_sample:end, 1] = (
        old[change_sample:end, 1] * g_old + new[change_sample:end, 1] * g_new
    )
    out[end:] = new[end:]
    return out


# ---------------------------------------------------------------------------
# Frequency response helper (verification only)
# ---------------------------------------------------------------------------


def frequency_response(
    profile: dict,
    sr: float,
    freqs: np.ndarray,
) -> np.ndarray:
    """Compute the magnitude response (linear, NOT dB) of a profile cascade
    at the given freq array. Used by the design doc verification scripts."""
    if len(profile.get("stages", [])) == 0:
        return np.ones_like(freqs, dtype=np.float64)

    coeffs = coefficients_for_profile(profile, sr)
    # H(z=exp(jw)) for biquad cascade
    w = 2.0 * np.pi * freqs / sr
    z_inv = np.exp(-1j * w)
    z_inv2 = z_inv * z_inv
    H = np.ones_like(w, dtype=np.complex128)
    for (b0, b1, b2, a1, a2) in coeffs:
        num = b0 + b1 * z_inv + b2 * z_inv2
        den = 1.0 + a1 * z_inv + a2 * z_inv2
        H *= num / den
    return np.abs(H)


# ---------------------------------------------------------------------------
# __main__: render fixtures
# ---------------------------------------------------------------------------


def _make_test_input(sr: float, dur_sec: float = 4.0) -> np.ndarray:
    """Test input: pink-ish noise + a stationary chord, 4 seconds.
    Pink noise reveals broadband EQ shape; the chord exposes how the
    profile colors harmonic content (which is what users actually hear)."""
    rng = np.random.default_rng(0)  # deterministic
    n = int(dur_sec * sr)
    t = np.arange(n) / sr

    # Pink noise via simple 1/f IIR (Voss-McCartney would be cleaner, but
    # one-pole 1/f works and is deterministic).
    white = rng.standard_normal(n).astype(np.float64)
    pink = np.empty(n, dtype=np.float64)
    b = 0.0
    a = 0.99
    for i in range(n):
        b = a * b + (1.0 - a) * white[i]
        pink[i] = b
    pink /= np.max(np.abs(pink)) or 1.0
    pink *= 0.25

    # Sustained chord: A2 + E3 + A3 + C#4 (A major, broad spectrum)
    chord = np.zeros(n, dtype=np.float64)
    fundamentals = [110.0, 164.81, 220.0, 277.18]
    for f0 in fundamentals:
        for k, gain in enumerate([1.0, 0.45, 0.25, 0.13, 0.06], start=1):
            chord += gain * np.sin(2.0 * np.pi * f0 * k * t + 0.13 * k * f0)
    chord /= np.max(np.abs(chord)) or 1.0
    chord *= 0.35

    # Light envelope so the start/end isn't a click.
    env = np.ones(n, dtype=np.float64)
    a_n = int(0.05 * sr)
    r_n = int(0.1 * sr)
    env[:a_n] = np.linspace(0.0, 1.0, a_n)
    env[-r_n:] = np.linspace(1.0, 0.0, r_n)

    sig = (pink + chord) * env
    sig /= max(1.0, np.max(np.abs(sig)))
    sig *= 0.7
    return np.stack([sig, sig], axis=1).astype(np.float32)


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny PCM16 WAV writer (no scipy/soundfile dependency)."""
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


def _slug(name: str) -> str:
    """File-system-safe slug for profile name."""
    s = name.lower().replace(" ", "_").replace("/", "_").replace("-", "_")
    return "".join(c for c in s if c.isalnum() or c == "_")


def render_fixtures(out_dir: Path, sr: int = 44100) -> list[Path]:
    """Render the dry input + one WAV per profile (1..12)."""
    table = load_coefficient_table()
    written: list[Path] = []
    in_audio = _make_test_input(sr=sr, dur_sec=4.0)

    dry_path = out_dir / "tl_model_eq_input_dry.wav"
    _save_wav(dry_path, in_audio, sr)
    written.append(dry_path)

    for i in range(1, 13):
        profile = table["profiles"][str(i)]
        name_slug = _slug(profile["name"])
        out = process(in_audio, sr=float(sr), model=i, table=table)
        path = out_dir / f"tl_model_eq_profile_{i:02d}_{name_slug}.wav"
        _save_wav(path, out, sr)
        written.append(path)
    return written


if __name__ == "__main__":
    out_dir = Path(__file__).resolve().parent / "fixtures"
    files = render_fixtures(out_dir)
    print(f"wrote {len(files)} fixture(s) to {out_dir}")
    for f in files:
        print(f"  {f}")
