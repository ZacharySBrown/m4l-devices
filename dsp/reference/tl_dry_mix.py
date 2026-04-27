"""tl_dry_mix — numpy reference implementation of the DRY toggle mixer.

The DRY toggle has three positions: NONE (wet only), SMALL
(−8 dB dry blend), UNITY (0 dB dry blend). The mixer is per-sample
per-channel: y[n] = wet[n] + g_dry[n] · dry_aligned[n].

`g_dry[n]` is held at the per-mode constant (see GAIN_FOR_MODE) and
crossfaded over 10 ms (Hann half-cosine) when the mode changes.

LATENCY-ALIGNMENT NOTE (also documented in the design doc):
    This reference takes a `dry` argument SEPARATELY from `wet`. The
    caller is responsible for time-aligning the two signals — i.e.
    `dry` must already be delayed to match the nominal delay of
    upstream `tl_wow` (~30 ms). The reference does NOT introduce its
    own delay; it sums what it's given. The engineer's M4L wiring
    must implement the parallel pre-WOW dry tap with a fixed 30 ms
    delay (see design doc §2).

Public API:
    process(dry, wet, sr, *, dry_mode, mode_changes=None)
        -> ndarray (N, 2)

`dry` and `wet` are shape (N, 2) float arrays; mono inputs of shape
(N,) are duplicated to stereo. `dry_mode` is the mode active at
buffer start. `mode_changes` is an optional list of
(sample_index, new_mode) tuples for mid-buffer mode toggles
(used by the xfade fixture render).

References:
    - W. Pirkle, "Designing Audio Effect Plug-Ins in C++", Ch. 4
      (chorus topology — positive-polarity dry sum)
    - S. W. Smith, "The Scientist and Engineer's Guide to DSP",
      Ch. 16 (Hann window for click-free crossfades)
    - tape-loss-spec.md §"DRY Toggle"
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Iterable, Optional

import numpy as np


# ---------------------------------------------------------------------------
# Mode constants — these are the load-bearing numbers. If the engineer
# needs to recalibrate, change them here AND in any companion
# coefficient JSON they generate; the tradeoff log in the design doc
# explains the rationale (especially for SMALL = -8 dB).
# ---------------------------------------------------------------------------

MODE_NONE = 0
MODE_SMALL = 1
MODE_UNITY = 2

G_NONE_LIN = 0.0
G_SMALL_LIN = 0.3981   # -8 dB. See design doc §6.
G_UNITY_LIN = 1.0      # 0 dB.

GAIN_FOR_MODE = {
    MODE_NONE:  G_NONE_LIN,
    MODE_SMALL: G_SMALL_LIN,
    MODE_UNITY: G_UNITY_LIN,
}

CROSSFADE_MS = 10.0  # design doc §4

# Latency alignment: nominal WOW delay tap. The engineer's M4L patch
# must provide `dry` already delayed by this much to time-align with
# `wet`. See design doc §2.1.
NOMINAL_WOW_DELAY_MS = 30.0


# ---------------------------------------------------------------------------
# Utility — coerce input to (N, 2) stereo
# ---------------------------------------------------------------------------


def _to_stereo(x: np.ndarray) -> np.ndarray:
    if x.ndim == 1:
        return np.stack([x, x], axis=1)
    if x.ndim == 2 and x.shape[1] == 2:
        return x
    raise ValueError(f"expected mono (N,) or stereo (N,2), got shape {x.shape}")


# ---------------------------------------------------------------------------
# Crossfade gain trajectory builder
# ---------------------------------------------------------------------------


def _build_gain_trajectory(
    n_samples: int,
    sr: float,
    initial_mode: int,
    mode_changes: Iterable[tuple[int, int]] = (),
) -> np.ndarray:
    """Build a per-sample dry gain array `g[n]` honoring the initial
    mode and any mode_changes (each a (sample_idx, new_mode) tuple).

    On each mode change, ramp from the *instantaneous* current gain
    (so back-to-back changes within one fade are handled) to the new
    target via Hann half-cosine over `CROSSFADE_MS`.
    """
    g = np.zeros(n_samples, dtype=np.float64)
    if initial_mode not in GAIN_FOR_MODE:
        raise ValueError(f"unknown initial mode {initial_mode}")
    fade_len = max(1, int(round(CROSSFADE_MS * 1e-3 * sr)))

    # Sort mode changes by sample index defensively.
    events = sorted(list(mode_changes), key=lambda e: int(e[0]))

    cursor = 0
    current_target = GAIN_FOR_MODE[initial_mode]
    # Treat the start of the buffer as already-settled at the initial
    # mode's target gain.
    last_settled_value = current_target
    fade_start_idx: Optional[int] = None
    fade_start_value = current_target
    fade_target_value = current_target

    def settle_until(idx: int) -> None:
        """Fill g[cursor:idx] respecting any in-flight fade."""
        nonlocal cursor, last_settled_value, fade_start_idx
        if idx <= cursor:
            return
        if fade_start_idx is None:
            g[cursor:idx] = last_settled_value
            cursor = idx
            return
        # We are inside a fade.
        for n in range(cursor, idx):
            local = n - fade_start_idx
            if local >= fade_len:
                # fade has completed
                g[n] = fade_target_value
                last_settled_value = fade_target_value
            else:
                # Hann half-cosine: fade_start (1→0) summed with
                # fade_target (0→1) using cos(pi * t):
                #   w_old = 0.5 * (1 + cos(pi * t))
                #   w_new = 0.5 * (1 - cos(pi * t))
                t = local / fade_len
                cos_term = math.cos(math.pi * t)
                w_old = 0.5 * (1.0 + cos_term)
                w_new = 0.5 * (1.0 - cos_term)
                g[n] = w_old * fade_start_value + w_new * fade_target_value
        # update last_settled_value for state outside the fade
        if idx - fade_start_idx >= fade_len:
            fade_start_idx = None
            last_settled_value = fade_target_value
        else:
            # leave fade_start_idx set; g[idx-1] is mid-fade
            last_settled_value = g[idx - 1]
        cursor = idx

    for evt_idx, new_mode in events:
        evt_idx = max(0, min(int(evt_idx), n_samples))
        if new_mode not in GAIN_FOR_MODE:
            raise ValueError(f"unknown mode in event: {new_mode}")
        # Settle output up to evt_idx
        settle_until(evt_idx)
        # Capture instantaneous current gain (handles fade-within-fade)
        if fade_start_idx is not None:
            # if a fade is in flight, last_settled_value was updated
            # to the most recent g[n].
            current_inst = last_settled_value
        else:
            current_inst = last_settled_value
        new_target = GAIN_FOR_MODE[new_mode]
        if abs(new_target - current_inst) < 1e-12:
            # No-op change (e.g. NONE → NONE) — skip fade.
            continue
        fade_start_idx = evt_idx
        fade_start_value = current_inst
        fade_target_value = new_target

    settle_until(n_samples)
    return g


# ---------------------------------------------------------------------------
# Top-level
# ---------------------------------------------------------------------------


def process(
    dry: np.ndarray,
    wet: np.ndarray,
    sr: float,
    *,
    dry_mode: int = MODE_NONE,
    mode_changes: Optional[Iterable[tuple[int, int]]] = None,
) -> np.ndarray:
    """Mix `dry` and `wet` per the DRY toggle.

    Args:
        dry: shape (N,) or (N, 2). MUST already be time-aligned to
            `wet` (i.e. delayed by the nominal upstream WOW tap;
            see design doc §2). The reference does not align.
        wet: shape (N,) or (N, 2). The output of upstream processing
            (post-volume-mix).
        sr: sample rate Hz.
        dry_mode: initial mode (0=NONE, 1=SMALL, 2=UNITY).
        mode_changes: optional iterable of (sample_idx, new_mode)
            tuples for mid-buffer mode toggles.

    Returns:
        ndarray of shape (N, 2), float of the larger input dtype
        (float32 or float64).
    """
    dry_s = _to_stereo(np.asarray(dry))
    wet_s = _to_stereo(np.asarray(wet))
    if dry_s.shape != wet_s.shape:
        raise ValueError(
            f"dry and wet must have matching shape; got {dry_s.shape} vs {wet_s.shape}"
        )
    n_samples = dry_s.shape[0]

    # Out dtype = whichever input is float64, else float32.
    out_dtype = np.float64 if (dry_s.dtype == np.float64 or wet_s.dtype == np.float64) \
        else np.float32

    g = _build_gain_trajectory(
        n_samples,
        sr=float(sr),
        initial_mode=int(dry_mode),
        mode_changes=tuple(mode_changes) if mode_changes else (),
    )
    # Apply per-channel: y = wet + g * dry
    g_col = g[:, None]  # broadcast across the 2 channels
    y = wet_s.astype(np.float64) + g_col * dry_s.astype(np.float64)
    return y.astype(out_dtype)


# ---------------------------------------------------------------------------
# Fixture rendering: build a dry/wet pair and render each mode + xfade.
# ---------------------------------------------------------------------------


def _make_dry_signal(sr: float, dur_sec: float = 3.0) -> np.ndarray:
    """Synthetic 'guitar-like' input: A2/E3/A3 chord with ADSR-ish
    envelope. Identical to tl_failure's test input for cross-fixture
    comparability."""
    n = int(dur_sec * sr)
    t = np.arange(n) / sr
    fundamentals = [110.0, 164.81, 220.0]
    sig = np.zeros(n, dtype=np.float64)
    for f0 in fundamentals:
        for k, gain in enumerate([1.0, 0.5, 0.3, 0.15, 0.08], start=1):
            sig += gain * np.sin(2.0 * np.pi * f0 * k * t + 0.1 * k)
    sig /= np.max(np.abs(sig)) or 1.0
    sig *= 0.6
    env = np.ones(n, dtype=np.float64)
    a_n = int(0.1 * sr)
    r_n = int(0.4 * sr)
    env[:a_n] = np.linspace(0.0, 1.0, a_n)
    env[-r_n:] = np.linspace(1.0, 0.0, r_n)
    sig *= env
    return np.stack([sig, sig], axis=1).astype(np.float32)


def _make_wet_signal(dry: np.ndarray, sr: float, cents: float = 7.0) -> np.ndarray:
    """LEGACY (no longer used for fixture rendering).

    Originally this synthesized a wet stand-in via a constant fractional
    resample of the dry. It produced output that was perceptually almost
    identical to the dry, so listeners couldn't actually hear the
    dry-mix's effect (only the brief crossfade artifact). Kept for
    reference / legacy callers; fixture rendering now uses
    `tl_wow.process(dry, sr, wow=0.5, seed=42)` for a properly
    differentiated wet stand-in (see `_make_wow_wet_signal`).
    """
    n = dry.shape[0]
    ratio = 2.0 ** (cents / 1200.0)
    src_idx = np.arange(n) * ratio
    src_floor = np.floor(src_idx).astype(np.int64)
    frac = src_idx - src_floor
    out = np.zeros_like(dry, dtype=np.float64)
    n_dry = dry.shape[0]
    valid = src_floor + 1 < n_dry
    s0 = np.clip(src_floor, 0, n_dry - 1)
    s1 = np.clip(src_floor + 1, 0, n_dry - 1)
    for ch in range(2):
        a = dry[s0, ch].astype(np.float64)
        b = dry[s1, ch].astype(np.float64)
        out[:, ch] = a + frac * (b - a)
    out[~valid] = 0.0
    return out.astype(dry.dtype)


def _make_wow_wet_signal(dry: np.ndarray, sr: float,
                         wow: float = 0.5, seed: int = 42) -> np.ndarray:
    """Render the wet probe as `tl_wow.process(dry, sr, wow=wow, seed=seed)`.

    The spec ("WOW + DRY UNITY produces classic chorus naturally")
    pegs the canonical demo for `tl_dry_mix` to dry vs dry-with-wow.
    Mixing those at UNITY produces audible chorus (comb-filtering
    between dry and pitch-modulated wet). At SMALL the wow dominates
    with a thin dry tail; at NONE only the wow is heard.

    `wow=0.5` (noon) is loud enough to be unambiguous but well below
    the cartoonish `wow=1.0` ceiling. `seed=42` keeps the fixture
    deterministic.

    Args:
        dry: (N, 2) input.
        sr: sample rate (Hz).
        wow: wow knob in [0, 1].
        seed: RNG seed for reproducibility.
    Returns:
        (N, 2) wet, dtype matching `dry`.
    """
    # Lazy import — avoid circular issues at module-load time, and
    # keep `tl_dry_mix.process` itself dependency-free.
    from tl_wow import process as wow_process  # type: ignore  # noqa: E402
    wet64 = wow_process(dry.astype(np.float64), float(sr), wow=float(wow),
                        seed=int(seed), stereo_decorrelate=True)
    return wet64.astype(dry.dtype)


def _save_wav(path: Path, x: np.ndarray, sr: int) -> None:
    """Tiny WAV writer (PCM16) — same recipe as tl_failure.py."""
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
    """Render fixtures: dry input, wet input (= tl_wow(0.5) of dry),
    one output per dry-mode, plus a mode-change crossfade demo.

    The wet probe is the dry processed through `tl_wow` at noon
    (wow=0.5, seed=42). This makes the dry/wet character difference
    audibly large — UNITY produces real chorus, SMALL is wow with a
    thin dry tail, NONE is wow only. The previous implementation
    (constant fractional pitch-shift) gave a wet that was
    perceptually identical to dry, so listeners couldn't hear what
    the dry-mix was actually doing.
    """
    written: list[Path] = []
    sr_f = float(sr)

    dry = _make_dry_signal(sr=sr_f, dur_sec=3.0)
    # Wet = WOW-processed dry. wow=0.5 (noon), seed=42 (deterministic).
    wet = _make_wow_wet_signal(dry, sr=sr_f, wow=0.5, seed=42)

    # Save inputs for engineer's reference (and as listener A/B).
    in_dry_path = out_dir / "tl_dry_mix_input_dry.wav"
    _save_wav(in_dry_path, dry, sr)
    written.append(in_dry_path)

    in_wet_path = out_dir / "tl_dry_mix_input_wet.wav"
    _save_wav(in_wet_path, wet, sr)
    written.append(in_wet_path)

    # Clean up any stale UNITY peakscaled fixtures from a prior run —
    # the scale factor depends on signal content, so the filename can
    # change. We leave only the freshly written one.
    for stale in out_dir.glob("tl_dry_mix_UNITY_peakscaled_*.wav"):
        try:
            stale.unlink()
        except OSError:
            pass
    stale_unity = out_dir / "tl_dry_mix_UNITY.wav"
    if stale_unity.exists():
        try:
            stale_unity.unlink()
        except OSError:
            pass

    # Per-mode renders.
    unity_peak_factor: Optional[float] = None
    for tag, mode in [("NONE", MODE_NONE), ("SMALL", MODE_SMALL), ("UNITY", MODE_UNITY)]:
        out = process(dry, wet, sr=sr_f, dry_mode=mode)
        # Normalize defensively — UNITY can clip on correlated material;
        # for the WAV fixture we scale down to 0.99 peak only when peak > 1.0
        # so the WAV is audible without clipping. The mathematical output
        # is the un-scaled `out`; we attach the scale factor in metadata
        # via filename suffix when relevant.
        peak = float(np.max(np.abs(out)) or 1.0)
        if peak > 1.0:
            wav_out = out * (0.99 / peak)
            suffix = f"_peakscaled_{peak:.2f}x"
        else:
            wav_out = out
            suffix = ""
        if tag == "UNITY":
            unity_peak_factor = peak
        path = out_dir / f"tl_dry_mix_{tag}{suffix}.wav"
        _save_wav(path, wav_out, sr)
        written.append(path)
        # Sanity: the WAV peak after defensive scaling must be ≤ 1.0
        # (no clipping in the int16 fixture).
        assert float(np.max(np.abs(wav_out))) <= 1.0 + 1e-9, \
            f"{tag} fixture peak > 1.0 after scaling: {float(np.max(np.abs(wav_out)))}"

    # Crossfade demo: NONE → SMALL → UNITY → NONE every 750 ms.
    ms_per_step = 750
    step_n = int(ms_per_step * 1e-3 * sr_f)
    mode_changes = [
        (step_n, MODE_SMALL),
        (2 * step_n, MODE_UNITY),
        (3 * step_n, MODE_NONE),
    ]
    out = process(dry, wet, sr=sr_f, dry_mode=MODE_NONE, mode_changes=mode_changes)
    peak = float(np.max(np.abs(out)) or 1.0)
    wav_out = out * (0.99 / peak) if peak > 1.0 else out
    path = out_dir / "tl_dry_mix_xfade.wav"
    _save_wav(path, wav_out, sr)
    written.append(path)

    if unity_peak_factor is not None:
        print(f"  UNITY peak factor: {unity_peak_factor:.4f}x "
              f"(filename suffix: _peakscaled_{unity_peak_factor:.2f}x)")
    return written


# ---------------------------------------------------------------------------
# Verification helpers — invoked from __main__ for sanity-check printouts
# ---------------------------------------------------------------------------


def _verify_properties(sr: float = 44100.0) -> None:
    """Programmatic property checks called from __main__."""
    dry = _make_dry_signal(sr, dur_sec=1.0)
    wet = _make_wet_signal(dry, sr=sr, cents=0.0)  # wet = dry exactly

    # 1. NONE → output == wet.
    out_none = process(dry, wet, sr=sr, dry_mode=MODE_NONE)
    diff_none = float(np.max(np.abs(out_none - wet)))
    print(f"  NONE: max|out - wet| = {diff_none:.2e}  (expect 0)")
    assert diff_none == 0.0, f"NONE mode should be identity, got {diff_none}"

    # 2. UNITY with dry == wet → output == 2 * dry.
    out_unity = process(dry, wet, sr=sr, dry_mode=MODE_UNITY)
    diff_unity = float(np.max(np.abs(out_unity - 2.0 * dry)))
    print(f"  UNITY (dry=wet): max|out - 2*dry| = {diff_unity:.2e}  (expect ~0)")
    assert diff_unity < 1e-6, f"UNITY+dry==wet should be 2x, got {diff_unity}"

    # 3. SMALL gain magnitude.
    out_small = process(dry, np.zeros_like(wet), sr=sr, dry_mode=MODE_SMALL)
    expected_small = G_SMALL_LIN * dry
    diff_small = float(np.max(np.abs(out_small - expected_small)))
    print(f"  SMALL gain check: max|out - G_SMALL*dry| = {diff_small:.2e}  (expect ~0)")
    assert diff_small < 1e-6

    # 4. Crossfade click-freeness: derivative shouldn't have a step.
    n = int(0.1 * sr)
    d = np.zeros((n, 2), dtype=np.float64)
    d[:, 0] = 1.0  # constant DC on left channel
    w = np.zeros((n, 2), dtype=np.float64)
    out_xfade = process(d, w, sr=sr, dry_mode=MODE_NONE,
                        mode_changes=[(n // 2, MODE_UNITY)])
    # During fade, output transitions from 0 to 1 over CROSSFADE_MS samples.
    # Max first-difference should be small: peak slope of Hann is
    # pi/(2*L). For L=441 samples, max step ≈ 0.00356.
    diffs = np.diff(out_xfade[:, 0])
    max_step = float(np.max(np.abs(diffs)))
    expected_max = math.pi / (2.0 * int(CROSSFADE_MS * 1e-3 * sr))
    print(f"  xfade click check: max|Δy| = {max_step:.4f}  "
          f"(Hann theoretical peak slope = {expected_max:.4f})")
    assert max_step <= expected_max * 1.01, "Hann xfade slope exceeded — click risk!"

    # 5. Stereo independence: feed decorrelated L/R noise, verify
    # channels stay independent (correlation between L and R of the
    # output ~= correlation between L and R of inputs).
    rng = np.random.default_rng(42)
    n2 = 4096
    d2 = rng.standard_normal((n2, 2)) * 0.3
    w2 = rng.standard_normal((n2, 2)) * 0.3
    out2 = process(d2, w2, sr=sr, dry_mode=MODE_UNITY)
    corr_in = float(np.corrcoef(d2[:, 0] + w2[:, 0], d2[:, 1] + w2[:, 1])[0, 1])
    corr_out = float(np.corrcoef(out2[:, 0], out2[:, 1])[0, 1])
    print(f"  stereo indep: corr(L, R) input-sum={corr_in:.3f} out={corr_out:.3f}  (expect close)")
    assert abs(corr_in - corr_out) < 1e-6


if __name__ == "__main__":
    import hashlib
    import sys

    # Make `tl_wow` importable when running this file directly
    # (`python3 dsp/reference/tl_dry_mix.py`). Both modules live side
    # by side in dsp/reference/.
    sys.path.insert(0, str(Path(__file__).resolve().parent))

    print("tl_dry_mix property checks:")
    _verify_properties()
    print()

    out_dir = Path(__file__).resolve().parent / "fixtures"

    # Capture the existing input_dry sha BEFORE rendering, so we can
    # confirm the source signal hasn't changed across this regen.
    in_dry_path = out_dir / "tl_dry_mix_input_dry.wav"
    prior_dry_sha: Optional[str] = None
    if in_dry_path.exists():
        prior_dry_sha = hashlib.sha256(in_dry_path.read_bytes()).hexdigest()

    files = render_fixtures(out_dir)
    print(f"\nwrote {len(files)} fixture(s) to {out_dir}")
    for f in files:
        print(f"  {f}")

    # ── Post-render sanity assertions ────────────────────────────────
    print("\nPost-render sanity assertions:")

    def _sha(p: Path) -> str:
        return hashlib.sha256(p.read_bytes()).hexdigest()

    # 1. input_dry sha unchanged (the dry probe is the same source signal).
    new_dry_sha = _sha(in_dry_path)
    print(f"  input_dry sha: {new_dry_sha}")
    if prior_dry_sha is not None:
        assert new_dry_sha == prior_dry_sha, (
            f"input_dry sha changed across regen!\n"
            f"  before: {prior_dry_sha}\n"
            f"  after:  {new_dry_sha}\n"
            "The dry probe must be deterministic and identical to the "
            "previous render — only the wet probe should change."
        )
        print("    -> matches prior render (PASS)")
    else:
        print("    -> no prior render to compare against (skip)")

    # 2. NONE.wav sha == input_wet.wav sha (NONE = wet only, bit-identical).
    in_wet_path = out_dir / "tl_dry_mix_input_wet.wav"
    none_path = out_dir / "tl_dry_mix_NONE.wav"
    wet_sha = _sha(in_wet_path)
    none_sha = _sha(none_path)
    print(f"  input_wet sha: {wet_sha}")
    print(f"  NONE sha:      {none_sha}")
    assert wet_sha == none_sha, (
        f"NONE.wav must be bit-identical to input_wet.wav "
        f"(NONE = wet only). Got {none_sha} vs {wet_sha}."
    )
    print("    -> NONE == input_wet (PASS)")

    # 3. UNITY peak ≤ 1.0 in the WAV fixture (no clipping after scaling).
    unity_paths = list(out_dir.glob("tl_dry_mix_UNITY_peakscaled_*.wav"))
    if not unity_paths:
        unity_paths = [out_dir / "tl_dry_mix_UNITY.wav"]
    assert len(unity_paths) == 1, (
        f"expected exactly one UNITY fixture, got {len(unity_paths)}: "
        f"{[p.name for p in unity_paths]}"
    )
    unity_path = unity_paths[0]
    print(f"  UNITY fixture: {unity_path.name}")
    # Re-read int16 PCM and verify peak ≤ full-scale.
    import wave
    with wave.open(str(unity_path), "rb") as w:
        n_frames = w.getnframes()
        raw = w.readframes(n_frames)
    pcm = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0
    pcm_peak = float(np.max(np.abs(pcm)))
    print(f"  UNITY WAV peak: {pcm_peak:.4f}  (must be <= 1.0)")
    assert pcm_peak <= 1.0 + 1e-9, f"UNITY WAV clipped: peak={pcm_peak}"
    print("    -> no clipping (PASS)")

    print("\nAll sanity assertions passed.")
