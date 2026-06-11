/**
 * Perform view UAT — "replace-the-Ableton-window" checklist.
 * Renders Perform vs sample_state.json and asserts every
 * perform-critical datum is present in the output.
 *
 * Run: node --test companion/tests/uat_perform.test.mjs
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

import { renderSurfaceMirror } from '../app/render/surface-mirror.js';
import { renderNowPlaying } from '../app/render/now-playing.js';
import { renderLegend } from '../app/render/legend.js';
import { renderRecommendations } from '../app/render/recommendations.js';

describe('Perform view — Ableton-window replacement checklist', () => {
  const surface = renderSurfaceMirror(sampleState);
  const nowPlaying = renderNowPlaying(sampleState);
  const legend = renderLegend(sampleState);
  const recs = renderRecommendations(sampleState);
  const allHtml = surface + nowPlaying + legend + recs;

  // ── What's playing ──
  it('shows all now_playing stems', () => {
    const count = (nowPlaying.match(/class="stem"/g) || []).length;
    assert.equal(count, 4, 'expected 4 now-playing stems');
  });

  it('shows song names for active stems', () => {
    assert.ok(allHtml.includes('Around the World'), 'missing Around the World');
    assert.ok(allHtml.includes('Let It Happen'), 'missing Let It Happen');
  });

  it('shows artist names', () => {
    assert.ok(allHtml.includes('Daft Punk'), 'missing Daft Punk');
    assert.ok(allHtml.includes('MGMT'), 'missing MGMT');
  });

  // ── Source per stem ──
  it('surface shows 64 grid cells', () => {
    const count = (surface.match(/class="cell/g) || []).length;
    assert.equal(count, 64);
  });

  it('legend shows all 16 presets', () => {
    const count = (legend.match(/class="pre/g) || []).length;
    assert.equal(count, 16);
  });

  it('source color visible for active presets', () => {
    assert.ok(allHtml.includes('#F5A623'), 'A1 color missing');
    assert.ok(allHtml.includes('#8C7BFF'), 'B3 color missing');
  });

  // ── Bars left ──
  it('shows bars-left count', () => {
    assert.ok(nowPlaying.includes('bars'), 'bars-left missing');
    assert.ok(nowPlaying.includes('2 bars') || nowPlaying.includes('6 bars'), 'specific bars count');
  });

  // ── Mix-Next ──
  it('shows recommendations', () => {
    assert.ok(recs.includes('D.A.N.C.E.'), 'missing recommended song');
    assert.ok(recs.includes('congruent') || recs.includes('spicy'), 'missing type tag');
  });

  it('shows recommendation scores', () => {
    assert.ok(recs.includes('96'), 'missing score');
  });

  // ── Progress playhead ──
  it('progress playhead rendered', () => {
    assert.ok(nowPlaying.includes('class="play"'), 'playhead missing');
  });

  // ── Sourcing info in legend ──
  it('legend shows which stems each preset sources', () => {
    assert.ok(legend.includes('drums other'), 'A1 sourcing missing');
    assert.ok(legend.includes('bass vox') || legend.includes('vox'), 'A4/B1 sourcing');
  });
});
