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
    _renderCurrent(_state);   // re-render active view with fresh state (fixes blank initial load)
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
    // Lightweight DOM-only playhead updates (no full re-render, preserves clicks/hover)
    _updatePlayheads(interpolated);
  }
  _rafId = requestAnimationFrame(_frame);
}

function _updatePlayheads(state) {
  if (!state || !state.now_playing) return;
  const stems = document.querySelectorAll('.np .stem');
  state.now_playing.forEach((np, i) => {
    const stemEl = stems[i];
    if (!stemEl) return;
    const playhead = stemEl.querySelector('.play');
    if (playhead) playhead.style.left = `${np.progress || 0}%`;
    const barsEl = stemEl.querySelector('.bars-left-text');
    const deck = state.decks?.[np.deck];
    const stemData = deck?.stems?.[np.stem];
    if (barsEl && stemData) barsEl.textContent = `${(stemData.bars_left ?? 0).toFixed(0)} bars`;
  });
}

// ── Router ────────────────────────────────────────────────────────

let _currentView = 'perform';
const _views = {};

export function registerView(name, renderFn) {
  _views[name] = renderFn;
}

function _renderCurrent(state) {
  const el = document.getElementById('view');
  if (!el) return;
  const renderFn = _views[_currentView];
  if (renderFn) {
    renderFn(el, state);   // render fns set innerHTML themselves
  } else {
    el.innerHTML = `<div class="card"><p class="h">${_currentView} view</p><p style="color:var(--muted)">Coming soon</p></div>`;
  }
}

function _mount(viewName) {
  _currentView = viewName;
  _renderCurrent(_state);
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

  // Delegated action handler: clicks on [data-action] → POST /action
  document.addEventListener('click', async (e) => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const type = btn.dataset.action;
    const payload = { type };
    // Collect data-* attributes as action args
    if (btn.dataset.id) payload.id = btn.dataset.id;
    if (btn.dataset.deck) payload.deck = btn.dataset.deck;
    if (btn.dataset.stem) payload.stem = btn.dataset.stem;
    if (btn.dataset.chop !== undefined) payload.chop = parseInt(btn.dataset.chop, 10);
    if (btn.dataset.set) payload.set_name = btn.dataset.set;
    // tag_scene needs name + current clips (prompt or auto from now_playing)
    if (type === 'tag_scene' && _state) {
      const clips = (_state.now_playing || []).map(np => `${np.deck}·${np.stem.slice(0,2).toUpperCase()}${(np.progress > 0 ? '1' : '0')}`);
      payload.name = `Scene ${Date.now().toString(36).slice(-4)}`;
      payload.clips = clips;
    }
    try {
      const resp = await fetch('/action', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const result = await resp.json();
      if (!result.ok) console.warn('action failed:', result.error);
      // Refresh state after action
      _poll();
    } catch (err) {
      console.error('action error:', err);
    }
  });

  // Start polling
  _poll();
  _pollTimer = setInterval(_poll, 1000);

  // Start animation interpolation
  _rafId = requestAnimationFrame(_frame);

  // Mount default view
  _mount('perform');
}

// ── Register views ────────────────────────────────────────────────
import { renderPerform } from './render/perform.js';
import { renderCurate } from './render/curate.js';
import { renderArrangement } from './render/arrangement.js';
registerView('perform', renderPerform);
registerView('curate', renderCurate);
registerView('arrange', renderArrangement);

// Auto-init when DOM is ready
if (typeof document !== 'undefined') {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
}
