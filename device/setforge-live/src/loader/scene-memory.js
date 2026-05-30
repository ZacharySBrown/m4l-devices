'use strict';

/**
 * Scene memory — snapshot save/recall for Grid 1 state.
 *
 * A scene captures: active preset, held chops (row,col pairs),
 * modifier latch state, and per-row mute/solo state.
 * 8 scene slots (row 8, cols 1-8).
 */

const NUM_SCENES = 8;

const SCENE_STATE = {
  EMPTY: 'empty',
  BUILT: 'built',
  PLAYING: 'playing',
};

function createSceneMemory() {
  const scenes = Array.from({ length: NUM_SCENES }, () => ({
    state: SCENE_STATE.EMPTY,
    snapshot: null,
  }));
  let lastTriggered = null;

  return {
    /**
     * Get scene at index.
     */
    getScene(index) {
      if (index < 0 || index >= NUM_SCENES) return null;
      return scenes[index];
    },

    /**
     * Get all scenes.
     */
    getScenes() {
      return scenes;
    },

    /**
     * Get the index of the last-triggered scene.
     */
    getLastTriggered() {
      return lastTriggered;
    },

    /**
     * Save current state as a scene.
     *
     * @param {number} index - scene slot (0-7)
     * @param {object} snapshot - { activePresetIndex, heldChops, modifiers, muteState }
     */
    save(index, snapshot) {
      if (index < 0 || index >= NUM_SCENES) {
        throw new Error(`Scene index out of range: ${index}`);
      }
      scenes[index] = {
        state: SCENE_STATE.BUILT,
        snapshot: { ...snapshot },
      };
    },

    /**
     * Recall a scene.
     *
     * @param {number} index
     * @returns {object|null} the snapshot, or null if empty
     */
    recall(index) {
      if (index < 0 || index >= NUM_SCENES) return null;
      const scene = scenes[index];
      if (scene.state === SCENE_STATE.EMPTY || !scene.snapshot) return null;

      // Mark as playing, clear previous
      if (lastTriggered !== null && lastTriggered !== index) {
        if (scenes[lastTriggered].state === SCENE_STATE.PLAYING) {
          scenes[lastTriggered].state = SCENE_STATE.BUILT;
        }
      }
      scene.state = SCENE_STATE.PLAYING;
      lastTriggered = index;

      return { ...scene.snapshot };
    },

    /**
     * Load scenes from a set.json preset entry.
     *
     * @param {Array} sceneData - array of scene snapshot objects from set.json
     */
    loadFromPreset(sceneData) {
      if (!Array.isArray(sceneData)) return;
      for (let i = 0; i < Math.min(sceneData.length, NUM_SCENES); i++) {
        if (sceneData[i]) {
          scenes[i] = {
            state: SCENE_STATE.BUILT,
            snapshot: { ...sceneData[i] },
          };
        }
      }
    },

    /**
     * Clear a single scene slot.
     */
    clear(index) {
      if (index < 0 || index >= NUM_SCENES) return;
      scenes[index] = { state: SCENE_STATE.EMPTY, snapshot: null };
      if (lastTriggered === index) lastTriggered = null;
    },

    /**
     * Clear all scenes (panic).
     */
    clearAll() {
      for (let i = 0; i < NUM_SCENES; i++) {
        scenes[i] = { state: SCENE_STATE.EMPTY, snapshot: null };
      }
      lastTriggered = null;
    },
  };
}

module.exports = {
  NUM_SCENES,
  SCENE_STATE,
  createSceneMemory,
};
