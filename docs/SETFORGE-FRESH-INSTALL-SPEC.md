# Setforge — Fresh-Install Spec

**For:** Claude Code. **Status:** spec (build the script + verify against the acceptance list).
**Goal:** One command stands up the entire Setforge ecosystem on a machine from the pushed `feat/ecosystem-unify` branches, in a consistent layout, **without recreating big model artifacts**. Two execution modes share one script:

- **Mode FRESH** — a genuinely new machine: clone, install deps, download models.
- **Mode SIM** — *zak's immediate goal*: simulate a fresh install **in a new directory on an existing machine**, **reusing the heavy model artifacts already on disk** (demucs/beat-this/LarsNet weights, and optionally the taste DB + stem/chop caches). This is how we validate the install end-to-end cheaply.

Companion docs: `SETFORGE-LEAN-RECONCILIATION-PLAN.md` (the `SETFORGE_HOME` resolver + dep/version reconciliation this spec depends on) and `SETFORGE-BACKUP-cc-instructions.md` (backup already completed — the branches are the source of truth).

---

## 1. What "installed" means (the layout)

Two roots, kept separate so code is disposable and data/models persist:

```
$SETFORGE_CODE   (default ~/setforge  — or a throwaway dir in SIM mode)
├── taste/         (git, feat/ecosystem-unify)
├── stemforge/     (git, feat/ecosystem-unify)
└── m4l-devices/   (git, feat/ecosystem-unify)

$SETFORGE_HOME   (default ~/.cache/setforge — see lean plan §A; env-overridable)
├── db/setforge.db          # the library DB (data — reused, never re-created if present)
├── stems/<track_id>/       # demucs output (data)
├── chops/<track_id>/       # materialized chops (data)
├── audio/<track_id>.*      # source cache (data)
├── analysis/<track_id>/    # bar grids, structure (data)
├── sets/<name>/            # exported set bundles (data)
├── recipes/<name>.yaml     # forge-set recipes
├── peaks/  ipc/  audit_state/  numba/
└── models/                 # see §2 — BIG, reused, never re-downloaded if present

MODEL CACHES (machine-global, NOT under code; reused across installs):
├── ~/.cache/torch/hub/checkpoints/      # demucs (htdemucs*) weights
├── ~/.cache/huggingface/                # beat-this weights (HF hub)
└── $SETFORGE_HOME/models/larsnet/       # LarsNet drum models (was ~/.stemforge/models/larsnet)
```

`$SETFORGE_CODE` and `$SETFORGE_HOME` are written into `~/.config/setforge/setforge.env` and sourced from the shell rc, so all three repos resolve the same paths (lean plan §A).

## 2. Model artifacts — the "do NOT recreate" set

These are large, slow to produce, and **must be reused, never regenerated, when already present**:

| Artifact | Size | Default location | Reuse mechanism |
|---|---|---|---|
| Demucs weights (htdemucs, htdemucs_ft) | ~1–4 GB | `~/.cache/torch/hub/checkpoints/` | torch auto-finds; install must NOT delete. SIM: leave as-is. FRESH: download once. |
| beat-this model | ~hundreds MB | `~/.cache/huggingface/hub/` | HF hub cache; same treatment. |
| LarsNet drum models | large | `$SETFORGE_HOME/models/larsnet/` | consolidate `~/.stemforge/models/larsnet` here; symlink if pre-existing. |
| taste DB (`setforge.db`) | ~25 MB | `$SETFORGE_HOME/db/` | **DATA, not a model, but treat the same: never clobber.** If present, reuse; if absent, `python -m taste init` an empty schema. |
| stems / chops / audio caches | many GB | `$SETFORGE_HOME/{stems,chops,audio}` | reused as-is; never wiped by install. |

**Install rule:** the script **detects** each model/data artifact and **skips acquisition if present**. A `--force-models` flag (off by default) is the only way to re-download. In SIM mode, model dirs are pointed at the existing machine caches (env vars or symlinks), so a fresh clone triggers **zero** model downloads and **zero** re-stemming.

## 3. The install script (`setforge-install.sh`)

Single entry point; home it in stemforge root next to `SETFORGE.md` (it orchestrates all three). Folds in the good parts of the four existing scripts (`taste/tools/setup-machine.sh`, `stemforge/scripts/setup.sh`, `stemforge/install.sh`) and fixes their known bugs (wrong remote URL, the no-op m4l `install.sh` call, version drift — see lean plan §C3).

**Flags:** `--mode fresh|sim` (default detect: `sim` if model caches already exist, else `fresh`), `--code-dir <path>`, `--home <path>`, `--force-models`, `--no-ableton` (skip Live wiring for headless/CI).

**Phases:**

1. **Prereqs.** Check `git`, `python3`, Homebrew; `op` (1Password) optional → warn if absent (Spotify enrichment degrades, per lean plan §B). Detect `arch=$(uname -m)`.
2. **Resolve roots.** Set `$SETFORGE_CODE`, `$SETFORGE_HOME`; create the full `$SETFORGE_HOME` tree (§1). Write `~/.config/setforge/setforge.env` and append a source-line to the shell rc (idempotent).
3. **Clone (or update) the three repos** from the correct remote `git@github.com-zacharysbrown:ZacharySBrown/<repo>.git` into `$SETFORGE_CODE`, checkout `feat/ecosystem-unify`. (SIM may instead symlink/worktree the existing checkouts — but the point of SIM is to prove a clean clone works, so prefer a real clone into a throwaway dir.)
4. **Python env.** pyenv **3.11** (resolve the 3.11/3.13 drift — lean §C3) + `uv`; `uv sync` in stemforge with the right extras (`native,beat,configurator` minimum; `all` for dev); install taste deps into that venv (`pyproject` or pinned `requirements.txt` — add one per lean §C3); `npm ci`/build for `taste/popup` (ship `dist/`) and optional `device/setforge-live` test deps.
5. **Model wiring (the reuse step).** Detect each artifact in §2. If present → record its path in `setforge.env` (and symlink LarsNet into `$SETFORGE_HOME/models/` if it lived under `~/.stemforge`). If absent and `--mode fresh` → trigger a one-time download (demucs/beat-this lazy-download on first run; LarsNet per stemforge's fetch path). **SIM mode asserts all are present and downloads nothing.**
6. **DB.** If `$SETFORGE_HOME/db/setforge.db` absent → `python -m taste init`. Never overwrite an existing DB.
7. **M4L wiring** (skip with `--no-ableton`). `stemforge generate-pipeline-json`; build the devices (`build_setforge.py`) and copy/symlink the setforge `.amxd` + JS into the Ableton User Library / Max Packages; write `~/.stemforge/python_path` for the bridge.
8. **Arch branch.** Apple Silicon: torch/demucs use MPS automatically. **Non-M-series → the placeholder block (§5).**
9. **Verify** (§4).

## 4. Acceptance criteria (the script self-checks these; CI-gateable with `--no-ableton`)

- [ ] All three repos cloned at `feat/ecosystem-unify`, clean working tree.
- [ ] `$SETFORGE_HOME` tree exists; `setforge.env` written + sourced; all three repos resolve the same `SETFORGE_HOME` (assert via a probe in each).
- [ ] **Zero model downloads in SIM mode** (assert torch/HF/LarsNet caches were pre-existing and untouched; assert no re-stemming).
- [ ] `python -m taste --help`, `stemforge --help` both run in the venv.
- [ ] DB present (reused) or initialized; `sqlite3 db/setforge.db "select count(*) from tracks"` succeeds.
- [ ] **End-to-end smoke:** `forge-set` a 2-track recipe that points at **already-cached stems** (reuse, no demucs) into a scratch `SETFORGE_HOME`, then `m4l-devices/schemas/validate.py` PASSes both output JSONs. (This is the install proving the curation→set path works on a "fresh" tree.)
- [ ] `--no-ableton` path is fully green headless (for CI).
- [ ] Apple Silicon: `torch.backends.mps.is_available()` True; Intel: False is treated as expected, not an error.

## 5. Non-M-series (Intel) placeholder — zak fills from the mini

```bash
if [ "$arch" = "arm64" ]; then
  :   # MPS auto-selected by demucs/beat_detect/drum_separator
else
  # ─────────────────────────────────────────────────────────────
  # TODO(zak): NON-M-SERIES (Intel x86_64) — paste working steps from the mini.
  #   • torch/torchaudio/demucs → CPU only (functional, ~5-10x slower; surface, don't fail).
  #   • Prefer uv.lock numba 0.65 / llvmlite 0.47 (old 0.60/0.43 pins lack x86_64/py3.11 wheels).
  #   • CoreML + the v0 arm64 native binary are NOT available on Intel → Python/Demucs path only.
  #   • <Intel-specific brew/pyenv/torch index-url steps here>
  # ─────────────────────────────────────────────────────────────
  echo "⚠️  Intel Mac: CPU torch (slower); native/CoreML path skipped. See TODO."
fi
```
Everything arch-sensitive except the v0 native binary is **soft** (auto CPU fallback already coded). v0 is out of the lean scope, so Intel users get the full Python/Demucs/companion path.

## 6. SIM runbook (validate now, on this machine)

```bash
# 1. throwaway code dir + reuse all existing model/data caches
SETFORGE_CODE=~/setforge-sim SETFORGE_HOME=~/.cache/setforge \
  bash setforge-install.sh --mode sim --code-dir ~/setforge-sim
# 2. it must: clone the 3 branches fresh, install deps, download NOTHING big,
#    reuse ~/.cache/torch + ~/.cache/huggingface + LarsNet + the existing DB/stems.
# 3. run the end-to-end smoke (forge-set on cached stems) + schema validate.
# 4. teardown: rm -rf ~/setforge-sim  (data/models in SETFORGE_HOME untouched)
```
If SIM is green, FRESH differs only by actually downloading models the first time — which the script does via the same detect-then-acquire path.

## 7. Open decisions (flag, default chosen)
- `$SETFORGE_CODE` default `~/setforge` vs keeping `~/zacharysbrown/` — **default `~/setforge`** for portability; the existing `~/zacharysbrown` checkouts remain valid (env points at whichever).
- Whether SIM clones fresh vs worktrees the existing repos — **default fresh clone** (truer test).
- Consolidating `~/.stemforge/models/larsnet` → `$SETFORGE_HOME/models/larsnet` now vs symlink — **default symlink** (zero move).
