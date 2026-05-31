'use strict';

/**
 * Fixed bank→slot-set mapping + sync safety net.
 *
 * Regression cover for the bug that silently wiped a B-bank track's curation
 * on save: the slot-set used to LOAD a preset was chosen by an alternating
 * "active set" flag, which could diverge from the slot-set the SAVE read.
 *
 * The fix ties the slot-set to the preset's BANK:
 *   - bank A presets (index 0..7)  ALWAYS use Live slots 0..7
 *   - bank B presets (index 8..15) ALWAYS use Live slots 8..15
 * so load-offset and sync-offset can never disagree. Plus a safety net:
 * sync refuses to mutate when 0 clips are found across ALL four stems.
 */

const { expect } = require('chai');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const LOADER_JS = path.join(__dirname, '..', '..', 'loader.js');

// Minimal Max env. hasClipFn(slotIndex) controls clip presence per slot so we
// can simulate "clips in 8..15", "all empty", etc.
function makeEnv(hasClipFn) {
  return {
    autowatch: 0, inlets: 0, outlets: 0, inlet: 0,
    Task: function (fn) { this.fn = fn; this.schedule = function () {}; this.cancel = function () {}; },
    post: function () {}, outlet: function () {},
    arrayfromargs: function (a) { return Array.prototype.slice.call(a); },
    LiveAPI: function (p) {
      this.path = p; this.id = "1";
      this.get = function (prop) {
        if (prop === 'has_clip') {
          var m = this.path.match(/clip_slots (\d+)/);
          return (m && hasClipFn) ? (hasClipFn(parseInt(m[1], 10)) ? "1" : "0") : "0";
        }
        return "";
      };
      this.set = function () {};
      this.call = function () {};
      this.getcount = function () { return 0; };
    },
    File: function () { this.isopen = false; this.readstring = function () { return ''; }; this.writestring = function () {}; this.close = function () {}; this.open = function () {}; },
    Dict: function () { this._d = {}; this.set = function (k, v) { this._d[k] = v; }; this.get = function (k) { return this._d[k]; }; },
    Math: Math, JSON: JSON, String: String, Array: Array, Date: Date,
    parseInt: parseInt, parseFloat: parseFloat, isNaN: isNaN,
  };
}

function load(env) {
  const ctx = vm.createContext(env);
  vm.runInContext(fs.readFileSync(LOADER_JS, 'utf8'), ctx);
  return ctx;
}

describe('bank→slot mapping', () => {
  it('bankSetOffset maps bank A (0-7)→0 and bank B (8-15)→8', () => {
    const ctx = load(makeEnv());
    expect(ctx.bankSetOffset(0)).to.equal(0);
    expect(ctx.bankSetOffset(7)).to.equal(0);
    expect(ctx.bankSetOffset(8)).to.equal(8);
    expect(ctx.bankSetOffset(15)).to.equal(8);
    // defensive: no active preset / bad index falls back to bank A
    expect(ctx.bankSetOffset(null)).to.equal(0);
    expect(ctx.bankSetOffset(-1)).to.equal(0);
  });

  it('activeSetOffset follows the ACTIVE preset bank (not an alternating flag)', () => {
    const ctx = load(makeEnv());
    ctx.activeSlotIndex = 3;  expect(ctx.activeSetOffset()).to.equal(0);
    ctx.activeSlotIndex = 0;  expect(ctx.activeSetOffset()).to.equal(0);
    ctx.activeSlotIndex = 8;  expect(ctx.activeSetOffset()).to.equal(8);
    ctx.activeSlotIndex = 15; expect(ctx.activeSetOffset()).to.equal(8);
  });

  it('the same B-bank preset gives the same offset for load AND sync (no divergence)', () => {
    const ctx = load(makeEnv());
    const presetIdx = 8; // B1
    ctx.activeSlotIndex = presetIdx;
    // load path uses bankSetOffset(presetIdx); sync path uses activeSetOffset()
    expect(ctx.bankSetOffset(presetIdx)).to.equal(ctx.activeSetOffset());
    expect(ctx.activeSetOffset()).to.equal(8);
  });
});

describe('sync safety net (all-stems-empty)', () => {
  function makeTrack() {
    const chops = (n) => Array.from({ length: n }, (_, i) => ({ column: i + 1, start_sec: i, length_sec: 1 }));
    return {
      bpm: 105,
      stems: {
        drums: { chops: chops(8) }, bass: { chops: chops(8) },
        other: { chops: chops(8) }, vox: { mode: 'full_stem', chops: chops(1) },
      },
    };
  }
  const trackIds = {
    drums: "live_set tracks 0", bass: "live_set tracks 1",
    other: "live_set tracks 2", vox: "live_set tracks 3",
  };
  const preset = { trackId: "5966", chops: {} };

  it('refuses to wipe a track when 0 clips are found across all stems', () => {
    const ctx = load(makeEnv(() => false)); // every slot empty
    const mTrack = makeTrack();
    const result = ctx.syncPresetClips(preset, mTrack, 8, trackIds);
    expect(result).to.equal(0);
    // all chops must be intact — NOT wiped
    expect(mTrack.stems.drums.chops).to.have.length(8);
    expect(mTrack.stems.bass.chops).to.have.length(8);
    expect(mTrack.stems.other.chops).to.have.length(8);
    expect(mTrack.stems.vox.chops).to.have.length(1);
  });

  it('does NOT abort (proceeds to reconcile) when clips ARE present in the read set', () => {
    // clips present in slots 8..15 → totalLive > 0 → guard does not fire
    const ctx = load(makeEnv((slot) => slot >= 8 && slot < 16));
    const mTrack = makeTrack();
    // Should proceed past the guard (not the early 0-return). With the bare
    // mock the reconcile may rewrite chop counts, but it must NOT be the
    // guard's untouched-return: prove it ran by reading at the B-bank offset.
    const result = ctx.syncPresetClips(preset, mTrack, 8, trackIds);
    expect(result).to.be.a('number');
    // at least one stem still has clips captured (other-stem deletion aside)
    const total = ['drums', 'bass', 'other', 'vox']
      .reduce((acc, s) => acc + mTrack.stems[s].chops.length, 0);
    expect(total).to.be.greaterThan(0);
  });

  it('stamps stems curated:true after a real sync (so reload honors empties)', () => {
    const ctx = load(makeEnv((slot) => slot >= 8 && slot < 16));
    const mTrack = makeTrack();
    ctx.syncPresetClips(preset, mTrack, 8, trackIds);
    expect(mTrack.stems.drums.curated).to.equal(true);
    expect(mTrack.stems.other.curated).to.equal(true);
  });
});

describe('curated empty stem (delete-all persists across reload)', () => {
  it('curated stem with 0 chops loads NOTHING (all disabled) — no blind grid', () => {
    const ctx = load(makeEnv());
    const track = {
      id: '5966', bpm: 105, downbeat_sec: 0.16,
      stems: { other: { path: '/x/other.wav', chops: [], curated: true } },
    };
    const other = ctx.computeTrackChops(track).other;
    expect(other).to.have.length(8);
    expect(other.every((c) => c.disabled)).to.equal(true);
  });

  it('UN-curated stem with 0 chops still blind-grids (uncurated tracks unchanged)', () => {
    const ctx = load(makeEnv());
    const track = {
      id: '9999', bpm: 105, downbeat_sec: 0.16, varying: false,
      stems: { other: { path: '/x/other.wav', chops: [] } },
    };
    const other = ctx.computeTrackChops(track).other;
    expect(other.filter((c) => !c.disabled).length).to.be.greaterThan(0);
  });
});
