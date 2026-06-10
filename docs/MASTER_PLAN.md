# Setforge Ecosystem — Master Plan

**Date:** 2026-06-10
**Owner:** zak
**Scope:** taste (curation) · stemforge (separation + bridge) · m4l-devices (performance/arrangement/calibration)
**Branch:** `feat/ecosystem-unify` across all three repos

This plan unifies the ecosystem behind two goals: **incredibly hardened, automated workflows** and a **deliberate, well-designed user experience**. It builds on the corpus already in `m4l-devices/docs/`: [FEATURE_INVENTORY.md](FEATURE_INVENTORY.md) (58 features, automation approaches), [UAT_PLAN.md](UAT_PLAN.md) (21 workflows), and [HANDOFF.md](HANDOFF.md) (redesign starting point).

---

## 0. Guiding principles

1. **The flow map and the test map are one artifact.** Every hero flow we design becomes a Live-in-the-loop regression test. "Well-designed UX" and "hardened workflow" ship together or not at all.
2. **No lying pads.** A control that lights up but does nothing is a UX defect, not a missing feature. Every visible affordance must do what it implies — or not be visible.
3. **Test the artifact that ships.** The device runs a concatenated monolith; tests must run against that monolith, not the modular source.
4. **Automate to the lowest sufficient tier.** Prefer API control planes (device UDP, Ableton MCP) over pixel automation. Computer use is for what only the GUI can do.
5. **Aural truth stays human.** Timing/feel verification remains a periodic manual gate (zak). Everything else gets automated.

---

## Focus Area 1 — Test Harness & CI

A five-layer pyramid. Lower layers run on every commit; upper layers run on demand / nightly against a real Ableton session.

### L0 · Build & static verification (no runtime)
- **Exists:** `tools/forge_device/verifiers.py` encodes the 20 M4L pitfalls; `stemforge_bridge.patcher` + `amxd_pack` provide patch primitives and round-trip.
- **Build:** make `build_setforge.py` **fail CI** on any verifier FAIL (today it prints but proceeds).
- **New — drift guard (highest leverage):** a verifier that re-concatenates `src/loader/*.js` in `LOADER_CONCAT_ORDER` and diffs against the shipped `loader.js`. This permanently closes the deployed-vs-modular gap (Critical Finding #6).

### L1 · Pure unit (no Live, no audio, no models)
- **taste (Python, pytest):** extend existing fixtures to cover `recommend` scorers, `BarGrid` geometry, and the genre strategies. Add **JSON-schema validators** for every contract: `set.json` (1.0), `manifest.json` (2.1), arrangement manifest, deck-loader v1.
- **m4l (JS):** modifier gesture state machine, scene serialization, chop-math, manifest-reader. **Rule: all JS tests `vm.eval` the monolith**, never import modules directly.

### L2 · Integration with mocked boundaries
- **taste:** a **stub `stemforge` CLI** (`split` + `re-anchor`) returning synthetic stems + metadata, so the full `forge-set` pipeline runs end-to-end in seconds. Mock demucs / beat-this / Spotify.
- **m4l:** expand the `loader-e2e` monolith-eval harness (mock Max env + `mock-live-api.js` + `mock-launchpad.js`) to cover the features currently untested-against-monolith: per-row, dual-song, staging, panic.

### L3 · Live-in-the-loop (the new tier) — three control planes
| Plane | Reaches | Use for |
|-------|---------|---------|
| Device UDP 7422/7423 · CC 100–108 · `/tmp/setforge_inspect.json` | Deep internal device state | Clip warp markers, implied BPM, save/sync round-trip, panic/eject |
| **`live-shortcuts` Ableton MCP** (`get_tracks`, `get_devices`, `get_device_params`, `set_device_param_by_name`, `fire_clip`, `get_transport`, `osc_status`) | LiveAPI surface, scriptably | Track creation/resolution, tempo sync, clip props, transport-quantized launches |
| **Computer use** | GUI-only operations | Drag `.amxd` onto tracks, configure MIDI track I/O (Launchpad Standalone Port, monitor In, arm), **read Launchpad LED state visually**, calibrate warp-marker drag |

Pattern: **computer use bootstraps Live into a testable state, then hands off to the API planes for assertions.** Never pixel-drive what UDP or the MCP can drive.

### L4 · Hardware / aural (manual, periodic — zak)
Physical Launchpad MIDI I/O, multi-machine sync (M2 ↔ Mini), and "does it sound right / in phase." Tracked as a manual checklist, not automated.

### Orchestration
A single `setforge-test` runner: `--ci` runs L0–L2; `--live` runs L3 with computer-use bootstrap; `--full` adds the L4 manual checklist prompts. CI gates merges to `feat/ecosystem-unify` on L0–L2 green.

---

## Focus Area 2 — UX, Flows & Design System

### Hero flows
Collapse the 21 UATs into a small set of journeys that must be flawless, each mapped entry → steps → decision points → failure modes → exit:
1. **Build a set** (curate from library → forge → load).
2. **Perform a set** (load → trigger → swap → scene → panic).
3. **Mashup / dual-song** (stage two decks → drum-on-drum → exit).
4. **Arrange** (load stems → re-anchor to locator → export snapshot).
5. **Calibrate** (validate downbeats by ear → write overrides).

Each finalized flow becomes one L3 regression scenario.

### Honesty gaps (resolve first — see FA3 for build)
The 6 inert modifiers and the visual-only FX bus actively mislead a performer mid-set. Decision (per zak): **implement them**, and **relocate the modifier layer to the physical circular side buttons of the Launchpad Pro MK2** (the original placed them on grid row 7 — a miss). This frees grid rows and gives modifiers a dedicated, always-available surface.

### Visual unification & design system
Promote `color-palette.js` into the single source of truth for state→color across **both** the M4L front panels and the Launchpad LED semantics. Define: stem colors, preset palette, scene purple, modifier states (idle/held/latched), staging flash colors, status-display typography and layout grid. All four devices (loader, grid, calibrate, arranger) adopt one front-panel design language.

### Process
Prototype flows as diagrams and front panels as mockups, iterate with zak (feel is his call), **then** touch `.maxpat`. Incoming: zak's whiteboard sketch of the target surface/flows — diagrams will be reconciled against it.

---

## Focus Area 3 — Device Functionality

### Modifier layer → Launchpad Pro MK2 side buttons (new requirement)
- Move all modifiers (HOLD, MUTE, SOLO, REV, STUT, HALF, DBL, KILL) off grid row 7 onto the **circular side buttons** surrounding the 8×8 grid.
- Requires a **Launchpad Pro MK2 surface implementation** with correct programmer-mode note numbers and SysEx for the side buttons (the standard-MK2 surface lacks full four-side circular buttons; the half-built MK3 surface may be partially reusable). Validate byte-for-byte against the Pro MK2 programmer reference, and add a surface verifier.
- Gesture semantics carry over: momentary press, double-tap latch (<400ms), no mutual exclusion. Re-home scenes if row 8 is also affected.

### Implement the 6 stub modifiers (real audio)
Build actual audio effects so the UI becomes honest:
- **MUTE / KILL** — route through Live clip/track state or an FX bus mute.
- **REV / HALF / DBL** — playback-rate / reverse handling on the stem clips.
- **STUT** — re-trigger / beat-repeat.
- Each gets a unit test (state machine), an L2 monolith test, and an L3 Live assertion (audible effect reflected in clip/transport state).

### FX bus routing
Wire the existing FX UI (targets, filter sweep, throws) to real Live sends/returns — today it emits status text and makes zero LiveAPI calls. Add the `live.send`/`live.return` setup to the `.maxpat`.

### Other consolidation
- **MK3 dead code:** either activate behind runtime hardware detection or remove `createSurface("mk2")` hardcode; reconcile with the Pro MK2 surface work above.
- **Async staging:** make pre-load stream in the background instead of blocking the press handler (Critical Finding #4).

---

## Focus Area 4 — Ecosystem Unification & Contracts

- **Canonical taste tree:** reconcile the two mount paths (one shows `forge_set.py`/`run_forge_set`, the other `setlist.py`); confirm which is canonical on `feat/ecosystem-unify` before writing harness code against it.
- **Contract registry:** version and schema-validate every cross-repo artifact (set.json, manifest 2.1, arrangement manifest, deck-loader v1, `.calib_override.json`, `arrangement_snapshot.json`). One `schemas/` directory, referenced by L1 validators.
- **Single ecosystem entry point:** keep `SETFORGE.md` current as the map of the three modes, interface contracts, and CLI quick reference.
- **Cross-machine portability:** fold `sync-machines.sh` dry-run + relative-path resolution into L3 as an integration check.

---

## Phasing & milestones

| Phase | Focus | Exit criteria |
|-------|-------|---------------|
| **P0 — Stop the bleeding** | L0 drift guard; CI fails on verifier FAIL; canonical taste tree confirmed; schemas extracted | Green CI gate on L0; monolith==src guaranteed |
| **P1 — Unit & integration depth** | L1 + L2 across both languages; stub `stemforge` CLI; monolith-only JS tests | forge-set runs e2e in CI <60s; per-row/dual-song/staging/panic covered |
| **P2 — UX design** | Hero-flow diagrams; front-panel mockups; design-system spec; reconcile with whiteboard sketch | Approved flows + visual language; honesty-gap decisions locked |
| **P3 — Device functionality** | Side-button modifier remap + Pro MK2 surface; implement 6 modifiers; FX routing; async staging | UI is honest; modifiers on side buttons; effects audible & asserted |
| **P4 — Live-in-the-loop** | L3 runner; computer-use bootstrap; each hero flow as a regression scenario | All 5 hero flows pass automated L3; nightly run green |
| **P5 — Polish & portability** | Cross-machine L3; manual aural checklist; docs | Sets portable M2↔Mini under test; release candidate |

---

## Open decisions

1. **Surface target:** confirm Launchpad **Pro** MK2 as the canonical hardware (changes the surface layer + SysEx vs. the standard MK2 the docs assumed).
2. **Modifier audio semantics:** exact behavior of REV/HALF/DBL/STUT (per-stem? whole-deck? latched vs momentary timing).
3. **Scene re-homing:** if modifiers vacate row 7, do scenes stay on row 8 or also move?
4. **Design fidelity:** inline diagrams/mockups vs. a connected design tool (Figma/Canva) for higher-fidelity front panels.
