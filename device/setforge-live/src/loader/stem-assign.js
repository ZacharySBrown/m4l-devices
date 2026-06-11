// ═══════════════════════════════════════════════════════════
//  Stem-Assign Gesture (Phase 1.3)
// ═══════════════════════════════════════════════════════════
//
// Left side buttons (one per grid row) are stem-assign triggers.
// Gesture: hold left button (target row) → tap a preset (top=A / bottom=B)
//   → that row sources its stem from that preset (per-row, not whole-kit).
// Release left button without preset = cancel.
// Re-press same row when already assigned = reset to default source.
// Max 1 stem/type/bank (e.g. only one drums row can source from A3).

// ── Provisional preset notes (Pro MK2 top/bottom side buttons) ──
// PROVISIONAL: verify hardware 2026-06-11 PM — top/bottom may send CCs
// (91-98 / 1-8) instead of notes. Isolate here so a flip is one-line.
var PRESET_NOTES_A = [91, 92, 93, 94, 95, 96, 97, 98];  // Top buttons → Bank A presets A1-A8
var PRESET_NOTES_B = [1, 2, 3, 4, 5, 6, 7, 8];           // Bottom buttons → Bank B presets B1-B8

// Left side button notes (one per grid row, top to bottom)
// TODO: confirm on hardware — Pro MK2 left side note numbers
var STEM_ASSIGN_BUTTONS = [80, 70, 60, 50, 40, 30, 20, 10];

// Row → stem name + deck
var ASSIGN_ROW_STEM = ["drums", "bass", "other", "vox", "drums", "bass", "other", "vox"];
var ASSIGN_ROW_DECK = ["x", "x", "x", "x", "y", "y", "y", "y"];

// ── State ──
var ASSIGN_IDLE = "idle";
var ASSIGN_WAITING = "waiting";  // left button held, waiting for preset tap

var assignState = ASSIGN_IDLE;
var assignTargetRow = -1;        // 0-7 (index into STEM_ASSIGN_BUTTONS)

// Row assignments: row index → preset slot index (or null for default)
var rowAssignments = [null, null, null, null, null, null, null, null];

// ── Helpers ──

function stemAssignButtonIndex(note) {
    return STEM_ASSIGN_BUTTONS.indexOf(note);
}

function isStemAssignButton(note) {
    return STEM_ASSIGN_BUTTONS.indexOf(note) >= 0;
}

function presetNoteToSlot(note) {
    var idxA = PRESET_NOTES_A.indexOf(note);
    if (idxA >= 0) return idxA;           // Bank A: slots 0-7
    var idxB = PRESET_NOTES_B.indexOf(note);
    if (idxB >= 0) return idxB + 8;       // Bank B: slots 8-15
    return -1;
}

function isPresetNote(note) {
    return presetNoteToSlot(note) >= 0;
}

// ── Max 1 stem/type/bank enforcement ──
// Only one row per stem type can source from the same bank.
// e.g. if drums row 1 (deck X) sources from A3, drums row 5 (deck Y)
// can also source from A3 (different deck), but row 1 can't also source
// from A5 while A3 is active for drums (the new assignment replaces it).

function findConflictingRow(targetRow, presetSlot) {
    var targetStem = ASSIGN_ROW_STEM[targetRow];
    for (var i = 0; i < 8; i++) {
        if (i === targetRow) continue;
        if (rowAssignments[i] === presetSlot && ASSIGN_ROW_STEM[i] === targetStem) {
            return i;
        }
    }
    return -1;
}

// ── State machine ──

function stemAssignButtonDown(note) {
    var idx = stemAssignButtonIndex(note);
    if (idx < 0) return false;

    // If this row already has a custom assignment and we re-press, reset it
    if (assignState === ASSIGN_IDLE && rowAssignments[idx] !== null) {
        var oldSlot = rowAssignments[idx];
        rowAssignments[idx] = null;
        post("stem-assign: row " + idx + " reset to default (was slot " + oldSlot + ")\n");
        return true;
    }

    assignState = ASSIGN_WAITING;
    assignTargetRow = idx;
    post("stem-assign: WAITING → row " + idx + " (" + ASSIGN_ROW_STEM[idx] + "-" + ASSIGN_ROW_DECK[idx] + ")\n");
    return true;
}

function stemAssignButtonUp(note) {
    var idx = stemAssignButtonIndex(note);
    if (idx < 0) return false;
    if (assignState === ASSIGN_WAITING && assignTargetRow === idx) {
        // Released without selecting a preset — cancel
        assignState = ASSIGN_IDLE;
        assignTargetRow = -1;
        post("stem-assign: cancelled → IDLE\n");
        return true;
    }
    return false;
}

function stemAssignPresetTap(note) {
    if (assignState !== ASSIGN_WAITING) return false;

    var slotIndex = presetNoteToSlot(note);
    if (slotIndex < 0) return false;

    var row = assignTargetRow;

    // Enforce max 1 stem/type/bank: clear any conflicting row
    var conflict = findConflictingRow(row, slotIndex);
    if (conflict >= 0) {
        rowAssignments[conflict] = null;
        post("stem-assign: cleared conflict on row " + conflict + "\n");
    }

    rowAssignments[row] = slotIndex;
    assignState = ASSIGN_IDLE;
    assignTargetRow = -1;

    post("stem-assign: row " + row + " (" + ASSIGN_ROW_STEM[row] + "-" + ASSIGN_ROW_DECK[row] + ") → preset slot " + slotIndex + "\n");
    return true;
}

function isStemAssigning() {
    return assignState === ASSIGN_WAITING;
}

function getAssignState() {
    return {
        state: assignState,
        targetRow: assignTargetRow,
        assignments: rowAssignments.slice(),
    };
}

function getRowAssignment(row) {
    return rowAssignments[row];
}

function getRowStem(row) {
    if (row < 0 || row >= 8) return null;
    return { stem: ASSIGN_ROW_STEM[row], deck: ASSIGN_ROW_DECK[row] };
}

function resetAssign() {
    assignState = ASSIGN_IDLE;
    assignTargetRow = -1;
    rowAssignments = [null, null, null, null, null, null, null, null];
}

// ── Module exports (guarded for test harness) ──
if (typeof module !== "undefined") {
    module.exports = {
        PRESET_NOTES_A: PRESET_NOTES_A,
        PRESET_NOTES_B: PRESET_NOTES_B,
        STEM_ASSIGN_BUTTONS: STEM_ASSIGN_BUTTONS,
        ASSIGN_ROW_STEM: ASSIGN_ROW_STEM,
        ASSIGN_ROW_DECK: ASSIGN_ROW_DECK,
        ASSIGN_IDLE: ASSIGN_IDLE,
        ASSIGN_WAITING: ASSIGN_WAITING,
        stemAssignButtonIndex: stemAssignButtonIndex,
        isStemAssignButton: isStemAssignButton,
        presetNoteToSlot: presetNoteToSlot,
        isPresetNote: isPresetNote,
        stemAssignButtonDown: stemAssignButtonDown,
        stemAssignButtonUp: stemAssignButtonUp,
        stemAssignPresetTap: stemAssignPresetTap,
        isStemAssigning: isStemAssigning,
        getAssignState: getAssignState,
        getRowAssignment: getRowAssignment,
        getRowStem: getRowStem,
        resetAssign: resetAssign,
    };
}
