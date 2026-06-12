# Setforge: forge-set pipeline reference

The complete pipeline for building a setlist of songs that loads into the setforge-loader M4L device.

## Overview

```
Recipe YAML → register → analyze → stem → structure → materialize → export → set.json + manifest.json
```

The pipeline lives in `~/zacharysbrown/taste/` (the `taste` package). Output loads in the setforge-loader device in `~/zacharysbrown/m4l-devices/`.

## Prerequisites

- **Working directory:** `~/zacharysbrown` (parent of the `taste` package)
- **DB:** `~/zacharysbrown/taste/setforge.db` (auto-detected, no `--db` needed)
- **Python:** 3.11+ with `scipy`, `librosa`, `soundfile`, `scikit-learn`, `torch`, `pyyaml`
- **Demucs:** installed (for the `stem` step)
- **Spotify creds:** only needed for the `analyze` step (set `SPOTIPY_CLIENT_ID` or unlock 1Password)

## Step 1: Find your tracks in the DB

Tracks get into the DB via Spotify ingest (`taste ingest-spotify`) or local scan. Check if your tracks exist:

```bash
cd ~/zacharysbrown/taste
sqlite3 setforge.db "SELECT id, title, artist, tempo FROM tracks WHERE title LIKE '%Song Name%';"
```

**Important:** Don't create duplicate rows. If a track already exists (even from Spotify with a different tempo), UPDATE it rather than inserting a new one:

```bash
sqlite3 setforge.db "UPDATE tracks SET local_path='/path/to/file.wav', tempo=120.0, stem_bpm=120.0 WHERE id=EXISTING_ID;"
```

If the track genuinely doesn't exist, the `register` step handles it (see below).

## Step 2: Write the recipe YAML

Create a file in `~/zacharysbrown/taste/sets/<name>.yaml`:

```yaml
name: my_setlist              # output name (used for filenames)
strategy: hiphop              # chop curation strategy (see below)
global_tempo: 95.0            # target tempo for the set
grid_mode: reconciled_continuity  # vocal warp grid mode (always use this)
tracks:
  - track_id: 1834            # existing DB row (preferred)
  - track_id: 5966
  - file: ~/path/to/song.wav  # OR local file (will auto-register)
    artist: "Artist Name"     # optional metadata for file-mode
    title: "Song Title"
```

### Strategies

| Strategy | Use for |
|----------|---------|
| `hiphop` | Hip-hop, rap, boom bap, trap |
| `default` | General purpose |
| `jazz` | Jazz, swing |
| `idm` | IDM, experimental |
| `mashup` | Mashup sets |

If omitted, auto-inferred from the track's `style_tags` in the DB.

### Grid modes

Always use `reconciled_continuity` — it produces the best vocal warp grids. Other modes (`fixed`, `every_bar`) exist but are lower fidelity.

## Step 3: Run the pipeline

### Full pipeline (new tracks, need everything)

```bash
cd ~/zacharysbrown
python -m taste forge-set taste/sets/my_setlist.yaml \
    --steps register,stem,structure,materialize,export \
    --out ~/.cache/setforge/sets/my_setlist \
    --force
```

Skip `analyze` unless you need Spotify features (requires creds). The `register` step handles DB row creation/lookup.

### Back-half only (tracks already stemmed)

```bash
python -m taste forge-set taste/sets/my_setlist.yaml \
    --steps structure,materialize,export \
    --out ~/.cache/setforge/sets/my_setlist \
    --force
```

### Steps explained

| Step | What it does | Skippable? |
|------|-------------|------------|
| `register` | Creates/finds DB rows for each track. File-mode tracks get inserted. | Skip if using `track_id` and rows exist |
| `analyze` | Computes librosa features, fetches Spotify data. Needs creds. | Skip if tracks already have `tempo` in DB |
| `stem` | Runs demucs separation → `~/.cache/setforge/stems/<id>/` | Skip if stems already cached |
| `structure` | Bar grid detection + chop curation + per-track manifest | Required |
| `materialize` | Cuts per-bar chop WAVs with padding + loop markers | Required |
| `export` | Writes `set.json` + `manifest.json` + vocal warp grids | Required |
| `prechop` | Arrangement-mode output (not needed for session) | Skip unless `--mode arrangement` |

### Critical: always use `--force`

Without `--force`, the materializer reuses cached chop WAVs and **skips writing `loop_start_sec`/`loop_end_sec`** into the manifest. This causes clips to load with wrong loop regions. Always use `--force` when rebuilding a set.

## Step 4: Validate

```bash
python ~/zacharysbrown/m4l-devices/schemas/validate.py \
    ~/.cache/setforge/sets/my_setlist/my_setlist.set.json \
    ~/.cache/setforge/sets/my_setlist/my_setlist.manifest.json
```

Both should report `[PASS]`.

## Step 5: Load in Ableton

In the setforge-loader device: **Browse** → navigate to `~/.cache/setforge/sets/my_setlist/my_setlist.set.json`.

### What to expect

- **Drums/bass/other:** 8 pre-cut per-bar chops per stem (fast load, no full-stem warp analysis)
- **Vocals:** 1 full-stem clip with a reconciled warp grid (N warp markers, logged during export)
- **Preset banks:** A1..A8 populated from the setlist order; B bank empty

### Save/load behavior

- **Save** (the device's Save button) calls `fullSave()`:
  1. `syncFromLive()` — reads all clip properties (positions, markers, warp, regions) from Live; removes deleted clips from the manifest via structural-sync
  2. `saveManifest()` — writes the updated manifest (clip state persisted)
  3. `saveSet()` — writes bank assignments to set.json
- **Reload** — reads the saved manifest + set.json; deleted clips stay gone; moved clips stay moved; marker edits preserved
- **Bank clearing:** when loading a new preset, all 8 slots in the target bank are cleared first (no stale clips bleeding through)

## Output structure

```
~/.cache/setforge/sets/my_setlist/
├── my_setlist.set.json              # set definition (schema 1.0)
├── my_setlist.manifest.json         # full manifest (schema 2.1)
├── manifests/
│   ├── 1834.json                    # per-track manifest (intermediate)
│   └── 5966.json
├── 1834/                            # per-track bundle
│   ├── drums/drums_0_main.wav       # pre-cut chop WAVs
│   ├── drums/drums_1_alt_1.wav
│   ├── bass/...
│   ├── other/...
│   └── vocals.wav                   # full stem (warped via .asd sidecar)
└── 5966/
    └── ...
```

## Cache layout

| Path | Contents |
|------|----------|
| `~/.cache/setforge/stems/<id>/` | Demucs stems: `drums.wav`, `bass.wav`, `other.wav`, `vocals.wav`, `stems.json` |
| `~/.cache/setforge/chops/<id>/` | Materialized chop WAVs (intermediate; copied to set output) |
| `~/.cache/setforge/audio/<id>.mp3` | Cached source audio (from Spotify ingest) |
| `~/.cache/setforge/sets/<name>/` | Final set output (what the loader reads) |

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Clips load at wrong positions / wrong loop | Materializer cache hit skipped `loop_start_sec` | Re-run with `--force` |
| "Invalid syntax" on clip creation | HFS path (`Macintosh HD:/...`) | Fixed in loader's `hfsToPosix()` |
| Vocal warp sounds off | Beat detection patchy (check the `filled` count in export log) | Re-anchor with corrected downbeat |
| 40%+ bars "filled" in vocal grid | Drum beat detection failed for this track | Adjust `stem_downbeat` in DB, re-run structure |
| Stale clips from previous preset | Old bug (pre-bank-clear fix) | Update to latest loader.js, restart Ableton |
| Save doesn't persist deletions | Using `save_set` (CC 108) instead of `save` (CC 100) | Use the Save button (calls `fullSave`) |
| Duplicate DB row | Manual SQL insert without checking first | Always check `SELECT ... WHERE title LIKE` first; update existing rows |
