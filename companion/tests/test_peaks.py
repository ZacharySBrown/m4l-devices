"""Tests for waveform peaks generator.

Run: cd m4l-devices && python3 -m pytest companion/tests/ -q
"""
import json
import math
import struct
import tempfile
import wave
from pathlib import Path

import pytest
import sys

# Add companion dir to path for imports
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from peaks_gen import peaks_for_wav, get_peaks_cached


def make_sine_wav(path: Path, freq: float = 440.0, duration: float = 1.0,
                  sr: int = 44100, channels: int = 1):
    """Write a synthetic sine wave WAV for testing."""
    nframes = int(sr * duration)
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)
        wf.setframerate(sr)
        for i in range(nframes):
            val = int(32767 * math.sin(2 * math.pi * freq * i / sr))
            sample = struct.pack("<h", val)
            wf.writeframes(sample * channels)


class TestPeaksForWav:
    def test_shape_and_count(self, tmp_path):
        wav = tmp_path / "test.wav"
        make_sine_wav(wav, duration=1.0, sr=44100)
        data = peaks_for_wav(wav, target_points=100)
        assert "sr" in data
        assert "samples_per_peak" in data
        assert "peaks" in data
        # Should produce ~100 peaks (±1)
        assert 90 <= len(data["peaks"]) <= 110
        assert data["sr"] == 44100

    def test_peaks_in_range(self, tmp_path):
        wav = tmp_path / "test.wav"
        make_sine_wav(wav, duration=0.5)
        data = peaks_for_wav(wav, target_points=50)
        for lo, hi in data["peaks"]:
            assert -1.0 <= lo <= 1.0
            assert -1.0 <= hi <= 1.0
            assert lo <= hi

    def test_min_max_not_all_zero(self, tmp_path):
        wav = tmp_path / "sine.wav"
        make_sine_wav(wav, freq=100, duration=0.5)
        data = peaks_for_wav(wav, target_points=50)
        maxvals = [hi for _, hi in data["peaks"]]
        assert max(maxvals) > 0.5  # sine should hit near ±1

    def test_stereo_mixed_to_mono(self, tmp_path):
        wav = tmp_path / "stereo.wav"
        make_sine_wav(wav, channels=2, duration=0.5)
        data = peaks_for_wav(wav, target_points=50)
        assert len(data["peaks"]) > 0

    def test_empty_wav(self, tmp_path):
        wav = tmp_path / "empty.wav"
        with wave.open(str(wav), "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(44100)
        data = peaks_for_wav(wav)
        assert data["peaks"] == []

    def test_default_target_points(self, tmp_path):
        wav = tmp_path / "long.wav"
        make_sine_wav(wav, duration=2.0, sr=44100)
        data = peaks_for_wav(wav)  # default 800
        assert 700 <= len(data["peaks"]) <= 900


class TestCaching:
    def test_cache_writes_and_reads(self, tmp_path, monkeypatch):
        import peaks_gen
        monkeypatch.setattr(peaks_gen, "CACHE_DIR", tmp_path / "cache")

        wav = tmp_path / "test.wav"
        make_sine_wav(wav, duration=0.2)

        data1 = get_peaks_cached("test-clip", wav)
        assert data1 is not None
        assert len(data1["peaks"]) > 0

        # Second call should read from cache
        data2 = get_peaks_cached("test-clip", wav)
        assert data2 == data1

    def test_missing_wav_returns_none(self, tmp_path, monkeypatch):
        import peaks_gen
        monkeypatch.setattr(peaks_gen, "CACHE_DIR", tmp_path / "cache")
        assert get_peaks_cached("missing", tmp_path / "no.wav") is None
