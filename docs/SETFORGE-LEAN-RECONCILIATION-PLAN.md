# Setforge — Path Reconciliation + Lean Single-Branch Packaging — Execution Plan

**For:** Claude Code, working across the three Setforge repos.
**Author:** research synthesized from a 4-agent sweep (paths / git+install / Spotify+skill / lean inventory).
**Goal:** Make the full Setforge UX flow (curate → stem → load → perform) reproducible on a fresh machine from a single consistent branch, with reconciled paths, DB reuse (no duplicates), a Spotify-creds guard, the `forge-set` skill, and a cross-platform install script (with a non-M-series placeholder zak fills in from the mini).

---

## 0. Decisions taken (override any before starting)

These were going to be confirmed interactively; the prompt tooling failed, so they're set to the safe defaults below. **If zak wants different, change here first — they ripple through the plan.**

1. **Lean strategy = untrack + gitignore** (NOT a history rewrite). `git rm --cached` the big/cruft dirs and add to `.gitignore`. Files stay on disk; fresh clones get lean from here forward. Reversible, no force-push. (Old blobs remain in history — a `filter-repo` purge is a separate, later call.)
2. **Scope = cut only dead/unrelated.** Remove m4l `device/tape-loss/` + `dsp/` + `data/tl_*`, and stemforge `v0/` (abandoned arm64-native experiment). **Keep** stemforge `exporters/` (EP-133/Koala/Chompi) + `configurator/` in-repo (lazy-imported, zero runtime cost) but **exclude from the default install**.
3. **Data root = keep `~/.cache/setforge`** as the default `SETFORGE_HOME`, env-overridable, plus a shim so stemforge's `~/stemforge/processed/<slug>` output is reachable by the taste pipeline. **Zero data migration.**

## 0.1 Canonical truths (verified — don't re-litigate)

- **Code repos (all three already on branch `feat/ecosystem-unify`):** `~/zacharysbrown/taste`, `~/zacharysbrown/stemforge`, `~/zacharysbrown/m4l-devices`. Remote = `git@github.com-zacharysbrown:ZacharySBrown/<repo>.git`.
- `~/stemforge` is **runtime data** (`STEMFORGE_ROOT`, `config.py:9`), not a checkout. `~/Claude/Projects/taste` is **scratch/docs**, not code. Ignore both for git work.
- **m4l-devices is ahead 28 unpushed commits** on `feat/ecosystem-unify` → **push before any consolidation** or they're at risk.
- **Branch name to standardize on: `feat/ecosystem-unify`** (already consistent across all three; no rename needed).
- The DB `~/zacharysbrown/taste/setforge.db` (23 MB) is the real library — **runtime data, never commit**.

---

## Workstream A — Path reconciliation (one env-overridable root + resolver)

**Problem (from research):** two parallel artifact roots (`~/.cache/setforge/` for taste vs `~/stemforge/processed/` for stemforge), stem dirs keyed differently (track_id vs name-slug), derived data written *into the code repos* (`analysis_cache/`, `companion/peaks/`), the DB resolved 3 different ways, and hardcoded `/Users/zak/...` paths. taste honors almost no env vars; stemforge honors several.

### A1. Introduce a single resolver in each repo
Create `paths.py` (taste + stemforge) / extend companion config (m4l) that resolves everything from `SETFORGE_HOME` (default `~/.cache/setforge`, override via env). One function per artifact type:

```python
# taste/paths.py  (mirror a thin version in stemforge/config.py and m4l companion)
import os
from pathlib import Path
SETFORGE_HOME = Path(os.environ.get("SETFORGE_HOME", os.path.expanduser("~/.cache/setforge")))
def db_path():        return Path(os.environ.get("SETFORGE_DB", SETFORGE_HOME / "db" / "setforge.db"))
def stems_dir(tid):   return SETFORGE_HOME / "stems" / str(tid)
def chops_dir(tid):   return SETFORGE_HOME / "chops" / str(tid)
def audio_cache(tid): return SETFORGE_HOME / "audio" / f"{tid}"
def analysis_dir(tid):return SETFORGE_HOME / "analysis" / str(tid)   # moved out of repo
def sets_dir(name):   return SETFORGE_HOME / "sets" / name
def recipes_dir():    return SETFORGE_HOME / "recipes"
def peaks_dir():      return SETFORGE_HOME / "peaks"                  # moved out of m4l repo
def models_dir():     return SETFORGE_HOME / "models"
```

### A2. Replace path literals with resolver calls (exact sites from research)
**taste:** `setlist.py:45` (STEM_ROOT) · `forge_set.py:91,118` · `fetch.py:23` · `ingest/chop_materializer.py:24` · `ingest/chop_curator.py:120,273` · `ingest/vocal_export.py:19` · `ingest/bar_grid.py:25` + `ingest/structure_analysis.py:39` (CACHE_DIR — **move `analysis_cache/` out of the repo** to `$SETFORGE_HOME/analysis/`) · `cli.py:329-331,436,442-443,492,541,554,725,752` · `app.py:25,75`, `schema.py:205`, `eval_tempo.py:73`, `rec_server.py:9` (DB default → `db_path()`).
**stemforge:** `config.py:9-16` (`STEMFORGE_ROOT`/`PROCESSED_DIR` → default to `$SETFORGE_HOME`, key stems by **track_id** when invoked by taste) · `drum_separator/__init__.py:16` (`~/.stemforge/models` → `models_dir()`). configurator already honors `STEMFORGE_*` envs — point their defaults at the new root.
**m4l-devices:** `companion/serve.py:27-28` (replace hardcoded `~/zacharysbrown/taste` + DB with `SETFORGE_HOME`/`SETFORGE_DB` + a `TASTE_REPO` env) · `companion/peaks_gen.py:90` (`peaks/` → `peaks_dir()`) · loader `loader-controller.js:2124,3883,3987` (`/tmp/setforge_*` → keep `/tmp` default but allow `$SETFORGE_HOME/ipc/`).

### A3. Bridge the stemforge↔taste stem gap (kills the #1 divergence)
- Make `setlist.py:177-188` (taste's `stem_track`) the single sanctioned entry: it already calls `stemforge split -o $SETFORGE_HOME/stems/<track_id>`. Keep that, but **also** teach `locate_stems` (`setlist.py:157-174`) to find a name-slug dir under `~/stemforge/processed/` and hardlink/symlink it into `stems/<track_id>/` if present (the shim) — so a bare `stemforge split` is reusable instead of invisible. This is exactly the manual `cp` step from the hey_mami handoff, automated.
- Make `stems.json` store **relative** paths (currently absolute `/Users/zak/...`), so stem dirs relocate across machines. Writer: stemforge slicer/backends; update the loader/readers that expect absolute (loader already re-absolutizes chop paths against set dir — mirror that for stems).

### A4. Fix hardcoded cross-repo paths → env vars
- `taste/setlist.py:29-39` `_find_stemforge()` sibling `.venv/bin/stemforge` → honor `$STEMFORGE` first (already partly does), document it.
- `m4l-devices/device/setforge-live/sf_locator_anchor.js:42-49` (`PYTHON_BIN`, `STEMFORGE_REPO`, `HELPER`) → read from env (`$STEMFORGE_REPO`, `$STEMFORGE_PY`) with the current paths as fallback.
- `m4l-devices/device/setforge-live/tests/uat/*` `MANIFEST_DIR = ~/zacharysbrown/taste/setlist_out/manifests` → env/`SETFORGE_HOME`.

### A5. Two `.set.json` schemas (note + guard, don't break)
There are two incompatible `.set.json` shapes: the **input recipe** (`tracks[].manifest`, schema 2.1, in `setlist_out/`) consumed by `export_set.py:58-67`, and the **output set** (`preset_bank_A/B` + `setlist[]`, schema 1.0) the loader reads. **Don't unify in this pass** — instead (a) document both in `m4l-devices/schemas/README`, and (b) add a one-line schema discriminator + clear error if the loader is handed a recipe-form file. Full unification is a follow-up.

**A — Acceptance:** `SETFORGE_HOME=/tmp/sf_test python -m taste forge-set <recipe> --steps structure,materialize,export` writes everything under `/tmp/sf_test` and nothing into the code repos; companion + loader read from the same root; rerun on a second machine path works without edits.

---

## Workstream B — Spotify creds guard + `forge-set` skill hardening

**Problem (from research):** `_load_spotify_creds()` (`cli.py:35-52`) reads env vars → falls back to 1Password `op read`, and **hard-exits** (`sys.exit`) if `op` is unavailable. `forge-set` calls it **unconditionally** when `register` is in steps (`cli.py:743-744`), so the pipeline dies even though `_resolve_or_register()` (`forge_set.py:499-522`) already degrades gracefully to local-only when the Spotify *lookup* fails. So a machine without 1Password can't run the skill's recommended `--steps register,...` even though it functionally could.

### B1. Add a non-fatal creds check + warn-and-continue
Add `_check_spotify_available()` (presence check only, no `sys.exit`) and gate the call:
```python
# cli.py, replace the unconditional block at ~743-744
if "register" in steps:
    if _check_spotify_available():
        _load_spotify_creds()
    else:
        print("⚠️  Spotify creds unavailable (no SPOTIPY_* env and `op` not reachable).")
        print("    Continuing with LOCAL-ONLY registration — new tracks get no genres/popularity/ISRC.")
        print("    To enable: set SPOTIPY_CLIENT_ID/SECRET/REFRESH_TOKEN or configure 1Password `op`.")
```
- **Hard-require (keep `sys.exit`):** `ingest-spotify`, `ingest-curators`, `discover` — these are inherently Spotify-driven.
- **Warn-and-continue:** `forge-set register`, `add` (also wrap `add`'s `_load_spotify_creds()` at `cli.py:270-283` the same way; today `--no-spotify` is the only escape).
- The `analyze` step's Spotify need should be documented, not silently fatal — if `analyze` is requested without creds, warn and skip enrichment rather than exit.

### B2. Update the `forge-set` skill (`taste/.claude/skills/forge-set.md`)
The skill already exists and is solid (5 steps: resolve→YAML→run→validate→report; checks DB first and UPDATEs instead of inserting duplicates; mandates `grid_mode: reconciled_continuity` and `--force`). Close the gaps:
- Add a **Spotify section**: how creds resolve (env → 1Password), that `register`/`add` now warn-and-continue, and that `--steps all`/`prep` still need creds for `analyze`. Recommended default steps stay `register,stem,structure,materialize,export`.
- Make all paths in the skill go through `SETFORGE_HOME` (it currently hardcodes `~/.cache/setforge/sets/...` and `~/zacharysbrown/...`).
- Note the stem-reuse shim (A3): if stems already exist under `~/stemforge/processed/<slug>`, the skill/pipeline reuses them instead of re-stemming.

**B — Acceptance:** with no `op` and no `SPOTIPY_*`, `python -m taste forge-set <recipe> --steps register,stem,structure,materialize,export` completes with a visible warning and local-only registration; `ingest-spotify` still hard-fails clearly. Skill dry-run resolves songs against the DB without creating duplicate rows.

---

## Workstream C — Lean single-branch + cross-platform install script

### C1. Push + standardize the branch
- In **m4l-devices**, push the 28 unpushed `feat/ecosystem-unify` commits FIRST.
- Confirm all three repos are on `feat/ecosystem-unify` and pushed. Prune stray local branches (esp. stemforge's ~140 `worktree-agent-*` / merged `feat/configurator-*`/`feat/v0-*`/`feat/hardening-*`; keep `main`, `feat/ecosystem-unify`, `release/v0.2.0`).

### C2. Untrack cruft + extend `.gitignore` (per decision 0.1/0.2)
For each repo, `git rm -r --cached <paths>` then add to `.gitignore` (files remain on disk):
- **taste:** `experiments/`, `audit/` (+ `taste-audit-station-*.md`), `app.py`/`visualize.py`/`eval_tempo.py` (old viz — confirm unused first), `popup/node_modules/`, `popup/src/` (ship only `popup/dist/`), stale `HANDOFF*.md`/`SETFORGE_HANDOFF.md`/`TEMPO_AND_BEAT_MAP_STATE.md`. Already-ignored (verify): `setlist_out/` (6.7 GB), `local_scan/`, `analysis_cache/`, `*.db`, `.env`.
- **stemforge (biggest wins):** untrack `v0/` (4.6 GB), `web/configurator/` (219 MB), `grooves/` (840 MB) + `grooves.zip` (269 MB), `docs/ep133-song-triage/*.pak|.ppak`, `docs/*EP-133*.pdf` + `specs/*EP-133*.pdf` (16 MB each), `specs/zak@mini`, root test audio (`01_Hey_Mami.wav`, `05 - Setting Sun.*`, `benjamins.*`, `little_by_little.wav`, `tinys_tempo.*`, `the_champ_30s.wav`), and output dirs `artifacts/ tbstemmed/ curated/ export/ dist/ test_musicai_output/ backups/ targets/ koala_exports/`.
- **m4l-devices:** **remove** (decision 0.2) `device/tape-loss/` (+ `tape-loss.amxd`), `dsp/` (45 MB tape-loss fixtures), `data/tl_*`, tape-loss `docs/`. Untrack `build/`, `pytest-cache-files-*`. Convert the dangling `.claude/agents` + `.claude/skills` **harness symlinks** (→ `~/raindog/harness/...`) to local copies or gitignore them (they break on any machine without the harness).

### C3. Reconcile dependency/version drift (blocks a clean install)
- **Python version:** pick ONE. Recommend **3.11** (install.sh already pins 3.11.11; demucs/torch wheels most stable). Update stemforge `.python-version` (currently 3.13) and `pyproject` `requires-python` to agree; note the venv is currently 3.13.
- **numba/llvmlite:** install.sh pins `numba==0.60.0`/`llvmlite==0.43.0` but `uv.lock` resolves `0.65.0`/`0.47.0`. Adopt the **uv.lock** versions (cross-platform wheels) and update install.sh.
- **taste deps:** add a `pyproject.toml` (or pin `requirements.txt`) — currently unpinned (`librosa soundfile mutagen rapidfuzz spotipy numpy flask` + `pyyaml`, `scipy`/`scikit-learn` implied). taste runs in stemforge's shared venv today; the install script should make that explicit.

### C4. Write ONE top-level install script
Create `setforge-install.sh` (home it in stemforge, or a new tiny `setforge` meta-repo / the m4l-devices root — recommend **stemforge root** next to `SETFORGE.md`). Fold in the good parts of the four existing scripts (`taste/tools/setup-machine.sh`, `stemforge/scripts/setup.sh`, `stemforge/install.sh`) and fix their bugs:
1. **Prereqs:** git, Homebrew, `op` (optional, warn), Ableton path prompt.
2. **Clone all three** from the **correct** remote `git@github.com-zacharysbrown:ZacharySBrown/<repo>.git` (setup-machine.sh currently uses the wrong `git@github.com:zacharysbrown/...` lowercase URL — fix), checkout `feat/ecosystem-unify`.
3. **Python env:** pyenv 3.11 + uv; `uv sync` in stemforge; install taste deps into that venv; `npm ci` where needed (`popup/dist` build, `device/setforge-live` test deps optional).
4. **`SETFORGE_HOME` bootstrap:** create the full dir tree (`db/ stems/ chops/ audio/ analysis/ sets/ recipes/ peaks/ models/ audit_state/ numba/ ipc/`) so paths are consistent across machines (requirement #2). Write a `setforge.env` exporting `SETFORGE_HOME`, `SETFORGE_DB`, `STEMFORGE`, `STEMFORGE_REPO`, `TASTE_REPO`; source it from shell rc.
5. **DB:** if no `$SETFORGE_DB`, `python -m taste init` to create an empty schema (don't clobber an existing library DB — check first; requirement #3).
6. **M4L wiring:** `stemforge generate-pipeline-json`; copy/symlink the setforge `.amxd` + JS into the Ableton User Library; write `~/.stemforge/python_path` for the bridge.
7. **Verify:** import torch + report device (MPS on Apple Silicon, CPU otherwise — see C5); `python -m taste --help`; `stemforge --help`; companion `serve.py` smoke; run `m4l-devices/schemas/validate.py` on a sample set.

### C5. Non-M-series placeholder (zak fills from the mini)
Add an explicit arch branch in the install script:
```bash
ARCH="$(uname -m)"
if [ "$ARCH" = "arm64" ]; then
   # Apple Silicon: torch/torchaudio/demucs use MPS automatically (beat_detect/demucs already auto-select).
   :
else
   # ───────────────────────────────────────────────────────────────
   # TODO(zak): NON-M-SERIES (Intel x86_64) SETUP — fill from the mini.
   #   • torch/torchaudio/demucs run CPU-only here (functional, ~5-10x slower — surfaced, not fatal).
   #   • Prefer uv.lock numba 0.65.0 / llvmlite 0.47.0 (the old 0.60/0.43 pins may lack x86_64/py3.11 wheels).
   #   • CoreML / the v0 arm64-native binary path is NOT available on Intel — Python/Demucs path only.
   #   • <zak: paste the exact working Intel install steps from the mini here>
   # ───────────────────────────────────────────────────────────────
   echo "⚠️  Intel Mac: using CPU torch (slower). Native/CoreML path skipped. See TODO block."
fi
```
The arch-specificity is otherwise **soft**: `backends/demucs.py:36-45`, `beat_detect.py:22-42`, `drum_separator/__init__.py:76-78` already fall back MPS→CUDA→CPU. The only **hard** arm64 piece (stemforge `v0/` native binary + CoreML, `docs/v0-ship-spec.md:370` "arm64-only") is out of the lean flow anyway (decision 0.2).

**C — Acceptance:** on a clean macOS account, `./setforge-install.sh` clones + sets up all three repos on `feat/ecosystem-unify`, builds `SETFORGE_HOME`, and ends green on the verify step; the Intel branch prints the placeholder and still installs the CPU path.

---

## Workstream D — Documentation + consistency

- Update `stemforge/SETFORGE.md` (the ecosystem entry point) with: the unified `SETFORGE_HOME` layout (the A1 tree), the install command, the branch name, and the canonical-trees table.
- Add `docs/PATHS.md` (or a section) = the artifact→path table from research, as the contract.
- Cross-link the `forge-set` skill, this plan, and `SETFORGE.md`.
- Note requirement #3 explicitly: the skill + pipeline always check the DB before inserting (verified: `forge_set.py:_resolve_or_register` resolves existing rows; skill Step 1 UPDATEs instead of inserting) — keep that invariant and add a test.

---

## Suggested sequencing (DAG)

```
C1 (push + branch)  ──►  A1–A4 (resolver + path swaps)  ──►  A5 (schema note)
                          │                                   │
                          ├──► B1 (creds guard) ──► B2 (skill update)
                          │
                          └──► C3 (dep/version reconcile) ──► C4 (install script) ──► C5 (Intel placeholder)
                                                                   │
C2 (untrack cruft) ───────────────────────────────────────────────┴──► D (docs)  ──► full-flow smoke test
```
Do **C1 first** (push m4l-devices). A-block is the backbone; B and C3/C4 can proceed in parallel once the resolver exists. C2 (untracking) is independent and low-risk — can run anytime. Finish with an end-to-end smoke (forge a 2-track set on a scratch `SETFORGE_HOME`, load it).

## Per-workstream testing
- **A:** unit-test `paths.py` resolver (env override, defaults); integration: forge-set into a temp `SETFORGE_HOME`, assert nothing written into repos; grep the repos for surviving `os.path.expanduser("~/.cache` / hardcoded `/Users/zak`.
- **B:** test `_check_spotify_available()` true/false branches; run register with creds unset → asserts warning + local-only row, no duplicate.
- **C:** run `setforge-install.sh` against a throwaway `$HOME`/`$SETFORGE_HOME`; CI matrix note for arm64 vs x86_64 (x86_64 marked allow-fail until zak fills the placeholder).
- **D:** `schemas/validate.py` on the smoke-test set; link-check the docs.

## Open follow-ups (out of scope here, flagged)
- Full unification of the two `.set.json` schemas (A5 only documents + guards).
- Optional `git filter-repo` history purge (decision 0.1 chose untrack-only).
- Universal2 / Intel native `stemforge-native` build (acknowledged arm64-only).
- Moving `~/.stemforge/models` (LarsNet) + consolidating the third stemforge root.
