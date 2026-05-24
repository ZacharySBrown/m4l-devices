'use strict';

const { expect } = require('chai');
const {
  validateTrack, parseManifest, parseSetJson, resolveTrack, filterValidated,
  PRESET_SLOTS_PER_BANK,
} = require('../../src/shared/manifest-reader');
const { loadManifest, loadSet } = require('../harness/fixture-loader');

describe('manifest-reader', () => {
  describe('validateTrack', () => {
    it('accepts a well-formed track', () => {
      const manifest = loadManifest('hiphop_v3');
      const result = validateTrack(manifest.tracks[0]);
      expect(result.valid).to.be.true;
      expect(result.errors).to.be.empty;
    });

    it('rejects null track', () => {
      const result = validateTrack(null);
      expect(result.valid).to.be.false;
    });

    it('rejects track missing id', () => {
      const result = validateTrack({ bpm: 120, stems: {} });
      expect(result.valid).to.be.false;
      expect(result.errors.some(e => e.includes('id'))).to.be.true;
    });

    it('rejects track with bpm=0', () => {
      const result = validateTrack({ id: 'x', bpm: 0, stems: {} });
      expect(result.valid).to.be.false;
      expect(result.errors.some(e => e.includes('BPM'))).to.be.true;
    });

    it('tolerates extra fields', () => {
      const track = { id: 'x', bpm: 120, stems: {}, extra_field: 'ok' };
      const result = validateTrack(track);
      expect(result.valid).to.be.true;
    });

    it('flags stem with no path', () => {
      const track = { id: 'x', bpm: 120, stems: { drums: { sha: 'abc' } } };
      const result = validateTrack(track);
      expect(result.errors.some(e => e.includes('drums'))).to.be.true;
    });
  });

  describe('parseManifest', () => {
    it('parses well-formed manifest', () => {
      const manifest = loadManifest('hiphop_v3');
      const result = parseManifest(manifest);
      expect(result.tracks).to.have.lengthOf(2);
      expect(result.errors).to.be.empty;
      expect(result.globalTempoHint).to.equal(94.0);
    });

    it('parses from JSON string', () => {
      const manifest = loadManifest('hiphop_v3');
      const result = parseManifest(JSON.stringify(manifest));
      expect(result.tracks).to.have.lengthOf(2);
    });

    it('reports errors for invalid tracks but still returns valid ones', () => {
      const manifest = loadManifest('invalid_bpm');
      const result = parseManifest(manifest);
      expect(result.errors).to.not.be.empty;
    });

    it('returns error on invalid JSON string', () => {
      const result = parseManifest('not json');
      expect(result.tracks).to.be.empty;
      expect(result.errors).to.not.be.empty;
    });

    it('handles missing tracks array', () => {
      const result = parseManifest({ schema_version: '2.0' });
      expect(result.tracks).to.be.empty;
      expect(result.errors.some(e => e.includes('tracks'))).to.be.true;
    });
  });

  describe('parseSetJson', () => {
    it('parses well-formed set', () => {
      const set = loadSet('hiphop_v3');
      const result = parseSetJson(set);
      expect(result.name).to.equal('hiphop_v3');
      expect(result.globalTempo).to.equal(94.0);
      expect(result.presetBankA).to.have.lengthOf(PRESET_SLOTS_PER_BANK);
      expect(result.presetBankB).to.have.lengthOf(PRESET_SLOTS_PER_BANK);
      expect(result.setlist).to.include('the_next_episode');
    });

    it('normalizes banks to exactly 8 slots', () => {
      const result = parseSetJson({ name: 'test', global_tempo: 120, preset_bank_A: [{ track_id: 'a' }], preset_bank_B: [], setlist: [] });
      expect(result.presetBankA).to.have.lengthOf(8);
      expect(result.presetBankA[0]).to.deep.equal({ track_id: 'a' });
      expect(result.presetBankA[1]).to.be.null;
    });

    it('reports error on missing global_tempo', () => {
      const result = parseSetJson({ name: 'test', preset_bank_A: [], preset_bank_B: [] });
      expect(result.errors.some(e => e.includes('global_tempo'))).to.be.true;
    });
  });

  describe('resolveTrack', () => {
    it('finds track by id', () => {
      const manifest = loadManifest('hiphop_v3');
      const { tracks } = parseManifest(manifest);
      const track = resolveTrack(tracks, 'big_poppa');
      expect(track).to.not.be.null;
      expect(track.bpm).to.equal(107.5);
    });

    it('returns null for unknown id', () => {
      const manifest = loadManifest('hiphop_v3');
      const { tracks } = parseManifest(manifest);
      expect(resolveTrack(tracks, 'nonexistent')).to.be.null;
    });
  });

  describe('filterValidated', () => {
    it('filters to validated-only tracks', () => {
      const tracks = [
        { id: 'a', validated: true },
        { id: 'b', validated: false },
        { id: 'c', validated: true },
      ];
      const result = filterValidated(tracks);
      expect(result).to.have.lengthOf(2);
    });
  });
});
