// ═══════════════════════════════════════════════════════════
//  Launchpad Surface — MK3 stub
// ═══════════════════════════════════════════════════════════
//
// Launchpad Pro MK3 (USB-C, 8-bit RGB).
// Stub implementation — same interface as MK2, MK3-specific SysEx.
//
// This file is concatenated into loader.js by the build script.

function createMk3Surface() {
    var SYSEX_HEADER_RGB = [240, 0, 32, 41, 2, 14, 3];  // F0 00 20 29 02 0E 03
    var SYSEX_PROGRAMMER_ENTER = [240, 0, 32, 41, 2, 14, 14, 1, 247];
    var SYSEX_PROGRAMMER_LEAVE = [240, 0, 32, 41, 2, 14, 14, 0, 247];

    // MK3 side buttons — TODO: confirm note numbers from MK3 programmer ref
    var SIDE_BUTTONS_LEFT = [80, 70, 60, 50, 40, 30, 20, 10];

    var RGB_CHUNK_SIZE = 70;
    var pendingRgb = { 1: [], 2: [] };

    // MK3 pad mapping is the same as MK2
    function noteToRowCol(note) {
        if (note < 11 || note > 88) return null;
        var lpRow = Math.floor(note / 10);
        var lpCol = note % 10;
        if (lpCol < 1 || lpCol > 8 || lpRow < 1 || lpRow > 8) return null;
        return { row: 9 - lpRow, col: lpCol };
    }

    function rowColToNote(row, col) {
        return (9 - row) * 10 + col;
    }

    return {
        model: "mk3",

        noteToRowCol: noteToRowCol,

        rowColToNote: rowColToNote,

        sideButtonIndex: function(note) {
            return SIDE_BUTTONS_LEFT.indexOf(note);
        },

        // MK3 accepts 7-bit RGB same as MK2 but per-LED prefix is 0x03
        queueRgb: function(grid, row, col, rgb) {
            var note = rowColToNote(row, col);
            pendingRgb[grid].push({ note: note, rgb: rgb });
        },

        queueRgbNote: function(grid, note, rgb) {
            pendingRgb[grid].push({ note: note, rgb: rgb });
        },

        flushRgb: function(grid) {
            var writes = pendingRgb[grid];
            if (!writes || writes.length === 0) return [];

            var messages = [];
            for (var start = 0; start < writes.length; start += RGB_CHUNK_SIZE) {
                var end = Math.min(start + RGB_CHUNK_SIZE, writes.length);
                var msg = SYSEX_HEADER_RGB.slice();
                for (var i = start; i < end; i++) {
                    // MK3: per-LED prefix 0x03 before each note/rgb group
                    msg.push(3, writes[i].note, writes[i].rgb[0], writes[i].rgb[1], writes[i].rgb[2]);
                }
                msg.push(247);
                messages.push(msg);
            }
            pendingRgb[grid] = [];
            return messages;
        },

        enterProgrammerMode: function() {
            return SYSEX_PROGRAMMER_ENTER;
        },

        leaveProgrammerMode: function() {
            return SYSEX_PROGRAMMER_LEAVE;
        },

        // TODO: MK3 pulse/flash SysEx — confirm from MK3 programmer ref
        buildPulseSysex: function(note, paletteIndex) {
            return null;
        },

        buildFlashSysex: function(note, colorA, colorB) {
            return null;
        }
    };
}
