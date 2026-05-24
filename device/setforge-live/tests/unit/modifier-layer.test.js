'use strict';

const { expect } = require('chai');
const { createModifierLayer, MOD_STATE, MODIFIERS, DOUBLE_TAP_WINDOW_MS } = require('../../src/loader/modifier-layer');

describe('modifier-layer', () => {
  let mods;

  beforeEach(() => {
    mods = createModifierLayer();
  });

  it('initializes all modifiers as idle', () => {
    for (const mod of MODIFIERS) {
      expect(mods.getState(mod)).to.equal(MOD_STATE.IDLE);
    }
  });

  describe('momentary press/release', () => {
    it('press sets held, release sets idle', () => {
      mods.press('HOLD', 1000);
      expect(mods.getState('HOLD')).to.equal(MOD_STATE.HELD);
      expect(mods.isActive('HOLD')).to.be.true;

      mods.release('HOLD');
      expect(mods.getState('HOLD')).to.equal(MOD_STATE.IDLE);
      expect(mods.isActive('HOLD')).to.be.false;
    });
  });

  describe('double-tap latch', () => {
    it('double-tap within window latches', () => {
      mods.press('SOLO', 1000);
      mods.release('SOLO');
      mods.press('SOLO', 1000 + DOUBLE_TAP_WINDOW_MS - 50);
      expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
    });

    it('release does not unlatch', () => {
      mods.press('SOLO', 1000);
      mods.release('SOLO');
      mods.press('SOLO', 1200);
      expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
      mods.release('SOLO');
      expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
    });

    it('tap on latched modifier releases it', () => {
      mods.press('SOLO', 1000);
      mods.release('SOLO');
      mods.press('SOLO', 1200); // latch
      mods.release('SOLO');

      // Third press should unlatch
      mods.press('SOLO', 5000); // well outside double-tap window
      expect(mods.getState('SOLO')).to.equal(MOD_STATE.IDLE);
    });

    it('double-tap outside window does not latch', () => {
      mods.press('MUTE', 1000);
      mods.release('MUTE');
      mods.press('MUTE', 1000 + DOUBLE_TAP_WINDOW_MS + 100);
      expect(mods.getState('MUTE')).to.equal(MOD_STATE.HELD);
    });
  });

  describe('getActive', () => {
    it('returns list of active modifiers', () => {
      mods.press('REV', 1000);
      mods.press('STUT', 1000);
      mods.release('STUT');
      mods.press('STUT', 1100); // latch
      const active = mods.getActive();
      expect(active).to.include('REV');
      expect(active).to.include('STUT');
    });
  });

  describe('snapshot/restore', () => {
    it('round-trips state', () => {
      mods.press('HOLD', 1000);
      mods.release('HOLD');
      mods.press('HOLD', 1200); // latch
      mods.press('KILL', 2000);

      const snap = mods.snapshot();
      expect(snap.HOLD).to.equal(MOD_STATE.LATCHED);
      expect(snap.KILL).to.equal(MOD_STATE.HELD);

      const mods2 = createModifierLayer();
      mods2.restore(snap);
      expect(mods2.getState('HOLD')).to.equal(MOD_STATE.LATCHED);
      expect(mods2.getState('KILL')).to.equal(MOD_STATE.HELD);
    });
  });

  describe('clearAll', () => {
    it('resets everything', () => {
      mods.press('REV', 1000);
      mods.clearAll();
      expect(mods.getActive()).to.be.empty;
    });
  });

  it('ignores unknown modifiers', () => {
    expect(mods.press('NONEXISTENT')).to.equal(MOD_STATE.IDLE);
  });
});
