# setforge-live — build specification

**Status:** v0 spec · pre-implementation
**Repo:** `m4l-devices` (worktree branch `worktree-setforge-live`)
**Location in repo:** `device/setforge-live/`
**Companion repos:** `stemforge` (provides manifests + overrides), `taste` (provides curated setlists)

---

## 0. What this device family is

setforge-live is an MLR-paradigm stem performance environment for Ableton Live, driven by two Novation Launchpad Pro grids (64 pads each, 128 total). It consumes the deck-manifest contract already produced by `stemforge` + drum-stem calibration and turns a curated setlist into a playable live instrument with no realtime DSP cleverness — every chop is derived from `(bpm, downbeat_sec, bar_index)` at clip-load time.

The family is **two Max for Live devices** that share a manifest format and a small helper library:

- **`setforge-loader.amxd`** — the performance device. Runs during the set. Drives both Launchpads. Owns chop routing, preset banks, scene memory, modifier layer, FX bus, transport.
- **`setforge-calibrate.amxd`** — the validation device. Runs once per track during setup. Single-stem audition with a live warp-marker UX that writes back to `calib_override.json` sidecars. Never used live.

Both devices read the same `manifest.json` schema (see §3). The calibrator additionally writes per-track override files that the manifest emitter (upstream in `stemforge`) folds in on next emit.

---

## 1. Scope and non-goals

### In scope (v0)

- Two-device family, both Max for Live audio effects.
- Performance loader for up to 16 simultaneously-loaded songs across two preset banks.
- 4 stems × 8 bar-aligned chops per song.
- Calibrator-validator using native Live warp-marker gesture.
- Launchpad Pro mk3 support (USB MIDI, RGB feedback, per-row launch quantization).
- Stem-targeted FX bus (filter sweep + delay/verb throws).
- 8-slot scene memory per loaded song.
- Per-row launch quantization (drums 1/16, bass 1 bar, other 1/4, vox 1/2; manifest-overridable).
- Two-tier set arc: bank-A (8 presets) + bank-B (8 presets) with mid-bar swap.

### Out of scope (v0, deferred)

- Push 2/3 support (Launchpad first; Push wrapper if useful later).
- Tempo-varying tracks beyond a `varying: true` "play full track only, no chop" flag.
- MIDI clock out / sync to external gear.
- Per-stem key shifting (decks are tempo-matched only).
- Recording the live set to an arrangement (use Live's own session record).
- Auto-resolution of BPM octaves via online DBs (that's `stemforge` Phase 2).
- Setlist authoring UI (that lives in `taste`).

### Non-goals (will not be added)

- Crossfader-style A/B deck mixing. This is MLR, not Serato.
- BPM detection inside the device. The device trusts the manifest; analysis is `stemforge`'s job.
- Custom stem separation. The device consumes pre-split stems.

---

## 2. UX specification — `setforge-loader.amxd`

### 2.1 Device front panel (in Live's device chain)

The device front panel is minimal. The actual UX is on the two Launchpads; the device panel is for state visibility, not for performance.

```
┌─ setforge-loader ──────────────────────────────────────────────┐
│                                                                │
│  set: [▼ hiphop_v3.json        ]   load   reload   eject       │
│                                                                │
│  ┌─ status ─────────────────────────────────────────────────┐  │
│  │ bank A: dre · jay · tribe · j5 · bstar · nextep · _ · _  │  │
│  │ bank B: aphex · sqp · 4tet · flpts · burial · _ · _ · _  │  │
│  │ active preset: A·C  (the next episode)                   │  │
│  │ active scene:  —                                         │  │
│  │ launchpad 1: ✓ connected  (mk3, port 1)                  │  │
│  │ launchpad 2: ✓ connected  (mk3, port 2)                  │  │
│  │ tempo: 94.0 bpm  (global)    drift since load: 0.00      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
│  [ master ▢ ]  [ fx target: bass ]  [ ⚠ panic ]                │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Front-panel controls:**

| Control | Behavior |
|---|---|
| `set ▼` chooser | Lists `*.set.json` files from the configured set directory. Selecting reloads. |
| `load` | Re-parses currently selected set, drops stems into hidden audio tracks, places initial warp markers. |
| `reload` | Same as load but preserves currently held chops in memory. Use after editing a manifest mid-rehearsal. |
| `eject` | Stops all clips, clears all preset slots, returns Launchpads to idle state. Does NOT power-cycle Launchpads. |
| `master ▢` | Bypass toggle. Mutes device output without unloading state. For "I need to use Spotify for 5 seconds" emergencies. |
| `fx target` | Mirrors Grid 2 row 5's target selector. Read-only display; sync from Grid 2. |
| `⚠ panic` | Mirrors Grid 2 row 8's panic pad. Triggerable from screen too (for screen-share / mouse contexts). |

**No knobs.** Everything dynamic is on the Launchpads. The screen is for diagnostics.

### 2.2 Grid 1 — the performance grid (full pad-by-pad spec)

8 rows × 8 columns. Each pad has a fixed function. The diagram below uses these conventions:

- **D1..D8** = drums chop 1 through 8 (drum stem of currently-active preset, in 4-bar windows)
- **B1..B8** = bass chops
- **O1..O8** = other chops
- **V1..V8** = vox chops
- **PA..PH** = preset slots 1-8 (bank A)
- **PI..PP** = preset slots 9-16 (bank B)
- **HOLD/MUTE/SOLO/REV/STUT/HALF/DBL/KILL** = modifiers (momentary)
- **SA..SH** = scene slots 1-8

```
        col 1   col 2   col 3   col 4   col 5   col 6   col 7   col 8
row 1   PA      PB      PC      PD      PE      PF      PG      PH        bank A presets
row 2   D1      D2      D3      D4      D5      D6      D7      D8        drums chops
row 3   B1      B2      B3      B4      B5      B6      B7      B8        bass chops
row 4   O1      O2      O3      O4      O5      O6      O7      O8        other chops
row 5   V1      V2      V3      V4      V5      V6      V7      V8        vox chops
row 6   HOLD    MUTE    SOLO    REV     STUT    HALF    DBL     KILL      modifiers (momentary)
row 7   PI      PJ      PK      PL      PM      PN      PO      PP        bank B presets
row 8   SA      SB      SC      SD      SE      SF      SG      SH        scenes
```

#### Row 1 + Row 7 — Preset banks (16 slots)

**State per pad:** `empty` | `loaded_idle` | `loaded_active` | `loading` | `error`

**Color encoding (Launchpad Pro RGB):**

| State | Color | Notes |
|---|---|---|
| empty | dim white (rgb 16,16,16) | no song assigned |
| loaded_idle | dim song-color (manifest `color_hue`) | song loaded, not active |
| loaded_active | bright song-color, pulsing | currently sourcing rows 2-5 |
| loading | blinking white | stems still streaming to disk; do not chop yet |
| error | bright red, slow blink | stems missing or manifest invalid |

**Press behaviors:**

| Gesture | Result |
|---|---|
| Tap (down + up) | Make this preset active. Rows 2-5 re-source from this song's chops. **Any currently-held chops in those rows continue playing until their loop boundary, then snap to the new song's same column.** This is the load-bearing swap mechanic. |
| Long-press (≥500ms) | Open the "load into slot" gesture from Grid 2. While long-pressed, Grid 2 enters setlist-load mode (see §2.3). Release on Grid 2 setlist pad to load that track here. |
| Shift + tap (where shift = HOLD) | Switch active preset *without* migrating held chops. The held chops stop at boundary. Use this for a hard rebuild of the playing material. |

**Loading behavior:** When `load` is pressed on the device, all 16 slots are populated from the set JSON. Stems are streamed to Live's hidden audio tracks asynchronously. Until a slot is `loaded_idle`, pressing its pad does nothing and emits a `loading` blink on the pad.

**Bank-pair convention:** A typical "bank" is 6-8 songs in row 1 (bank A) for one genre, plus a contrasting 6-8 in row 7 (bank B) for the transition target. Both are loaded simultaneously. Mid-set rotation is via Grid 2 long-press (see set-arc workflow).

#### Rows 2-5 — Stem chops (32 pads)

These are the playable instrument. Each row is one stem of the currently-active preset; each column is the start of a 4-bar window in that stem.

**Chop derivation (load-time computation, never realtime):**

```
For preset P with manifest fields { bpm, downbeat_sec, stems.{drum,bass,other,vox}.path }:

  For each column c in 1..8:
    bar_index   = (c - 1) * 4
    clip_start  = downbeat_sec + (bar_index * 4 * 60 / bpm)
    clip_length = 4 * 4 * 60 / bpm     # 4 bars at this BPM

  At preset activation, write 32 audio clips into hidden audio tracks:
    track "drums"  has 8 clips: clip[c].start_marker = clip_start(c, drum_path)
    track "bass"   has 8 clips: ...
    track "other"  has 8 clips: ...
    track "vox"    has 8 clips: ...

  Each clip's first warp marker is the song's downbeat_sec.
  Each clip's launch quant is per-row (see §2.5).
```

**State per pad:** `empty` (stem missing for this clip) | `loaded` | `playing` | `cued` | `disabled` (preset flagged `varying: true`)

**Color encoding:**

| State | Color | Notes |
|---|---|---|
| empty | off | stem absent for this song |
| loaded | stem-color soft (drums #ffe5dc, bass #dbeaff, other #f0efe9, vox #dcf2e4) | ready to play |
| playing | stem-color bright, solid | currently looping |
| cued | stem-color bright, blinking on the launch-quant interval | will start at next quant boundary |
| disabled | dim red | preset is `varying`, chop math doesn't apply |

**Press behaviors:**

| Gesture | Result |
|---|---|
| Tap | Toggle: if not playing, schedule start at next quant boundary in this row. If playing, schedule stop at next boundary. |
| Tap while another chop in same row is playing | Replace: the other chop stops, this one starts, both at the same quant boundary (no overlap, no gap). |
| Hold + tap (HOLD = row 6 col 1 momentary) | One-shot: chop plays once for its full length (4 bars) and stops, regardless of quantization. |
| Modifier + tap (REV/STUT/HALF/DBL/KILL held on row 6) | Apply modifier to this chop while held. See §2.4. |

**Multi-row interaction:** Up to 4 chops can be active simultaneously (one per stem row). They all share the global tempo and are phase-locked to the global grid. There is **no per-row tempo nudge**; if you need de-syncing, that's a manifest-level decision.

#### Row 6 — Modifiers (8 pads, all momentary)

Modifiers act on whatever chop is pressed *while the modifier is held*. They are momentary: release the modifier, behavior reverts. If you tap a modifier alone (no chop), nothing happens.

| Pad | Name | While held + chop tap |
|---|---|---|
| col 1 | **HOLD** | Chop plays as one-shot (not loop), regardless of row default |
| col 2 | **MUTE** | Chop is scheduled but muted — useful for re-syncing without sound |
| col 3 | **SOLO** | All other stem rows muted while held |
| col 4 | **REV** | Chop plays in reverse |
| col 5 | **STUT** | Chop retriggers every 1/8 note while modifier held |
| col 6 | **HALF** | Chop plays at half-speed (octave down, half tempo) |
| col 7 | **DBL** | Chop plays at double-speed (octave up, double tempo) |
| col 8 | **KILL** | Currently-playing chop in the *tapped row* is silenced until KILL released |

**Modifier-only gestures (no chop tap):**

| Modifier double-tap | Latches the modifier (no need to hold). Tap again to release. |
| --- | --- |
| HOLD double-tap | Locks the "switch preset without migrating chops" behavior. |
| SOLO double-tap | Latches solo on whatever was last soloed. |
| KILL double-tap | Latches KILL on the currently-targeted stem (per FX target on Grid 2). |

**Modifier color:**

| State | Color |
|---|---|
| Idle | dim white |
| Held | bright white |
| Latched (double-tap) | bright yellow |

#### Row 8 — Scenes (8 pads)

A scene is a **snapshot of the entire Grid 1 state**, recallable in one tap. Specifically:

- Which preset is active
- Which chop is playing in each of rows 2-5 (or none)
- Modifier latch state
- Per-row mute/solo state

**Authoring (offline, in the set JSON):** scenes are pre-built in the set file. See `set.json` schema (§3.2).

**State per pad:** `empty` | `built` | `playing`

| State | Color |
|---|---|
| empty | off |
| built | dim purple |
| playing (last triggered) | bright purple, solid |

**Press behaviors:**

| Gesture | Result |
|---|---|
| Tap | Recall scene: change active preset (if scene specifies), retrigger chops in each row to match scene state, all on next bar boundary. |
| Hold + tap | "Build mode": memorize current Grid 1 state into this scene slot. Updates `set.json` if `auto_save_scenes: true`. |
| Long-press (≥500ms) | Open scene-edit screen on device front panel (post-v0). |

**The bridge convention:** scene G is reserved by convention for "outro to one stem" (the bridge-out move). Scene A is reserved for "intro/anchor" (the bridge-in move). Other scenes are per-song improvisation snapshots.

### 2.3 Grid 2 — the control grid (full pad-by-pad spec)

8 rows × 8 columns. Two zones: top half (rows 1-4) is navigation, bottom half (rows 5-8) is FX + transport.

```
        col 1   col 2   col 3   col 4   col 5   col 6   col 7   col 8
row 1   T01     T02     T03     T04     T05     T06     T07     T08      setlist tracks 1-8
row 2   T09     T10     T11     T12     T13     T14     T15     T16      setlist tracks 9-16
row 3   T17     T18     T19     T20     T21     T22     T23     T24      setlist tracks 17-24
row 4   T25     T26     T27     T28     T29     T30     T31     T32      setlist tracks 25-32
row 5   DRM     BASS    OTH     VOX     ALL     DECKA   DECKB   MSTR     fx target select
row 6   F1      F2      F3      F4      F5      F6      F7      F8       fx-A (filter, lp→hp)
row 7   X1      X2      X3      X4      X5      X6      X7      X8       fx-B (throws)
row 8   TAP     SYNC    BPM-    BPM+    LI      LO      REC     PANIC    transport
```

#### Rows 1-4 — Setlist map (32 pads)

Each pad represents one track in the current set, indexed by position in `set.tracks[]`. Color is derived from the track's genre:

| Genre | Color |
|---|---|
| `hiphop` | warm orange (#ff8c5a) |
| `idm` | cool blue (#5aa0ff) |
| `ambient` | soft green (#5acf8c) |
| `rock` | neutral grey (#a0a0a0) |
| `funk` | yellow (#ffcc4d) |
| custom | manifest `color_hue` value |

**Brightness encodes energy** (manifest `energy: 0.0-1.0`): dim = low energy intro/outro, bright = peak energy.

**State indicators:**

| State | Visual |
|---|---|
| Track loaded into a Grid 1 preset slot | Solid color, normal brightness |
| Track is currently active preset (sourcing chops) | Solid color, pulsing slowly (every bar) |
| Track is cued for next preset swap | Blinking on bar boundary |
| Track flagged `varying: true` | Color with red border-pulse — playable as full track only, no chops |
| Track not yet in any preset slot | Color, half brightness |

**Press behaviors:**

| Gesture | Result |
|---|---|
| Tap | Pre-listen in headphones (cue bus). Plays full mix at low volume. Tap again to stop. |
| Double-tap | Cue this track for next preset swap. Next time you tap an empty/replaceable preset slot on Grid 1, this track loads there. |
| Long-press (≥500ms) | "Load into slot" mode: Grid 1 enters slot-pick state, you tap a Grid 1 preset pad to drop this track there. Existing slot contents are unloaded. |
| Shift (HOLD held on Grid 1) + tap | Force-load to next empty slot. If no empty slots, do nothing. |

#### Row 5 — FX target select (8 pads)

Determines which audio stream the rows 6-7 FX apply to.

| Pad | Target | Color when selected |
|---|---|---|
| col 1 | DRM (drums stem of active preset) | drums-color bright |
| col 2 | BASS | bass-color bright |
| col 3 | OTH | other-color bright |
| col 4 | VOX | vox-color bright |
| col 5 | ALL (sum of stems) | white bright |
| col 6 | DECKA (entire bank-A bus) | yellow |
| col 7 | DECKB (entire bank-B bus) | yellow |
| col 8 | MSTR (post-master) | red |

**Behavior:** exclusive selection (radio buttons). Last-tapped target wins. Selection persists until changed. Multiple targets at once is out of scope for v0.

#### Row 6 — FX-A filter sweep (8 pads)

A discrete 8-position filter applied to the current target:

| Pad | Filter state |
|---|---|
| col 1 | LP fully closed (silence) |
| col 2 | LP 100 Hz |
| col 3 | LP 300 Hz |
| col 4 | Bypass (open, dry) — default |
| col 5 | HP 300 Hz |
| col 6 | HP 1 kHz |
| col 7 | HP 3 kHz |
| col 8 | HP fully open (near-silence) |

**Behavior:** momentary by default (release returns to bypass at col 4). Double-tap latches a position. Latched position has solid bright color; momentary has soft glow.

**Implementation:** internal SVF, slope 12dB/oct, resonance 0.3. Not user-adjustable in v0 (manifest-overridable in future).

#### Row 7 — FX-B throws (8 pads)

Eight one-shot effects that fire as long as held:

| Pad | Effect |
|---|---|
| col 1 | Quarter-note delay (3 feedback taps, sync to global tempo) |
| col 2 | Eighth-note delay (5 taps) |
| col 3 | Dotted-8th delay (4 taps) |
| col 4 | Triplet-8th delay (5 taps) |
| col 5 | Short verb (1.2s plate) |
| col 6 | Long verb (4.5s hall, freeze-style) |
| col 7 | Freeze (capture current buffer, loop it under live signal) |
| col 8 | Bitcrush + decimation (8-bit, 12kHz) |

**Behavior:** momentary. Release returns to dry. Effects do NOT stack (last-pressed wins).

#### Row 8 — Transport (8 pads)

| Pad | Function |
|---|---|
| col 1 | **TAP** — Tap tempo. 4 taps over 3 sec sets global BPM. Should rarely be needed. |
| col 2 | **SYNC** — Snap Live's transport to bar boundary. |
| col 3 | **BPM-** — Nudge global BPM down 0.1. Hold for continuous nudge. |
| col 4 | **BPM+** — Nudge global BPM up 0.1. Hold for continuous nudge. |
| col 5 | **LI** — Loop In at current bar. |
| col 6 | **LO** — Loop Out at current bar. |
| col 7 | **REC** — Toggle session record (captures performance to a new arrangement). |
| col 8 | **PANIC** — Stop all clips, clear all chops, reset FX to bypass. Bright red, slow blink when triggered. Triple-tap to confirm (prevents accidental kill). |

### 2.4 Per-row launch quantization (per-stem-row default)

Each stem row in Grid 1 has its own default launch quantization. Manifest can override per-clip.

| Row | Default quant | Reasoning |
|---|---|---|
| Drums (row 2) | 1/16 | Allows stutter and fast retriggers |
| Bass (row 3) | 1 bar | Bass entries on bar boundaries stay musical |
| Other (row 4) | 1/4 | Mid-flexibility for chords/pads |
| Vox (row 5) | 1/2 | Half-bar entries sound deliberate, full-bar mechanical |

Quantization is enforced by Live's launch-quant system on the underlying clips. The device sets `Clip.launch_quantization` at clip-creation time.

### 2.5 The hot-swap mechanic (load-bearing detail)

When the user taps a new preset pad on Grid 1 row 1 or row 7:

1. The device looks up which chops are currently playing in rows 2-5 (call them `held[]`: list of `(row, col)` tuples).
2. For each `(row, col)` in `held`:
   - Determine the corresponding chop in the new preset (same row, same col).
   - At the next launch-quant boundary for that row, stop the current chop and start the new one.
3. The preset color on row 1/7 transitions: old preset goes `loaded_active → loaded_idle`, new preset goes `loaded_idle → loaded_active`.
4. Scene state (row 8) is preserved across swap.
5. Modifier latch state (row 6) is preserved across swap.

**Edge case — new preset is missing a stem the user had held:** the held chop stops at boundary and does not restart (no silent loop). The pad lights `error` briefly.

**Edge case — new preset is flagged `varying: true`:** the swap proceeds but rows 2-5 light `disabled`; the user can still play the full track via a special pad gesture (see §2.6).

### 2.6 Tempo-varying track playback

Tracks flagged `varying: true` in the manifest cannot be chopped. They can still be played as full-track entries:

- Their setlist pad on Grid 2 has a red border-pulse.
- When loaded into a Grid 1 preset slot, rows 2-5 light `disabled` (dim red).
- Pressing **Row 2, col 1 (D1)** on a varying preset plays the full mix track from `0:00`. No quantization, no chops.
- All other chop pads do nothing on a varying preset.
- The track can be FX'd from Grid 2 normally.

This is a deliberate UX dead-end: varying tracks are second-class citizens by design, not by neglect.

---

## 3. Data formats

### 3.1 Manifest schema (consumed; defined upstream in stemforge)

```json
{
  "schema_version": "2.0",
  "set_id": "hiphop_v3",
  "global_tempo_hint": 94.0,
  "tracks": [
    {
      "id": "the_next_episode",
      "display_name": "the next episode",
      "artist": "dr. dre",
      "bpm": 94.7,
      "downbeat_sec": 2.31,
      "drift_bpm": 0.05,
      "grid_tightness_ms": 11.8,
      "octave_confidence": "verified",
      "varying": false,
      "energy": 0.7,
      "genre": "hiphop",
      "color_hue": "#ff8c5a",
      "stems": {
        "drums": { "path": "/abs/path/drums.wav", "sha": "..." },
        "bass":  { "path": "...", "sha": "..." },
        "other": { "path": "...", "sha": "..." },
        "vox":   { "path": "...", "sha": "..." }
      },
      "chop_quant_override": null,
      "validated": true,
      "validated_at": "2026-05-20T18:30:00Z"
    }
  ]
}
```

**Fields the loader reads:**
- `bpm`, `downbeat_sec` — chop math
- `varying` — disables chops
- `stems.*.path` — clip sourcing
- `energy`, `genre`, `color_hue` — Grid 2 visualization
- `validated` — gate on whether to surface this track to the live set (filter in loader UI)
- `chop_quant_override` — per-row override of default quantization

### 3.2 Set JSON (the live-set definition, authored in `taste`)

```json
{
  "schema_version": "1.0",
  "name": "hiphop_v3",
  "global_tempo": 94.0,
  "preset_bank_A": [
    { "track_id": "the_next_episode", "scenes": [...] },
    { "track_id": "big_poppa", "scenes": [...] },
    null, null, null, null, null, null
  ],
  "preset_bank_B": [
    { "track_id": "aphex_minipops", "scenes": [...] },
    null, null, null, null, null, null, null
  ],
  "setlist": [
    "the_next_episode", "big_poppa", "aphex_minipops", ...
  ]
}
```

The 16 preset slots are explicitly null-able; setlist is a flat array of 32 entries (track IDs) for Grid 2.

### 3.3 Calibration override sidecar (written by calibrator)

```json
{
  "track_id": "the_next_episode",
  "downbeat_sec": 2.27,
  "validated_at": "2026-05-20T18:30:00Z",
  "method": "warp_marker_drag",
  "delta_from_auto_sec": -0.04
}
```

Lives at `<stem_dir>/.calib_override.json`. On next manifest emit by `stemforge`, this overrides the auto-calibrated value.

---

## 4. UX specification — `setforge-calibrate.amxd`

A standalone single-track device for downbeat validation. Used during set prep; not used live.

### 4.1 Front panel

```
┌─ setforge-calibrate ────────────────────────────────────────────┐
│                                                                 │
│  track:  [▼ the_next_episode    ]   load   next ▶               │
│                                                                 │
│  stem:   ● drums  ○ bass  ○ other  ○ vox                        │
│                                                                 │
│  calibrated downbeat:  2.31 sec  (auto)                         │
│  current marker:       2.27 sec  (delta -0.04 sec)              │
│                                                                 │
│  [ ▶ audition ] [ click 🔔 ] [ ✓ validated ] [ ↺ revert ]       │
│                                                                 │
│  set state: 12 of 32 validated · 18 unverified · 2 red          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 The flow per track

1. **Load** — Device drops the selected stem into a Live audio track named `calibrate-audition`. Warp on, mode complex-pro, auto-warp off, first warp marker placed at manifest's `downbeat_sec`. A 4-bar loop is set from 1.1.1 to 5.1.1.
2. **Audition** — Hit `▶ audition`. Live transport starts; loop plays 4 bars; metronome click is armed on the same beat 1.
3. **Validate by ear** — If kicks line up with click ticks, hit `✓ validated`. Done.
4. **Nudge if not** — Grab the warp marker at 1.1.1 with mouse (or use Live's native arrow-key nudge — left/right while marker selected). Move it until kick locks to click. The device observes `Clip.warp_markers` changes and updates `current marker` display in real time. **No save button**: when you hit `✓ validated`, current marker value writes to `.calib_override.json`.
5. **Next** — `next ▶` advances to the next unverified track in the set.

### 4.3 Listener for warp-marker changes (M4L plumbing)

```
clip = live_set.tracks["calibrate-audition"].clip_slots[0].clip
clip.warp_markers observer →
  marker_zero = clip.warp_markers[0]   # always exists if warp is on
  current_downbeat_sec = marker_zero.sample_time
  device.display.current_marker_sec = current_downbeat_sec
  # NB: does NOT write to disk yet. Disk write happens on ✓ validated.
```

### 4.4 Set-level state machine

The calibrator tracks per-track validation state across the set:

| State | Visual on track dropdown |
|---|---|
| `green_auto` | green dot — auto-cal passed all thresholds, skip recommended |
| `yellow_pending` | yellow dot — needs listen |
| `red` | red dot — auto-cal failed or stem missing |
| `validated_by_ear` | solid green checkmark — user confirmed |
| `varying` | greyed out — flagged tempo-varying, no calibration applies |

A set is "calibration-complete" when every non-`varying` track is either `green_auto` (acceptable) or `validated_by_ear`. The device shows this count in the front-panel summary.

### 4.5 Stem-selection affordance

Default audition stem is `drums` (calibration is drum-anchored). User can audition other stems against the same grid to spot-check phase alignment. Switching the stem selector reloads the audition clip; the warp marker stays at the same time value (just shown against a different audio stream).

---

## 5. Architecture & file layout

```
device/setforge-live/
├── spec/
│   └── setforge-live-spec.md          ← this file
│
├── src/
│   ├── loader/
│   │   ├── setforge-loader.amxd       ← Max patch (binary)
│   │   ├── loader.js                  ← top-level JS controller
│   │   ├── chop-router.js             ← pad → (stem, bar) → clip start
│   │   ├── preset-banks.js            ← 16-slot state machine
│   │   ├── scene-memory.js            ← scene snapshot save/recall
│   │   ├── modifier-layer.js          ← row 6 momentary/latch logic
│   │   ├── fx-bus.js                  ← filter + throws routing
│   │   └── launchpad-surface.js       ← 2× Launchpad MIDI I/O, RGB writes
│   │
│   ├── calibrator/
│   │   ├── setforge-calibrate.amxd    ← Max patch (binary)
│   │   ├── calibrate.js               ← top-level
│   │   ├── audition-clip.js           ← load stem, place markers, watch changes
│   │   └── override-writer.js         ← writes .calib_override.json
│   │
│   └── shared/
│       ├── manifest-reader.js         ← parses manifest.json + set.json
│       ├── chop-math.js               ← the load-bearing one-liner
│       ├── live-api-helpers.js        ← LiveAPI boilerplate
│       └── color-palette.js           ← stem/genre/state color constants
│
├── tests/
│   ├── harness/
│   │   ├── mock-launchpad.js          ← simulates Launchpad MIDI in/out
│   │   ├── mock-live-api.js           ← simulates LiveAPI surface
│   │   ├── fixture-loader.js          ← loads fixture manifests
│   │   └── README.md                  ← how to run the harness
│   │
│   ├── fixtures/
│   │   ├── manifests/
│   │   │   ├── hiphop_v3.set.json     ← canonical happy-path set
│   │   │   ├── mixed_genre.set.json   ← cross-bank test
│   │   │   ├── varying_track.set.json ← contains a SICKO MODE-class track
│   │   │   ├── missing_stem.set.json  ← drums.wav not on disk
│   │   │   └── invalid_bpm.set.json   ← bpm = 0, error case
│   │   │
│   │   ├── stems/
│   │   │   └── synthetic/              ← procedurally-generated test stems
│   │   │       └── README.md           ← how the fixtures were made
│   │   │
│   │   └── expected/
│   │       └── chop-math/              ← expected clip_start values for each fixture
│   │           └── *.json
│   │
│   ├── unit/
│   │   ├── chop-math.test.js
│   │   ├── manifest-reader.test.js
│   │   ├── preset-banks.test.js
│   │   ├── scene-memory.test.js
│   │   ├── modifier-layer.test.js
│   │   ├── color-palette.test.js
│   │   └── override-writer.test.js
│   │
│   └── integration/
│       ├── load-set.test.js           ← load a set, verify all 16 slots populate
│       ├── chop-trigger.test.js       ← MIDI in → clip launch sequence
│       ├── preset-swap.test.js        ← hot-swap with held chops
│       ├── scene-recall.test.js
│       ├── calibrate-flow.test.js     ← load track, move marker, verify override file
│       └── panic.test.js              ← all-stop, all-clear semantics
│
└── docs/
    ├── pad-reference-card.md           ← printable cheat sheet
    ├── setup-guide.md                  ← first-time-running instructions
    ├── manifest-format.md              ← duplicate of §3 for standalone reading
    └── troubleshooting.md
```

### 5.1 Cross-cutting principles

- **Manifest reads happen once at load.** Realtime path never parses JSON.
- **All MIDI I/O is on a dedicated thread.** The JS scheduler is allowed to lag; MIDI cannot.
- **Color writes are coalesced per-bar.** Updating all 128 pads on every event would saturate USB MIDI; batch and send on the bar.
- **State is in JS objects, not in Max attributes.** Save/restore explicitly via JSON on set load.

---

## 6. Testing plan

Three tiers: unit → integration → acceptance.

### 6.1 Unit tests (Tier 1, runs in CI on every commit)

**Stack:** Node.js + Mocha + Chai. JS modules in `src/shared/` and `src/loader/*.js` are written as pure functions where possible, importable by Node.

| Module under test | Test file | Key cases |
|---|---|---|
| `chop-math.js` | `chop-math.test.js` | `clip_start(c, bpm, downbeat)` returns expected sec for canonical inputs; handles c=0 edge; handles varying flag; handles missing fields gracefully |
| `manifest-reader.js` | `manifest-reader.test.js` | Parses well-formed manifest; rejects missing required fields; tolerates extra fields; resolves stem paths |
| `preset-banks.js` | `preset-banks.test.js` | Slot assignment; eviction; finding a slot by track_id; "find next empty"; bank A vs bank B separation |
| `scene-memory.js` | `scene-memory.test.js` | Snapshot → recall round-trip; partial snapshots (no chops held); cross-preset scene recall |
| `modifier-layer.js` | `modifier-layer.test.js` | Momentary press/release; double-tap latch; latch release; mutual exclusion (only one modifier latched at a time) |
| `color-palette.js` | `color-palette.test.js` | Genre → RGB triple; state → RGB triple; brightness scaling |
| `override-writer.js` | `override-writer.test.js` | Writes file at expected path; preserves existing fields on partial update; atomic write (tmp + rename) |

**Run command:** `npm test --workspace device/setforge-live`

**Coverage target:** 90% for `src/shared/`, 80% for `src/loader/`. Calibrator code aims for 80% (some of it is inherently Live-API-bound).

### 6.2 Integration tests (Tier 2, runs in CI nightly + on pre-merge)

Uses the mock harness (`tests/harness/mock-launchpad.js`, `tests/harness/mock-live-api.js`). Each test exercises a complete pad-press → behavior pipeline without needing actual Live or actual Launchpads.

**Critical paths to cover:**

| Path | Test | Pass criteria |
|---|---|---|
| Cold load → ready | `load-set.test.js` | Loading a fixture set populates all preset slots, computes correct chop offsets, lights pads correctly within 2 sec mock-time |
| Single chop trigger | `chop-trigger.test.js` | MIDI note-on for (row 2, col 3) → clip-launch call to mock LiveAPI with correct start_marker; pad lights `playing`; quant boundary respected |
| Preset hot-swap | `preset-swap.test.js` | With chops held in rows 2+3, tapping new preset → mock LiveAPI receives stop-old + start-new calls for those rows on next quant boundary |
| Scene recall | `scene-recall.test.js` | Tapping scene A → preset changes + chops re-trigger to match scene state |
| Calibrator marker change | `calibrate-flow.test.js` | Mock LiveAPI emits warp_markers change → device updates display → tapping `validated` writes correct JSON to mock filesystem |
| Panic | `panic.test.js` | Triple-tap panic → all mock-LiveAPI clip slots receive stop; modifier state cleared; FX bypassed |
| Missing stem | `load-set.test.js::missing_stem` | Loading manifest with missing-stem fixture → pad lights `error`, no crash, other slots still load |
| Varying track | `load-set.test.js::varying` | Loading set with varying-flagged track → preset slot loads, rows 2-5 light disabled, full-mix-play pad (D1) responds, other chops no-op |

**Mock harness rules:**
- `mock-launchpad.js` records all RGB writes and emits scripted MIDI input. Tests assert on the recorded RGB sequence.
- `mock-live-api.js` records all `LiveAPI` calls (clip creation, marker placement, transport, etc.) and lets tests pre-script return values.
- Tests should assert on **observable behavior** (MIDI out, LiveAPI calls), not internal state.

### 6.3 Acceptance tests (Tier 3, manual, runs before any tagged release)

These cannot be automated because they require actual hardware and ears. Run as a checklist before tagging a release.

**Setup acceptance:**
- [ ] Drop `setforge-loader.amxd` onto an audio track in Live 12. Device front panel renders correctly.
- [ ] Plug in two Launchpad Pro mk3s via USB. Device front panel shows both connected within 5 sec.
- [ ] Load the canonical `hiphop_v3.set.json`. All 16 preset slots populate within 30 sec.
- [ ] Both Launchpads show expected idle color pattern (preset rows lit per loaded slots, all stem chop rows dim, transport pad colors correct).

**Performance acceptance:**
- [ ] Tap a preset pad on Grid 1 row 1. That preset goes active (pulses), rows 2-5 light with stem-colored loaded pads.
- [ ] Tap drums chop 1. Within 1 bar, drums audible, pad solid bright.
- [ ] Tap bass chop 1. Within 1 bar, bass joins, both in phase (no audible flam).
- [ ] Tap drums chop 5 while drums chop 1 is playing. Chop 5 replaces chop 1 on next 1/16 boundary.
- [ ] Hold REV (row 6 col 4), tap a chop. Chop plays reversed for as long as REV held.
- [ ] Tap a different preset on row 1. Bass and drums chops migrate to new preset's chop 5 on next boundary (same column, new source).
- [ ] Tap scene G (row 8 col 7). Grid 1 collapses to whatever scene G specifies.
- [ ] Triple-tap panic. All audio stops. All pads return to idle colors.

**Calibrator acceptance:**
- [ ] Drop `setforge-calibrate.amxd` onto an audio track.
- [ ] Load a fixture track. Stem appears in `calibrate-audition` audio track with warp marker at expected position.
- [ ] Hit audition. Loop plays with click.
- [ ] Drag warp marker 50ms earlier. Front panel `current marker` updates in real time.
- [ ] Tap `validated`. `.calib_override.json` written to expected location with expected contents.
- [ ] Tap `next ▶`. Advances to next unverified track in set.

**End-to-end acceptance (the load-bearing one):**
- [ ] Run the full validation flow on a 20-track set: ~30 sec/track × 20 = 10 min.
- [ ] Re-emit the manifest from `stemforge` (picks up overrides).
- [ ] Load the re-emitted set in `setforge-loader`.
- [ ] Pick any two tracks at random, load to bank A. Play drum chops from both simultaneously.
- [ ] Result: kicks lock within ~15 ms (Phase 4 of the existing pipeline plan).

### 6.4 Performance budget tests

| Metric | Target | Method |
|---|---|---|
| Pad press → clip launch latency | < 30 ms | Capture MIDI in timestamp + mock-LiveAPI call timestamp |
| Set load time (16 presets) | < 30 sec | Wall-clock on canonical fixture |
| Bar-boundary RGB update | < 5 ms | Profile in Max's `cpu_meter` |
| Memory footprint after full load | < 250 MB | Max's `mem_meter` after canonical-set load |

Integration tests include perf assertions where deterministic; acceptance tests measure with actual hardware.

### 6.5 Regression discipline

- Every fixture in `tests/fixtures/manifests/` ships with a snapshot of expected chop math in `tests/fixtures/expected/`. CI fails on diff.
- Acceptance test results are recorded in `docs/acceptance-log.md` per release tag.
- The `panic` test is non-negotiable. Any change to FX, transport, or modifier code must re-run it.

---

## 7. Build order (for the implementing Claude / future-Zak)

This is the recommended phasing. Each phase is independently testable.

### Phase 0 — scaffold (this commit)

- Add this spec to `device/setforge-live/spec/`.
- Create directory structure under `src/`, `tests/`, `docs/`.
- Add empty stub `.amxd` files (in Max, save empty patches to lock filenames).
- Add `package.json` for the JS test harness.
- CI green on `npm test` (zero tests, but harness runs).

### Phase 1 — chop math + manifest reader

- Implement `src/shared/chop-math.js` and `src/shared/manifest-reader.js`.
- Write all Tier-1 unit tests for these two.
- Create canonical and edge-case fixtures.
- CI green with real tests.

### Phase 2 — calibrator (smaller, unblocks pipeline)

- Implement `setforge-calibrate.amxd` shell in Max.
- Wire up audition-clip load + warp-marker listener.
- Wire up `override-writer.js` and its unit tests.
- Integration test: `calibrate-flow.test.js`.
- Acceptance test: validate one real track end-to-end.
- **Ship this as v0.1.** Use it to validate the existing 20-track hip-hop set. Generates overrides; re-emits manifests through stemforge.

### Phase 3 — loader skeleton (single Launchpad, single preset)

- Implement `setforge-loader.amxd` shell.
- Single Launchpad surface code.
- One preset slot, no banks. Just verify the chop-pad → clip-launch path works.
- Integration tests: `load-set` (single-track set), `chop-trigger`.
- Acceptance: chop a single track live, single grid, single preset.

### Phase 4 — full Grid 1

- Add row 1+7 preset banks (16 slots).
- Add hot-swap logic.
- Add row 6 modifiers.
- Add row 8 scenes.
- Integration tests: `preset-swap`, `scene-recall`, plus modifier coverage.
- Acceptance: full Grid 1 performance flow.

### Phase 5 — Grid 2

- Second Launchpad surface code.
- Setlist map (rows 1-4).
- FX target + FX A + FX B (rows 5-7).
- Transport (row 8) including panic.
- Integration test: `panic`.
- Acceptance: full two-grid acceptance suite.

### Phase 6 — set arc workflow

- Bank-A/bank-B simultaneous load.
- Long-press load-into-slot from Grid 2.
- Cross-bank transition gestures verified.
- Acceptance: 30-minute set from scratch.

---

## 8. Open questions (for future-Zak)

These do not block v0 but should be revisited before v1:

1. **Push 3 integration.** Push has 64 pads + screens; could it replace one Launchpad? Probably yes for Grid 2 (setlist+FX), no for Grid 1 (you want both hands on the same physical surface).
2. **Multi-target FX.** v0 is single-target; live, you sometimes want "filter just the drums of deck A while reverb-throwing the vox of deck B." Worth designing if it doesn't bloat row 5.
3. **Visual setlist editor.** v0 authors `set.json` in a text editor or via `taste`. A drag-and-drop M4L UI for "drag setlist track onto preset slot" might earn its keep, especially mid-rehearsal.
4. **MIDI clock out.** No external sync in v0. If you ever play with a hardware-using collaborator, you'll want it.
5. **Recording the chop performance to ARRANGEMENT.** Live's session-record-to-arrangement would capture the chop launches as MIDI; you could then re-render the set as a stable arrangement. Probably trivial to enable, just hasn't been tested.

---

## 9. Glossary

| Term | Definition |
|---|---|
| **chop** | A 4-bar window of one stem, addressable by a single pad. |
| **preset** | One song's full stem set + chops + scenes, loadable into one of 16 slots. |
| **bank** | A group of 8 preset slots (row 1 = bank A, row 7 = bank B). |
| **scene** | A snapshot of all Grid 1 state (active preset, held chops, modifier latch), recallable in one tap. |
| **target** | The audio stream FX apply to (one stem, all stems, a bank bus, master). |
| **manifest** | JSON describing one track's stems + tempo + downbeat. Produced by stemforge. |
| **set.json** | JSON describing a full performance setup: 16 presets + 32 setlist tracks. Produced by `taste`. |
| **override** | A `.calib_override.json` sidecar that supersedes the auto-calibrated downbeat for one track. |
| **launch-quant** | Live's clip-launch quantization. Per-row defaults: drums 1/16, bass 1 bar, other 1/4, vox 1/2. |
| **hot-swap** | Changing the active preset while chops are held; held chops migrate to the new preset's same-column chops on the next launch-quant boundary. |
| **bridge** | A scene-pair convention: scene G outros to one stem, scene A intros from one stem. Used between banks. |
| **varying** | A track flagged as having mid-track tempo changes. Cannot be chopped; plays as full mix only. |

---

*End of v0 spec. Next iteration adds Push 3 wrapper, multi-target FX, setlist editor.*
