# setforge-live test-harness rebuild — Phase A–D

**Date:** 2026-05-29
**Worktree:** `.claude/worktrees/setforge-live` on `worktree-setforge-live`
**Predecessor:** [setforge-live-multi-song-next-session.md](setforge-live-multi-song-next-session.md)

Re-uses the patterns proven in `stemforge` to eliminate the deploy/test
friction that blocked the last session. Each phase is self-contained and
already shipped on this branch.

---

## Phase A — Max Package distribution for JS

**Was:** `.amxd` referenced `loader.js` by filename but didn't embed it. Every
build cycle needed a manual `cp loader.js ~/Documents/Max 8/Library/`. Often
out of sync, easy to forget.

**Now:** `build_setforge.py` writes `loader.js` and `calibrate.js` into both
`~/Documents/Max 8/Packages/setforge-live/javascript/` and the Max 9
equivalent on every build. Max resolves them via its standard package search
path (pitfall #16). `project.contents.code.local = 1` was dropped from the
loader patcher — that was forcing Max to look only inside the (empty) .amxd
project dir.

Stale manual-copy `~/Documents/Max 8/Library/loader.js` renamed aside to
`loader.js.PHASE_A_BAK_2026-05-29` so the new package path actually wins on
the next Live reload. Safe to delete once verified.

`package-info.json` (one per Max version) sets `forcerestart: 1` per the
stemforge guide.

---

## Phase B — Standalone debug harness

`setforge-loader-debug.maxpat` is written on every build. Opens in standalone
Max — no Live required. Contains:

- `[js loader.js @scripting_name loader]` (same file the device uses)
- `[print]` taps on all 4 outlets (`SF-GRID1-OUT`, `SF-GRID2-OUT`,
  `SF-LIVEAPI`, `SF-STATUS`)
- `[loadbang] → init` to mirror device boot
- Message palette: `load <fixture>`, `reload`, `eject`, `sync`, `save`,
  `inspect`, `panic`, `debug`, `save_manifest`, `save_set`
- MIDI note-on injectors with `[iter]` for grid 1 (sample pads: drums col 1,
  bass col 2, preset A, SOLO double-tap targets)
- CC injectors for the new remote-command CCs (see Phase C)

`autowatch = 1` is already on in `loader-controller.js`, so editing source +
rebuilding triggers an instant reload inside the debug patch. Iterate in
~10s instead of ~10min via Live (pitfall #9).

To use: `open setforge-loader-debug.maxpat`, open Max Console (Window menu),
click messages, watch prints. LiveAPI calls error in standalone Max — that's
expected; dispatch logic still verifies.

---

## Phase C — MIDI CC for remote commands

**Was:** `/tmp/setforge_cmd.txt` file-poll, every 500ms via a `Task`, plus
opportunistic polls from `handleNoteOn` and `bar_tick`. Timing unpredictable;
the `[udpreceive]` attempt failed because Max defaults to OSC mode.

**Now:** the loader recognises CC messages on its grid-MIDI input and
dispatches via the same `handleMessage()` switch the file-poll used. Map
(in [loader-controller.js](../../device/setforge-live/src/loader/loader-controller.js)
and [tests/uat/setforge_remote.py](../../device/setforge-live/tests/uat/setforge_remote.py)):

| CC  | Command         |
| --- | --------------- |
| 100 | save            |
| 101 | sync            |
| 102 | inspect         |
| 103 | panic           |
| 104 | eject           |
| 105 | reload          |
| 106 | debug           |
| 107 | save_manifest   |
| 108 | save_set        |

UAT helper:

```python
from setforge_remote import send_command, find_iac_port
port = mido.open_output(find_iac_port())
send_command(port, "inspect")            # fires CC102 127, then CC102 0
```

The legacy file-poll Task (`startCmdPoll`) is left in place so manual
`echo "sync" > /tmp/setforge_cmd.txt` debugging still works, but the
opportunistic `pollCommandFile()` calls in `handleNoteOn` and `bar_tick` are
gone. CCs are the primary path for any scripted control.

---

## Phase D — syncFromLive short-clip fix + diagnostics

Two changes to `syncPresetClips()`:

1. **Diagnostic dump.** Every clip now logs its raw Live properties
   (`warping`, `loop_start/end`, `start/end_marker`, warp-marker count) at
   sync time. The next hardware run reveals which branch each short-drum
   clip actually hits — root cause for `length_sec=0` is observable instead
   of guessed.

2. **Unconditional length fallback.** After both branches (warped /
   unwarped) run, if `mc.length_sec <= 0` we derive a sensible length from
   `track.bpm * length_bars` (default 1 bar). A wrong-but-reasonable length
   keeps clips firing; zero kills them.

Unit tests don't exercise the LiveAPI path (mock-live-api.js is for clip
loading, not property reads). Hardware verification still owed.

---

## Hardware verification still needed

These are the items the last handoff carried forward, still unblocked:

- [ ] **Phase A verify:** Live picks up `loader.js` from the Max Package —
      run a build, reload the .amxd in Live, look for the new sentinel
      `[sync raw]` log in the Max console.
- [ ] **Phase C verify:** UAT runner uses `setforge_remote.send_command()`
      instead of any file-poll path; `inspect` and `save` fire deterministically
      from CC.
- [ ] **Phase D verify:** Trigger `sync` on the production set, watch the
      `[sync raw]` lines for short-clip drum rows. Expectation: every drum row
      now has `length_sec > 0`.
- [ ] Gap-closure §6 validation passes 1–5 (from the multi-song spec).
- [ ] The load-bearing test: drum-on-drum chord at 1/16, tight phase.

---

## File map (additions / changes)

- `device/setforge-live/build/build_setforge.py`
  - Adds `MAX_PACKAGE_TARGETS`, `deploy_js_to_packages()`,
    `build_debug_harness()`. Drops `project.contents.code.local`.
- `device/setforge-live/src/loader/loader-controller.js`
  - Adds `REMOTE_CC_MAP` + `handleControlChange()`; extends `processMidiByte`
    with a 0xB0 branch.
  - Removes opportunistic `pollCommandFile()` calls from `handleNoteOn` and
    `bar_tick`.
  - Adds `[sync raw]` log + unconditional length fallback in `syncPresetClips`.
- `device/setforge-live/tests/uat/setforge_remote.py` (new)
  - `send_command(port, name)` + `REMOTE_CC` map + `find_iac_port()`.
- `device/setforge-live/setforge-loader-debug.maxpat` (new, built artifact)
- `~/Documents/Max 8/Packages/setforge-live/` (new, build target)
- `~/Documents/Max 9/Packages/setforge-live/` (new, build target)

---

## Build + deploy cycle (updated)

```bash
cd /Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live/device/setforge-live

# 1. Edit src/loader/*.js or build/build_setforge.py
# 2. Rebuild — concats loader.js, packs .amxd, deploys to Max Packages
PYTHONPATH=~/raindog/harness/quickstarts/max-plugin/tools python3 build/build_setforge.py
# 3a. Standalone Max iteration (no Live needed)
open setforge-loader-debug.maxpat
# 3b. Or full Live UAT (reload .amxd in Live first)
npm test
python3 tests/uat/test_multi_song_modes.py
```

No more `cp loader.js ~/Documents/Max\ 8/Library/loader.js` step.
