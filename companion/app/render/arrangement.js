/**
 * Arrangement view — dual-deck timeline with clip placements + scene markers.
 * Pure render: (container, state) → DOM.
 */

const STEMS = ['drums', 'bass', 'other', 'vox'];
const DECKS = ['A', 'B'];
const BAR_WIDTH = 12; // px per bar

export function renderArrangement(container, state) {
  if (!state || !state.arrangement) {
    container.innerHTML = '<div class="card"><p class="h">Arrangement</p><p style="color:var(--muted)">No arrangement data</p></div>';
    return;
  }

  const arr = state.arrangement;
  const totalBars = arr.length_bars || 64;
  const timelineWidth = totalBars * BAR_WIDTH;
  const playheadBar = arr.playhead_bar || 0;
  const playheadPx = playheadBar * BAR_WIDTH;

  // Bar ruler
  const barNums = [];
  for (let b = 0; b < totalBars; b += 4) {
    barNums.push(`<span class="bar-num" style="left:${b * BAR_WIDTH}px">${b + 1}</span>`);
  }

  // Scene markers
  const markers = (arr.scene_markers || []).map(m => {
    const left = (m.start_bar || 0) * BAR_WIDTH;
    return `<div class="scene-marker" style="left:${left}px;--c:${m.color || 'var(--muted)'}">
      <span class="marker-flag">${m.name || m.scene_id}</span>
    </div>`;
  });

  // Per-deck stem lanes
  const lanes = [];
  for (const deck of DECKS) {
    for (const stem of STEMS) {
      const blocks = (arr.placements || [])
        .filter(p => p.deck === deck && p.stem === stem)
        .map(p => {
          const left = (p.start_bar || 0) * BAR_WIDTH;
          const width = (p.len_bars || 1) * BAR_WIDTH;
          const color = p.color || 'var(--muted)';
          return `<div class="tl-block" style="left:${left}px;width:${width}px;--c:${color}" title="${p.source || ''} ${p.clip_id || ''}"></div>`;
        });

      lanes.push(`<div class="tl-lane">
        <span class="tl-label">${deck}·${stem.slice(0,2).toUpperCase()}</span>
        <div class="tl-track" style="width:${timelineWidth}px">${blocks.join('')}</div>
      </div>`);
    }
  }

  // Controls
  const controls = `<div class="arr-controls">
    <button class="arr-btn" data-action="place_pair" data-timeline_bar="${Math.floor(playheadBar)}">Place pair @ bar ${Math.floor(playheadBar) + 1}</button>
    <button class="arr-btn" data-action="save_arrangement" data-name="current">Save</button>
    <button class="arr-btn" data-action="load_arrangement" data-name="current">Load</button>
  </div>`;

  container.innerHTML = `
    <div class="card arrangement-view">
      <p class="h">Arrangement</p>
      ${controls}
      <div class="tl-container">
        <div class="tl-ruler" style="width:${timelineWidth}px">${barNums.join('')}</div>
        <div class="tl-markers" style="width:${timelineWidth}px">${markers.join('')}</div>
        <div class="tl-lanes">${lanes.join('')}</div>
        <div class="tl-playhead" style="left:${playheadPx}px"></div>
      </div>
    </div>
  `;
}
