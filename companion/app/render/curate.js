/**
 * Curate view — chop-level clip pairing across two songs.
 *
 * Two-panel layout: pick Song A and Song B from presets,
 * see their chops per stem, select specific bar segments to mix.
 */

const STEMS = ['drums', 'bass', 'other', 'vox'];
const STEM_COLORS = { drums: '#F5A623', bass: '#34C8E8', other: '#3DCC91', vox: '#B058CF' };

let _songA = null;  // { track_id, title, artist, ... }
let _songB = null;
let _chopsA = null; // full chop data from /track-chops
let _chopsB = null;
let _activeChops = {}; // { "drums": {song: "A", idx: 2}, "bass": {song: "B", idx: 0}, ... }
let _mounted = false;
let _el = null;
let _eventsWired = false;

async function _fetchChops(trackId) {
  try {
    const r = await fetch(`/track-chops?id=${trackId}`);
    return await r.json();
  } catch (e) { return null; }
}

function _esc(s) {
  if (!s) return '';
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function _getPresets(state) {
  if (!state || !state.presets) return [];
  const all = [...(state.presets.bankA || []), ...(state.presets.bankB || [])];
  return all.filter(p => p.song);
}

function _render(state) {
  if (!_el) return;
  const presets = _getPresets(state);

  // Song selectors
  function selectorHtml(label, selected, side) {
    const opts = presets.map(p =>
      `<option value="${p.id}" ${selected && selected.preset_id === p.id ? 'selected' : ''}>${_esc(p.id)}: ${_esc(p.song)}</option>`
    ).join('');
    return `<select class="curate-select" data-side="${side}">
      <option value="">— pick ${label} —</option>${opts}</select>`;
  }

  // Chop panels
  function chopPanelHtml(side, chops, song) {
    if (!chops || !song) {
      return `<div class="curate-empty">Pick a song ${side === 'A' ? 'above' : 'above'}</div>`;
    }
    let html = `
      <div class="curate-song-header" style="--c:${song.color || 'var(--muted)'}">
        <b>${_esc(song.title)}</b>
        <span>${_esc(song.artist ? song.artist.split(',')[0].trim() : '')}</span>
        <span class="curate-song-meta">${chops.bpm ? chops.bpm.toFixed(0) + ' BPM' : ''} · ${_esc(chops.key || '')}</span>
      </div>`;

    for (const stem of STEMS) {
      const stemChops = chops.stems?.[stem] || [];
      const color = STEM_COLORS[stem];
      const active = _activeChops[stem];
      const isActiveSide = active && active.song === side;

      html += `<div class="curate-stem-row">
        <span class="curate-stem-label" style="color:${color}">${stem.slice(0, 2).toUpperCase()}</span>
        <div class="curate-chop-grid">`;

      for (const chop of stemChops) {
        const isActive = isActiveSide && active.idx === chop.idx;
        const cls = isActive ? 'curate-chop active' : 'curate-chop';
        html += `<div class="${cls}" style="--c:${color}"
          data-select-chop data-side="${side}" data-stem="${stem}" data-idx="${chop.idx}"
          title="${_esc(chop.label)} (${chop.bars} bars)">
          <span class="chop-label">${_esc(chop.label)}</span>
          <span class="chop-bars">${chop.bars}b</span>
        </div>`;
      }

      html += `</div></div>`;
    }
    return html;
  }

  // Mix summary
  let mixParts = [];
  for (const stem of STEMS) {
    const a = _activeChops[stem];
    if (a) {
      const chops = a.song === 'A' ? _chopsA : _chopsB;
      const song = a.song === 'A' ? _songA : _songB;
      const stemChops = chops?.stems?.[stem] || [];
      const chop = stemChops[a.idx];
      if (chop && song) {
        mixParts.push(`<span class="mix-part" style="--c:${STEM_COLORS[stem]}">
          ${stem.slice(0, 2).toUpperCase()}: ${_esc(song.song || song.title)} · ${_esc(chop.label)}
        </span>`);
      }
    }
  }

  _el.innerHTML = `
    <div class="curate-layout">
      <div class="curate-panels">
        <div class="curate-panel card">
          <div class="curate-panel-header">
            <span class="h" style="margin:0">SONG A</span>
            ${selectorHtml('Song A', _songA, 'A')}
          </div>
          ${chopPanelHtml('A', _chopsA, _songA)}
        </div>
        <div class="curate-panel card">
          <div class="curate-panel-header">
            <span class="h" style="margin:0">SONG B</span>
            ${selectorHtml('Song B', _songB, 'B')}
          </div>
          ${chopPanelHtml('B', _chopsB, _songB)}
        </div>
      </div>
      ${mixParts.length > 0 ? `
        <div class="curate-mix card">
          <span class="h" style="margin:0">MIX</span>
          <div class="mix-parts">${mixParts.join('')}</div>
        </div>
      ` : ''}
    </div>
  `;
}

function _wireEvents(state) {
  if (_eventsWired) return;
  _eventsWired = true;

  _el.addEventListener('change', async (e) => {
    const sel = e.target.closest('.curate-select');
    if (!sel) return;
    const side = sel.dataset.side;
    const presetId = sel.value;
    const presets = _getPresets(state);
    const preset = presets.find(p => p.id === presetId);

    if (!preset) {
      if (side === 'A') { _songA = null; _chopsA = null; }
      else { _songB = null; _chopsB = null; }
      _render(state);
      return;
    }

    // Find track_id from setlist
    const setlist = [...(state.presets?.bankA || []), ...(state.presets?.bankB || [])];
    const idx = setlist.findIndex(p => p.id === presetId);
    // We need track_id — get it from the setlist-timeline
    try {
      const r = await fetch('/setlist-timeline');
      const tl = await r.json();
      const track = tl.tracks?.[idx];
      if (track) {
        const chops = await _fetchChops(track.track_id);
        if (side === 'A') {
          _songA = { ...preset, preset_id: presetId, track_id: track.track_id };
          _chopsA = chops;
        } else {
          _songB = { ...preset, preset_id: presetId, track_id: track.track_id };
          _chopsB = chops;
        }
      }
    } catch (err) { console.warn('curate select:', err); }
    _render(state);
  });

  _el.addEventListener('click', (e) => {
    const chopEl = e.target.closest('[data-select-chop]');
    if (!chopEl) return;
    const side = chopEl.dataset.side;
    const stem = chopEl.dataset.stem;
    const idx = parseInt(chopEl.dataset.idx, 10);

    // Toggle: if already active, deactivate
    const current = _activeChops[stem];
    if (current && current.song === side && current.idx === idx) {
      delete _activeChops[stem];
    } else {
      _activeChops[stem] = { song: side, idx };
    }
    _render(state);
  });
}

export function renderCurate(container, state) {
  _el = container;
  if (!_mounted) {
    _mounted = true;
    _wireEvents(state);
  }
  _render(state);
}
