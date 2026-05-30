'use strict';

/**
 * Color palette — stem, genre, and state color constants.
 *
 * All colors are [R, G, B] triples in 0-127 range (Launchpad Pro RGB).
 * Launchpad Pro mk3 uses 7-bit color per channel via SysEx.
 */

// Stem colors (soft/loaded state)
const STEM_COLORS = {
  drums: { soft: [64, 45, 35], bright: [127, 90, 70] },
  bass:  { soft: [35, 47, 64], bright: [70, 94, 127] },
  other: { soft: [48, 48, 37], bright: [96, 96, 74] },
  vox:   { soft: [35, 60, 44], bright: [70, 120, 88] },
};

// Genre colors for Grid 2 setlist map
const GENRE_COLORS = {
  hiphop:  [127, 56, 36],
  idm:     [36, 64, 127],
  ambient: [36, 82, 56],
  rock:    [64, 64, 64],
  funk:    [127, 102, 31],
};

// State colors (universal)
const STATE_COLORS = {
  empty:       [8, 8, 8],       // dim white
  error:       [127, 0, 0],     // bright red
  loading:     [64, 64, 64],    // mid white (blinks)
  disabled:    [40, 0, 0],      // dim red
  off:         [0, 0, 0],
};

// Modifier colors
const MODIFIER_COLORS = {
  idle:    [16, 16, 16],   // dim white
  held:    [127, 127, 127], // bright white
  latched: [127, 127, 0],   // bright yellow
};

// Scene colors
const SCENE_COLORS = {
  empty:   [0, 0, 0],
  built:   [32, 0, 48],     // dim purple
  playing: [96, 0, 127],    // bright purple
};

// FX target colors
const FX_TARGET_COLORS = {
  drums:  STEM_COLORS.drums.bright,
  bass:   STEM_COLORS.bass.bright,
  other:  STEM_COLORS.other.bright,
  vox:    STEM_COLORS.vox.bright,
  all:    [127, 127, 127],  // white
  deckA:  [127, 127, 0],    // yellow
  deckB:  [127, 127, 0],    // yellow
  master: [127, 0, 0],      // red
};

/**
 * Parse a hex color string to [R, G, B] in 0-127 range.
 * @param {string} hex - e.g. "#ff8c5a"
 * @returns {number[]}
 */
function hexToLaunchpadRgb(hex) {
  if (!hex || typeof hex !== 'string') return STATE_COLORS.empty;
  const clean = hex.replace('#', '');
  if (clean.length !== 6) return STATE_COLORS.empty;
  const r = parseInt(clean.slice(0, 2), 16);
  const g = parseInt(clean.slice(2, 4), 16);
  const b = parseInt(clean.slice(4, 6), 16);
  // Scale from 0-255 to 0-127
  return [Math.round(r / 2), Math.round(g / 2), Math.round(b / 2)];
}

/**
 * Get genre color, falling back to custom color_hue or default.
 * @param {string} genre
 * @param {string} [colorHue] - hex color override from manifest
 * @returns {number[]}
 */
function genreColor(genre, colorHue) {
  if (GENRE_COLORS[genre]) return GENRE_COLORS[genre];
  if (colorHue) return hexToLaunchpadRgb(colorHue);
  return STATE_COLORS.empty;
}

/**
 * Scale brightness of a color by energy level.
 * @param {number[]} rgb
 * @param {number} energy - 0.0 to 1.0
 * @returns {number[]}
 */
function scaleBrightness(rgb, energy) {
  const e = Math.max(0, Math.min(1, energy || 0));
  const minScale = 0.3; // dim but visible
  const scale = minScale + (1 - minScale) * e;
  return rgb.map(c => Math.round(c * scale));
}

module.exports = {
  STEM_COLORS,
  GENRE_COLORS,
  STATE_COLORS,
  MODIFIER_COLORS,
  SCENE_COLORS,
  FX_TARGET_COLORS,
  hexToLaunchpadRgb,
  genreColor,
  scaleBrightness,
};
