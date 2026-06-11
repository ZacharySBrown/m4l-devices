/**
 * Preset legend — maps preset id → song/artist/key + color + sourcing.
 * Pure render function: state → HTML string.
 */

export function renderLegend(state) {
  if (!state || !state.presets) return '';

  const bankA = _renderBank('A', state.presets.bankA || []);
  const bankB = _renderBank('B', state.presets.bankB || []);

  return `<div class="card">
    <p class="h">Preset Legend</p>
    <div class="legend-banks">
      <div class="legend-bank">${bankA}</div>
      <div class="legend-bank">${bankB}</div>
    </div>
  </div>`;
}

function _renderBank(bankLabel, presets) {
  return presets.map(p => {
    const isEmpty = !p.song;
    const cls = isEmpty ? 'pre empty' : (p.sourcing ? 'pre src' : 'pre');
    const color = p.color || 'var(--muted)';
    const stemsTag = p.sourcing
      ? `<span class="stems" style="background:${color}">${p.sourcing.join(' ')}</span>`
      : '';

    return `<div class="${cls}" style="--c:${color}">
      <span class="sw" style="background:${color}"></span>
      <span class="id">${p.id}</span>
      <span class="nm"><b>${p.song || '—'}</b><span style="color:var(--muted);font-size:11px">${p.artist || ''}</span></span>
      ${stemsTag}
    </div>`;
  }).join('');
}

export function getPresetById(state, id) {
  if (!state || !state.presets) return null;
  for (const bank of [state.presets.bankA, state.presets.bankB]) {
    const p = (bank || []).find(x => x.id === id);
    if (p) return p;
  }
  return null;
}

export { _renderBank };
