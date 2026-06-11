// ═══════════════════════════════════════════════════════════
//  Per-Source LED Coloring (Phase 1.4)
// ═══════════════════════════════════════════════════════════
//
// Each loaded preset gets its own color from LEGEND_PALETTE.
// Stem rows, left stem-assign buttons, and preset buttons all
// wear the source-preset's color so "who's sourcing what" is
// readable at a glance.
//
// KEEP IN SYNC with companion/serve.py LEGEND_PALETTE.

// ── 8-bit hex palette (canonical, matches companion app) ──
var LEGEND_PALETTE_HEX = [
    "#F5A623",  // slot 0 — warm amber
    "#FF7A3D",  // slot 1 — orange
    "#E85B5B",  // slot 2 — red
    "#B058CF",  // slot 3 — purple
    "#8C7BFF",  // slot 4 — indigo
    "#34C8E8",  // slot 5 — cyan
    "#3DCC91",  // slot 6 — green
    "#8BC34A",  // slot 7 — lime
];

// ── Pre-computed 7-bit RGB arrays for MK2 SysEx (0–127) ──
var LEGEND_PALETTE_7BIT = [];

function hexTo7bit(hex) {
    var r = parseInt(hex.slice(1, 3), 16);
    var g = parseInt(hex.slice(3, 5), 16);
    var b = parseInt(hex.slice(5, 7), 16);
    return [
        Math.round(r * 127 / 255),
        Math.round(g * 127 / 255),
        Math.round(b * 127 / 255)
    ];
}

// Initialize palette
for (var _pi = 0; _pi < LEGEND_PALETTE_HEX.length; _pi++) {
    LEGEND_PALETTE_7BIT.push(hexTo7bit(LEGEND_PALETTE_HEX[_pi]));
}

// ── Dim default color (unsourced rows) ──
var DIM_DEFAULT = [8, 8, 8];   // very dim white
var OFF_COLOR = [0, 0, 0];

// ── Color lookups ──

function sourceColor7bit(slotIndex) {
    // Slot 0-7 = bank A, 8-15 = bank B; palette wraps at 8
    var paletteIdx = slotIndex % 8;
    if (paletteIdx < 0 || paletteIdx >= LEGEND_PALETTE_7BIT.length) return DIM_DEFAULT;
    return LEGEND_PALETTE_7BIT[paletteIdx];
}

function sourceColorHex(slotIndex) {
    var paletteIdx = slotIndex % 8;
    if (paletteIdx < 0 || paletteIdx >= LEGEND_PALETTE_HEX.length) return null;
    return LEGEND_PALETTE_HEX[paletteIdx];
}

// ── LED application ──
// These use the surface + stem-assign state to drive LED writes.
// The caller must flush after calling these.

function applySourceLeds(surfaceObj, grid) {
    if (!surfaceObj || !surfaceObj.queueRgb) return;

    for (var row = 0; row < 8; row++) {
        var assignment = (typeof getRowAssignment === "function") ? getRowAssignment(row) : null;
        var color = (assignment !== null) ? sourceColor7bit(assignment) : DIM_DEFAULT;

        // Color all 8 chop pads in this row
        var specRow = row + 1;  // spec rows are 1-based
        for (var col = 1; col <= 8; col++) {
            surfaceObj.queueRgb(grid, specRow, col, color);
        }

        // Color the left stem-assign button
        if (surfaceObj.queueRgbNote && typeof STEM_ASSIGN_BUTTONS !== "undefined") {
            surfaceObj.queueRgbNote(grid, STEM_ASSIGN_BUTTONS[row], color);
        }

        // Color the source preset button (top for bank A, bottom for bank B)
        if (assignment !== null && surfaceObj.queueRgbNote) {
            if (assignment < 8 && typeof PRESET_NOTES_A !== "undefined") {
                surfaceObj.queueRgbNote(grid, PRESET_NOTES_A[assignment], color);
            } else if (assignment >= 8 && typeof PRESET_NOTES_B !== "undefined") {
                surfaceObj.queueRgbNote(grid, PRESET_NOTES_B[assignment - 8], color);
            }
        }
    }
}

function dimAllPresetButtons(surfaceObj, grid) {
    if (!surfaceObj || !surfaceObj.queueRgbNote) return;
    if (typeof PRESET_NOTES_A !== "undefined") {
        for (var i = 0; i < PRESET_NOTES_A.length; i++) {
            surfaceObj.queueRgbNote(grid, PRESET_NOTES_A[i], OFF_COLOR);
        }
    }
    if (typeof PRESET_NOTES_B !== "undefined") {
        for (var j = 0; j < PRESET_NOTES_B.length; j++) {
            surfaceObj.queueRgbNote(grid, PRESET_NOTES_B[j], OFF_COLOR);
        }
    }
}

// ── Module exports (guarded for test harness) ──
if (typeof module !== "undefined") {
    module.exports = {
        LEGEND_PALETTE_HEX: LEGEND_PALETTE_HEX,
        LEGEND_PALETTE_7BIT: LEGEND_PALETTE_7BIT,
        DIM_DEFAULT: DIM_DEFAULT,
        OFF_COLOR: OFF_COLOR,
        hexTo7bit: hexTo7bit,
        sourceColor7bit: sourceColor7bit,
        sourceColorHex: sourceColorHex,
        applySourceLeds: applySourceLeds,
        dimAllPresetButtons: dimAllPresetButtons,
    };
}
