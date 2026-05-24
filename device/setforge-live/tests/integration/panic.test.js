'use strict';

const { expect } = require('chai');
const { parseManifest } = require('../../src/shared/manifest-reader');
const { computeTrackChops } = require('../../src/shared/chop-math');
const { createPresetBanks, SLOT_STATE } = require('../../src/loader/preset-banks');
const { createChopRouter, CHOP_STATE } = require('../../src/loader/chop-router');
const { createModifierLayer, MOD_STATE } = require('../../src/loader/modifier-layer');
const { createSceneMemory, SCENE_STATE } = require('../../src/loader/scene-memory');
const { createFxBus } = require('../../src/loader/fx-bus');
const { createMockLiveApi } = require('../harness/mock-live-api');
const { loadManifest } = require('../harness/fixture-loader');

describe('integration: panic', () => {
  let banks, router, mods, scenes, fx, liveApi;

  beforeEach(() => {
    banks = createPresetBanks();
    router = createChopRouter(banks);
    mods = createModifierLayer();
    scenes = createSceneMemory();
    fx = createFxBus();
    liveApi = createMockLiveApi();

    // Set up a full playing state
    const manifest = loadManifest('hiphop_v3');
    const track = manifest.tracks[0];
    const chops = computeTrackChops(track);
    banks.loadSlot(0, 'the_next_episode', track, chops);
    banks.activate(0);

    // Play some chops
    router.press(2, 1, mods); // drums
    router.press(3, 3, mods); // bass

    // Latch a modifier
    mods.press('SOLO', 1000);
    mods.release('SOLO');
    mods.press('SOLO', 1200); // latch

    // Save a scene
    scenes.save(0, { preset: 0, heldChops: router.getHeldChops() });

    // Activate FX
    fx.setTarget('drums');
    fx.pressFilter(2, true); // latch LP 100Hz
    fx.pressThrow(5);         // short verb
  });

  /**
   * Panic procedure: stop all chops, clear modifiers, bypass FX.
   * In real device, this also calls liveApi.stopAllClips().
   */
  function executePanic() {
    router.stopAll();
    mods.clearAll();
    fx.bypass();
    liveApi.stopAllClips();
  }

  it('stops all playing chops', () => {
    expect(router.getHeldChops()).to.have.lengthOf(2);
    executePanic();
    expect(router.getHeldChops()).to.have.lengthOf(0);
    expect(router.getPlaying('drums')).to.be.null;
    expect(router.getPlaying('bass')).to.be.null;
  });

  it('clears all modifier state', () => {
    expect(mods.isActive('SOLO')).to.be.true;
    executePanic();
    expect(mods.getActive()).to.be.empty;
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.IDLE);
  });

  it('bypasses FX (filter + throws)', () => {
    expect(fx.getFilter().type).to.equal('lp');
    expect(fx.getThrow()).to.not.be.null;
    executePanic();
    expect(fx.getFilter().type).to.equal('bypass');
    expect(fx.isFilterLatched()).to.be.false;
    expect(fx.getThrow()).to.be.null;
  });

  it('calls stopAllClips on mock LiveAPI', () => {
    executePanic();
    const stopCalls = liveApi.getCallsFor('stopAllClips');
    expect(stopCalls).to.have.lengthOf(1);
  });

  it('preserves loaded preset state (does not eject)', () => {
    executePanic();
    // Preset is still loaded, just not active-playing
    expect(banks.getSlot(0).state).to.equal(SLOT_STATE.LOADED_ACTIVE);
    expect(banks.getSlot(0).trackId).to.equal('the_next_episode');
  });

  it('preserves scene memory (scenes are not cleared by panic)', () => {
    executePanic();
    expect(scenes.getScene(0).state).to.equal(SCENE_STATE.BUILT);
  });

  it('pads return to idle colors after panic', () => {
    executePanic();
    // Chop pads should be loaded (not playing)
    expect(router.padState(2, 1)).to.equal(CHOP_STATE.LOADED);
    expect(router.padState(3, 3)).to.equal(CHOP_STATE.LOADED);
  });
});
