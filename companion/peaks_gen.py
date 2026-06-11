"""Waveform peaks generator for companion app.

Produces downsampled min/max envelopes from stem WAV files for
waveform rendering in the Perform view. Pure stdlib (wave module).

Usage:
    from peaks_gen import peaks_for_wav
    data = peaks_for_wav("/path/to/stem.wav", target_points=800)
    # -> {"sr": 44100, "samples_per_peak": 55, "peaks": [[-0.3, 0.4], ...]}
"""
from __future__ import annotations
import json
import os
import struct
import wave
from pathlib import Path


def peaks_for_wav(path: str | Path, target_points: int = 800) -> dict:
    """Generate a downsampled min/max envelope from a WAV file.

    Returns {"sr", "samples_per_peak", "peaks": [[min, max], ...]}.
    Peaks are normalized to -1..1. Stereo is mixed to mono.
    """
    path = Path(path)
    with wave.open(str(path), "rb") as wf:
        nchannels = wf.getnchannels()
        sampwidth = wf.getsampwidth()
        sr = wf.getframerate()
        nframes = wf.getnframes()

        if nframes == 0:
            return {"sr": sr, "samples_per_peak": 0, "peaks": []}

        # Read all frames as bytes
        raw = wf.readframes(nframes)

    # Decode samples
    if sampwidth == 2:
        fmt = f"<{nframes * nchannels}h"
        samples = struct.unpack(fmt, raw)
        max_val = 32767.0
    elif sampwidth == 3:
        # 24-bit: unpack manually
        samples = []
        for i in range(0, len(raw), 3):
            b = raw[i:i+3]
            val = int.from_bytes(b, "little", signed=True)
            samples.append(val)
        max_val = 8388607.0
    elif sampwidth == 1:
        samples = struct.unpack(f"{nframes * nchannels}B", raw)
        samples = [s - 128 for s in samples]  # unsigned to signed
        max_val = 127.0
    else:
        raise ValueError(f"unsupported sample width: {sampwidth}")

    # Mix to mono if stereo
    if nchannels > 1:
        mono = []
        for i in range(0, len(samples), nchannels):
            mono.append(sum(samples[i:i+nchannels]) / nchannels)
        samples = mono

    total = len(samples)
    samples_per_peak = max(1, total // target_points)
    num_peaks = (total + samples_per_peak - 1) // samples_per_peak

    peaks = []
    for i in range(num_peaks):
        start = i * samples_per_peak
        end = min(start + samples_per_peak, total)
        chunk = samples[start:end]
        lo = min(chunk) / max_val
        hi = max(chunk) / max_val
        # Clamp to -1..1
        lo = max(-1.0, min(1.0, lo))
        hi = max(-1.0, min(1.0, hi))
        peaks.append([round(lo, 4), round(hi, 4)])

    return {
        "sr": sr,
        "samples_per_peak": samples_per_peak,
        "peaks": peaks,
    }


# ── Caching ────────────────────────────────────────────────────────

CACHE_DIR = Path(__file__).resolve().parent / "peaks"


def _cache_path(clip_id: str) -> Path:
    safe = clip_id.replace("/", "_").replace(":", "_").replace("?", "_")
    return CACHE_DIR / f"{safe}.json"


def get_peaks_cached(clip_id: str, wav_path: str | Path) -> dict | None:
    """Return cached peaks, regenerating if WAV is newer or cache missing."""
    wav_path = Path(wav_path)
    if not wav_path.exists():
        return None

    cache = _cache_path(clip_id)
    wav_mtime = wav_path.stat().st_mtime

    if cache.exists():
        try:
            if cache.stat().st_mtime >= wav_mtime:
                return json.loads(cache.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass

    # Generate + cache
    try:
        data = peaks_for_wav(wav_path)
    except Exception:
        return None

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache.write_text(json.dumps(data), encoding="utf-8")
    return data
