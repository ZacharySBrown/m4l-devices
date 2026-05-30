'use strict';

const { expect } = require('chai');
const { parseManifest, parseSetJson, resolveTrack } = require('../../src/shared/manifest-reader');
const { computeTrackChops } = require('../../src/shared/chop-math');
const { createPresetBanks, SLOT_STATE } = require('../../src/loader/preset-banks');
const { createMockLiveApi } = require('../harness/mock-live-api');
const { loadManifest, loadSet } = require('../harness/fixture-loader');

describe('integration: load-set', () => {
  let banks, liveApi;

  beforeEach(() => {
    banks = createPresetBanks();
    liveApi = createMockLiveApi();
  });

  /**
   * Simulate the full set-load pipeline:
   * 1. Parse manifest + set JSON
   * 2. For each preset slot with a track_id, resolve the track, compute chops, load into bank
   */
  function loadFullSet(manifestName) {
    const manifestData = loadManifest(manifestName);
    const setData = loadSet(manifestName);
    const { tracks, errors: manifestErrors } = parseManifest(manifestData);
    const { presetBankA, presetBankB, errors: setErrors } = parseSetJson(setData);

    const loadErrors = [];

    // Load bank A
    for (let i = 0; i < presetBankA.length; i++) {
      const entry = presetBankA[i];
      if (!entry) continue;
      const track = resolveTrack(tracks, entry.track_id);
      if (!track) {
        banks.setError(i);
        loadErrors.push(`Bank A slot ${i}: track ${entry.track_id} not found`);
        continue;
      }
      try {
        const chops = computeTrackChops(track);
        banks.loadSlot(i, entry.track_id, track, chops);
      } catch (e) {
        banks.setError(i);
        loadErrors.push(`Bank A slot ${i}: ${e.message}`);
      }
    }

    // Load bank B
    for (let i = 0; i < presetBankB.length; i++) {
      const entry = presetBankB[i];
      if (!entry) continue;
      const slotIndex = i + 8;
      const track = resolveTrack(tracks, entry.track_id);
      if (!track) {
        banks.setError(slotIndex);
        loadErrors.push(`Bank B slot ${i}: track ${entry.track_id} not found`);
        continue;
      }
      try {
        const chops = computeTrackChops(track);
        banks.loadSlot(slotIndex, entry.track_id, track, chops);
      } catch (e) {
        banks.setError(slotIndex);
        loadErrors.push(`Bank B slot ${i}: ${e.message}`);
      }
    }

    return { manifestErrors, setErrors, loadErrors };
  }

  it('loads hiphop_v3 set into correct slots', () => {
    const { manifestErrors, setErrors, loadErrors } = loadFullSet('hiphop_v3');

    expect(manifestErrors).to.be.empty;
    expect(loadErrors).to.be.empty;

    // Bank A: the_next_episode at slot 0, big_poppa at slot 1, rest empty
    expect(banks.getSlot(0).trackId).to.equal('the_next_episode');
    expect(banks.getSlot(0).state).to.equal(SLOT_STATE.LOADED_IDLE);
    expect(banks.getSlot(1).trackId).to.equal('big_poppa');
    expect(banks.getSlot(2).state).to.equal(SLOT_STATE.EMPTY);

    // Bank B: all empty
    for (let i = 8; i < 16; i++) {
      expect(banks.getSlot(i).state).to.equal(SLOT_STATE.EMPTY);
    }
  });

  it('computes correct chop offsets for loaded tracks', () => {
    loadFullSet('hiphop_v3');

    const slot = banks.getSlot(0);
    expect(slot.chops.drums).to.have.lengthOf(8);
    expect(slot.chops.drums[0].clipStart).to.equal(2.31); // downbeat_sec
    expect(slot.chops.drums[0].disabled).to.be.false;

    // Verify all 4 stems present
    expect(slot.chops.drums).to.not.be.null;
    expect(slot.chops.bass).to.not.be.null;
    expect(slot.chops.other).to.not.be.null;
    expect(slot.chops.vox).to.not.be.null;
  });

  it('activates first preset and sources chops', () => {
    loadFullSet('hiphop_v3');
    banks.activate(0);

    const active = banks.getActive();
    expect(active.trackId).to.equal('the_next_episode');
    expect(active.state).to.equal(SLOT_STATE.LOADED_ACTIVE);
    expect(active.chops.drums).to.have.lengthOf(8);
  });

  describe('edge cases', () => {
    it('missing stem: loads without crash, stem chops are null', () => {
      // Create a set that references the missing_stem track
      const manifestData = loadManifest('missing_stem');
      const { tracks } = parseManifest(manifestData);
      const track = tracks[0];
      const chops = computeTrackChops(track);
      banks.loadSlot(0, 'partial_track', track, chops);

      expect(banks.getSlot(0).state).to.equal(SLOT_STATE.LOADED_IDLE);
      expect(banks.getSlot(0).chops.drums).to.be.null; // missing
      expect(banks.getSlot(0).chops.bass).to.not.be.null;
    });

    it('varying track: loads with disabled chops', () => {
      const manifestData = loadManifest('varying_track');
      const { tracks } = parseManifest(manifestData);
      const track = tracks[0];
      const chops = computeTrackChops(track);
      banks.loadSlot(0, 'sicko_mode', track, chops);

      expect(banks.getSlot(0).state).to.equal(SLOT_STATE.LOADED_IDLE);
      expect(banks.getSlot(0).chops.drums[0].disabled).to.be.true;
      expect(banks.getSlot(0).chops.drums[0].clipStart).to.equal(0);
    });
  });
});
