# Setforge Ecosystem — Feature Inventory & Test Harness Spec

**Date:** 2026-06-08
**Scope:** taste (Python curation) + m4l-devices (Max for Live) + stemforge (stem separation)
**Purpose:** Exhaustive feature catalog with automation requirements for integration testing.

---

## How to read this document

Each feature has:
- **Feature ID** — unique, traceable across the UAT plan
- **Mode** — Curation / Performance / Arrangement / Calibration / Cross-cutting
- **Status** — Implemented / Partial / Stub / Not implemented
- **Automation approach** — how to test automatically (UDP, LiveAPI, file system, etc.)
- **Current test coverage** — what exists today
- **Automation blockers** — what cannot be automated and why

UDP ports: 7422 (loader), 7423 (arranger). CC remote: loader responds to MIDI CCs 100-108.

---

## A. Curation Mode (taste)

### A1. forge-set YAML Parsing

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-01 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Parse a YAML file defining a set (name, global_tempo, strategy, tracks with artist/title/file or track_id). Validate that each track has either a `file` path or `track_id`. Auto-derive artist/title from filename if missing (split on " - "). Support step presets (`all`, `prep`, `curate`, `export`) and comma-separated step lists. |
| **Setup requirements** | Python environment with `pyyaml`. taste DB initialized (`python3 -m taste init`). |
| **Inputs** | YAML file path, optional `--steps` argument, optional `--force` flag, optional `--mode` (session/arrangement/both). |
| **Expected outputs** | Parsed dict with validated tracks list. Exit with error on missing file, missing tracks key, unknown step name. |
| **Automation approach** | Pure Python unit test — no Live required. Call `load_set_yaml()` and `parse_steps()` directly. Check filesystem state for output files. |
| **Current test coverage** | None in taste/tests/. |
| **Automation blockers** | None — fully automatable. |

### A2. Track Registration (Spotify Lookup + Local File Linking)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-02 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Three registration paths: (1) explicit `track_id` in YAML — verify DB row exists; (2) file-based — find by `local_path` exact match, then fuzzy artist/title match (rapidfuzz token_sort_ratio >= 88), or register new via Spotify then local-only; (3) backfill artist/title from DB for track_id entries. Also checks `~/.cache/setforge/audio/{id}.mp3` cache. |
| **Setup requirements** | taste DB with tracks table. Spotify env vars (SPOTIPY_CLIENT_ID/SECRET/REFRESH_TOKEN) for Spotify path. |
| **Inputs** | Track dict with `file` or `track_id`, DB connection. |
| **Expected outputs** | DB row ID for each track. Tracks table updated with local_path, source. |
| **Automation approach** | Python unit test with in-memory SQLite. Mock Spotify API. Test all three paths plus fuzzy matching edge cases. |
| **Current test coverage** | None. |
| **Automation blockers** | Live Spotify API for real integration test (mockable for unit). |

### A3. Audio Analysis (Tempo, Key, Groove, Vocal)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-03 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Compute tempo (octave-corrected), key (Camelot wheel), groove (pulse regularity, swing, syncopation, onset rate), vocal (presence, syllable rate, pitch variance), timbre (spectral centroid, RMS, MFCC). Stores results in DB `tracks` table with `analyzed_at` timestamp. Resumable — skips tracks with existing `analyzed_at` unless `--force`. |
| **Setup requirements** | librosa, numpy, soundfile. Audio file on disk. |
| **Inputs** | Audio file path. |
| **Expected outputs** | Feature dict stored in DB. Fields include `tempo`, `camelot`, groove metrics, vocal metrics, timbre metrics. |
| **Automation approach** | Python unit test with synthetic audio fixtures. Test `analyze_track()` directly. |
| **Current test coverage** | `test_rhythm_analysis.py` (groove/rhythm features), `test_phrase_analysis.py` (phrase analysis). |
| **Automation blockers** | None — fully automatable with synthetic audio. |

### A4. Stem Separation (Demucs)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-04 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Run Demucs stem separation producing 4 stems: drums.wav, bass.wav, other.wav, vocals.wav. Cached at `~/.cache/setforge/stems/{track_id}/`. Stores `stem_bpm` and `stem_downbeat` in DB. Resumable — skips if stems exist unless `--force`. |
| **Setup requirements** | stemforge installed (demucs backend). GPU recommended (~5-10 min/track on CPU). |
| **Inputs** | Audio file path, output directory. |
| **Expected outputs** | 4 WAV files in stem cache. DB updated with stem_bpm, stem_downbeat. |
| **Automation approach** | Integration test with short synthetic audio. Test `stem_track()` + `locate_stems()`. Mock demucs for fast unit tests. |
| **Current test coverage** | None in taste tests (stemforge has its own tests). |
| **Automation blockers** | Slow on CPU. Requires demucs model download (~1.5GB). |

### A5. Structure Analysis (Bar Grid Detection)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-05 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Three-phase structure analysis: (1) `analyze_structure` — beat-this bar grid detection from full mix; (2) `build_bar_grid` — construct bar grid from detected beats, using drum stem if available for higher fidelity; (3) stores `BarGrid` (bar_starts, global_bpm, first_downbeat) in analysis_cache/{track_id}/bar_grid.json. |
| **Setup requirements** | beat-this model, librosa, analysis_cache directory. |
| **Inputs** | Audio file, track_id, reference BPM, optional drum stem path. |
| **Expected outputs** | bar_grid.json with bar_starts array, global_bpm, first_downbeat. |
| **Automation approach** | Python unit test with synthetic audio at known BPM. |
| **Current test coverage** | None directly (indirectly tested via chop curator tests). |
| **Automation blockers** | beat-this model required. |

### A6. Chop Curation (8 Chops per Stem, Structure-Aware)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-06 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Select 8 representative 4-bar chop regions per stem from the bar grid. Strategy-aware (`hiphop`, `idm`, `jazz`, `mashup`, `default`) — each strategy biases chop selection differently (e.g. hiphop favors verse/chorus boundaries, idm favors textural variety). Writes curated chop metadata to manifest. |
| **Setup requirements** | Bar grid computed. Strategy determined (explicit or inferred from tags). |
| **Inputs** | Audio file, track_id, BPM, strategy name. |
| **Expected outputs** | Per-stem chop metadata (8 chops each with bar range, column assignment). |
| **Automation approach** | Python unit test — `curate_all_stems()` with fixture bar grids. |
| **Current test coverage** | `test_chop_curator.py`, `test_strategies.py`. |
| **Automation blockers** | None. |

### A7. Chop Materialization (Crop WAVs with Padding)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-07 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Crop individual WAV files for each curated chop from the full stem. Chops stored at `~/.cache/setforge/chops/` and referenced by the manifest. Each chop WAV is a 4-bar excerpt of the source stem. |
| **Setup requirements** | Curated chop metadata from CUR-06. Stem WAVs from CUR-04. |
| **Inputs** | Manifest directory, track_ids list, force flag. |
| **Expected outputs** | Individual WAV files per chop. Manifest updated with `chop_path` fields. |
| **Automation approach** | Python integration test — verify WAV files written at expected paths with correct duration. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

### A8. Vocal Warp Grid Export (reconciled_continuity Mode)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-08 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Export full vocal stem with Ableton-compatible warp markers. Copies vocal WAV to output dir, writes .asd sidecar with warp markers at every beat position. `reconciled_continuity` mode: builds reconciled grid from detected bar positions, fixes bar count and coverage, uses onset detection from drum stem to fill missed bars. Returns bar_markers array for the set manifest. |
| **Setup requirements** | Bar grid computed. Vocal stem exists. Optional drum stem for onset candidates. |
| **Inputs** | track_id, output_dir, manifest_bpm, grid_mode. |
| **Expected outputs** | `{track_id}_vocals.wav` (renamed to `vocals.wav`), `.asd` sidecar, bar_markers array. |
| **Automation approach** | Python test — call `export_vocal_stem()`, verify .asd written and marker count. |
| **Current test coverage** | `test_export_vocal_delivery.py` (partial — tests vocal delivery metrics, not full export). |
| **Automation blockers** | None for file generation. Audible verification requires Ableton playback. |

### A9. Prechop for Arrangement (BPM-Fixed Grid, Intro Chunks)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-09 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Slice full-song stem WAVs into N-bar chunks (default 4 bars) with padding bars on either side. Grid anchored on `first_downbeat_sec`, spaced by exact BPM-derived frame counts. Each chunk records `loop_start_sec` / `loop_end_sec` for arrangement-view clip loop regions. Pre-downbeat audio emitted as intro chunks with `bar_position < 0`. Leading partial chunk left-padded with silence to maintain bar alignment. |
| **Setup requirements** | Stem WAVs, bar grid, BPM. |
| **Inputs** | stem_paths dict, bar_starts, bpm, output_dir, chunk_bars, pad_bars, first_downbeat_sec. |
| **Expected outputs** | Chunk WAV files in `{stem_name}_prechop/` subdirs. `prechop_manifest.json` with flat chunks[] array. |
| **Automation approach** | Python unit test — `prechop_stem()` and `prechop_track()` with synthetic audio. Verify chunk count, file sizes, loop region correctness. |
| **Current test coverage** | `test_prechop.py`. |
| **Automation blockers** | None. |

### A10. Set Export (set.json + manifest.json, Portable Relative Paths)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-10 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Assemble the final set: (1) compute global_tempo from track tempos if not specified; (2) build preset_bank_A/B (8 slots each, null-filled); (3) write set.json with schema_version, name, global_tempo, banks, setlist; (4) export vocal warp grids; (5) copy chop WAVs into output dir with relative paths; (6) write combined manifest.json (schema 2.1) with all tracks. Vocal stems get `mode: "full_stem"` with `warp_grid` array instead of individual chops. |
| **Setup requirements** | All prior steps complete. |
| **Inputs** | Set YAML data, DB connection, output directory. |
| **Expected outputs** | `{name}.set.json`, `{name}.manifest.json`, per-track subdirs with chops and vocal stems. All paths relative. |
| **Automation approach** | Python integration test — run full pipeline on fixture, verify output file structure and JSON schemas. |
| **Current test coverage** | None. |
| **Automation blockers** | None for file generation. |

### A11. Recommendation Engine (Transition/Mashup Scoring)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-11 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | Score candidate tracks against seed tracks across 6 dimensions: tempo (octave-corrected), key (Camelot), groove, vocal, timbre, taste (playlist co-occurrence). Two modes: `transition` (favors compatible tempo + key for smooth mixing) and `mashup` (favors similar groove + vocal for simultaneous layering, with optional `--tempo-lock`). |
| **Setup requirements** | taste DB with analyzed tracks. |
| **Inputs** | Seed track IDs, mode, limit. |
| **Expected outputs** | Ranked list of candidate tracks with per-dimension scores. |
| **Automation approach** | Python test with fixture DB containing analyzed tracks. |
| **Current test coverage** | `test_audit_scorer.py` (partial — audit scorer, not full recommend). |
| **Automation blockers** | None. |

### A12. Recommendation Popup (React UI + rec_server)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-12 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | HTTP server (port 7450, configurable via TASTE_REC_PORT) serving a React popup UI. API routes: `/api/recommend` (POST, seeds + mode + limit), `/api/tracks` (GET, list analyzed tracks), `/api/search` (GET, query by artist/title). Writes port file at `~/stemforge/.rec_server_port` for device discovery. |
| **Setup requirements** | taste DB, popup/dist/ static build. |
| **Inputs** | HTTP requests. |
| **Expected outputs** | JSON responses with track/recommendation data. |
| **Automation approach** | Python test — start server, hit API endpoints, verify JSON responses. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

### A13. Cross-Machine Sync (rsync Stems/Chops/DB)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-13 |
| **Mode** | Cross-cutting |
| **Status** | Implemented |
| **Description** | rsync wrapper syncing 6 items between M2 MacBook and Intel Mini: stems cache, chops cache, audio cache, taste DB, analysis_cache, sets cache. Supports push (local to remote) and pull (remote to local) with `--dry-run`. Excludes .pyc, __pycache__, .DS_Store. |
| **Setup requirements** | SSH access to `zak@mini`. rsync installed. |
| **Inputs** | `--pull` or default push, `--dry-run`. |
| **Expected outputs** | Synced files on target machine. |
| **Automation approach** | Shell test with mock rsync or dry-run verification. |
| **Current test coverage** | None. |
| **Automation blockers** | Requires SSH to remote machine for real test. Dry-run testable locally. |

### A14. track_id YAML Support (Existing DB Rows)

| Field | Value |
|-------|-------|
| **Feature ID** | CUR-14 |
| **Mode** | Curation |
| **Status** | Implemented |
| **Description** | YAML tracks can specify `track_id: <int>` instead of `file:` to reference an existing DB row. The register step verifies the ID exists, backfills artist/title from DB, and checks the audio cache at `~/.cache/setforge/audio/{id}.mp3` if no file is specified. |
| **Setup requirements** | taste DB with existing track rows. |
| **Inputs** | YAML with `track_id` entries. |
| **Expected outputs** | Resolved track IDs, backfilled metadata. |
| **Automation approach** | Python unit test with fixture DB. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

---

## B. Live Performance Mode (setforge-loader + grid)

### B1. Set Loading (Browse, Load set.json)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-01 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Load a `.set.json` file: parse JSON, populate 16 preset slots (bank A slots 0-7, bank B slots 8-15) from preset_bank_A/B arrays. Read combined manifest for track metadata (bpm, downbeat_sec, stems, chops, energy, genre, color). Create audio clips on hidden stem tracks (sf-drums, sf-bass, sf-other, sf-vox) for each loaded preset. Persist last-loaded path to `/tmp/setforge_last_set.txt` for autowatch reload. |
| **Setup requirements** | setforge-loader.amxd on an audio track. Stem tracks created (or auto-created). set.json + manifest.json on disk. |
| **Inputs** | File path to set.json (via device browse UI or UDP command). |
| **Expected outputs** | Preset slots populated, clips created on stem tracks, pad colors updated, status display shows set info. |
| **Automation approach** | **UDP** (port 7422): send `load <path>` command. **LiveAPI test harness**: verify track count, clip presence, clip properties via mock-live-api. **File system**: check `/tmp/setforge_last_set.txt`. **Max console**: check for error/success posts. |
| **Current test coverage** | `loader-e2e.test.js` (loads built monolith, tests load/status/eject). `load-set.test.js` (modular imports — NOT deployed code). |
| **Automation blockers** | Full audio verification requires Live playback. |

### B2. Clip Creation (create_audio_clip on Stem Tracks)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-02 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | For each preset, create 8 audio clips per stem (32 total) on dedicated stem tracks. Clip start_marker derived from chop math: `downbeat_sec + (bar_index * 4 * 60 / bpm)`. Clips use curated chop regions when available; otherwise fall back to BPM-grid 4-bar windows. Per-row launch quantization set at clip creation: drums 1/16, bass 1 bar, other 1/4, vox 1/2. |
| **Setup requirements** | Set loaded (PERF-01). Stem WAV files accessible. |
| **Inputs** | Preset activation (tap preset pad). |
| **Expected outputs** | Audio clips created with correct start_marker, end_marker, launch_quantization. |
| **Automation approach** | **LiveAPI harness**: query clip_slots for clip properties (start_marker, end_marker, launch_quantization, file_path). **UDP**: trigger preset activation, then query clip state. |
| **Current test coverage** | `chop-trigger.test.js` (modular), `loader-e2e.test.js` (chop trigger/replace/stop). Unit: `chop-math.test.js`. |
| **Automation blockers** | None for clip property verification. Audio content verification needs playback. |

### B3. Vocal Warp Grid Application (writeVocalWarpGrid)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-03 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | For vocal stems with `mode: "full_stem"`, apply the warp_grid array as warp markers on the vocal clip. Each marker maps a sample position to a beat position, aligning the vocal's musical timing to the global tempo grid. The vocal plays as one continuous clip (not chopped) with warp markers maintaining phrase alignment. |
| **Setup requirements** | Vocal stem WAV with .asd sidecar containing warp markers. Manifest with `stems.vox.warp_grid` array. |
| **Inputs** | Preset activation with full_stem vocal. |
| **Expected outputs** | Warp markers applied to vocal clip. Clip warping enabled. |
| **Automation approach** | **LiveAPI harness**: query clip warp_markers property after preset activation. **UDP**: trigger load, then inspect. |
| **Current test coverage** | `full-vocal.test.js` (integration, import target unconfirmed). |
| **Automation blockers** | Audible alignment verification requires playback + ears. |

### B4. Preset Activation (Bank A: A1-A8, Bank B: B1-B8)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-04 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Tap a preset pad (row 5 bank A, row 6 bank B) to make it active. First activation: load clips. Subsequent: hot-swap (PERF-08). Active preset lights bright with palette color, others dim. Status display updates with preset name/tempo. Dual slot-set staging model: ACTIVE set alternates between slots 0-7 and 8-15 for gapless swaps. |
| **Setup requirements** | Set loaded. |
| **Inputs** | MIDI note-on for preset pad (row 5/6). |
| **Expected outputs** | activeSlotIndex updated, clips loaded/swapped, pad colors reflect active/idle states, status updated. |
| **Automation approach** | **UDP**: send MIDI note for preset pad. **LiveAPI harness**: verify activeSlotIndex, clip state. **Max console**: status text. |
| **Current test coverage** | `loader-e2e.test.js` (preset activation). `preset-swap.test.js` (modular). |
| **Automation blockers** | None for state verification. |

### B5. Chop Triggering (Pad Press -> Clip Fire)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-05 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Tap a chop pad (rows 1-4) to launch/stop/replace a clip. Toggle: if not playing, schedule start at next quant boundary. If playing, stop. Tap while another chop in same row plays: replace at boundary (no overlap, no gap). One chop per stem row maximum. Pad lights bright when playing, soft when idle. |
| **Setup requirements** | Preset active with loaded chops. |
| **Inputs** | MIDI note-on for stem row pad. |
| **Expected outputs** | Clip launched/stopped on correct stem track. playingChops state updated. Pad color changes. |
| **Automation approach** | **UDP**: send MIDI note, query playingChops state or clip playing status. **LiveAPI**: check clip is_playing. **LED verification**: capture RGB writes from surface. |
| **Current test coverage** | `loader-e2e.test.js` (chop trigger/replace/stop). `chop-trigger.test.js` (modular). |
| **Automation blockers** | None for clip state. Audio timing verification needs real transport. |

### B6. Modifier Layer (HOLD, MUTE, SOLO, REV, STUT, HALF, DBL, KILL)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-06 |
| **Mode** | Performance |
| **Status** | Partial (2 of 8 functional) |
| **Description** | Row 7 modifier pads. Gesture engine: momentary press/release, double-tap (<400ms) latches (yellow), tap latched to release. No mutual exclusion — multiple can be latched. **HOLD (col 1)**: PARTIAL — real role is SHIFT: preset-no-migrate + scene-save. One-shot NOT implemented. **SOLO (col 3)**: per-row mode toggle (NOT stem solo). **MUTE, REV, STUT, HALF, DBL, KILL (cols 2,4,5,6,7,8)**: INERT STUBS — visual/state only, zero audio effect. |
| **Setup requirements** | Set loaded, preset active. |
| **Inputs** | MIDI note-on/off for row 7 pads. |
| **Expected outputs** | modState updated (idle/held/latched). HOLD+preset = no-migrate swap. SOLO double-tap = per-row toggle. Others: visual only. |
| **Automation approach** | **UDP**: send modifier MIDI + verify modState. **LiveAPI harness**: verify HOLD changes preset swap behavior, SOLO toggles performanceView. **LED**: verify color changes (idle=dim white, held=bright white, latched=yellow). |
| **Current test coverage** | `loader-e2e.test.js` (modifier test). `modifier-layer.test.js` (unit, modular — NOT deployed code). |
| **Automation blockers** | Audio effects for the 6 stubs are not implemented — nothing to test. |

### B7. Scene Memory (Save/Recall 8 Snapshots)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-07 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Row 8 scene pads. Tap: recall scene (restore active preset, held chops, modifier latch state, view mode, rowSources). HOLD+tap: save current state to scene slot. Scene data captures: view (solo/perRow/dualSong/control), activePreset or rowSources, staging deckX/Y, heldChops with source presets. Scene recall restores view including dual-song mode. Empty scenes render off, built = dim purple, last-recalled = bright purple. |
| **Setup requirements** | Set loaded, preset active. |
| **Inputs** | MIDI note-on for row 8 pad. HOLD modifier for save gesture. |
| **Expected outputs** | On save: scene slot populated with full state snapshot. On recall: state restored (preset, chops, modifiers, view). |
| **Automation approach** | **UDP**: trigger save (HOLD+scene pad), then eject/reload and trigger recall, verify state matches. **LiveAPI harness**: compare pre-save and post-recall state objects. |
| **Current test coverage** | `loader-e2e.test.js` (scene save+recall). `scene-recall.test.js`, `scene-memory.test.js` (modular). |
| **Automation blockers** | None for state verification. |

### B8. Per-Row Mode (Double-Tap SOLO, Cross-Song Mashup)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-08 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Double-tap SOLO (row 7 col 3) to enter/exit per-row mode. Each stem row sources chops from its own preset (rowSources.drums/bass/other/vox). Reassignment gesture: hold chop pad in stem row + tap preset pad = reassign that row's source. Multiple held rows reassign together. Assignment immediate (Live's clip-launch quant applies). Col-1 source indicator: leftmost pad tinted with source preset's palette color (suppressed when col-1 chop is playing). Exit returns active preset to drums row's source. |
| **Setup requirements** | Multiple presets loaded in set. |
| **Inputs** | MIDI: double-tap SOLO, then hold-chop + tap-preset for reassignment. |
| **Expected outputs** | performanceView = "perRow", rowSources populated, clips load from per-row sources, col-1 color tint visible. |
| **Automation approach** | **UDP**: send SOLO double-tap, verify performanceView. Send hold+preset sequence, verify rowSources. **LiveAPI**: verify clips loaded from correct preset per row. |
| **Current test coverage** | `multi-song-modes.test.js` (modular — NOT deployed). `loader-e2e.test.js` does NOT cover per-row. |
| **Automation blockers** | None for state/clip verification. |

### B9. Dual-Song Mode (Deck X + Deck Y, 8 Independent Voices)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-09 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Top-right side button (note 89): hold = momentary peek, double-tap = latch. All 8 rows become stems: rows 1-4 = deck X (4 stems), rows 5-8 = deck Y (4 stems). 8 simultaneous voices possible. Decks resolved from staging (PERF-10) with fallback to last-active bank A/B preset. Entry refused if no decks resolvable (red blink on toggle). Per-row launch quant maintained per stem type. Modifiers/scenes unavailable during dual-song. PANIC exits to solo. |
| **Setup requirements** | Decks staged (PERF-10) or presets previously activated on both banks. |
| **Inputs** | MIDI: side button note 89 (hold or double-tap). Chop pads for stem triggering. |
| **Expected outputs** | dualSongActive = true, grid repainted with X/Y stems, chops playable from both decks simultaneously. |
| **Automation approach** | **UDP**: send side button note, verify dualSongActive. Send chop pads in rows 1-4 and 5-8, verify clips fire on correct deck tracks (sf-{stem}-x / sf-{stem}-y). |
| **Current test coverage** | `loader-e2e.test.js` does NOT cover dual-song. `multi-song-modes.test.js` (modular — NOT deployed). |
| **Automation blockers** | 8-voice audio verification requires playback. |

### B10. Staging / Hot-Swap (Pre-Load Next Song)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-10 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Hold deck-setup side button (note 79, bright white while held) to enter staging mode. While held: tap row 5 preset = stage to deck X, tap row 6 = deck Y. Pre-loading: clips created synchronously on dedicated X/Y tracks immediately on stage. Deferred warp-marker fix via 4000ms Task. Visual: staged pads flash two colors (deck X: preset color <-> white, deck Y: preset color <-> soft blue) using MK2 native SysEx flash. Empty slot stage attempt: red flash, no assignment. |
| **Setup requirements** | Set loaded with presets on both banks. |
| **Inputs** | MIDI: hold note 79, then tap preset pad on row 5 or 6. |
| **Expected outputs** | staging.deckX/Y set, loadedDecks populated, clips on X/Y tracks, visual flash on staged pads. |
| **Automation approach** | **UDP**: send hold+preset sequence, verify staging state. **LiveAPI**: verify clips on sf-{stem}-x/y tracks. **LED**: capture flash SysEx. |
| **Current test coverage** | None against deployed code. |
| **Automation blockers** | Flash SysEx verification requires MIDI capture or surface mock. |

### B11. Curation Persistence (Save/Reload Preserves Edits)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-11 |
| **Mode** | Performance |
| **Status** | Implemented (FIXED 2026-05-31) |
| **Description** | Save command writes current manifest state to disk (per-clip column assignments, moved clips). Reload re-reads saved set from disk, honoring saved per-clip `column` so moved clips restore to their slot. Full_stem vocals restore saved chop regions. Auto-save on eject (commented out in current code). |
| **Setup requirements** | Set loaded, edits made (chop moves, etc.). |
| **Inputs** | UDP/CC: `save` (CC 100), `reload` (CC 105). |
| **Expected outputs** | JSON written to disk on save. On reload: state matches saved state. |
| **Automation approach** | **UDP**: save, modify state, reload, verify state restored. **File system**: verify JSON file contents. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

### B12. Launchpad MK2 Surface (RGB, SysEx, Programmer Mode)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-12 |
| **Mode** | Performance |
| **Status** | Implemented (primary surface) |
| **Description** | Full MK2 SysEx implementation: programmer mode enter (F0 00 20 29 02 10 2C 03 F7) prepended before every grid flush. RGB write (header F0 00 20 29 02 10 0B, chunked to 70 pads per SysEx). Flash SysEx for staging indicators. Pad note mapping: lpRow*10 + lpCol, flipped vertically (row 1 = top = LP row 8). 7-bit RGB (0-127). Leave programmer mode defined but never called. |
| **Setup requirements** | Launchpad MK2 connected via USB. MIDI track configured: input/output to Launchpad Standalone Port, monitor In, arm on. |
| **Inputs** | MIDI note-on/off from Launchpad pads and side buttons. |
| **Expected outputs** | SysEx RGB writes to Launchpad. Correct pad-to-note mapping. |
| **Automation approach** | **Mock Launchpad (harness)**: `mock-launchpad.js` records RGB writes and emits scripted MIDI. Tests assert on recorded RGB sequences. **MIDI capture**: capture SysEx output for byte-level verification. |
| **Current test coverage** | `mock-launchpad.js` exists in harness. Used by integration tests. |
| **Automation blockers** | Hardware verification requires physical Launchpad. |

### B13. Launchpad MK3 Surface (Partial)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-13 |
| **Mode** | Performance |
| **Status** | Partial (concatenated but dead in deployment) |
| **Description** | MK3 surface code is concatenated into the built monolith but never activated — `createSurface("mk2")` is hardcoded. Pulse SysEx defined (`buildPulseSysex`) but has no call sites. The MK3 surface would support pulse (breathing) and flash with different SysEx headers. |
| **Setup requirements** | N/A (not deployed). |
| **Inputs** | N/A. |
| **Expected outputs** | N/A. |
| **Automation approach** | N/A until MK3 is activated. |
| **Current test coverage** | None. |
| **Automation blockers** | Feature not deployed. |

### B14. Grid MIDI Bridge (setforge-grid.amxd)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-14 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | setforge-grid.amxd is a MIDI device placed on a MIDI track configured for Launchpad I/O. It bridges MIDI from the Launchpad to the loader device via Max send/receive buses. The MIDI track must have: input = Launchpad (Standalone Port), output = Launchpad (Standalone Port), monitor = In, arm = on. |
| **Setup requirements** | MIDI track in Live, Launchpad connected. |
| **Inputs** | MIDI from Launchpad. |
| **Expected outputs** | MIDI forwarded to loader via send/receive. SysEx from loader forwarded to Launchpad. |
| **Automation approach** | **LiveAPI**: verify MIDI track routing configuration. **Mock MIDI**: inject note-on, verify it arrives at loader. |
| **Current test coverage** | None. |
| **Automation blockers** | Requires Live session with correct track routing. |

### B15. MIDI Track Configuration (Arm, Monitor=In, I/O)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-15 |
| **Mode** | Performance |
| **Status** | Manual setup required |
| **Description** | The Launchpad MIDI track must be configured: input from Launchpad MK2 (Standalone Port), output to Launchpad MK2 (Standalone Port), monitoring = In, armed = on. This is currently a manual step per the install.sh instructions. |
| **Setup requirements** | Ableton Live, Launchpad connected. |
| **Inputs** | Manual configuration. |
| **Expected outputs** | Correctly routed MIDI track. |
| **Automation approach** | **LiveAPI**: script to verify/set track.input_routing, track.output_routing, track.current_monitoring_state, track.arm. |
| **Current test coverage** | None. |
| **Automation blockers** | None — LiveAPI can verify this. |

### B16. Panic (Stop All, Clear Modifiers, Bypass FX)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-16 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Triple-tap PANIC within 1000ms window. Two entry sites: left side button note 10, or transport row col 8 (both share global tap counter). CC 103 bypasses tap-count guard (fires directly). `executePanic()`: stops all chops, clears all modifier latches, bypasses FX state, stops all clips, reverts to solo mode, clears rowSources and dualSongPlaying. Does NOT reset: viewMode (control overlay persists), staging (deckX/Y survive), activeSlotIndex. |
| **Setup requirements** | Device loaded. |
| **Inputs** | Triple-tap MIDI note 10 or row 8 col 8. Or CC 103. |
| **Expected outputs** | All audio stopped. All modifiers idle. performanceView = "solo". dualSongActive = false. Grid repainted to idle state. |
| **Automation approach** | **UDP/CC**: send CC 103 for direct panic. Verify all state cleared via status query. **LiveAPI**: verify no clips playing. **LED**: verify idle pad colors. |
| **Current test coverage** | `loader-e2e.test.js` (panic test). `panic.test.js` (modular). |
| **Automation blockers** | None. |

### B17. Eject (Clear Everything, Reset State)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-17 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Eject command: stops all clips, clears all preset slots, returns pads to idle state. Does NOT power-cycle Launchpad. Triggered via CC 104 or device UI button. |
| **Setup requirements** | Set loaded. |
| **Inputs** | CC 104 or device UI. |
| **Expected outputs** | All state cleared, pads return to idle/off. |
| **Automation approach** | **UDP/CC**: send CC 104, verify state cleared. |
| **Current test coverage** | `loader-e2e.test.js` (eject test). |
| **Automation blockers** | None. |

### B18. Reload (Re-Read from Disk)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-18 |
| **Mode** | Performance |
| **Status** | Implemented (FIXED 2026-05-31) |
| **Description** | Reload command: re-reads saved set from disk. Preserves saved per-clip column assignments. Full_stem vocals restore saved chop regions. Triggered via CC 105. |
| **Setup requirements** | Set loaded, modifications saved. |
| **Inputs** | CC 105. |
| **Expected outputs** | State refreshed from disk. Saved edits preserved. |
| **Automation approach** | **UDP/CC**: send CC 105, verify state matches saved file. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

### B19. Sync from Live (Read Clip State Back)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-19 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Sync command (CC 101): read clip state from Live's audio tracks back into the manifest. Guards against empty wipe — if totalLive === 0 across all stems, abort with "sync ABORTED — refusing to wipe". Updates manifest with current clip positions. |
| **Setup requirements** | Set loaded with clips on tracks. |
| **Inputs** | CC 101. |
| **Expected outputs** | Manifest updated with Live's clip positions. Guard prevents accidental wipe. |
| **Automation approach** | **UDP/CC**: send CC 101, verify manifest updated. Test guard: create state with no clips, send sync, verify abort. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

### B20. UDP Command Interface (Port 7422)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-20 |
| **Mode** | Performance |
| **Status** | Implemented (via CC remote + file poll) |
| **Description** | The loader accepts remote commands via MIDI CCs (100-108) mapped to: save, sync, inspect, panic, eject, reload, debug, save_manifest, save_set. A legacy file-based poll (`/tmp/setforge_cmd.txt`) also exists but is superseded by CC path. CC 103 (panic) bypasses triple-tap guard. |
| **Setup requirements** | Loader device loaded in Live. MIDI CC source configured. |
| **Inputs** | MIDI CC messages on the mapped CC numbers. |
| **Expected outputs** | Command executed (same as pressing the corresponding UI button). |
| **Automation approach** | **MIDI CC**: send CC messages programmatically via Python MIDI library or Max [ctlout]. Verify responses via Max console or state queries. |
| **Current test coverage** | None specifically for remote CC path. |
| **Automation blockers** | None — CC injection is straightforward. |

### B21. Status Display (Bank, Preset, Scene, Tempo)

| Field | Value |
|-------|-------|
| **Feature ID** | PERF-21 |
| **Mode** | Performance |
| **Status** | Implemented |
| **Description** | Device front panel shows: bank A/B track names, active preset, active scene, Launchpad connection status, global tempo, drift since load. Updated on every state change. Status output via outlet to live.comment display. |
| **Setup requirements** | Device loaded. |
| **Inputs** | Any state change. |
| **Expected outputs** | Status text reflects current state. |
| **Automation approach** | **UDP/CC**: trigger state changes, capture status outlet text. **Max console**: grep for status posts. |
| **Current test coverage** | `loader-e2e.test.js` (status outlet test). |
| **Automation blockers** | None. |

---

## C. Arrangement Mode (setforge-arranger)

### C1. Manifest Loading (prechop_manifest.json)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-01 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Read prechop_manifest.json (or arrangement_manifest.json). Supports two manifest shapes: nested `stems{}` (legacy) and flat `chunks[]` (new forge output). Flat shape auto-adapted to nested via `_alAdaptChunksToStems()`. Field mapping: audio_path -> file, duration_bars -> bars, duration_sec -> total_sec, bar_position -> start_bar. |
| **Setup requirements** | setforge-arranger.amxd on an audio track. Manifest file on disk. |
| **Inputs** | `load <manifest_path>` message (via UDP port 7423 or patcher UI). |
| **Expected outputs** | Manifest parsed, stems/chunks resolved. |
| **Automation approach** | **UDP** (port 7423): send `load` message. **LiveAPI harness**: mock File API, verify parse output. **File system**: provide test manifests in both shapes. |
| **Current test coverage** | None against arranger-main.js wrapper. `sf_arrangement_loader.js` has CommonJS test exports. |
| **Automation blockers** | None for parsing. |

### C2. Track Creation/Resolution (Find/Create Audio Tracks by Stem Name)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-02 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | For each stem in the manifest, find an existing audio track by name (case-insensitive exact match, then substring match with aliases). Alias table handles drum/drums, vocal/vocals variance. If no match, create new audio track at end of track list and rename to stem name. |
| **Setup requirements** | Ableton Live with arrangement view. |
| **Inputs** | Stem names from manifest. |
| **Expected outputs** | Track indices resolved for all stems. New tracks created if needed. |
| **Automation approach** | **LiveAPI harness**: pre-create named tracks, verify resolution. Test alias matching. Test auto-creation. |
| **Current test coverage** | `_alFindTrackForStem` and `_AL_STEM_ALIASES` exported for tests. |
| **Automation blockers** | None. |

### C3. Clip Creation in Arrangement View

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-03 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Create audio clips on arrangement view using `Track.create_audio_clip(filepath, start_time_in_beats)`. Position derived from chunk's bar_position (or sequential index * bars). Explicit `start_bar` honored when present (per-chunk positions from new-shape adapter). Negative start_beat clamped to 0 (partial intro chunk). Post-creation: find clip by walking arrangement_clips in reverse (optimized — O(1) for append case). |
| **Setup requirements** | Track resolved (ARR-02). WAV files on disk. |
| **Inputs** | WAV path, start beat, length beats. |
| **Expected outputs** | Audio clip created at correct arrangement position. |
| **Automation approach** | **LiveAPI**: verify arrangement_clips count and start_time for each clip. |
| **Current test coverage** | `runArrangementLoad` exported for tests. |
| **Automation blockers** | `create_audio_clip` is Live-version-sensitive. |

### C4. Loop Region Configuration

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-04 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Set clip properties: start_marker, end_marker, loop_start, loop_end (all in seconds since warping is OFF). Looping enabled. Order matters: set markers before enabling looping. Loop region corresponds to the manifest's loop_start_sec / loop_end_sec — the target N-bar window. Padding sits outside the loop region for drag-extend. |
| **Setup requirements** | Clip created (ARR-03). |
| **Inputs** | loop_start_sec, loop_end_sec from manifest chunk. |
| **Expected outputs** | Clip markers set to correct values. Looping = 1. |
| **Automation approach** | **LiveAPI**: query clip.start_marker, clip.end_marker, clip.loop_start, clip.loop_end, clip.looping. |
| **Current test coverage** | Indirect via `runArrangementLoad`. |
| **Automation blockers** | None. |

### C5. Warping OFF (Native Playback Speed)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-05 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Set `clip.warping = 0` on every created arrangement clip. Chunks are pre-rendered at manifest BPM, project tempo is aligned (ARR-07), so unwarped playback at native rate stays in sync. Avoids Live's auto-warp tempo guessing. All marker values interpreted in seconds (not beats). |
| **Setup requirements** | Clip created (ARR-03). |
| **Inputs** | Automatic on clip creation. |
| **Expected outputs** | clip.warping = 0. |
| **Automation approach** | **LiveAPI**: query clip.warping for every created clip. |
| **Current test coverage** | Indirect via `runArrangementLoad`. |
| **Automation blockers** | None. |

### C6. Fades Disabled

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-06 |
| **Mode** | Arrangement |
| **Status** | Not explicitly implemented |
| **Description** | The spec mentions `fades_are_enabled = 0` but the current `_alCreateAndConfigureClip` does not set this property. Live may apply default fades to arrangement clips. |
| **Setup requirements** | N/A. |
| **Inputs** | N/A. |
| **Expected outputs** | `clip.fades_are_enabled = 0` (not currently set). |
| **Automation approach** | **LiveAPI**: query clip.fades_are_enabled — will show whether Live defaults apply. |
| **Current test coverage** | None. |
| **Automation blockers** | None — simple property check. |

### C7. Project Tempo Sync (Set to Manifest BPM)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-07 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Before clip creation, set `live_set.tempo` to manifest BPM. Ensures project tempo matches chunk rendering tempo so unwarped clips stay in sync with the arrangement timeline. |
| **Setup requirements** | Live session open. |
| **Inputs** | manifest.bpm value. |
| **Expected outputs** | `live_set.tempo` set to manifest BPM. |
| **Automation approach** | **LiveAPI**: query `live_set.tempo` after load. |
| **Current test coverage** | Indirect via `runArrangementLoad`. |
| **Automation blockers** | None. |

### C8. Clear Prior Clips (Scoped to Manifest Dir)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-08 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Before placing new clips, delete every arrangement_clip on the stem track whose `file_path` sits inside the manifest directory. Scoping preserves user-placed clips. Walk clips in reverse to avoid index shifting. Necessary on re-anchor: same WAV paths collide at same start_times, and `create_audio_clip` silently fails. |
| **Setup requirements** | Stem track with existing clips. |
| **Inputs** | Track index, manifest directory path. |
| **Expected outputs** | Matching clips deleted, non-matching preserved. |
| **Automation approach** | **LiveAPI**: pre-populate clips from two dirs, run load from one dir, verify only that dir's clips were cleared. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

### C9. Re-Anchor from Locator

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-09 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | User places a locator in arrangement view at what they hear as bar 1. The anchor function: (1) reads Live tempo + cue_point time, (2) reads current prechop_manifest, (3) back-computes source time at locator's timeline beat, (4) parses named locator for bar number ("bar 4" -> bar 4), (5) adjusts source time for bar offset, (6) snaps locator to nearest bar boundary, (7) shells out to `stemforge re-anchor` via outlet -> [shell], (8) on completion, reloads manifest with timeline shift so new bar-1 chunk lands at locator position. Idempotency: skips if delta < 5ms. |
| **Setup requirements** | Arrangement loaded with clips. Locator placed. stemforge CLI accessible. |
| **Inputs** | `anchor` or `anchor <dir>` message. Locator in arrangement view. |
| **Expected outputs** | Re-cut chunks with corrected bar alignment. Clips reloaded at shifted positions. Locator snapped to bar boundary. |
| **Automation approach** | **UDP** (port 7423): send `anchor` message. **LiveAPI**: verify locator moved to snapped position, clips repositioned. **File system**: verify new prechop_manifest.json written. **Shell mock**: intercept stemforge re-anchor call. |
| **Current test coverage** | `_pickLocator`, `_parseBarFromLocatorName`, `_sourceTimeAtTimelineBeat` exported for tests. |
| **Automation blockers** | stemforge re-anchor requires Python + stems on disk (~2s roundtrip). |

### C10. Snapshot Export (arrangement_snapshot.json)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-10 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Export current arrangement state as JSON. Reads: tempo, time signature, locators (cue_points), per-track clips (A/B/C/D named tracks). Each clip: file_path (HFS prefix stripped), start_time_sec, length_sec, warping. Schema v2: wrapped in `{schema_version: 2, songs: [{...}]}`. Computes arrangement_length_sec from max clip end or locator time. |
| **Setup requirements** | Arrangement view with clips. |
| **Inputs** | `export [output_path]` message. Defaults to manifest dir + arrangement_snapshot.json. |
| **Expected outputs** | JSON file written with snapshot data. |
| **Automation approach** | **UDP** (port 7423): send `export` message. **File system**: verify JSON written, validate schema, check clip counts. |
| **Current test coverage** | `buildArrangementSnapshot` and `runArrangementExport` exported for tests. |
| **Automation blockers** | None. |

### C11. Stem Alias Handling (drum/drums, vocal/vocals)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-11 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Alias table: drum <-> drums, vocal <-> vocals. When resolving tracks by name, both forms are tried. Prevents track duplication when prechop manifest uses plural ("drums") but existing tracks use singular ("drum" or "definition | drum"). |
| **Setup requirements** | Tracks with varied naming. |
| **Inputs** | Stem names from manifest. |
| **Expected outputs** | Correct track resolution regardless of singular/plural. |
| **Automation approach** | **LiveAPI harness**: create tracks with singular names, load manifest with plural, verify no duplicates. |
| **Current test coverage** | `_AL_STEM_ALIASES` exported for tests. |
| **Automation blockers** | None. |

### C12. Flat chunks[] to Nested stems{} Adapter

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-12 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Auto-adapts flat `chunks[]` manifest shape (from auto-curation forge) into legacy nested `stems{}` shape. Field mapping: audio_path -> file, duration_bars -> bars, duration_sec -> total_sec, bar_position -> start_bar. Triggered when manifest has `chunks[]` but no `stems{}`. |
| **Setup requirements** | Manifest in flat shape. |
| **Inputs** | Manifest with chunks[] array. |
| **Expected outputs** | Adapted stems{} dict with per-stem chunk arrays. |
| **Automation approach** | **Unit test**: call `_alAdaptChunksToStems()` with fixture, verify output shape. |
| **Current test coverage** | `_alAdaptChunksToStems` exported for tests. |
| **Automation blockers** | None. |

### C13. UDP Command Interface (Port 7423)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-13 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Arranger responds to messages via its [js] inlet: `load <path> [shift]`, `export [path]`, `anchor [dir]`, `eject`, `debug`, `anchor_complete`, `anchor_started`, `anchor_error`. Messages arrive from patcher UI or via UDP routing. |
| **Setup requirements** | setforge-arranger.amxd loaded. |
| **Inputs** | Max messages. |
| **Expected outputs** | Corresponding operations executed. Status via outlet 0. |
| **Automation approach** | **UDP** (port 7423): send messages, verify responses. |
| **Current test coverage** | None against wrapper. |
| **Automation blockers** | None. |

### C14. Intro Chunk Handling (bar_position < 0)

| Field | Value |
|-------|-------|
| **Feature ID** | ARR-14 |
| **Mode** | Arrangement |
| **Status** | Implemented |
| **Description** | Chunks with `bar_position < 0` represent pre-downbeat audio (intro material). Their `start_bar` resolves to a negative number. The loader clamps negative `startBeat` to 0 — this clips the leading portion of intro chunks that would hang off the left edge. User sees a partial intro chunk at timeline start. |
| **Setup requirements** | Manifest with intro chunks. |
| **Inputs** | Manifest with bar_position < 0 chunks. |
| **Expected outputs** | Intro chunks placed at timeline 0 (clamped). |
| **Automation approach** | **LiveAPI**: verify intro chunk at beat 0, verify non-intro chunks at correct positions. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

---

## D. Calibration (setforge-calibrate)

### D1. Track Selection

| Field | Value |
|-------|-------|
| **Feature ID** | CAL-01 |
| **Mode** | Calibration |
| **Status** | Implemented |
| **Description** | Load manifest, populate track chooser. Each track shows validation state via color: green_auto (auto-cal passed), yellow_pending (needs listen), red (auto-cal failed or stem missing), validated_by_ear (user confirmed), varying (greyed out). Track count shown in set state summary. |
| **Setup requirements** | setforge-calibrate.amxd on an audio track. Manifest file. |
| **Inputs** | `loadManifest <path>` message. |
| **Expected outputs** | Tracks list populated, validation states computed, chooser updated. |
| **Automation approach** | **LiveAPI harness**: mock manifest, verify tracks array and validationState. |
| **Current test coverage** | `calibrate-flow.test.js` (integration, modular imports). |
| **Automation blockers** | None for state. UI verification requires Live. |

### D2. Stem Selection (drums/bass/other/vox)

| Field | Value |
|-------|-------|
| **Feature ID** | CAL-02 |
| **Mode** | Calibration |
| **Status** | Implemented |
| **Description** | Default audition stem is drums (calibration is drum-anchored). User can switch stem selector to bass/other/vox to spot-check phase alignment. Switching reloads the audition clip; warp marker stays at same time value. |
| **Setup requirements** | Track loaded. |
| **Inputs** | Stem name (via UI radio buttons). |
| **Expected outputs** | currentStem updated, audition clip reloaded from selected stem. |
| **Automation approach** | **LiveAPI harness**: set stem, verify clip reloaded from correct WAV path. |
| **Current test coverage** | None. |
| **Automation blockers** | None. |

### D3. Downbeat Calibration

| Field | Value |
|-------|-------|
| **Feature ID** | CAL-03 |
| **Mode** | Calibration |
| **Status** | Implemented |
| **Description** | Load stem into calibrate-audition track with warp on, auto-warp off. First warp marker at manifest's downbeat_sec. 4-bar loop from 1.1.1 to 5.1.1. Audition plays loop with metronome click. User nudges warp marker until kicks lock to click. Device observes warp_markers changes and updates currentMarker display. |
| **Setup requirements** | Track loaded (CAL-01). calibrate-audition audio track in Live. |
| **Inputs** | `load_stem` outlet message with stem path, downbeat, BPM. |
| **Expected outputs** | Clip loaded on audition track, warp marker placed, loop set. |
| **Automation approach** | **LiveAPI**: verify clip on audition track, check warp_markers, check loop region. |
| **Current test coverage** | `calibrate-flow.test.js` (modular). |
| **Automation blockers** | Warp marker observation requires Live's observer system. Audible verification requires ears. |

### D4. Warp Marker Editing

| Field | Value |
|-------|-------|
| **Feature ID** | CAL-04 |
| **Mode** | Calibration |
| **Status** | Implemented |
| **Description** | User drags warp marker with mouse or uses Live's arrow-key nudge. Device observes Clip.warp_markers changes via inlet 1 (observer). Updates currentMarker display in real time. No disk write until validated — this is preview only. Delta from auto-calibrated value shown. |
| **Setup requirements** | Track loaded, clip on audition track. |
| **Inputs** | Warp marker drag in Live UI. Observer fires on change. |
| **Expected outputs** | currentMarker updated to new sample_time. Delta displayed. |
| **Automation approach** | **LiveAPI**: programmatically set warp_markers, verify currentMarker updated. |
| **Current test coverage** | `calibrate-flow.test.js` (modular — tests marker change -> display update). |
| **Automation blockers** | Live observer system requires actual Live runtime. |

### D5. Validation Marking

| Field | Value |
|-------|-------|
| **Feature ID** | CAL-05 |
| **Mode** | Calibration |
| **Status** | Implemented |
| **Description** | Tap "validated" button: writes current marker value to `.calib_override.json` at `<stem_dir>/.calib_override.json`. Contains track_id, downbeat_sec (current marker), validated_at (ISO timestamp), method ("warp_marker_drag"), delta_from_auto_sec. Next `stemforge` manifest emit folds this override into the auto-calibrated value. "next" button advances to next unverified track. |
| **Setup requirements** | Track loaded, marker positioned. |
| **Inputs** | "validated" message. |
| **Expected outputs** | `.calib_override.json` written with correct fields. validationState updated to "validated_by_ear". |
| **Automation approach** | **File system**: verify JSON file written at expected path with expected contents. **State**: verify validationState updated. |
| **Current test coverage** | `calibrate-flow.test.js` (modular). `override-writer.test.js` (unit). |
| **Automation blockers** | None. |

---

## E. Installation & Setup

### E1. install.sh (Build All Devices, Deploy JS to Max Packages)

| Field | Value |
|-------|-------|
| **Feature ID** | INST-01 |
| **Mode** | Cross-cutting |
| **Status** | Implemented |
| **Description** | Build script: (1) detect Max version (8 or 9); (2) create Max Package dir (~/Documents/Max N/Packages/setforge-live/javascript/); (3) run build_setforge.py (builds .maxpat, .amxd, concatenated JS); (4) verify key outputs: setforge-loader.amxd, setforge-grid.amxd, setforge-calibrate.amxd, setforge-arranger.amxd, loader.js, arranger-main.js, sf_arrangement_loader.js in both device dir and package dir. |
| **Setup requirements** | Python 3 available. m4l-devices repo cloned. |
| **Inputs** | `bash install.sh` from repo root. |
| **Expected outputs** | .amxd files built, JS files deployed to Max Package dir. Exit 0 on success, exit 1 on missing files. |
| **Automation approach** | **Shell test**: run install.sh, verify exit code and file existence. Compare deployed JS against source. |
| **Current test coverage** | None. |
| **Automation blockers** | Requires Max version directory on disk. Testable with mock dirs. |

### E2. Max Package Structure

| Field | Value |
|-------|-------|
| **Feature ID** | INST-02 |
| **Mode** | Cross-cutting |
| **Status** | Implemented |
| **Description** | Max Package at ~/Documents/Max N/Packages/setforge-live/ with javascript/ subdirectory. Max's search path auto-discovers JS files in this location, enabling `include()` in the [js] objects. |
| **Setup requirements** | install.sh run (INST-01). |
| **Inputs** | N/A. |
| **Expected outputs** | Package directory exists with correct JS files. |
| **Automation approach** | **File system**: verify directory structure and file presence. |
| **Current test coverage** | None (install.sh checks files). |
| **Automation blockers** | None. |

### E3. Device Deployment Verification

| Field | Value |
|-------|-------|
| **Feature ID** | INST-03 |
| **Mode** | Cross-cutting |
| **Status** | Partial (install.sh checks file existence) |
| **Description** | Verify that all 4 .amxd devices can be loaded in Ableton Live: setforge-loader, setforge-grid, setforge-calibrate, setforge-arranger. Verify [js] objects load their scripts without errors. Verify SysEx/MIDI routing works. |
| **Setup requirements** | Live running, devices installed. |
| **Inputs** | Drop device onto track. |
| **Expected outputs** | Device loads without errors, front panel renders, [js] posts "loaded" message. |
| **Automation approach** | **LiveAPI**: create track, add device, verify device.parameters. **Max console**: check for load errors. |
| **Current test coverage** | None automated. Manual acceptance test in spec. |
| **Automation blockers** | Requires Live running with devices on search path. |

### E4. Multi-Machine Setup (M2 + Mini)

| Field | Value |
|-------|-------|
| **Feature ID** | INST-04 |
| **Mode** | Cross-cutting |
| **Status** | Implemented |
| **Description** | Two-machine workflow: M2 MacBook for curation/analysis (CPU-heavy stems), Intel Mini for performance (lighter, dedicated Ableton). sync-machines.sh handles data transfer (CUR-13). Both machines need install.sh run independently. |
| **Setup requirements** | SSH between machines. Both have Max + Live installed. |
| **Inputs** | install.sh on each machine, sync-machines.sh for data. |
| **Expected outputs** | Same sets playable on both machines. |
| **Automation approach** | **Integration**: run sync dry-run, verify path mapping. Verify set.json portability (relative paths). |
| **Current test coverage** | None. |
| **Automation blockers** | Requires two machines or VM setup for real integration test. |

---

## Summary: Test Coverage Matrix

| Category | Total Features | Implemented | Has Tests | No Tests | Stubs |
|----------|---------------|-------------|-----------|----------|-------|
| A. Curation | 14 | 14 | 5 | 9 | 0 |
| B. Performance | 21 | 19 | 8 | 11 | 2 (B6 partial, B13) |
| C. Arrangement | 14 | 13 | 4 | 9 | 1 (C6) |
| D. Calibration | 5 | 5 | 3 | 2 | 0 |
| E. Installation | 4 | 4 | 0 | 4 | 0 |
| **Total** | **58** | **55** | **20** | **35** | **3** |

### Critical gap: deployed vs modular test targets

The most important finding: most JS integration tests import modular `src/loader/*.js` and `src/shared/*.js` files that are **NOT deployed**. The deployed device runs a concatenated monolith (`loader-controller.js` -> `loader.js`). Only `loader-e2e.test.js` tests the built monolith. This means passing modular tests does NOT validate shipped behavior.

### Automation-ready features (no Live required)

These can be tested in CI without Ableton Live:
- All CUR-* features (pure Python)
- Chop math, manifest parsing, color palette (JS unit tests)
- File I/O verification (arrangement loader/reader)
- Modifier gesture engine (state machine logic)
- Scene snapshot serialization/deserialization

### Features requiring Live for full automation

These need a LiveAPI test harness running inside Live:
- PERF-01 through PERF-21 (clip creation, playback, MIDI routing)
- ARR-01 through ARR-14 (arrangement clip creation, track resolution)
- CAL-01 through CAL-05 (warp marker observation, audition clip)

### Features requiring hardware

These cannot be fully automated:
- PERF-12, PERF-14 (physical Launchpad MIDI I/O)
- PERF-15 (MIDI track routing to hardware)
- INST-04 (multi-machine sync)
- Any audio quality / timing verification (requires ears)
