# Phase 3 — Arrangement & Production: Implementation Spec

**Status:** spec (2026-06-11) · scope = PRD Phase 3 items **3.2–3.4** · **3.1 (refined-preset editing) stays DEFERRED** per the locked product call ("almost cheating / maybe never; do NOT build now"). Product intent: `~/zacharysbrown/maad_traash_muzak/mtm/Setforge-Product-Definition.md`.

## 0. North star
Production mode = arranged mashups/remixes on Ableton's **arrangement timeline** (vs Performance's session view). You drop **two songs' stems at a timeline point**, audition the pair, and your vetted **scenes** (clip pairings from Curate) show up *on the timeline* so a set's structure is visible and reusable. The arranger device + the companion's Arrangement view are the two surfaces.

## 1. Scope (what ships this phase)
- **3.2 Arrangement-loader dual-deck parity** — load **2 tracks (deck A + B) at a timeline position**, overwriting at that position; audition the pair in arrangement view. Reuse the always-dual model + per-stem tracks from the session loader.
- **3.3 Arranged-set** — an **8-track bank (two songs × 4 stems) placed at a timeline point**; save/restore an **arrangement-view manifest** (`arrangement_manifest`, schema already exists: `schemas/arrangement.schema.json` — `schema_version, bpm, first_downbeat_sec, forge_slug, manifest_hash, source_audio, chunks`).
- **3.4 Scenes on the arrangement timeline** — render the **vetted scenes** (from Curate's scene store, Phase-2) as markers/regions on the timeline; cross-link Curate ↔ Arrangement so a scene tagged in Curate appears here.

**Deferred (not this phase):** 3.1 refined-preset editing (delete/move/re-slot clips, warp materialization); native-Ableton persistence.

## 2. Architecture & seams
Two surfaces, one manifest contract:
- **Arranger device** (`device/setforge-live/src/arranger/`: `arranger-main.js`, `sf_arrangement_loader.js`, `sf_arrangement_reader.js`; packed `setforge-arranger.amxd`). Owns: place 2 decks × 4 stems at a timeline position via LiveAPI; read/write the arrangement manifest. **Mirror the session loader's patterns** (HFS→POSIX path fix, `stemTrackIdsX/Y`, guarded LiveAPI, the build-from-src + drift-guard + AMXD verifiers).
- **Companion Arrangement view** (new `app/render/arrangement.js`, third tab) — productionize `docs/mockups/arrangement-view.html`: dual-deck timeline, clips colored by source song, **vetted scenes on the timeline**, song locators, "load 2 tracks @ playhead". Reads a new `/arrangement` state slice; actions via the existing `POST /action` vocabulary (extended).
- **Manifest = the seam.** `arrangement.schema.json` (extend if needed for scene markers + dual-deck placement) is the contract between the arranger device and the companion view, exactly as `stems.json`/state are for session.

## 3. Data contract additions
- **Arrangement state** (companion): extend `/state` (or a sibling `GET /arrangement`) with `arrangement: { bpm, length_bars, decks:{A,B}, placements:[{deck,stem,clip_id,start_bar,len_bars,source,color}], scene_markers:[{scene_id,name,color,start_bar}] , playhead_bar }`. Add to `state.schema.json` (v2.x, additive).
- **arrangement_manifest** (device save/restore): extend `arrangement.schema.json` if needed for dual-deck placements + scene markers; keep backward-compatible (`additionalProperties:true`).
- **Actions** (extend the frozen `/action` vocab from Phase 2): `place_pair{timeline_bar}` (load 2 tracks @ position), `save_arrangement{name}`, `load_arrangement{name}`, `seek_bar{bar}`. Same injectable command-sink pattern → arranger device / AbletonOSC.

## 4. Headless vs gated (same discipline as Phase 1/2)
**Headless-now (build + test without Live/hardware):**
- Arranger dual-deck placement *logic* + manifest read/write (synthetic, mocked LiveAPI sink) — like the session loader's e2e.
- Arrangement manifest schema + validator + examples.
- Companion Arrangement view render fns (pure, jsdom-tested) + scene-marker layout + the new `/action` types (mock-tested) + the `/arrangement` state slice (sample data).
**Gated (needs zak / Max / Live):**
- Packing + aural/visual check of `setforge-arranger.amxd` in Live (placing real clips on the real timeline).
- Real-audio waveform/locator rendering.

## 5. Testing + harness UAT
- **JS device e2e** (mocha): arranger places 2 decks × 4 stems at a bar; overwrite-at-position; manifest round-trips (save→load equals). Mocked LiveAPI.
- **Schema** (pytest): extended arrangement manifest validates the `breaks-n-beats` example + a dual-deck example; malformed fails.
- **Companion** (node/jsdom): Arrangement view renders placements + scene markers from sample `/arrangement`; the new `/action` types fire correct commands (mock sink); scene tagged in Curate appears on the timeline.
- **Drift + guards:** keep L0 drift-guard green (arranger built from src); the class-coverage + init-render guards (cc-033) cover the new view.
- **End-to-end headless UAT:** boot serve.py(sample) → render Arrangement → fire `place_pair`/`save_arrangement` vs mock → assert manifest + timeline. New `arrangement` stage in `setforge-test.sh`.
- **Live smoke** (gated): zak places a pair on the real timeline + aural check.

## 6. Acceptance (phase, headless-complete)
Arranger places 2 decks @ a timeline point (logic + mocked LiveAPI), saves/loads an arrangement manifest; companion Arrangement view renders the dual-deck timeline with clips-by-source-color + vetted scenes as markers; new `/action` types round-trip; full headless UAT + setforge-test (incl. new arrangement stage) green. Only the live aural/visual pass remains for zak.
