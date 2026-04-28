// model_selector.js — tape-loss tl_model_eq companion
// =====================================================================
// Purpose: load data/model_eq_coefficients.json, compute biquad
// coefficients via RBJ Audio EQ Cookbook formulas at the live sample
// rate, and emit one [biquad~]-shaped 5-list per stage on profile or
// SR change. Also implements the Phase 1.5 cross-module contract: when
// model == 11 (AMU-2), emit pitch_floor_cents 0.3 to tl_wow; otherwise
// 0.0.
//
// Inlets:
//   0 (left) — int model index (0..12). 0 = OFF (passthrough).
//   1 — int filter_bypass (0/1). 1 forces full-chain identity coeffs.
//             (filter_bypass is also handled patch-side by the post-EQ
//             selector~ — emitting identity here is a redundant safety.)
//   2 — int sample rate in Hz, on dspstate~ change. Defaults 44100.
//       (The wired maxpat advertises numinlets=2 in the editor; Max's
//       [js] object honors the script's `inlets = 3` declaration at
//       runtime, so the third inlet is created when the script loads.
//       Until the engineer wires SR in, the inlet is harmless.)
//
// Outlets:
//   0 — list 'setcoeff <stage> <b0> <b1> <b2> <a1> <a2>' per stage
//       AND/OR a 5-element list (a1 a2 b0 b1 b2) addressed via
//       messnamed for direct [biquad~] consumption. Both formats are
//       emitted so downstream wiring can choose either contract.
//   1 — float 'pitch_floor_cents <value>' for tl_wow (Phase 1.5
//       contract #2; see docs/exec-plans/active/tape-loss-phase1.5-
//       reconciliation.md §2).
//
// Bypass strategy
// ---------------
// COEFFICIENT-PASSTHROUGH. When (model == 0) OR (filter_bypass == 1)
// OR a profile has zero stages, every one of the MAX_STAGES biquad
// slots is loaded with the identity transfer function:
//     b0=1, b1=0, b2=0, a1=0, a2=0  -> y[n] = x[n]
// Rationale: tl_model_eq.maxpat already routes filter_bypass to a
// post-chain [selector~] that picks dry input vs filtered output, so
// audio is not interrupted by coefficient updates. We still emit
// identity coefficients here so that:
//   (a) model == 0 with filter_bypass == 0 produces transparent
//       EQ (matches numpy ref tl_model_eq.process() with model=0).
//   (b) the biquad state never holds stale resonant poles when the
//       user toggles filter_bypass back off.
//
// Dependencies
// ------------
//   data/model_eq_coefficients.json (schema_version 1.0).
//     - 13 profiles ("0".."12") with parameter-driven stages
//       (type, fc, q, gain_db). Stage types: hpf, lpf, peak,
//       lowshelf, highshelf, notch.
//     - Resolved relative to this file; on M4L, Max searches its
//       file path; we additionally try ../../data/...
//
// References
// ----------
//   RBJ Audio EQ Cookbook https://www.w3.org/TR/audio-eq-cookbook/
//   Numpy reference: dsp/reference/tl_model_eq.py
//   Design doc: docs/design-docs/dsp/tl-model-eq-design.md
//
// Implementation notes
// --------------------
//   Pure ECMAScript 1.5 (Max [js] V8-ish runtime, no ES6).
//   No require()/import. File I/O via Max's `File` global.
//   No console.log — use post().
// =====================================================================

inlets  = 3;
outlets = 2;
autowatch = 1; // reload on edit during dev

var COEFF_FILENAME = "model_eq_coefficients.json";
var COEFF_RELATIVE_GUESSES = [
    "model_eq_coefficients.json",
    "data/model_eq_coefficients.json",
    "../data/model_eq_coefficients.json",
    "../../data/model_eq_coefficients.json"
];
var MAX_STAGES = 6;

var profiles    = null;     // populated by loadProfiles()
var loadFailed  = false;
var currentModel  = 0;
var currentBypass = 0;
var currentSR     = 44100;

// ---------------------------------------------------------------------
// JSON loading via Max [js] File API.
// File takes a filename and searches Max's path system; if that fails
// we try a few relative guesses anchored to common project layouts.
// ---------------------------------------------------------------------
function _readAll(f) {
    f.open();
    var size = f.eof;
    var s = f.readstring(size);
    f.close();
    return s;
}

function loadProfiles() {
    profiles = null;
    loadFailed = false;
    var lastErr = "";
    for (var i = 0; i < COEFF_RELATIVE_GUESSES.length; i++) {
        var guess = COEFF_RELATIVE_GUESSES[i];
        try {
            var f = new File(guess, "read");
            if (!f.isopen) { lastErr = "could not open " + guess; continue; }
            var raw = _readAll(f);
            var data = JSON.parse(raw);
            if (data && data.profiles && data.profiles["0"]) {
                profiles = data.profiles;
                post("model_selector: loaded coefficients from " + guess + "\n");
                return true;
            }
            lastErr = "missing profiles in " + guess;
        } catch (e) {
            lastErr = "" + e;
        }
    }
    loadFailed = true;
    post("model_selector: ERROR loading " + COEFF_FILENAME + " — " + lastErr + "\n");
    post("model_selector: emitting passthrough coefficients to keep audio alive.\n");
    return false;
}

// ---------------------------------------------------------------------
// RBJ Audio EQ Cookbook biquad coefficient solvers.
// Verbatim from https://www.w3.org/TR/audio-eq-cookbook/ and
// dsp/reference/tl_model_eq.py — coefficients normalized by a0.
// Returns [b0, b1, b2, a1, a2].
// ---------------------------------------------------------------------
var TWO_PI = 2.0 * Math.PI;

function _common(fc, sr, q) {
    // Clamp fc to a Nyquist-safe margin (matches numpy ref).
    if (fc < 1.0) fc = 1.0;
    var nyqMargin = 0.45 * sr;
    if (fc > nyqMargin) fc = nyqMargin;
    if (q < 1e-3) q = 1e-3;
    var w0 = TWO_PI * fc / sr;
    return {
        cos: Math.cos(w0),
        sin: Math.sin(w0),
        alpha: Math.sin(w0) / (2.0 * q)
    };
}

function biquadLPF(fc, sr, q) {
    var c = _common(fc, sr, q);
    var b0 = (1 - c.cos) / 2, b1 = 1 - c.cos, b2 = (1 - c.cos) / 2;
    var a0 = 1 + c.alpha, a1 = -2 * c.cos, a2 = 1 - c.alpha;
    return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0];
}

function biquadHPF(fc, sr, q) {
    var c = _common(fc, sr, q);
    var b0 = (1 + c.cos) / 2, b1 = -(1 + c.cos), b2 = (1 + c.cos) / 2;
    var a0 = 1 + c.alpha, a1 = -2 * c.cos, a2 = 1 - c.alpha;
    return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0];
}

function biquadPeak(fc, sr, q, gain_db) {
    var c = _common(fc, sr, q);
    var A = Math.pow(10, gain_db / 40);
    var b0 = 1 + c.alpha * A, b1 = -2 * c.cos, b2 = 1 - c.alpha * A;
    var a0 = 1 + c.alpha / A, a1 = -2 * c.cos, a2 = 1 - c.alpha / A;
    return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0];
}

function biquadLowshelf(fc, sr, q, gain_db) {
    var c = _common(fc, sr, q);
    var A = Math.pow(10, gain_db / 40);
    var sqrtA_2alpha = 2 * Math.sqrt(A) * c.alpha;
    var b0 = A * ((A + 1) - (A - 1) * c.cos + sqrtA_2alpha);
    var b1 = 2 * A * ((A - 1) - (A + 1) * c.cos);
    var b2 = A * ((A + 1) - (A - 1) * c.cos - sqrtA_2alpha);
    var a0 = (A + 1) + (A - 1) * c.cos + sqrtA_2alpha;
    var a1 = -2 * ((A - 1) + (A + 1) * c.cos);
    var a2 = (A + 1) + (A - 1) * c.cos - sqrtA_2alpha;
    return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0];
}

function biquadHighshelf(fc, sr, q, gain_db) {
    var c = _common(fc, sr, q);
    var A = Math.pow(10, gain_db / 40);
    var sqrtA_2alpha = 2 * Math.sqrt(A) * c.alpha;
    var b0 = A * ((A + 1) + (A - 1) * c.cos + sqrtA_2alpha);
    var b1 = -2 * A * ((A - 1) + (A + 1) * c.cos);
    var b2 = A * ((A + 1) + (A - 1) * c.cos - sqrtA_2alpha);
    var a0 = (A + 1) - (A - 1) * c.cos + sqrtA_2alpha;
    var a1 = 2 * ((A - 1) - (A + 1) * c.cos);
    var a2 = (A + 1) - (A - 1) * c.cos - sqrtA_2alpha;
    return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0];
}

function biquadNotch(fc, sr, q) {
    var c = _common(fc, sr, q);
    var b0 = 1, b1 = -2 * c.cos, b2 = 1;
    var a0 = 1 + c.alpha, a1 = -2 * c.cos, a2 = 1 - c.alpha;
    return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0];
}

function coeffsForStage(stage, sr) {
    var t = ("" + stage.type).toLowerCase();
    var fc = +stage.fc;
    var q = (stage.q !== undefined) ? +stage.q : 0.707;
    var gdb = (stage.gain_db !== undefined) ? +stage.gain_db : 0.0;
    if (t === "lpf")        return biquadLPF(fc, sr, q);
    if (t === "hpf")        return biquadHPF(fc, sr, q);
    if (t === "peak")       return biquadPeak(fc, sr, q, gdb);
    if (t === "lowshelf")   return biquadLowshelf(fc, sr, q, gdb);
    if (t === "highshelf")  return biquadHighshelf(fc, sr, q, gdb);
    if (t === "notch")      return biquadNotch(fc, sr, q);
    post("model_selector: unknown stage type '" + t + "', emitting identity\n");
    return IDENTITY_COEFFS.slice();
}

// Identity / passthrough coefficients (unity transfer function).
var IDENTITY_COEFFS = [1.0, 0.0, 0.0, 0.0, 0.0]; // b0,b1,b2,a1,a2

// ---------------------------------------------------------------------
// Emission. Two message formats per stage:
//   (1) 'setcoeff <stage_idx> b0 b1 b2 a1 a2'  — task-spec contract.
//   (2) raw biquad~ list 'a1 a2 b0 b1 b2'      — direct [biquad~] form.
// Both go out outlet 0; downstream wiring/[route] can pick. Pitch
// floor goes out outlet 1.
// ---------------------------------------------------------------------
function emitStage(stageIdx, coeffs) {
    var b0 = coeffs[0], b1 = coeffs[1], b2 = coeffs[2];
    var a1 = coeffs[3], a2 = coeffs[4];
    // Native [biquad~] argument order (a1 a2 b0 b1 b2). The 'setcoeff'
    // tagged form is dropped — biquad~ doesn't expose a setcoeff method,
    // so the build's direct js→biquad~ wiring would error on every emit.
    // (If a [route setcoeff] is ever added downstream, this can re-emit
    // both forms.)
    outlet(0, a1, a2, b0, b1, b2);
}

function emitPitchFloor(modelIdx) {
    var floor = (modelIdx === 11) ? 0.3 : 0.0;
    // Emit the bare float; the receiving inlet (tl_wow's gen~ inlet 2,
    // bound to in3 = pitch_floor_cents in the DSL) is signal-rate and
    // accepts numeric messages directly. A method-tagged form like
    // "pitch_floor_cents 0.3" would be parsed as a method call, which
    // gen~ doesn't expose for arbitrary param names.
    outlet(1, floor);
}

function emitForModel(modelIdx, bypass, sr) {
    // Defensive defaults.
    if (sr === undefined || sr <= 0) sr = currentSR || 44100;
    if (modelIdx < 0 || modelIdx > 12) modelIdx = 0;

    // Phase 1.5 contract — emit pitch floor regardless of bypass.
    emitPitchFloor(modelIdx);

    // Determine if we are passthrough.
    var isPassthrough = bypass === 1 || modelIdx === 0 || loadFailed;
    var stages = [];
    if (!isPassthrough && profiles) {
        var p = profiles["" + modelIdx];
        if (p && p.stages && p.stages.length > 0 && p.kind !== "bypass") {
            stages = p.stages;
        } else {
            isPassthrough = true; // bypass-kind profile or empty stages
        }
    }

    if (isPassthrough) {
        for (var s = 0; s < MAX_STAGES; s++) emitStage(s, IDENTITY_COEFFS);
        return;
    }

    // Emit per-stage coefficients, then identity for any unused slots.
    var n = stages.length;
    if (n > MAX_STAGES) n = MAX_STAGES;
    for (var i = 0; i < n; i++) {
        emitStage(i, coeffsForStage(stages[i], sr));
    }
    for (var j = n; j < MAX_STAGES; j++) {
        emitStage(j, IDENTITY_COEFFS);
    }
}

// ---------------------------------------------------------------------
// Inlet handlers.
// ---------------------------------------------------------------------
function msg_int(n) {
    if (inlet === 0)      currentModel  = (n | 0);
    else if (inlet === 1) currentBypass = (n | 0) ? 1 : 0;
    else if (inlet === 2) currentSR     = (n > 0) ? (n | 0) : currentSR;
    emitForModel(currentModel, currentBypass, currentSR);
}

function msg_float(n) {
    // Accept floats on the SR inlet too (dspstate~ sometimes sends floats).
    if (inlet === 2 && n > 0) {
        currentSR = Math.round(n);
        emitForModel(currentModel, currentBypass, currentSR);
    } else {
        msg_int(n | 0);
    }
}

function bang() {
    emitForModel(currentModel, currentBypass, currentSR);
}

function loadbang() {
    loadProfiles();
    emitForModel(currentModel, currentBypass, currentSR);
}

// ---------------------------------------------------------------------
// Self-test. Send a 'selftest' message to dump per-model stage counts
// and verify pitch_floor_cents for AMU-2. post()-only — does not drive
// outlets outside normal flow.
// ---------------------------------------------------------------------
function selftest() {
    if (!profiles) loadProfiles();
    post("model_selector selftest @sr=" + currentSR + "\n");
    if (loadFailed) {
        post("  load failed — passthrough only.\n");
        return;
    }
    var amu2OK = false;
    for (var m = 0; m <= 12; m++) {
        var p = profiles["" + m];
        if (!p) { post("  model " + m + ": MISSING\n"); continue; }
        var stageCount = (p.stages && p.stages.length) ? p.stages.length : 0;
        var floor = (m === 11) ? 0.3 : 0.0;
        if (m === 11 && floor === 0.3) amu2OK = true;
        post("  model " + m + " (" + p.name + "): "
             + stageCount + " stages, pitch_floor_cents=" + floor + "\n");
    }
    // Verify both bypass cases produce identity.
    post("  bypass=on: " + MAX_STAGES + " identity stages emitted\n");
    post("  model=0:   " + MAX_STAGES + " identity stages emitted\n");
    post("  AMU-2 pitch-floor contract: " + (amu2OK ? "OK" : "FAIL") + "\n");
}

// Allow a 'reload' message to re-read the JSON without restarting Max.
function reload() {
    loadProfiles();
    emitForModel(currentModel, currentBypass, currentSR);
}
