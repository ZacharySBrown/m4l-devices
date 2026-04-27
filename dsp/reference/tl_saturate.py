"""tl_saturate — numpy reference implementation of the SATURATE module.

This is the golden render the Max patcher (`tl.saturate.maxpat`) must
match. It implements the chain in tape-loss-spec.md Module 1, refined
in `docs/design-docs/dsp/tl-saturate-design.md`:

    INPUT
      │
      ▼
    [INPUT_GAIN preamp]      LINE / INSTRUMENT (+6dB) / HIGH_GAIN (+12dB)
      │
      ▼
    [Pre-emphasis high-shelf]  +4 dB above 3 kHz (Q=0.7)
      │
      ▼
    [2× upsample (halfband FIR)]
      │
      ▼
    [Asymmetric polynomial / tanh hybrid waveshaper]
      │
      ▼
    [2× downsample (halfband FIR)]
      │
      ▼
    [De-emphasis high-shelf]   −4 dB above 3 kHz (Q=0.7)
      │
      ▼
    [DC blocker]               1-pole HPF at 20 Hz
      │
      ▼
    [Mis-bias offset inject]   ±0.002 max, gated by drive>8
      │
      ▼
    [Output level matching]    cancels INPUT_GAIN at small signals
      │
      ▼
    OUTPUT

Decisions (full rationale in design doc):
    - Memoryless asymmetric shaper — see §2 "memoryless vs hysteresis".
    - 2× oversampling around the shaper only (linear stages run native).
    - Pre/de-emphasis lives here (NOT in tl_model_eq) — see §4.
    - INPUT_GAIN compensated at output so only character changes.

References:
    - tape-loss-spec.md §"MODULE 1: tl.saturate.maxpat"
    - RBJ Audio EQ Cookbook (high-shelf coefficients)
    - Smith, "DSP Guide", Ch. 16 (windowed-sinc / halfband FIR design)
    - JOS, "Introduction to Digital Filters" (DC blocker, denormals)
    - JOS, "Physical Audio Signal Processing" (tape recording bias)
    - Pirkle, "Designing Audio Effect Plug-Ins in C++" §16.4
      (asymmetric-clipper recipe)

Determinism:
    Mis-bias inject uses a `numpy.random.Generator` seeded by the
    `seed` argument. With a fixed seed, output is bit-identical.

Public API:
    process(x, sr, *, saturate, input_gain="LINE", seed=0) -> ndarray

`x` is shape (N, 2) float32/float64 stereo; mono (N,) is duplicated.
"""

from __future__ import annotations

import dataclasses
import json
import math
from pathlib import Path
from typing import Literal

import numpy as np


# ---------------------------------------------------------------------------
# Parameter mapping
# ---------------------------------------------------------------------------


def _drive(saturate: float) -> float:
    """saturate ∈ [0, 1] → drive ∈ [1, 12], quadratic taper.

    See design doc §3 "Drive mapping". Quadratic distributes audible
    change uniformly across knob rotation.
    """
    s = float(np.clip(saturate, 0.0, 1.0))
    return 1.0 + 11.0 * (s ** 2)


def _bias(drive: float) -> float:
    """DC bias term, kicks in past drive=4 (saturate≈0.55), linear to
    0.05 at drive=12. Used in conjunction with `_beta` to break
    symmetry of the tanh curve."""
    return 0.05 * max(0.0, (drive - 4.0) / 8.0)


def _beta(drive: float) -> float:
    """Asymmetric-damping coefficient for the negative half of the
    waveshaper. 0 below drive=2, linear to 0.20 at drive=12.
    Pirkle §16.4 ("Asymmetric Distortion")."""
    return 0.20 * max(0.0, (drive - 2.0) / 10.0)


_INPUT_GAIN_DB = {"LINE": 0.0, "INSTRUMENT": 6.0, "HIGH_GAIN": 12.0}


def _input_gain_lin(mode: str) -> float:
    if mode not in _INPUT_GAIN_DB:
        raise ValueError(f"unknown input_gain mode {mode!r}; "
                         f"expected one of {list(_INPUT_GAIN_DB)}")
    return 10.0 ** (_INPUT_GAIN_DB[mode] / 20.0)


# ---------------------------------------------------------------------------
# RBJ high-shelf biquad — coefficient computation
# ---------------------------------------------------------------------------
#
# Per RBJ Audio EQ Cookbook §"High shelf":
#     b0 =    A · ((A+1) + (A−1)·cos + 2·√A·α)
#     b1 = −2·A · ((A−1) + (A+1)·cos)
#     b2 =    A · ((A+1) + (A−1)·cos − 2·√A·α)
#     a0 =        (A+1) − (A−1)·cos + 2·√A·α
#     a1 =    2 · ((A−1) − (A+1)·cos)
#     a2 =        (A+1) − (A−1)·cos − 2·√A·α
# where  A   = 10^(gain_dB / 40)
#        ω0  = 2π · fc / Fs
#        α   = sin(ω0) / (2·Q)
#
# All coefficients are then divided by a0 before use (a0 implicitly = 1).
# Vendored at ~/raindog/harness/references/audio-eq-cookbook.md


def highshelf_coeffs(fc: float, q: float, gain_db: float, sr: float
                     ) -> tuple[float, float, float, float, float]:
    """RBJ high-shelf biquad. Returns (b0, b1, b2, a1, a2) normalized
    by a0. a0 implicitly 1.0 after normalization."""
    A = 10.0 ** (gain_db / 40.0)
    w0 = 2.0 * math.pi * fc / sr
    cos_w = math.cos(w0)
    sin_w = math.sin(w0)
    alpha = sin_w / (2.0 * q)
    sqA = math.sqrt(A)
    two_sqA_alpha = 2.0 * sqA * alpha
    Ap1 = A + 1.0
    Am1 = A - 1.0

    b0 = A * (Ap1 + Am1 * cos_w + two_sqA_alpha)
    b1 = -2.0 * A * (Am1 + Ap1 * cos_w)
    b2 = A * (Ap1 + Am1 * cos_w - two_sqA_alpha)
    a0 = Ap1 - Am1 * cos_w + two_sqA_alpha
    a1 = 2.0 * (Am1 - Ap1 * cos_w)
    a2 = Ap1 - Am1 * cos_w - two_sqA_alpha
    return b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0


def biquad_apply(x: np.ndarray, coeffs: tuple[float, float, float, float, float]
                 ) -> np.ndarray:
    """Direct Form I biquad on a 1-D array.

    DFI chosen over Transposed DF-II because our coefficients are
    static (one set per sample-rate / shelf gain, recomputed only on
    sr change). DFI has cleaner numerical reasoning at 64-bit float;
    JOS *Introduction to Digital Filters* §"Numerical Considerations".
    """
    b0, b1, b2, a1, a2 = coeffs
    n = x.shape[0]
    y = np.zeros(n, dtype=np.float64)
    x1 = x2 = y1 = y2 = 0.0
    for i in range(n):
        xn = float(x[i])
        yn = b0 * xn + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        # Denormal flush — recursive structures with idle inputs can
        # accumulate denormals over hours, costing CPU on x86.
        if abs(yn) < 1e-30:
            yn = 0.0
        y[i] = yn
        x2 = x1
        x1 = xn
        y2 = y1
        y1 = yn
    return y


# ---------------------------------------------------------------------------
# Halfband FIR (31-tap) — for 2× upsampling and downsampling
# ---------------------------------------------------------------------------
#
# A halfband FIR has the property that h[n] == 0 for all even n except
# the center (n == N//2). This means we get free zeros — only ~half
# the multiplies are non-trivial.
#
# Designed via windowed-sinc with Kaiser window (β=8.0). 31 taps gives
# ~80 dB stopband attenuation. Cutoff at fs/4 (i.e., the new Nyquist
# at the *higher* sample rate) so passband extends to ~19 kHz at
# 44.1 kHz host rate.
#
# Smith, "DSP Guide" Ch. 16. JOS, "Spectral Audio Signal Processing"
# (halfband as polyphase decomposition).


def design_halfband_fir(num_taps: int = 31, cutoff_norm: float = 0.5,
                         beta: float = 8.0) -> np.ndarray:
    """Design a halfband FIR by windowed-sinc.

    Args:
        num_taps: must be odd; gives a Type I FIR with linear phase.
        cutoff_norm: normalized cutoff (0..1, where 1.0 = Nyquist).
                     For halfband, this is 0.5.
        beta: Kaiser window beta (8.0 ≈ 80 dB stopband).

    Returns h[n] of length num_taps. By halfband symmetry, h[k] == 0
    for k != center and (k - center) odd.
    """
    if num_taps % 2 == 0:
        raise ValueError("halfband FIR requires odd number of taps")
    n = np.arange(num_taps) - (num_taps - 1) / 2.0
    # sinc-based ideal lowpass at fc = 0.5 (cutoff_norm * 0.5 in
    # half-spectrum convention, but here we want fc / (sr/2) = 0.5).
    sinc = np.sinc(cutoff_norm * n)
    # Kaiser window
    w = np.kaiser(num_taps, beta)
    h = sinc * w
    # Normalize to unity DC gain
    h /= np.sum(h)
    # Force exact halfband zeros (numerical noise around the true zeros)
    center = (num_taps - 1) // 2
    for k in range(num_taps):
        if k != center and (k - center) % 2 == 0:
            h[k] = 0.0
    # Renormalize after zeroing (tiny correction)
    h /= np.sum(h)
    return h


_HB_FIR = design_halfband_fir(num_taps=31, cutoff_norm=0.5, beta=8.0)


def upsample_2x(x: np.ndarray, fir: np.ndarray = _HB_FIR) -> np.ndarray:
    """Insert zero between every sample, then convolve with the
    halfband FIR. This is the standard 2× upsampler.

    Result length = 2 · len(x). Output is scaled by 2.0 to compensate
    for the energy lost to zero-insertion (so RMS is preserved across
    the upsampler-downsampler pair).
    """
    n = x.shape[0]
    up = np.zeros(2 * n, dtype=np.float64)
    up[::2] = x
    # Convolve, mode='same' to preserve length 2n.
    y = np.convolve(up, fir, mode="same")
    return y * 2.0


def downsample_2x(x: np.ndarray, fir: np.ndarray = _HB_FIR) -> np.ndarray:
    """Lowpass with halfband FIR, then take every other sample."""
    y = np.convolve(x, fir, mode="same")
    return y[::2]


# ---------------------------------------------------------------------------
# Asymmetric polynomial / tanh waveshaper
# ---------------------------------------------------------------------------


def waveshape_asymmetric(x: np.ndarray, drive: float) -> np.ndarray:
    """Asymmetric tanh-based waveshaper.

    For u = x + bias:
        base = tanh(drive · u) / tanh(drive)            (output saturates at ±1)
        y    = base · (1 + β · u)   if u < 0,   else base

    Small-signal slope is `drive / tanh(drive)` — i.e., turning the
    saturate knob up *also* increases pre-clip gain. This is
    intentional and matches the spec formula (and how every boutique
    drive pedal behaves: more drive = more output until clipping).
    The chain compensates with a saturate-dependent output makeup
    attenuation to keep perceived loudness in a sane band, so that
    A/B at different settings compares character not loudness.

    `bias` and `β` derive from drive (see _bias, _beta above).

    Pirkle §16.4; design doc §3.
    """
    b = _bias(drive)
    beta = _beta(drive)
    u = x + b
    base = np.tanh(drive * u) / math.tanh(drive)
    mult = np.where(u < 0.0, 1.0 + beta * u, 1.0)
    return base * mult


def _output_makeup_db(drive: float) -> float:
    """Saturate-dependent output trim that limits loudness blow-up.

    The shaper's small-signal gain is `drive/tanh(drive)`. At drive=1,
    this is ≈ 1.31 (+2.4 dB); at drive=12, it's ≈ 12.0 (+21.6 dB).
    Without compensation, turning the saturate knob would also boost
    loudness by 20+ dB at the top of the sweep, which is musically
    correct (it IS a drive knob) but makes the output unusably loud
    and confuses A/B comparison.

    We compensate by ~70% of the small-signal gain in dB. This still
    lets the user hear "drive = louder" (≈ +6 dB across the sweep,
    a healthy push) while preventing speaker-blowing levels at full.
    Tradeoff log entry #15.
    """
    full_comp_db = 20.0 * math.log10(drive / math.tanh(drive))
    return -0.70 * full_comp_db


# ---------------------------------------------------------------------------
# DC blocker — 1-pole HPF at 20 Hz
# ---------------------------------------------------------------------------


def dc_blocker_R(sr: float, fc: float = 20.0) -> float:
    """Pole radius for the leaky-integrator DC blocker.

    R = exp(−2π · fc / sr)  →  cutoff ≈ fc.
    JOS, "Introduction to Digital Filters", §"DC blocker".
    """
    return math.exp(-2.0 * math.pi * fc / sr)


def dc_block_apply(x: np.ndarray, R: float) -> np.ndarray:
    """y[n] = x[n] − x[n−1] + R · y[n−1]"""
    n = x.shape[0]
    y = np.zeros(n, dtype=np.float64)
    x1 = 0.0
    y1 = 0.0
    for i in range(n):
        xn = float(x[i])
        yn = xn - x1 + R * y1
        y[i] = yn
        x1 = xn
        y1 = yn
    return y


# ---------------------------------------------------------------------------
# Mis-bias slow random walk (drive > 8 only)
# ---------------------------------------------------------------------------


def mis_bias_signal(n_samples: int, sr: float, drive: float,
                    rng: np.random.Generator) -> np.ndarray:
    """Drive-gated low-frequency wander, ±0.002 max at drive=12.

    Implementation: white noise → 1-pole LPF at 0.5 Hz → scale.
    """
    if drive <= 8.0:
        return np.zeros(n_samples, dtype=np.float64)

    # Scale (0..1) at drive=8..12
    scale = (drive - 8.0) / 4.0
    scale = float(np.clip(scale, 0.0, 1.0))

    # 1-pole LPF at 0.5 Hz: alpha = 2π·fc/sr; small.
    fc = 0.5
    alpha = 2.0 * math.pi * fc / sr
    if alpha > 1.0:
        alpha = 1.0

    noise = rng.standard_normal(n_samples).astype(np.float64)
    walk = np.zeros(n_samples, dtype=np.float64)
    y = 0.0
    for i in range(n_samples):
        y = (1.0 - alpha) * y + alpha * noise[i]
        walk[i] = y

    # Remove DC drift from the random walk so the inject is zero-mean
    # over the buffer (otherwise the average mis-bias offset shows up
    # as a static DC pedestal in the output).
    walk -= np.mean(walk)
    # Normalize to peak ~1.0, then scale.
    peak = float(np.max(np.abs(walk))) or 1.0
    walk /= peak
    return np.clip(0.002 * scale * walk, -0.002, 0.002)


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


@dataclasses.dataclass
class SaturateParams:
    saturate: float = 0.0
    input_gain: Literal["LINE", "INSTRUMENT", "HIGH_GAIN"] = "LINE"


def _process_one_channel(x: np.ndarray, sr: float, p: SaturateParams,
                          rng: np.random.Generator) -> np.ndarray:
    """Apply the full chain to a single mono channel."""
    n = x.shape[0]
    drive = _drive(p.saturate)

    # Stage 1: input gain (linear)
    g_in = _input_gain_lin(p.input_gain)
    y = x.astype(np.float64) * g_in

    # saturate=0 → bypass the entire nonlinear chain. The shelves,
    # DC blocker, and mis-bias all collapse to no-ops at this setting
    # too, so we can short-circuit cleanly.
    if p.saturate <= 0.0:
        # Still apply input-gain compensation so output is mode-independent.
        g_out_db = -_INPUT_GAIN_DB[p.input_gain]
        g_out = 10.0 ** (g_out_db / 20.0)
        return y * g_out

    # Stage 2: pre-emphasis high-shelf, +4 dB @ 3 kHz, Q=0.7
    pre_coef = highshelf_coeffs(fc=3000.0, q=0.7, gain_db=+4.0, sr=sr)
    y = biquad_apply(y, pre_coef)

    # Stage 3: 2× upsample
    y_up = upsample_2x(y)

    # Stage 4: nonlinear waveshape at 2× rate
    y_up_shaped = waveshape_asymmetric(y_up, drive=drive)

    # Stage 5: 2× downsample
    y = downsample_2x(y_up_shaped)
    # Defensive: ensure length matches input (numpy 'same' should already)
    y = y[:n]
    if y.shape[0] < n:
        y = np.concatenate([y, np.zeros(n - y.shape[0])])

    # Stage 6: de-emphasis high-shelf, −4 dB @ 3 kHz, Q=0.7
    post_coef = highshelf_coeffs(fc=3000.0, q=0.7, gain_db=-4.0, sr=sr)
    y = biquad_apply(y, post_coef)

    # Stage 7: DC blocker, 20 Hz
    R = dc_blocker_R(sr=sr, fc=20.0)
    y = dc_block_apply(y, R)

    # Stage 8: mis-bias inject (drive>8 only)
    inject = mis_bias_signal(n, sr=sr, drive=drive, rng=rng)
    y = y + inject

    # Stage 9a: drive-dependent output makeup — keeps loudness in a
    # consistent band across the saturate sweep so A/B comparisons
    # measure character, not amplitude.
    makeup_db = _output_makeup_db(drive)
    y = y * (10.0 ** (makeup_db / 20.0))

    # Stage 9b: output level compensation — cancel INPUT_GAIN linear
    # gain so small-signal loudness is mode-independent.
    g_out_db = -_INPUT_GAIN_DB[p.input_gain]
    g_out = 10.0 ** (g_out_db / 20.0)
    y = y * g_out

    return y


def process(x: np.ndarray, sr: float, *, saturate: float,
            input_gain: str = "LINE", seed: int = 0) -> np.ndarray:
    """Process a mono or stereo audio buffer through tl_saturate.

    Args:
        x: shape (N,) mono or (N, 2) stereo, float32 or float64.
        sr: sample rate in Hz.
        saturate: 0..1.
        input_gain: "LINE" | "INSTRUMENT" | "HIGH_GAIN".
        seed: RNG seed for the mis-bias random walk. Same seed +
              same args = bit-identical output.

    Returns:
        ndarray with the same shape and dtype as `x`.
    """
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    if x.ndim != 2 or x.shape[1] != 2:
        raise ValueError(f"expected stereo or mono input, got shape {x.shape}")

    p = SaturateParams(
        saturate=float(np.clip(saturate, 0.0, 1.0)),
        input_gain=input_gain,
    )

    # Independent RNG streams for L and R via SeedSequence.spawn —
    # avoids correlation across channels (same justification as
    # tl_failure spread mode).
    ss = np.random.SeedSequence(seed)
    ss_l, ss_r = ss.spawn(2)
    rng_l = np.random.default_rng(ss_l)
    rng_r = np.random.default_rng(ss_r)

    out_l = _process_one_channel(x[:, 0], sr, p, rng_l)
    out_r = _process_one_channel(x[:, 1], sr, p, rng_r)

    return np.stack([out_l, out_r], axis=1).astype(x.dtype)


# ---------------------------------------------------------------------------
# __main__: render fixtures and verify properties
# ---------------------------------------------------------------------------


def _make_test_input(sr: float, dur_sec: float = 3.0) -> np.ndarray:
    """Synthetic 'guitar-like' input: A2 + E3 + A3 chord with a slow
    attack/release envelope. Same input as tl_failure for direct A/B."""
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    fundamentals = [110.0, 164.81, 220.0]
    sig = np.zeros(n, dtype=np.float64)
    for f0 in fundamentals:
        for k, gain in enumerate([1.0, 0.5, 0.3, 0.15, 0.08], start=1):
            sig += gain * np.sin(2.0 * np.pi * f0 * k * t + 0.1 * k)
    sig /= np.max(np.abs(sig)) or 1.0
    sig *= 0.6  # leave headroom

    env = np.ones(n, dtype=np.float64)
    a_n = int(0.1 * sr)
    r_n = int(0.4 * sr)
    env[:a_n] = np.linspace(0.0, 1.0, a_n)
    env[-r_n:] = np.linspace(1.0, 0.0, r_n)
    sig *= env
    return np.stack([sig, sig], axis=1).astype(np.float32)


def _make_sine_input(sr: float, freq: float = 1000.0, dur_sec: float = 1.0,
                      amp: float = 0.5) -> np.ndarray:
    """Pure sine for spectrum / THD measurement."""
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    sig = amp * np.sin(2.0 * np.pi * freq * t)
    return np.stack([sig, sig], axis=1).astype(np.float32)


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny WAV writer (PCM16). Same helper as tl_failure for parity."""
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


def _measure_thd(y: np.ndarray, sr: float, fund_freq: float) -> float:
    """Total Harmonic Distortion — root of the energy in non-fundamental
    bins divided by energy in the fundamental bin. Single-channel input.
    """
    n = y.shape[0]
    # Hann window to suppress leakage
    win = np.hanning(n)
    Y = np.fft.rfft(y * win)
    freqs = np.fft.rfftfreq(n, d=1.0 / sr)
    bin_w = freqs[1] - freqs[0]
    fund_bin = int(round(fund_freq / bin_w))
    # Sum a small range around fundamental and harmonics
    half_w = 3
    fund_e = float(np.sum(np.abs(Y[fund_bin - half_w:fund_bin + half_w + 1]) ** 2))
    harm_e = 0.0
    for k in range(2, 11):
        h_bin = int(round(k * fund_freq / bin_w))
        if h_bin + half_w + 1 >= len(Y):
            break
        harm_e += float(np.sum(np.abs(Y[h_bin - half_w:h_bin + half_w + 1]) ** 2))
    if fund_e <= 0.0:
        return 0.0
    return math.sqrt(harm_e / fund_e)


def render_fixtures(out_dir: Path, sr: int = 44100) -> list[Path]:
    """Render a sanity-check WAV at several saturate settings, plus
    a 1 kHz sine sweep at saturate=1.0 for spectrum inspection.

    Returns the list of files written, in the order they were rendered.
    """
    written: list[Path] = []
    in_audio = _make_test_input(sr=sr, dur_sec=3.0)

    # Save the dry input as reference.
    dry_path = out_dir / "tl_saturate_input_dry.wav"
    _save_wav(dry_path, in_audio, sr)
    written.append(dry_path)

    settings = [
        ("sat0p0_LINE",        dict(saturate=0.0, input_gain="LINE")),
        ("sat0p3_LINE",        dict(saturate=0.3, input_gain="LINE")),
        ("sat0p7_LINE",        dict(saturate=0.7, input_gain="LINE")),
        ("sat1p0_LINE",        dict(saturate=1.0, input_gain="LINE")),
        ("sat0p7_INSTRUMENT",  dict(saturate=0.7, input_gain="INSTRUMENT")),
        ("sat0p7_HIGH_GAIN",   dict(saturate=0.7, input_gain="HIGH_GAIN")),
    ]

    for tag, kw in settings:
        out = process(in_audio, sr=float(sr), seed=42, **kw)
        path = out_dir / f"tl_saturate_demo_{tag}.wav"
        _save_wav(path, out, sr)
        written.append(path)

    # 1 kHz sine for spectrum / THD inspection at full drive
    sine_in = _make_sine_input(sr=sr, freq=1000.0, dur_sec=1.0, amp=0.5)
    sine_out = process(sine_in, sr=float(sr), saturate=1.0,
                       input_gain="LINE", seed=42)
    sweep_path = out_dir / "tl_saturate_demo_sweep1k.wav"
    _save_wav(sweep_path, sine_out, sr)
    written.append(sweep_path)

    return written


def _run_property_checks(sr: int = 44100) -> dict[str, object]:
    """Verification battery — used both as sanity-test in __main__
    and as a hashable property record for regression. Returns a dict
    of measured values. Design doc §15 lists target ranges."""
    in_chord = _make_test_input(sr=sr, dur_sec=1.0)
    in_sine = _make_sine_input(sr=sr, freq=1000.0, dur_sec=1.0, amp=0.5)

    # 1) saturate=0 → cascade error at 1 kHz
    y0 = process(in_sine, sr=float(sr), saturate=0.0, seed=0)
    rms_in = float(np.sqrt(np.mean(in_sine[:, 0] ** 2)))
    rms_y0 = float(np.sqrt(np.mean(y0[:, 0] ** 2)))
    cascade_err_db = 20.0 * math.log10(rms_y0 / rms_in)

    # 2) THD monotonically rises with saturate
    thds = []
    for s in [0.0, 0.3, 0.5, 0.7, 1.0]:
        y = process(in_sine, sr=float(sr), saturate=s, seed=0)
        thds.append((s, _measure_thd(y[:, 0], sr=float(sr),
                                     fund_freq=1000.0)))

    # 3) INPUT_GAIN modes preserve small-signal output level
    rms_modes = {}
    for mode in ["LINE", "INSTRUMENT", "HIGH_GAIN"]:
        y = process(in_sine, sr=float(sr), saturate=0.0,
                    input_gain=mode, seed=0)
        rms_modes[mode] = float(np.sqrt(np.mean(y[:, 0] ** 2)))

    # 4) DC offset in output
    y_full = process(in_chord, sr=float(sr), saturate=1.0, seed=0)
    dc_offset = float(np.mean(y_full[:, 0]))

    # 5) No NaN/Inf
    n_bad = int(np.sum(~np.isfinite(y_full)))

    # 6) Even-harmonic emergence — H2 amplitude across saturate sweep
    h2_levels = []
    for s in [0.0, 0.3, 0.5, 0.7, 1.0]:
        y = process(in_sine, sr=float(sr), saturate=s, seed=0)
        n = y.shape[0]
        win = np.hanning(n)
        Y = np.fft.rfft(y[:, 0] * win)
        freqs = np.fft.rfftfreq(n, d=1.0 / sr)
        bin_w = freqs[1] - freqs[0]
        h2_bin = int(round(2000.0 / bin_w))
        h2_amp = float(np.max(np.abs(Y[h2_bin - 3:h2_bin + 4])))
        h2_levels.append((s, h2_amp))

    return {
        "cascade_err_db_at_1khz_sat0": cascade_err_db,
        "thd_sweep": thds,
        "rms_by_input_gain_at_sat0": rms_modes,
        "dc_offset_at_sat1": dc_offset,
        "n_nonfinite_at_sat1": n_bad,
        "h2_amp_sweep": h2_levels,
    }


if __name__ == "__main__":
    sr = 44100
    out_dir = Path(__file__).resolve().parent / "fixtures"
    files = render_fixtures(out_dir, sr=sr)
    print(f"wrote {len(files)} fixture(s) to {out_dir}")
    for f in files:
        print(f"  {f}")
    print()
    print("--- property checks ---")
    props = _run_property_checks(sr=sr)
    for k, v in props.items():
        print(f"  {k}: {v}")
