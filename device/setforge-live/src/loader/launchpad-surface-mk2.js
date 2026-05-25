// ═══════════════════════════════════════════════════════════
//  Launchpad Surface — MK2 concrete implementation
// ═══════════════════════════════════════════════════════════
//
// Launchpad Pro MK2 (USB-B, 7-bit RGB).
// SysEx reference: Novation "Launchpad Pro Programmer's Reference Manual"
//
// This file is concatenated into loader.js by the build script.
// No require() / module.exports — everything is at global scope.

function createMk2Surface() {
    // ── SysEx constants ──
    var SYSEX_HEADER_RGB = [240, 0, 32, 41, 2, 16, 11];  // F0 00 20 29 02 10 0B
    var SYSEX_PROGRAMMER_ENTER = [240, 0, 32, 41, 2, 16, 44, 3, 247];
    var SYSEX_PROGRAMMER_LEAVE = [240, 0, 32, 41, 2, 16, 44, 0, 247];

    // Pulse: F0 00 20 29 02 10 28 <note> <palette_color> F7
    var SYSEX_HEADER_PULSE = [240, 0, 32, 41, 2, 16, 40];
    // Flash: F0 00 20 29 02 10 23 <note> <color_a> <color_b> F7
    var SYSEX_HEADER_FLASH = [240, 0, 32, 41, 2, 16, 35];

    // Side button note numbers (left column, top-to-bottom in programmer mode)
    var SIDE_BUTTONS_LEFT = [80, 70, 60, 50, 40, 30, 20, 10];

    // Max ~78 pads per SysEx before USB buffer limits
    var RGB_CHUNK_SIZE = 70;

    // Pending RGB writes, batched per grid
    var pendingRgb = { 1: [], 2: [] };

    // ── Pad note mapping ──
    // MK2 programmer mode: note = row*10 + col
    // row 1 (bottom) = notes 11-18, row 8 (top) = notes 81-88
    // We flip so spec row 1 = top = LP row 8

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
        model: "mk2",

        noteToRowCol: noteToRowCol,

        rowColToNote: rowColToNote,

        // Returns side button index (0-7) or -1 if not a side button
        sideButtonIndex: function(note) {
            return SIDE_BUTTONS_LEFT.indexOf(note);
        },

        // Queue an RGB write. Colors are 0-127 (MK2 native 7-bit).
        queueRgb: function(grid, row, col, rgb) {
            var note = rowColToNote(row, col);
            pendingRgb[grid].push({ note: note, rgb: rgb });
        },

        // Queue an RGB write for a raw note number (side buttons, etc.)
        queueRgbNote: function(grid, note, rgb) {
            pendingRgb[grid].push({ note: note, rgb: rgb });
        },

        // Flush pending writes as SysEx messages.
        // Returns an array of SysEx byte arrays, or empty array if nothing pending.
        flushRgb: function(grid) {
            var writes = pendingRgb[grid];
            if (!writes || writes.length === 0) return [];

            var messages = [];
            for (var start = 0; start < writes.length; start += RGB_CHUNK_SIZE) {
                var end = Math.min(start + RGB_CHUNK_SIZE, writes.length);
                var msg = SYSEX_HEADER_RGB.slice();
                for (var i = start; i < end; i++) {
                    msg.push(writes[i].note, writes[i].rgb[0], writes[i].rgb[1], writes[i].rgb[2]);
                }
                msg.push(247);
                messages.push(msg);
            }
            pendingRgb[grid] = [];
            return messages;
        },

        // Programmer mode SysEx
        enterProgrammerMode: function() {
            return SYSEX_PROGRAMMER_ENTER;
        },

        leaveProgrammerMode: function() {
            return SYSEX_PROGRAMMER_LEAVE;
        },

        // Pulse a pad at tempo using a palette color index (0-127).
        // MK2 pulse syncs to Live's tempo automatically.
        buildPulseSysex: function(note, paletteIndex) {
            var msg = SYSEX_HEADER_PULSE.slice();
            msg.push(note, paletteIndex, 247);
            return msg;
        },

        // Flash a pad between two palette colors at tempo.
        buildFlashSysex: function(note, colorA, colorB) {
            var msg = SYSEX_HEADER_FLASH.slice();
            msg.push(note, colorA, colorB, 247);
            return msg;
        }
    };
}
