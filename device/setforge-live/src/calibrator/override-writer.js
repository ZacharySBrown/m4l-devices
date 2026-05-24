'use strict';

/**
 * Override writer — writes .calib_override.json sidecars.
 *
 * Atomic write: tmp file + rename to prevent partial writes.
 */

const path = require('path');
const fs = require('fs');

/**
 * Build the override file path for a track's stem directory.
 *
 * @param {string} stemPath - absolute path to any stem WAV
 * @returns {string} path to .calib_override.json
 */
function overridePath(stemPath) {
  const dir = path.dirname(stemPath);
  return path.join(dir, '.calib_override.json');
}

/**
 * Build the override JSON object.
 *
 * @param {string} trackId
 * @param {number} downbeatSec - calibrated downbeat
 * @param {string} method - 'warp_marker_drag' or 'auto'
 * @param {number} autoDownbeatSec - original auto-calibrated value
 * @returns {object}
 */
function buildOverride(trackId, downbeatSec, method, autoDownbeatSec) {
  return {
    track_id: trackId,
    downbeat_sec: downbeatSec,
    validated_at: new Date().toISOString(),
    method: method || 'warp_marker_drag',
    delta_from_auto_sec: Math.round((downbeatSec - (autoDownbeatSec || 0)) * 1000) / 1000,
  };
}

/**
 * Write override to disk (atomic: write tmp, then rename).
 *
 * @param {string} filePath
 * @param {object} override
 * @param {object} [fsImpl] - filesystem implementation (for testing)
 */
function writeOverride(filePath, override, fsImpl) {
  const _fs = fsImpl || fs;
  const tmpPath = filePath + '.tmp';
  const content = JSON.stringify(override, null, 2) + '\n';
  _fs.writeFileSync(tmpPath, content, 'utf8');
  _fs.renameSync(tmpPath, filePath);
}

/**
 * Read existing override if present.
 *
 * @param {string} filePath
 * @param {object} [fsImpl]
 * @returns {object|null}
 */
function readOverride(filePath, fsImpl) {
  const _fs = fsImpl || fs;
  try {
    const content = _fs.readFileSync(filePath, 'utf8');
    return JSON.parse(content);
  } catch {
    return null;
  }
}

module.exports = {
  overridePath,
  buildOverride,
  writeOverride,
  readOverride,
};
