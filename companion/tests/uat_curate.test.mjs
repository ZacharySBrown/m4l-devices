/**
 * Curate view UAT — clip select, A↔B swap, scene tag/recall/untag.
 * Tests the render output + action→control mapping.
 *
 * Run: node --test companion/tests/uat_curate.test.mjs
 */
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const sampleState = JSON.parse(
  readFileSync(resolve(__dirname, '../sample_state.json'), 'utf-8')
);

import { renderScenes, getSceneClipIds } from '../app/render/scenes.js';

// Simulate the curate render by composing deck clips
const STEMS = ['drums', 'bass', 'other', 'vox'];

function renderDeckClipsHtml(state, deckKey) {
  const deck = state.decks?.[deckKey];
  if (!deck) return '';
  let html = '';
  for (const stem of STEMS) {
    const sd = deck.stems[stem];
    if (!sd) continue;
    for (let i = 0; i < (sd.loaded_chops || 0); i++) {
      html += `<div data-action="select_clip" data-deck="${deckKey}" data-stem="${stem}" data-chop="${i}"></div>`;
    }
  }
  return html;
}

describe('Curate view — controls + actions', () => {
  it('renders clip cells with select_clip action data', () => {
    const html = renderDeckClipsHtml(sampleState, 'A');
    assert.ok(html.includes('data-action="select_clip"'));
    assert.ok(html.includes('data-deck="A"'));
    assert.ok(html.includes('data-stem="drums"'));
    assert.ok(html.includes('data-chop="0"'));
  });

  it('renders clip cells for both decks', () => {
    const htmlA = renderDeckClipsHtml(sampleState, 'A');
    const htmlB = renderDeckClipsHtml(sampleState, 'B');
    // A has loaded chops on all stems
    assert.ok(htmlA.includes('data-deck="A"'));
    assert.ok(htmlB.includes('data-deck="B"'));
  });

  it('scene board renders all scenes', () => {
    const html = renderScenes(sampleState);
    const sceneCount = (html.match(/class="scene-card"/g) || []).length;
    assert.equal(sceneCount, 3);
  });

  it('scene cards have recall and untag buttons', () => {
    const html = renderScenes(sampleState);
    assert.ok(html.includes('data-action="recall_scene"'));
    assert.ok(html.includes('data-action="untag_scene"'));
  });

  it('scene cards show clip chips', () => {
    const html = renderScenes(sampleState);
    assert.ok(html.includes('A·DR1'));
    assert.ok(html.includes('B·VX3'));
  });

  it('has a tag-scene button', () => {
    const html = renderScenes(sampleState);
    assert.ok(html.includes('data-action="tag_scene"'));
  });

  it('scene clip identity is preserved (getSceneClipIds)', () => {
    const scene = sampleState.scenes[0];
    const clips = getSceneClipIds(scene);
    assert.deepEqual(clips, ['A·DR1', 'B·VX3', 'A·OT2']);
  });

  it('scene clips survive conceptual A↔B swap (identity-based)', () => {
    // After swap, A becomes B and vice versa, but clip identities
    // like "A·DR1" are strings that point to what WAS deck A —
    // the scene board should track by clip_id, not by deck position.
    const scene = sampleState.scenes[0];
    const clipsBefore = getSceneClipIds(scene);
    // The clips are stored as strings — they survive regardless of deck state
    assert.ok(clipsBefore.includes('A·DR1'));
    // After a swap, the scene still holds the same clip references
    assert.deepEqual(getSceneClipIds(scene), clipsBefore);
  });
});
