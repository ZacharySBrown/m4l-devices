/**
 * Mix-Next recommendations — congruent vs spicy cards.
 * Pure render: state → HTML string.
 */

export function renderRecommendations(state) {
  if (!state || !state.recommendations || state.recommendations.length === 0) {
    return '<div class="card"><p class="h">Mix Next</p><p style="color:var(--muted)">No recommendations</p></div>';
  }

  const cards = state.recommendations.map(r => {
    const color = r.type === 'spicy' ? 'var(--warn)' : 'var(--ok)';
    const pct = Math.min(100, Math.max(0, r.score));
    return `<div class="rec" style="--c:${color}">
      <span class="tag">${r.type}</span>
      <h4>${r.song || '—'}</h4>
      <div class="m"><span>${r.artist || ''}</span><span>${r.bpm || '—'} BPM</span><span>${r.key || ''}</span></div>
      <div class="sc">
        <div class="bar"><i style="width:${pct}%"></i></div>
        <span class="pct">${pct}</span>
      </div>
      ${r.action ? `<button class="action-btn" data-action="queue_set" data-set="${r.song}" style="margin-top:6px;font-size:10px;padding:4px 10px;border-radius:999px;border:1px solid ${color};background:none;color:${color};cursor:pointer">${r.action}</button>` : ''}
    </div>`;
  });

  return `<div class="card"><p class="h">Mix Next</p><div class="recs">${cards.join('')}</div></div>`;
}
