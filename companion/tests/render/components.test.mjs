/**
 * Render component tests — surface-mirror, now-playing, legend.
 * Pure function tests: state → HTML string assertions.
 *
 * Run: node --test companion/tests/render/components.test.mjs
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

// Import render fns
import { renderSurfaceMirror, _presetColor } from '../../app/render/surface-mirror.js';
import { renderNowPlaying, _sourceColor, _renderWaveform } from '../../app/render/now-playing.js';
import { renderLegend, getPresetById } from '../../app/render/legend.js';

describe('surface-mirror', () => {
  it('renders 64 grid cells', () => {
    const html = renderSurfaceMirror(sampleState);
    const cellCount = (html.match(/class="cell/g) || []).length;
    assert.equal(cellCount, 64);
  });

  it('marks live chop cells with "live" class', () => {
    const html = renderSurfaceMirror(sampleState);
    assert.ok(html.includes('cell live'));
  });

  it('colors sourced cells with preset color', () => {
    const html = renderSurfaceMirror(sampleState);
    assert.ok(html.includes('#F5A623')); // A1's color (drums/other source)
  });

  it('renders left side buttons with stem labels', () => {
    const html = renderSurfaceMirror(sampleState);
    assert.ok(html.includes('DR'));
    assert.ok(html.includes('BA'));
  });

  it('renders top A and bottom B preset buttons', () => {
    const html = renderSurfaceMirror(sampleState);
    assert.ok(html.includes('A1'));
    assert.ok(html.includes('B1'));
  });

  it('_presetColor finds color for A1', () => {
    assert.equal(_presetColor(sampleState, 'A1'), '#F5A623');
  });

  it('_presetColor returns null for empty preset', () => {
    assert.equal(_presetColor(sampleState, 'A6'), null);
  });
});

describe('now-playing', () => {
  it('renders all now_playing stems', () => {
    const html = renderNowPlaying(sampleState);
    const stemCount = (html.match(/class="stem"/g) || []).length;
    assert.equal(stemCount, sampleState.now_playing.length);
  });

  it('shows song name', () => {
    const html = renderNowPlaying(sampleState);
    assert.ok(html.includes('Around the World'));
  });

  it('shows bars-left', () => {
    const html = renderNowPlaying(sampleState);
    assert.ok(html.includes('bars'));
  });

  it('renders progress playhead', () => {
    const html = renderNowPlaying(sampleState);
    assert.ok(html.includes('class="play"'));
    assert.ok(html.includes('left:62%'));
  });

  it('renders waveform bars when peaks provided', () => {
    const peaks = { peaks: [[0, 0.5], [-0.3, 0.7], [-0.1, 0.2]] };
    const html = _renderWaveform(peaks, 50, '#F5A623');
    assert.ok(html.includes('class="bars"'));
    const barCount = (html.match(/<i /g) || []).length;
    assert.equal(barCount, 3);
  });

  it('_sourceColor finds color for sourced preset', () => {
    assert.equal(_sourceColor(sampleState, 'A1'), '#F5A623');
    assert.equal(_sourceColor(sampleState, 'B3'), '#8C7BFF');
  });
});

describe('legend', () => {
  it('renders all 16 presets (8 per bank)', () => {
    const html = renderLegend(sampleState);
    const preCount = (html.match(/class="pre/g) || []).length;
    assert.equal(preCount, 16);
  });

  it('marks sourcing presets with "src" class', () => {
    const html = renderLegend(sampleState);
    assert.ok(html.includes('pre src'));
  });

  it('shows song name for loaded presets', () => {
    const html = renderLegend(sampleState);
    assert.ok(html.includes('Around the World'));
    assert.ok(html.includes('Kids'));
  });

  it('shows sourcing stem labels', () => {
    const html = renderLegend(sampleState);
    assert.ok(html.includes('drums other')); // A1 sources drums + other
  });

  it('marks empty presets', () => {
    const html = renderLegend(sampleState);
    assert.ok(html.includes('pre empty'));
  });

  it('getPresetById finds A4', () => {
    const p = getPresetById(sampleState, 'A4');
    assert.equal(p.song, 'Music Sounds Better');
  });

  it('colors match LEGEND_PALETTE', () => {
    const html = renderLegend(sampleState);
    assert.ok(html.includes('#F5A623')); // A1
    assert.ok(html.includes('#8C7BFF')); // B3
    assert.ok(html.includes('#34C8E8')); // B1
  });
});
