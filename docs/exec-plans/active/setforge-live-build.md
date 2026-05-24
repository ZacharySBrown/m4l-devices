# setforge-live — Build Exec Plan

> Generated manually by coding agent. Spec: `device/setforge-live/spec/setforge-live-spec.md`

## Manual Steps Required

These are the steps that genuinely need a human. The harness MUST gate the
build on `--confirm-tested` for each.

- **Create two empty .amxd patches in Max IDE** (~30s) — Max binary format can't be generated programmatically without Max SDK
- **Drop setforge-loader.amxd onto an audio track in Ableton Live** (~10s) — LiveAPI cannot programmatically add a M4L device to a chain
- **Drop setforge-calibrate.amxd onto an audio track in Ableton Live** (~10s) — same
- **Connect two Launchpad Pro mk3s via USB; verify device sees both** (~30s) — requires physical hardware
- **Load a real set; play chops; verify phase alignment by ear** (~120s) — audio quality requires human ear
- **Run full calibrator validation flow on a real track** (~60s) — warp marker gesture requires mouse interaction in Live
- **Run 30-min set arc acceptance test** (~1800s) — full performance flow requires human performer

**Total estimated human time per build cycle (excluding set arc):**
260 seconds (~4.5 min)

## Phase 0 — Scaffold ✅

- [x] Directory structure per spec §5
- [x] `package.json` with Mocha + Chai harness
- [x] `README.md`
- [x] Spec landed at `spec/setforge-live-spec.md`
- [x] Commit: `12eefe3`

## Phase 1 — Shared modules + unit tests ✅

- [x] `src/shared/chop-math.js` — clip_start/clip_length derivation (20 tests)
- [x] `src/shared/manifest-reader.js` — manifest + set.json parsing (16 tests)
- [x] `src/shared/color-palette.js` — stem/genre/state RGB constants (12 tests)
- [x] `src/shared/live-api-helpers.js` — launch quant constants, stem↔row mapping
- [x] Fixtures: `hiphop_v3`, `varying_track`, `missing_stem`, `invalid_bpm`
- [x] Expected chop-math regression fixture: `the_next_episode.json`

## Phase 2 — Loader modules + unit tests ✅

- [x] `src/loader/preset-banks.js` — 16-slot state machine (12 tests)
- [x] `src/loader/modifier-layer.js` — momentary/latch logic (10 tests)
- [x] `src/loader/scene-memory.js` — snapshot save/recall (7 tests)
- [x] `src/loader/chop-router.js` — pad→stem→clip routing
- [x] `src/loader/fx-bus.js` — filter + throws state machine
- [x] `src/loader/launchpad-surface.js` — MIDI note↔grid mapping, RGB batching

## Phase 3 — Calibrator modules + unit tests ✅

- [x] `src/calibrator/override-writer.js` — atomic .calib_override.json writes (5 tests)

## Phase 4 — Test harness + integration tests ✅

- [x] `tests/harness/mock-live-api.js` — records LiveAPI calls, scriptable returns
- [x] `tests/harness/mock-launchpad.js` — records RGB writes, emits MIDI
- [x] `tests/harness/fixture-loader.js` — loads fixtures + mock filesystem
- [x] Integration: `load-set.test.js` — full set load pipeline (5 tests)
- [x] Integration: `chop-trigger.test.js` — MIDI→clip launch (11 tests)
- [x] Integration: `preset-swap.test.js` — hot-swap with held chops (4 tests)
- [x] Integration: `scene-recall.test.js` — scene save/recall (4 tests)
- [x] Integration: `calibrate-flow.test.js` — full calibration pipeline (3 tests)
- [x] Integration: `panic.test.js` — all-stop semantics (7 tests)

**Test totals: 121 passing, 0 failing, 29ms**

## Phase 5 — Max patch wiring (NEXT — requires human)

- [ ] Create `setforge-loader.amxd` shell in Max IDE
- [ ] Wire `loader.js` as top-level JS controller via `[js]` object
- [ ] Add `[plugin~ 2]` / `[plugout~ 2]` (pitfall #7)
- [ ] Add presentation-mode UI per spec §2.1 (set chooser, status panel, panic button)
- [ ] Wire MIDI I/O for two Launchpad Pro mk3s
- [ ] Create `setforge-calibrate.amxd` shell in Max IDE
- [ ] Wire `calibrate.js` as top-level controller
- [ ] Add presentation-mode UI per spec §4.1

## Phase 6 — Live integration test (requires human)

- [ ] **Manual:** Drop both `.amxd` on audio tracks in Ableton Live
- [ ] **Manual:** Connect Launchpads, verify device recognition
- [ ] **Manual:** Load canonical hiphop_v3 set, verify slot population
- [ ] **Manual:** Play chops, verify phase alignment
- [ ] **Manual:** Test hot-swap, scene recall, panic
- [ ] **Manual:** Run calibrator on one real track, verify override write

## Phase 7 — Full performance test (requires human)

- [ ] **Manual:** 30-minute set from scratch with bank-A/B rotation
- [ ] **Manual:** Cross-bank transitions with held chops
- [ ] **Manual:** FX throws + filter sweeps during performance
- [ ] **Manual:** Panic recovery mid-set

## Audit-trail expectations

The build run MUST emit at minimum these events:

- `forge.start` (with spec reference)
- `spec.parsed` (with module + test counts)
- `module.<name>.tests_passed` for every JS module
- `integration.<suite>.passed` for every integration test suite
- `manual_step_required` for every step in `manual_steps`
- `forge.complete` (with duration_ms, test_count, pass_count)

## Edge cases covered by integration tests

| Scenario | Test file | Verified behavior |
|---|---|---|
| Missing stem in preset | `load-set.test.js` | Loads without crash; stem chops = null; other stems unaffected |
| Varying track (SICKO MODE-class) | `chop-trigger.test.js` | D1 plays full mix; other pads no-op; pads show disabled |
| Hot-swap to track missing held stem | `preset-swap.test.js` | Held chop stops, no replacement, no crash |
| Hot-swap to varying track | `preset-swap.test.js` | All held chops stop |
| Panic preserves preset state | `panic.test.js` | Stops chops + FX but does NOT eject loaded presets or scenes |
| Cross-preset scene recall | `scene-recall.test.js` | Snapshot stores preset index; caller re-activates on recall |
| Modifier double-tap latch | `modifier-layer.test.js` | Within 400ms window → latch; release doesn't unlatch; re-tap releases |
| Calibrator round-trip | `calibrate-flow.test.js` | Load → drag marker → validate → atomic JSON write with delta |
