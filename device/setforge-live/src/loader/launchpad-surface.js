'use strict';

/**
 * Launchpad surface — 2× Launchpad MIDI I/O, RGB writes.
 *
 * Handles MIDI note-on/note-off from two Launchpad Pro mk3s,
 * maps pad coordinates to (grid, row, col), and batches RGB
 * color writes to avoid saturating USB MIDI.
 *
 * Launchpad Pro mk3 programmer mode layout:
 *   Bottom-left pad = note 11, rows go up by 10, cols go right by 1
 *   Row 1 (bottom) = notes 11-18
 *   Row 8 (top) = notes 81-88
 *
 * We flip this so our row 1 is the TOP row (conceptually matches the spec).
 */

const GRID_1 = 1;
const GRID_2 = 2;

// Launchpad Pro mk3 note mapping
function noteToRowCol(note) {
  if (note < 11 || note > 88) return null;
  const lpRow = Math.floor(note / 10); // 1-8 from bottom
  const lpCol = note % 10;             // 1-8
  if (lpCol < 1 || lpCol > 8 || lpRow < 1 || lpRow > 8) return null;
  // Flip: our row 1 = LP row 8 (top)
  const row = 9 - lpRow;
  return { row, col: lpCol };
}

function rowColToNote(row, col) {
  if (row < 1 || row > 8 || col < 1 || col > 8) return null;
  const lpRow = 9 - row;
  return lpRow * 10 + col;
}

/**
 * SysEx RGB message for Launchpad Pro mk3.
 * Header: F0 00 20 29 02 0E 03
 * Per-LED: 03 <note> <r> <g> <b>
 * Footer: F7
 */
function buildRgbSysex(noteColorPairs) {
  const header = [0xF0, 0x00, 0x20, 0x29, 0x02, 0x0E, 0x03];
  const body = [];
  for (const { note, rgb } of noteColorPairs) {
    body.push(0x03, note, rgb[0], rgb[1], rgb[2]);
  }
  return [...header, ...body, 0xF7];
}

function createLaunchpadSurface() {
  // Pending RGB writes, batched per bar
  const pendingWrites = { [GRID_1]: [], [GRID_2]: [] };
  const rgbLog = []; // for testing: records all RGB writes

  return {
    /**
     * Convert a MIDI note to grid coordinates.
     */
    noteToRowCol,

    /**
     * Convert grid coordinates to a MIDI note.
     */
    rowColToNote,

    /**
     * Queue an RGB color write for a pad.
     * @param {number} grid - GRID_1 or GRID_2
     * @param {number} row
     * @param {number} col
     * @param {number[]} rgb - [r, g, b] in 0-127
     */
    setColor(grid, row, col, rgb) {
      const note = rowColToNote(row, col);
      if (note === null) return;
      pendingWrites[grid].push({ note, rgb, row, col });
      rgbLog.push({ grid, row, col, rgb, note });
    },

    /**
     * Flush pending writes as SysEx messages.
     * Called on bar boundaries to coalesce updates.
     * @param {number} grid
     * @returns {number[]|null} SysEx bytes, or null if nothing pending
     */
    flush(grid) {
      const writes = pendingWrites[grid];
      if (!writes || writes.length === 0) return null;
      const sysex = buildRgbSysex(writes);
      pendingWrites[grid] = [];
      return sysex;
    },

    /**
     * Get the RGB log (for testing).
     */
    getRgbLog() {
      return rgbLog;
    },

    /**
     * Clear the RGB log.
     */
    clearRgbLog() {
      rgbLog.length = 0;
    },

    /**
     * Clear all pending writes and set all pads to off.
     */
    clearAll() {
      pendingWrites[GRID_1] = [];
      pendingWrites[GRID_2] = [];
      // Queue all-off for both grids
      for (let row = 1; row <= 8; row++) {
        for (let col = 1; col <= 8; col++) {
          this.setColor(GRID_1, row, col, [0, 0, 0]);
          this.setColor(GRID_2, row, col, [0, 0, 0]);
        }
      }
    },
  };
}

module.exports = {
  GRID_1,
  GRID_2,
  noteToRowCol,
  rowColToNote,
  buildRgbSysex,
  createLaunchpadSurface,
};
