// ═══════════════════════════════════════════════════════════
//  Punch-FX Layer — momentary effect triggers with pressure
// ═══════════════════════════════════════════════════════════
//
// The punch buttons (right side, top 4) are momentary mode-shifts:
//   hold button → grid enters FX_APPLY → pad press applies effect to
//   the pad's stem → aftertouch drives 0–1 amount → release = disengage.
//
// One effect at a time (last button wins); multiple pads allowed,
// each with independent per-target amount.

// ── Provisional button notes (Pro MK2 right side) ──
// TODO: confirm on hardware — exact note numbers for Pro MK2 right side
var PUNCH_BUTTON_NOTES = [89, 79, 69, 59];

// Effect order matches the punch-fx device spec
var PUNCH_EFFECTS = ["REPEAT", "STUTTER", "SLICER", "OCT"];

// ── State ──
var PUNCH_IDLE = "idle";
var PUNCH_FX_APPLY = "fx_apply";

var punchState = PUNCH_IDLE;
var punchActiveEffect = null;    // index into PUNCH_EFFECTS (0-3)
var punchActiveTargets = {};     // key: targetId → { effect, amount }

// ── Stem mapping (8 rows → stem + deck) ──
var STEM_ROWS = ["drums", "bass", "other", "vox", "drums", "bass", "other", "vox"];
var DECK_ROWS = ["x", "x", "x", "x", "y", "y", "y", "y"];

// ── Injectable FX sink (guarded — no-ops if no punch-fx device present) ──
var _punchSink = null;

function setPunchSink(fn) {
    _punchSink = fn;
}

function applyPunch(target, effect, on, amount) {
    if (typeof _punchSink === "function") {
        _punchSink(target, effect, on, amount);
    } else {
        post("punch-layer: [no-op] applyPunch(" + target + ", " + effect + ", " + on + ", " + amount.toFixed(3) + ") — no sink\n");
    }
}

// ── FX target resolution ──
// mode: "per-stem" (Phase 1), "deckA"/"deckB"/"master" (future)
var punchFxMode = "per-stem";

function resolveFxTarget(row, col, mode) {
    if (mode === undefined) mode = punchFxMode;
    if (mode === "per-stem") {
        if (row < 1 || row > 8) return null;
        var stem = STEM_ROWS[row - 1];
        var deck = DECK_ROWS[row - 1];
        // Look up the stem track path from the controller's globals
        var trackIds = (deck === "x") ? stemTrackIdsX : stemTrackIdsY;
        // stemTrackIdsX/Y may not exist yet (before concat with controller)
        if (typeof trackIds === "undefined" || !trackIds) return null;
        var path = trackIds[stem];
        return path ? { stem: stem, deck: deck, trackPath: path } : null;
    }
    // Future modes: return sentinel for deck bus / master
    if (mode === "deckA") return { stem: "all", deck: "x", trackPath: null };
    if (mode === "deckB") return { stem: "all", deck: "y", trackPath: null };
    if (mode === "master") return { stem: "all", deck: "all", trackPath: null };
    return null;
}

// ── State machine ──

function isPunchButton(note) {
    return PUNCH_BUTTON_NOTES.indexOf(note) >= 0;
}

function punchButtonIndex(note) {
    return PUNCH_BUTTON_NOTES.indexOf(note);
}

function punchButtonDown(note) {
    var idx = punchButtonIndex(note);
    if (idx < 0) return false;

    punchState = PUNCH_FX_APPLY;
    punchActiveEffect = idx;
    punchActiveTargets = {};
    post("punch-layer: FX_APPLY → " + PUNCH_EFFECTS[idx] + "\n");
    return true;
}

function punchButtonUp(note) {
    var idx = punchButtonIndex(note);
    if (idx < 0) return false;
    if (punchState !== PUNCH_FX_APPLY) return false;

    // Disengage all active targets
    for (var key in punchActiveTargets) {
        if (punchActiveTargets.hasOwnProperty(key)) {
            var t = punchActiveTargets[key];
            applyPunch(t.trackPath || key, PUNCH_EFFECTS[punchActiveEffect], false, 0);
        }
    }
    punchActiveTargets = {};
    punchActiveEffect = null;
    punchState = PUNCH_IDLE;
    post("punch-layer: → IDLE\n");
    return true;
}

function punchPadDown(grid, row, col) {
    if (punchState !== PUNCH_FX_APPLY || punchActiveEffect === null) return false;

    var target = resolveFxTarget(row, col, punchFxMode);
    if (!target) return false;

    var key = (target.trackPath || target.stem + "-" + target.deck);
    // Get initial pressure (may be 0 until aftertouch arrives)
    var pressure = 0;
    if (typeof getPadPressure === "function") {
        var note = (typeof surface !== "undefined" && surface.rowColToNote)
            ? surface.rowColToNote(row, col) : 0;
        pressure = getPadPressure(grid, note);
    }

    punchActiveTargets[key] = { stem: target.stem, deck: target.deck, trackPath: target.trackPath, amount: pressure };
    applyPunch(target.trackPath || key, PUNCH_EFFECTS[punchActiveEffect], true, pressure);
    return true;
}

function punchPadUp(grid, row, col) {
    if (punchState !== PUNCH_FX_APPLY) return false;

    var target = resolveFxTarget(row, col, punchFxMode);
    if (!target) return false;

    var key = (target.trackPath || target.stem + "-" + target.deck);
    if (punchActiveTargets[key]) {
        applyPunch(target.trackPath || key, PUNCH_EFFECTS[punchActiveEffect], false, 0);
        delete punchActiveTargets[key];
    }
    return true;
}

function punchUpdatePressure(grid, note, pressure01) {
    if (punchState !== PUNCH_FX_APPLY || punchActiveEffect === null) return;

    // Resolve the note back to row/col to find the target
    var pos = null;
    if (typeof surface !== "undefined" && surface.noteToRowCol) {
        pos = surface.noteToRowCol(note);
    }
    if (!pos) return;

    var target = resolveFxTarget(pos.row, pos.col, punchFxMode);
    if (!target) return;

    var key = (target.trackPath || target.stem + "-" + target.deck);
    if (punchActiveTargets[key]) {
        punchActiveTargets[key].amount = pressure01;
        applyPunch(target.trackPath || key, PUNCH_EFFECTS[punchActiveEffect], true, pressure01);
    }
}

function isPunchFxActive() {
    return punchState === PUNCH_FX_APPLY;
}

function getPunchState() {
    return {
        state: punchState,
        effect: punchActiveEffect !== null ? PUNCH_EFFECTS[punchActiveEffect] : null,
        targets: punchActiveTargets
    };
}

function resetPunch() {
    punchState = PUNCH_IDLE;
    punchActiveEffect = null;
    punchActiveTargets = {};
}

// ── Module exports (guarded for test harness; no-op in Max SpiderMonkey) ──
if (typeof module !== "undefined") {
    module.exports = {
        PUNCH_BUTTON_NOTES: PUNCH_BUTTON_NOTES,
        PUNCH_EFFECTS: PUNCH_EFFECTS,
        PUNCH_IDLE: PUNCH_IDLE,
        PUNCH_FX_APPLY: PUNCH_FX_APPLY,
        STEM_ROWS: STEM_ROWS,
        DECK_ROWS: DECK_ROWS,
        isPunchButton: isPunchButton,
        punchButtonIndex: punchButtonIndex,
        punchButtonDown: punchButtonDown,
        punchButtonUp: punchButtonUp,
        punchPadDown: punchPadDown,
        punchPadUp: punchPadUp,
        punchUpdatePressure: punchUpdatePressure,
        isPunchFxActive: isPunchFxActive,
        getPunchState: getPunchState,
        resetPunch: resetPunch,
        resolveFxTarget: resolveFxTarget,
        setPunchSink: setPunchSink,
        applyPunch: applyPunch,
    };
}
