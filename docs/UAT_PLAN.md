# Setforge Ecosystem — User Acceptance Test Plan

**Date:** 2026-06-08
**Scope:** End-to-end user workflows across taste, stemforge, and m4l-devices
**Purpose:** Verify the ecosystem works as a coherent product from the user's perspective.

Feature IDs reference the companion [FEATURE_INVENTORY.md](./FEATURE_INVENTORY.md).

---

## End-to-End Workflows

### UAT-01: First-Time Setup to First Performance

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-01 |
| **Title** | First-time setup to first performance |
| **Persona** | New user installing Setforge for the first time |
| **Features tested** | INST-01, INST-02, INST-03, PERF-01, PERF-04, PERF-05, PERF-14, PERF-15 |

**Preconditions:**
- macOS with Ableton Live 11+ and Max 8/9 installed
- m4l-devices repo cloned
- Launchpad MK2 connected via USB
- A pre-built `.set.json` and `.manifest.json` with at least 2 tracks available on disk

**Steps:**

1. Open terminal, navigate to the m4l-devices repo root.
2. Run `bash install.sh`.
3. Verify terminal output shows "Install complete" with all files OK.
4. Open Ableton Live. Create a new Live Set.
5. Create an audio track. Drag `setforge-loader.amxd` onto it from the Max for Live browser.
6. Create a MIDI track. Drag `setforge-grid.amxd` onto it.
7. On the MIDI track: set input to "Launchpad MK2 (Standalone Port)", output to "Launchpad MK2 (Standalone Port)", monitoring to "In", arm the track.
8. Observe the Launchpad enters programmer mode (all pads initially off or dim).
9. In the loader device's front panel, browse to the pre-built `.set.json` file and click "load".
10. Wait for loading to complete (< 30 seconds for a 2-track set).
11. Observe preset pads on rows 5-6 of the Launchpad light up with preset colors.
12. Tap a preset pad on row 5. Observe rows 1-4 light up with stem colors (orange/blue/olive/green).
13. Tap drums chop 1 (row 1, col 1). Hear drums playing. Pad lights bright orange.
14. Tap bass chop 1 (row 2, col 1). Hear bass join, in phase with drums.
15. Tap drums chop 3 (row 1, col 3). Drums switch to chop 3 on next 1/16 boundary. Chop 1 pad returns to soft orange, chop 3 goes bright.

**Expected results:**
- Step 3: No MISSING files in output.
- Step 8: Launchpad pads respond to programmer mode SysEx.
- Step 10: Status display shows set name, bank contents, tempo.
- Step 11: Preset pads colored per palette, empty slots dim.
- Step 12: Stem rows show playable chops (soft stem colors); disabled chops show dark red.
- Step 13-14: Audio audible, in phase, pads reflect playing state.
- Step 15: Clean transition, no audible gap or overlap.

**Pass criteria:**
- [ ] install.sh exits 0
- [ ] All 4 .amxd files loadable in Live without errors
- [ ] Launchpad enters programmer mode within 2 seconds
- [ ] Set loads in < 30 seconds with correct preset count
- [ ] At least one chop per stem row is playable (bright on tap)
- [ ] Two stems play simultaneously in phase (no audible flam > 15ms)

---

### UAT-02: Build a New Set from Local Files

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-02 |
| **Title** | Build a new set from local audio files |
| **Persona** | DJ preparing a new set from their music library |
| **Features tested** | CUR-01, CUR-02, CUR-03, CUR-04, CUR-05, CUR-06, CUR-07, CUR-08, CUR-09, CUR-10, PERF-01, PERF-04, PERF-05 |

**Preconditions:**
- taste repo with `pip install` dependencies met
- taste DB initialized (`python3 -m taste init`)
- 2-3 local audio files (MP3/FLAC/WAV) accessible
- Ableton Live + setforge devices installed (UAT-01 passed)

**Steps:**

1. Create a set YAML file:
   ```yaml
   name: test_set
   tracks:
     - artist: "Artist One"
       title: "Song One"
       file: ~/Music/song_one.mp3
     - artist: "Artist Two"
       title: "Song Two"
       file: ~/Music/song_two.flac
   ```
2. Run `python3 -m taste forge-set test_set.yaml`.
3. Observe each pipeline stage completes:
   - Register: tracks added/found in DB
   - Analyze: tempo, key computed
   - Stem: demucs separation runs (this is slow — ~5-10 min per track on CPU)
   - Structure: bar grid detected, chops curated
   - Materialize: chop WAVs cropped
   - Export: set.json + manifest.json written
4. Verify output directory (`~/Desktop/test_set/` or specified location):
   - `test_set.set.json` exists
   - `test_set.manifest.json` exists
   - Per-track subdirs with stem chop WAVs
   - Vocal stems with .asd sidecars
5. In Ableton Live, load `test_set.set.json` in the setforge-loader device.
6. Activate a preset. Trigger chops across all 4 stem rows.
7. Switch presets. Verify hot-swap works (held chops migrate).

**Expected results:**
- Step 3: All stages complete without errors. Resumable on rerun.
- Step 4: Output directory contains all expected files. All paths in manifest are relative.
- Step 5: Set loads successfully with both tracks in preset slots.
- Step 6: Chops play from the correct bar positions per the curated selection.
- Step 7: Hot-swap transitions cleanly at quant boundaries.

**Pass criteria:**
- [ ] forge-set completes all 7 stages without error
- [ ] set.json schema valid (schema_version, banks, setlist present)
- [ ] manifest.json contains all tracks with stems and chop data
- [ ] All chop WAV paths in manifest resolve to actual files
- [ ] Set loads in setforge-loader and all presets are playable
- [ ] Vocal stem plays as continuous full_stem (not chopped)

---

### UAT-03: Curate a Set, Edit in Live, Save, Reload on Another Machine

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-03 |
| **Title** | Curate, edit, save, reload across machines |
| **Persona** | DJ refining a set and transferring to performance machine |
| **Features tested** | CUR-10, CUR-13, PERF-01, PERF-05, PERF-11, PERF-18, INST-04 |

**Preconditions:**
- Set built (UAT-02 passed)
- Two machines with SSH access (M2 + Mini) or ability to simulate transfer
- sync-machines.sh configured

**Steps:**

1. Load set in setforge-loader on Machine A (M2).
2. Activate preset A1. Move chops around: drag chop 3 to column 5 position (rearrange the performance).
3. Send `save` command (CC 100 or device button).
4. Verify saved state on disk: the manifest JSON should reflect the edited column assignments.
5. Run `./tools/sync-machines.sh` to push to Machine B (Mini).
6. Verify sync output shows items transferred.
7. On Machine B: install devices (if not done), load the same set.json.
8. Activate preset A1. Verify chop column assignments match the saved edits from step 2.
9. Send `reload` (CC 105) on Machine B. Verify state still matches.

**Expected results:**
- Step 4: JSON on disk reflects column edits.
- Step 6: rsync transfers stems, chops, DB, sets.
- Step 8: Edited chop positions restored on Machine B.

**Pass criteria:**
- [ ] Save writes to disk within 1 second
- [ ] Saved JSON contains per-clip column assignments
- [ ] sync-machines.sh transfers all 6 sync items without error
- [ ] Reload on Machine B matches saved state from Machine A
- [ ] Relative paths in manifest resolve correctly on both machines

---

### UAT-04: Arrangement Workflow

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-04 |
| **Title** | Arrangement view: load stems, edit, re-anchor, export snapshot |
| **Persona** | Producer arranging stems in Ableton's arrangement view |
| **Features tested** | CUR-09, ARR-01, ARR-02, ARR-03, ARR-04, ARR-05, ARR-07, ARR-08, ARR-09, ARR-10, ARR-11, ARR-12, ARR-14 |

**Preconditions:**
- Prechop manifest exists (from forge-set with `--mode arrangement` or `--mode both`)
- setforge-arranger.amxd installed
- Ableton Live in arrangement view

**Steps:**

1. Create an audio track. Drop `setforge-arranger.amxd` onto it.
2. Send `load ~/path/to/prechop_manifest.json` to the arranger device.
3. Observe: project tempo changes to manifest BPM.
4. Observe: audio tracks created (or resolved) for each stem (drums, bass, other, vocals).
5. Observe: arrangement clips appear on each track, tiled end-to-end.
6. Play from bar 1. Verify all stems are in sync.
7. Verify clips have warping OFF (check clip properties).
8. Check intro material: if the source had pre-downbeat audio, verify a partial chunk appears at timeline 0.
9. Place a locator at what sounds like bar 4 of the song. Name it "bar 4".
10. Send `anchor` message to the arranger.
11. Observe: stemforge re-anchor runs (~2 seconds), then clips reload at shifted positions.
12. Verify the locator snapped to the nearest bar boundary.
13. Play from the locator. Verify bar 4 of the song now starts at the locator's position.
14. Send `export` message.
15. Verify `arrangement_snapshot.json` written to the manifest directory.

**Expected results:**
- Step 3: `live_set.tempo` matches manifest BPM.
- Step 4: Tracks named "drums", "bass", "other", "vocals" (or resolved via alias).
- Step 5: Correct number of clips per stem, positioned at correct bar boundaries.
- Step 6: All stems phase-aligned.
- Step 7: Every clip has warping = 0.
- Step 11: Clips refresh with new positions.
- Step 12: Locator at exact bar boundary (beat divisible by beats_per_bar).
- Step 15: JSON contains tempo, time_sig, locators, per-track clips.

**Pass criteria:**
- [ ] Arrangement loads with correct clip count (= number of chunks per stem)
- [ ] All clips have warping = 0
- [ ] Project tempo matches manifest BPM
- [ ] Re-anchor shifts clips to align bar 4 with locator
- [ ] Locator snapped to bar boundary (no fractional bar position)
- [ ] Snapshot JSON valid and contains all track clips
- [ ] Stem alias resolution works (no duplicate tracks)

---

### UAT-05: Recommendation Workflow

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-05 |
| **Title** | Find next song via recommendations, add to set, forge, perform |
| **Persona** | DJ expanding a set with recommended tracks |
| **Features tested** | CUR-11, CUR-12, CUR-01, CUR-10, PERF-01 |

**Preconditions:**
- taste DB populated with analyzed tracks (>20 tracks)
- rec_server dependencies installed (Flask)
- Working set already built

**Steps:**

1. Start rec server: `python3 -m taste.rec_server`.
2. Verify server starts on configured port (default 7450).
3. Open browser to `http://127.0.0.1:7450`. Verify popup UI loads.
4. Search for a seed track. Select it.
5. Choose "transition" mode. Click recommend.
6. Verify ranked candidates appear with per-dimension scores.
7. Switch to "mashup" mode. Recommend again.
8. Verify results differ (mashup favors groove/vocal similarity).
9. Pick a recommended track. Note its ID.
10. Add it to the set YAML (using `track_id:` if in DB, or `file:` if local).
11. Re-run `python3 -m taste forge-set test_set.yaml --steps curate`.
12. Reload the set in setforge-loader. Verify the new track appears in a preset slot.

**Expected results:**
- Step 2: Server prints port and DB path.
- Step 3: React UI renders with search bar and mode toggles.
- Step 6: Recommendations scored across key/tempo/groove/vocal/timbre/taste.
- Step 8: Mashup mode weights groove and vocal higher than transition mode.
- Step 12: New track loadable and playable.

**Pass criteria:**
- [ ] rec_server starts without error
- [ ] /api/recommend returns ranked results with scores
- [ ] /api/search returns matching tracks
- [ ] Transition and mashup modes produce different rankings
- [ ] New track integrates into existing set without breaking other tracks

---

### UAT-06: Cross-Machine Workflow

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-06 |
| **Title** | Build on M2, sync to Mini, perform |
| **Persona** | DJ with separate curation and performance machines |
| **Features tested** | CUR-13, INST-04, PERF-01, PERF-05 |

**Preconditions:**
- Set built on M2 (UAT-02 passed)
- SSH access from M2 to Mini (`zak@mini`)
- install.sh run on both machines

**Steps:**

1. On M2: verify set directory has all expected files (set.json, manifest.json, stem chops, vocal stems).
2. Run `./tools/sync-machines.sh --dry-run` on M2. Verify output lists all 6 sync items.
3. Run `./tools/sync-machines.sh` (without dry-run). Verify sync completes.
4. SSH to Mini. Verify files arrived at expected paths:
   - `~/.cache/setforge/stems/{track_ids}/` have stems
   - `~/.cache/setforge/chops/` has chop WAVs
   - `~/zacharysbrown/taste/setforge.db` matches
5. On Mini: open Live, load the set.json. Verify all presets load.
6. Perform: trigger chops, switch presets, verify audio plays correctly.
7. On M2: modify the set (add a track, re-forge). Sync again.
8. On Mini: reload. Verify new track available.

**Expected results:**
- Step 3: rsync transfers only changed files (incremental).
- Step 5: Set loads identically on Mini (relative paths resolve).
- Step 6: All performance features work on Mini.

**Pass criteria:**
- [ ] Dry-run lists all 6 sync items
- [ ] sync completes without errors
- [ ] Set loads identically on both machines
- [ ] Chops play from correct bar positions on Mini
- [ ] Incremental re-sync transfers only new/changed files

---

## Performance Workflows

### UAT-07: Basic Performance

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-07 |
| **Title** | Basic performance: load, trigger, switch |
| **Persona** | DJ performing a live set |
| **Features tested** | PERF-01, PERF-04, PERF-05, PERF-21 |

**Preconditions:**
- Set loaded with at least 4 presets (UAT-01 or UAT-02 passed)
- Launchpad connected, grid device on MIDI track

**Steps:**

1. Tap preset A1 on row 5, col 1. Rows 1-4 light up.
2. Tap drums chop 1 (row 1, col 1). Drums play. Pad bright orange.
3. Tap bass chop 3 (row 2, col 3). Bass plays from bar 9. Pad bright blue.
4. Tap other chop 1 (row 3, col 1). Other plays. Pad bright olive/yellow.
5. Tap vox chop 1 (row 4, col 1). Vox plays. Pad bright green. All 4 stems audible simultaneously.
6. Tap drums chop 5 (row 1, col 5). Drums replace at next 1/16 boundary. Chop 1 goes soft, chop 5 goes bright.
7. Tap bass chop 3 again (currently playing). Bass stops at next 1-bar boundary.
8. Tap preset A2 on row 5, col 2. Hot-swap: drums chop 5 migrates to A2's chop 5, other chop 1 migrates to A2's chop 1, vox chop 1 migrates.
9. Verify status display shows "A2" as active preset.

**Expected results:**
- All chops play in sync on the global grid.
- Launch quantization per row: drums immediate (1/16), bass on bar, other on 1/4, vox on 1/2.
- Hot-swap transitions are clean (no gap, no overlap at quant boundary).
- Status display updates on every state change.

**Pass criteria:**
- [ ] All 4 stems play simultaneously without dropout
- [ ] Chop replace within same row is gapless
- [ ] Hot-swap migrates held chops to matching columns in new preset
- [ ] Bass launch waits for bar boundary
- [ ] Status display reflects active preset name and tempo

---

### UAT-08: Modifier Deep Dive

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-08 |
| **Title** | Test each modifier pad individually |
| **Persona** | DJ learning the modifier layer |
| **Features tested** | PERF-06 |

**Preconditions:**
- Set loaded, preset active, chops playing

**Steps:**

1. **HOLD (row 7, col 1) — SHIFT function:**
   a. Hold HOLD pad. Tap a different preset. Verify: active preset changes but held chops STOP (no migration). This is the "hard rebuild" behavior.
   b. Release HOLD.
   c. Hold HOLD pad. Tap a scene pad. Verify: current state is SAVED to that scene (not recalled).

2. **SOLO (row 7, col 3) — Per-row toggle:**
   a. Double-tap SOLO within 400ms. Verify: SOLO pad latches yellow. Per-row mode entered.
   b. Double-tap SOLO again. Verify: SOLO unlatches. Back to solo mode.

3. **MUTE, REV, STUT, HALF, DBL, KILL (cols 2, 4, 5, 6, 7, 8) — Inert stubs:**
   a. For each: tap once. Verify pad goes bright white (held state).
   b. Release. Verify pad returns to dim white.
   c. Double-tap to latch. Verify pad goes yellow (latched).
   d. Tap again to unlatch. Verify pad returns to dim white.
   e. **Confirm: NO audio change occurs.** These are visual-only stubs.

4. **Multiple latches:**
   a. Latch HOLD (double-tap). Latch REV (double-tap). Verify: both latched simultaneously (no mutual exclusion in deployed code).

**Expected results:**
- HOLD acts as SHIFT for preset-no-migrate and scene-save.
- SOLO toggles per-row mode.
- Other 6 modifiers light up but produce no audio effect.
- No mutual exclusion — multiple latches allowed.

**Pass criteria:**
- [ ] HOLD+preset = no-migrate swap (chops stop, don't follow)
- [ ] HOLD+scene = save (not recall)
- [ ] SOLO double-tap enters/exits per-row mode
- [ ] 6 stub modifiers have correct visual behavior but zero audio impact
- [ ] Multiple modifiers latchable simultaneously

---

### UAT-09: Scene Workflow

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-09 |
| **Title** | Build scenes, recall during performance |
| **Persona** | DJ building performance snapshots |
| **Features tested** | PERF-07, PERF-06 (HOLD/SHIFT for save) |

**Preconditions:**
- Set loaded, preset active, some chops playing

**Steps:**

1. Set up a musical state: activate preset A3, play drums chop 2, bass chop 4, vox chop 1.
2. Hold HOLD pad (row 7, col 1). While holding, tap scene pad 1 (row 8, col 1). This SAVES the current state.
3. Verify scene pad 1 changes from off/empty to dim purple (built).
4. Change to a different state: activate preset A1, play different chops.
5. Tap scene pad 1 (row 8, col 1) WITHOUT holding HOLD. This RECALLS.
6. Verify: preset returns to A3, drums chop 2 plays, bass chop 4 plays, vox chop 1 plays. Scene pad 1 goes bright purple.
7. Save a second scene in per-row mode:
   a. Enter per-row mode (double-tap SOLO).
   b. Reassign bass row to a different preset.
   c. Save to scene pad 2 (HOLD + tap scene 2).
8. Change to solo mode, play different chops.
9. Recall scene pad 2. Verify: per-row mode re-enters, bass row sources from the saved preset.

**Expected results:**
- Scene save captures: active preset, held chops per row, modifier latch state, view mode, rowSources.
- Scene recall restores all captured state including view mode.
- Multiple scenes can coexist.

**Pass criteria:**
- [ ] Scene save stores complete state (verified by recall)
- [ ] Scene recall restores preset + chops + modifiers + view
- [ ] Per-row scene recall restores rowSources and re-enters per-row mode
- [ ] Scene colors: empty=off, built=dim purple, last-recalled=bright purple

---

### UAT-10: Dual-Song Mashup

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-10 |
| **Title** | Stage two songs, enter dual-song, chord across decks |
| **Persona** | DJ performing a drum-on-drum mashup |
| **Features tested** | PERF-09, PERF-10 |

**Preconditions:**
- Set loaded with presets on BOTH bank A and bank B
- At least one preset loaded on row 5 and one on row 6

**Steps:**

1. Hold deck-setup button (right side, 2nd from top, note 79). Verify: button lights bright white.
2. While holding: tap a preset on row 5 (bank A). Verify: that pad starts flashing preset-color <-> white (deck X staged).
3. While still holding: tap a preset on row 6 (bank B). Verify: that pad starts flashing preset-color <-> soft blue (deck Y staged).
4. Release deck-setup. Verify: button settles to dim white.
5. Verify dual-song toggle (top-right, note 89) shows mid white (something staged).
6. Double-tap the dual-song toggle. Verify: toggle goes bright white, grid shows 8 rows of stems.
7. Rows 1-4: deck X stems (drums/bass/other/vox). Rows 5-8: deck Y stems.
8. Tap row 1 col 3 (deck X drums chop 3). Hear deck X drums.
9. Tap row 5 col 5 (deck Y drums chop 5). Hear deck Y drums ON TOP of deck X drums.
10. Verify both drum rows play simultaneously — drum-on-drum mashup.
11. Tap row 2 col 1 (deck X bass). Hear X bass join.
12. Tap row 8 col 1 (deck Y vox). Hear Y vox join. 4 simultaneous voices across 2 songs.
13. Double-tap dual-song toggle to exit. Verify: return to previous view (solo or per-row).
14. Verify: chops held in dual-song mode continue playing invisibly.

**Expected results:**
- Staging pre-loads clips instantly (no delay on dual-song entry).
- Both decks' stems playable simultaneously.
- Exit preserves audio that was playing.
- Visual: deck X rows and deck Y rows both use stem colors.

**Pass criteria:**
- [ ] Staging flash colors correct (X=white, Y=soft blue)
- [ ] Dual-song entry is instant (pre-loaded)
- [ ] 8 simultaneous voices without dropout
- [ ] Drum-on-drum: both drum rows play in phase
- [ ] Exit returns to prior view with audio continuing

---

### UAT-11: Hot-Swap (Pre-Stage Next Song, Seamless Transition)

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-11 |
| **Title** | Pre-stage next song, seamless transition |
| **Persona** | DJ transitioning between songs mid-set |
| **Features tested** | PERF-04, PERF-05, PERF-10 |

**Preconditions:**
- Set loaded with 4+ presets across both banks

**Steps:**

1. Activate preset A1. Play drums chop 1, bass chop 1.
2. Tap preset A2 (without HOLD). Observe:
   - Drums chop 1 migrates to A2's drums chop 1 at next 1/16 boundary.
   - Bass chop 1 migrates to A2's bass chop 1 at next 1-bar boundary.
   - A1 pad goes dim, A2 pad goes bright.
3. Now hold HOLD pad and tap preset A3. Observe:
   - Active preset changes to A3 but held chops STOP (no migration).
   - Grid is now A3's chops, nothing playing.
4. Stage a new song into deck X while performing:
   - Continue playing chops from A3.
   - Hold deck-setup, tap a different preset on row 5. Pre-load happens in background.
   - Release deck-setup. Performance undisturbed.
5. Switch to dual-song view. Both the performing song and the pre-staged song are ready.

**Expected results:**
- Normal preset swap: held chops migrate smoothly.
- HOLD+preset swap: held chops stop (hard rebuild).
- Staging does not interrupt current performance.

**Pass criteria:**
- [ ] Normal swap: chops migrate at correct quant boundaries per stem row
- [ ] HOLD swap: chops stop, no migration
- [ ] Staging pre-load does not cause audio glitch
- [ ] Pre-staged song immediately available in dual-song mode

---

### UAT-12: Panic Recovery

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-12 |
| **Title** | Trigger panic, verify clean state, resume |
| **Persona** | DJ recovering from a mess during performance |
| **Features tested** | PERF-16, PERF-04, PERF-05, PERF-10 |

**Preconditions:**
- Set loaded, complex state: per-row mode active, chops playing across rows, modifiers latched, dual-song previously staged

**Steps:**

1. Build complex state:
   - Enter per-row mode. Assign different presets to each row.
   - Latch HOLD modifier.
   - Play chops in all 4 rows.
   - Stage decks for dual-song.
2. Triple-tap PANIC (left side button note 10, 3 taps within 1 second).
   - Observe "panic 1/3" status on first tap, "panic 2/3" on second.
3. On third tap, observe:
   - All audio stops immediately.
   - All modifier pads return to dim white (latches cleared).
   - Grid returns to solo mode layout.
   - Dual-song mode deactivated.
4. Verify staging survives: deck-setup button still shows dim white (something staged).
5. Verify active preset survives: tap a chop pad on rows 1-4. It should source from the last active preset.
6. Resume performance: activate a preset, trigger chops. Everything works normally.
7. Enter dual-song via toggle. Staged songs still ready.

**Expected results:**
- PANIC stops all audio and resets to solo mode.
- Staging and active preset survive panic.
- Device is immediately usable after panic.

**Pass criteria:**
- [ ] All audio stops on 3rd tap
- [ ] All modifiers cleared to idle
- [ ] performanceView = "solo"
- [ ] dualSongActive = false
- [ ] rowSources all null
- [ ] staging.deckX/Y unchanged
- [ ] activeSlotIndex unchanged
- [ ] Device fully functional after panic

---

### UAT-13: Save and Reload

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-13 |
| **Title** | Curate chops, save, quit Live, reload, verify |
| **Persona** | DJ saving a rehearsal session |
| **Features tested** | PERF-11, PERF-18, PERF-01 |

**Preconditions:**
- Set loaded, preset active

**Steps:**

1. Activate preset A1. Move chops around (rearrange columns).
2. For vocal stem: verify it loads as full_stem (one continuous clip, not 8 chops).
3. Send save command (CC 100).
4. Verify save confirmation in status display.
5. Send eject (CC 104). Verify all state cleared.
6. Quit Ableton Live. Reopen.
7. Drop setforge-loader.amxd on a track.
8. Verify autowatch reload: the device should auto-load the last set from `/tmp/setforge_last_set.txt`.
9. Activate preset A1.
10. Verify: chop column assignments match the saved edits from step 1.
11. Verify: vocal stem restores as full_stem with correct warp grid.

**Expected results:**
- Save persists to disk.
- Reload after quit/restart restores edits.
- Full_stem vocals survive save/reload cycle.

**Pass criteria:**
- [ ] Saved JSON contains edited column positions
- [ ] Autowatch reload finds last set path
- [ ] Column assignments match after reload
- [ ] Vocal full_stem mode preserved
- [ ] No data loss in save/reload cycle

---

## Edge Case Workflows

### UAT-14: Empty Set

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-14 |
| **Title** | Load a set with no tracks |
| **Persona** | User testing error handling |
| **Features tested** | PERF-01 |

**Preconditions:**
- A set.json with empty preset banks (all null) and empty setlist

**Steps:**

1. Load the empty set.json in the loader.
2. Verify: device loads without crash. Status shows set name with 0 tracks.
3. All preset pads show empty (dim white [8,8,8]).
4. Tapping any preset pad does nothing (no crash).
5. Tapping any chop pad does nothing (no crash).

**Pass criteria:**
- [ ] No crash on empty set load
- [ ] Status display shows set name
- [ ] All pads in idle/empty state
- [ ] No error in Max console beyond informational messages

---

### UAT-15: Missing Stems

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-15 |
| **Title** | Load set where some stems are missing on disk |
| **Persona** | User with incomplete stem cache |
| **Features tested** | PERF-01, PERF-02, PERF-05 |

**Preconditions:**
- `missing_stem.manifest.json` fixture (included in test fixtures)

**Steps:**

1. Load a set where one track's drums.wav is missing from disk.
2. Verify: other stems for that track load normally.
3. Activate the preset with missing drums.
4. Verify: drums row shows empty/disabled (off or dark red). Other rows playable.
5. Tap a drums pad. Nothing happens (no crash, no audio).
6. Tap a bass pad. Bass plays normally.
7. Switch to a different preset (fully loaded). All 4 rows work.

**Pass criteria:**
- [ ] Set loads despite missing stem (no crash)
- [ ] Missing stem's pads show disabled state
- [ ] Other stems for same track are unaffected
- [ ] Switching away from the broken preset works normally

---

### UAT-16: Wrong Tempo

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-16 |
| **Title** | Load set with mismatched global_tempo |
| **Persona** | User with tempo detection octave error |
| **Features tested** | PERF-01, PERF-02 |

**Preconditions:**
- Set with global_tempo deliberately wrong (e.g. track is 90 BPM but manifest says 180 BPM)

**Steps:**

1. Load the set.
2. Activate the mismatched preset.
3. Trigger chops. Observe: chops play at wrong speed (double-time if 180 vs 90).
4. Note: this is expected behavior — the device trusts the manifest. BPM detection is stemforge's job.

**Pass criteria:**
- [ ] Set loads without crash
- [ ] Chops play (even if at wrong speed)
- [ ] Device does not attempt to correct BPM (trusts manifest)

---

### UAT-17: Large Set (16 Tracks, Both Banks Full)

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-17 |
| **Title** | Full 16-track set across both banks |
| **Persona** | DJ with a large set |
| **Features tested** | PERF-01, PERF-04, PERF-05 |

**Preconditions:**
- Set with 16 tracks: 8 in bank A, 8 in bank B

**Steps:**

1. Load the set. Observe: loading time < 30 seconds.
2. All 16 preset pads light up (8 on row 5, 8 on row 6).
3. Tap each preset in bank A sequentially. Verify each loads and plays.
4. Tap each preset in bank B sequentially. Verify each loads and plays.
5. Hot-swap between bank A and bank B presets. Verify migration works across banks.
6. Stage one from each bank for dual-song. Enter dual-song. Verify both play.

**Pass criteria:**
- [ ] All 16 presets load (no slots missing)
- [ ] Load time < 30 seconds for full set
- [ ] Every preset's chops are playable
- [ ] Cross-bank hot-swap works
- [ ] Memory footprint < 250 MB after full load

---

### UAT-18: Re-Anchor with Named Locator

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-18 |
| **Title** | Re-anchor arrangement using a "bar 4" locator |
| **Persona** | Producer fixing arrangement alignment |
| **Features tested** | ARR-09 |

**Preconditions:**
- Arrangement loaded (UAT-04 steps 1-5 passed)

**Steps:**

1. Listen to the arrangement. Identify that what should be bar 4 is audibly at a certain position.
2. Drop a locator at that position. Name it "bar 4" (or just "4").
3. Send `anchor` to the arranger device.
4. Observe status messages: "locator 'bar 4' = bar 4 at source X.XXXs, adjusted bar 1 -> Y.YYYs".
5. Observe re-anchor runs and clips reload (~2 seconds).
6. Play from the locator. Verify: bar 4 of the song starts exactly at the locator.
7. Play from bar 1 (timeline earlier). Verify: bars 1-3 are correctly positioned before the locator.

**Expected results:**
- Named locator parsing: "bar 4" -> bar number 4, adjusts source time back by 3 bars.
- Locator snapped to nearest bar boundary.
- After re-anchor, all chunks repositioned so bar 4 = locator position.

**Pass criteria:**
- [ ] "bar 4" parsed correctly from locator name
- [ ] Source time adjusted by -(4-1) * bar_seconds
- [ ] Locator snapped to bar boundary
- [ ] Clips at bar 4 align with locator after re-anchor
- [ ] Idempotent: re-running anchor with same locator = no-op (delta < 5ms)

---

### UAT-19: Arrangement with Intro Material

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-19 |
| **Title** | Arrangement loading with pre-downbeat audio |
| **Persona** | Producer with a song that has an intro before bar 1 |
| **Features tested** | CUR-09, ARR-03, ARR-14 |

**Preconditions:**
- Prechop manifest from a song with significant pre-downbeat audio (first_downbeat_sec > 2 seconds)

**Steps:**

1. Verify the prechop manifest contains chunks with `bar_position < 0`.
2. Load arrangement via arranger device.
3. Observe: a partial chunk appears at timeline beat 0 (clamped from negative position).
4. Observe: bar-1 chunk starts at a positive beat position after the intro.
5. Play from timeline start. Hear intro material, then main song starts.
6. Verify the intro chunk's loop region is set correctly (loop_start/end in the padded WAV).

**Expected results:**
- Intro chunks placed at timeline 0 (negative positions clamped).
- Non-intro chunks at correct bar positions.
- No gaps between intro and main content.

**Pass criteria:**
- [ ] Chunks with bar_position < 0 present in manifest
- [ ] Intro chunk at timeline beat 0
- [ ] Main chunks at correct positive positions
- [ ] Audio plays continuously from intro through song start
- [ ] Loop regions correct within each chunk WAV

---

## Calibration Workflows

### UAT-20: Full Calibration Flow

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-20 |
| **Title** | Validate a track's downbeat calibration |
| **Persona** | DJ validating set prep |
| **Features tested** | CAL-01, CAL-02, CAL-03, CAL-04, CAL-05 |

**Preconditions:**
- setforge-calibrate.amxd on an audio track
- Manifest with at least 3 tracks (mix of validated and unvalidated)

**Steps:**

1. Load the manifest in the calibrator. Verify track dropdown populated.
2. Verify set state shows "N of M validated, K unverified, J red".
3. Load the first unverified track (yellow_pending). Verify:
   - Drums stem appears in `calibrate-audition` track.
   - Warp marker placed at manifest's downbeat_sec.
   - Front panel shows "calibrated downbeat: X.XX sec (auto)".
4. Hit audition. Transport starts, 4-bar loop plays with metronome click.
5. Listen. If kicks are aligned with click, proceed. If not:
   a. Drag the warp marker 50ms earlier.
   b. Verify: front panel "current marker" updates in real time.
   c. Verify: delta shows the difference from auto.
6. Switch stem to "bass". Verify: audition clip reloads with bass stem, marker stays at same position.
7. Switch back to "drums".
8. Tap "validated". Verify:
   a. `.calib_override.json` written to stem directory.
   b. Contains: track_id, downbeat_sec (current marker value), validated_at, method, delta_from_auto_sec.
   c. validationState for this track updates to "validated_by_ear".
9. Tap "next". Verify: advances to next unverified track.
10. Repeat until all tracks validated. Verify set state shows all green.

**Expected results:**
- Warp marker observation works in real time.
- Override JSON written correctly.
- "Next" skips already-validated tracks.
- Set-level completion tracking accurate.

**Pass criteria:**
- [ ] Tracks load with correct stem on audition track
- [ ] Warp marker position reflected in real time
- [ ] Stem switch preserves marker position
- [ ] .calib_override.json written with correct schema
- [ ] validationState transitions correctly
- [ ] Set state counter accurate

---

## Automation Integration Tests

### UAT-21: Automated Regression via UDP

| Field | Value |
|-------|-------|
| **Workflow ID** | UAT-21 |
| **Title** | Run automated regression suite against running Live session |
| **Persona** | Developer verifying no regressions before release |
| **Features tested** | PERF-20, PERF-01, PERF-04, PERF-05, PERF-16, PERF-17 |

**Preconditions:**
- Live running with setforge-loader loaded
- UDP port 7422 reachable (loader)
- Test fixture set.json available
- Python test runner with UDP client (`tests/uat/setforge_remote.py`)

**Steps:**

1. Send UDP `load <fixture_set_path>` to port 7422.
2. Wait 5 seconds. Send `debug` and verify status output shows loaded set.
3. Send `inspect` and parse the returned state JSON.
4. Verify: preset count matches fixture, activeSlotIndex = -1 (not yet activated).
5. Send CC 103 (panic). Verify clean state.
6. Send `eject` (CC 104). Verify empty state.
7. Re-load. Send preset activation MIDI. Send chop trigger MIDI.
8. Send `inspect` and verify playingChops state.
9. Send `save` (CC 100). Verify file written.
10. Send `reload` (CC 105). Verify state matches.

**Expected results:**
- All commands execute without crash.
- State transitions match expected behavior.
- File system artifacts created correctly.

**Pass criteria:**
- [ ] All UDP commands respond within 1 second
- [ ] State queries return valid JSON
- [ ] Load -> inspect -> activate -> chop -> inspect cycle works
- [ ] Panic clears state correctly
- [ ] Save/reload preserves state
- [ ] No Max console errors during the sequence

---

## Summary: Workflow-to-Feature Traceability

| Workflow | Features Tested |
|----------|----------------|
| UAT-01 | INST-01, INST-02, INST-03, PERF-01, PERF-04, PERF-05, PERF-14, PERF-15 |
| UAT-02 | CUR-01 through CUR-10, PERF-01, PERF-04, PERF-05 |
| UAT-03 | CUR-10, CUR-13, PERF-01, PERF-05, PERF-11, PERF-18, INST-04 |
| UAT-04 | CUR-09, ARR-01 through ARR-12, ARR-14 |
| UAT-05 | CUR-11, CUR-12, CUR-01, CUR-10, PERF-01 |
| UAT-06 | CUR-13, INST-04, PERF-01, PERF-05 |
| UAT-07 | PERF-01, PERF-04, PERF-05, PERF-21 |
| UAT-08 | PERF-06 |
| UAT-09 | PERF-07, PERF-06 |
| UAT-10 | PERF-09, PERF-10 |
| UAT-11 | PERF-04, PERF-05, PERF-10 |
| UAT-12 | PERF-16, PERF-04, PERF-05, PERF-10 |
| UAT-13 | PERF-11, PERF-18, PERF-01 |
| UAT-14 | PERF-01 |
| UAT-15 | PERF-01, PERF-02, PERF-05 |
| UAT-16 | PERF-01, PERF-02 |
| UAT-17 | PERF-01, PERF-04, PERF-05 |
| UAT-18 | ARR-09 |
| UAT-19 | CUR-09, ARR-03, ARR-14 |
| UAT-20 | CAL-01 through CAL-05 |
| UAT-21 | PERF-20, PERF-01, PERF-04, PERF-05, PERF-16, PERF-17 |

### Features with NO workflow coverage

The following features from the inventory have no dedicated UAT workflow above. They are either tested implicitly as part of other workflows or are infrastructure features:

| Feature ID | Name | Reason |
|------------|------|--------|
| CUR-14 | track_id YAML support | Implicitly tested in UAT-02 if YAML uses track_id |
| PERF-03 | Vocal warp grid application | Implicitly tested in UAT-02, UAT-13 (vocal full_stem) |
| PERF-08 | Per-row mode | Implicitly tested in UAT-09 (scene with per-row), UAT-12 (panic from per-row) |
| PERF-12 | Launchpad MK2 surface | Implicitly tested in every performance UAT |
| PERF-13 | Launchpad MK3 surface | Not deployed — no test needed |
| PERF-19 | Sync from Live | Infrastructure feature — testable in UAT-21 extension |
| PERF-21 | Status display | Implicitly verified in every workflow |
| ARR-02 | Track creation/resolution | Implicitly tested in UAT-04 |
| ARR-04-08 | Clip/loop/warp/tempo/clear | Implicitly tested in UAT-04 |
| ARR-10 | Snapshot export | Explicitly tested in UAT-04 step 14 |
| ARR-11-12 | Alias/adapter | Implicitly tested in UAT-04 |
| ARR-13 | UDP interface | Implicitly tested in UAT-04 |
| INST-02 | Max Package | Implicitly tested in UAT-01 |
