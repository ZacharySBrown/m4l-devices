# Coding agent handoff — setforge-live phase 0

**Date:** 2026-05-24
**Author:** chat-Claude (Zak's planning session)
**Target:** Claude Code, working from a worktree
**Status:** ready to execute phase 0 (scaffold + spec landing); phases 1-6 spec'd but not yet started

---

## 0. What you're building (in one paragraph)

`setforge-live` is a new device family inside the `m4l-devices` repo: two Max for Live audio-effect devices that turn two Novation Launchpad Pro grids into an MLR-paradigm stem performance instrument. It consumes calibrated deck manifests already produced by the existing `stemforge` repo and turns a curated setlist into a playable two-grid surface — Grid 1 plays bar-aligned stem chops, Grid 2 navigates the setlist and applies stem-targeted FX. **You do not need to understand the audio analysis side; trust the manifest contract.** Your job in this handoff is **phase 0 only** — scaffold the directory structure, land the spec and reference card, set up the JS test harness skeleton, and produce a clean phase-0 commit. Do not write any device code, any DSP, or any Max patches yet.

---

## 1. Repo state and where you should be working

The repo `/Users/zak/zacharysbrown/m4l-devices` has the following relevant state as of this handoff:

- **Main tree** is on branch `main` (note: upstream `origin/master` is gone but ignore that for this work — do not attempt to push).
- **Existing worktrees** in `.claude/worktrees/`:
  - `punch-fx/` — Zak's parallel punch-fx build. **Do not touch.**
- **Active builds you must not interfere with:** `device/tape-loss/` (uncommitted changes on main), `device/punch-fx/` (untracked on main + parallel worktree).
- **The new work for this handoff** goes in a **new worktree on a new branch**: `worktree-setforge-live`. You will create this.

### 1.1 Setup commands (run these first, in order)

**Zak has already created the worktree and dropped the spec into place before kicking you off.** Your job is to verify that state, scaffold everything else inside the device tree, and commit.

```bash
# 1. Confirm worktree exists and is on the right branch
cd /Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live
git rev-parse --abbrev-ref HEAD                   # should print "worktree-setforge-live"
git status                                        # may show the spec as untracked

# 2. Verify the spec exists (Zak dropped it before kickoff)
ls -la device/setforge-live/spec/setforge-live-spec.md
```

**If the spec is missing, stop and surface to Zak.** Do not proceed and do not improvise its contents.

**If the worktree doesn't exist yet** (i.e. `cd` fails), surface that to Zak — it means the prep step was skipped and you should not create it yourself, since Zak's intent may have changed.

The pad reference card files (`pad-reference-card.md`, `.svg`, `.pdf`) are **not part of this phase**. They will be added in a later commit by Zak directly. You do not need to create or verify them.

---

## 2. Inputs (what to read before you start)

### 2.1 Primary contract — read this first

**`device/setforge-live/spec/setforge-live-spec.md`** — the build specification. 837 lines, 9 numbered sections. This file does not yet exist in the repo; Zak will drop it into place before you begin. Verify it exists:

```bash
ls -la device/setforge-live/spec/setforge-live-spec.md
```

If missing, surface to Zak. Do not improvise the spec.

The spec sections most relevant to **phase 0** specifically:

- **§5 Architecture & file layout** — defines the exact directory structure you'll scaffold
- **§7 Build order** — Phase 0 is "scaffold (this commit)". Read this section carefully. Phases 1-6 are out of scope for this handoff.
- **§6 Testing plan** — only the framing matters for phase 0; you'll set up the harness skeleton, not write tests yet

### 2.2 Reference card — out of scope for this phase

The pad reference card (a printable cheat sheet of the two-grid layout) will be added separately. **Do not create it, do not reference it in scaffolding, and do not write a stub for it.** The `device/setforge-live/docs/` directory should still be created (per spec §5), and it can be empty with a `.gitkeep` for this phase.

### 2.3 Context — optional, only if you get stuck

The design conversation that produced these specs covered:
- Why MLR-paradigm and not Serato-paradigm DJ (look up "MLR monome Daedelus" if the spec's "MLR-style" terminology is unclear)
- Why this lives in `m4l-devices` and not `stemforge` (the calibrator-validator writes back to override files that `stemforge` consumes; the loader is a peer of `tape-loss`)
- The two-device split: performance loader + calibrator-validator share a manifest format but have different UX surfaces

If anything in the spec is unclear, **ask Zak before guessing**. Especially around:
- The exact format of `set.json` (spec §3.2)
- The hot-swap mechanic (spec §2.5) — this is the load-bearing detail
- The relationship to existing `stemforge` repo (it's upstream; we consume manifests, do not modify them)

---

## 3. Deliverables (phase 0 only)

Produce exactly these artifacts in the worktree, in this order:

### 3.1 Directory structure

Create the full directory tree per spec §5:

```bash
mkdir -p device/setforge-live/{spec,src/{loader,calibrator,shared},tests/{harness,fixtures/{manifests,stems,expected},unit,integration},docs}
```

Verify with:
```bash
tree device/setforge-live -L 3
```

Expected output: 4 top-level dirs (`spec/`, `src/`, `tests/`, `docs/`), with `src/` having 3 subdirs, `tests/` having 4 with `fixtures/` having 3 sub-subdirs, and `docs/` being empty (will be populated by Zak's drops).

### 3.2 Empty `.gitkeep` files in empty leaves

Every empty directory needs a `.gitkeep` so git tracks it. Specifically:

```bash
touch device/setforge-live/src/loader/.gitkeep
touch device/setforge-live/src/calibrator/.gitkeep
touch device/setforge-live/src/shared/.gitkeep
touch device/setforge-live/tests/harness/.gitkeep
touch device/setforge-live/tests/fixtures/manifests/.gitkeep
touch device/setforge-live/tests/fixtures/stems/.gitkeep
touch device/setforge-live/tests/fixtures/expected/.gitkeep
touch device/setforge-live/tests/unit/.gitkeep
touch device/setforge-live/tests/integration/.gitkeep
touch device/setforge-live/docs/.gitkeep
```

**Do not** add `.gitkeep` to `spec/` — it has the spec file Zak dropped.

### 3.3 JS test harness skeleton

Create `device/setforge-live/package.json` with the harness scaffolding:

```json
{
  "name": "setforge-live",
  "version": "0.0.0",
  "private": true,
  "description": "MLR-paradigm stem performance device family for Ableton Live",
  "scripts": {
    "test": "mocha tests/unit/**/*.test.js tests/integration/**/*.test.js",
    "test:unit": "mocha tests/unit/**/*.test.js",
    "test:integration": "mocha tests/integration/**/*.test.js"
  },
  "devDependencies": {
    "chai": "^4.4.1",
    "mocha": "^10.4.0"
  }
}
```

**Versions:** check what's in `device/tape-loss/` or `device/punch-fx/` for existing version pins. Match them if they exist; the versions above are sensible defaults if not. **Do not run `npm install` or commit a `package-lock.json` in phase 0** — that's a phase 1 concern.

### 3.4 A README at the device root

Create `device/setforge-live/README.md`:

````markdown
# setforge-live

MLR-paradigm stem performance device family for Ableton Live.

Two Max for Live devices:

- **`setforge-loader.amxd`** — the performance device, drives two Launchpad Pro grids
- **`setforge-calibrate.amxd`** — the validation device, native warp-marker UX

Reads deck manifests produced by [stemforge](../../stemforge); see `spec/setforge-live-spec.md` for the full build specification.

## Status

Pre-implementation. Phase 0 (scaffold) complete; phases 1-6 not yet started.

## Build order

See spec §7. Phase 2 (calibrator) ships first as v0.1 standalone.

## Reference

- Spec: [`spec/setforge-live-spec.md`](spec/setforge-live-spec.md)
- Tests: `npm test` (run from this directory)
````

### 3.5 The spec (already in place)

The spec at `device/setforge-live/spec/setforge-live-spec.md` was dropped into the worktree by Zak before kickoff. You verified its presence in §1.1. It is currently **untracked**; the `git add` in §3.6 will include it in the commit.

No action needed here.

### 3.6 The phase 0 commit

Once all of the above is in place:

```bash
git add device/setforge-live/
git status                                        # review what's staged
```

Verify staged files include:
- All `.gitkeep` files (including the one in `docs/`)
- `device/setforge-live/package.json`
- `device/setforge-live/README.md`
- `device/setforge-live/spec/setforge-live-spec.md`

If anything else appears (e.g. accidentally staged tape-loss or punch-fx changes), **unstage it**. The worktree should not be modifying any other device's files.

Commit:

```bash
git commit -m "setforge-live: v0 spec scaffold (phase 0)

Adds the directory structure, build spec, and JS test harness
scaffolding for the setforge-live device family (performance
loader + calibrator-validator).

No code yet. Phase 0 per spec §7 — scaffold only.

See device/setforge-live/spec/setforge-live-spec.md for full
build specification. Next phase (1) is chop-math + manifest-reader
unit-tested implementation in src/shared/."
```

---

## 4. Non-goals for this handoff (do not do these things)

- **Do not write any device code.** No `.js` files in `src/`, no Max patches, no DSP. Phase 1 starts that.
- **Do not write tests.** The harness scaffolding (package.json) is enough; the actual `*.test.js` files come in phase 1.
- **Do not modify any other device.** `device/tape-loss/` and `device/punch-fx/` are untouchable.
- **Do not modify `stemforge` or `taste` repos.** They are upstream; we consume their outputs.
- **Do not run `npm install`.** Save that for phase 1 when you actually need the modules.
- **Do not push to any remote.** This is local-only worktree work; Zak will push when ready.
- **Do not merge to main.** Stay on `worktree-setforge-live`.
- **Do not touch `.claude/worktrees/punch-fx/`.** That's Zak's parallel build.

---

## 5. How to surface questions

If the spec is ambiguous, or if any of the verify-files-exist checks fail, **stop and produce a question for Zak rather than guessing.** Phase 0 is intentionally small precisely so it's hard to get wrong; if you find yourself improvising, something is off.

Append questions to a new file at `docs/exec-plans/active/setforge-live-handoff-questions.md` in the main tree (not the worktree — that file is across both, Zak will see it). Use the format:

```markdown
## Q1
**Asked:** 2026-MM-DD
**Context:** <one sentence>
**Question:** <the question>
**Blocker?** yes/no
**Default if no answer in 24h:** <what you'll do otherwise>
```

---

## 6. Definition of done

Phase 0 is done when:

- [ ] Worktree `worktree-setforge-live` exists at `.claude/worktrees/setforge-live` (created by Zak before kickoff)
- [ ] Directory structure under `device/setforge-live/` matches spec §5
- [ ] `package.json` and `README.md` exist with the contents above
- [ ] `spec/setforge-live-spec.md` is in place (dropped by Zak, verified by you)
- [ ] One commit on `worktree-setforge-live` containing all of the above
- [ ] `git status` is clean
- [ ] No changes outside `device/setforge-live/`

Surface the commit hash to Zak when done.

---

## 7. Next handoff

Phase 1 (chop-math + manifest-reader, unit-tested) will be a separate handoff doc. Do not start it.

The order of subsequent phases, per spec §7:

1. **Phase 1** — `src/shared/chop-math.js` + `src/shared/manifest-reader.js` with unit tests
2. **Phase 2** — Calibrator device (`setforge-calibrate.amxd`) shipped as v0.1
3. **Phase 3** — Loader skeleton, single Launchpad, single preset
4. **Phase 4** — Full Grid 1 (presets, modifiers, scenes)
5. **Phase 5** — Grid 2 (setlist, target, FX, transport, panic)
6. **Phase 6** — Set arc workflow (bank-A/B simultaneous load, long-press load)

Each phase has its own definition-of-done in spec §7.

---

*end of handoff doc*
