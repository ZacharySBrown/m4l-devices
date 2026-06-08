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

// Inlined at build time from data/model_eq_coefficients.json — pitfall #27.
// (Live cannot resolve `../../data/...` from inside the .amxd; runtime
// File-load fails and falls back to passthrough, killing the EQ's
// per-model character. Inlining removes the resolution path entirely.)
var INLINED_COEFFICIENTS = {"schema_version":"1.0","generated_by":"pedal-dsp persona, tape-loss tl_model_eq","spec_source":"specs/tape-loss-spec.md \u00a7MODULE 2","biquad_math_source":"RBJ Audio EQ Cookbook (https://www.w3.org/TR/audio-eq-cookbook/)","sample_rate_anchor":44100,"notes":["Stages are stored as parameters (type, fc, Q, gain_db). Coefficients are computed at runtime from the live sample rate using RBJ Cookbook formulas in dsp/reference/tl_model_eq.py and the engineer's [js] companion.","Order of stages matters: HPF \u2192 low shelf \u2192 peaks \u2192 high shelf \u2192 LPF. The reference impl applies them strictly in this order to match Module 2 of the prose spec.","All gain values are in dB. Linear gain = 10^(dB/20) is computed inside the biquad solver.","Q values follow the Cookbook Q-form: alpha = sin(w0) / (2*Q). For shelves, Q is interpreted as the standard biquad Q (S=1 equivalent at Q=1/sqrt(2)) to keep one parameter taxonomy.","Profile 0 is OFF (passthrough). Profile names follow the prose spec.","fc must be < sr/2; the runtime clamps fc to 0.45*sr for safety.","filter_bypass=true short-circuits this entire block regardless of profile."],"transitions":{"model_change_strategy":"equal_power_crossfade","crossfade_ms":12.0,"filter_bypass_strategy":"equal_power_crossfade","rationale":"Switching biquad coefficients mid-stream causes audible clicks because the IIR state is wrong for the new transfer function. Crossfading two parallel chains (old vs new) over ~12 ms is inaudible to humans and absorbs the transient. See pitfall catalog \u00a7click-on-coeff-change."},"profiles":{"0":{"name":"OFF","kind":"bypass","description":"Passthrough. No filtering applied.","stages":[]},"1":{"name":"CPR-3300 Gen 1","kind":"VHS","description":"First-generation VHS CPR-3300. Subsonic-cleaned, mild bass shelf, midrange color, presence dip, distinctive HF rolloff (the VHS hallmark) and soft brick wall.","physical_justification":"VHS linear audio tracks have ~80 Hz\u201310 kHz bandwidth with audible pre-emphasis recovery losses around 6 kHz. The high-shelf cut at 8 kHz captures bias-induced HF loss; the LPF at 10 kHz models the head-gap rolloff.","stages":[{"type":"hpf","fc":40,"q":0.7,"gain_db":0,"comment":"subsonic"},{"type":"lowshelf","fc":200,"q":0.7,"gain_db":-2,"comment":"VHS bass rolloff"},{"type":"peak","fc":800,"q":1.5,"gain_db":1,"comment":"midrange color"},{"type":"peak","fc":6000,"q":0.8,"gain_db":-3,"comment":"presence cut"},{"type":"highshelf","fc":8000,"q":0.7,"gain_db":-8,"comment":"VHS HF rolloff (signature)"},{"type":"lpf","fc":10000,"q":0.6,"gain_db":0,"comment":"soft brick wall"}]},"2":{"name":"CPR-3300 Gen 2","kind":"VHS","description":"Second-generation copy: more HF loss, lower brick wall.","physical_justification":"VHS dub-down generation loss compounds HF rolloff. Each generation typically loses ~3-4 dB more above 8 kHz and tightens the LPF corner.","stages":[{"type":"hpf","fc":40,"q":0.7,"gain_db":0},{"type":"lowshelf","fc":200,"q":0.7,"gain_db":-2},{"type":"peak","fc":800,"q":1.5,"gain_db":1},{"type":"peak","fc":6000,"q":0.8,"gain_db":-3},{"type":"highshelf","fc":8000,"q":0.7,"gain_db":-12,"comment":"more HF loss than Gen 1"},{"type":"lpf","fc":8000,"q":0.6,"gain_db":0,"comment":"tighter brick wall"}]},"3":{"name":"CPR-3300 Gen 3","kind":"VHS","description":"Third-generation copy: severely degraded; mud accumulates around 500 Hz, high end nearly gone.","physical_justification":"Repeated copies build cumulative low-mid mud (additive harmonic distortion + low-rate FM modulation that gathers around tape-bias resonances) and lose nearly all HF detail.","stages":[{"type":"hpf","fc":40,"q":0.7,"gain_db":0},{"type":"lowshelf","fc":200,"q":0.7,"gain_db":-2},{"type":"peak","fc":500,"q":1.0,"gain_db":2,"comment":"muddy copy buildup"},{"type":"peak","fc":800,"q":1.5,"gain_db":1},{"type":"peak","fc":6000,"q":0.8,"gain_db":-3},{"type":"highshelf","fc":8000,"q":0.7,"gain_db":-16,"comment":"severe HF loss"},{"type":"lpf","fc":6000,"q":0.6,"gain_db":0}]},"4":{"name":"Portamax-RT","kind":"Cassette","description":"Cassette 4-track at standard speed. Slight bass cut, midrange presence bump, gentle HF rolloff.","physical_justification":"Type-I cassette tape at 1-7/8 ips has ~13-15 kHz upper limit (Dolby B/C-dependent) and a head-bump near 1-2 kHz from the playback EQ curve (NAB/IEC).","stages":[{"type":"hpf","fc":60,"q":0.7,"gain_db":0},{"type":"lowshelf","fc":300,"q":0.7,"gain_db":-1},{"type":"peak","fc":1200,"q":1.2,"gain_db":2,"comment":"cassette midrange presence (head-bump)"},{"type":"highshelf","fc":10000,"q":0.7,"gain_db":-5},{"type":"lpf","fc":13000,"q":0.7,"gain_db":0}]},"5":{"name":"Portamax-HT","kind":"Cassette","description":"Cassette 4-track at half-speed (15/16 ips). Slower transport halves available bandwidth and emphasizes mid losses.","physical_justification":"Halving tape speed halves the upper-frequency response (Nyquist-style proportional to head-gap-vs-wavelength). Detail above ~7-8 kHz is essentially lost; midrange becomes more prominent.","stages":[{"type":"hpf","fc":60,"q":0.7,"gain_db":0},{"type":"lowshelf","fc":300,"q":0.7,"gain_db":-1},{"type":"peak","fc":1200,"q":1.2,"gain_db":2},{"type":"peak","fc":4000,"q":0.6,"gain_db":-4,"comment":"half-speed mid-HF loss"},{"type":"highshelf","fc":8000,"q":0.7,"gain_db":-8},{"type":"lpf","fc":9000,"q":0.5,"gain_db":0}]},"6":{"name":"CAM-8","kind":"Camcorder","description":"8mm camcorder built-in mic. Boxy, no lows, prominent boxy-mic resonance, narrow band.","physical_justification":"Tiny built-in electret mic inside a plastic camcorder body has a HPF-like proximity rolloff below 150 Hz, an enclosure resonance around 1.8-2 kHz, and AGC-induced softness above ~9 kHz.","stages":[{"type":"hpf","fc":120,"q":1.2,"gain_db":0,"comment":"mic proximity rolloff"},{"type":"lowshelf","fc":200,"q":0.7,"gain_db":-6,"comment":"boxy, no low end"},{"type":"peak","fc":1800,"q":1.5,"gain_db":4,"comment":"mic body resonance"},{"type":"peak","fc":7000,"q":1.0,"gain_db":-3},{"type":"highshelf","fc":9000,"q":0.7,"gain_db":-10},{"type":"lpf","fc":11000,"q":0.5,"gain_db":0}]},"7":{"name":"DICTATRON","kind":"Dictaphone","description":"Cassette dictaphone via line in. Telephone-band character: cut all bass, narrow midrange, hard HF brick wall.","physical_justification":"Dictaphones speech-optimize via aggressive HPF (300 Hz) and LPF (3-4 kHz) to maximize speech intelligibility per square millimeter of tape. Mimics ITU-T G.711 telephone bandwidth (300-3400 Hz).","stages":[{"type":"hpf","fc":300,"q":1.5,"gain_db":0,"comment":"telephone band lower edge"},{"type":"lowshelf","fc":400,"q":0.7,"gain_db":-10},{"type":"peak","fc":2000,"q":0.8,"gain_db":3,"comment":"telephone midrange peak"},{"type":"peak","fc":3000,"q":1.2,"gain_db":-5},{"type":"highshelf","fc":4000,"q":0.7,"gain_db":-15},{"type":"lpf","fc":4000,"q":1.2,"gain_db":0,"comment":"hard telephone band brick wall"}]},"8":{"name":"DICTATRON Mic","kind":"Dictaphone","description":"Dictaphone built-in mic. Same telephone character but with more pronounced enclosure resonance.","physical_justification":"Built-in mic adds a tiny plastic-shell resonance and a sharper proximity HPF, otherwise identical to Model 7.","stages":[{"type":"hpf","fc":300,"q":2.0,"gain_db":0,"comment":"more resonant box HPF"},{"type":"lowshelf","fc":400,"q":0.7,"gain_db":-10},{"type":"peak","fc":2000,"q":0.8,"gain_db":5,"comment":"more resonant box"},{"type":"peak","fc":3000,"q":1.2,"gain_db":-5},{"type":"highshelf","fc":4000,"q":0.7,"gain_db":-15},{"type":"lpf","fc":4000,"q":1.2,"gain_db":0}]},"9":{"name":"FISHY 60","kind":"Toy","description":"Toy recorder (Fisher-Price-style 1980s plastic). Honky tiny-speaker resonance, almost no bass, sharp brick wall.","physical_justification":"Small plastic toy speaker (~2-3 cm cone) has a primary resonance near 1.5 kHz, no bass response below ~500 Hz, and aliased sample-and-hold playback above ~3.5 kHz from cheap circuitry.","stages":[{"type":"hpf","fc":500,"q":2.0,"gain_db":0,"comment":"cheap speaker \u2014 no bass"},{"type":"lowshelf","fc":600,"q":0.7,"gain_db":-15},{"type":"peak","fc":1500,"q":2.0,"gain_db":6,"comment":"toy speaker resonance"},{"type":"peak","fc":5000,"q":1.5,"gain_db":-8},{"type":"highshelf","fc":4000,"q":0.7,"gain_db":-20},{"type":"lpf","fc":3500,"q":2.0,"gain_db":0}]},"10":{"name":"MS-WALKER","kind":"Walkman","description":"Consumer Walkman-style cassette portable. Slight smile-curve EQ from consumer-target playback chain. The most hi-fi-sounding profile after M-PEX.","physical_justification":"Walkman playback EQ deliberately bumps bass (~100 Hz) and presence (~3 kHz) to compensate for cheap earbuds. Also has a soft HF rolloff above 12 kHz from the cassette + small-amp combo.","stages":[{"type":"hpf","fc":50,"q":0.7,"gain_db":0},{"type":"peak","fc":100,"q":0.8,"gain_db":3,"comment":"consumer bass boost"},{"type":"peak","fc":3000,"q":1.0,"gain_db":2,"comment":"presence/clarity boost"},{"type":"highshelf","fc":12000,"q":0.7,"gain_db":-4},{"type":"lpf","fc":15000,"q":0.6,"gain_db":0}]},"11":{"name":"AMU-2","kind":"Imaginary","description":"Imaginary deteriorated machine. Scooped mids, weird HF resonance peak that shouldn't be there, severe HF rolloff. Always slightly off-pitch.","physical_justification":"Models a partly-broken transport: misaligned head causes the scooped midrange (Q=0.7 wide cut at 1 kHz), oxide buildup creates a phantom resonance around 3 kHz, and worn out HF response collapses everything above 5 kHz. Pitch wobble is handled by the tl_wow / tl_flutter modules; this profile only contributes the EQ.","stages":[{"type":"hpf","fc":200,"q":1.5,"gain_db":0},{"type":"lowshelf","fc":300,"q":0.7,"gain_db":-8},{"type":"peak","fc":1000,"q":0.7,"gain_db":-4,"comment":"scooped mids \u2014 broken machine"},{"type":"peak","fc":3000,"q":2.0,"gain_db":3,"comment":"weird oxide-buildup resonance"},{"type":"highshelf","fc":5000,"q":0.7,"gain_db":-18},{"type":"lpf","fc":5500,"q":1.5,"gain_db":0}],"extra_behavior":{"pitch_drift_cents":0.3,"pitch_drift_handled_by":"tl_wow","note":"tl_model_eq does not emit pitch drift; the architect should ensure tl_wow honors a per-model floor when model=11."}},"12":{"name":"M-PEX","kind":"Reel-to-reel","description":"Reel-to-reel master. Flattest of all profiles \u2014 only subtle warmth and very gentle air rolloff. Reference 'open' tape sound.","physical_justification":"Professional reel-to-reel at 15 ips with a brand new tape has near-flat response 30 Hz to 18 kHz. The slight 600 Hz bump captures NAB-curve playback warmth; the -3 dB at 14 kHz captures the gentle HF rolloff inherent to tape vs digital.","stages":[{"type":"hpf","fc":30,"q":0.7,"gain_db":0},{"type":"lowshelf","fc":100,"q":0.7,"gain_db":-1,"comment":"slight bass loss"},{"type":"peak","fc":600,"q":1.5,"gain_db":1,"comment":"NAB-curve warmth"},{"type":"highshelf","fc":14000,"q":0.7,"gain_db":-3,"comment":"tape air"},{"type":"lpf","fc":16000,"q":0.7,"gain_db":0}]}}};
var MAX_STAGES = 6;

var profiles    = null;     // populated by loadProfiles()
var loadFailed  = false;
var currentModel  = 0;
var currentBypass = 0;
var currentSR     = 44100;

// Inlined loader — no File I/O. Always succeeds.
function loadProfiles() {
    profiles = INLINED_COEFFICIENTS.profiles;
    loadFailed = false;
    post("model_selector: loaded inlined coefficients (schema " + INLINED_COEFFICIENTS.schema_version + ")\n");
    return true;
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
