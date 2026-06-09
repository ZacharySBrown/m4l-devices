# SetForge Live — Handoff: multi-song docs, bug fix, and narrated deck

**Date:** 2026-06-08
**Branch:** `fix/setforge-live-curation-persistence`
**Scope:** Three connected pieces of work — (1) a full multi-song documentation
suite generated from the deployed code, (2) a real bug found during that audit
and fixed with regression coverage, and (3) a narrated academic slide deck of the
tutorial, produced with the `narrated-toolkit` (sibling repo).

This document is the single source of truth for what changed, why, and what's
left open.

---

## Part 1 — Multi-song documentation suite

Generated per `docs-spec.md` (untracked, repo root) as a **documentation-only**
task: code is the source of truth, no behavior changes. Built with a multi-agent
pass — 6 parallel readers over the deployed `src/loader/loader-controller.js`
monolith (3,867 lines) → one synthesized behavior catalog → 5 parallel artifact
writers. Every claim is tied to `loader-controller.js:<line>`.

**Artifacts** (in `device/setforge-live/docs/`):

| File | What it is |
|---|---|
| `multi-song-reference.md` | Precise behavior catalog: pad layout, side buttons, 3-variable state model, transitions, row-7 modifier table, SysEx, edge cases, test map |
| `implementation-drift-notes.md` | 28 code-vs-spec drift items + 14 open questions |
| `multi-song-tutorial.md` | Step-by-step performance tutorial (source for the narrated deck) |
| `pad-reference-card.md` / `.svg` / `.pdf` | Printable US-Letter landscape card (PDF is print-ready) |
| `diagrams/{view-transitions,staging-flow,mode-state-shape}.svg` | Three supporting diagrams |

**Key findings (code as truth):**

- **Deployment truth.** The shipped device runs `loader.js` = concat of
  `launchpad-surface-mk2/mk3/.js` + `loader-controller.js`. The modular
  `src/loader/{chop-router,fx-bus,modifier-layer,preset-banks,scene-memory}.js`
  and `src/shared/*` are **reference-only, NOT deployed** — yet most JS tests
  import those modular files, so passing them does not validate the monolith.
  Only `tests/integration/loader-e2e.test.js` exercises the built `loader.js`.
- **Three view variables, not one.** `performanceView` (solo/perRow),
  `dualSongActive` (bool), `viewMode` (perf/control). Control is an orthogonal
  overlay, not a mutually-exclusive 4th view.
- **Row-7 modifiers.** HOLD is really SHIFT (preset-no-migrate + scene-save);
  SOLO is the per-row toggle (no stem solo); MUTE/REV/STUT/HALF/DBL/KILL are six
  inert visual-only stubs. The Grid-2 FX bus is likewise visual/status only.
- **Per-stem launch quant** (dual-song): drums 1/16, bass 1 bar, other 1/4,
  vox 1/2. Stem colors: drums orange, bass blue, **other YELLOW/olive (not grey)**,
  vox green.

---

## Part 2 — Bug fix: dual-song no-deck ReferenceError

**Found by the audit, then fixed (this was an authorized code change, separate
from the docs-only Part 1).**

- **Bug.** `enterDualSongMode()` called `flashSideButtonRed(DUAL_SONG_TOGGLE)` on
  its no-deck / partial-staging failure branches, but `DUAL_SONG_TOGGLE` was never
  declared — it exists only as a string in `SIDE_FUNC_RIGHT[0]`. Reading it threw
  a **ReferenceError**, crashing MIDI dispatch instead of blinking the toggle red.
- **Fix** (`e6c1d87`). Both call sites now pass `SIDE_BUTTONS_RIGHT[0]` (note 89);
  deployed `loader.js` regenerated via the concat only (the `.amxd`/`.maxpat` were
  deliberately left untouched).
- **Verification.** Installed Node (v26.3.0 via Homebrew — mocha 10 is incompatible
  with Node 26, so tests run via `npx mocha@11`). Added a 4-case regression suite
  to `loader-e2e.test.js` (no throw, posts failure, red flash on note 89, dual-song
  not entered). **Full suite: 194 passing, 0 failing** (190 baseline + 4 new).
- **Docs updated** (`c9406c0`) to mark the bug resolved across drift notes,
  reference doc, and pad card (pre-fix descriptions kept for the record).

---

## Part 3 — Narrated academic slide deck

Built with `~/zacharysbrown/narrated-toolkit` (separate repo) from
`multi-song-tutorial.md`.

- **Deck:** `narrated-toolkit/deck/template/deck.html` — 12 slides, ~4.5 min.
- **Clean academic theme.** Restyled the toolkit's stock dark theme to warm paper
  ground, serif display type (Iowan/Palatino), restrained slate accent, flat
  hairline surfaces. All toolkit CSS class/variable names preserved so the
  generator still works.
- **Pipeline.** Narration scripts + slide HTML + beat anchors hand-authored
  (Claude, no Anthropic key needed) → OpenAI TTS (`onyx`, hd) → Whisper word
  timestamps → beat timing patched into the deck. **0 linear fallbacks** — every
  reveal anchors to a real spoken word. Total OpenAI spend ≈ **$0.20**.
- **Honest to the source:** slide 10 color-codes the row-7 reality (HOLD works,
  SOLO=per-row, 6 inert stubs); per-stem quant and "other=olive" preserved.
- **Source files** (in `narrated-toolkit/deck/`): `template/narration.json`,
  `template/beat-anchors.json`, `examples/setforge-multi-song-brief.md`. Generated
  audio/transcripts are gitignored (regenerable).

---

## Commits (this branch, m4l-devices — all local, NOT yet pushed)

```
c9406c0 docs(setforge-live): mark DUAL_SONG_TOGGLE crash resolved (e6c1d87)
e6c1d87 fix(setforge-live): dual-song no-deck entry crashed on undeclared DUAL_SONG_TOGGLE
04512b4 docs(setforge-live): supporting diagrams (view transitions, staging flow, state shape)
24519b1 docs(setforge-live): printable pad reference card (md + svg + pdf)
c3178fc docs(setforge-live): multi-song usage tutorial
521ad40 docs(setforge-live): implementation drift notes
671197f docs(setforge-live): multi-song reference doc
```
Plus this handoff doc. The narrated-toolkit work is committed in that repo
(separate branch).

---

## Open items / known issues

1. **`narrated-toolkit` `build.py` is out of sync with its own script** —
   it calls `generate_audio.py --in …` but the script needs the `generate`
   subcommand (`generate_audio.py generate --in …`). Worked around by running
   stages directly; the one-shot `build.py` is still broken. Easy fix.
2. **14 open questions** remain in `implementation-drift-notes.md` (e.g. whether
   the `/tmp` command-file poll is still intended; restaging unload semantics).
   These need Zak's call; none block correctness.
3. **A static "undeclared identifier" verifier** for the build was recommended
   (the regression test guards the specific bug, but a lint-style pass would catch
   the whole class). Not implemented.
4. **7 commits are unpushed** on this branch; nothing was pushed (not requested).
5. **Pre-existing uncommitted `.maxpat`/`.amxd` edits** (yours) are untouched and
   still in the working tree.
6. **`docs-spec.md`** (the generation spec you provided) is untracked at repo root.

---

## Next steps (suggested)

- [ ] Review the 5 doc artifacts + the narrated deck; print `pad-reference-card.pdf`.
- [ ] Decide on the 14 drift open questions (or defer).
- [ ] Push this branch when ready (`git push origin fix/setforge-live-curation-persistence`).
- [ ] Optionally: fix `narrated-toolkit/build.py`; add the undeclared-identifier
      verifier; render a second deck (e.g. from the reference doc); swap the deck
      voice if `onyx` isn't right.
