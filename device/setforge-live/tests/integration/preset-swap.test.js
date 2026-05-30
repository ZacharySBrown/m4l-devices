'use strict';

const { expect } = require('chai');
const { parseManifest } = require('../../src/shared/manifest-reader');
const { computeTrackChops } = require('../../src/shared/chop-math');
const { createPresetBanks, SLOT_STATE } = require('../../src/loader/preset-banks');
const { createChopRouter } = require('../../src/loader/chop-router');
const { createModifierLayer } = require('../../src/loader/modifier-layer');
const { loadManifest } = require('../harness/fixture-loader');

describe('integration: preset-swap (hot-swap)', () => {
  let banks, router, mods;
  let trackA, trackB;

  beforeEach(() => {
    banks = createPresetBanks();
    router = createChopRouter(banks);
    mods = createModifierLayer();

    const manifest = loadManifest('hiphop_v3');
    trackA = manifest.tracks[0]; // the_next_episode (94.7 BPM)
    trackB = manifest.tracks[1]; // big_poppa (107.5 BPM)

    const chopsA = computeTrackChops(trackA);
    const chopsB = computeTrackChops(trackB);

    banks.loadSlot(0, 'the_next_episode', trackA, chopsA);
    banks.loadSlot(1, 'big_poppa', trackB, chopsB);
    banks.activate(0);
  });

  it('swaps preset while preserving held chops', () => {
    // Hold drums col 1 and bass col 3
    router.press(1, 1, mods);
    router.press(2, 3, mods);
    expect(router.getHeldChops()).to.have.lengthOf(2);

    // Swap to big_poppa
    const { previous, current } = banks.activate(1);
    expect(previous).to.equal(0);
    expect(current).to.equal(1);

    // Perform hot-swap migration
    const migrations = router.hotSwap(banks.getSlot(1).chops);

    expect(migrations).to.have.lengthOf(2);

    // Drums should migrate: same column, new chop from big_poppa
    const drumsMigration = migrations.find(m => m.stem === 'drums');
    expect(drumsMigration.column).to.equal(1);
    expect(drumsMigration.newChop).to.not.be.null;
    expect(drumsMigration.newChop.clipStart).to.equal(trackB.downbeat_sec);

    // Bass should migrate: same column 3, new chop
    const bassMigration = migrations.find(m => m.stem === 'bass');
    expect(bassMigration.column).to.equal(3);
    expect(bassMigration.newChop).to.not.be.null;
  });

  it('previous preset goes idle, new goes active', () => {
    banks.activate(1);
    expect(banks.getSlot(0).state).to.equal(SLOT_STATE.LOADED_IDLE);
    expect(banks.getSlot(1).state).to.equal(SLOT_STATE.LOADED_ACTIVE);
  });

  it('stops held chop if new preset is missing that stem', () => {
    // Load missing_stem track (no drums)
    const missingManifest = loadManifest('missing_stem');
    const missingTrack = missingManifest.tracks[0];
    const missingChops = computeTrackChops(missingTrack);
    banks.loadSlot(2, 'partial_track', missingTrack, missingChops);

    // Hold drums in current preset
    router.press(1, 1, mods);
    expect(router.getPlaying('drums')).to.equal(1);

    // Swap to partial track (no drums)
    banks.activate(2);
    const migrations = router.hotSwap(banks.getSlot(2).chops);

    const drumsMigration = migrations.find(m => m.stem === 'drums');
    expect(drumsMigration.newChop).to.be.null; // no replacement
  });

  it('stops held chop if new preset is varying', () => {
    const varyingManifest = loadManifest('varying_track');
    const varyingTrack = varyingManifest.tracks[0];
    const varyingChops = computeTrackChops(varyingTrack);
    banks.loadSlot(3, 'sicko_mode', varyingTrack, varyingChops);

    router.press(1, 1, mods);
    banks.activate(3);
    const migrations = router.hotSwap(banks.getSlot(3).chops);

    // All chops should stop (disabled)
    for (const m of migrations) {
      expect(m.newChop).to.be.null;
    }
  });
});
