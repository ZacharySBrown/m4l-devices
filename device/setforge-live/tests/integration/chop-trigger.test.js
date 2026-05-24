'use strict';

const { expect } = require('chai');
const { parseManifest } = require('../../src/shared/manifest-reader');
const { computeTrackChops } = require('../../src/shared/chop-math');
const { createPresetBanks } = require('../../src/loader/preset-banks');
const { createChopRouter, CHOP_STATE } = require('../../src/loader/chop-router');
const { createModifierLayer } = require('../../src/loader/modifier-layer');
const { ROW_QUANT_DEFAULTS } = require('../../src/shared/live-api-helpers');
const { loadManifest } = require('../harness/fixture-loader');

describe('integration: chop-trigger', () => {
  let banks, router, mods;

  beforeEach(() => {
    banks = createPresetBanks();
    router = createChopRouter(banks);
    mods = createModifierLayer();

    // Load a track and activate it
    const manifest = loadManifest('hiphop_v3');
    const track = manifest.tracks[0]; // the_next_episode
    const chops = computeTrackChops(track);
    banks.loadSlot(0, 'the_next_episode', track, chops);
    banks.activate(0);
  });

  it('triggers drum chop with correct start marker and quant', () => {
    const result = router.press(2, 3, mods); // row 2 (drums), col 3

    expect(result).to.not.be.null;
    expect(result.action).to.equal('start');
    expect(result.stem).to.equal('drums');
    expect(result.column).to.equal(3);
    expect(result.chop.clipStart).to.be.a('number');
    expect(result.chop.clipStart).to.be.greaterThan(0);
    expect(result.quant).to.equal(ROW_QUANT_DEFAULTS.drums);
  });

  it('pad lights playing after trigger', () => {
    router.press(2, 3, mods);
    expect(router.padState(2, 3)).to.equal(CHOP_STATE.PLAYING);
    expect(router.padState(2, 1)).to.equal(CHOP_STATE.LOADED);
  });

  it('replaces chop in same row', () => {
    router.press(2, 1, mods);
    expect(router.getPlaying('drums')).to.equal(1);

    const result = router.press(2, 5, mods);
    expect(result.action).to.equal('replace');
    expect(router.getPlaying('drums')).to.equal(5);
  });

  it('toggles off on re-press', () => {
    router.press(2, 1, mods);
    const result = router.press(2, 1, mods);
    expect(result.action).to.equal('stop');
    expect(router.getPlaying('drums')).to.be.null;
  });

  it('allows one chop per stem row, multiple rows simultaneously', () => {
    router.press(2, 1, mods); // drums
    router.press(3, 1, mods); // bass
    router.press(4, 3, mods); // other
    router.press(5, 2, mods); // vox

    expect(router.getPlaying('drums')).to.equal(1);
    expect(router.getPlaying('bass')).to.equal(1);
    expect(router.getPlaying('other')).to.equal(3);
    expect(router.getPlaying('vox')).to.equal(2);

    const held = router.getHeldChops();
    expect(held).to.have.lengthOf(4);
  });

  it('HOLD modifier triggers one_shot action', () => {
    mods.press('HOLD', 1000);
    const result = router.press(2, 1, mods);
    expect(result.action).to.equal('one_shot');
  });

  it('returns null for non-stem row', () => {
    expect(router.press(1, 1, mods)).to.be.null;  // preset row
    expect(router.press(6, 1, mods)).to.be.null;  // modifier row
    expect(router.press(8, 1, mods)).to.be.null;  // scene row
  });

  it('returns null when no preset is active', () => {
    banks.clearAll();
    expect(router.press(2, 1, mods)).to.be.null;
  });

  describe('varying track', () => {
    beforeEach(() => {
      const manifest = loadManifest('varying_track');
      const track = manifest.tracks[0];
      const chops = computeTrackChops(track);
      banks.loadSlot(1, 'sicko_mode', track, chops);
      banks.activate(1);
    });

    it('D1 on varying track plays full mix', () => {
      const result = router.press(2, 1, mods);
      expect(result).to.not.be.null;
      expect(result.action).to.equal('play_full');
    });

    it('other chop pads return null on varying track', () => {
      expect(router.press(2, 2, mods)).to.be.null;
      expect(router.press(3, 1, mods)).to.be.null;
    });

    it('pads show disabled state', () => {
      expect(router.padState(2, 1)).to.equal(CHOP_STATE.DISABLED);
    });
  });
});
