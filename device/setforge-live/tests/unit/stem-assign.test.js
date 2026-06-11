'use strict';

/**
 * Unit tests for stem-assign.js (left-button + preset-tap gesture).
 * Runs headless — tests the module directly.
 */

const { expect } = require('chai');
const sa = require('../../src/loader/stem-assign');

// Provide globals
global.post = function() {};

describe('stem-assign gesture', () => {
  beforeEach(() => {
    sa.resetAssign();
  });

  describe('button recognition', () => {
    it('recognizes left side buttons', () => {
      expect(sa.isStemAssignButton(80)).to.be.true;   // row 0 (drums-x)
      expect(sa.isStemAssignButton(10)).to.be.true;   // row 7 (vox-y)
      expect(sa.isStemAssignButton(81)).to.be.false;   // grid pad
    });

    it('maps button note to row index', () => {
      expect(sa.stemAssignButtonIndex(80)).to.equal(0);
      expect(sa.stemAssignButtonIndex(70)).to.equal(1);
      expect(sa.stemAssignButtonIndex(10)).to.equal(7);
    });

    it('recognizes preset notes', () => {
      expect(sa.isPresetNote(91)).to.be.true;   // A1
      expect(sa.isPresetNote(98)).to.be.true;   // A8
      expect(sa.isPresetNote(1)).to.be.true;    // B1
      expect(sa.isPresetNote(8)).to.be.true;    // B8
      expect(sa.isPresetNote(81)).to.be.false;   // grid pad
    });

    it('maps preset notes to slot indices', () => {
      expect(sa.presetNoteToSlot(91)).to.equal(0);   // A1 → slot 0
      expect(sa.presetNoteToSlot(98)).to.equal(7);   // A8 → slot 7
      expect(sa.presetNoteToSlot(1)).to.equal(8);    // B1 → slot 8
      expect(sa.presetNoteToSlot(8)).to.equal(15);   // B8 → slot 15
    });
  });

  describe('state transitions', () => {
    it('starts in IDLE', () => {
      expect(sa.getAssignState().state).to.equal('idle');
    });

    it('enters WAITING on left button down', () => {
      sa.stemAssignButtonDown(80);  // row 0 = drums-x
      const state = sa.getAssignState();
      expect(state.state).to.equal('waiting');
      expect(state.targetRow).to.equal(0);
    });

    it('cancels on left button release without preset tap', () => {
      sa.stemAssignButtonDown(80);
      sa.stemAssignButtonUp(80);
      expect(sa.getAssignState().state).to.equal('idle');
    });

    it('completes assignment on preset tap while WAITING', () => {
      sa.stemAssignButtonDown(80);  // hold row 0 (drums-x)
      const handled = sa.stemAssignPresetTap(93);  // tap A3 (slot 2)
      expect(handled).to.be.true;
      expect(sa.getAssignState().state).to.equal('idle');
      expect(sa.getRowAssignment(0)).to.equal(2);
    });

    it('ignores preset tap when not WAITING', () => {
      const handled = sa.stemAssignPresetTap(91);
      expect(handled).to.be.false;
    });
  });

  describe('row stem resolution', () => {
    it('row 0 → drums-x', () => {
      expect(sa.getRowStem(0)).to.deep.equal({ stem: 'drums', deck: 'x' });
    });

    it('row 3 → vox-x', () => {
      expect(sa.getRowStem(3)).to.deep.equal({ stem: 'vox', deck: 'x' });
    });

    it('row 4 → drums-y', () => {
      expect(sa.getRowStem(4)).to.deep.equal({ stem: 'drums', deck: 'y' });
    });

    it('row 7 → vox-y', () => {
      expect(sa.getRowStem(7)).to.deep.equal({ stem: 'vox', deck: 'y' });
    });

    it('invalid row → null', () => {
      expect(sa.getRowStem(-1)).to.be.null;
      expect(sa.getRowStem(8)).to.be.null;
    });
  });

  describe('bank A vs B preset assignment', () => {
    it('top button (note 91) assigns bank A slot 0', () => {
      sa.stemAssignButtonDown(80);
      sa.stemAssignPresetTap(91);
      expect(sa.getRowAssignment(0)).to.equal(0);
    });

    it('bottom button (note 3) assigns bank B slot 10', () => {
      sa.stemAssignButtonDown(70);  // row 1 = bass-x
      sa.stemAssignPresetTap(3);    // B3 → slot 10
      expect(sa.getRowAssignment(1)).to.equal(10);
    });
  });

  describe('reset row to default', () => {
    it('re-pressing an assigned row resets it', () => {
      // First: assign row 0 to A3
      sa.stemAssignButtonDown(80);
      sa.stemAssignPresetTap(93);
      expect(sa.getRowAssignment(0)).to.equal(2);

      // Re-press row 0 while IDLE → reset
      sa.stemAssignButtonDown(80);
      expect(sa.getRowAssignment(0)).to.be.null;
      // Should stay in IDLE (not enter WAITING)
      expect(sa.getAssignState().state).to.equal('idle');
    });
  });

  describe('max 1 stem/type/bank enforcement', () => {
    it('assigning same preset to same stem type clears the conflict', () => {
      // Row 0 (drums-x) → A3
      sa.stemAssignButtonDown(80);
      sa.stemAssignPresetTap(93);
      expect(sa.getRowAssignment(0)).to.equal(2);

      // Row 4 (drums-y, same stem type) → A3 (same preset)
      sa.stemAssignButtonDown(40);
      sa.stemAssignPresetTap(93);
      expect(sa.getRowAssignment(4)).to.equal(2);
      // Row 0 should be cleared (conflict: same stem type, same preset)
      expect(sa.getRowAssignment(0)).to.be.null;
    });

    it('different stem types can share a preset', () => {
      // Row 0 (drums-x) → A3
      sa.stemAssignButtonDown(80);
      sa.stemAssignPresetTap(93);

      // Row 1 (bass-x) → A3 (different stem type, OK)
      sa.stemAssignButtonDown(70);
      sa.stemAssignPresetTap(93);

      expect(sa.getRowAssignment(0)).to.equal(2);  // drums still assigned
      expect(sa.getRowAssignment(1)).to.equal(2);  // bass also assigned
    });
  });

  describe('isStemAssigning', () => {
    it('returns true while WAITING', () => {
      expect(sa.isStemAssigning()).to.be.false;
      sa.stemAssignButtonDown(80);
      expect(sa.isStemAssigning()).to.be.true;
    });
  });

  describe('non-gesture preset tap passthrough', () => {
    it('returns false when not in WAITING state', () => {
      // Normal preset tap should not be consumed
      expect(sa.stemAssignPresetTap(91)).to.be.false;
    });
  });
});
