'use strict';

/**
 * Chop math — the load-bearing one-liner.
 *
 * Derives clip start/length from (bpm, downbeat_sec, bar_index).
 * All computation happens at load time, never realtime.
 *
 * Convention: 4 bars per chop, 4 beats per bar (4/4 time).
 */

const BARS_PER_CHOP = 4;
const BEATS_PER_BAR = 4;
const NUM_CHOPS = 8;

/**
 * Seconds per bar at a given BPM.
 * @param {number} bpm
 * @returns {number}
 */
function secondsPerBar(bpm) {
  if (!bpm || bpm <= 0) throw new Error(`Invalid BPM: ${bpm}`);
  return (BEATS_PER_BAR * 60) / bpm;
}

/**
 * Compute the clip start time in seconds for a given chop column.
 *
 * @param {number} column - 1-based column index (1..8)
 * @param {number} bpm - track BPM
 * @param {number} downbeatSec - first downbeat position in seconds
 * @returns {number} clip start in seconds
 */
function clipStart(column, bpm, downbeatSec) {
  if (column < 1 || column > NUM_CHOPS) {
    throw new Error(`Column out of range: ${column} (must be 1..${NUM_CHOPS})`);
  }
  if (typeof downbeatSec !== 'number' || downbeatSec < 0) {
    throw new Error(`Invalid downbeat_sec: ${downbeatSec}`);
  }
  const barIndex = (column - 1) * BARS_PER_CHOP;
  return downbeatSec + barIndex * secondsPerBar(bpm);
}

/**
 * Compute clip length in seconds (always 4 bars).
 *
 * @param {number} bpm
 * @returns {number}
 */
function clipLength(bpm) {
  return BARS_PER_CHOP * secondsPerBar(bpm);
}

/**
 * Generate all 8 chop descriptors for a single stem.
 *
 * @param {number} bpm
 * @param {number} downbeatSec
 * @param {string} stemPath - absolute path to the stem WAV
 * @param {boolean} [varying=false] - if true, chops are disabled
 * @returns {Array<{column: number, clipStart: number, clipLength: number, stemPath: string, disabled: boolean}>}
 */
function computeChops(bpm, downbeatSec, stemPath, varying) {
  if (varying) {
    return Array.from({ length: NUM_CHOPS }, (_, i) => ({
      column: i + 1,
      clipStart: 0,
      clipLength: 0,
      stemPath,
      disabled: true,
    }));
  }

  const length = clipLength(bpm);
  return Array.from({ length: NUM_CHOPS }, (_, i) => {
    const col = i + 1;
    return {
      column: col,
      clipStart: clipStart(col, bpm, downbeatSec),
      clipLength: length,
      stemPath,
      disabled: false,
    };
  });
}

/**
 * Compute chops for all 4 stems of a track.
 *
 * @param {object} track - manifest track object
 * @returns {object} { drums: [...], bass: [...], other: [...], vox: [...] }
 */
function computeTrackChops(track) {
  if (!track || !track.bpm) {
    throw new Error('Track missing required bpm field');
  }
  const { bpm, downbeat_sec: ds, varying, stems } = track;
  const downbeatSec = ds || 0;

  const result = {};
  for (const stemName of ['drums', 'bass', 'other', 'vox']) {
    const stem = stems && stems[stemName];
    if (!stem || !stem.path) {
      result[stemName] = null; // stem missing
    } else {
      result[stemName] = computeChops(bpm, downbeatSec, stem.path, varying);
    }
  }
  return result;
}

module.exports = {
  BARS_PER_CHOP,
  BEATS_PER_BAR,
  NUM_CHOPS,
  secondsPerBar,
  clipStart,
  clipLength,
  computeChops,
  computeTrackChops,
};
