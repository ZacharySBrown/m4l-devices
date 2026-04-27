"""tl_aux — numpy reference implementation of the AUX footswitch module.

This is the golden render the Max patcher (`tl.aux.maxpat`) must
match. It implements the three AUX modes from tape-loss-spec.md
Module 7:

    A) STOP    — tape-stop simulation via a circular delay buffer with
                 a decelerating fractional read head. Pitch slides
                 from 1.0× to 0×; output gain fades to silence.
    B) FILTER  — sweeping low-pass filter (TPT-SVF after Simper /
                 Zavalishin). Cutoff sweeps 18 kHz → 200 Hz with
                 mild resonance increase.
    C) FAIL    — emits a sidechain "failure_override" control signal
                 that downstream `tl_failure` reads. Audio is
                 passthrough.

All three modes share an exponential one-pole onset envelope `e[n]`
driven by `aux_active` (0/1) and `aux_onset_ms` (10–3000 ms).

References:
    - Chase Bliss Generation Loss MKII manual (behavioral spec)
    - tape-loss-spec.md §"MODULE 7: tl.aux.maxpat"
    - Andrew Simper, "Linear Trapezoidal Integrated State Variable
      Filter", Cytomic 2014:
      https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf
    - Vadim Zavalishin, "The Art of VA Filter Design", §3.10
    - Julius O. Smith III, "Physical Audio Signal Processing",
      "Wow and Flutter Modeling" chapter — informs STOP curve.
    - Julius O. Smith III, "Introduction to Digital Filters with
      Audio Applications" — exponential-envelope math.

LOCAL-ONLY note:
    The STOP mode requires a stateful audio-buffer with a
    fractional-read decelerator. This is only fully verifiable in
    Max IDE (buffer init timing, tapout~ interp quality). The numpy
    reference is byte-deterministic given fixed inputs, but the M4L
    patch's audio quality on the read interp must be confirmed by ear.

Public API:
    process(x, sr, *, aux_mode, aux_active, aux_onset_ms,
            failure_knob=0.0) -> dict

Returns a dict:
    {"audio": (N, 2) float, "failure_override": (N,) float}
The failure_override is meaningful only in FAIL mode; otherwise zeros.
`aux_active` may be a scalar (constant) or an (N,) array (per-sample
press timeline) — the test harness uses the array form.
"""

from __future__ import annotations

import dataclasses
import math
from pathlib import Path
from typing import Optional, Union

import numpy as np


# ---------------------------------------------------------------------------
# Mode constants — match the live.tab indices in the spec
# ---------------------------------------------------------------------------

MODE_STOP = 0
MODE_FILTER = 1
MODE_FAIL = 2

_MODE_NAMES = {MODE_STOP: "STOP", MODE_FILTER: "FILTER", MODE_FAIL: "FAIL"}


# ---------------------------------------------------------------------------
# Onset envelope — exponential one-pole smoother
# ---------------------------------------------------------------------------
#
# α  = 1 - exp(-1 / (aux_onset_ms · sr / 1000))
# e[n] = α · target + (1 - α) · e[n-1]
#
# Standard envelope follower from Smith DSP Guide Ch. 19; JOS Filters
# §"Time-Constant Filter".


def _onset_alpha(onset_ms: float, sr: float) -> float:
    """Per-sample smoothing coefficient for the onset envelope."""
    onset_samples = max(1.0, onset_ms * 1e-3 * sr)
    return 1.0 - math.exp(-1.0 / onset_samples)


def _build_envelope(active: np.ndarray, onset_ms: float, sr: float,
                    e0: float = 0.0) -> np.ndarray:
    """Build the per-sample onset envelope `e[n]` ∈ [0, 1].

    Args:
        active: shape (N,), 0/1 — the per-sample aux_active state.
        onset_ms: ramp time constant.
        sr: sample rate.
        e0: initial envelope value (for stateful processing).

    Returns:
        envelope: shape (N,), float in [0, 1].
    """
    n = active.shape[0]
    alpha = _onset_alpha(onset_ms, sr)
    env = np.zeros(n, dtype=np.float64)
    e = float(e0)
    for i in range(n):
        target = float(active[i])
        e = alpha * target + (1.0 - alpha) * e
        env[i] = e
    return env


# ---------------------------------------------------------------------------
# Mode A: STOP — decelerating circular delay-buffer read
# ---------------------------------------------------------------------------


def _process_stop(x: np.ndarray, env: np.ndarray, sr: float,
                  *, gamma: float = 2.5,
                  buffer_seconds: float = 5.46) -> np.ndarray:
    """Apply tape-stop deceleration to a single mono channel.

    Args:
        x: shape (N,), float input.
        env: shape (N,), onset envelope ∈ [0, 1].
        sr: sample rate.
        gamma: deceleration curve exponent (spec: 2.5).
        buffer_seconds: circular buffer length headroom.

    Returns:
        y: shape (N,), float output.
    """
    n = x.shape[0]
    buf_n = int(2 ** math.ceil(math.log2(max(2.0, buffer_seconds * sr))))
    buf = np.zeros(buf_n, dtype=np.float64)
    y = np.zeros(n, dtype=np.float64)

    write_head = 0  # integer
    read_head = 0.0  # fractional samples (offset behind write_head)
    # We track read_head as the *delay* in samples behind the writer.
    # When env=0, read_head ≡ 0 (read = current write — pass-through w/ 1-sample latency).
    # When env=1, read_rate=0, so read_head grows by 1 per output sample
    # (the read freezes while writer keeps moving).

    for i in range(n):
        # Write current input at write_head
        buf[write_head] = x[i]

        e_i = env[i]
        # Read rate: 1.0 - read_head_growth_rate. read_head_growth = 1 - rate.
        rate = (1.0 - e_i) ** gamma
        rate = max(0.0, min(1.0, rate))

        # Compute read position: write_head - read_head, with fractional interp.
        read_pos = (write_head - read_head) % buf_n
        rp_floor = int(math.floor(read_pos))
        frac = read_pos - rp_floor
        a = buf[rp_floor]
        b = buf[(rp_floor + 1) % buf_n]
        sample = a + frac * (b - a)

        # Output gain: √(1 - e) — fades to silence cleanly.
        gain = math.sqrt(max(0.0, 1.0 - e_i))
        y[i] = sample * gain

        # Advance heads: writer moves by 1, read_head delay grows by (1 - rate).
        write_head = (write_head + 1) % buf_n
        read_head += (1.0 - rate)
        # Clamp to buffer length (defensive — should never trigger in normal use)
        if read_head >= buf_n - 256:
            read_head = float(buf_n - 256)
    return y


# ---------------------------------------------------------------------------
# Mode B: FILTER — TPT-SVF (trapezoidal-integrated state-variable filter)
# ---------------------------------------------------------------------------
#
# Reference: Andrew Simper, "Linear Trapezoidal Integrated State
# Variable Filter", Cytomic 2014.
# Per-sample form below.


def _svf_step(x: float, fc: float, q: float, sr: float,
              state: list) -> float:
    """One-sample step of the TPT-SVF, returning the low-pass output.

    Args:
        x: input sample.
        fc: cutoff in Hz.
        q: quality factor (Q).
        sr: sample rate.
        state: [ic1eq, ic2eq] — mutated in place.

    Returns:
        y_lpf: low-pass output sample.
    """
    fc_clamped = max(20.0, min(fc, 0.45 * sr))
    q_clamped = max(0.5, min(q, 10.0))
    g = math.tan(math.pi * fc_clamped / sr)
    k = 1.0 / q_clamped
    a1 = 1.0 / (1.0 + g * (g + k))
    a2 = g * a1
    a3 = g * a2

    ic1eq, ic2eq = state[0], state[1]
    v3 = x - ic2eq
    v1 = a1 * ic1eq + a2 * v3
    v2 = ic2eq + a2 * ic1eq + a3 * v3
    state[0] = 2.0 * v1 - ic1eq
    state[1] = 2.0 * v2 - ic2eq
    # Denormal flush
    if abs(state[0]) < 1e-30:
        state[0] = 0.0
    if abs(state[1]) < 1e-30:
        state[1] = 0.0
    return v2  # low-pass output


def _process_filter(x: np.ndarray, env: np.ndarray, sr: float,
                    *, fc_max: float = 18000.0, fc_min: float = 200.0,
                    q_base: float = 0.707, q_max: float = 4.0) -> np.ndarray:
    """Apply the FILTER-mode sweeping LPF to a single mono channel.

    Cutoff: log sweep fc_max → fc_min as env goes 0 → 1.
    Resonance: linear ramp q_base → q_max.
    """
    n = x.shape[0]
    y = np.zeros(n, dtype=np.float64)
    state = [0.0, 0.0]
    log_ratio = math.log(fc_min / fc_max)
    for i in range(n):
        e_i = env[i]
        fc = fc_max * math.exp(log_ratio * e_i)  # log sweep
        q = q_base + e_i * (q_max - q_base)
        y[i] = _svf_step(x[i], fc, q, sr, state)
    return y


# ---------------------------------------------------------------------------
# Mode C: FAIL — sidechain control signal; audio passthrough
# ---------------------------------------------------------------------------


def _process_fail_audio(x: np.ndarray) -> np.ndarray:
    """FAIL mode does not modify the audio path."""
    return x.astype(np.float64).copy()


def _build_failure_override(env: np.ndarray, failure_knob: float) -> np.ndarray:
    """failure_override = knob + e · (1 - knob).
    When e=0: override = knob (no boost).
    When e=1: override = 1.0 (max failure).
    """
    knob = float(np.clip(failure_knob, 0.0, 1.0))
    return knob + env * (1.0 - knob)


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


@dataclasses.dataclass
class AuxParams:
    aux_mode: int = MODE_STOP
    aux_onset_ms: float = 200.0
    failure_knob: float = 0.0


def process(x: np.ndarray, sr: float, *,
            aux_mode: int,
            aux_active: Union[int, np.ndarray],
            aux_onset_ms: float,
            failure_knob: float = 0.0) -> dict:
    """Process a stereo audio buffer through tl_aux.

    Args:
        x: shape (N,) mono or (N, 2) stereo, float32 or float64.
        sr: sample rate in Hz.
        aux_mode: 0=STOP, 1=FILTER, 2=FAIL.
        aux_active: scalar 0/1, or shape (N,) per-sample press timeline.
        aux_onset_ms: ramp time, 10–3000 ms.
        failure_knob: current FAILURE knob value (used in FAIL mode
            for the additive-toward-max boost).

    Returns:
        dict with keys:
            "audio": (N, 2) float — processed output.
            "failure_override": (N,) float — sidechain control signal
                (zeros in non-FAIL modes, otherwise a [knob..1.0] ramp).
            "envelope": (N,) float — the onset envelope, for debug.
    """
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    if x.ndim != 2 or x.shape[1] != 2:
        raise ValueError(f"expected stereo or mono input, got shape {x.shape}")

    n = x.shape[0]

    # Coerce aux_active to a per-sample array.
    if np.isscalar(aux_active):
        active_arr = np.full(n, float(aux_active), dtype=np.float64)
    else:
        active_arr = np.asarray(aux_active, dtype=np.float64).reshape(-1)
        if active_arr.shape[0] != n:
            raise ValueError(
                f"aux_active array length {active_arr.shape[0]} != audio length {n}"
            )

    onset_ms = float(np.clip(aux_onset_ms, 10.0, 3000.0))
    mode = int(aux_mode)
    if mode not in (MODE_STOP, MODE_FILTER, MODE_FAIL):
        raise ValueError(f"aux_mode must be 0/1/2, got {mode}")

    env = _build_envelope(active_arr, onset_ms, sr)

    out = np.zeros_like(x, dtype=np.float64)
    failure_override = np.zeros(n, dtype=np.float64)

    if mode == MODE_STOP:
        out[:, 0] = _process_stop(x[:, 0].astype(np.float64), env, sr)
        out[:, 1] = _process_stop(x[:, 1].astype(np.float64), env, sr)
    elif mode == MODE_FILTER:
        out[:, 0] = _process_filter(x[:, 0].astype(np.float64), env, sr)
        out[:, 1] = _process_filter(x[:, 1].astype(np.float64), env, sr)
    else:  # MODE_FAIL
        out[:, 0] = _process_fail_audio(x[:, 0])
        out[:, 1] = _process_fail_audio(x[:, 1])
        failure_override = _build_failure_override(env, failure_knob)

    return {
        "audio": out.astype(x.dtype),
        "failure_override": failure_override,
        "envelope": env,
    }


# ---------------------------------------------------------------------------
# __main__: render fixtures
# ---------------------------------------------------------------------------


def _make_test_input(sr: float, dur_sec: float = 4.0) -> np.ndarray:
    """A test signal that exposes all three modes:
    - sustained tone (so STOP's pitch slide is audible)
    - mid-frequency content (so FILTER's sweep is audible)
    - quasi-stationary RMS (so FAIL's pass-through is verifiable)
    """
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    sig = (
        0.35 * np.sin(2.0 * np.pi * 220.0 * t)        # A3 fundamental
        + 0.20 * np.sin(2.0 * np.pi * 440.0 * t)      # A4
        + 0.12 * np.sin(2.0 * np.pi * 1320.0 * t)     # E6 (mid-air)
        + 0.06 * np.sin(2.0 * np.pi * 2640.0 * t)     # E7 (treble for FILTER)
    )
    # Add a tiny bit of broadband noise so FILTER's sweep has hash to chew on.
    rng = np.random.default_rng(seed=1234)
    sig += 0.02 * rng.standard_normal(n)
    sig /= np.max(np.abs(sig)) or 1.0
    sig *= 0.5
    return np.stack([sig, sig], axis=1).astype(np.float32)


def _make_press_timeline(sr: float, dur_sec: float = 4.0,
                         press_start: float = 1.0,
                         press_end: float = 3.0) -> np.ndarray:
    """0 from 0..press_start, 1 from press_start..press_end, 0 after."""
    n = int(dur_sec * sr)
    active = np.zeros(n, dtype=np.float64)
    s = int(press_start * sr)
    e = int(press_end * sr)
    active[s:e] = 1.0
    return active


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny WAV writer (PCM16) — avoids scipy/soundfile dependency.
    Accepts (N,) mono or (N, 2) stereo float in [-1, 1]."""
    import wave
    path.parent.mkdir(parents=True, exist_ok=True)
    if x.ndim == 1:
        nchannels = 1
        x_clip = np.clip(x, -1.0, 1.0)
        int16 = (x_clip * 32767.0).astype(np.int16)
        interleaved = int16
    else:
        nchannels = x.shape[1]
        x_clip = np.clip(x, -1.0, 1.0)
        int16 = (x_clip * 32767.0).astype(np.int16)
        interleaved = int16.reshape(-1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(nchannels)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(interleaved.tobytes())


def render_fixtures(out_dir: Path, sr: int = 44100) -> list[Path]:
    """Render the four sanity-check WAVs (dry + 3 mode demos)."""
    written: list[Path] = []
    in_audio = _make_test_input(sr=sr, dur_sec=4.0)
    active = _make_press_timeline(sr=sr, dur_sec=4.0,
                                  press_start=1.0, press_end=3.0)

    # Dry reference
    dry_path = out_dir / "tl_aux_input_dry.wav"
    _save_wav(dry_path, in_audio, sr)
    written.append(dry_path)

    cases = [
        ("stop",   MODE_STOP,   800.0, dict()),
        ("filter", MODE_FILTER, 600.0, dict()),
        ("fail",   MODE_FAIL,   400.0, dict(failure_knob=0.2)),
    ]

    for tag, mode, onset, kw in cases:
        result = process(
            in_audio, sr=float(sr),
            aux_mode=mode,
            aux_active=active,
            aux_onset_ms=onset,
            **kw,
        )
        path = out_dir / f"tl_aux_demo_{tag}.wav"
        _save_wav(path, result["audio"], sr)
        written.append(path)
        # For FAIL mode, also render the control-signal trace as mono WAV
        # so the engineer can audition / diff it.
        if mode == MODE_FAIL:
            ctrl_path = out_dir / "tl_aux_demo_fail_ctrl.wav"
            _save_wav(ctrl_path, result["failure_override"].astype(np.float32),
                      sr)
            written.append(ctrl_path)

    # Verification properties
    print("--- verification ---")
    # Property 1: aux_active=0 always → output == input for all modes
    zero_active = np.zeros(in_audio.shape[0], dtype=np.float64)
    for tag, mode, onset, kw in cases:
        r = process(in_audio, sr=float(sr),
                    aux_mode=mode, aux_active=zero_active,
                    aux_onset_ms=onset, **kw)
        diff = float(np.max(np.abs(r["audio"].astype(np.float64) -
                                    in_audio.astype(np.float64))))
        # Mode FILTER will not be exactly 0 because envelope is exactly 0 →
        # SVF runs with fc=18kHz wide-open. That's a near-pass-through but
        # not bit-identical. Print the diff.
        print(f"  active=0, mode={tag}: max abs diff = {diff:.6f}")

    # Property 2: STOP mode at e=1 plateau → output ≈ silence
    plateau_active = np.ones(in_audio.shape[0], dtype=np.float64)
    r = process(in_audio, sr=float(sr),
                aux_mode=MODE_STOP, aux_active=plateau_active,
                aux_onset_ms=10.0)
    # Look at the last 25% of the buffer (after the 4.6 × 10ms ≈ 46ms ramp)
    tail = r["audio"][int(0.75 * in_audio.shape[0]):]
    tail_rms = float(np.sqrt(np.mean(tail ** 2)))
    dry_rms = float(np.sqrt(np.mean(in_audio.astype(np.float64) ** 2)))
    print(f"  STOP plateau tail RMS = {tail_rms:.6f}; dry RMS = {dry_rms:.6f}; "
          f"ratio = {tail_rms/dry_rms:.6f}")

    # Property 3: FAIL mode → audio bit-identical to input regardless of e
    for active_test in [zero_active, plateau_active, active]:
        r = process(in_audio, sr=float(sr), aux_mode=MODE_FAIL,
                    aux_active=active_test, aux_onset_ms=400.0,
                    failure_knob=0.2)
        diff = float(np.max(np.abs(r["audio"].astype(np.float64) -
                                    in_audio.astype(np.float64))))
        print(f"  FAIL audio passthrough max diff = {diff:.6e}")

    # Property 4: failure_override at end of plateau → 1.0
    r = process(in_audio, sr=float(sr), aux_mode=MODE_FAIL,
                aux_active=plateau_active, aux_onset_ms=10.0,
                failure_knob=0.2)
    final_override = float(r["failure_override"][-1])
    print(f"  FAIL override at plateau end = {final_override:.6f} "
          f"(expected ≈ 1.0)")

    # Property 5: FILTER mode spectral centroid monotone-decreasing during press
    r = process(in_audio, sr=float(sr), aux_mode=MODE_FILTER,
                aux_active=active, aux_onset_ms=600.0)
    # Spectral centroid via FFT of two windows. Press window's centroid
    # MUST be lower than dry window's (high freqs attenuated by closing LPF).
    def _centroid(buf, sr):
        # Use mean of L+R, mono-fold, FFT magnitude
        mono = buf.astype(np.float64).mean(axis=1)
        spec = np.abs(np.fft.rfft(mono * np.hanning(len(mono))))
        freqs = np.fft.rfftfreq(len(mono), d=1.0 / sr)
        denom = float(np.sum(spec)) + 1e-30
        return float(np.sum(freqs * spec) / denom)

    dry_window = r["audio"][int(0.5 * sr):int(0.9 * sr)]
    press_window = r["audio"][int(2.5 * sr):int(2.9 * sr)]
    c_dry = _centroid(dry_window, sr)
    c_press = _centroid(press_window, sr)
    print(f"  FILTER spectral centroid: dry={c_dry:.1f} Hz, "
          f"press={c_press:.1f} Hz (expect press < dry)")

    return written


if __name__ == "__main__":
    out_dir = Path(__file__).resolve().parent / "fixtures"
    files = render_fixtures(out_dir)
    print(f"\nwrote {len(files)} fixture(s) to {out_dir}")
    for f in files:
        print(f"  {f}")
