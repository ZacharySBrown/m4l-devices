'use strict';

/**
 * Manifest reader — parses manifest.json and set.json contracts.
 *
 * All JSON parsing and validation happens at load time.
 * The realtime path never touches JSON.
 */

const REQUIRED_TRACK_FIELDS = ['id', 'bpm', 'stems'];
const STEM_NAMES = ['drums', 'bass', 'other', 'vox'];
const MAX_SETLIST_TRACKS = 32;
const PRESET_SLOTS_PER_BANK = 8;

/**
 * Validate a single track object from the manifest.
 *
 * @param {object} track
 * @returns {{ valid: boolean, errors: string[] }}
 */
function validateTrack(track) {
  const errors = [];

  if (!track || typeof track !== 'object') {
    return { valid: false, errors: ['Track is null or not an object'] };
  }

  for (const field of REQUIRED_TRACK_FIELDS) {
    if (track[field] === undefined || track[field] === null) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  if (track.bpm !== undefined && (typeof track.bpm !== 'number' || track.bpm <= 0)) {
    errors.push(`Invalid BPM: ${track.bpm}`);
  }

  if (track.stems && typeof track.stems === 'object') {
    for (const name of STEM_NAMES) {
      const stem = track.stems[name];
      if (stem && (!stem.path || typeof stem.path !== 'string')) {
        errors.push(`Stem '${name}' has no valid path`);
      }
    }
  }

  return { valid: errors.length === 0, errors };
}

/**
 * Parse a manifest JSON object (the upstream stemforge contract).
 *
 * @param {object|string} manifestData - parsed JSON or raw string
 * @returns {{ tracks: object[], errors: string[], globalTempoHint: number|null }}
 */
function parseManifest(manifestData) {
  let data = manifestData;
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (e) {
      return { tracks: [], errors: [`JSON parse error: ${e.message}`], globalTempoHint: null };
    }
  }

  if (!data || typeof data !== 'object') {
    return { tracks: [], errors: ['Manifest is not an object'], globalTempoHint: null };
  }

  const errors = [];
  const validTracks = [];

  if (!Array.isArray(data.tracks)) {
    errors.push('Manifest missing tracks array');
    return { tracks: [], errors, globalTempoHint: data.global_tempo_hint || null };
  }

  for (let i = 0; i < data.tracks.length; i++) {
    const track = data.tracks[i];
    const result = validateTrack(track);
    if (result.valid) {
      validTracks.push(track);
    } else {
      errors.push(`Track[${i}] (${track && track.id || '?'}): ${result.errors.join('; ')}`);
    }
  }

  return {
    tracks: validTracks,
    errors,
    globalTempoHint: data.global_tempo_hint || null,
  };
}

/**
 * Parse a set.json file (the live-set definition, authored in taste).
 *
 * @param {object|string} setData - parsed JSON or raw string
 * @returns {{ name: string, globalTempo: number, presetBankA: Array, presetBankB: Array, setlist: string[], errors: string[] }}
 */
function parseSetJson(setData) {
  let data = setData;
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (e) {
      return { name: '', globalTempo: 0, presetBankA: [], presetBankB: [], setlist: [], errors: [`JSON parse error: ${e.message}`] };
    }
  }

  const errors = [];

  if (!data || typeof data !== 'object') {
    return { name: '', globalTempo: 0, presetBankA: [], presetBankB: [], setlist: [], errors: ['Set data is not an object'] };
  }

  const name = data.name || '';
  const globalTempo = data.global_tempo || 0;

  if (!globalTempo || globalTempo <= 0) {
    errors.push('Missing or invalid global_tempo');
  }

  // Preset banks: arrays of 8, nullable entries
  const presetBankA = normalizeBank(data.preset_bank_A, 'A', errors);
  const presetBankB = normalizeBank(data.preset_bank_B, 'B', errors);

  // Setlist: flat array of track IDs
  const setlist = Array.isArray(data.setlist) ? data.setlist.slice(0, MAX_SETLIST_TRACKS) : [];

  return { name, globalTempo, presetBankA, presetBankB, setlist, errors };
}

/**
 * Normalize a preset bank array to exactly 8 slots.
 */
function normalizeBank(bank, label, errors) {
  if (!Array.isArray(bank)) {
    errors.push(`preset_bank_${label} is not an array`);
    return new Array(PRESET_SLOTS_PER_BANK).fill(null);
  }
  const result = new Array(PRESET_SLOTS_PER_BANK).fill(null);
  for (let i = 0; i < Math.min(bank.length, PRESET_SLOTS_PER_BANK); i++) {
    result[i] = bank[i] || null;
  }
  return result;
}

/**
 * Resolve a track by ID from the manifest's track list.
 *
 * @param {object[]} tracks - validated track array from parseManifest
 * @param {string} trackId
 * @returns {object|null}
 */
function resolveTrack(tracks, trackId) {
  if (!tracks || !trackId) return null;
  return tracks.find(t => t.id === trackId) || null;
}

/**
 * Filter tracks to only those that are validated.
 *
 * @param {object[]} tracks
 * @returns {object[]}
 */
function filterValidated(tracks) {
  return (tracks || []).filter(t => t.validated === true);
}

module.exports = {
  REQUIRED_TRACK_FIELDS,
  STEM_NAMES,
  MAX_SETLIST_TRACKS,
  PRESET_SLOTS_PER_BANK,
  validateTrack,
  parseManifest,
  parseSetJson,
  normalizeBank,
  resolveTrack,
  filterValidated,
};
