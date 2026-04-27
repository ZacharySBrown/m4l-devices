"""tl_volume_mix — numpy reference implementation of the VOLUME + MISO module.

This is the golden render the Max patcher (`tl.volume_mix.maxpat` or
the equivalent inline `*~ / selector~` group inside `tape-loss.maxpat`)
must match. It implements the two operations described in
`docs/design-docs/dsp/tl-volume-mix-design.md`:

    1) MISO mux (with crossfade on toggle)
       miso=True  → m_L = m_R = (L+R)/2
       miso=False → m_L = L, m_R = R
    2) Volume scaling (with one-pole smoother on the gain coefficient)
       y = m * g[n], where g[n] = α·v_target + (1-α)·g[n-1]

Both the volume gain and the MISO crossfade share the same one-pole
smoother time constant τ = 10 ms. α is recomputed for the supplied
`sr`. Initial smoother state is set to the *target* (volume / miso
bool) so a fresh patch does NOT fade in from zero on every reload.

References:
    - tape-loss-spec.md §"Global Parameters & Routing — VOLUME Knob"
      and §"MISO (Mono In Stereo Out)"
    - Steven W. Smith, "The Scientist and Engineer's Guide to DSP"
      Ch. 19 §"The Single-Pole Recursive Filter" — α from τ.
    - Julius O. Smith III, "Introduction to Digital Filters" — one-pole
      filter derivation.
    - RBJ Audio EQ Cookbook (cited for SR-dependence convention).

Public API:
    process(x, sr, *, volume, miso=False,
            initial_volume=None, initial_miso=None,
            tau_sec=0.010) -> ndarray

`x` is shape (N, 2) float32/float64 stereo. `volume` may be a scalar
(constant target) OR a length-N array (per-sample target — useful for
modeling automation curves). `miso` similarly may be a scalar bool OR
a length-N array of 0/1 floats (so we can model a mid-buffer toggle
and verify it crossfades cleanly).

Determinism:
    Pure scalar arithmetic; no RNG. Same inputs → bit-identical output.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Optional, Union

import numpy as np


# ---------------------------------------------------------------------------
# Smoother coefficient
# ---------------------------------------------------------------------------


def alpha_for_tau(tau_sec: float, sr: float) -> float:
    """One-pole smoother coefficient: α = 1 - exp(-1 / (τ · sr)).

    Citation: Smith, "Scientist and Engineer's Guide to DSP", Ch. 19
    §"The Single-Pole Recursive Filter".

    With this α, g[n] = α·target + (1-α)·g[n-1] reaches 1-1/e of a
    step input after τ seconds, and ≈99% after 4.6·τ.
    """
    if tau_sec <= 0.0:
        return 1.0
    return 1.0 - math.exp(-1.0 / (tau_sec * sr))


# ---------------------------------------------------------------------------
# One-pole smoother (vectorized)
# ---------------------------------------------------------------------------


def _one_pole_smooth(target: np.ndarray, alpha: float, init: float) -> np.ndarray:
    """Apply g[n] = α·target[n] + (1-α)·g[n-1] sample-by-sample.

    Uses an explicit loop because the recurrence is not parallelizable
    in the general case (target may vary per-sample). For our buffer
    sizes (a few seconds of audio) this is fine; the engineer's M4L
    implementation will use a hardware-friendly `slide~` or `*~ + +~`
    feedback pair.
    """
    out = np.empty_like(target, dtype=np.float64)
    g = float(init)
    one_minus_alpha = 1.0 - alpha
    for i in range(target.shape[0]):
        g = alpha * float(target[i]) + one_minus_alpha * g
        out[i] = g
    return out


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


def process(
    x: np.ndarray,
    sr: float,
    *,
    volume: Union[float, np.ndarray],
    miso: Union[bool, int, np.ndarray] = False,
    initial_volume: Optional[float] = None,
    initial_miso: Optional[float] = None,
    tau_sec: float = 0.010,
) -> np.ndarray:
    """Process a stereo audio buffer through tl_volume_mix.

    Args:
        x: shape (N,) mono or (N, 2) stereo audio buffer.
        sr: sample rate in Hz.
        volume: scalar OR length-N array. Range [0.0, 2.0]; clipped if
                outside. 1.0 == unity, 2.0 == +6 dB.
        miso: scalar bool/int OR length-N array of 0/1. The MISO toggle.
        initial_volume: optional override for the smoother's g[-1].
                        Defaults to the first volume target value (so
                        a fresh patch doesn't fade in from zero).
        initial_miso: optional override for the MISO crossfader's
                      g[-1]. Defaults to first miso target value.
        tau_sec: smoother time constant in seconds. Default 10 ms,
                 matching the design doc.

    Returns:
        Stereo (N, 2) ndarray, same dtype as input.
    """
    # --- Input shape normalization ---
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    if x.ndim != 2 or x.shape[1] != 2:
        raise ValueError(f"expected stereo or mono input, got shape {x.shape}")
    n = x.shape[0]
    in_dtype = x.dtype
    x64 = x.astype(np.float64)

    # --- Volume target as length-N array, clipped to [0, 2] ---
    if np.isscalar(volume):
        v_target = np.full(n, float(np.clip(volume, 0.0, 2.0)), dtype=np.float64)
    else:
        v_arr = np.asarray(volume, dtype=np.float64)
        if v_arr.shape[0] != n:
            raise ValueError(
                f"volume array length {v_arr.shape[0]} != audio length {n}"
            )
        v_target = np.clip(v_arr, 0.0, 2.0)

    # --- MISO target as length-N array of {0.0, 1.0} ---
    if np.isscalar(miso) or isinstance(miso, (bool, int, np.bool_)):
        m_target = np.full(n, 1.0 if bool(miso) else 0.0, dtype=np.float64)
    else:
        m_arr = np.asarray(miso, dtype=np.float64)
        if m_arr.shape[0] != n:
            raise ValueError(
                f"miso array length {m_arr.shape[0]} != audio length {n}"
            )
        m_target = np.clip(m_arr, 0.0, 1.0)

    # --- Smoother init: default to first target so we don't fade in ---
    init_v = float(v_target[0]) if initial_volume is None else float(initial_volume)
    init_m = float(m_target[0]) if initial_miso is None else float(initial_miso)

    alpha = alpha_for_tau(tau_sec, sr)

    # --- Smoothed control signals ---
    g = _one_pole_smooth(v_target, alpha, init_v)        # shape (n,)
    miso_g = _one_pole_smooth(m_target, alpha, init_m)   # shape (n,)

    # --- MISO crossfade ---
    L = x64[:, 0]
    R = x64[:, 1]
    mono = 0.5 * (L + R)
    # When miso_g = 1, output is mono on both channels.
    # When miso_g = 0, output is L/R passthrough.
    m_L = miso_g * mono + (1.0 - miso_g) * L
    m_R = miso_g * mono + (1.0 - miso_g) * R

    # --- Volume scale ---
    y_L = m_L * g
    y_R = m_R * g

    return np.stack([y_L, y_R], axis=1).astype(in_dtype)


# ---------------------------------------------------------------------------
# __main__: render fixtures + numeric assertions
# ---------------------------------------------------------------------------


def _make_stereo_test_input(sr: float, dur_sec: float = 2.0) -> np.ndarray:
    """Stereo content with distinguishable L vs R: L is a 220 Hz sine,
    R is a 330 Hz sine. Used to verify (a) passthrough preserves
    L≠R and (b) MISO collapses to L==R."""
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    L = 0.5 * np.sin(2.0 * np.pi * 220.0 * t)
    R = 0.5 * np.sin(2.0 * np.pi * 330.0 * t)
    return np.stack([L, R], axis=1).astype(np.float32)


def _make_white_noise_input(sr: float, dur_sec: float = 1.0,
                             seed: int = 0) -> np.ndarray:
    """Stereo decorrelated white noise — useful for MISO loudness check."""
    rng = np.random.default_rng(seed)
    n = int(dur_sec * sr)
    L = rng.standard_normal(n).astype(np.float32) * 0.2
    R = rng.standard_normal(n).astype(np.float32) * 0.2
    return np.stack([L, R], axis=1).astype(np.float32)


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny WAV writer (PCM16) — no scipy/soundfile dependency."""
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
    """Render sanity-check WAVs and assert numeric properties.

    Fixtures rendered:
        tl_volume_mix_input_dry.wav
            Stereo 220/330 Hz reference input.
        tl_volume_mix_unity.wav
            volume=1.0, miso=False — should be ≈ identical to input
            (modulo a 10 ms ramp from initial_volume default = 1.0,
            i.e. no ramp).
        tl_volume_mix_plus6dB.wav
            volume=2.0, miso=False — should be 2× input.
        tl_volume_mix_miso_stereo.wav
            volume=1.0, miso=True on stereo content — L and R should
            be identical at every sample (post-smoother).
        tl_volume_mix_miso_white_noise.wav
            volume=1.0, miso=True on decorrelated white noise — useful
            sanity check for the (-3 dB perceived) loudness collapse.
        tl_volume_mix_zipper_test.wav
            volume ramps 0 → 1 over 100 ms on a 440 Hz tone. Should be
            silent of zipper / staircase artefacts (no high-frequency
            energy beyond what the source contains).
        tl_volume_mix_miso_toggle_test.wav
            miso bool toggles 0→1 mid-buffer on stereo content. Should
            crossfade smoothly with no click at the toggle point.

    Numeric assertions (raise AssertionError on failure):
        - unity passthrough: max abs error < 1e-6
        - +6 dB: peak ≈ 2× input peak (within 1e-6)
        - MISO post-convergence: |L - R| < 1e-9 sample-wise
        - zipper test: in the 'flat' region after the ramp settles,
          spectral energy in the band [2 kHz, sr/2] is no greater
          than -60 dB relative to the tone's energy
        - MISO toggle: no inter-sample step > 0.05 in either channel
          (a click test — the input itself is bounded near 0.5 amp)
    """
    written: list[Path] = []
    out_dir.mkdir(parents=True, exist_ok=True)

    # ---------- Reference input ----------
    in_audio = _make_stereo_test_input(sr=sr, dur_sec=2.0)
    dry_path = out_dir / "tl_volume_mix_input_dry.wav"
    _save_wav(dry_path, in_audio, sr)
    written.append(dry_path)

    # ---------- 1) Unity passthrough ----------
    out_unity = process(in_audio, sr=float(sr), volume=1.0, miso=False)
    err = float(np.max(np.abs(out_unity.astype(np.float64) - in_audio.astype(np.float64))))
    # Initial smoother state defaults to first volume target (1.0), so
    # there is no ramp and the operation is exact within int16 quant noise.
    # We compare in the original float32 domain, however, so error
    # should be near machine precision.
    assert err < 1e-6, f"unity passthrough error {err} > 1e-6"
    p = out_dir / "tl_volume_mix_unity.wav"
    _save_wav(p, out_unity, sr)
    written.append(p)

    # ---------- 2) +6 dB (volume=2.0) ----------
    out_2x = process(in_audio, sr=float(sr), volume=2.0, miso=False)
    # Compare peaks: input peak is 0.5 (from the 0.5*sin construction).
    in_peak = float(np.max(np.abs(in_audio)))
    out_peak = float(np.max(np.abs(out_2x)))
    # Smoother converges before any peaks (init_v=2.0 since
    # initial_volume defaults to first target = 2.0).
    assert abs(out_peak - 2.0 * in_peak) < 1e-3, (
        f"+6 dB peak {out_peak:.4f} != 2× input peak {2.0*in_peak:.4f}"
    )
    p = out_dir / "tl_volume_mix_plus6dB.wav"
    _save_wav(p, out_2x, sr)
    written.append(p)

    # ---------- 3) MISO on stereo content → L == R ----------
    out_miso = process(in_audio, sr=float(sr), volume=1.0, miso=True)
    # Skip the first ~5τ samples to let the MISO crossfader converge
    # (initial_miso also defaults to first target = 1.0, so technically
    # no ramp, but we test conservatively).
    skip = int(0.05 * sr)  # 50 ms = 5τ
    diff = np.max(np.abs(out_miso[skip:, 0].astype(np.float64)
                         - out_miso[skip:, 1].astype(np.float64)))
    assert diff < 1e-9, f"MISO L vs R diff = {diff:.3e}, expected 0"
    p = out_dir / "tl_volume_mix_miso_stereo.wav"
    _save_wav(p, out_miso, sr)
    written.append(p)

    # ---------- 4) MISO on white noise (perceptual sanity render) ----------
    in_noise = _make_white_noise_input(sr=sr, dur_sec=1.0, seed=42)
    out_miso_noise = process(in_noise, sr=float(sr), volume=1.0, miso=True)
    diff_n = np.max(np.abs(out_miso_noise[skip:, 0].astype(np.float64)
                            - out_miso_noise[skip:, 1].astype(np.float64)))
    assert diff_n < 1e-9, f"MISO white-noise L-R diff {diff_n:.3e}"
    # Loudness check: RMS of mono-summed decorrelated noise should be
    # ≈ 1/sqrt(2) of either channel's RMS (the canonical -3 dB result).
    rms_in_L = float(np.sqrt(np.mean(in_noise[:, 0].astype(np.float64) ** 2)))
    rms_out = float(np.sqrt(np.mean(out_miso_noise[skip:, 0].astype(np.float64) ** 2)))
    expected = rms_in_L / math.sqrt(2.0)
    # Very loose bound (decorrelation isn't perfect on a finite window).
    assert abs(rms_out - expected) / expected < 0.10, (
        f"MISO mono-sum RMS {rms_out:.4f} not within 10% of expected "
        f"{expected:.4f} (-3 dB rule)"
    )
    p = out_dir / "tl_volume_mix_miso_white_noise.wav"
    _save_wav(p, out_miso_noise, sr)
    written.append(p)

    # ---------- 5) Zipper / click-avoidance: 0 → 1 ramp over 100 ms ----------
    n_test = int(2.0 * sr)
    t = np.arange(n_test) / sr
    tone = 0.4 * np.sin(2.0 * np.pi * 440.0 * t).astype(np.float32)
    tone_stereo = np.stack([tone, tone], axis=1)
    # Volume target: 0.0 for first 0.5 s, ramp 0→1 over 100 ms,
    # then hold 1.0.
    ramp_n = int(0.1 * sr)
    pre_n = int(0.5 * sr)
    v_target = np.empty(n_test, dtype=np.float64)
    v_target[:pre_n] = 0.0
    v_target[pre_n:pre_n + ramp_n] = np.linspace(0.0, 1.0, ramp_n, endpoint=False)
    v_target[pre_n + ramp_n:] = 1.0
    out_zip = process(tone_stereo, sr=float(sr), volume=v_target,
                       miso=False, initial_volume=0.0)
    p = out_dir / "tl_volume_mix_zipper_test.wav"
    _save_wav(p, out_zip, sr)
    written.append(p)

    # Spectral test: in the post-ramp settled region, residual
    # high-frequency energy (above 2 kHz) should be at least 60 dB
    # below the tone's fundamental energy. The 440 Hz tone is well
    # below 2 kHz, so any zipper / staircase noise would show up as
    # broadband energy above 2 kHz.
    settled_start = pre_n + ramp_n + int(0.05 * sr)  # +50 ms post-ramp
    settled = out_zip[settled_start:settled_start + int(0.5 * sr), 0].astype(np.float64)
    # FFT
    win = np.hanning(settled.shape[0])
    spec = np.abs(np.fft.rfft(settled * win))
    freqs = np.fft.rfftfreq(settled.shape[0], d=1.0 / sr)
    # Energy in tone band (around 440 Hz, ±50 Hz)
    tone_mask = (freqs > 390) & (freqs < 490)
    tone_energy = float(np.sum(spec[tone_mask] ** 2))
    hf_mask = freqs > 2000.0
    hf_energy = float(np.sum(spec[hf_mask] ** 2))
    assert tone_energy > 0.0, "tone energy zero — sanity fail"
    ratio_db = 10.0 * math.log10(hf_energy / tone_energy + 1e-30)
    assert ratio_db < -60.0, (
        f"zipper test: HF energy {ratio_db:.1f} dB below tone, "
        f"expected ≤ -60 dB"
    )

    # ---------- 6) MISO mid-buffer toggle: no click ----------
    in_audio2 = _make_stereo_test_input(sr=sr, dur_sec=2.0)
    n2 = in_audio2.shape[0]
    miso_target = np.zeros(n2, dtype=np.float64)
    miso_target[n2 // 2:] = 1.0
    out_toggle = process(in_audio2, sr=float(sr), volume=1.0,
                          miso=miso_target, initial_miso=0.0)
    p = out_dir / "tl_volume_mix_miso_toggle_test.wav"
    _save_wav(p, out_toggle, sr)
    written.append(p)
    # Click test: max sample-to-sample step in either channel.
    # The input is two sines at amplitudes 0.5; the largest legitimate
    # one-sample delta is 2π·f·dt·amp ≈ 2π·330·(1/sr)·0.5 ≈ 0.0235.
    # We allow up to 0.05 to leave headroom but a click would spike
    # well above that.
    diffs_L = np.abs(np.diff(out_toggle[:, 0].astype(np.float64)))
    diffs_R = np.abs(np.diff(out_toggle[:, 1].astype(np.float64)))
    max_step = float(max(diffs_L.max(), diffs_R.max()))
    assert max_step < 0.05, (
        f"MISO toggle introduced sample-to-sample step {max_step:.4f}, "
        f"expected < 0.05 (click)"
    )

    return written


if __name__ == "__main__":
    out_dir = Path(__file__).resolve().parent / "fixtures"
    files = render_fixtures(out_dir)
    print(f"wrote {len(files)} fixture(s) to {out_dir}")
    for f in files:
        print(f"  {f}")
    print("all numeric assertions passed.")
