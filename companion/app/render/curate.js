/**
 * Curate view — clip select/audition, A↔B swap, scene board.
 * Composes deck clip grids + swap control + scene board.
 */

import { renderLegend } from './legend.js';
import { renderScenes } from './scenes.js';

const STEMS = ['drums', 'bass', 'other', 'vox'];

export function renderCurate(container, state) {
  if (!state) {
    container.innerHTML = '<p style="color:var(--muted)">Waiting for state...</p>';
    return;
  }

  const deckA = _renderDeckClips('A', state);
  const deckB = _renderDeckClips('B', state);
  const swap = `<div class="swap-control">
    <button class="swap-btn" data-action="swap_ab">A ↔ B</button>
  </div>`;
  const legend = renderLegend(state);
  const scenes = renderScenes(state);

  container.innerHTML = `
    <div class="curate-layout">
      <div class="decks-row">
        <div class="deck-panel card">
          <p class="h">Deck A</p>
          ${deckA}
        </div>
        ${swap}
        <div class="deck-panel card">
          <p class="h">Deck B</p>
          ${deckB}
        </div>
      </div>
      <div class="curate-bottom">
        ${scenes}
        ${legend}
      </div>
    </div>
  `;
}

function _renderDeckClips(deckKey, state) {
  const deck = state.decks?.[deckKey];
  if (!deck || !deck.stems) return '<p style="color:var(--muted)">No deck data</p>';

  return STEMS.map(stem => {
    const stemData = deck.stems[stem];
    if (!stemData) return '';
    const source = stemData.source;
    const color = _presetColor(state, source);
    const chops = stemData.loaded_chops || 0;
    const liveChop = stemData.live_chop;

    const cells = [];
    for (let i = 0; i < chops; i++) {
      const isLive = liveChop === i;
      const cls = isLive ? 'clip-cell live' : 'clip-cell';
      cells.push(`<div class="${cls}" style="--c:${color || 'var(--muted)'}" data-action="select_clip" data-deck="${deckKey}" data-stem="${stem}" data-chop="${i}">${i + 1}</div>`);
    }

    return `<div class="stem-row" style="--c:${color || 'var(--muted)'}">
      <span class="stem-label">${stem.toUpperCase()}</span>
      <span class="stem-song">${stemData.song || '—'}</span>
      <div class="clip-cells">${cells.join('')}</div>
    </div>`;
  }).join('');
}

function _presetColor(state, sourceId) {
  if (!sourceId || !state.presets) return null;
  for (const bank of [state.presets.bankA, state.presets.bankB]) {
    const p = (bank || []).find(x => x.id === sourceId);
    if (p?.color) return p.color;
  }
  return null;
}
