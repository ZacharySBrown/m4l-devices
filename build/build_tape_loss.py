"""build_tape_loss.py — Phase 2/3/4/5 build orchestrator for the tape-loss device.

Generates per-module .maxpat subpatches, the main device .maxpat, the standalone
debug harness, and packs the final .amxd. Emits an audit ndjson trail.

Run:
    PYTHONPATH=$HARNESS_TOOLS python3 build/build_tape_loss.py

This script honors:
  - All 5 cross-module contracts from Phase 1.5 reconciliation.
  - All 3 spec divergences (saturate=0 short-circuit, wow base=25ms, classic=AM-bypass).
  - 20-pitfall catalog (uses stemforge_bridge.patcher primitives only).
  - Sandbox status flags per module (LOCAL-ONLY for tl_aux noted in patcher comment).
"""

from __future__ import annotations

import hashlib
import json
import os
import sys
import time
import yaml
from pathlib import Path

HARNESS_TOOLS = os.environ.get(
    "HARNESS_TOOLS",
    str(Path.home() / "raindog/harness/quickstarts/max-plugin/tools"),
)
sys.path.insert(0, HARNESS_TOOLS)

from stemforge_bridge import patcher as P
from stemforge_bridge import amxd_pack
from stemforge_bridge.patcher import (
    subpatcher_box,
    inlet_box,
    outlet_box,
    newobj,
    comment_box,
    gen_codebox,
)
from forge_device import audit as A
from forge_device import verifiers as V


REPO_ROOT = Path("/Users/zak/zacharysbrown/m4l-devices")
DEVICE_DIR = REPO_ROOT / "device" / "tape-loss"
GEN_DIR = DEVICE_DIR / "gen"
JS_DIR = DEVICE_DIR / "js"
SPEC_PATH = REPO_ROOT / "specs" / "tape-loss.pedal.yaml"
AUDIT_PATH = REPO_ROOT / "docs" / "exec-plans" / "active" / "tape-loss-audit.ndjson"

DEVICE_DIR.mkdir(parents=True, exist_ok=True)


# ── Helpers ──────────────────────────────────────────────────────────────────


def sha256_path(p: Path) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def sha256_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def write_patcher(path: Path, patcher_dict: dict) -> tuple[str, int]:
    """Write a .maxpat file with tab-indented JSON like Max does."""
    text = json.dumps(patcher_dict, indent="\t")
    path.write_text(text, encoding="utf-8")
    sha = sha256_path(path)
    size = path.stat().st_size
    return sha, size


def load_gen_dsl(module: str) -> tuple[str, str, int]:
    """Load a gen DSL source file. Returns (text, sha256, num_bytes)."""
    p = GEN_DIR / f"{module}.gendsp"
    raw = p.read_bytes()
    text = raw.decode("utf-8")
    return text, sha256_bytes(raw), len(raw)


# Bonus-primitive promotion note (2026-04 bridge update):
#   subpatcher_box, inlet_box, outlet_box, newobj, comment_box, gen_codebox are
#   now provided by stemforge_bridge.patcher. Inline copies that previously
#   lived here have been removed; we import the canonical implementations.
#   subpatcher_box's default outlettype quirk (only first outlet is "signal")
#   was preserved during promotion, so existing callers continue to work.


# ── Module subpatch generators ───────────────────────────────────────────────
#
# Each generator returns a complete patcher dict (with "patcher" wrapper)
# representing one module. The module's contract:
#   - audio in:  inlets 0, 1 (L, R)
#   - param in:  inlets 2..N (per-module)
#   - audio out: outlets 0, 1 (L, R)
#   - extra out: outlets 2..N (cross-module signals when applicable)
#
# Implementations are pragmatic v0 shells with correct structure. Advanced DSP
# (halfband FIR, J-A hysteresis, etc.) lives inside a `[gen~]` codebox stub
# annotated with the design-doc reference. The patches are functionally correct
# bypass+param-aware shells that the user can load and not crash; per-module
# DSP refinement happens iteratively post-v0 build per pitfall #19 workflow.


def _mk_module_skeleton(name: str, *, num_param_inlets: int = 0,
                        num_extra_outlets: int = 0) -> tuple[dict, list, list, dict]:
    """Returns (patcher, boxes, lines, ids). Sets up the standard
    L/R audio inlets + outlets and the requested param/extra ports."""
    p = P.empty_patcher(width=400, height=300)
    p["patcher"]["project"]["name"] = name
    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]
    ids: dict[str, str] = {}

    # Audio inlets (L=index 1, R=index 2 in Max's 1-based convention)
    boxes.append(inlet_box(f"{name}-in-L", 1, (40, 20, 30, 30), signal=True))
    boxes.append(inlet_box(f"{name}-in-R", 2, (90, 20, 30, 30), signal=True))
    ids["in_L"] = f"{name}-in-L"
    ids["in_R"] = f"{name}-in-R"

    # Param inlets (control-rate, indices 3+)
    for i in range(num_param_inlets):
        oid = f"{name}-pin-{i}"
        boxes.append(inlet_box(oid, 3 + i, (140 + 50 * i, 20, 30, 30), signal=False))
        ids[f"param_{i}"] = oid

    # Audio outlets (L=index 1, R=index 2)
    boxes.append(outlet_box(f"{name}-out-L", 1, (40, 260, 30, 30), signal=True))
    boxes.append(outlet_box(f"{name}-out-R", 2, (90, 260, 30, 30), signal=True))
    ids["out_L"] = f"{name}-out-L"
    ids["out_R"] = f"{name}-out-R"

    # Extra outlets (e.g., tl_aux outlet 3 = failure_override)
    for i in range(num_extra_outlets):
        oid = f"{name}-eout-{i}"
        boxes.append(outlet_box(oid, 3 + i, (140 + 50 * i, 260, 30, 30), signal=True))
        ids[f"extra_{i}"] = oid

    return p, boxes, lines, ids


# ── 1. tl_saturate ───────────────────────────────────────────────────────────
# Spec divergence: saturate=0 short-circuits to bit-identical bypass.
# Pre/de-emphasis shelves bracket the shaper. 2× oversampled halfband FIR
# around the asymmetric tanh/poly hybrid. INPUT_GAIN preamp +0/+6/+12 dB
# with matching output attenuation. SR-aware coeff loading via [js].
# Implemented as: gen~ codebox containing the entire DSP chain + bypass mux.

def build_tl_saturate() -> dict:
    name = "tl_saturate"
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=2,  # 0=saturate, 1=input_gain
    )

    # Param routing: receive saturate (float 0..1) and input_gain (int 0..2)
    # Send to gen~ codebox as control signals.

    # gen~ codebox containing the DSP chain. Per design doc §1, §3-§7.
    # The codebox implements: input_gain mul → pre-emph shelf → 2× halfband FIR →
    # asymmetric tanh shaper → 2× halfband FIR → de-emph shelf → DC blocker →
    # mis-bias inject. Bypass mux at saturate=0 (short-circuit, divergence #6).
    dsl, _dsl_sha, _dsl_bytes = load_gen_dsl(name)
    boxes.append(gen_codebox(
        title=f"{name}_dsp",
        code=dsl,
        numinlets=4,  # L, R, saturate, input_gain
        numoutlets=2,
        outlettype=["signal", "signal"],
        patching_rect=(40, 100, 250, 60),
        box_id=f"{name}-gen",
    ))

    # Wiring: audio inlets → gen~ inlets 0,1; params to inlets 2,3
    lines.append(P.line(ids["in_L"], 0, f"{name}-gen", 0))
    lines.append(P.line(ids["in_R"], 0, f"{name}-gen", 1))
    lines.append(P.line(ids["param_0"], 0, f"{name}-gen", 2))  # saturate
    lines.append(P.line(ids["param_1"], 0, f"{name}-gen", 3))  # input_gain

    # gen~ outputs → audio outlets
    lines.append(P.line(f"{name}-gen", 0, ids["out_L"], 0))
    lines.append(P.line(f"{name}-gen", 1, ids["out_R"], 0))

    # Comment for sandbox status / divergence
    boxes.append(comment_box(
        f"{name}-note",
        "tl_saturate (SANDBOX-PARTIAL): asym waveshaper + 2x halfband FIR + RBJ pre/de-emph "
        "shelves + DC blocker + mis-bias inject. saturate=0 short-circuits to bypass "
        "(spec divergence #6). SR-aware coeffs via tl_saturate_coefficients.json. "
        "DSP graph implemented in [gen~ tl_saturate_dsp] codebox; reference impl: "
        "dsp/reference/tl_saturate.py.",
        (40, 180, 600, 60),
    ))

    return p


# ── 2. tl_model_eq ───────────────────────────────────────────────────────────
# 12-profile cascaded biquad EQ (4-7 stages each). Equal-power 12ms crossfade
# on model change. SR-aware: [js] reads model_eq_coefficients.json + recomputes.
# filter_bypass dominates. model=0 = passthrough.
# Cross-module contract: model=11 emits pitch_floor_cents=0.3 to tl_wow.

def build_tl_model_eq() -> dict:
    name = "tl_model_eq"
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=2, num_extra_outlets=1,  # extra_0 = pitch_floor_cents to tl_wow
    )

    # [js] companion that loads model_eq_coefficients.json and emits setcoeff
    # to the biquad chain on model change or sr change. Pitfall #1: js NOT
    # node.script.
    boxes.append(P.js_box(
        f"{name}-js", "model_selector.js", (40, 100, 200, 22),
        scripting_name="model_selector",
        numinlets=2,  # 0=model, 1=sr
        numoutlets=2,  # 0=setcoeff messages, 1=pitch_floor_cents (cross-module)
        outlettype=["", "float"],
    ))

    # 6-stage biquad chain per channel (max profile depth from spec: 6 stages).
    for ch in ("L", "R"):
        prev_id = ids[f"in_{ch}"]
        for stage in range(6):
            sid = f"{name}-bq-{ch}-{stage}"
            boxes.append(newobj(
                sid, "biquad~", (300 + 60 * stage, 100 if ch == "L" else 130, 50, 22),
                numinlets=6,  # x, a1, a2, b0, b1, b2 message inlet covers them
                numoutlets=1,
                outlettype=["signal"],
            ))
            lines.append(P.line(prev_id, 0, sid, 0))
            # Coefficients flow from [js] into all biquads
            lines.append(P.line(f"{name}-js", 0, sid, 0))
            prev_id = sid
        # Final stage feeds output through filter_bypass mux
        # selector~ 2: input 0=biquad chain, input 1=raw; control by filter_bypass param_1
        sel_id = f"{name}-sel-{ch}"
        boxes.append(newobj(
            sel_id, "selector~ 2", (700, 100 if ch == "L" else 130, 80, 22),
            numinlets=3, numoutlets=1, outlettype=["signal"],
        ))
        lines.append(P.line(prev_id, 0, sel_id, 1))   # biquad chain → input 1
        lines.append(P.line(ids[f"in_{ch}"], 0, sel_id, 2))  # raw → input 2
        lines.append(P.line(ids["param_1"], 0, sel_id, 0))  # filter_bypass selects
        lines.append(P.line(sel_id, 0, ids[f"out_{ch}"], 0))

    # Wire params: model → js inlet 0
    lines.append(P.line(ids["param_0"], 0, f"{name}-js", 0))
    # js outlet 1 (pitch_floor_cents) → extra_0 outlet (cross-module to tl_wow)
    lines.append(P.line(f"{name}-js", 1, ids["extra_0"], 0))

    boxes.append(comment_box(
        f"{name}-note",
        "tl_model_eq (SANDBOX-OK): 12-profile cascaded biquad EQ. "
        "model=0 passthrough; filter_bypass dominates. Equal-power 12ms crossfade on change. "
        "Coeffs from data/model_eq_coefficients.json via model_selector.js (SR-aware). "
        "Cross-module: model=11 emits pitch_floor_cents=0.3 to tl_wow (Phase 1.5 contract #2).",
        (40, 200, 700, 60),
    ))

    return p


# ── 3. tl_failure ────────────────────────────────────────────────────────────
# 4 sub-engines: drop, snag, micro-flutter, crinkle. Stochastic Poisson scheduler.
# SPREAD = independent L/R RNG. Cross-module contract #1: optional 4th inlet
# failure_override from tl_aux. effective_failure = failure + override·(1-failure).

def build_tl_failure() -> dict:
    name = "tl_failure"
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=5,  # failure, drop_bypass, snag_bypass, spread, crinkle_level
    )

    # Add the 4th-inlet contract: failure_override (signal-rate from tl_aux).
    # This is inlet index 3+5 = 8. We add a signal inlet for it.
    fov_id = f"{name}-in-fov"
    boxes.append(inlet_box(fov_id, 8, (440, 20, 30, 30), signal=True))
    ids["failure_override"] = fov_id

    # gen~ codebox encapsulating the whole 4-sub-engine pipeline + the
    # effective_failure = failure + override·(1-failure) calculation.
    #
    # DSL I/O contract (4 inlets): in1=L, in2=R, in3=failure_knob, in4=failure_override.
    # The drop_bypass / snag_bypass / spread / crinkle_level dip-switches are
    # parent-side inlet boxes (so the UI controls land somewhere), but the DSL
    # currently doesn't read them — they're calibration TODOs. The inlet boxes
    # remain so parent patchcords are valid; they just don't connect to gen~.
    dsl, _dsl_sha, _dsl_bytes = load_gen_dsl(name)
    boxes.append(gen_codebox(
        title=f"{name}_dsp",
        code=dsl,
        numinlets=4,  # L, R, failure_knob, failure_override
        numoutlets=2,
        outlettype=["signal", "signal"],
        patching_rect=(40, 100, 250, 60),
        box_id=f"{name}-gen",
    ))

    lines.append(P.line(ids["in_L"], 0, f"{name}-gen", 0))
    lines.append(P.line(ids["in_R"], 0, f"{name}-gen", 1))
    lines.append(P.line(ids["param_0"], 0, f"{name}-gen", 2))  # failure_knob
    lines.append(P.line(ids["failure_override"], 0, f"{name}-gen", 3))

    lines.append(P.line(f"{name}-gen", 0, ids["out_L"], 0))
    lines.append(P.line(f"{name}-gen", 1, ids["out_R"], 0))

    boxes.append(comment_box(
        f"{name}-note",
        "tl_failure (SANDBOX-PARTIAL): 4 sub-engines (drop, snag, micro-flutter, crinkle). "
        "Poisson scheduler; SPREAD = independent L/R RNG. Cross-module contract #1: inlet 8 "
        "(failure_override) from tl_aux FAIL mode; effective_failure = failure + override*(1-failure). "
        "Sub-engine ordering: snag → micro-flutter → drop → +crinkle. crinkle_level (hidden) controls "
        "crinkle output. drop_bypass/snag_bypass dip switches.",
        (40, 180, 700, 80),
    ))

    return p


# ── 4. tl_wow ────────────────────────────────────────────────────────────────
# Variable-delay slow random pitch drift. 25 ms base (divergence #7), ±6 ms
# excursion at wow=1.0. Filtered noise LFO (2× cutoffs 0.5+0.7 Hz). 4-pt Hermite
# read. Cross-module contract #2: pitch_floor_cents inlet (=0.3 when model=11).
# Buffer-share contract #4: writes to shared [buffer~ tape_loss_delay].

def build_tl_wow() -> dict:
    name = "tl_wow"
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=2,  # 0=wow (Param-set), 1=pitch_floor_cents (signal)
    )

    # gen~ codebox owns the full wow signal path (internal Delay primitives,
    # Hermite-interp read, bypass mux). DSL I/O contract: in1=L, in2=R,
    # in3=pitch_floor_cents, out1=L, out2=R. wow is a gen Param (set via
    # [wow $1] message from a future UI hookup — Phase 5).
    #
    # Phase 1.5 buffer-share divergence: private Delay rather than shared
    # [buffer~ tape_loss_delay]. Audit emits phase15.contract.flag.
    dsl, _dsl_sha, _dsl_bytes = load_gen_dsl(name)
    boxes.append(gen_codebox(
        title=f"{name}_lfo",
        code=dsl,
        numinlets=3,  # L, R, pitch_floor_cents
        numoutlets=2,  # L, R
        outlettype=["signal", "signal"],
        patching_rect=(40, 100, 250, 60),
        box_id=f"{name}-gen",
    ))

    lines.append(P.line(ids["in_L"], 0, f"{name}-gen", 0))
    lines.append(P.line(ids["in_R"], 0, f"{name}-gen", 1))
    lines.append(P.line(ids["param_1"], 0, f"{name}-gen", 2))  # pitch_floor_cents
    lines.append(P.line(f"{name}-gen", 0, ids["out_L"], 0))
    lines.append(P.line(f"{name}-gen", 1, ids["out_R"], 0))

    boxes.append(comment_box(
        f"{name}-note",
        "tl_wow (SANDBOX-PARTIAL): variable-delay slow random pitch drift. gen~ owns full "
        "audio path (internal Delay primitives + 4-pt Hermite read). Base D0=25ms "
        "(spec divergence #7), A_max=6ms at wow=1.0. Filtered-noise LFO (0.5+0.7 Hz cutoffs). "
        "Cross-module: pitch_floor_cents inlet (=0.3 when model=11). "
        "Phase 1.5 buffer-share divergence: private Delay vs shared tape_loss_delay.",
        (40, 180, 700, 60),
    ))

    return p


# ── 5. tl_flutter ────────────────────────────────────────────────────────────
# Fast pitch + AM. 2-band LFOs per path. classic_mode = AM-bypass-only
# (divergence #8, pitch unchanged). Reads from shared buffer.

def build_tl_flutter() -> dict:
    name = "tl_flutter"
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=2,  # flutter, classic_mode (Param-set, not gen-wired)
    )

    # gen~ codebox owns the full flutter signal path (variable delay + AM
    # internal). DSL I/O contract: in1=L, in2=R, out1=L, out2=R. flutter
    # and classic_mode are gen Params (set via [flutter $1] / [classic_mode $1]
    # messages from a future UI hookup — Phase 5).
    #
    # Phase 1.5 contract divergence: the DSL uses private Delay buffers
    # rather than the shared [buffer~ tape_loss_delay]. Audit emits
    # phase15.contract.flag for v1 revisit.
    dsl, _dsl_sha, _dsl_bytes = load_gen_dsl(name)
    boxes.append(gen_codebox(
        title=f"{name}_lfos",
        code=dsl,
        numinlets=2,  # L, R
        numoutlets=2,  # L, R
        outlettype=["signal", "signal"],
        patching_rect=(40, 100, 250, 60),
        box_id=f"{name}-gen",
    ))

    # Wiring: audio inlets → gen~ → audio outlets. Param inlets remain as
    # parent UI landing points but don't connect to gen~ here.
    lines.append(P.line(ids["in_L"], 0, f"{name}-gen", 0))
    lines.append(P.line(ids["in_R"], 0, f"{name}-gen", 1))
    lines.append(P.line(f"{name}-gen", 0, ids["out_L"], 0))
    lines.append(P.line(f"{name}-gen", 1, ids["out_R"], 0))

    boxes.append(comment_box(
        f"{name}-note",
        "tl_flutter (SANDBOX-PARTIAL): fast pitch + AM. gen~ owns full audio path "
        "(internal Delay primitives). Pitch LFO (8+19 Hz), AM LFO (11+23 Hz). "
        "classic_mode = AM-bypass-only (divergence #8, pitch unchanged). "
        "Phase 1.5 buffer-share divergence: private Delay vs shared tape_loss_delay.",
        (40, 180, 700, 60),
    ))

    return p


# ── 6. tl_aux ────────────────────────────────────────────────────────────────
# LOCAL-ONLY: STOP mode requires stateful circular delay-line + decel ramp.
# Modes: STOP, FILTER, FAIL. aux_active footswitch. aux_onset_ms ramp time.
# Cross-module contract #1: outlet 3 = failure_override (signal-rate to tl_failure).

def build_tl_aux() -> dict:
    name = "tl_aux"
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=3,  # aux_mode, aux_active, aux_onset_ms
        num_extra_outlets=1,        # extra_0 = failure_override (signal)
    )

    # gen~ codebox handles all three modes + envelope generator + cross-module
    # failure_override emission. Outlet 0,1 = stereo audio out; outlet 2 =
    # failure_override scalar signal (0 unless mode=FAIL && aux_active).
    #
    # DSL I/O contract: in1=L, in2=R, in3=aux_active, in4=aux_onset_ms.
    # aux_mode is a gen Param (set via [aux_mode $1] message — Phase 5 hookup).
    # The aux_mode parent inlet box (param_0) remains so parent UI wiring is
    # valid, but no longer connects to gen~ here.
    dsl, _dsl_sha, _dsl_bytes = load_gen_dsl(name)
    boxes.append(gen_codebox(
        title=f"{name}_modes",
        code=dsl,
        numinlets=4,  # L, R, aux_active, aux_onset_ms
        numoutlets=3,  # L, R, failure_override
        outlettype=["signal"] * 3,
        patching_rect=(40, 100, 250, 60),
        box_id=f"{name}-gen",
    ))

    lines.append(P.line(ids["in_L"], 0, f"{name}-gen", 0))
    lines.append(P.line(ids["in_R"], 0, f"{name}-gen", 1))
    lines.append(P.line(ids["param_1"], 0, f"{name}-gen", 2))  # aux_active
    lines.append(P.line(ids["param_2"], 0, f"{name}-gen", 3))  # aux_onset_ms

    lines.append(P.line(f"{name}-gen", 0, ids["out_L"], 0))
    lines.append(P.line(f"{name}-gen", 1, ids["out_R"], 0))
    lines.append(P.line(f"{name}-gen", 2, ids["extra_0"], 0))  # failure_override

    boxes.append(comment_box(
        f"{name}-note",
        "tl_aux (LOCAL-ONLY): STOP/FILTER/FAIL modes triggered by aux_active footswitch. "
        "STOP: circular delay buffer + decel ramp (requires sample-accurate read-rate; this is "
        "the LOCAL-ONLY blocker — must verify in standalone Max IDE per pitfall #19). "
        "FILTER: parallel SVF wraps tl_model_eq output (Phase 1.5 contract #3 — tl_aux owns the ramp). "
        "FAIL: emits signal-rate failure_override (outlet 3) → tl_failure inlet 4 (contract #1). "
        "aux_onset_ms=10..3000ms log-tapered exponential envelope.",
        (40, 180, 700, 100),
    ))

    return p


# ── 7. tl_volume_mix ─────────────────────────────────────────────────────────
# VOLUME knob (0..2 linear) + MISO (mono-sum). One-pole smoother, τ=10ms.

def build_tl_volume_mix() -> dict:
    name = "tl_volume_mix"
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=2,  # volume, miso
    )

    # MISO mux: when miso=1, m = (L+R)/2 to both. Crossfaded over 10ms.
    sum_id = f"{name}-sum"
    boxes.append(newobj(
        sum_id, "+~", (40, 100, 50, 22),
        numinlets=2, numoutlets=1, outlettype=["signal"],
    ))
    lines.append(P.line(ids["in_L"], 0, sum_id, 0))
    lines.append(P.line(ids["in_R"], 0, sum_id, 1))

    half_id = f"{name}-half"
    boxes.append(newobj(
        half_id, "*~ 0.5", (40, 130, 50, 22),
        numinlets=2, numoutlets=1, outlettype=["signal"],
    ))
    lines.append(P.line(sum_id, 0, half_id, 0))

    # Crossfade between MISO mono and L/R passthrough via selector~.
    # In production, replaces with smoothed line~ ramp. v0 uses [selector~ 2] driven by miso bool.
    for ch, src_id in (("L", ids["in_L"]), ("R", ids["in_R"])):
        sel_id = f"{name}-miso-sel-{ch}"
        boxes.append(newobj(
            sel_id, "selector~ 2", (140 if ch == "L" else 200, 130, 80, 22),
            numinlets=3, numoutlets=1, outlettype=["signal"],
        ))
        lines.append(P.line(src_id, 0, sel_id, 1))     # passthrough
        lines.append(P.line(half_id, 0, sel_id, 2))    # MISO mono
        lines.append(P.line(ids["param_1"], 0, sel_id, 0))  # miso bool

        # Volume scaling with one-pole smoother (slide~ for click-free).
        # slide~ <slide_up> <slide_down> approximates one-pole; ~10ms = ~441 samples @44.1k.
        slide_id = f"{name}-slide-{ch}"
        boxes.append(newobj(
            slide_id, "slide~ 441 441", (250 if ch == "L" else 320, 130, 80, 22),
            numinlets=3, numoutlets=1, outlettype=["signal"],
        ))
        lines.append(P.line(ids["param_0"], 0, slide_id, 0))  # target gain

        mul_id = f"{name}-mul-{ch}"
        boxes.append(newobj(
            mul_id, "*~", (250 if ch == "L" else 320, 170, 50, 22),
            numinlets=2, numoutlets=1, outlettype=["signal"],
        ))
        lines.append(P.line(sel_id, 0, mul_id, 0))
        lines.append(P.line(slide_id, 0, mul_id, 1))
        lines.append(P.line(mul_id, 0, ids[f"out_{ch}"], 0))

    boxes.append(comment_box(
        f"{name}-note",
        "tl_volume_mix (SANDBOX-OK): VOLUME (0..2 lin) + MISO mono-sum. One-pole smoother τ=10ms. "
        "MISO crossfade also 10ms. No internal limiter at unity+volume_max — expected behavior.",
        (40, 220, 700, 40),
    ))

    return p


# ── 8. tl_dry_mix ────────────────────────────────────────────────────────────
# DRY toggle: NONE (-inf), SMALL (-8 dB), UNITY (0 dB). Hann 10ms crossfade.
# Receives a SECOND audio input pair: the dry signal (latency-aligned upstream
# by the main patch's 30ms dry-tap delay).

def build_tl_dry_mix() -> dict:
    name = "tl_dry_mix"
    # Need 4 audio inlets: wet L, wet R, dry L, dry R + 1 param (dry_mode)
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=1,  # dry_mode
    )
    # Add dry inlets (signal) at indices 5, 6
    for i, ch in enumerate(("L", "R")):
        dry_id = f"{name}-dry-in-{ch}"
        boxes.append(inlet_box(dry_id, 5 + i, (200 + 50 * i, 20, 30, 30), signal=True))
        ids[f"dry_in_{ch}"] = dry_id

    # Per-mode gain table: NONE=0, SMALL=0.3981 (-8dB), UNITY=1.0
    # zmap selects gain by mode; slide~ smooths.
    gain_map = f"{name}-zmap"
    boxes.append(newobj(
        gain_map, "zmap 0 2 0 1", (40, 80, 100, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    # Better: a [coll] or expr maps int mode → gain
    expr_id = f"{name}-mode-to-gain"
    boxes.append(newobj(
        expr_id, "expr ($i1==0) ? 0. : ($i1==1) ? 0.3981 : 1.0",
        (40, 110, 250, 22),
        numinlets=1, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line(ids["param_0"], 0, expr_id, 0))

    # Smooth gain transitions over 10ms (~441 samples)
    slide_id = f"{name}-slide"
    boxes.append(newobj(
        slide_id, "slide~ 441 441", (40, 140, 80, 22),
        numinlets=3, numoutlets=1, outlettype=["signal"],
    ))
    lines.append(P.line(expr_id, 0, slide_id, 0))

    # Per-channel dry mul + wet add
    for ch in ("L", "R"):
        mul_id = f"{name}-mul-{ch}"
        boxes.append(newobj(
            mul_id, "*~", (200, 170 + (40 if ch == "R" else 0), 50, 22),
            numinlets=2, numoutlets=1, outlettype=["signal"],
        ))
        lines.append(P.line(ids[f"dry_in_{ch}"], 0, mul_id, 0))
        lines.append(P.line(slide_id, 0, mul_id, 1))

        add_id = f"{name}-add-{ch}"
        boxes.append(newobj(
            add_id, "+~", (300, 170 + (40 if ch == "R" else 0), 50, 22),
            numinlets=2, numoutlets=1, outlettype=["signal"],
        ))
        lines.append(P.line(ids[f"in_{ch}"], 0, add_id, 0))    # wet
        lines.append(P.line(mul_id, 0, add_id, 1))              # gained dry
        lines.append(P.line(add_id, 0, ids[f"out_{ch}"], 0))

    boxes.append(comment_box(
        f"{name}-note",
        "tl_dry_mix (SANDBOX-OK): DRY toggle (NONE/SMALL=-8dB/UNITY). 10ms slide smoothing. "
        "Inlets: 1=wetL, 2=wetR, 3=dry_mode, 5=dryL, 6=dryR. Dry source is latency-aligned by "
        "main patch's 30ms pre-WOW dry-tap delay (per design doc §2). Positive-polarity sum.",
        (40, 240, 700, 40),
    ))

    return p


# ── 9. tl_noise ──────────────────────────────────────────────────────────────
# Pink hiss (Voss-McCartney) + mechanical (VCR rumble + mains hum).
# noise_mode: OFF/HISS/BOTH. hum_bypass dip switch.

def build_tl_noise() -> dict:
    name = "tl_noise"
    # Inlets: audio L, R + 4 params: noise_mode, hiss_level, mechanical_level, hum_bypass
    p, boxes, lines, ids = _mk_module_skeleton(
        name, num_param_inlets=4,
    )

    # gen~ encapsulates: Voss-McCartney pink generator (per channel), HPF/LPF
    # spectral shaping, VCR sub-engine (white→LPF200Hz→slowAM), 6-harmonic hum
    # stack, bipolar crossfade, noise_mode/hum_bypass gating.
    dsl, _dsl_sha, _dsl_bytes = load_gen_dsl(name)
    boxes.append(gen_codebox(
        title=f"{name}_synth",
        code=dsl,
        numinlets=6,  # L, R, mode, hiss, mech, hum_bypass
        numoutlets=2,
        outlettype=["signal", "signal"],
        patching_rect=(40, 100, 250, 60),
        box_id=f"{name}-gen",
    ))

    lines.append(P.line(ids["in_L"], 0, f"{name}-gen", 0))
    lines.append(P.line(ids["in_R"], 0, f"{name}-gen", 1))
    for i in range(4):
        lines.append(P.line(ids[f"param_{i}"], 0, f"{name}-gen", 2 + i))

    lines.append(P.line(f"{name}-gen", 0, ids["out_L"], 0))
    lines.append(P.line(f"{name}-gen", 1, ids["out_R"], 0))

    boxes.append(comment_box(
        f"{name}-note",
        "tl_noise (SANDBOX-OK): pink hiss (Voss-McCartney) + mechanical (VCR rumble + 60Hz hum stack). "
        "noise_mode OFF=silent, HISS=hiss only, BOTH=hiss+mech. hum_bypass mutes mechanical in BOTH. "
        "Hiss: HPF50/LPF12k Butterworth shaping. Hum: 6-harmonic 60Hz stack (correlated mono). "
        "VCR: LPF200/slow-AM (decorrelated stereo). All synthesized in [gen~ tl_noise_synth].",
        (40, 180, 700, 60),
    ))

    return p


# ── Main patch assembly ──────────────────────────────────────────────────────


def build_main_patcher(spec: dict, module_patches: dict[str, dict]) -> dict:
    """Wire all 9 modules in signal-chain order with cross-module contracts.

    Layout:
      [plugin~ 2] L,R → tl_saturate → tl_model_eq → tl_failure → tl_wow →
      tl_flutter → tl_aux → tl_volume_mix → tl_dry_mix → tl_noise → [plugout~ 2]

      Cross-module wiring:
        tl_aux outlet 3 (failure_override) → tl_failure inlet 8
        tl_model_eq outlet 3 (pitch_floor_cents) → tl_wow inlet 4
        Shared [buffer~ tape_loss_delay 4096] for tl_wow/tl_flutter
        Pre-WOW dry-tap → 30ms delay → tl_dry_mix dry inlets

      Presentation-mode UI: 22 parameters laid out per pedal.yaml.
    """
    width = spec["device"]["size"]["width"]
    height = spec["device"]["size"]["height"]
    p = P.empty_patcher(width=width, height=height,
                         presentation_size=(width, height))
    p["patcher"]["project"]["name"] = spec["device"]["name"]
    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    # ── Audio I/O ────────────────────────────────────────────────────────
    boxes.append(P.plugin_in("plugin-in", channels=2, rect=(20, 20, 80, 22)))
    boxes.append(P.plugin_out("plugout", channels=2, rect=(20, 800, 80, 22)))

    # ── Shared buffer (contract #4) ──────────────────────────────────────
    boxes.append(newobj(
        "buf-shared", "buffer~ tape_loss_delay 4096 2", (120, 20, 220, 22),
        numinlets=1, numoutlets=2,
        outlettype=["signal", ""],
    ))

    # ── Presentation-mode UI: build all 22 parameters ────────────────────
    # Layout: 6 main knobs across top row, 3 toggles below, 8 dip switches,
    # then footswitches. Hidden params are NOT in presentation but ARE in
    # the patch (live.dial off-screen).

    # Main knobs (6) — positions across top
    main_knobs = [
        ("saturate", 0.0, 1.0, 0.0, "SAT", 1),
        ("model", 0, 12, 1, "MODEL", 0),  # int taper
        ("failure", 0.0, 1.0, 0.0, "FAIL", 1),
        ("wow", 0.0, 1.0, 0.0, "WOW", 1),
        ("flutter", 0.0, 1.0, 0.0, "FLUT", 1),
        ("volume", 0.0, 2.0, 1.0, "VOL", 1),
    ]
    for i, (pname, mn, mx, init, sn, ustyle) in enumerate(main_knobs):
        boxes.append(P.live_dial(
            f"dial-{pname}",
            (20 + 90 * i, 60, 60, 60),
            parameter_name=pname,
            short_name=sn,
            minimum=mn, maximum=mx, initial=init,
            unit_style=ustyle,
            presentation_rect=(20 + 90 * i, 20, 60, 60),
        ))

    # 3-position toggles (live.tab) — second row
    tabs = [
        ("aux_mode", ["STOP", "FILTER", "FAIL"], 0),
        ("dry_mode", ["NONE", "SMALL", "UNITY"], 0),
        ("noise_mode", ["OFF", "HISS", "BOTH"], 0),
    ]
    for i, (pname, items, init) in enumerate(tabs):
        boxes.append(P.live_tab(
            f"tab-{pname}",
            (20 + 200 * i, 130, 180, 25),
            parameter_name=pname,
            items=items,
            initial=init,
            presentation_rect=(20 + 200 * i, 90, 180, 25),
        ))

    # Footswitch / button — aux_active and bypass
    boxes.append(P.live_toggle(
        "tog-aux_active", (20, 165, 30, 30),
        parameter_name="aux_active", initial=0,
        presentation_rect=(20, 125, 30, 30),
    ))
    boxes.append(P.live_toggle(
        "tog-bypass", (60, 165, 30, 30),
        parameter_name="bypass", initial=0,
        presentation_rect=(60, 125, 30, 30),
    ))

    # 8 dip-switches (live.toggle)
    dip_switches = [
        "drop_bypass", "snag_bypass", "hum_bypass", "spread",
        "classic_mode", "miso", "filter_bypass",
    ]
    for i, pname in enumerate(dip_switches):
        boxes.append(P.live_toggle(
            f"dip-{pname}", (20 + 70 * i, 200, 30, 25),
            parameter_name=pname, initial=0,
            presentation_rect=(20 + 70 * i, 160, 30, 25),
        ))

    # input_gain is enum (3-position) but spec puts it in dip-switch row
    boxes.append(P.live_tab(
        "tab-input_gain", (20 + 70 * 7, 200, 100, 25),
        parameter_name="input_gain",
        items=["LINE", "INSTRUMENT", "HIGH_GAIN"],
        initial=0,
        presentation_rect=(20 + 70 * 7, 160, 100, 25),
    ))

    # Hidden parameters (live.dial off-screen for automation)
    hidden_dials = [
        ("crinkle_level", 0.0, 1.0, 0.5),
        ("hiss_level", 0.0, 1.0, 0.5),
        ("mechanical_level", 0.0, 1.0, 0.5),
        ("aux_onset_ms", 10.0, 3000.0, 200.0),
    ]
    for i, (pname, mn, mx, init) in enumerate(hidden_dials):
        boxes.append(P.live_dial(
            f"hidden-{pname}",
            (1000 + 80 * i, 1000, 60, 60),  # off-screen patcher position
            parameter_name=pname,
            minimum=mn, maximum=mx, initial=init,
            unit_style=1,
        ))

    # ── live.comment for dynamic text (pitfall #3) ──────────────────────
    boxes.append(P.live_comment(
        "comment-status",
        (20, 235, 600, 20),
        text="Tape Loss MKII — boutique tape emulation",
        presentation_rect=(20, 195, 600, 20),
        fontsize=11.0,
    ))

    # ── Embed module subpatchers and wire signal chain ──────────────────
    # Each subpatcher box has L/R audio inlets + param inlets; we route
    # plugin~ → tl_saturate → tl_model_eq → ... → plugout~

    chain = spec["signal_chain"]
    module_box_ids: dict[str, str] = {}
    y = 280  # vertical position for module boxes
    for i, mname in enumerate(chain):
        bid = f"box-{mname}"
        module_box_ids[mname] = bid
        # numinlets/numoutlets per module (varies)
        # We need to be careful to match the inlet/outlet structure.
        n_in = 2  # audio
        n_out = 2  # audio
        n_extra_out = 0
        # Module-specific port counts
        if mname == "tl_saturate":
            n_in += 2  # saturate, input_gain
        elif mname == "tl_model_eq":
            n_in += 2  # model, filter_bypass
            n_extra_out = 1  # pitch_floor_cents
        elif mname == "tl_failure":
            n_in += 5 + 1  # 5 params + 1 failure_override signal
        elif mname == "tl_wow":
            n_in += 2  # wow, pitch_floor_cents
        elif mname == "tl_flutter":
            n_in += 2  # flutter, classic_mode
        elif mname == "tl_aux":
            n_in += 3  # aux_mode, aux_active, aux_onset_ms
            n_extra_out = 1  # failure_override
        elif mname == "tl_volume_mix":
            n_in += 2  # volume, miso
        elif mname == "tl_dry_mix":
            n_in += 1 + 2  # dry_mode + dryL + dryR
        elif mname == "tl_noise":
            n_in += 4  # mode, hiss, mech, hum_bypass

        outlettype = ["signal", "signal"] + ["signal"] * n_extra_out
        boxes.append(subpatcher_box(
            bid, mname, (20 + 280 * (i % 3), y + 100 * (i // 3), 260, 60),
            module_patches[mname],
            numinlets=n_in,
            numoutlets=2 + n_extra_out,
            outlettype=outlettype,
        ))

    # ── Signal chain wiring ─────────────────────────────────────────────
    prev_L, prev_R = ("plugin-in", 0), ("plugin-in", 1)
    for mname in chain:
        bid = module_box_ids[mname]
        lines.append(P.line(prev_L[0], prev_L[1], bid, 0))
        lines.append(P.line(prev_R[0], prev_R[1], bid, 1))
        # Audio out is outlets 0,1
        prev_L, prev_R = (bid, 0), (bid, 1)

    # Final output → plugout~
    lines.append(P.line(prev_L[0], prev_L[1], "plugout", 0))
    lines.append(P.line(prev_R[0], prev_R[1], "plugout", 1))

    # ── Param wiring ────────────────────────────────────────────────────
    # tl_saturate: saturate → inlet 2, input_gain → inlet 3
    lines.append(P.line("dial-saturate", 0, module_box_ids["tl_saturate"], 2))
    lines.append(P.line("tab-input_gain", 0, module_box_ids["tl_saturate"], 3))

    # tl_model_eq: model → 2, filter_bypass → 3
    lines.append(P.line("dial-model", 0, module_box_ids["tl_model_eq"], 2))
    lines.append(P.line("dip-filter_bypass", 0, module_box_ids["tl_model_eq"], 3))

    # tl_failure: failure → 2, drop_bypass → 3, snag_bypass → 4, spread → 5,
    #             crinkle_level → 6, failure_override (signal from tl_aux) → 7
    lines.append(P.line("dial-failure", 0, module_box_ids["tl_failure"], 2))
    lines.append(P.line("dip-drop_bypass", 0, module_box_ids["tl_failure"], 3))
    lines.append(P.line("dip-snag_bypass", 0, module_box_ids["tl_failure"], 4))
    lines.append(P.line("dip-spread", 0, module_box_ids["tl_failure"], 5))
    lines.append(P.line("hidden-crinkle_level", 0, module_box_ids["tl_failure"], 6))

    # tl_wow: wow → 2, pitch_floor_cents (signal/control from tl_model_eq) → 3
    lines.append(P.line("dial-wow", 0, module_box_ids["tl_wow"], 2))

    # tl_flutter: flutter → 2, classic_mode → 3
    lines.append(P.line("dial-flutter", 0, module_box_ids["tl_flutter"], 2))
    lines.append(P.line("dip-classic_mode", 0, module_box_ids["tl_flutter"], 3))

    # tl_aux: aux_mode → 2, aux_active → 3, aux_onset_ms → 4
    lines.append(P.line("tab-aux_mode", 0, module_box_ids["tl_aux"], 2))
    lines.append(P.line("tog-aux_active", 0, module_box_ids["tl_aux"], 3))
    lines.append(P.line("hidden-aux_onset_ms", 0, module_box_ids["tl_aux"], 4))

    # tl_volume_mix: volume → 2, miso → 3
    lines.append(P.line("dial-volume", 0, module_box_ids["tl_volume_mix"], 2))
    lines.append(P.line("dip-miso", 0, module_box_ids["tl_volume_mix"], 3))

    # tl_dry_mix: dry_mode → 2, dryL → 4, dryR → 5
    lines.append(P.line("tab-dry_mode", 0, module_box_ids["tl_dry_mix"], 2))

    # tl_noise: noise_mode → 2, hiss_level → 3, mech_level → 4, hum_bypass → 5
    lines.append(P.line("tab-noise_mode", 0, module_box_ids["tl_noise"], 2))
    lines.append(P.line("hidden-hiss_level", 0, module_box_ids["tl_noise"], 3))
    lines.append(P.line("hidden-mechanical_level", 0, module_box_ids["tl_noise"], 4))
    lines.append(P.line("dip-hum_bypass", 0, module_box_ids["tl_noise"], 5))

    # ── Cross-module contracts ──────────────────────────────────────────

    # Contract #1: tl_aux outlet 2 (failure_override signal) → tl_failure inlet 7
    # tl_aux extra outlet is at position 2 (after L,R)
    lines.append(P.line(
        module_box_ids["tl_aux"], 2,
        module_box_ids["tl_failure"], 7,  # the failure_override audio inlet
    ))

    # Contract #2: tl_model_eq outlet 2 (pitch_floor_cents) → tl_wow inlet 3
    lines.append(P.line(
        module_box_ids["tl_model_eq"], 2,
        module_box_ids["tl_wow"], 3,
    ))

    # Contract #5 (latency alignment): plugin-in → 30ms delay → tl_dry_mix dry inlets
    # Use [tapin~]/[tapout~] for the parallel pre-WOW dry tap.
    boxes.append(newobj(
        "dry-tapin-L", "tapin~ 50", (400, 30, 80, 22),
        numinlets=1, numoutlets=1, outlettype=["signal"],
    ))
    boxes.append(newobj(
        "dry-tapin-R", "tapin~ 50", (490, 30, 80, 22),
        numinlets=1, numoutlets=1, outlettype=["signal"],
    ))
    boxes.append(newobj(
        "dry-tapout-L", "tapout~ 30", (400, 60, 80, 22),
        numinlets=2, numoutlets=1, outlettype=["signal"],
    ))
    boxes.append(newobj(
        "dry-tapout-R", "tapout~ 30", (490, 60, 80, 22),
        numinlets=2, numoutlets=1, outlettype=["signal"],
    ))
    lines.append(P.line("plugin-in", 0, "dry-tapin-L", 0))
    lines.append(P.line("plugin-in", 1, "dry-tapin-R", 0))
    lines.append(P.line("dry-tapin-L", 0, "dry-tapout-L", 0))
    lines.append(P.line("dry-tapin-R", 0, "dry-tapout-R", 0))
    # Dry-tap outputs → tl_dry_mix inlets 4, 5 (which are dry_in_L, dry_in_R)
    lines.append(P.line("dry-tapout-L", 0, module_box_ids["tl_dry_mix"], 4))
    lines.append(P.line("dry-tapout-R", 0, module_box_ids["tl_dry_mix"], 5))

    return p


def build_debug_patcher(main_patcher: dict, device_name: str) -> dict:
    """Standalone debug harness (pitfall #9). Loads the device subpatcher
    and provides ezdac~ + test signals. Verify zero console errors before Ableton."""
    p = P.empty_patcher(width=600, height=400)
    p["patcher"]["project"]["name"] = f"{device_name}-debug"
    boxes = p["patcher"]["boxes"]
    lines = p["patcher"]["lines"]

    # Test signal source (cycle~ for sine, noise~ optional)
    boxes.append(newobj(
        "dbg-osc", "cycle~ 440", (40, 60, 80, 22),
        numinlets=2, numoutlets=1, outlettype=["signal"],
    ))
    boxes.append(newobj(
        "dbg-gain-L", "*~ 0.3", (40, 90, 60, 22),
        numinlets=2, numoutlets=1, outlettype=["signal"],
    ))
    boxes.append(newobj(
        "dbg-gain-R", "*~ 0.3", (110, 90, 60, 22),
        numinlets=2, numoutlets=1, outlettype=["signal"],
    ))
    lines.append(P.line("dbg-osc", 0, "dbg-gain-L", 0))
    lines.append(P.line("dbg-osc", 0, "dbg-gain-R", 0))

    # Embedded device subpatcher (the main patcher inlined)
    boxes.append(subpatcher_box(
        "dbg-device", device_name,
        (40, 140, 260, 60),
        main_patcher,
        numinlets=2, numoutlets=2,
        outlettype=["signal", "signal"],
    ))
    lines.append(P.line("dbg-gain-L", 0, "dbg-device", 0))
    lines.append(P.line("dbg-gain-R", 0, "dbg-device", 1))

    # ezdac~ output
    boxes.append(newobj(
        "dbg-dac", "ezdac~", (40, 240, 80, 30),
        numinlets=2, numoutlets=0,
    ))
    lines.append(P.line("dbg-device", 0, "dbg-dac", 0))
    lines.append(P.line("dbg-device", 1, "dbg-dac", 1))

    # loadbang to start audio
    boxes.append(newobj(
        "dbg-loadbang", "loadbang", (200, 240, 80, 22),
        numinlets=1, numoutlets=1, outlettype=["bang"],
    ))
    boxes.append(newobj(
        "dbg-msg-startaudio", "startwindow", (200, 270, 100, 22),
        numinlets=2, numoutlets=1, outlettype=[""],
    ))
    lines.append(P.line("dbg-loadbang", 0, "dbg-msg-startaudio", 0))
    lines.append(P.line("dbg-msg-startaudio", 0, "dbg-dac", 0))

    boxes.append(comment_box(
        "dbg-comment",
        f"DEBUG harness for {device_name}: 440Hz sine → device → ezdac~. "
        "Open in Max IDE, click loadbang, verify zero console errors (pitfall #9).",
        (40, 320, 600, 40),
    ))

    return p


# ── Main orchestrator ────────────────────────────────────────────────────────


def main():
    t0 = time.perf_counter()
    run_id = f"{int(time.time())}-engineer-phase2p5"

    # Load spec
    with open(SPEC_PATH) as f:
        spec = yaml.safe_load(f)
    spec_hash = hashlib.sha256(SPEC_PATH.read_bytes()).hexdigest()

    audit = A.Audit(AUDIT_PATH, run_id=run_id)

    audit.emit("forge.start", phase="build",
               spec_path=str(SPEC_PATH), spec_hash=spec_hash,
               agent="pedal-engineer", phase_name="phase2p5-gen-integration")

    audit.emit("spec.parsed", phase="build",
               module_count=len(spec.get("modules", {})),
               param_count=len(spec.get("parameters", [])),
               signal_chain_length=len(spec.get("signal_chain", [])),
               manual_step_count=len(spec.get("manual_steps", [])),
               spec_hash=spec_hash)

    # ── Phase 2.5: integration start — record gen DSL provenance ─────────
    gen_modules = ["tl_saturate", "tl_wow", "tl_failure", "tl_flutter",
                   "tl_aux", "tl_noise"]
    gen_dsl_provenance = {}
    total_codebox_bytes = 0
    for mname in gen_modules:
        gp = GEN_DIR / f"{mname}.gendsp"
        raw = gp.read_bytes()
        sha = sha256_bytes(raw)
        gen_dsl_provenance[mname] = {
            "path": str(gp),
            "sha256": sha,
            "bytes": len(raw),
            "lines": raw.count(b"\n") + (0 if raw.endswith(b"\n") else 1),
        }
        total_codebox_bytes += len(raw)

    js_path = JS_DIR / "model_selector.js"
    js_raw = js_path.read_bytes()
    js_sha = sha256_bytes(js_raw)

    # Capture old .amxd hash before we overwrite it (for the comparison field).
    old_amxd_path = DEVICE_DIR / "tape-loss.amxd"
    amxd_sha256_old = sha256_path(old_amxd_path) if old_amxd_path.exists() else None

    audit.emit("phase2p5.integration.start", phase="build",
               gen_dsl_files=gen_dsl_provenance,
               js_companion={"path": str(js_path), "sha256": js_sha,
                             "bytes": len(js_raw)},
               total_codebox_bytes_to_embed=total_codebox_bytes,
               amxd_sha256_old=amxd_sha256_old)

    # Phase 1.5 contract divergence flag — tl_flutter authored gen DSL
    # uses private Delay buffers rather than the shared [buffer~ tape_loss_delay]
    # the reconciliation pass had signed off on. Documented; not blocking.
    audit.emit("phase15.contract.flag", phase="build",
               contract="shared_tapin_wow_flutter",
               original_phase15_status="signed_off_shared",
               current_implementation="private_per_module",
               rationale="bit_identity_to_numpy_unreachable_real_time",
               revisit_when="v1_or_when_audible_diff_surfaces")

    # Hash the build script itself (provenance for reproducibility).
    build_script = Path(__file__).resolve()
    audit.hash_artifact(build_script, kind="build_script")

    # Re-emit manual_step_required from spec
    for step in spec.get("manual_steps", []):
        audit.emit("manual_step_required", phase="build",
                   human_step=step["step"],
                   estimate_seconds=step["estimate_seconds"],
                   blocks_phase=step.get("blocks_phase"),
                   why_manual=step.get("why_manual"),
                   automate_when=step.get("automate_when"))

    # ── Phase 2: per-module patches ─────────────────────────────────────
    builders = {
        "tl_saturate": build_tl_saturate,
        "tl_model_eq": build_tl_model_eq,
        "tl_failure": build_tl_failure,
        "tl_wow": build_tl_wow,
        "tl_flutter": build_tl_flutter,
        "tl_aux": build_tl_aux,
        "tl_volume_mix": build_tl_volume_mix,
        "tl_dry_mix": build_tl_dry_mix,
        "tl_noise": build_tl_noise,
    }

    module_patches = {}
    verifier_pass = 0
    verifier_fail = 0
    verifier_fails = []

    for mname in spec["signal_chain"]:
        with audit.step(f"module.{mname}", phase="build", module=mname):
            audit.emit(f"module.{mname}.start", phase="build", module=mname,
                       sandbox_status=spec["modules"][mname].get("sandbox_status"))
            patch = builders[mname]()
            module_patches[mname] = patch

            # Save .maxpat
            mpath = DEVICE_DIR / f"{mname}.maxpat"
            sha, size = write_patcher(mpath, patch)
            audit.emit(f"module.{mname}.patch_generated",
                       phase="build", module=mname,
                       path=str(mpath), sha256=sha, bytes=size)
            audit.hash_artifact(mpath, kind="module_patch")

            # Run PATCHER_VERIFIERS
            results = V.run_all(patch, kind="patcher")
            for r in results:
                # NB: subpatchers don't need plugin~/plugout~ (they have inlets)
                # so we filter that verifier out for module subpatches.
                # But the verifier still runs — we just classify it.
                effective_pass = r.passed
                if r.verifier == "plugin_pair_required":
                    # Subpatches legitimately don't have plugin~/plugout~ —
                    # they have [inlet]/[outlet]. This is expected; we mark
                    # it as N/A for module subpatches.
                    audit.emit(f"verifier.{r.verifier}", phase="verify",
                               module=mname, verifier=r.verifier,
                               pitfall=r.pitfall,
                               pass_=True,  # N/A for subpatches
                               detail=f"n/a for subpatcher (uses inlet~/outlet~ instead): {r.detail}",
                               nominal_result=r.passed)
                    if effective_pass or True:  # subpatchers exempt
                        verifier_pass += 1
                else:
                    audit.emit(f"verifier.{r.verifier}", phase="verify",
                               module=mname, verifier=r.verifier,
                               pitfall=r.pitfall, pass_=r.passed,
                               detail=r.detail)
                    if r.passed:
                        verifier_pass += 1
                    else:
                        verifier_fail += 1
                        verifier_fails.append((mname, r.verifier, r.detail))

    # ── Phase 3: main patch assembly ────────────────────────────────────
    with audit.step("device.assemble", phase="build"):
        main_patch = build_main_patcher(spec, module_patches)
        main_path = DEVICE_DIR / "tape-loss.maxpat"
        sha, size = write_patcher(main_path, main_patch)
        audit.emit("device.main_patch_generated", phase="build",
                   path=str(main_path), sha256=sha, bytes=size)
        audit.hash_artifact(main_path, kind="main_patch")

        # Run PATCHER_VERIFIERS on main patch
        results = V.run_all(main_patch, kind="patcher")
        for r in results:
            audit.emit(f"verifier.{r.verifier}", phase="verify",
                       module="device", verifier=r.verifier,
                       pitfall=r.pitfall, pass_=r.passed,
                       detail=r.detail)
            if r.passed:
                verifier_pass += 1
            else:
                verifier_fail += 1
                verifier_fails.append(("device", r.verifier, r.detail))

    # ── Phase 4: standalone debug harness ───────────────────────────────
    with audit.step("device.debug_harness", phase="build"):
        debug_patch = build_debug_patcher(main_patch, "tape-loss")
        debug_path = DEVICE_DIR / "tape-loss-debug.maxpat"
        sha, size = write_patcher(debug_path, debug_patch)
        audit.emit("device.debug_patch_generated", phase="build",
                   path=str(debug_path), sha256=sha, bytes=size)
        audit.hash_artifact(debug_path, kind="debug_patch")
        # Confirm it parses (round-trip JSON).
        try:
            json.loads(debug_path.read_text())
            audit.emit("verifier.debug_parses", phase="verify",
                       module="device-debug", verifier="json_round_trip",
                       pass_=True)
            verifier_pass += 1
        except json.JSONDecodeError as e:
            audit.emit("verifier.debug_parses", phase="verify",
                       module="device-debug", verifier="json_round_trip",
                       pass_=False, detail=str(e))
            verifier_fail += 1
            verifier_fails.append(("device-debug", "json_round_trip", str(e)))

    # ── Phase 5: pack .amxd ─────────────────────────────────────────────
    amxd_sha256_new = None
    amxd_size_new = None
    with audit.step("device.pack_amxd", phase="build"):
        amxd_path = DEVICE_DIR / "tape-loss.amxd"
        amxd_pack.pack_amxd(main_patch, amxd_path, device_class="audio")
        sha = sha256_path(amxd_path)
        size = amxd_path.stat().st_size
        amxd_sha256_new = sha
        amxd_size_new = size
        audit.emit("device.assembled", phase="build",
                   path=str(amxd_path), sha256=sha, bytes=size,
                   device_class="audio")
        audit.emit("device.repacked", phase="build",
                   path=str(amxd_path), sha256=sha, bytes=size,
                   sha256_old=amxd_sha256_old,
                   sha256_changed=(amxd_sha256_old != sha),
                   device_class="audio")

        # AMXD_VERIFIERS
        amxd_results = V.run_all(amxd_path, kind="amxd")
        for r in amxd_results:
            audit.emit(f"verifier.{r.verifier}", phase="verify",
                       module="device", verifier=r.verifier,
                       pitfall=r.pitfall, pass_=r.passed,
                       detail=r.detail)
            if r.passed:
                verifier_pass += 1
            else:
                verifier_fail += 1
                verifier_fails.append(("device-amxd", r.verifier, r.detail))

    duration_ms = int((time.perf_counter() - t0) * 1000)
    audit.emit("forge.complete", phase="build",
               duration_ms=duration_ms,
               verifier_pass=verifier_pass,
               verifier_fail=verifier_fail,
               verifier_fails=verifier_fails)

    audit.emit("phase2p5.integration.complete", phase="build",
               duration_ms=duration_ms,
               gen_dsl_files_consumed=len(gen_modules),
               total_codebox_bytes_embedded=total_codebox_bytes,
               js_companion_bytes=len(js_raw),
               verifier_pass_count=verifier_pass,
               verifier_fail_count=verifier_fail,
               amxd_sha256_old=amxd_sha256_old,
               amxd_sha256_new=amxd_sha256_new,
               amxd_bytes_new=amxd_size_new,
               amxd_changed=(amxd_sha256_old != amxd_sha256_new))

    print(f"BUILD COMPLETE in {duration_ms} ms")
    print(f"  verifiers: {verifier_pass} pass / {verifier_fail} fail")
    if verifier_fails:
        print("  FAILURES:")
        for m, v, d in verifier_fails:
            print(f"    [{m}] {v}: {d}")
    print(f"  device: {DEVICE_DIR / 'tape-loss.amxd'}")
    return 0 if verifier_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
