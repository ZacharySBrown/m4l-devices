'use strict';

const { expect } = require('chai');
const { createSceneMemory, SCENE_STATE, NUM_SCENES } = require('../../src/loader/scene-memory');

describe('scene-memory', () => {
  let scenes;

  beforeEach(() => {
    scenes = createSceneMemory();
  });

  it('initializes 8 empty scenes', () => {
    expect(scenes.getScenes()).to.have.lengthOf(NUM_SCENES);
    for (const scene of scenes.getScenes()) {
      expect(scene.state).to.equal(SCENE_STATE.EMPTY);
    }
  });

  describe('save + recall round-trip', () => {
    const snapshot = {
      activePresetIndex: 2,
      heldChops: [{ row: 2, col: 1 }, { row: 3, col: 3 }],
      modifiers: { HOLD: 'idle', MUTE: 'latched' },
    };

    it('saves and recalls a scene', () => {
      scenes.save(0, snapshot);
      expect(scenes.getScene(0).state).to.equal(SCENE_STATE.BUILT);

      const recalled = scenes.recall(0);
      expect(recalled).to.deep.equal(snapshot);
      expect(scenes.getScene(0).state).to.equal(SCENE_STATE.PLAYING);
    });

    it('returns null for empty scene recall', () => {
      expect(scenes.recall(3)).to.be.null;
    });
  });

  describe('last-triggered tracking', () => {
    it('tracks last triggered scene', () => {
      scenes.save(0, { preset: 0 });
      scenes.save(1, { preset: 1 });
      scenes.recall(0);
      expect(scenes.getLastTriggered()).to.equal(0);
      scenes.recall(1);
      expect(scenes.getLastTriggered()).to.equal(1);
      // Previous goes back to built
      expect(scenes.getScene(0).state).to.equal(SCENE_STATE.BUILT);
    });
  });

  describe('loadFromPreset', () => {
    it('loads scenes from preset data', () => {
      const presetScenes = [
        { activePresetIndex: 0, heldChops: [] },
        null,
        { activePresetIndex: 0, heldChops: [{ row: 2, col: 5 }] },
      ];
      scenes.loadFromPreset(presetScenes);
      expect(scenes.getScene(0).state).to.equal(SCENE_STATE.BUILT);
      expect(scenes.getScene(1).state).to.equal(SCENE_STATE.EMPTY);
      expect(scenes.getScene(2).state).to.equal(SCENE_STATE.BUILT);
    });
  });

  describe('clearAll', () => {
    it('clears all scenes', () => {
      scenes.save(0, { x: 1 });
      scenes.save(5, { x: 2 });
      scenes.clearAll();
      for (const scene of scenes.getScenes()) {
        expect(scene.state).to.equal(SCENE_STATE.EMPTY);
      }
      expect(scenes.getLastTriggered()).to.be.null;
    });
  });

  it('throws on out-of-range save', () => {
    expect(() => scenes.save(8, {})).to.throw();
    expect(() => scenes.save(-1, {})).to.throw();
  });
});
