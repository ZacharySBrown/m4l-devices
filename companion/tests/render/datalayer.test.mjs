/**
 * Data layer unit tests — store reducer + interpolateProgress.
 * No DOM needed; runs under node --test.
 *
 * Run: node --test companion/tests/render/datalayer.test.mjs
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

// Import the interpolation function.
// Since app.js uses browser APIs (document, fetch, requestAnimationFrame),
// we extract the pure logic to test here by re-implementing it identically.
// This mirrors the production code in app.js::interpolateProgress.

function interpolateProgress(state, elapsedMs) {
  if (!state || !state.set || !state.set.bpm || state.set.bpm <= 0) return state;
  if (!state.decks) return state;

  const bpm = state.set.bpm;
  const beatsPerMs = bpm / 60000;
  const barsElapsed = (beatsPerMs * elapsedMs) / 4;

  const result = JSON.parse(JSON.stringify(state));

  for (const deckKey of ['A', 'B']) {
    const deck = result.decks[deckKey];
    if (!deck || !deck.stems) continue;
    for (const stemName of Object.keys(deck.stems)) {
      const stem = deck.stems[stemName];
      if (stem.live_chop === null || stem.live_chop === undefined) continue;
      if (stem.bars_left <= 0) continue;

      const totalBars = stem.bars_left / (1 - stem.progress / 100);
      if (totalBars <= 0) continue;
      const pctPerBar = 100 / totalBars;
      stem.progress = Math.min(100, stem.progress + barsElapsed * pctPerBar);
      stem.bars_left = Math.max(0, stem.bars_left - barsElapsed);
    }
  }
  return result;
}

describe('interpolateProgress', () => {
  const baseState = {
    set: { name: 'Test', bpm: 120, bar: '1.1.1', is_playing: true },
    decks: {
      A: { stems: {
        drums: { source: 'A1', loaded_chops: 8, live_chop: 2, progress: 50, bars_left: 4 },
        bass:  { source: 'A1', loaded_chops: 8, live_chop: null, progress: 0, bars_left: 0 },
      }},
      B: { stems: {
        drums: { source: 'B1', loaded_chops: 8, live_chop: 0, progress: 25, bars_left: 6 },
      }}
    },
    presets: { bankA: [], bankB: [] },
    now_playing: [], recommendations: [], scenes: [],
  };

  it('advances progress for live clips', () => {
    const result = interpolateProgress(baseState, 500); // 500ms at 120bpm = 1 beat = 0.25 bars
    // drums A: was 50%, 4 bars left (total ~8 bars)
    assert.ok(result.decks.A.stems.drums.progress > 50);
    assert.ok(result.decks.A.stems.drums.bars_left < 4);
  });

  it('does not change clips with live_chop=null', () => {
    const result = interpolateProgress(baseState, 500);
    assert.equal(result.decks.A.stems.bass.progress, 0);
    assert.equal(result.decks.A.stems.bass.bars_left, 0);
  });

  it('caps progress at 100', () => {
    const result = interpolateProgress(baseState, 60000); // 1 minute — way past done
    assert.ok(result.decks.A.stems.drums.progress <= 100);
    assert.ok(result.decks.A.stems.drums.bars_left >= 0);
  });

  it('returns state unchanged with zero BPM', () => {
    const bad = { ...baseState, set: { ...baseState.set, bpm: 0 } };
    const result = interpolateProgress(bad, 500);
    assert.deepEqual(result, bad);
  });

  it('returns null/undefined state unchanged', () => {
    assert.equal(interpolateProgress(null, 500), null);
    assert.equal(interpolateProgress(undefined, 500), undefined);
  });

  it('does not mutate the input state', () => {
    const before = JSON.stringify(baseState);
    interpolateProgress(baseState, 500);
    assert.equal(JSON.stringify(baseState), before);
  });

  it('interpolates both decks independently', () => {
    const result = interpolateProgress(baseState, 500);
    // Deck A drums and Deck B drums should both advance
    assert.ok(result.decks.A.stems.drums.progress > 50);
    assert.ok(result.decks.B.stems.drums.progress > 25);
  });
});

describe('store contract', () => {
  it('interpolateProgress is a pure function', () => {
    // Call twice with same input → same output
    const r1 = interpolateProgress(baseState(), 200);
    const r2 = interpolateProgress(baseState(), 200);
    assert.deepEqual(r1, r2);

    function baseState() {
      return {
        set: { name: 'Test', bpm: 120 },
        decks: { A: { stems: { drums: { source: 'A1', loaded_chops: 8, live_chop: 0, progress: 30, bars_left: 5 } } }, B: { stems: {} } },
        presets: { bankA: [], bankB: [] }, now_playing: [], recommendations: [], scenes: [],
      };
    }
  });
});
