'use strict';

/**
 * LiveAPI helper stubs.
 *
 * In Max for Live, these wrap the LiveAPI object. For testing,
 * they're replaced by mock-live-api.js. This module provides the
 * interface contract that both real and mock implementations satisfy.
 */

/**
 * @typedef {object} LiveApiAdapter
 * @property {function(string): object} getTrack - Get a track by name
 * @property {function(object, number, object): void} setClip - Set clip in slot
 * @property {function(object): void} launchClip - Launch a clip
 * @property {function(object): void} stopClip - Stop a clip
 * @property {function(): number} getGlobalTempo - Get current global BPM
 * @property {function(number): void} setGlobalTempo - Set global BPM
 * @property {function(): void} stopAllClips - Panic: stop everything
 * @property {function(string, number, object): void} setClipWarpMarker - Set warp marker
 * @property {function(string): object[]} getWarpMarkers - Get warp markers for clip
 */

/**
 * Launch quantization values matching Live's enum.
 */
const LAUNCH_QUANT = {
  NONE:    0,
  '1/16':  4,
  '1/8':   5,
  '1/4':   6,
  '1/2':   7,
  '1 BAR': 8,
};

/**
 * Default per-row launch quantization.
 * Spec §2.4.
 */
const ROW_QUANT_DEFAULTS = {
  drums: LAUNCH_QUANT['1/16'],
  bass:  LAUNCH_QUANT['1 BAR'],
  other: LAUNCH_QUANT['1/4'],
  vox:   LAUNCH_QUANT['1/2'],
};

/**
 * Stem row indices (1-based, matching Grid 1 layout).
 */
const STEM_ROWS = {
  drums: 2,
  bass:  3,
  other: 4,
  vox:   5,
};

/**
 * Get the stem name for a grid row.
 * @param {number} row - 1-based row index
 * @returns {string|null}
 */
function stemForRow(row) {
  for (const [name, r] of Object.entries(STEM_ROWS)) {
    if (r === row) return name;
  }
  return null;
}

module.exports = {
  LAUNCH_QUANT,
  ROW_QUANT_DEFAULTS,
  STEM_ROWS,
  stemForRow,
};
