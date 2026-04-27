"""Coefficient generator for `tl_saturate`.

Computes the RBJ high-shelf biquad coefficients for the pre- and
de-emphasis stages, the DC-blocker pole radius, and the halfband FIR
taps, at all sample rates the device supports. The output JSON is
read at runtime by the engineer's `[js]` companion in
`tl.saturate.maxpat`.

References:
    - RBJ Audio EQ Cookbook §"High shelf"
    - JOS, "Introduction to Digital Filters", §"DC blocker"
    - Smith, "DSP Guide", Ch. 16 (windowed-sinc / Kaiser halfband)

Run:
    python -m dsp.coefficients.tl_saturate         # writes data/tl_saturate_coefficients.json

The reference impl (`dsp/reference/tl_saturate.py`) computes the same
coefficients on-the-fly per sample-rate; this script vendors them so
the M4L `[js]` doesn't have to reimplement the cookbook formulas.
"""

from __future__ import annotations

import json
from pathlib import Path

# Re-use the reference impl's coefficient functions to guarantee that
# both layers (reference render and M4L runtime) see byte-identical
# coefficients.
import sys as _sys
_REF = Path(__file__).resolve().parent.parent / "reference"
_sys.path.insert(0, str(_REF))
from tl_saturate import (  # noqa: E402
    highshelf_coeffs,
    dc_blocker_R,
    design_halfband_fir,
    _INPUT_GAIN_DB,
)


SUPPORTED_SAMPLE_RATES = [44100, 48000, 88200, 96000]
SHELF_FC_HZ = 3000.0
SHELF_Q = 0.7
PRE_GAIN_DB = +4.0
POST_GAIN_DB = -4.0
DC_BLOCK_FC_HZ = 20.0
HALFBAND_TAPS = 31
HALFBAND_BETA = 8.0


def build_coefficients() -> dict:
    """Build the full coefficient JSON payload."""
    payload: dict = {
        "version": 1,
        "module": "tl_saturate",
        "description": (
            "Static coefficients for tl_saturate: RBJ high-shelf "
            "pre/de-emphasis at 3 kHz Q=0.7 (±4 dB), DC-blocker pole "
            "radius for 20 Hz cutoff, and a 31-tap halfband FIR for "
            "2× oversampling around the asymmetric tanh waveshaper."
        ),
        "shelf": {
            "fc_hz": SHELF_FC_HZ,
            "q": SHELF_Q,
            "pre_emphasis_gain_db": PRE_GAIN_DB,
            "de_emphasis_gain_db": POST_GAIN_DB,
        },
        "dc_blocker": {
            "fc_hz": DC_BLOCK_FC_HZ,
        },
        "halfband_fir": {
            "num_taps": HALFBAND_TAPS,
            "kaiser_beta": HALFBAND_BETA,
            "taps": [float(x) for x in design_halfband_fir(
                num_taps=HALFBAND_TAPS, cutoff_norm=0.5,
                beta=HALFBAND_BETA,
            )],
        },
        "input_gain_db": dict(_INPUT_GAIN_DB),
        "by_sample_rate": {},
    }

    for sr in SUPPORTED_SAMPLE_RATES:
        pre_b0, pre_b1, pre_b2, pre_a1, pre_a2 = highshelf_coeffs(
            fc=SHELF_FC_HZ, q=SHELF_Q, gain_db=PRE_GAIN_DB, sr=float(sr),
        )
        post_b0, post_b1, post_b2, post_a1, post_a2 = highshelf_coeffs(
            fc=SHELF_FC_HZ, q=SHELF_Q, gain_db=POST_GAIN_DB, sr=float(sr),
        )
        R = dc_blocker_R(sr=float(sr), fc=DC_BLOCK_FC_HZ)
        payload["by_sample_rate"][str(sr)] = {
            "pre_emphasis_biquad": {
                "b0": pre_b0, "b1": pre_b1, "b2": pre_b2,
                "a1": pre_a1, "a2": pre_a2,
            },
            "de_emphasis_biquad": {
                "b0": post_b0, "b1": post_b1, "b2": post_b2,
                "a1": post_a1, "a2": post_a2,
            },
            "dc_blocker_R": R,
        }

    return payload


def main() -> None:
    out = (Path(__file__).resolve().parent.parent.parent
           / "data" / "tl_saturate_coefficients.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    payload = build_coefficients()
    with out.open("w") as f:
        json.dump(payload, f, indent=2, sort_keys=False)
        f.write("\n")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
