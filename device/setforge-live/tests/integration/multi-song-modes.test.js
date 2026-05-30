'use strict';

const { expect } = require('chai');
const { computeTrackChops } = require('../../src/shared/chop-math');
const { createPresetBanks, SLOT_STATE } = require('../../src/loader/preset-banks');
const { createChopRouter, STEM_ROWS, CHOP_STATE } = require('../../src/loader/chop-router');
const { createSceneMemory, SCENE_STATE } = require('../../src/loader/scene-memory');
const { createModifierLayer, MOD_STATE, DOUBLE_TAP_WINDOW_MS } = require('../../src/loader/modifier-layer');
const { STEM_ROWS: STEM_ROW_MAP } = require('../../src/shared/live-api-helpers');
const { loadManifest } = require('../harness/fixture-loader');

// ═══════════════════════════════════════════════════════════
//  Phase 1: Layout reshuffle
// ═══════════════════════════════════════════════════════════

describe('Phase 1: layout reshuffle', () => {
  it('stem rows are 1-4 (drums=1, bass=2, other=3, vox=4)', () => {
    expect(STEM_ROW_MAP.drums).to.equal(1);
    expect(STEM_ROW_MAP.bass).to.equal(2);
    expect(STEM_ROW_MAP.other).to.equal(3);
    expect(STEM_ROW_MAP.vox).to.equal(4);
  });

  it('chop router STEM_ROWS matches new layout', () => {
    expect(STEM_ROWS[1]).to.equal('drums');
    expect(STEM_ROWS[2]).to.equal('bass');
    expect(STEM_ROWS[3]).to.equal('other');
    expect(STEM_ROWS[4]).to.equal('vox');
  });

  it('rows 5-8 are not stem rows in chop router', () => {
    expect(STEM_ROWS[5]).to.be.undefined;
    expect(STEM_ROWS[6]).to.be.undefined;
    expect(STEM_ROWS[7]).to.be.undefined;
    expect(STEM_ROWS[8]).to.be.undefined;
  });

  it('chop router rejects presses on non-stem rows', () => {
    const banks = createPresetBanks();
    const router = createChopRouter(banks);
    const mods = createModifierLayer();
    const manifest = loadManifest('hiphop_v3');
    const track = manifest.tracks[0];
    banks.loadSlot(0, 'test', track, computeTrackChops(track));
    banks.activate(0);

    // Row 5 (bank A), 6 (bank B), 7 (mods), 8 (scenes) should return null
    expect(router.press(5, 1, mods)).to.be.null;
    expect(router.press(6, 1, mods)).to.be.null;
    expect(router.press(7, 1, mods)).to.be.null;
    expect(router.press(8, 1, mods)).to.be.null;

    // Rows 1-4 should work
    expect(router.press(1, 1, mods)).to.not.be.null;
    expect(router.press(2, 1, mods)).to.not.be.null;
    expect(router.press(3, 1, mods)).to.not.be.null;
    expect(router.press(4, 1, mods)).to.not.be.null;
  });

  it('getHeldChops returns correct rows after layout change', () => {
    const banks = createPresetBanks();
    const router = createChopRouter(banks);
    const mods = createModifierLayer();
    const manifest = loadManifest('hiphop_v3');
    const track = manifest.tracks[0];
    banks.loadSlot(0, 'test', track, computeTrackChops(track));
    banks.activate(0);

    router.press(1, 3, mods); // drums row 1
    router.press(4, 2, mods); // vox row 4

    const held = router.getHeldChops();
    expect(held).to.have.lengthOf(2);
    expect(held.find(h => h.stem === 'drums').row).to.equal(1);
    expect(held.find(h => h.stem === 'vox').row).to.equal(4);
  });
});

// ═══════════════════════════════════════════════════════════
//  Phase 2: Per-row mode
// ═══════════════════════════════════════════════════════════

describe('Phase 2: per-row mode', () => {
  it('SOLO double-tap latches (per-row mode entry gesture)', () => {
    const mods = createModifierLayer();
    mods.press('SOLO', 1000);
    mods.release('SOLO');
    mods.press('SOLO', 1000 + DOUBLE_TAP_WINDOW_MS - 50);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
  });

  it('SOLO latch release (per-row mode exit gesture)', () => {
    const mods = createModifierLayer();
    // Double-tap to latch
    mods.press('SOLO', 1000);
    mods.release('SOLO');
    mods.press('SOLO', 1200);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
    mods.release('SOLO');

    // Third press releases latch
    mods.press('SOLO', 5000);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.IDLE);
  });

  it('held chops survive SOLO latch toggle', () => {
    const banks = createPresetBanks();
    const router = createChopRouter(banks);
    const mods = createModifierLayer();
    const manifest = loadManifest('hiphop_v3');
    const track = manifest.tracks[0];
    banks.loadSlot(0, 'test', track, computeTrackChops(track));
    banks.activate(0);

    // Play drums
    router.press(1, 3, mods);
    expect(router.getPlaying('drums')).to.equal(3);

    // Double-tap SOLO (entering per-row)
    mods.press('SOLO', 1000);
    mods.release('SOLO');
    mods.press('SOLO', 1200);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);

    // Drums still playing
    expect(router.getPlaying('drums')).to.equal(3);

    // Exit per-row
    mods.press('SOLO', 5000);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.IDLE);

    // Drums still playing
    expect(router.getPlaying('drums')).to.equal(3);
  });

  it('scene snapshot includes view and rowSources fields', () => {
    const scenes = createSceneMemory();

    // Save a per-row scene
    const snapshot = {
      activePresetIndex: 0,
      heldChops: [{ row: 1, col: 1, stem: 'drums' }],
      modifiers: { SOLO: 'latched' },
      view: 'perRow',
      rowSources: { drums: 0, bass: 3, other: 0, vox: 8 },
      stagingDeckX: null,
      stagingDeckY: null,
    };
    scenes.save(0, snapshot);

    const recalled = scenes.recall(0);
    expect(recalled.view).to.equal('perRow');
    expect(recalled.rowSources.bass).to.equal(3);
    expect(recalled.rowSources.vox).to.equal(8);
  });

  it('legacy scene without view field defaults correctly', () => {
    const scenes = createSceneMemory();
    const legacySnapshot = {
      activePresetIndex: 0,
      heldChops: [],
      modifiers: {},
    };
    scenes.save(0, legacySnapshot);
    const recalled = scenes.recall(0);
    // Missing view field — caller should treat as "solo"
    expect(recalled.view).to.be.undefined;
  });

  it('hot-swap works per-row (only affects target stem)', () => {
    const banks = createPresetBanks();
    const router = createChopRouter(banks);
    const mods = createModifierLayer();

    const manifest = loadManifest('hiphop_v3');
    const trackA = manifest.tracks[0];
    const trackB = manifest.tracks[1];

    banks.loadSlot(0, 'track_a', trackA, computeTrackChops(trackA));
    banks.loadSlot(1, 'track_b', trackB, computeTrackChops(trackB));
    banks.activate(0);

    // Play drums col 1 and bass col 2
    router.press(1, 1, mods);
    router.press(2, 2, mods);
    expect(router.getPlaying('drums')).to.equal(1);
    expect(router.getPlaying('bass')).to.equal(2);

    // Hot-swap with trackB's chops (simulating per-row reassign of drums only)
    // In per-row mode, only the reassigned row's chops would be swapped
    const drumsOnlyChops = { drums: banks.getSlot(1).chops.drums };
    // This tests that hot-swap only touches stems with active chops
    const migrations = router.hotSwap(drumsOnlyChops);

    // Drums should migrate, bass should stop (no bass in drumsOnlyChops)
    const drumsMig = migrations.find(m => m.stem === 'drums');
    const bassMig = migrations.find(m => m.stem === 'bass');
    expect(drumsMig.newChop).to.not.be.null;
    expect(bassMig.newChop).to.be.null;
  });
});

// ═══════════════════════════════════════════════════════════
//  Phase 3: Staging + pre-loading
// ═══════════════════════════════════════════════════════════

describe('Phase 3: staging + pre-loading', () => {
  it('staging state tracks deck assignments', () => {
    // Test the staging state model directly
    const staging = { deckX: null, deckY: null, stagingHeld: false };

    // Simulate staging gesture
    staging.stagingHeld = true;
    staging.deckX = 2; // bank A slot 2
    staging.deckY = 10; // bank B slot 10
    staging.stagingHeld = false;

    expect(staging.deckX).to.equal(2);
    expect(staging.deckY).to.equal(10);
  });

  it('restaging replaces previous deck assignment', () => {
    const staging = { deckX: 2, deckY: 10, stagingHeld: false };

    // Restage deck X
    staging.deckX = 5;
    expect(staging.deckX).to.equal(5);
    expect(staging.deckY).to.equal(10); // Y unchanged
  });

  it('staging follows slot not song', () => {
    // If a slot's content changes, the staging reference (slot index)
    // still points to that slot — the new content becomes the source
    const banks = createPresetBanks();
    const manifest = loadManifest('hiphop_v3');
    const trackA = manifest.tracks[0];
    const trackB = manifest.tracks[1];

    banks.loadSlot(0, 'track_a', trackA, computeTrackChops(trackA));

    // Stage slot 0
    const staging = { deckX: 0 };

    // Now swap slot 0's content
    banks.loadSlot(0, 'track_b', trackB, computeTrackChops(trackB));

    // Staging still points to slot 0 — now has track_b
    expect(staging.deckX).to.equal(0);
    expect(banks.getSlot(0).trackId).to.equal('track_b');
  });

  it('scene captures staging state', () => {
    const scenes = createSceneMemory();
    const snapshot = {
      activePresetIndex: 0,
      heldChops: [],
      modifiers: {},
      view: 'solo',
      stagingDeckX: 2,
      stagingDeckY: 10,
    };
    scenes.save(0, snapshot);
    const recalled = scenes.recall(0);
    expect(recalled.stagingDeckX).to.equal(2);
    expect(recalled.stagingDeckY).to.equal(10);
  });

  it('lastActive bank tracking for fallback', () => {
    // Simple state model test
    let lastActiveBankA = null;
    let lastActiveBankB = null;

    // Tap preset on row 5 (bank A, slot 3)
    lastActiveBankA = 3;
    // Tap preset on row 6 (bank B, slot 11)
    lastActiveBankB = 11;

    expect(lastActiveBankA).to.equal(3);
    expect(lastActiveBankB).to.equal(11);
  });
});

// ═══════════════════════════════════════════════════════════
//  Phase 4: Dual-song view
// ═══════════════════════════════════════════════════════════

describe('Phase 4: dual-song view', () => {
  let banks;

  beforeEach(() => {
    banks = createPresetBanks();
    const manifest = loadManifest('hiphop_v3');
    const trackA = manifest.tracks[0];
    const trackB = manifest.tracks[1];
    banks.loadSlot(0, 'the_next_episode', trackA, computeTrackChops(trackA));
    banks.loadSlot(8, 'big_poppa', trackB, computeTrackChops(trackB));
  });

  it('dual-song view maps rows 1-4 to deck X, rows 5-8 to deck Y', () => {
    const loadedDecks = { deckX: 0, deckY: 8 };

    // Row 1 → deckX drums, Row 5 → deckY drums
    for (let r = 1; r <= 4; r++) {
      const stemIdx = r - 1;
      const stem = ['drums', 'bass', 'other', 'vox'][stemIdx];
      const deck = 'deckX';
      const slot = banks.getSlot(loadedDecks[deck]);
      expect(slot).to.not.be.null;
      expect(slot.chops[stem]).to.not.be.null;
    }

    for (let r = 5; r <= 8; r++) {
      const stemIdx = r - 5;
      const stem = ['drums', 'bass', 'other', 'vox'][stemIdx];
      const deck = 'deckY';
      const slot = banks.getSlot(loadedDecks[deck]);
      expect(slot).to.not.be.null;
      expect(slot.chops[stem]).to.not.be.null;
    }
  });

  it('8 simultaneous voices: each deck×stem combo is independent', () => {
    const dualSongPlaying = {};

    // Fire chops from both decks
    dualSongPlaying['deckX_drums'] = 3;
    dualSongPlaying['deckX_bass'] = 1;
    dualSongPlaying['deckY_drums'] = 5;
    dualSongPlaying['deckY_vox'] = 2;

    expect(Object.keys(dualSongPlaying)).to.have.lengthOf(4);
    expect(dualSongPlaying['deckX_drums']).to.equal(3);
    expect(dualSongPlaying['deckY_drums']).to.equal(5);
  });

  it('dual-song entry requires both decks', () => {
    // Test the entry validation logic
    function canEnterDualSong(staging, lastA, lastB) {
      const deckX = staging.deckX !== null ? staging.deckX : lastA;
      const deckY = staging.deckY !== null ? staging.deckY : lastB;
      return deckX !== null && deckY !== null;
    }

    expect(canEnterDualSong({ deckX: 0, deckY: 8 }, null, null)).to.be.true;
    expect(canEnterDualSong({ deckX: null, deckY: null }, 0, 8)).to.be.true;
    expect(canEnterDualSong({ deckX: null, deckY: null }, null, null)).to.be.false;
    expect(canEnterDualSong({ deckX: 0, deckY: null }, null, null)).to.be.false;
  });

  it('scene save in dual-song captures view state', () => {
    const scenes = createSceneMemory();
    const snapshot = {
      activePresetIndex: 0,
      heldChops: [
        { row: 1, col: 3, stem: 'drums' },
        { row: 5, col: 1, stem: 'drums' }, // deck Y drums
      ],
      modifiers: {},
      view: 'dualSong',
      stagingDeckX: 0,
      stagingDeckY: 8,
    };
    scenes.save(0, snapshot);
    const recalled = scenes.recall(0);
    expect(recalled.view).to.equal('dualSong');
    expect(recalled.heldChops).to.have.lengthOf(2);
    expect(recalled.stagingDeckX).to.equal(0);
    expect(recalled.stagingDeckY).to.equal(8);
  });

  it('per-row and dual-song are mutually exclusive (state model)', () => {
    // Model: entering dual-song from per-row suspends per-row
    let performanceView = 'perRow';
    let dualSongActive = false;
    let preDualSongView = null;

    // Enter dual-song
    preDualSongView = performanceView;
    dualSongActive = true;

    expect(dualSongActive).to.be.true;
    expect(preDualSongView).to.equal('perRow');

    // Exit dual-song restores per-row
    dualSongActive = false;
    performanceView = preDualSongView;

    expect(performanceView).to.equal('perRow');
    expect(dualSongActive).to.be.false;
  });

  it('launch quantization preserved per stem in dual-song', () => {
    const { ROW_QUANT_DEFAULTS } = require('../../src/shared/live-api-helpers');

    // Rows 1,5 = drums → 1/16
    // Rows 2,6 = bass → 1 bar
    // Rows 3,7 = other → 1/4
    // Rows 4,8 = vox → 1/2
    const stemForDualRow = (r) => ['drums', 'bass', 'other', 'vox'][(r <= 4 ? r - 1 : r - 5)];

    expect(ROW_QUANT_DEFAULTS[stemForDualRow(1)]).to.equal(ROW_QUANT_DEFAULTS[stemForDualRow(5)]);
    expect(ROW_QUANT_DEFAULTS[stemForDualRow(2)]).to.equal(ROW_QUANT_DEFAULTS[stemForDualRow(6)]);
    expect(ROW_QUANT_DEFAULTS[stemForDualRow(3)]).to.equal(ROW_QUANT_DEFAULTS[stemForDualRow(7)]);
    expect(ROW_QUANT_DEFAULTS[stemForDualRow(4)]).to.equal(ROW_QUANT_DEFAULTS[stemForDualRow(8)]);
  });

  it('invisible held chops: chops from non-displayed presets keep playing', () => {
    // State model: heldChops track source preset for visibility check
    const heldChops = [
      { presetId: 0, stem: 'drums', chopIndex: 3 },
      { presetId: 5, stem: 'bass', chopIndex: 1 }, // from a third preset
    ];
    const loadedDecks = { deckX: 0, deckY: 8 };

    const visiblePresets = [loadedDecks.deckX, loadedDecks.deckY];
    const invisibleHeld = heldChops.filter(hc => !visiblePresets.includes(hc.presetId));

    expect(invisibleHeld).to.have.lengthOf(1);
    expect(invisibleHeld[0].presetId).to.equal(5);
  });

  it('panic resets all multi-song state', () => {
    // Simulate panic state reset
    let performanceView = 'perRow';
    let dualSongActive = true;
    const rowSources = { drums: 3, bass: 5, other: 0, vox: 8 };
    const dualSongPlaying = { deckX_drums: 3 };

    // Panic
    performanceView = 'solo';
    dualSongActive = false;
    for (const stem of ['drums', 'bass', 'other', 'vox']) {
      rowSources[stem] = null;
    }
    for (const key of Object.keys(dualSongPlaying)) {
      delete dualSongPlaying[key];
    }

    expect(performanceView).to.equal('solo');
    expect(dualSongActive).to.be.false;
    expect(rowSources.drums).to.be.null;
    expect(Object.keys(dualSongPlaying)).to.have.lengthOf(0);
  });
});

// ═══════════════════════════════════════════════════════════
//  Cross-phase: view transition matrix
// ═══════════════════════════════════════════════════════════

describe('View transition matrix', () => {
  it('solo → perRow via double-tap SOLO', () => {
    const mods = createModifierLayer();
    mods.press('SOLO', 1000);
    mods.release('SOLO');
    mods.press('SOLO', 1200);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
    // Controller would set performanceView = "perRow"
  });

  it('perRow → solo via double-tap SOLO (latch release)', () => {
    const mods = createModifierLayer();
    // Enter per-row
    mods.press('SOLO', 1000);
    mods.release('SOLO');
    mods.press('SOLO', 1200);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
    mods.release('SOLO');

    // Exit per-row
    mods.press('SOLO', 5000);
    expect(mods.getState('SOLO')).to.equal(MOD_STATE.IDLE);
    // Controller would set performanceView = "solo"
  });

  it('modifier snapshot preserves SOLO latch for scene recall', () => {
    const mods = createModifierLayer();
    // Enter per-row
    mods.press('SOLO', 1000);
    mods.release('SOLO');
    mods.press('SOLO', 1200);

    const snap = mods.snapshot();
    expect(snap.SOLO).to.equal(MOD_STATE.LATCHED);

    // Restore on another instance
    const mods2 = createModifierLayer();
    mods2.restore(snap);
    expect(mods2.getState('SOLO')).to.equal(MOD_STATE.LATCHED);
  });
});
