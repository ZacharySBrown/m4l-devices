/**
 * Now-playing render — per-stem waveform + progress + bars-left.
 * Pure render function: (state, peaksMap) → HTML string.
 * peaksMap: { [clip_id]: { peaks: [[min,max],...] } }
 */

export function renderNowPlaying(state, peaksMap = {}) {
  if (!state || !state.now_playing) return '';

  const items = state.now_playing.map(np => {
    const deck = state.decks?.[np.deck];
    const stemData = deck?.stems?.[np.stem];
    const song = stemData?.song || '—';
    const artist = stemData?.artist || '';
    const key = stemData?.key || '';
    const progress = np.progress || 0;
    const barsLeft = stemData?.bars_left ?? 0;
    const color = _sourceColor(state, np.source);
    const clipId = stemData?.clip_id;
    const peaks = clipId ? peaksMap[clipId] : null;
    const waveHtml = peaks ? _renderWaveform(peaks, progress, color) : _renderEmptyWave(progress, color);

    return `<div class="stem" style="--c:${color || 'var(--muted)'}">
      <div class="top">
        <b>${np.stem.toUpperCase()}</b>
        <span>${song}</span>
        <span style="color:var(--muted)">${artist}</span>
        ${key ? `<span class="pin">${key}</span>` : ''}
        <span style="margin-left:auto;font-size:10px">${barsLeft.toFixed(0)} bars</span>
      </div>
      <div class="wave">${waveHtml}
        <div class="play" style="left:${progress}%"></div>
      </div>
    </div>`;
  });

  return `<div class="card">
    <p class="h">Now Playing</p>
    <div class="np">${items.join('')}</div>
  </div>`;
}

function _renderWaveform(peaksData, progress, color) {
  const peaks = peaksData.peaks || [];
  if (peaks.length === 0) return '';
  const bars = peaks.map(([lo, hi]) => {
    const h = Math.max(2, Math.round((hi - lo) * 30));
    return `<i style="height:${h}px;background:${color || 'var(--muted)'}"></i>`;
  });
  return `<div class="bars">${bars.join('')}</div>`;
}

function _renderEmptyWave(progress, color) {
  return `<div class="bars" style="opacity:0.3"><i style="height:15px;background:${color || 'var(--muted)'}"></i></div>`;
}

function _sourceColor(state, sourceId) {
  if (!sourceId || !state.presets) return null;
  for (const bank of [state.presets.bankA, state.presets.bankB]) {
    const p = (bank || []).find(x => x.id === sourceId);
    if (p?.color) return p.color;
  }
  return null;
}

export { _sourceColor, _renderWaveform };
