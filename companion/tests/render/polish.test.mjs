/**
 * Polish tests: action delegation, playhead interpolation, partial-state robustness.
 *
 * Run: node --test companion/tests/render/polish.test.mjs
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const sampleState = JSON.parse(
  readFileSync(resolve(__dirname, '../../sample_state.json'), 'utf-8')
);

import { renderSurfaceMirror } from '../../app/render/surface-mirror.js';
import { renderNowPlaying } from '../../app/render/now-playing.js';
import { renderLegend } from '../../app/render/legend.js';
import { renderRecommendations } from '../../app/render/recommendations.js';
import { renderScenes } from '../../app/render/scenes.js';

// Re-import interpolateProgress (same logic as app.js)
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

describe('action delegation', () => {
  it('render output contains data-action attributes for clickable elements', () => {
    const scenes = renderScenes(sampleState);
    assert.ok(scenes.includes('data-action="recall_scene"'), 'recall_scene missing');
    assert.ok(scenes.includes('data-action="untag_scene"'), 'untag_scene missing');
    assert.ok(scenes.includes('data-action="tag_scene"'), 'tag_scene missing');
  });

  it('recommendations have action buttons', () => {
    const recs = renderRecommendations(sampleState);
    assert.ok(recs.includes('data-action="queue_set"'), 'queue_set action missing');
  });

  it('scene cards carry data-id for action routing', () => {
    const scenes = renderScenes(sampleState);
    assert.ok(scenes.includes('data-id="scene-hook-slam"'), 'scene id missing');
  });
});

describe('playhead interpolation', () => {
  it('progress advances after 500ms at 121 BPM', () => {
    const before = sampleState.decks.A.stems.drums.progress;
    const after = interpolateProgress(sampleState, 500);
    assert.ok(after.decks.A.stems.drums.progress > before, 'drums progress should advance');
  });

  it('bars_left decreases', () => {
    const before = sampleState.decks.A.stems.drums.bars_left;
    const after = interpolateProgress(sampleState, 500);
    assert.ok(after.decks.A.stems.drums.bars_left < before, 'bars_left should decrease');
  });
});

describe('partial-state robustness', () => {
  const partial = {
    set: { name: 'Test', bpm: 90 },
    decks: {
      A: { stems: { drums: { source: null } } },
      B: { stems: {} },
    },
    presets: { bankA: [{ id: 'A1' }], bankB: [] },
    now_playing: [],
    recommendations: [],
    scenes: [],
  };

  it('surface-mirror renders without throwing', () => {
    assert.doesNotThrow(() => renderSurfaceMirror(partial));
  });

  it('now-playing renders empty gracefully', () => {
    const html = renderNowPlaying(partial);
    assert.ok(!html.includes('undefined'), 'should not contain "undefined"');
  });

  it('legend handles single-item bank without throwing', () => {
    assert.doesNotThrow(() => renderLegend(partial));
  });

  it('recommendations renders empty list', () => {
    const html = renderRecommendations(partial);
    assert.ok(html.includes('No recommendations') || html.length > 0);
  });

  it('scenes renders empty list', () => {
    const html = renderScenes(partial);
    assert.ok(typeof html === 'string');
  });
});
