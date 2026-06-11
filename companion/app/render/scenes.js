/**
 * Scene board — tag/recall/untag vetted clip pairings.
 * Pure render: (state, actionFn) → HTML string.
 * actionFn: (type, data) → void (fires POST /action).
 */

export function renderScenes(state, actionFn) {
  if (!state) return '';
  const scenes = state.scenes || [];

  const cards = scenes.map(s => {
    const clipChips = (s.clips || []).map(c =>
      `<span class="clip-chip">${c}</span>`
    ).join('');

    return `<div class="scene-card" style="--c:${s.color || 'var(--muted)'}" data-scene-id="${s.id || ''}">
      <div class="scene-top">
        <span class="sw" style="background:${s.color || 'var(--muted)'}"></span>
        <b>${s.name || '—'}</b>
        <button class="scene-btn recall" data-action="recall_scene" data-id="${s.id}">Recall</button>
        <button class="scene-btn untag" data-action="untag_scene" data-id="${s.id}">×</button>
      </div>
      <div class="clip-chips">${clipChips}</div>
    </div>`;
  });

  const tagBtn = `<button class="scene-btn tag" data-action="tag_scene">+ Tag Scene</button>`;

  return `<div class="card">
    <p class="h">Scenes</p>
    <div class="scene-list">${cards.join('')}</div>
    ${tagBtn}
  </div>`;
}

export function getSceneClipIds(scene) {
  return (scene?.clips || []).slice();
}
