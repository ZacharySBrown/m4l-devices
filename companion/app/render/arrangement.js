/**
 * Arrange view — interactive setlist builder with drag-and-drop.
 *
 * Split-pane layout:
 *   Top: Sequential timeline (auto-fits width to viewport)
 *   Bottom: Persistent library dock (scrollable track cards)
 *
 * Drag whole songs from dock → insert at drop position in timeline.
 * Abstracted for v2 per-stem drag.
 */

const STEM_NAMES = ['drums', 'bass', 'other', 'vox'];
const STEM_LABELS = { drums: 'DR', bass: 'BA', other: 'OT', vox: 'VX' };
const LANE_H = 16;

// ── State ──
let _library = [];
let _timeline = [];  // ordered array of track objects on the timeline
let _mounted = false;
let _searchQuery = '';
let _searchResults = [];
let _dragItem = null;
let _dropIdx = -1;
let _el = null;

async function _fetchLibrary() {
  try {
    const r = await fetch('/library');
    const d = await r.json();
    _library = d.tracks || [];
  } catch (e) { console.warn('library:', e); }
}

async function _fetchTimeline() {
  try {
    const r = await fetch('/setlist-timeline');
    const d = await r.json();
    if (d.tracks && d.tracks.length) {
      _timeline = d.tracks.map(t => ({ ...t, _uid: t.track_id + '_' + Math.random().toString(36).slice(2, 6) }));
    }
  } catch (e) { console.warn('timeline:', e); }
}

async function _doSearch(q) {
  _searchQuery = q;
  if (!q || q.length < 2) { _searchResults = []; return; }
  try {
    const r = await fetch(`/search?q=${encodeURIComponent(q)}&limit=15`);
    const d = await r.json();
    _searchResults = d.results || [];
  } catch (e) { _searchResults = []; }
}

function _esc(s) {
  if (!s) return '';
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// ── Computed values ──
function _computeBarPositions() {
  let cum = 0;
  for (const t of _timeline) {
    t._start_bar = cum;
    cum += (t.bar_count || 64);
  }
  return cum;
}

// ── Render ──
function _render() {
  if (!_el) return;
  const totalBars = _computeBarPositions();

  // Auto-fit: compute BAR_WIDTH so timeline fills the available space
  const containerWidth = _el.clientWidth - 80; // subtract label width + padding
  const barWidth = _timeline.length > 0
    ? Math.max(1, Math.min(8, containerWidth / (totalBars || 1)))
    : 4;
  const totalWidth = totalBars * barWidth;

  // Track header band
  let headersHtml = '';
  _timeline.forEach((t, i) => {
    const x = t._start_bar * barWidth;
    const w = (t.bar_count || 64) * barWidth;
    headersHtml += `
      <div class="arr-track-header" data-timeline-idx="${i}"
           style="left:${x}px;width:${w}px;--c:${t.color}"
           draggable="true"
           title="${_esc(t.artist)} — ${_esc(t.title)} (${t.bpm ? t.bpm.toFixed(1) : '?'} BPM, ${_esc(t.camelot || '')})">
        <span class="arr-track-id">${_esc(t.preset_id)}</span>
        <span class="arr-track-name">${_esc(t.title)}</span>
        <span class="arr-track-meta">${t.bpm ? t.bpm.toFixed(0) : ''} ${_esc(t.camelot || '')}</span>
        <button class="arr-track-remove" data-remove-idx="${i}" title="Remove">&times;</button>
      </div>`;
  });

  // Drop zones between tracks
  let dropZonesHtml = '';
  for (let i = 0; i <= _timeline.length; i++) {
    const x = i < _timeline.length
      ? _timeline[i]._start_bar * barWidth
      : totalWidth;
    dropZonesHtml += `
      <div class="arr-drop-zone${_dropIdx === i ? ' active' : ''}"
           data-drop-idx="${i}"
           style="left:${x - 3}px"></div>`;
  }

  // Stem lanes
  let lanesHtml = '';
  for (const stem of STEM_NAMES) {
    let blocksHtml = '';
    for (const t of _timeline) {
      const x = t._start_bar * barWidth;
      const w = (t.bar_count || 64) * barWidth;
      blocksHtml += `<div class="tl-block" style="left:${x}px;width:${w}px;--c:${t.color}"></div>`;
    }
    lanesHtml += `
      <div class="tl-lane" style="height:${LANE_H}px">
        <span class="tl-label">${STEM_LABELS[stem]}</span>
        <div class="tl-track" style="width:${totalWidth}px">${blocksHtml}</div>
      </div>`;
  }

  // Summary
  const bpms = _timeline.map(t => t.bpm).filter(b => b > 0);
  const totalSec = _timeline.reduce((s, t) => s + ((t.bar_count || 64) * 240 / (t.bpm || 120)), 0);
  const summaryHtml = _timeline.length > 0
    ? `${_timeline.length} tracks · ${totalBars} bars · ~${Math.round(totalSec / 60)}min · ${bpms.length ? Math.min(...bpms).toFixed(0) + '–' + Math.max(...bpms).toFixed(0) : '?'} BPM`
    : 'Drop tracks from the library below to build your set';

  // Library dock — show processed tracks + search
  const dockSource = _searchQuery.length >= 2 ? _searchResults : _library;
  let dockCardsHtml = '';
  for (const t of dockSource) {
    const onTimeline = _timeline.some(tl => String(tl.track_id) === String(t.id));
    dockCardsHtml += `
      <div class="dock-card${onTimeline ? ' used' : ''}"
           draggable="${t.processed && !onTimeline ? 'true' : 'false'}"
           data-dock-id="${t.id}"
           title="${_esc(t.artist)} — ${_esc(t.title)}">
        <div class="dock-title">${_esc(t.title)}</div>
        <div class="dock-artist">${_esc(t.artist ? t.artist.split(',')[0].trim() : '')}</div>
        <div class="dock-meta">
          <span>${t.bpm ? t.bpm.toFixed(0) : '?'}</span>
          <span>${_esc(t.key || '')}</span>
        </div>
        ${!t.processed ? '<div class="dock-badge">not forged</div>' : ''}
        ${onTimeline ? '<div class="dock-badge used">in set</div>' : ''}
      </div>`;
  }

  _el.innerHTML = `
    <div class="arrange-split">
      <div class="arrange-top">
        <div class="arrange-toolbar">
          <span class="h" style="margin:0">ARRANGE</span>
          <span class="arrange-summary">${summaryHtml}</span>
          <div style="margin-left:auto;display:flex;gap:6px">
            <button class="arr-btn" id="arr-assemble" ${_timeline.length === 0 ? 'disabled' : ''}
              style="border-color:var(--ok);color:var(--ok)">Assemble Set</button>
            <button class="arr-btn" id="arr-clear">Clear</button>
          </div>
        </div>
        <div class="arrange-timeline" id="arrange-timeline">
          ${_timeline.length === 0
            ? '<div class="arrange-empty">Drag songs from the library dock below</div>'
            : `
              <div class="tl-container">
                <div class="arr-headers" style="position:relative;width:${totalWidth}px;height:30px">
                  ${headersHtml}
                  ${dropZonesHtml}
                </div>
                <div class="tl-lanes">${lanesHtml}</div>
              </div>
            `}
        </div>
      </div>
      <div class="arrange-dock">
        <div class="dock-toolbar">
          <span class="h" style="margin:0">LIBRARY</span>
          <input type="text" id="dock-search" placeholder="Search..."
            value="${_esc(_searchQuery)}"
            class="dock-search-input">
          <span class="dock-count">${dockSource.length} tracks</span>
        </div>
        <div class="dock-cards" id="dock-cards">
          ${dockCardsHtml || '<div style="color:var(--muted);padding:20px;text-align:center">No processed tracks yet</div>'}
        </div>
      </div>
    </div>
  `;

  _wireEvents();
}

// ── Events (delegated on _el — survives re-renders) ──
let _eventsWired = false;

function _wireEvents() {
  if (_eventsWired) return;
  _eventsWired = true;

  // Search (delegated)
  _el.addEventListener('input', (e) => {
    if (e.target.id !== 'dock-search') return;
    clearTimeout(_searchDebounce);
    _searchDebounce = setTimeout(async () => {
      const val = e.target.value;
      await _doSearch(val);
      const cursor = e.target.selectionStart;
      _render();
      const inp = _el.querySelector('#dock-search');
      if (inp) { inp.focus(); inp.setSelectionRange(cursor, cursor); }
    }, 250);
  });
  let _searchDebounce = null;

  // Click handler (delegated)
  _el.addEventListener('click', async (e) => {
    // Remove track
    const removeBtn = e.target.closest('.arr-track-remove');
    if (removeBtn) {
      e.stopPropagation();
      const idx = parseInt(removeBtn.dataset.removeIdx, 10);
      _timeline.splice(idx, 1);
      _recomputePresetIds();
      _render();
      return;
    }
    // Clear
    if (e.target.id === 'arr-clear') {
      _timeline = [];
      _render();
      return;
    }
    // Assemble
    if (e.target.id === 'arr-assemble') {
      const name = prompt('Set name:', 'my_set');
      if (!name) return;
      const ids = _timeline.map(t => parseInt(t.track_id, 10));
      try {
        const r = await fetch('/assemble-set', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name, track_ids: ids }),
        });
        const result = await r.json();
        if (result.ok) alert(`Set assembled!\n${result.set_path}`);
        else alert(`Error: ${result.error}`);
      } catch (err) { alert('Assemble failed: ' + err); }
      return;
    }
  });

  // Drag start (delegated)
  _el.addEventListener('dragstart', (e) => {
    // Dock card
    const card = e.target.closest('.dock-card[draggable="true"]');
    if (card) {
      const id = card.dataset.dockId;
      const track = _library.find(t => String(t.id) === id) ||
                    _searchResults.find(t => String(t.id) === id);
      if (!track) return;
      _dragItem = { source: 'dock', track };
      e.dataTransfer.setData('text/plain', id);
      e.dataTransfer.effectAllowed = 'copyMove';
      requestAnimationFrame(() => card.classList.add('dragging'));
      return;
    }
    // Timeline header (reorder)
    const header = e.target.closest('.arr-track-header[draggable="true"]');
    if (header) {
      const idx = parseInt(header.dataset.timelineIdx, 10);
      _dragItem = { source: 'timeline', idx, track: _timeline[idx] };
      e.dataTransfer.setData('text/plain', 'reorder');
      e.dataTransfer.effectAllowed = 'move';
      requestAnimationFrame(() => header.classList.add('dragging'));
    }
  });

  // Drag end (delegated)
  _el.addEventListener('dragend', () => {
    _dragItem = null;
    _dropIdx = -1;
    _el.querySelectorAll('.dragging').forEach(el => el.classList.remove('dragging'));
    _el.querySelectorAll('.arr-drop-zone.active').forEach(z => z.classList.remove('active'));
    const empty = _el.querySelector('.arrange-empty');
    if (empty) empty.classList.remove('drag-hover');
  });

  // Drag over timeline (delegated)
  _el.addEventListener('dragover', (e) => {
    const timeline = e.target.closest('#arrange-timeline');
    if (!timeline) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = _dragItem?.source === 'timeline' ? 'move' : 'copy';

    // Highlight empty area
    const empty = _el.querySelector('.arrange-empty');
    if (empty) { empty.classList.add('drag-hover'); return; }

    // Find nearest drop zone
    const headers = _el.querySelectorAll('.arr-track-header');
    let bestIdx = _timeline.length;
    let bestDist = Infinity;
    headers.forEach((h, i) => {
      const rect = h.getBoundingClientRect();
      const mid = rect.left + rect.width / 2;
      const dist = Math.abs(e.clientX - mid);
      if (e.clientX < mid && dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
      }
    });
    // Check if past the last header
    if (headers.length > 0) {
      const lastRect = headers[headers.length - 1].getBoundingClientRect();
      if (e.clientX > lastRect.right) bestIdx = _timeline.length;
    }

    if (bestIdx !== _dropIdx) {
      _dropIdx = bestIdx;
      _el.querySelectorAll('.arr-drop-zone').forEach(z =>
        z.classList.toggle('active', parseInt(z.dataset.dropIdx) === bestIdx));
    }
  });

  // Drop (delegated)
  _el.addEventListener('drop', (e) => {
    const timeline = e.target.closest('#arrange-timeline');
    if (!timeline) return;
    e.preventDefault();
    if (!_dragItem) return;

    const empty = _el.querySelector('.arrange-empty');
    if (empty) empty.classList.remove('drag-hover');

    function _makeTrack(t) {
      return {
        track_id: String(t.id || t.track_id),
        title: t.title, artist: t.artist,
        preset_id: '', color: '',
        bpm: t.bpm || 0, camelot: t.key || t.camelot || '',
        start_bar: 0,
        bar_count: t.bar_count || (t.chops ? Math.max(64, t.chops * 4) : 128),
        stems: t.stems || {},
        _uid: (t.id || t.track_id) + '_' + Math.random().toString(36).slice(2, 6),
      };
    }

    if (_dragItem.source === 'dock') {
      const idx = _dropIdx >= 0 ? Math.min(_dropIdx, _timeline.length) : _timeline.length;
      _timeline.splice(idx, 0, _makeTrack(_dragItem.track));
      _recomputePresetIds();
    } else if (_dragItem.source === 'timeline') {
      const fromIdx = _dragItem.idx;
      let toIdx = _dropIdx >= 0 ? _dropIdx : _timeline.length;
      if (toIdx > fromIdx) toIdx--;
      if (fromIdx !== toIdx && toIdx >= 0) {
        const [item] = _timeline.splice(fromIdx, 1);
        _timeline.splice(toIdx, 0, item);
        _recomputePresetIds();
      }
    }

    _dragItem = null;
    _dropIdx = -1;
    _render();
  });
}

const PALETTE = [
  '#F5A623', '#FF7A3D', '#E85B5B', '#B058CF',
  '#8C7BFF', '#34C8E8', '#3DCC91', '#8BC34A',
];

function _recomputePresetIds() {
  _timeline.forEach((t, i) => {
    t.preset_id = i < 8 ? `A${i + 1}` : `B${i - 7}`;
    t.color = PALETTE[i % PALETTE.length];
  });
}

// ── Export ──
export async function renderArrangement(el, state) {
  _el = el;
  if (!_mounted) {
    _mounted = true;
    await Promise.all([_fetchLibrary(), _fetchTimeline()]);
    _wireEvents();
    _render();
    return;
  }
  // Don't re-render on state polls — we manage our own state via drag/drop
  if (!el.querySelector('.arrange-split')) {
    _wireEvents();
    _render();
  }
}
