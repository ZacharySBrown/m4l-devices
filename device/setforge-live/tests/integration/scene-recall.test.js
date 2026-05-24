'use strict';

const { expect } = require('chai');
const { parseManifest } = require('../../src/shared/manifest-reader');
const { computeTrackChops } = require('../../src/shared/chop-math');
const { createPresetBanks } = require('../../src/loader/preset-banks');
const { createChopRouter } = require('../../src/loader/chop-router');
const { createSceneMemory, SCENE_STATE } = require('../../src/loader/scene-memory');
const { createModifierLayer } = require('../../src/loader/modifier-layer');
const { loadManifest } = require('../harness/fixture-loader');

describe('integration: scene-recall', () => {
  let banks, router, scenes, mods;

  beforeEach(() => {
    banks = createPresetBanks();
    router = createChopRouter(banks);
    scenes = createSceneMemory();
    mods = createModifierLayer();

    const manifest = loadManifest('hiphop_v3');
    const trackA = manifest.tracks[0];
    const trackB = manifest.tracks[1];
    banks.loadSlot(0, 'the_next_episode', trackA, computeTrackChops(trackA));
    banks.loadSlot(1, 'big_poppa', trackB, computeTrackChops(trackB));
    banks.activate(0);
  });

  it('saves current state as a scene and recalls it', () => {
    // Play some chops
    router.press(2, 1, mods);
    router.press(3, 3, mods);

    // Save scene
    const snapshot = {
      activePresetIndex: banks.getActiveIndex(),
      heldChops: router.getHeldChops(),
      modifiers: mods.snapshot(),
    };
    scenes.save(0, snapshot);
    expect(scenes.getScene(0).state).to.equal(SCENE_STATE.BUILT);

    // Stop everything
    router.stopAll();
    banks.activate(1);

    // Recall scene
    const recalled = scenes.recall(0);
    expect(recalled).to.not.be.null;
    expect(recalled.activePresetIndex).to.equal(0);
    expect(recalled.heldChops).to.have.lengthOf(2);
    expect(recalled.heldChops[0]).to.deep.include({ row: 2, col: 1, stem: 'drums' });
  });

  it('scene recall with cross-preset state', () => {
    // Save a scene pointing to preset 1
    router.press(2, 5, mods);
    const snapshot = {
      activePresetIndex: 0,
      heldChops: router.getHeldChops(),
      modifiers: mods.snapshot(),
    };
    scenes.save(2, snapshot);

    // Switch to preset 1, recall scene 2 (which wants preset 0)
    banks.activate(1);
    router.stopAll();

    const recalled = scenes.recall(2);
    expect(recalled.activePresetIndex).to.equal(0);
    // Caller is responsible for re-activating the preset and re-triggering chops
  });

  it('scene G (index 6) can be used as outro convention', () => {
    // Per spec: scene G = "outro to one stem"
    const outroSnapshot = {
      activePresetIndex: 0,
      heldChops: [{ row: 5, col: 3, stem: 'vox' }], // just vox
      modifiers: mods.snapshot(),
    };
    scenes.save(6, outroSnapshot);

    const recalled = scenes.recall(6);
    expect(recalled.heldChops).to.have.lengthOf(1);
    expect(recalled.heldChops[0].stem).to.equal('vox');
  });

  it('last-triggered transitions correctly', () => {
    scenes.save(0, { preset: 0 });
    scenes.save(1, { preset: 1 });

    scenes.recall(0);
    expect(scenes.getScene(0).state).to.equal(SCENE_STATE.PLAYING);

    scenes.recall(1);
    expect(scenes.getScene(0).state).to.equal(SCENE_STATE.BUILT);
    expect(scenes.getScene(1).state).to.equal(SCENE_STATE.PLAYING);
  });
});
