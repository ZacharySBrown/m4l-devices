'use strict';

/**
 * Chop router — pad → (stem, bar) → clip start.
 *
 * Maps Grid 1 pad presses (row 2-5, col 1-8) to clip launch
 * commands via the chop math and preset bank state.
 */

const { stemForRow, ROW_QUANT_DEFAULTS } = require('../shared/live-api-helpers');
const { SLOT_STATE } = require('./preset-banks');

const STEM_ROWS = { 1: 'drums', 2: 'bass', 3: 'other', 4: 'vox' };

const CHOP_STATE = {
  EMPTY: 'empty',
  LOADED: 'loaded',
  PLAYING: 'playing',
  CUED: 'cued',
  DISABLED: 'disabled',
};

function createChopRouter(presetBanks) {
  // Track which chop is playing per stem row
  const playing = { drums: null, bass: null, other: null, vox: null };

  return {
    /**
     * Get which chop is currently playing in a stem row.
     */
    getPlaying(stemName) {
      return playing[stemName] || null;
    },

    /**
     * Get all currently held chops as (row, col) tuples.
     */
    getHeldChops() {
      const held = [];
      for (const [stem, col] of Object.entries(playing)) {
        if (col !== null) {
          const row = Object.entries(STEM_ROWS).find(([, s]) => s === stem);
          if (row) held.push({ row: parseInt(row[0]), col, stem });
        }
      }
      return held;
    },

    /**
     * Handle a chop pad press.
     *
     * @param {number} row - Grid 1 row (2-5)
     * @param {number} col - Grid 1 column (1-8)
     * @param {object} [modifiers] - active modifier state
     * @returns {{ action: string, stem: string, column: number, chop: object|null, quant: number }|null}
     */
    press(row, col, modifiers) {
      const stem = STEM_ROWS[row];
      if (!stem) return null;

      const active = presetBanks.getActive();
      if (!active || active.state !== SLOT_STATE.LOADED_ACTIVE) return null;

      const chops = active.chops;
      if (!chops || !chops[stem]) return null;

      const chopList = chops[stem];
      const chop = chopList.find(c => c.column === col);
      if (!chop) return null;

      // Disabled (varying track)
      if (chop.disabled) {
        // D1 on varying track plays full mix
        if (stem === 'drums' && col === 1) {
          return { action: 'play_full', stem, column: col, chop, quant: 0 };
        }
        return null;
      }

      const currentPlaying = playing[stem];
      const quant = ROW_QUANT_DEFAULTS[stem];

      // Determine action
      let action;
      if (modifiers && modifiers.isActive && modifiers.isActive('HOLD')) {
        action = 'one_shot';
      } else if (currentPlaying === col) {
        // Toggle off
        action = 'stop';
        playing[stem] = null;
      } else {
        // Start (replaces current if any)
        action = currentPlaying !== null ? 'replace' : 'start';
        playing[stem] = col;
      }

      return { action, stem, column: col, chop, quant };
    },

    /**
     * Execute a hot-swap: migrate held chops to a new preset.
     *
     * @param {object} newChops - chop data from the new preset
     * @returns {Array<{ stem: string, column: number, oldChop: object, newChop: object|null }>}
     */
    hotSwap(newChops) {
      const migrations = [];

      for (const [stem, col] of Object.entries(playing)) {
        if (col === null) continue;

        const newStemChops = newChops && newChops[stem];
        let newChop = null;

        if (newStemChops) {
          newChop = newStemChops.find(c => c.column === col) || null;
        }

        if (newChop && !newChop.disabled) {
          // Migrate: same column in new preset
          migrations.push({
            stem,
            column: col,
            oldChop: null, // caller can look up from old preset
            newChop,
          });
        } else {
          // Stem missing in new preset — stop
          playing[stem] = null;
          migrations.push({
            stem,
            column: col,
            oldChop: null,
            newChop: null, // signals "stop, no replacement"
          });
        }
      }

      return migrations;
    },

    /**
     * Stop all chops (panic).
     */
    stopAll() {
      for (const stem of Object.keys(playing)) {
        playing[stem] = null;
      }
    },

    /**
     * Get the state of a pad (for lighting).
     */
    padState(row, col) {
      const stem = STEM_ROWS[row];
      if (!stem) return CHOP_STATE.EMPTY;

      const active = presetBanks.getActive();
      if (!active || !active.chops || !active.chops[stem]) return CHOP_STATE.EMPTY;

      const chopList = active.chops[stem];
      const chop = chopList.find(c => c.column === col);
      if (!chop) return CHOP_STATE.EMPTY;
      if (chop.disabled) return CHOP_STATE.DISABLED;

      if (playing[stem] === col) return CHOP_STATE.PLAYING;
      return CHOP_STATE.LOADED;
    },
  };
}

module.exports = {
  STEM_ROWS,
  CHOP_STATE,
  createChopRouter,
};
