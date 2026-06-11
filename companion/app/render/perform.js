/**
 * Perform view — composes surface mirror + now-playing + legend + recommendations.
 * Registered as a view in the app shell, re-renders on state update.
 */

import { renderSurfaceMirror } from './surface-mirror.js';
import { renderNowPlaying } from './now-playing.js';
import { renderLegend } from './legend.js';
import { renderRecommendations } from './recommendations.js';

const _peaksCache = {};

export function renderPerform(container, state) {
  if (!state) {
    container.innerHTML = '<p style="color:var(--muted)">Waiting for state...</p>';
    return;
  }

  const nowPlaying = renderNowPlaying(state, _peaksCache);
  const surface = renderSurfaceMirror(state);
  const legend = renderLegend(state);
  const recs = renderRecommendations(state);

  // Queue section
  const queue = `<div class="queue card">
    <p class="h">Queue</p>
    <p style="color:var(--muted);font-size:12px">Next set cued here</p>
  </div>`;

  container.innerHTML = `
    <div class="grid">
      <div class="col-left">${nowPlaying}</div>
      <div class="col-center">${surface}</div>
      <div class="col-right">${legend}</div>
    </div>
    <div class="strip">${recs}${queue}</div>
  `;

  // Fetch peaks for any clip_ids we haven't cached yet
  _fetchMissingPeaks(state);
}

async function _fetchMissingPeaks(state) {
  if (!state.now_playing) return;
  for (const np of state.now_playing) {
    const deck = state.decks?.[np.deck];
    const stemData = deck?.stems?.[np.stem];
    const clipId = stemData?.clip_id;
    if (!clipId || _peaksCache[clipId]) continue;
    _peaksCache[clipId] = { peaks: [] }; // placeholder to avoid refetch
    try {
      const resp = await fetch(`/peaks?clip=${encodeURIComponent(clipId)}`);
      if (resp.ok) _peaksCache[clipId] = await resp.json();
    } catch (e) { /* non-blocking */ }
  }
}
