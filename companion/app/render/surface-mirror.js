/**
 * Surface mirror — 8×8 grid + side buttons, colored by source preset.
 * Pure render function: state → HTML string.
 */

const STEMS = ['drums', 'bass', 'other', 'vox', 'drums', 'bass', 'other', 'vox'];
const DECKS = ['A', 'A', 'A', 'A', 'B', 'B', 'B', 'B'];

export function renderSurfaceMirror(state) {
  if (!state || !state.decks || !state.presets) return '<div class="card"><p class="h">Surface</p></div>';

  const cells = [];
  for (let row = 0; row < 8; row++) {
    const deck = DECKS[row];
    const stem = STEMS[row];
    const deckData = state.decks[deck];
    const stemData = deckData?.stems?.[stem];
    const source = stemData?.source;
    const color = _presetColor(state, source);
    const liveChop = stemData?.live_chop;

    for (let col = 0; col < 8; col++) {
      const isLive = liveChop === col;
      const cls = isLive ? 'cell live' : (source ? 'cell on' : 'cell');
      const style = color ? `--c:${color}` : '';
      cells.push(`<div class="${cls}" style="${style}" data-row="${row}" data-col="${col}"></div>`);
    }
  }

  // Side buttons (left = stems, right = modifiers, top = A, bottom = B)
  const leftBtns = STEMS.map((stem, i) => {
    const deck = DECKS[i];
    const stemData = state.decks[deck]?.stems?.[stem];
    const color = _presetColor(state, stemData?.source);
    const style = color ? `border-color:${color};color:${color}` : '';
    return `<div class="sb stem" style="${style}">${stem.slice(0,2).toUpperCase()}</div>`;
  }).join('');

  const topBtns = (state.presets.bankA || []).map(p => {
    const cls = p.sourcing ? 'sb A on' : 'sb A';
    return `<div class="${cls}">${p.id}</div>`;
  }).join('');

  const botBtns = (state.presets.bankB || []).map(p => {
    const cls = p.sourcing ? 'sb B on' : 'sb B';
    return `<div class="${cls}">${p.id}</div>`;
  }).join('');

  return `<div class="card surface-mirror">
    <p class="h">Surface</p>
    <div class="toprow">${topBtns}</div>
    <div class="midrow">
      <div class="leftcol">${leftBtns}</div>
      <div class="padcore">${cells.join('')}</div>
    </div>
    <div class="botrow">${botBtns}</div>
  </div>`;
}

function _presetColor(state, sourceId) {
  if (!sourceId) return null;
  for (const bank of [state.presets.bankA, state.presets.bankB]) {
    const p = (bank || []).find(x => x.id === sourceId);
    if (p?.color) return p.color;
  }
  return null;
}

// Re-export for testing
export { _presetColor };
