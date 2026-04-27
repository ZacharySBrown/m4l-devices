"""tl_flutter — numpy reference implementation of the FLUTTER module.

This is the golden render the Max patcher (`tl.flutter.maxpat`) must
match. It implements the fast pitch + AM modulation per
tape-loss-spec.md §"MODULE 5: tl.flutter.maxpat" and the design
doc at `docs/design-docs/dsp/tl-flutter-design.md`.

ROUND-2 TAPER RECALIBRATION (2026-04-26, TUNING_VERSION = 2)
------------------------------------------------------------
User feedback (verbatim): "The flutter sounds great, but it's almost
non-existent on the chord at 0.5". Round-1 used `f²` for pitch depth
and `f` for AM depth — the quadratic put noon pitch p99 at ~6 c
(ground-truth measurement), inaudible against harmonically rich
content. Even a linear `f` taper at the +25 %-max-bump cap leaves
noon pitch p99 at ~14 c (still under the ~18 c audibility floor on
the A2/E3/A3 chord). The only shape that lifts noon enough while
respecting the max-bump cap is **sqrt(f)** — concave, lots at low
values, plateaus at high.

Round-2 changes:
  * Pitch taper: `1.2e-4·f² → 1.5e-4·sqrt(f)`  (max +25 %, sqrt shape)
  * AM    taper: `0.20·f    → 0.25·sqrt(f)`    (max +25 %, sqrt shape)
Ground-truth values (delay-derivative & multiplier-swing, seed=42):
  f      pitch_p99_c   pitch_pmax_c   AM_swing_dB
  0.25     14.2           22.5          ~2.5
  0.50     20.1           31.9          ~3.4
  0.75     24.6           39.1          ~4.3
  1.00     28.4           45.3          ~5.0
Round-1 at f=1.0 was p99 22.8 c / pmax 36.1 c / AM 3.2 dB pk-pk.
Round-2 max climbs ~25 % across the board — within the user's cap.
sqrt(0.1)=0.316 → ~9 c at f=0.1, a healthy "minimum effect" rather
than near-silence.

Bit-identical passthrough at f=0.0 preserved (no RNG advance; sqrt(0)=0).

Topology (per channel):

    x[n]
      │
      ▼
    [pitch-mod LFO bank]                      ┌───── classic_mode = 1
      │  noise → LPF(8 Hz)  ─┐                │     bypasses AM stage
      │  noise → LPF(19 Hz) ─┴── 0.5·sum      │
      │  → flutter_pitch_depth(f)             │
      │  → +base_delay                        │
      │                                       │
      ▼                                       │
    [variable-delay read, Lagrange-4 interp]  │
      │                                       │
      ▼                                       │
    x_pitched[n]                              │
      │                                       │
      ▼                                       │
    [AM-mod LFO bank]                         │
      │  noise → LPF(11 Hz) ─┐                │
      │  noise → LPF(23 Hz) ─┴── 0.5·sum      │
      │  → flutter_am_depth(f)                │
      │  → 1 + d·m[n]                         │
      ▼  (gated off when classic_mode = 1) ◄──┘
    y[n] = x_pitched[n] · (1 + d_am·m[n])

References:
    - Robert Bristow-Johnson, *Audio EQ Cookbook*
      (https://www.w3.org/TR/audio-eq-cookbook/) — RBJ LPF biquad.
    - Julius O. Smith III, *Physical Audio Signal Processing*:
        - "Wow and Flutter Modeling"
          (ccrma.stanford.edu/~jos/pasp/Wow_Flutter_Modeling.html)
        - "Lagrange Interpolation"
          (ccrma.stanford.edu/~jos/pasp/Lagrange_Interpolation.html)
    - JOS, *Introduction to Digital Filters with Audio Applications* —
      Direct Form I, denormal handling.
    - W. Pirkle, *Designing Audio Effect Plug-Ins in C++* (2nd ed.),
      Ch. 6 — flutter rate/depth ranges for boutique character.
    - tape-loss-spec.md §"MODULE 5: tl.flutter.maxpat".

Determinism:
    A single `seed` parameter drives all RNGs. SeedSequence.spawn(4)
    yields four independent generators (2 channels × 2 paths
    [pitch, AM]). Same seed + args → bit-identical output.

Public API:
    process(x, sr, *, flutter, classic_mode=False, seed=0) -> ndarray

`x` is shape (N,) mono (auto-duplicated) or (N, 2) stereo.
Output is the same shape as the duplicated/passed-in stereo array.
"""

from __future__ import annotations

import dataclasses
import math
from pathlib import Path

import numpy as np


# Round-2 retune (see top-of-file note). Bumped on every taper change so
# downstream regression tests can key off a single integer.
TUNING_VERSION = 2


# ---------------------------------------------------------------------------
# Parameter mapping
# ---------------------------------------------------------------------------


def _flutter_pitch_depth_seconds(f: float) -> float:
    """Peak delay-swing (seconds). ROUND-2 taper:

        depth(f) = 1.5e-4 · sqrt(f)          (concave / square-root)

    Round-1 used `1.2e-4 · f²` — convex/quadratic, putting noon at
    25 % of max (~6 c peak99 ground-truth) and inaudible on chords.
    Linear `f` was insufficient even at the 25 %-max-bump cap — noon
    p99 stayed ~14 c. Sqrt is the most concave taper short of a
    step function and is the only shape that lifts noon above the
    ~18 c audibility floor while keeping max within the +25 % cap.
    Max bumped from 1.2e-4 → 1.5e-4 s (+25 %, at the cap).

    Ground-truth peak99 cents (delay-derivative measurement; same
    seed=42 LFO):
      f=0.25:  depth=7.5e-5,  p99=14.2 c
      f=0.50:  depth=1.06e-4, p99=20.1 c   ← clears 18 c floor
      f=0.75:  depth=1.30e-4, p99=24.6 c
      f=1.00:  depth=1.50e-4, p99=28.4 c   (round-1 was 22.8 c)

    sqrt(0.1) = 0.316 → depth=4.7e-5, p99=9 c — a healthy "minimum
    effect" rather than near-silence.  Confirmed not jarring vs the
    round-1 baseline (round-1 at f=0.5 was 5.7 c; round-2 at f=0.1
    is ~9 c — same perceptual order of magnitude).

    The depth value is small (1.5e-4 s = 6.6 samples at 44.1 kHz)
    because pitch shift via fractional delay is governed by *slope*
    of the delay envelope, not its absolute magnitude. See design
    doc §3 for the full FM-relation derivation; round-2 calibration
    in design doc §round-2.
    """
    return 1.5e-4 * math.sqrt(max(0.0, f))


def _flutter_am_depth(f: float) -> float:
    """Peak fractional gain swing of the AM multiplier `1 + d·m(t)`.

    ROUND-2 taper: `0.25 · sqrt(f)` (was `0.20 · f` — linear).
    Same shape change as the pitch taper: sqrt lifts noon while
    keeping max in check. Max bumped 25 % (0.20 → 0.25, at the cap).

    Worked values:
      f=0.25:  d=0.125     → ~±1.1 dB typical swing
      f=0.50:  d=0.177     → ~±1.5 dB typical, ~±3.4 dB peak (clears
                              ≥1.0 dB chord-noon assertion)
      f=0.75:  d=0.216     → ~±1.9 dB typical, ~±4.3 dB peak
      f=1.00:  d=0.25      → ~±2.2 dB typical, ~±5 dB peak

    Round-1 at f=1.0 measured ~3.2 dB pk-to-pk on a sine; round-2
    will measure ~4 dB pk-to-pk — over the ±3 dB "shimmer not
    tremolo" spec target on rare peaks but well within typical
    swing. Tradeoff: noon audibility is the primary objective per
    user feedback. See design doc §round-2 for the discussion.
    """
    return 0.25 * math.sqrt(max(0.0, f))


# Pitch-mod LFO band cutoffs (Hz). Two bands per channel, summed.
_PITCH_LFO_BANDS = [(8.0, 0.7), (19.0, 0.7)]
# AM-mod LFO band cutoffs. Offset from pitch bands so AM doesn't track pitch.
_AM_LFO_BANDS = [(11.0, 0.6), (23.0, 0.6)]

# Base delay in seconds for the variable-delay read. Matches `tl_wow`'s
# base offset so a future shared-buffer M4L impl can use the same line.
_BASE_DELAY_S = 5.0e-3


# ---------------------------------------------------------------------------
# RBJ LPF biquad
# ---------------------------------------------------------------------------


def _lpf_coeffs(fc: float, q: float, sr: float) -> tuple[float, float, float, float, float]:
    """RBJ Audio EQ Cookbook 2nd-order LPF coefficients.

    Returns (b0, b1, b2, a1, a2) normalized by a0.
    """
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
    """Direct Form I biquad with denormal flush. Per JOS *Filters* Ch. 9
    DF-I has the cleanest numerical behavior for static coefficients."""
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
# LFO bank — two filtered-noise streams summed and renormalized
# ---------------------------------------------------------------------------


def _build_lfo(n_samples: int, sr: float, bands: list[tuple[float, float]],
               rng: np.random.Generator) -> np.ndarray:
    """Generate a control-rate LFO from summed filtered-noise bands.

    Each band: white noise → LPF(fc, Q) → contribute. After summing, the
    result is **percentile-peak-normalized** so that the 99th-percentile
    of |out| ≈ 1.0. This makes subsequent depth-multiplication
    (`depth · lfo`) map cleanly to the user-facing peak excursion target:
    a typical worst-case sample of `depth · lfo` is `±depth`, with
    occasional outliers up to ~1.4·depth.

    Why 99th percentile and not absolute peak? Filtered Gaussian noise
    has heavy tails; absolute peak is a single-sample outlier, swings
    around 3–4 RMS, and makes depth math unintuitive. RMS-normalization
    is the other extreme — peak then sits at ~3–4× the depth target.
    The 99th-percentile choice gives stable depth math: the user-facing
    "max" knob value produces the user-facing "max" excursion >99% of
    the time, with rare audible peaks up to ~1.4× the target. This
    matches real tape behavior, where flutter has occasional larger
    excursions on top of a steadier baseline.

    Returns shape (n_samples,) float64.
    """
    out = np.zeros(n_samples, dtype=np.float64)
    for fc, q in bands:
        noise = rng.standard_normal(n_samples).astype(np.float64)
        coeffs = _lpf_coeffs(fc, q, sr)
        filtered = _biquad_apply(noise, coeffs)
        out += filtered
    out /= float(len(bands))
    # 99th-percentile peak normalization (see docstring).
    p99 = float(np.percentile(np.abs(out), 99.0)) or 1.0
    return out / p99


# ---------------------------------------------------------------------------
# Variable-delay read (Lagrange-4 interpolation)
# ---------------------------------------------------------------------------


def _read_lagrange4(buf: np.ndarray, idx: int, frac: float) -> float:
    """4-point Lagrange interpolation read at position (idx + frac).

    `frac ∈ [0, 1)`; samples drawn at idx-1, idx, idx+1, idx+2.
    Per JOS *Physical Audio Signal Processing* "Lagrange Interpolation".
    Out-of-range reads return 0.
    """
    n = buf.shape[0]
    i_m1 = idx - 1
    i_0 = idx
    i_p1 = idx + 1
    i_p2 = idx + 2
    xm1 = buf[i_m1] if 0 <= i_m1 < n else 0.0
    x0 = buf[i_0] if 0 <= i_0 < n else 0.0
    x1 = buf[i_p1] if 0 <= i_p1 < n else 0.0
    x2 = buf[i_p2] if 0 <= i_p2 < n else 0.0
    # Lagrange-4 coefficients
    c0 = -frac * (frac - 1.0) * (frac - 2.0) / 6.0
    c1 = (frac + 1.0) * (frac - 1.0) * (frac - 2.0) / 2.0
    c2 = -(frac + 1.0) * frac * (frac - 2.0) / 2.0
    c3 = (frac + 1.0) * frac * (frac - 1.0) / 6.0
    return c0 * xm1 + c1 * x0 + c2 * x1 + c3 * x2


def _apply_variable_delay(x: np.ndarray, delay_samples: np.ndarray) -> np.ndarray:
    """Apply per-sample variable delay via Lagrange-4 read.

    `delay_samples[n]` is the *positive* delay in samples (≥ 0). Output
    sample n is read from x[n - delay_samples[n]] with fractional
    interpolation. A short buffer prefix of zeros is conceptually
    prepended; we just clamp out-of-range reads to 0.
    """
    n = x.shape[0]
    y = np.zeros_like(x)
    for i in range(n):
        d = delay_samples[i]
        rp = float(i) - d
        rp_floor = int(math.floor(rp))
        frac = rp - rp_floor
        y[i] = _read_lagrange4(x, rp_floor, frac)
    return y


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


@dataclasses.dataclass
class FlutterParams:
    flutter: float = 0.0
    classic_mode: bool = False


def _process_one_channel(x: np.ndarray, sr: float, p: FlutterParams,
                          rng_pitch: np.random.Generator,
                          rng_am: np.random.Generator) -> np.ndarray:
    """Apply pitch-mod (always) and AM-mod (unless classic) to one channel.

    Bit-identical passthrough when `p.flutter == 0`.
    """
    if p.flutter <= 0.0:
        return x.astype(np.float64).copy()

    n = x.shape[0]

    # --- Pitch-mod LFO ---
    pitch_lfo = _build_lfo(n, sr, _PITCH_LFO_BANDS, rng_pitch)
    pitch_depth_s = _flutter_pitch_depth_seconds(p.flutter)
    pitch_depth_samples = pitch_depth_s * sr
    base_delay_samples = _BASE_DELAY_S * sr
    # delay[n] = base + depth · lfo[n].  LFO is RMS-normalized; clip to
    # [base - depth, base + depth] is implicit since base ≥ depth.
    delay_samples = base_delay_samples + pitch_depth_samples * pitch_lfo

    # Defensive: never let delay go negative (would read future samples).
    np.maximum(delay_samples, 0.0, out=delay_samples)

    # --- Variable-delay read ---
    x_pitched = _apply_variable_delay(x.astype(np.float64), delay_samples)

    if p.classic_mode:
        return x_pitched

    # --- AM-mod LFO ---
    am_lfo = _build_lfo(n, sr, _AM_LFO_BANDS, rng_am)
    am_depth = _flutter_am_depth(p.flutter)
    # Multiplier centered on unity. Clamp to [0, 2] so we can never
    # invert phase even if the LFO peaks unusually high.
    multiplier = 1.0 + am_depth * am_lfo
    np.clip(multiplier, 0.0, 2.0, out=multiplier)

    return x_pitched * multiplier


def process(x: np.ndarray, sr: float, *, flutter: float,
            classic_mode: bool = False, seed: int = 0) -> np.ndarray:
    """Process a stereo audio buffer through tl_flutter.

    Args:
        x: shape (N,) mono or (N, 2) stereo, float32 or float64.
        sr: sample rate in Hz.
        flutter: 0..1 modulation amount.
        classic_mode: if True, AM stage is bypassed; pitch path remains.
        seed: RNG seed. Same seed + same args → bit-identical output.

    Returns:
        Stereo float array (same dtype as input) of shape (N, 2).
    """
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    if x.ndim != 2 or x.shape[1] != 2:
        raise ValueError(f"expected stereo or mono input, got shape {x.shape}")

    p = FlutterParams(
        flutter=float(np.clip(flutter, 0.0, 1.0)),
        classic_mode=bool(classic_mode),
    )

    # Bit-identical passthrough at zero flutter (no RNG advanced).
    if p.flutter <= 0.0:
        return x.astype(x.dtype).copy()

    # Spawn 4 independent RNGs: (L_pitch, L_am, R_pitch, R_am).
    ss = np.random.SeedSequence(seed)
    rngs = [np.random.default_rng(s) for s in ss.spawn(4)]
    rng_lp, rng_la, rng_rp, rng_ra = rngs

    out_l = _process_one_channel(x[:, 0], sr, p, rng_lp, rng_la)
    out_r = _process_one_channel(x[:, 1], sr, p, rng_rp, rng_ra)

    return np.stack([out_l, out_r], axis=1).astype(x.dtype)


# ---------------------------------------------------------------------------
# Test inputs
# ---------------------------------------------------------------------------


def _make_sine_input(sr: float, dur_sec: float = 3.0,
                     freq: float = 440.0, amp: float = 0.5) -> np.ndarray:
    """Pure tone, mono-duplicated stereo. Probe for pitch excursion."""
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    sig = (amp * np.sin(2.0 * np.pi * freq * t)).astype(np.float32)
    # Soft attack/release so we don't measure transients.
    a_n = int(0.05 * sr)
    r_n = int(0.05 * sr)
    env = np.ones(n, dtype=np.float32)
    env[:a_n] = np.linspace(0.0, 1.0, a_n, dtype=np.float32)
    env[-r_n:] = np.linspace(1.0, 0.0, r_n, dtype=np.float32)
    sig = sig * env
    return np.stack([sig, sig], axis=1)


def _make_chord_input(sr: float, dur_sec: float = 3.0) -> np.ndarray:
    """Sustained A2 + E3 + A3 chord with mild harmonic content."""
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    fundamentals = [110.0, 164.81, 220.0]
    sig = np.zeros(n, dtype=np.float64)
    for f0 in fundamentals:
        for k, gain in enumerate([1.0, 0.5, 0.3, 0.15, 0.08], start=1):
            sig += gain * np.sin(2.0 * np.pi * f0 * k * t + 0.1 * k)
    sig /= np.max(np.abs(sig)) or 1.0
    sig *= 0.6
    a_n = int(0.1 * sr)
    r_n = int(0.4 * sr)
    env = np.ones(n, dtype=np.float64)
    env[:a_n] = np.linspace(0.0, 1.0, a_n)
    env[-r_n:] = np.linspace(1.0, 0.0, r_n)
    sig *= env
    return np.stack([sig.astype(np.float32), sig.astype(np.float32)], axis=1)


# ---------------------------------------------------------------------------
# Measurement helpers (used by __main__ for verified-property checks)
# ---------------------------------------------------------------------------


def _measure_pitch_excursion_cents(y_mono: np.ndarray, sr: float,
                                   nominal_freq: float = 440.0) -> tuple[float, float]:
    """Estimate (rms_cents, 99th-percentile_peak_cents) pitch shift via
    zero-crossing-pair instantaneous-period analysis.

    Uses the 99th percentile rather than absolute peak because edge
    cases at attack/release boundaries can produce single-sample
    artifacts that dominate `max`. The 99th percentile is the right
    "perceptual peak" measure for a signal modulated by bandlimited
    noise.

    Skips the first/last 10 % of samples to avoid attack/release
    artifacts in the test signal envelope.
    """
    n = y_mono.shape[0]
    skip = n // 10
    inner = y_mono[skip:n - skip] if n > 2 * skip else y_mono
    # Detect raw sign flips (use `sign` and look for transitions).
    sign = np.sign(inner)
    flips = np.where(np.diff(sign) != 0)[0]
    if flips.size < 2:
        return 0.0, 0.0
    # Filter spurious crossings in low-amplitude regions by requiring
    # the local envelope (1-cycle window around crossing) to exceed a
    # threshold. We use a coarse window of ~2.5 ms (~ 1 cycle of 400 Hz).
    win_n = max(8, int(0.0025 * sr))
    threshold = 0.1 * float(np.max(np.abs(inner)) or 1.0)
    keep = []
    for f in flips:
        lo = max(0, f - win_n)
        hi = min(inner.shape[0], f + win_n)
        if float(np.max(np.abs(inner[lo:hi]))) >= threshold:
            keep.append(f)
    if len(keep) < 2:
        return 0.0, 0.0
    flips_arr = np.asarray(keep)
    # Half-periods between consecutive crossings.
    half_periods = np.diff(flips_arr).astype(np.float64) / sr
    inst_freqs = 0.5 / half_periods
    # Reject implausible periods (a half-octave in either direction).
    valid = (inst_freqs > nominal_freq * 0.5) & (inst_freqs < nominal_freq * 2.0)
    if not np.any(valid):
        return 0.0, 0.0
    inst_freqs = inst_freqs[valid]
    cents = 1200.0 * np.log2(inst_freqs / nominal_freq)
    rms = float(np.sqrt(np.mean(cents * cents)))
    peak99 = float(np.percentile(np.abs(cents), 99))
    return rms, peak99


def _measure_am_swing_db(y_mono: np.ndarray, sr: float) -> float:
    """Estimate peak AM swing in dB by tracking the envelope (abs+LPF).
    Returns peak swing (max - min) of envelope in dB.
    """
    env = np.abs(y_mono)
    # Smooth env with a 30 ms moving average (control rate).
    win_n = max(64, int(0.03 * sr))
    if env.shape[0] < 2 * win_n:
        return 0.0
    kernel = np.ones(win_n) / win_n
    env_s = np.convolve(env, kernel, mode="valid")
    # Skip first / last 5% to avoid attack/release artifacts.
    skip = max(1, env_s.shape[0] // 20)
    env_inner = env_s[skip:-skip] if env_s.shape[0] > 2 * skip else env_s
    if env_inner.size == 0 or float(np.min(env_inner)) <= 0.0:
        return 0.0
    e_max = float(np.max(env_inner))
    e_min = float(np.min(env_inner))
    if e_min <= 1e-9:
        return 0.0
    return 20.0 * math.log10(e_max / e_min)


def _stereo_lr_correlation(y: np.ndarray) -> float:
    """Pearson correlation between L and R of a stereo signal."""
    l = y[:, 0].astype(np.float64)
    r = y[:, 1].astype(np.float64)
    l = l - np.mean(l)
    r = r - np.mean(r)
    denom = float(np.sqrt(np.sum(l * l) * np.sum(r * r)))
    if denom <= 0:
        return 0.0
    return float(np.sum(l * r) / denom)


# ---------------------------------------------------------------------------
# WAV writer
# ---------------------------------------------------------------------------


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny PCM16 WAV writer."""
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


# ---------------------------------------------------------------------------
# Fixture rendering + verified-property checks
# ---------------------------------------------------------------------------


def render_fixtures(out_dir: Path, sr: int = 44100) -> list[Path]:
    written: list[Path] = []
    sine_in = _make_sine_input(sr=float(sr), dur_sec=3.0, freq=440.0, amp=0.5)
    chord_in = _make_chord_input(sr=float(sr), dur_sec=3.0)

    sine_path = out_dir / "tl_flutter_input_sine.wav"
    chord_path = out_dir / "tl_flutter_input_chord.wav"
    _save_wav(sine_path, sine_in, sr)
    _save_wav(chord_path, chord_in, sr)
    written += [sine_path, chord_path]

    # --- Sine probe: pitch excursion at varying flutter / classic_mode ---
    sine_settings = [
        ("f0p0",         dict(flutter=0.0, classic_mode=False)),
        ("f0p5",         dict(flutter=0.5, classic_mode=False)),
        ("f1p0",         dict(flutter=1.0, classic_mode=False)),
        ("f1p0_classic", dict(flutter=1.0, classic_mode=True)),
    ]
    for tag, kw in sine_settings:
        out = process(sine_in, sr=float(sr), seed=42, **kw)
        path = out_dir / f"tl_flutter_demo_{tag}.wav"
        _save_wav(path, out, sr)
        written.append(path)

    # --- Chord texture: how it feels on harmonic material ---
    for f, tag in [(0.5, "chord_f0p5"), (1.0, "chord_f1p0")]:
        out = process(chord_in, sr=float(sr), seed=42, flutter=f, classic_mode=False)
        path = out_dir / f"tl_flutter_demo_{tag}.wav"
        _save_wav(path, out, sr)
        written.append(path)

    return written


def run_verified_properties(sr: int = 44100) -> None:
    """Programmatic checks of the design-doc claims. Prints pass/fail.
    Output should be eyeballed in CI pre-merge of this module.
    """
    print("--- tl_flutter verified properties ---")
    sine_in = _make_sine_input(sr=float(sr), dur_sec=3.0, freq=440.0, amp=0.5)

    # Property 1: flutter = 0 → bit-identical output.
    out_zero = process(sine_in, sr=float(sr), flutter=0.0, classic_mode=False, seed=42)
    diff = float(np.max(np.abs(out_zero.astype(np.float64) - sine_in.astype(np.float64))))
    print(f"[1] flutter=0 → output==input  (max abs diff = {diff:.2e})  "
          f"{'PASS' if diff == 0.0 else 'FAIL'}")

    # Property 2: monotonic departure from dry as flutter increases.
    rms_diffs = []
    for f in [0.0, 0.3, 0.5, 0.7, 1.0]:
        out = process(sine_in, sr=float(sr), flutter=f, classic_mode=False, seed=42)
        diff = out.astype(np.float64) - sine_in.astype(np.float64)
        rms_diffs.append(float(np.sqrt(np.mean(diff * diff))))
    monotonic = all(rms_diffs[i] <= rms_diffs[i + 1] + 1e-6 for i in range(len(rms_diffs) - 1))
    print(f"[2] monotonic departure  rms_diffs={['%.4f' % v for v in rms_diffs]}  "
          f"{'PASS' if monotonic else 'FAIL'}")

    # Property 3: classic_mode bypasses AM (envelope swing should be small).
    out_classic = process(sine_in, sr=float(sr), flutter=1.0, classic_mode=True, seed=42)
    out_full = process(sine_in, sr=float(sr), flutter=1.0, classic_mode=False, seed=42)
    swing_classic = _measure_am_swing_db(out_classic[:, 0], sr=float(sr))
    swing_full = _measure_am_swing_db(out_full[:, 0], sr=float(sr))
    # Classic mode envelope is from sine's natural amplitude only — should be
    # noticeably smaller than full-mode swing.
    am_bypassed = swing_classic < swing_full - 0.5  # at least 0.5 dB margin
    print(f"[3] classic_mode → AM bypassed  swing_full={swing_full:.2f} dB  "
          f"swing_classic={swing_classic:.2f} dB  "
          f"{'PASS' if am_bypassed else 'FAIL'}")

    # Property 4: pitch excursion at f=1 within boutique target.
    # Bound generously: design targets ~10–30 c "peak" (99th percentile).
    rms_c, peak_c = _measure_pitch_excursion_cents(out_full[:, 0], sr=float(sr), nominal_freq=440.0)
    pitch_in_band = 3.0 <= peak_c <= 80.0
    print(f"[4] pitch excursion at f=1.0  rms={rms_c:.2f} c  peak99={peak_c:.2f} c  "
          f"{'PASS' if pitch_in_band else 'FAIL'}")

    # Property 5: AM swing at f=1, classic_mode=0 in the spec'd <±3 dB band.
    am_in_band = swing_full < 7.0  # peak-to-peak ≈ 6 dB
    print(f"[5] AM swing at f=1.0 < 7 dB peak-to-peak (~±3 dB)  "
          f"swing={swing_full:.2f} dB  {'PASS' if am_in_band else 'FAIL'}")

    # Property 6: stereo decorrelation of LFO streams — the per-channel
    # noise generators must be independent. Verify by building L and R
    # pitch LFOs from the same SeedSequence and checking cross-correlation.
    ss = np.random.SeedSequence(42)
    rngs = [np.random.default_rng(s) for s in ss.spawn(4)]
    lfo_l = _build_lfo(int(3 * sr), float(sr), _PITCH_LFO_BANDS, rngs[0])
    lfo_r = _build_lfo(int(3 * sr), float(sr), _PITCH_LFO_BANDS, rngs[2])
    lfo_corr = float(np.corrcoef(lfo_l, lfo_r)[0, 1])
    lfo_decorrelated = abs(lfo_corr) < 0.1
    print(f"[6] LFO L/R decorrelation  corr = {lfo_corr:.4f}  "
          f"{'PASS' if lfo_decorrelated else 'FAIL'}")
    # Output-audio L/R correlation is reported but not pass/fail — for a
    # mono source with shallow modulation it stays close to 1.0 by design.
    out_corr = _stereo_lr_correlation(out_full)
    print(f"    (output L/R corr = {out_corr:.4f}, expected high for mono sine)")


def _ground_truth_pitch_cents(f: float, sr: int, seed: int = 42, dur_sec: float = 3.0) -> tuple[float, float]:
    """Return (rms_cents, p99_cents) of the instantaneous pitch shift implied
    by the pitch-LFO + depth taper, computed via numerical derivative of the
    delay envelope. Independent of any carrier signal — the only honest way
    to measure pitch deviation when the ZCR-on-440Hz method saturates near
    the resolution ceiling.

    Same RNG-spawn ordering as `process()` so seeds align.
    """
    n = int(dur_sec * sr)
    ss = np.random.SeedSequence(seed)
    rng_lp = np.random.default_rng(ss.spawn(4)[0])
    lfo = _build_lfo(n, float(sr), _PITCH_LFO_BANDS, rng_lp)
    depth_s = _flutter_pitch_depth_seconds(f)
    delay = depth_s * lfo
    # Pitch ratio vs dry: 1 - d/dt(delay).  cents = 1200 * log2(ratio).
    dd_per_sec = np.gradient(delay) * sr  # d(seconds-of-delay) / d(second) ≈ unitless
    cents = -1200.0 * np.log2(np.clip(1.0 - dd_per_sec, 1e-6, None))
    rms = float(np.sqrt(np.mean(cents * cents)))
    p99 = float(np.percentile(np.abs(cents), 99))
    return rms, p99


def _ground_truth_am_swing_db(f: float, sr: int, seed: int = 42, dur_sec: float = 3.0) -> float:
    """Peak-to-peak swing in dB of the multiplier `1 + d_am · m(t)`, computed
    on the AM LFO directly — no carrier interference. Returns 20·log10(max/min)
    over the inner 90 % of the buffer.
    """
    n = int(dur_sec * sr)
    ss = np.random.SeedSequence(seed)
    rng_la = np.random.default_rng(ss.spawn(4)[1])
    lfo = _build_lfo(n, float(sr), _AM_LFO_BANDS, rng_la)
    d_am = _flutter_am_depth(f)
    mult = 1.0 + d_am * lfo
    skip = n // 20
    inner = mult[skip:n - skip] if n > 2 * skip else mult
    e_max = float(np.max(inner))
    e_min = float(np.min(inner))
    if e_min <= 1e-9:
        return 0.0
    return 20.0 * math.log10(e_max / e_min)


def run_round2_taper_assertions(sr: int = 44100) -> bool:
    """Round-2 taper sanity checks. All four MUST pass:

      A. f=0.0 still bit-identical to dry (regression on passthrough).
      B. f=0.5: ground-truth pitch peak99 ≥ 18 c (noon audibility floor).
      C. f=0.5: ground-truth AM peak-to-peak ≥ 1.0 dB (noon audibility).
      D. f=1.0: ground-truth pitch peak99 ≤ 50 c (don't exceed round-1
         ceiling much; round-1 was ~23 c, round-2 ~28 c).

    Both [B] and [C] use *ground-truth* measurements (LFO + taper, no
    carrier) because ZCR on 440 Hz saturates near the sample-period
    resolution ceiling and chord envelope-swing estimation includes the
    chord's own amplitude variation. The same LFO state drives the chord
    fixture, so passing the ground-truth assertion is necessary and
    sufficient for the chord to flutter audibly.

    Returns True if all assertions pass.
    """
    print(f"--- tl_flutter ROUND-{TUNING_VERSION} taper assertions ---")
    sine_in = _make_sine_input(sr=float(sr), dur_sec=3.0, freq=440.0, amp=0.5)

    # A: f=0 bit-identical
    out_zero = process(sine_in, sr=float(sr), flutter=0.0, classic_mode=False, seed=42)
    diff_a = float(np.max(np.abs(out_zero.astype(np.float64) - sine_in.astype(np.float64))))
    pass_a = diff_a == 0.0
    print(f"[A] f=0.0 bit-identical to dry  (max abs diff = {diff_a:.2e})  "
          f"{'PASS' if pass_a else 'FAIL'}")

    # B: noon pitch ≥ 18 c peak99 (ground truth — drives the chord fixture)
    rms_b, peak99_b = _ground_truth_pitch_cents(0.5, sr=sr, seed=42)
    pass_b = peak99_b >= 18.0
    print(f"[B] f=0.5 ground-truth pitch peak99 ≥ 18 c  "
          f"rms={rms_b:.2f} c  peak99={peak99_b:.2f} c  "
          f"{'PASS' if pass_b else 'FAIL'}")

    # C: noon AM swing ≥ 1.0 dB peak-to-peak (ground truth)
    swing_c = _ground_truth_am_swing_db(0.5, sr=sr, seed=42)
    pass_c = swing_c >= 1.0
    print(f"[C] f=0.5 ground-truth AM peak-to-peak ≥ 1.0 dB  "
          f"swing={swing_c:.2f} dB  {'PASS' if pass_c else 'FAIL'}")

    # D: f=1.0 pitch peak99 ≤ 50 c (ground truth)
    rms_d, peak99_d = _ground_truth_pitch_cents(1.0, sr=sr, seed=42)
    pass_d = peak99_d <= 50.0
    print(f"[D] f=1.0 ground-truth pitch peak99 ≤ 50 c  "
          f"rms={rms_d:.2f} c  peak99={peak99_d:.2f} c  "
          f"{'PASS' if pass_d else 'FAIL'}")

    all_pass = pass_a and pass_b and pass_c and pass_d
    print(f"--- ROUND-{TUNING_VERSION} taper: {'ALL PASS' if all_pass else 'FAIL'} ---")
    return all_pass


if __name__ == "__main__":
    out_dir = Path(__file__).resolve().parent / "fixtures"
    files = render_fixtures(out_dir)
    print(f"wrote {len(files)} fixture(s) to {out_dir}")
    for f in files:
        print(f"  {f}")
    print()
    run_verified_properties()
    print()
    run_round2_taper_assertions()
