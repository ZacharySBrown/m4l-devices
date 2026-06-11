'use strict';

/**
 * Unit tests for punch-layer.js (punch-FX gesture state machine).
 *
 * Runs headless — tests the module directly via require(), not via
 * the concat'd loader.js. The production code works the same way
 * after concatenation (plain script scope).
 */

const { expect } = require('chai');

// Load the module (guarded module.exports)
const punch = require('../../src/loader/punch-layer');

// Provide globals that punch-layer.js references from concat scope
// (post, stemTrackIdsX, stemTrackIdsY, surface, getPadPressure)
global.post = function() {};
global.stemTrackIdsX = {
  drums: 'live_set tracks 5',
  bass: 'live_set tracks 6',
  other: 'live_set tracks 7',
  vox: 'live_set tracks 8',
};
global.stemTrackIdsY = {
  drums: 'live_set tracks 9',
  bass: 'live_set tracks 10',
  other: 'live_set tracks 11',
  vox: 'live_set tracks 12',
};
global.surface = {
  noteToRowCol(note) {
    const lpRow = Math.floor(note / 10);
    const lpCol = note % 10;
    if (lpCol < 1 || lpCol > 8 || lpRow < 1 || lpRow > 8) return null;
    return { row: 9 - lpRow, col: lpCol };
  },
  rowColToNote(row, col) {
    return (9 - row) * 10 + col;
  },
};
global.getPadPressure = function() { return 0; };

describe('punch-layer', () => {
  let sinkCalls;

  beforeEach(() => {
    punch.resetPunch();
    sinkCalls = [];
    punch.setPunchSink((target, effect, on, amount) => {
      sinkCalls.push({ target, effect, on, amount });
    });
  });

  describe('isPunchButton', () => {
    it('recognizes punch button notes', () => {
      expect(punch.isPunchButton(89)).to.be.true;
      expect(punch.isPunchButton(79)).to.be.true;
      expect(punch.isPunchButton(69)).to.be.true;
      expect(punch.isPunchButton(59)).to.be.true;
    });

    it('rejects non-punch notes', () => {
      expect(punch.isPunchButton(81)).to.be.false;
      expect(punch.isPunchButton(49)).to.be.false;
    });
  });

  describe('state transitions', () => {
    it('starts in IDLE', () => {
      expect(punch.getPunchState().state).to.equal('idle');
      expect(punch.isPunchFxActive()).to.be.false;
    });

    it('enters FX_APPLY on punch button down', () => {
      punch.punchButtonDown(89);
      expect(punch.getPunchState().state).to.equal('fx_apply');
      expect(punch.getPunchState().effect).to.equal('REPEAT');
      expect(punch.isPunchFxActive()).to.be.true;
    });

    it('returns to IDLE on punch button up', () => {
      punch.punchButtonDown(89);
      punch.punchButtonUp(89);
      expect(punch.getPunchState().state).to.equal('idle');
      expect(punch.isPunchFxActive()).to.be.false;
    });

    it('last button wins (one effect at a time)', () => {
      punch.punchButtonDown(89);  // REPEAT
      expect(punch.getPunchState().effect).to.equal('REPEAT');
      punch.punchButtonDown(69);  // SLICER
      expect(punch.getPunchState().effect).to.equal('SLICER');
    });
  });

  describe('resolveFxTarget (per-stem)', () => {
    it('row 1 → drums-x', () => {
      const t = punch.resolveFxTarget(1, 1, 'per-stem');
      expect(t).to.deep.include({ stem: 'drums', deck: 'x' });
      expect(t.trackPath).to.equal('live_set tracks 5');
    });

    it('row 4 → vox-x', () => {
      const t = punch.resolveFxTarget(4, 1, 'per-stem');
      expect(t).to.deep.include({ stem: 'vox', deck: 'x' });
    });

    it('row 5 → drums-y', () => {
      const t = punch.resolveFxTarget(5, 1, 'per-stem');
      expect(t).to.deep.include({ stem: 'drums', deck: 'y' });
      expect(t.trackPath).to.equal('live_set tracks 9');
    });

    it('row 8 → vox-y', () => {
      const t = punch.resolveFxTarget(8, 1, 'per-stem');
      expect(t).to.deep.include({ stem: 'vox', deck: 'y' });
    });

    it('row 0 → null (out of range)', () => {
      expect(punch.resolveFxTarget(0, 1, 'per-stem')).to.be.null;
    });

    it('future modes return sentinels', () => {
      const da = punch.resolveFxTarget(1, 1, 'deckA');
      expect(da.stem).to.equal('all');
      expect(da.deck).to.equal('x');
    });
  });

  describe('pad engage/disengage', () => {
    it('engaging a pad calls applyPunch(on=true)', () => {
      punch.punchButtonDown(89);  // REPEAT
      punch.punchPadDown(1, 1, 1);  // drums row, col 1
      expect(sinkCalls).to.have.length(1);
      expect(sinkCalls[0].target).to.equal('live_set tracks 5');
      expect(sinkCalls[0].effect).to.equal('REPEAT');
      expect(sinkCalls[0].on).to.be.true;
    });

    it('releasing a pad calls applyPunch(on=false)', () => {
      punch.punchButtonDown(89);
      punch.punchPadDown(1, 1, 1);
      punch.punchPadUp(1, 1, 1);
      expect(sinkCalls).to.have.length(2);
      expect(sinkCalls[1].on).to.be.false;
      expect(sinkCalls[1].amount).to.equal(0);
    });

    it('releasing the punch button disengages all active targets', () => {
      punch.punchButtonDown(79);  // STUTTER
      punch.punchPadDown(1, 1, 1);  // drums
      punch.punchPadDown(1, 2, 1);  // bass
      sinkCalls = [];
      punch.punchButtonUp(79);
      // Should disengage both
      expect(sinkCalls.length).to.be.at.least(2);
      expect(sinkCalls.every(c => c.on === false)).to.be.true;
    });

    it('does nothing in IDLE state', () => {
      const result = punch.punchPadDown(1, 1, 1);
      expect(result).to.be.false;
      expect(sinkCalls).to.have.length(0);
    });
  });

  describe('multi-pad independent amounts', () => {
    it('tracks multiple pads simultaneously', () => {
      punch.punchButtonDown(89);  // REPEAT
      punch.punchPadDown(1, 1, 1);  // drums
      punch.punchPadDown(1, 2, 1);  // bass
      const state = punch.getPunchState();
      expect(Object.keys(state.targets)).to.have.length(2);
    });
  });

  describe('pressure update', () => {
    it('updates amount via punchUpdatePressure', () => {
      punch.punchButtonDown(89);
      punch.punchPadDown(1, 1, 1);  // drums-x, note 81
      sinkCalls = [];
      punch.punchUpdatePressure(1, 81, 0.75);
      expect(sinkCalls).to.have.length(1);
      expect(sinkCalls[0].amount).to.equal(0.75);
      expect(sinkCalls[0].on).to.be.true;
    });

    it('ignores pressure for pads not engaged', () => {
      punch.punchButtonDown(89);
      // Don't press any pad — just send pressure
      sinkCalls = [];
      punch.punchUpdatePressure(1, 81, 0.5);
      expect(sinkCalls).to.have.length(0);
    });
  });

  describe('FX_APPLY suppresses chop-trigger', () => {
    it('isPunchFxActive returns true during FX_APPLY', () => {
      expect(punch.isPunchFxActive()).to.be.false;
      punch.punchButtonDown(89);
      expect(punch.isPunchFxActive()).to.be.true;
    });

    it('punchPadDown returns true (handled) during FX_APPLY', () => {
      punch.punchButtonDown(89);
      const handled = punch.punchPadDown(1, 1, 1);
      expect(handled).to.be.true;
    });
  });

  describe('guarded sink', () => {
    it('no-ops without a device (no sink set)', () => {
      punch.setPunchSink(null);
      punch.punchButtonDown(89);
      // Should not throw
      expect(() => punch.punchPadDown(1, 1, 1)).to.not.throw();
    });
  });
});
