/**
 * Library view — search, browse, forge, and assemble sets.
 *
 * Three panels:
 *   1. Search (top) — search taste DB, trigger forge-track
 *   2. Processed tracks (left) — ready-to-use library
 *   3. Set builder (right) — drag tracks in, assemble
 */

let _library = [];
let _searchResults = [];
let _searchQuery = '';
let _forgeStatus = null;
let _builderTracks = [];
let _sets = [];
let _setName = 'new_set';
let _mounted = false;

async function _fetchLibrary() {
  try {
    const r = await fetch('/library');
    const d = await r.json();
    _library = d.tracks || [];
  } catch (e) { console.warn('library fetch:', e); }
}

async function _fetchSets() {
  try {
    const r = await fetch('/sets');
    const d = await r.json();
    _sets = d.sets || [];
  } catch (e) { console.warn('sets fetch:', e); }
}

async function _doSearch(q) {
  _searchQuery = q;
  if (!q || q.length < 2) { _searchResults = []; return; }
  try {
    const r = await fetch(`/search?q=${encodeURIComponent(q)}&limit=20`);
    const d = await r.json();
    _searchResults = d.results || [];
  } catch (e) { console.warn('search:', e); }
}

async function _pollForgeStatus() {
  try {
    const r = await fetch('/forge-status');
    _forgeStatus = await r.json();
  } catch (e) { _forgeStatus = null; }
}

async function _forgeTrack(trackId) {
  try {
    await fetch('/forge-track', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ track_id: trackId }),
    });
    // Start polling forge status
    const poll = setInterval(async () => {
      await _pollForgeStatus();
      _rerender();
      if (_forgeStatus && !_forgeStatus.running) {
        clearInterval(poll);
        await _fetchLibrary();
        _rerender();
      }
    }, 2000);
  } catch (e) { console.warn('forge:', e); }
}

async function _assembleSet() {
  if (!_builderTracks.length || !_setName) return;
  try {
    const r = await fetch('/assemble-set', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: _setName, track_ids: _builderTracks.map(t => t.id) }),
    });
    const result = await r.json();
    if (result.ok) {
      await _fetchSets();
      _rerender();
    }
  } catch (e) { console.warn('assemble:', e); }
}

let _rerenderEl = null;
function _rerender() {
  if (_rerenderEl) _render(_rerenderEl);
}

function _render(el) {
  _rerenderEl = el;

  const forgeRunning = _forgeStatus && _forgeStatus.running;
  const forgeLog = _forgeStatus ? (_forgeStatus.log || []).slice(-3).join('\n') : '';

  el.innerHTML = `
    <div class="library-layout">
      <!-- Search -->
      <div class="card" style="margin-bottom:14px">
        <p class="h">Search Library</p>
        <div style="display:flex;gap:8px">
          <input type="text" id="lib-search" placeholder="Search by artist or title..."
            value="${_searchQuery}"
            style="flex:1;padding:8px 12px;background:var(--bg0);border:1px solid var(--line);
              border-radius:8px;color:var(--txt);font-size:13px;outline:none">
        </div>
        ${_searchResults.length ? `
          <div class="search-results" style="margin-top:10px;max-height:240px;overflow-y:auto">
            ${_searchResults.map(t => `
              <div class="search-row" style="display:flex;align-items:center;gap:8px;padding:6px 4px;
                border-bottom:1px solid var(--line)">
                <div style="flex:1;min-width:0">
                  <b style="font-size:12px">${_esc(t.artist)}</b>
                  <span style="color:var(--muted);font-size:12px"> — ${_esc(t.title)}</span>
                </div>
                <span style="font-size:10px;color:var(--muted)">${t.key || ''}</span>
                <span style="font-size:10px;color:var(--muted)">${t.bpm ? t.bpm.toFixed(0) + ' BPM' : ''}</span>
                ${t.processed
                  ? `<button class="lib-add-btn arr-btn" data-tid="${t.id}" style="border-color:var(--ok);color:var(--ok);font-size:10px;padding:3px 8px">+ Add</button>`
                  : t.has_audio
                    ? `<button class="lib-forge-btn arr-btn" data-tid="${t.id}" style="border-color:var(--A);color:var(--A);font-size:10px;padding:3px 8px"${forgeRunning ? ' disabled' : ''}>Forge</button>`
                    : `<span style="font-size:10px;color:var(--muted)">no audio</span>`
                }
              </div>
            `).join('')}
          </div>
        ` : _searchQuery.length >= 2 ? '<p style="color:var(--muted);font-size:12px;margin-top:8px">No results</p>' : ''}
      </div>

      ${forgeRunning ? `
        <div class="card" style="margin-bottom:14px;border-color:var(--A)">
          <p class="h" style="color:var(--A)">Forging Track ${_forgeStatus.track_id || ''}...</p>
          <pre style="font-size:10px;color:var(--muted);white-space:pre-wrap;margin:0">${_esc(forgeLog)}</pre>
        </div>
      ` : ''}

      <div class="lib-columns" style="display:grid;grid-template-columns:1fr 1fr;gap:14px;align-items:start">
        <!-- Processed Library -->
        <div class="card">
          <p class="h">Processed Tracks (${_library.length})</p>
          <div style="max-height:400px;overflow-y:auto">
            ${_library.length ? _library.map(t => `
              <div class="lib-row" style="display:flex;align-items:center;gap:8px;padding:5px 4px;
                border-bottom:1px solid rgba(255,255,255,.04)">
                <div style="flex:1;min-width:0">
                  <b style="font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;display:block">${_esc(t.artist)} — ${_esc(t.title)}</b>
                  <span style="font-size:10px;color:var(--muted)">${t.key || ''} · ${t.bpm ? t.bpm.toFixed(0) : '?'} BPM · ${t.chops} chops · ${t.strategy}</span>
                </div>
                <button class="lib-add-btn arr-btn" data-tid="${t.id}" style="font-size:10px;padding:3px 8px">+ Add</button>
              </div>
            `).join('') : '<p style="color:var(--muted);font-size:12px">No processed tracks yet. Search and forge some!</p>'}
          </div>
        </div>

        <!-- Set Builder -->
        <div class="card">
          <p class="h">Set Builder</p>
          <div style="display:flex;gap:8px;margin-bottom:12px;align-items:center">
            <input type="text" id="set-name" placeholder="Set name" value="${_esc(_setName)}"
              style="flex:1;padding:6px 10px;background:var(--bg0);border:1px solid var(--line);
                border-radius:8px;color:var(--txt);font-size:12px;outline:none">
            <button id="assemble-btn" class="arr-btn" style="border-color:var(--ok);color:var(--ok)"
              ${_builderTracks.length === 0 ? 'disabled' : ''}>
              Assemble (${_builderTracks.length})
            </button>
          </div>
          <div id="builder-list" style="min-height:120px">
            ${_builderTracks.length ? _builderTracks.map((t, i) => `
              <div class="builder-row" style="display:flex;align-items:center;gap:8px;padding:5px 4px;
                border-bottom:1px solid rgba(255,255,255,.04)">
                <span style="font-size:11px;color:var(--muted);min-width:20px">${i < 8 ? 'A' : 'B'}${(i % 8) + 1}</span>
                <div style="flex:1;min-width:0">
                  <b style="font-size:12px">${_esc(t.artist)} — ${_esc(t.title)}</b>
                </div>
                <span style="font-size:10px;color:var(--muted)">${t.bpm ? t.bpm.toFixed(0) : '?'} BPM</span>
                <button class="lib-remove-btn arr-btn" data-idx="${i}" style="font-size:10px;padding:2px 7px;border-color:var(--warn);color:var(--warn)">✕</button>
              </div>
            `).join('') : '<p style="color:var(--muted);font-size:12px;text-align:center;padding:30px 0">Add tracks from the library or search results</p>'}
          </div>

          ${_sets.length ? `
            <div style="margin-top:14px;border-top:1px solid var(--line);padding-top:10px">
              <p class="h">Assembled Sets</p>
              ${_sets.map(s => `
                <div style="display:flex;align-items:center;gap:8px;padding:4px 0">
                  <b style="font-size:12px">${_esc(s.name)}</b>
                  <span style="font-size:10px;color:var(--muted)">${s.tracks} tracks · ${s.tempo} BPM</span>
                </div>
              `).join('')}
            </div>
          ` : ''}
        </div>
      </div>
    </div>
  `;

  // Wire up events
  const searchInput = el.querySelector('#lib-search');
  if (searchInput && !searchInput._wired) {
    searchInput._wired = true;
    let debounce = null;
    searchInput.addEventListener('input', (e) => {
      clearTimeout(debounce);
      debounce = setTimeout(async () => {
        await _doSearch(e.target.value);
        _rerender();
      }, 300);
    });
  }

  const setNameInput = el.querySelector('#set-name');
  if (setNameInput) {
    setNameInput.addEventListener('input', (e) => { _setName = e.target.value; });
  }

  const assembleBtn = el.querySelector('#assemble-btn');
  if (assembleBtn) {
    assembleBtn.addEventListener('click', _assembleSet);
  }

  // Add-to-builder buttons
  el.querySelectorAll('.lib-add-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tid = parseInt(btn.dataset.tid, 10);
      if (_builderTracks.find(t => t.id === tid)) return; // already added
      // Find track info from library or search results
      const track = _library.find(t => t.id === tid) ||
                    _searchResults.find(t => t.id === tid);
      if (track && _builderTracks.length < 16) {
        _builderTracks.push({ ...track });
        _rerender();
      }
    });
  });

  // Remove from builder
  el.querySelectorAll('.lib-remove-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const idx = parseInt(btn.dataset.idx, 10);
      _builderTracks.splice(idx, 1);
      _rerender();
    });
  });

  // Forge buttons
  el.querySelectorAll('.lib-forge-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tid = parseInt(btn.dataset.tid, 10);
      _forgeTrack(tid);
      _rerender();
    });
  });
}

function _esc(s) {
  if (!s) return '';
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

export async function renderLibrary(el, state) {
  if (!_mounted) {
    _mounted = true;
    await Promise.all([_fetchLibrary(), _fetchSets()]);
    _render(el);
    return;
  }
  // Don't re-render on state polls — library has its own data sources.
  // Only render on first mount or explicit _rerender() calls.
  if (!_rerenderEl) _render(el);
}
