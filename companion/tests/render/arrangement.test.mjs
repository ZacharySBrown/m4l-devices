/**
 * Arrangement view render tests.
 * Run: node --test companion/tests/render/arrangement.test.mjs
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

import { renderArrangement } from '../../app/render/arrangement.js';

// Mock container
function render(state) {
  const container = { innerHTML: '' };
  renderArrangement(container, state);
  return container.innerHTML;
}

describe('arrangement view', () => {
  it('renders placement blocks', () => {
    const html = render(sampleState);
    const blocks = (html.match(/class="tl-block"/g) || []).length;
    assert.equal(blocks, sampleState.arrangement.placements.length);
  });

  it('colors blocks by source', () => {
    const html = render(sampleState);
    assert.ok(html.includes('#F5A623'), 'A1 color');
    assert.ok(html.includes('#8C7BFF'), 'B3 color');
  });

  it('renders scene markers', () => {
    const html = render(sampleState);
    const markers = (html.match(/class="scene-marker"/g) || []).length;
    assert.equal(markers, sampleState.arrangement.scene_markers.length);
  });

  it('scene markers show names', () => {
    const html = render(sampleState);
    assert.ok(html.includes('Hook Slam'));
    assert.ok(html.includes('Float'));
  });

  it('renders 8 stem lanes (2 decks × 4 stems)', () => {
    const html = render(sampleState);
    const lanes = (html.match(/class="tl-lane"/g) || []).length;
    assert.equal(lanes, 8);
  });

  it('has place_pair action button', () => {
    const html = render(sampleState);
    assert.ok(html.includes('data-action="place_pair"'));
  });

  it('has save/load action buttons', () => {
    const html = render(sampleState);
    assert.ok(html.includes('data-action="save_arrangement"'));
    assert.ok(html.includes('data-action="load_arrangement"'));
  });

  it('renders playhead', () => {
    const html = render(sampleState);
    assert.ok(html.includes('tl-playhead'));
  });

  it('gracefully handles missing arrangement', () => {
    const noArr = { ...sampleState, arrangement: undefined };
    const html = render(noArr);
    assert.ok(html.includes('No arrangement data'));
  });
});
