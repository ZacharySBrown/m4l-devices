'use strict';

/**
 * Unit tests for source-led.js (per-source LED coloring).
 * Verifies palette conversion, color lookup, and LED application.
 */

const { expect } = require('chai');

// Provide globals before requiring source-led (it references stem-assign globals)
global.post = function() {};
global.STEM_ASSIGN_BUTTONS = [80, 70, 60, 50, 40, 30, 20, 10];
global.PRESET_NOTES_A = [91, 92, 93, 94, 95, 96, 97, 98];
global.PRESET_NOTES_B = [1, 2, 3, 4, 5, 6, 7, 8];

// Mock getRowAssignment (from stem-assign)
let mockAssignments = [null, null, null, null, null, null, null, null];
global.getRowAssignment = function(row) { return mockAssignments[row]; };

const led = require('../../src/loader/source-led');

describe('source-led', () => {
  beforeEach(() => {
    mockAssignments = [null, null, null, null, null, null, null, null];
  });

  describe('hexTo7bit', () => {
    it('converts #F5A623 to 7-bit RGB', () => {
      const rgb = led.hexTo7bit('#F5A623');
      // F5 = 245 → round(245*127/255) = 122
      // A6 = 166 → round(166*127/255) = 83
      // 23 = 35  → round(35*127/255) = 17
      expect(rgb[0]).to.equal(122);
      expect(rgb[1]).to.equal(83);
      expect(rgb[2]).to.equal(17);
    });

    it('converts #000000 to [0,0,0]', () => {
      expect(led.hexTo7bit('#000000')).to.deep.equal([0, 0, 0]);
    });

    it('converts #FFFFFF to [127,127,127]', () => {
      expect(led.hexTo7bit('#FFFFFF')).to.deep.equal([127, 127, 127]);
    });
  });

  describe('LEGEND_PALETTE_7BIT', () => {
    it('has 8 entries', () => {
      expect(led.LEGEND_PALETTE_7BIT).to.have.length(8);
    });

    it('each entry is a 3-element array with values 0-127', () => {
      for (const rgb of led.LEGEND_PALETTE_7BIT) {
        expect(rgb).to.have.length(3);
        for (const c of rgb) {
          expect(c).to.be.at.least(0);
          expect(c).to.be.at.most(127);
        }
      }
    });
  });

  describe('LEGEND_PALETTE_HEX matches companion', () => {
    // Must stay in sync with companion/serve.py LEGEND_PALETTE
    const COMPANION_PALETTE = [
      '#F5A623', '#FF7A3D', '#E85B5B', '#B058CF',
      '#8C7BFF', '#34C8E8', '#3DCC91', '#8BC34A',
    ];

    it('matches the companion app palette exactly', () => {
      expect(led.LEGEND_PALETTE_HEX).to.deep.equal(COMPANION_PALETTE);
    });
  });

  describe('sourceColor7bit', () => {
    it('slot 0 → palette[0]', () => {
      expect(led.sourceColor7bit(0)).to.deep.equal(led.LEGEND_PALETTE_7BIT[0]);
    });

    it('slot 7 → palette[7]', () => {
      expect(led.sourceColor7bit(7)).to.deep.equal(led.LEGEND_PALETTE_7BIT[7]);
    });

    it('slot 8 (bank B) → palette[0] (wraps)', () => {
      expect(led.sourceColor7bit(8)).to.deep.equal(led.LEGEND_PALETTE_7BIT[0]);
    });

    it('slot 10 → palette[2]', () => {
      expect(led.sourceColor7bit(10)).to.deep.equal(led.LEGEND_PALETTE_7BIT[2]);
    });
  });

  describe('applySourceLeds', () => {
    let rgbWrites, rgbNoteWrites;
    let mockSurface;

    beforeEach(() => {
      rgbWrites = [];
      rgbNoteWrites = [];
      mockSurface = {
        queueRgb(grid, row, col, rgb) {
          rgbWrites.push({ grid, row, col, rgb });
        },
        queueRgbNote(grid, note, rgb) {
          rgbNoteWrites.push({ grid, note, rgb });
        },
      };
    });

    it('unsourced rows get DIM_DEFAULT color', () => {
      led.applySourceLeds(mockSurface, 1);
      // Row 1 (spec) = 8 pads
      const row1Writes = rgbWrites.filter(w => w.row === 1);
      expect(row1Writes).to.have.length(8);
      for (const w of row1Writes) {
        expect(w.rgb).to.deep.equal(led.DIM_DEFAULT);
      }
    });

    it('sourced row gets source-preset color', () => {
      mockAssignments[0] = 2;  // row 0 → slot 2 (palette[2])
      led.applySourceLeds(mockSurface, 1);
      const row1Writes = rgbWrites.filter(w => w.row === 1);
      expect(row1Writes).to.have.length(8);
      for (const w of row1Writes) {
        expect(w.rgb).to.deep.equal(led.LEGEND_PALETTE_7BIT[2]);
      }
    });

    it('left stem-assign button gets source color', () => {
      mockAssignments[0] = 3;  // row 0 → slot 3
      led.applySourceLeds(mockSurface, 1);
      const leftBtn = rgbNoteWrites.find(w => w.note === 80);
      expect(leftBtn).to.exist;
      expect(leftBtn.rgb).to.deep.equal(led.LEGEND_PALETTE_7BIT[3]);
    });

    it('source preset button (bank A) gets source color', () => {
      mockAssignments[0] = 2;  // row 0 → slot 2 (bank A)
      led.applySourceLeds(mockSurface, 1);
      // PRESET_NOTES_A[2] = 93
      const presetBtn = rgbNoteWrites.find(w => w.note === 93);
      expect(presetBtn).to.exist;
      expect(presetBtn.rgb).to.deep.equal(led.LEGEND_PALETTE_7BIT[2]);
    });

    it('source preset button (bank B) gets source color', () => {
      mockAssignments[1] = 10;  // row 1 → slot 10 (bank B, palette[2])
      led.applySourceLeds(mockSurface, 1);
      // PRESET_NOTES_B[10-8] = PRESET_NOTES_B[2] = 3
      const presetBtn = rgbNoteWrites.find(w => w.note === 3);
      expect(presetBtn).to.exist;
      expect(presetBtn.rgb).to.deep.equal(led.LEGEND_PALETTE_7BIT[2]);
    });

    it('writes to all 8 rows × 8 cols = 64 grid pads', () => {
      led.applySourceLeds(mockSurface, 1);
      expect(rgbWrites).to.have.length(64);
    });
  });
});
