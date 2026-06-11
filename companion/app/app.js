/**
 * Setforge Companion — data layer + routing
 *
 * Pure-render architecture: poll /state → store → views subscribe.
 * Progress interpolation between polls via requestAnimationFrame.
 * Vanilla ES modules, no framework.
 */

// ── Store ─────────────────────────────────────────────────────────

let _state = null;
let _lastPollMs = 0;
const _subscribers = [];

export function getState() { return _state; }

export function subscribe(fn) {
  _subscribers.push(fn);
  return () => { const i = _subscribers.indexOf(fn); if (i >= 0) _subscribers.splice(i, 1); };
}

function _notify() {
  for (const fn of _subscribers) {
    try { fn(_state); } catch (e) { console.error('subscriber error', e); }
  }
}

// ── Progress interpolation ────────────────────────────────────────
// Between polls, advance each live clip's progress from BPM + bars_left.
// Snap to server value on each poll.

export function interpolateProgress(state, elapsedMs) {
  if (!state || !state.set || !state.set.bpm || state.set.bpm <= 0) return state;
  if (!state.decks) return state;

  const bpm = state.set.bpm;
  const beatsPerMs = bpm / 60000;
  const barsElapsed = (beatsPerMs * elapsedMs) / 4; // 4 beats per bar

  const result = JSON.parse(JSON.stringify(state)); // deep clone

  for (const deckKey of ['A', 'B']) {
    const deck = result.decks[deckKey];
    if (!deck || !deck.stems) continue;
    for (const stemName of Object.keys(deck.stems)) {
      const stem = deck.stems[stemName];
      if (stem.live_chop === null || stem.live_chop === undefined) continue;
      if (stem.bars_left <= 0) continue;

      // Advance progress proportionally
      const totalBars = stem.bars_left / (1 - stem.progress / 100);
      if (totalBars <= 0) continue;
      const pctPerBar = 100 / totalBars;
      stem.progress = Math.min(100, stem.progress + barsElapsed * pctPerBar);
      stem.bars_left = Math.max(0, stem.bars_left - barsElapsed);
    }
  }
  return result;
}

// ── Polling ───────────────────────────────────────────────────────

let _pollTimer = null;
let _reconnecting = false;

async function _poll() {
  try {
    const resp = await fetch('/state');
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    _state = await resp.json();
    _lastPollMs = performance.now();
    if (_reconnecting) {
      _reconnecting = false;
      const el = document.getElementById('reconnect');
      if (el) el.classList.remove('show');
    }
    _updateTransport();
    _notify();
  } catch (e) {
    if (!_reconnecting) {
      _reconnecting = true;
      const el = document.getElementById('reconnect');
      if (el) el.classList.add('show');
    }
  }
}

function _updateTransport() {
  if (!_state || !_state.set) return;
  const bpmEl = document.getElementById('bpm');
  const barEl = document.getElementById('bar');
  const dotEl = document.querySelector('#transport .dot');
  if (bpmEl) bpmEl.textContent = _state.set.bpm.toFixed(1);
  if (barEl) barEl.textContent = _state.set.bar || '';
  if (dotEl) dotEl.style.background = _state.set.is_playing ? 'var(--ok)' : 'var(--muted)';
}

// ── Animation frame interpolation ─────────────────────────────────

let _rafId = null;

function _frame() {
  if (_state) {
    const elapsed = performance.now() - _lastPollMs;
    const interpolated = interpolateProgress(_state, elapsed);
    // Views can read interpolated state; we don't overwrite _state
    // to avoid drift accumulation — snap on next poll.
    for (const fn of _subscribers) {
      try { fn(interpolated); } catch (e) { /* skip */ }
    }
  }
  _rafId = requestAnimationFrame(_frame);
}

// ── Router ────────────────────────────────────────────────────────

let _currentView = 'perform';
const _views = {};

export function registerView(name, renderFn) {
  _views[name] = renderFn;
}

function _mount(viewName) {
  _currentView = viewName;
  const el = document.getElementById('view');
  if (!el) return;
  const renderFn = _views[viewName];
  if (renderFn) {
    el.innerHTML = '';
    renderFn(el, _state);
  } else {
    el.innerHTML = `<div class="card"><p class="h">${viewName} view</p><p style="color:var(--muted)">Coming soon</p></div>`;
  }
  // Update tab active state
  document.querySelectorAll('.tab').forEach(t => {
    t.classList.toggle('active', t.dataset.view === viewName);
  });
}

// ── Init ──────────────────────────────────────────────────────────

function init() {
  // Tab routing
  const tabsEl = document.getElementById('tabs');
  if (tabsEl) {
    tabsEl.addEventListener('click', (e) => {
      const tab = e.target.closest('.tab');
      if (tab && tab.dataset.view) _mount(tab.dataset.view);
    });
  }

  // Start polling
  _poll();
  _pollTimer = setInterval(_poll, 1000);

  // Start animation interpolation
  _rafId = requestAnimationFrame(_frame);

  // Mount default view
  _mount('perform');
}

// Auto-init when DOM is ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
}
