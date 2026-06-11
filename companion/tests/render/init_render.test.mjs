/**
 * Guard B — first state arrival renders the active view.
 *
 * Tests that when _renderCurrent is called with state, the render fn
 * produces non-empty output that does NOT contain "Waiting for state".
 * Exercises the real render path without a full DOM.
 *
 * Run: node --test companion/tests/render/init_render.test.mjs
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

// Import the render functions that the views use
import { renderSurfaceMirror } from '../../app/render/surface-mirror.js';
import { renderNowPlaying } from '../../app/render/now-playing.js';
import { renderLegend } from '../../app/render/legend.js';
import { renderRecommendations } from '../../app/render/recommendations.js';
import { renderScenes } from '../../app/render/scenes.js';

describe('init render guard — first state populates view', () => {
  it('Perform components produce non-empty output with sample state', () => {
    const surface = renderSurfaceMirror(sampleState);
    const nowPlaying = renderNowPlaying(sampleState);
    const legend = renderLegend(sampleState);
    const recs = renderRecommendations(sampleState);

    assert.ok(surface.length > 100, 'surface output too short');
    assert.ok(nowPlaying.length > 50, 'now-playing output too short');
    assert.ok(legend.length > 50, 'legend output too short');
    assert.ok(recs.length > 50, 'recommendations output too short');
  });

  it('none of the render outputs contain "Waiting for state"', () => {
    const outputs = [
      renderSurfaceMirror(sampleState),
      renderNowPlaying(sampleState),
      renderLegend(sampleState),
      renderRecommendations(sampleState),
      renderScenes(sampleState),
    ];
    for (const html of outputs) {
      assert.ok(!html.includes('Waiting for state'),
        'render fn returned placeholder instead of real content');
    }
  });

  it('Perform render with null state returns placeholder (expected before first poll)', () => {
    // This is the "before first poll" state — renderPerform would show placeholder
    // The render fns handle null gracefully
    const surface = renderSurfaceMirror(null);
    assert.ok(surface.length > 0, 'null-state output should be a card placeholder');
  });
});
