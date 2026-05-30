'use strict';

/**
 * FX bus — filter + throws routing.
 *
 * Grid 2 rows 5-7: target select, filter sweep (FX-A), throws (FX-B).
 */

const FX_TARGETS = ['drums', 'bass', 'other', 'vox', 'all', 'deckA', 'deckB', 'master'];

const FILTER_POSITIONS = [
  { col: 1, type: 'lp', freq: 0,     label: 'LP closed' },
  { col: 2, type: 'lp', freq: 100,   label: 'LP 100Hz' },
  { col: 3, type: 'lp', freq: 300,   label: 'LP 300Hz' },
  { col: 4, type: 'bypass', freq: 0, label: 'Bypass' },
  { col: 5, type: 'hp', freq: 300,   label: 'HP 300Hz' },
  { col: 6, type: 'hp', freq: 1000,  label: 'HP 1kHz' },
  { col: 7, type: 'hp', freq: 3000,  label: 'HP 3kHz' },
  { col: 8, type: 'hp', freq: 20000, label: 'HP open' },
];

const THROW_EFFECTS = [
  { col: 1, type: 'delay', subdivision: '1/4', taps: 3 },
  { col: 2, type: 'delay', subdivision: '1/8', taps: 5 },
  { col: 3, type: 'delay', subdivision: 'dotted-1/8', taps: 4 },
  { col: 4, type: 'delay', subdivision: 'triplet-1/8', taps: 5 },
  { col: 5, type: 'reverb', time: 1.2, label: 'Short plate' },
  { col: 6, type: 'reverb', time: 4.5, label: 'Long hall' },
  { col: 7, type: 'freeze', label: 'Freeze' },
  { col: 8, type: 'bitcrush', bits: 8, sampleRate: 12000, label: 'Bitcrush' },
];

function createFxBus() {
  let target = 'all'; // default target
  let filterCol = 4;  // bypass
  let filterLatched = false;
  let throwCol = null;

  return {
    /**
     * Get current FX target.
     */
    getTarget() {
      return target;
    },

    /**
     * Set FX target (exclusive selection).
     */
    setTarget(newTarget) {
      if (!FX_TARGETS.includes(newTarget)) return false;
      target = newTarget;
      return true;
    },

    /**
     * Set FX target by column index (1-8).
     */
    setTargetByCol(col) {
      if (col < 1 || col > FX_TARGETS.length) return false;
      target = FX_TARGETS[col - 1];
      return true;
    },

    /**
     * Get current filter state.
     */
    getFilter() {
      return FILTER_POSITIONS[filterCol - 1];
    },

    /**
     * Is the filter latched?
     */
    isFilterLatched() {
      return filterLatched;
    },

    /**
     * Press a filter pad (momentary or latch via double-tap).
     * @param {number} col
     * @param {boolean} isDoubleTap
     */
    pressFilter(col, isDoubleTap) {
      if (col < 1 || col > 8) return;
      filterCol = col;
      filterLatched = isDoubleTap || false;
    },

    /**
     * Release filter pad (returns to bypass unless latched).
     */
    releaseFilter() {
      if (!filterLatched) {
        filterCol = 4; // bypass
      }
    },

    /**
     * Get currently active throw effect.
     */
    getThrow() {
      return throwCol ? THROW_EFFECTS[throwCol - 1] : null;
    },

    /**
     * Press a throw pad (momentary, last-pressed wins).
     */
    pressThrow(col) {
      if (col < 1 || col > 8) return;
      throwCol = col;
    },

    /**
     * Release throw pad.
     */
    releaseThrow() {
      throwCol = null;
    },

    /**
     * Full bypass (panic).
     */
    bypass() {
      filterCol = 4;
      filterLatched = false;
      throwCol = null;
    },
  };
}

module.exports = {
  FX_TARGETS,
  FILTER_POSITIONS,
  THROW_EFFECTS,
  createFxBus,
};
