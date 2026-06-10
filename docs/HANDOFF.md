# Setforge Ecosystem — Redesign Handoff

## What this is

This handoff captures the current state of the setforge ecosystem as of 2026-06-10, after a major unification effort across three repos. It's the starting point for a robust redesign that consolidates the devices and closes gaps.

## Key Documents

### Feature Inventory
**[docs/FEATURE_INVENTORY.md](FEATURE_INVENTORY.md)** — 58 features across 5 categories (Curation, Performance, Arrangement, Calibration, Installation). Each feature has:
- Setup requirements and inputs/outputs
- Automation approach (UDP, LiveAPI, filesystem, visual)
- Current test coverage status
- Automation blockers

### User Acceptance Test Plan
**[docs/UAT_PLAN.md](UAT_PLAN.md)** — 21 user-centric workflows chaining features into testable scenarios. Covers end-to-end flows, performance-specific workflows, and edge cases. Each workflow has numbered steps with pass criteria.

### Ecosystem Overview
**[~/zacharysbrown/SETFORGE.md](../../SETFORGE.md)** — Single-page entry point explaining the three modes, interface contracts between repos, and CLI quick reference.

## Repos & Branches

All work is on `feat/ecosystem-unify`:

| Repo | Path | Branch |
|------|------|--------|
| **taste** | `~/zacharysbrown/taste` | `feat/ecosystem-unify` |
| **stemforge** | `~/zacharysbrown/stemforge` | `feat/ecosystem-unify` |
| **m4l-devices** | `~/zacharysbrown/m4l-devices` | `feat/ecosystem-unify` |

## Current Devices

| Device | File | Status |
|--------|------|--------|
| **setforge-loader.amxd** | `device/setforge-live/` | Working — 194 tests, all multi-song phases complete |
| **setforge-grid.amxd** | `device/setforge-live/` | Working — MIDI bridge to Launchpad |
| **setforge-calibrate.amxd** | `device/setforge-live/` | Working — warp marker validation |
| **setforge-arranger.amxd** | `device/setforge-live/` | Working — uses original v0 JS via include() |
| **punch-fx** | `device/punch-fx/` | Spec only — 31KB spec, no implementation |

## Critical Findings for Redesign

These were discovered during the feature inventory and should drive redesign priorities:

1. **6 of 8 modifiers are stubs** — MUTE, REV, STUT, HALF, DBL, KILL display visually but have no audio effect. Only HOLD and SOLO work.
2. **FX bus is visual-only** — filter sweep and throw controls emit status text but make zero LiveAPI calls.
3. **MK3 surface is dead code** — hardcoded to MK2 via `createSurface("mk2")`. MK3 pulse/flash SysEx returns null.
4. **Staging is synchronous** — pre-load blocks the press handler instead of streaming in the background.
5. **35/58 features untested** — most features have no automated coverage.
6. **Tests target source, not build** — modular tests run against `src/loader/*.js`, not the concatenated `loader.js` that ships.

## Pipeline State

The `forge-set` pipeline is fully functional:
```
YAML → register → analyze → stem → structure → materialize → [prechop] → export
```
- Vocal warp grids use `reconciled_continuity` mode (verified matching known-good reference)
- Supports `track_id` for existing DB rows and `file` for new local audio
- `--mode arrangement|session|both` controls arrangement prechop output
- Portable sets with relative paths via `resolveManifestPaths` at load time

## Cross-Machine Setup

- **M2 MacBook** (user `zak`) — primary dev machine
- **Intel Mini** (ssh `zak@mini`, user `zacharybrown`) — performance machine
- `install.sh` — builds + deploys all devices (no external deps)
- `tools/sync-machines.sh` — rsync stems/chops/DB between machines
- `taste` alias on Mini points to stemforge venv Python 3.11

## What's Next

Use the Feature Inventory to:
1. Decide which features to keep, cut, or merge in the redesign
2. Prioritize implementing the stub modifiers or removing them
3. Design the consolidated device architecture
4. Build the automated test harness using the automation approaches documented per feature

Use the UAT Plan to:
1. Define acceptance criteria for the redesigned device
2. Build regression tests from the workflow steps
3. Validate cross-machine portability end-to-end
