# setforge-live curation — next session handoff

**Date:** 2026-05-29 18:45 PDT
**Last commit:** `7b4c58a` on branch `worktree-setforge-live` (pushed)
**Worktree:** `/Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live`

---

## 0. The one-sentence summary

The curation harness is scaffolded and the loader-side wiring for ops 1–5 (marker edits, per-clip BPM, move, delete, copy) is in place — but the sync's `length_sec` derivation isn't reflecting user loop-edit changes, and the test suite can't pass until that's fixed.

---

## 1. The point of this work

The user (Zak) wants a curation loop where he edits clips in Live's UI — moving markers, changing BPM, dragging clips between slots, deleting, copying — and the changes persist across `save`/reload. That closes a real gap in `taste` (the upstream curation pipeline): taste does ~80% of the curation correctly but he needs to tune the last 20% by hand in Live. Once this works, he can run taste, then sit in Live and polish, then ship.

The test suite verifies persistence programmatically so we don't regress when iterating the loader.

---

## 2. Start here — confirm your environment

```bash
cd /Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live
git status                            # should be clean except for .DS_Store junk
git log --oneline -8 worktree-setforge-live
```

You should see, top to bottom:

```
7b4c58a curation harness — test_op1 simplified to content checks; status doc
b6495a5 sync — positional fallback for legacy clips (no identity)
6331af1 curation harness + identity-based sync (ops 1-5 wired)
d2ea207 REVERT warp-marker removal (mistake)
0f12105 dedicated deckX tracks + LED feedback + warp-marker noise
b4ea2dc fix wrong note numbers in debug harness messages
8132571 truncate File writes (eof = 0) before writing
206ffe2 convert opendialog HFS path to POSIX before JS
```

If you don't see `7b4c58a`, the curation work didn't land — stop and investigate.

---

## 3. What must happen before you can run tests

1. **Restart Ableton Live.** The AbletonOSC remote script in
   `~/Music/Ableton/User Library/Remote Scripts/AbletonOSC/abletonosc/clip.py`
   has `warp_bpm` patched into its rw-properties list (line ~115), but Live
   caches the Python import on first load. Toggling the Control Surface in
   prefs doesn't re-import. A full Live restart is the only way to pick up
   the patch. Without it, OSC `/live/clip/get/warp_bpm` times out and op 2's
   test can't verify BPM writes via OSC.

2. **Reload the loader device** in Live's set (right-click device header →
   reload, or remove + re-drag `.amxd`). Autowatch *might* pick up the new
   loader.js, but a hard reload is safer.

3. **Verify smoke:**

   ```bash
   cd device/setforge-live
   python3 tests/curation/osc_client.py
   ```

   Expect:

   ```
     /live/test reply: ('ok',)
     Live version: (12, 4)
     num_tracks in current set: (14,)
   ```

4. **Verify warp_bpm now reads:**

   ```bash
   python3 << 'PY'
   import sys; sys.path.insert(0, 'tests/curation')
   from osc_client import AbletonOSC
   osc = AbletonOSC(default_timeout=4.0)
   try:
       r = osc.ask('/live/clip/get/warp_bpm', 2, 0)
       print(f'warp_bpm: {r}')   # Should print a float, NOT TIMEOUT
   finally:
       osc.close()
   PY
   ```

   If you get `TIMEOUT`, Live didn't restart cleanly. Restart it again.

---

## 4. The outstanding bug — this is what blocks ship

`syncPresetClips` in
[`device/setforge-live/src/loader/loader-controller.js`](../../device/setforge-live/src/loader/loader-controller.js)
isn't reflecting user loop-edit changes in `chop.length_sec`.

### Symptom

The op 1 test does this:

1. Snapshot `~/Desktop/hiphop_breaks/` → `~/Desktop/hiphop_breaks_test/`
2. Load the sandbox set into the device
3. Activate preset slot 0 (1835 Electric Relaxation)
4. Via AbletonOSC: set `sf-drums` slot 0's `loop_end = 2` (half a bar)
5. Confirm Live accepted the change (read-back returns 2.0) ✓
6. Send `save` to the device
7. Read the sandbox manifest

Expected: `chops[0].length_sec ≈ 1.22` (half-bar at ~98 BPM).
Actual: `chops[0].length_sec = 2.46` (full bar — the original value).

Also: `chops[7]` (the oneshot, `warping=0`) is coming back with
`length_sec = 0.241` and `start_sec = 29.745`, which are NOT the values
Live actually shows for that clip (`end_marker = 0.84`, `start_marker = 0`).
The oneshot is being mangled too.

### Theory of cause

Look at `syncPresetClips` (around line 2930) — specifically the warped
branch (~3066) and the unconditional fallback at the end (~3150). For
the warped branch:

```js
if (warping === 1 && loopEnd > loopStart) {
    var beatSpan = loopEnd - loopStart;       // 2
    var bars = Math.round(beatSpan / 4);       // 1
    var secPerBeat = 60.0 / mTrack.bpm;        // 0.612
    var lengthSec = bars * 4 * secPerBeat;     // 2.45 (initial fallback)

    if (markers.length >= 1) {
        var anchor = markers[0];
        for (var mi = 1; mi < markers.length; mi++) {
            if (Math.abs(markers[mi].beat_time) < Math.abs(anchor.beat_time)) {
                anchor = markers[mi];
            }
        }
        ...
        startSec = anchor.sample_time + (loopStart - anchor.beat_time) * secPerBeatFromMarkers;
        lengthSec = beatSpan * secPerBeatFromMarkers;
    }
    ...
    mc.length_sec = lengthSec;
}

// Unconditional fallback
if (!mc.length_sec || mc.length_sec <= 0) {
    mc.length_sec = (mc.length_bars || 1) * 4 * (60.0 / mTrack.bpm);   // 2.45 again
}
```

Most likely the first marker has `beat_time = undefined` (the `[b=?,s=?]`
row that shows up in inspect output is exactly this — the "anchor at
beat-negative-infinity" marker Live auto-generates). When my code uses
that marker as the anchor:

- `anchor.sample_time` may also be undefined → `startSec = NaN`
- `lengthSec = beatSpan * secPerBeatFromMarkers` is fine if
  `secPerBeatFromMarkers` defaulted to `secPerBeat` (because `dtBeat`
  via `last - first` is `NaN`)

So `lengthSec` should be `~1.22` (which is `< 2.46`), and the
unconditional fallback at the end should NOT fire (`1.22 > 0`). But
the manifest shows `2.46`, exactly matching the fallback. So either:

- the fallback IS firing (meaning `mc.length_sec` ends up `<= 0` or
  `undefined`), OR
- something else (the `lengthSec <= 0 || lengthSec > 600` sanity check
  inside the warped branch) is overwriting `lengthSec` back to the
  fallback `bars * 4 * secPerBeat = 2.45` value

For chop 7 (the oneshot), the values `length_sec = 0.241` and
`start_sec = 29.745` look like they came from the **warped branch**,
not the oneshot branch — but Live reports `warping=0` for it. Either
my sync's `warping === 1` check is misfiring, or there's variable
contamination between iterations (the per-iteration `var c = lc.slot`
shadows or interacts with the inner loop's logging variable).

### Diagnostic plan

Add a temporary post-trace block in `syncPresetClips` right after
`mc.length_sec = lengthSec` (warped branch) and similarly for the
oneshot branch, that writes the per-clip state to a file:

```js
// TEMP DIAG — remove before commit
try {
    var trace = {
        stem: stem, slot: lc.slot, identity: lc.identity,
        warping: warping, loopStart: loopStart, loopEnd: loopEnd,
        beatSpan: beatSpan, bars: bars,
        secPerBeatFromMarkers: secPerBeatFromMarkers,
        startSec_computed: startSec, lengthSec_computed: lengthSec,
        anchor_bt: anchor ? anchor.beat_time : null,
        anchor_st: anchor ? anchor.sample_time : null,
        markers_count: markers.length,
        first_marker: markers[0],
        last_marker: markers[markers.length - 1],
        mc_length_sec_after: mc.length_sec
    };
    var f = new File("/tmp/setforge_sync_trace_" + stem + "_" + lc.slot + ".json", "w");
    if (f.isopen) { f.eof = 0; f.writestring(JSON.stringify(trace, null, 2)); f.close(); }
} catch (_) {}
```

Then run op 1's test, save, and read the trace files:

```bash
ls -la /tmp/setforge_sync_trace_*.json
for f in /tmp/setforge_sync_trace_drums_*.json; do echo "=== $f ==="; cat "$f"; done
```

That'll tell you exactly what `mc.length_sec` ended up as before the save
wrote, what `secPerBeatFromMarkers` was, what `anchor` was, etc.

### Likely fixes

Once you've confirmed the diagnostic:

1. **Skip the broken anchor** — when `markers[0]` has `undefined`
   beat_time or sample_time, start iterating `anchor` from index 1
   instead. Or filter `markers` to only those with finite
   `beat_time`/`sample_time` before the anchor pick.

2. **Guard the fallback** to only fire when neither the warped nor
   oneshot branch updated `length_sec`:

   ```js
   var lengthAssigned = false;
   if (warping === 1 && loopEnd > loopStart) {
       ...
       mc.length_sec = lengthSec;
       lengthAssigned = true;
   } else if (warping === 0) {
       ...
       lengthAssigned = true;
   }
   if (!lengthAssigned && (!mc.length_sec || mc.length_sec <= 0)) {
       // fallback
   }
   ```

3. **Audit the `c` variable contamination.** I added `var c = lc.slot`
   at the top of each iteration, but the existing property-extraction
   body uses `c` for `presetChops[c]` (which used to be the position
   in the manifest's chop list — now lc.slot is the live slot, not
   necessarily the same). For ops where the user hasn't moved clips,
   they coincide; for moves they don't. Rename `c` to `slotIdx` inside
   the body and use `lc.identity` (or a fresh `mci`) for any operation
   that should target the manifest's chop list position. Be careful:
   `presetChops` is keyed by *manifest position* (where the chop sits
   in `mStem.chops`), not by slot, so use `lc.identity` when known.

---

## 5. DO NOT TOUCH

The **warp-marker correction code** in `fixWarpMarkers` /
`fixWarpMarkersOnTracks` / `fixWarpMarkersForStem`. This is the
`move_warp_marker` pass that runs after preset load. Zak spent 2 days
getting this right; we already burned him once by removing it (commit
`0f12105`) and had to revert (`d2ea207`). The `jsliveapi: The specified
warp marker doesn't exist` console noise from a subset of failed calls
is acceptable — the silently-successful calls are doing critical BPM
correction. Don't touch.

If you find yourself wanting to modify the marker math, stop. Ping Zak.

---

## 6. Architecture quick reference

### Loader-side: where the curation work lives

**New in commits `6331af1` and `b6495a5`:**

- **Identity-prefix clip naming** — both `loadClipsToSlotSet` and
  `loadStemClipsToTrack` set clip names as
  `[sf:trackId/stem/idx] <label>` where idx is the chop's position in
  the manifest at load time. Sync parses this to track moves.
- **Per-clip BPM (op 2 write)** — if a chop has a `bpm` field in the
  manifest, the loader sets `clipApi.set("warp_bpm", chop.bpm)` right
  after `set("warping", 1)`.
- **Structural sync** — `syncPresetClips` now does three passes:
  1. Scan all 8 slots in the preset's range, build `liveClips[]`
     `{slot, clipApi, identity, name}`
  2. For each live clip: identity match → existing chop (update
     column + properties); positional fallback (no identity, slot has
     a manifest chop) → match by slot, stamp identity into Live;
     otherwise → new chop entry with fresh identity stamped in
  3. After loop: drop unmatched manifest chops (deletes), append new
     chops (copies/news), sort by column

This is the structural piece. The per-clip property extraction (warp
markers → start_sec / length_sec) is the SAME code that was there
before; I just wrapped a different outer loop around it. The bug is
in either the structural wrapping or the existing extraction.

### Test harness layout

```
device/setforge-live/tests/curation/
├── osc_client.py      — AbletonOSC wrapper (UDP, request/reply pattern)
├── live_bridge.py     — high-level clip ops on top of osc_client
│                          (find_track, get_clip_state, edit_clip_markers,
│                           set_clip_bpm, move_clip, delete_clip, copy_clip)
├── loader_bridge.py   — talks to the device via IAC MIDI + /tmp/setforge_cmd.txt
│                          (load_set, activate_preset, save, sync, inspect, panic, eject)
├── snapshot.py        — copies ~/Desktop/hiphop_breaks/ → ~/Desktop/hiphop_breaks_test/,
│                          renames files + patches set.json's "name" field
├── test_op1_markers.py — first end-to-end test (currently failing)
└── .gitignore         — excludes __pycache__
```

### Build + deploy cycle

```bash
cd /Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live/device/setforge-live

# 1. Edit src/loader/*.js
# 2. Rebuild — concats loader.js, packs .amxd, deploys to Max Packages,
#    builds setforge-loader-debug.maxpat for standalone iteration
PYTHONPATH=~/raindog/harness/quickstarts/max-plugin/tools python3 build/build_setforge.py
# 3a. Standalone Max iteration (no Live needed)
open setforge-loader-debug.maxpat
# 3b. Or full Live test
npm test                                       # JS unit + integration (167)
python3 -m pytest tests/curation/ -v           # curation OSC-driven tests
```

The JS deploys to BOTH `~/Documents/Max 8/Packages/setforge-live/javascript/`
and `~/Documents/Max 9/Packages/setforge-live/javascript/` — autowatch in
Live picks it up within a second.

---

## 7. The five ops and where they stand

| Op | Description | Loader support | Test |
|---|---|---|---|
| 1 | Edit clip start/end (markers, loop region) | ✓ shipped (this is what's broken — sync derives wrong `length_sec`) | `test_op1_markers.py` (failing) |
| 2 | Change BPM (`warp_bpm`) per clip | ✓ shipped (manifest writes via `chop.bpm`; OSC needs Live restart) | not written |
| 3 | Move clip between slots | ✓ shipped (structural sync handles identity tracking) | not written |
| 4 | Delete clip | ✓ shipped (sync prunes manifest chops whose identity isn't seen) | not written |
| 5 | Copy clip + edit | ✓ shipped (duplicate-identity detection stamps fresh ID; new chop appended) | not written |

For all five, after fixing the op 1 sync bug, the test pattern is:

1. Activate a preset (preset A slot 0 = 1835 Electric Relaxation, note 41)
2. Do the op via AbletonOSC (`live.edit_clip_markers`, `live.set_clip_bpm`,
   `live.move_clip`, `live.delete_clip`, `live.copy_clip`)
3. Verify Live's state matches the op
4. `loader.save()` to push state to manifest
5. `loader.eject()` + `loader.load_set(sandbox)` + `loader.activate_preset(0)`
6. Re-read clip state from Live, assert it matches what was edited

The sandbox is `~/Desktop/hiphop_breaks_test/`, snapshotted from
`~/Desktop/hiphop_breaks/`. Tests should never write to the production set.

---

## 8. Production set track inventory

Per Zak's current production set at `~/Desktop/hiphop_breaks/`:

| Slot | Bank | ID | Track |
|---|---|---|---|
| 0 | A | 1835 | Tribe Called Quest — Electric Relaxation |
| 1 | A | 1851 | Digable Planets — Rebirth of Slick |
| 2 | A | 5941 | Notorious B.I.G. — Juicy |
| 3 | A | 1849 | Gang Starr — Mass Appeal |
| 4 | A | 7954 | Mobb Deep — Shook Ones Pt. II |
| 5 | A | 4060 | Wu-Tang Clan — C.R.E.A.M. |
| 6 | A | 8326 | RJD2 — Smoke & Mirrors |
| 7 | A | 6553 | Massive Attack — Mezzanine |
| 8 | B | 2098 | Chemical Brothers — Setting Sun (135 BPM, IDM) |
| 9 | B | 4044 | Tribe Called Quest — His Name Is Mutty Ranks |
| 10 | B | 10488 | Squarepusher — Vic Acid (165 BPM, IDM) |

Note 4044 (Mutty Ranks) loads at half-time BPM in Live (~184 instead of
manifest's 92) — this is a `taste`-side issue, not a loader bug.

---

## 9. CC + note reference for the IAC driver

| CC | Command | Notes |
|---|---|---|
| 100 | save | full save (sync + manifest + set) |
| 101 | sync | sync only, no disk write |
| 102 | inspect | writes /tmp/setforge_inspect.json |
| 103 | panic | stops all clips |
| 104 | eject | clears manifest/set state |
| 105 | reload | reload preset banks from set |
| 106 | debug | dumps state to Max Console |
| 107 | save_manifest | manifest write only |
| 108 | save_set | set.json write only |

Note numbers (MK2 programmer mode: `note = (9 - row) * 10 + col`):

- Row 1–4 stems cols 1–8: notes 81–88, 71–78, 61–68, 51–58
- Row 5 (bank A) cols 1–8: notes 41–48
- Row 6 (bank B) cols 1–8: notes 31–38
- Row 7 modifiers cols 1–8: notes 21–28 (col 3 = SOLO = note 23)
- Row 8 scenes cols 1–8: notes 11–18
- Side right (top to bottom): 89, 79, 69, 59, 49, 39, 29, 19
  - 89 = dual-song toggle
  - 79 = deck-setup (staging hold)

For path-bearing commands (`load <path>`), still write to
`/tmp/setforge_cmd.txt` — CC can't carry paths.

---

## 10. Done definition

The curation harness is done when:

- [ ] Op 1 test (`test_op1_markers.py`) passes: marker edits persist
- [ ] Op 2 test passes: `warp_bpm` change in Live → saved into
      `chop.bpm` → on reload the loader sets `warp_bpm` back to that value
- [ ] Op 3 test passes: moving a clip from slot N to slot M in Live →
      after save+reload, the clip's at slot M with the same content
- [ ] Op 4 test passes: deleting a clip in Live → after save+reload,
      that slot is empty and the manifest's chop list has one fewer entry
- [ ] Op 5 test passes: copying a clip in Live → after save+reload,
      both copies exist; editing the copy's location/markers persists separately
- [ ] Zak runs a hand-curate pass on one real song in Live's UI and
      confirms everything he changed survived save+reload
- [ ] All 167+ JS tests still green
- [ ] Final commit pushed to `origin/worktree-setforge-live`

---

## 11. References

- [setforge-live-curation-status.md](setforge-live-curation-status.md) — shorter
  status snapshot
- [setforge-live-test-harness-rebuild.md](setforge-live-test-harness-rebuild.md)
  — what landed in the test-harness rebuild (Phase A–D)
- [setforge-live-multi-song-next-session.md](setforge-live-multi-song-next-session.md)
  — prior handoff (multi-song work, completed this session)
- [launchpad-state-reference.md](../../device/setforge-live/docs/launchpad-state-reference.md)
  — verified-from-source LED reference (some gaps have since been filled)
- [stemforge memory `MEMORY.md`](/Users/zak/.claude/projects/-Users-zak-zacharysbrown-stemforge/memory/MEMORY.md)
  — battle-tested M4L patterns; especially `m4l_device_development_guide.md`
  (20 pitfalls), `feedback_test_deploy_discipline.md`,
  `feedback_build_deploy_process.md`, `feedback_js_source_of_truth.md`.

---

*end of handoff*
