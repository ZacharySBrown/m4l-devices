'use strict';

const { expect } = require('chai');
const { createPresetBanks, SLOT_STATE, TOTAL_SLOTS, SLOTS_PER_BANK } = require('../../src/loader/preset-banks');

describe('preset-banks', () => {
  let banks;

  beforeEach(() => {
    banks = createPresetBanks();
  });

  it('initializes 16 empty slots', () => {
    const slots = banks.getSlots();
    expect(slots).to.have.lengthOf(TOTAL_SLOTS);
    for (const slot of slots) {
      expect(slot.state).to.equal(SLOT_STATE.EMPTY);
    }
  });

  it('slots 0-7 are bank A, 8-15 are bank B', () => {
    expect(banks.getSlot(0).bank).to.equal('A');
    expect(banks.getSlot(7).bank).to.equal('A');
    expect(banks.getSlot(8).bank).to.equal('B');
    expect(banks.getSlot(15).bank).to.equal('B');
  });

  describe('loadSlot', () => {
    it('loads a track into a slot', () => {
      banks.loadSlot(0, 'track_a', { bpm: 120 }, { drums: [] });
      const slot = banks.getSlot(0);
      expect(slot.state).to.equal(SLOT_STATE.LOADED_IDLE);
      expect(slot.trackId).to.equal('track_a');
    });

    it('throws on out-of-range index', () => {
      expect(() => banks.loadSlot(16, 'x', {}, {})).to.throw();
      expect(() => banks.loadSlot(-1, 'x', {}, {})).to.throw();
    });
  });

  describe('activate', () => {
    it('activates a loaded slot', () => {
      banks.loadSlot(2, 'track_c', {}, {});
      const result = banks.activate(2);
      expect(result.current).to.equal(2);
      expect(result.previous).to.be.null;
      expect(banks.getSlot(2).state).to.equal(SLOT_STATE.LOADED_ACTIVE);
    });

    it('deactivates previous on new activation', () => {
      banks.loadSlot(0, 'a', {}, {});
      banks.loadSlot(1, 'b', {}, {});
      banks.activate(0);
      banks.activate(1);
      expect(banks.getSlot(0).state).to.equal(SLOT_STATE.LOADED_IDLE);
      expect(banks.getSlot(1).state).to.equal(SLOT_STATE.LOADED_ACTIVE);
    });

    it('returns null for empty slot', () => {
      expect(banks.activate(0)).to.be.null;
    });
  });

  describe('findByTrackId', () => {
    it('finds a loaded track', () => {
      banks.loadSlot(5, 'my_track', {}, {});
      const slot = banks.findByTrackId('my_track');
      expect(slot.index).to.equal(5);
    });

    it('returns null for unknown track', () => {
      expect(banks.findByTrackId('nope')).to.be.null;
    });
  });

  describe('findNextEmpty', () => {
    it('finds first empty slot', () => {
      banks.loadSlot(0, 'a', {}, {});
      const empty = banks.findNextEmpty();
      expect(empty.index).to.equal(1);
    });

    it('finds empty in bank B only', () => {
      const empty = banks.findNextEmpty('B');
      expect(empty.index).to.equal(8);
    });

    it('returns null when bank is full', () => {
      for (let i = 0; i < SLOTS_PER_BANK; i++) {
        banks.loadSlot(i, `t${i}`, {}, {});
      }
      expect(banks.findNextEmpty('A')).to.be.null;
    });
  });

  describe('clearAll', () => {
    it('clears all slots and active', () => {
      banks.loadSlot(0, 'a', {}, {});
      banks.activate(0);
      banks.clearAll();
      expect(banks.getActive()).to.be.null;
      for (const slot of banks.getSlots()) {
        expect(slot.state).to.equal(SLOT_STATE.EMPTY);
      }
    });
  });

  describe('getBankA / getBankB', () => {
    it('returns correct slices', () => {
      expect(banks.getBankA()).to.have.lengthOf(8);
      expect(banks.getBankB()).to.have.lengthOf(8);
      expect(banks.getBankA()[0].index).to.equal(0);
      expect(banks.getBankB()[0].index).to.equal(8);
    });
  });
});
