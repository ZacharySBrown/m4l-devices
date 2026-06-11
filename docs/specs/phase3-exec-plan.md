# Phase 3 — Arrangement & Production: Execution Plan (cc DAG)

Translates `phase3-arrangement-spec.md` into a dependency-ordered task DAG. Each node = one bridge task, self-verifying (tests + harness UAT), local commits only, no push. **3.1 refined-preset editing excluded (deferred).**

## Waves & dependencies
```
WAVE 0  (the manifest/state seam — everything builds on it)
  035 (3A) Arrangement contract: extend arrangement.schema (dual-deck placements + scene markers)
           + /arrangement state slice in state.schema + sample data + validator/tests

WAVE 1  (the two surfaces — parallel-eligible, both need 035)
  036 (3B) Arranger device: dual-deck placement @ timeline bar + manifest read/write
           (src/arranger/*, mocked LiveAPI) + mocha e2e            [∥ 037]
  037 (3C) Write path: extend /action (place_pair, save/load_arrangement, seek_bar)
           + serve.py /arrangement slice (mock-tested)             [∥ 036]

WAVE 2  (companion view — needs the state slice + actions)
  038 (3D) Companion Arrangement view (3rd tab): dual-deck timeline, clips-by-source,
           scenes-as-markers; jsdom tests (uses cc-033 guards)     [needs 037]

WAVE 3  (integration)
  039 (3E) Phase-3 end-to-end headless UAT + new `arrangement` stage in setforge-test
           (place_pair / save+load / scene-on-timeline)            [needs 036 + 038]
```
Serial order respecting all edges: 035 → 036 → 037 → 038 → 039 (036∥037 marked for a future 2nd executor).

## Stable seams
- `arrangement.schema.json` + the `/arrangement` state slice — frozen after 035; later tasks consume.
- `/action` arrangement verbs — fixed in 037; the view calls, doesn't redefine.
- Arranger built from `src/arranger/*` via the build → drift-guard stays green.

## Per-node testing + harness UAT
| Task | Tests | Harness UAT |
|------|-------|-------------|
| 035 | schema validates dual-deck + breaks-n-beats examples; /arrangement sample validates | examples pass in setforge-test |
| 036 | mocha: place 2×4 stems @ bar, overwrite-at-position, manifest save→load round-trip (mock LiveAPI) | arranger e2e green |
| 037 | pytest: each new /action emits right command (mock sink); /arrangement slice served | action round-trips asserted |
| 038 | jsdom: Arrangement view renders placements + scene markers; new actions fire; scene-from-Curate appears | view renders vs sample /arrangement |
| 039 | end-to-end: serve.py(sample) → render Arrangement → place_pair/save/load vs mock → assert manifest + timeline | new `arrangement` stage green in setforge-test |

## Acceptance (phase, headless-complete)
Arranger places 2 decks @ a timeline point + saves/loads a manifest (mocked LiveAPI); Arrangement view renders dual-deck timeline + scenes-as-markers; new `/action` verbs round-trip; full headless UAT + setforge-test (with arrangement stage) green. **Gated for zak:** pack `setforge-arranger.amxd` + live aural/visual placement on the real timeline; real-audio rendering.
