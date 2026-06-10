# Setforge — Live Setup Runbook & Known Issues

**Last updated:** 2026-06-10 (live validation session against Ableton Live 12.4 beta)
**Purpose:** Stop re-deriving the same setup friction and bugs. If you're bringing up a set in Live to test, read Part 1. If something's broken, check Part 2 first.

---

## Part 1 — Getting to a testable state (the runbook)

Do these in order. Most "it doesn't work" reports are a missed step here.

1. **Launch Ableton Live 12 *beta*** (not stable — the devices are developed against the beta).
2. **Audio:** Settings → Audio → Output Device = *Use System Device* (engine off → nothing runs).
3. **AbletonOSC / MCP:** AbletonOSC is installed as **Control Surface slot 1**. The `live-shortcuts` MCP only connects **while Live is running** with that surface loaded — confirm with `osc_status`. (The MCP is not "brittle"; it's just dead when Live is closed.)
4. **Free the Launchpad from Live's native control:** when a Launchpad Pro is plugged in it auto-registers as **Control Surface slot 2** (Live Port). That steals pad presses and fights the grid's programmer-mode SysEx. **Set slot 2's Control Surface + Input + Output to None.** Keep the **Launchpad Pro (Standalone Port)** "Track" boxes checked in Input/Output Ports — that's the port the grid uses.
5. **Devices:** place `setforge-grid.amxd` on a MIDI track (MIDI From = Launchpad Pro / Standalone Port, Monitor = In) and `setforge-loader.amxd` on an audio track. Canonical built copies: `device/setforge-live/*.amxd`.
6. **After changing the control-surface setup, reload the devices in this order:** **grid first** (it re-grabs the now-free Standalone Port), **then loader** (it repaints the Launchpad — it prepends programmer-mode-enter SysEx before every grid flush). Pads should now light.
7. **Load a set** via the loader's `browse…` (or `load <path>`). Loading auto-creates `sf-drums/bass/other/vox` tracks + scenes. A 16-preset set creates 16 scenes — that's how you know the banks populated even if the panel display lags.
8. **Play:** tap a **preset pad** (rows 5–6) to load/arm a song, then tap **chop pads** (top 4 rows) to trigger audio. Preset pads do not make sound on their own.

### Loader pad layout (8×8, logical row 1 = top)
| Row (from top) | Function |
|---|---|
| 1–4 | Stem chops: drums / bass / other / vox |
| 5 | **Bank A presets A1–A8** (left→right; A1 = note 41) |
| 6 | Bank B presets B1–B8 |
| 7 | Modifiers |
| 8 | Scenes |

So **A1 = 5th row down, far-left column = MIDI note 41.**

---

## Part 2 — Known issues & fixes

| # | Symptom | Root cause | Status / fix |
|---|---------|-----------|--------------|
| 1 | **Preset loads (pads light) but no clips appear; console: `create_audio_clip Macintosh HD:/… → Invalid syntax`, `0/8 clips`** | The `browse…` dialog hands the loader an **HFS path** (`Macintosh HD:/Users/…`). The boot-volume name has a space; `LiveAPI.call("create_audio_clip", path)` tokenizes its arg on the space → invalid. (Files are fine; it's the path *format*.) Loading via a POSIX path — autowatch last-set or `load /Users/…` — does not hit this, which is why it "worked yesterday." | **FIXED 2026-06-10:** added `hfsToPosix()` normalizer at the top of `loadSet()` in `src/loader/loader-controller.js`. Rebuild + redeploy required (see Part 3). |
| 2 | Pads don't light / wrong pads light on a Launchpad **Pro** | Loader is hardcoded to `createSurface("mk2")`; the Pro MK2 layout/SysEx differs from the mini MK2. | Open: needs a Pro-MK2 surface + runtime hardware detection (redesign FA3). Workaround: tap whatever pad *does* light as a preset. |
| 3 | Launchpad shows Live's session view, taps don't reach loader | Launchpad Pro registered as Control Surface slot 2 (see runbook step 4). | Disable slot 2 + reload devices (steps 4, 6). |
| 4 | Device `load` button does nothing | The bare `load` button has no path; it does **not** restore the last set. | Use `browse…`, or wire `load` to `/tmp/setforge_last_set.txt` (the `reload` message already does). Open. |
| 5 | Bank panel shows `bank A: —` after a successful load | Front-panel bank display doesn't refresh on load (cosmetic). | Open (low priority). Confirm load via scene count / MCP instead. |

---

## Part 3 — Rebuild & redeploy (after editing `src/loader/*.js`)

The deployed device runs the **concatenated monolith** `loader.js`, resolved from the **Max Package** dir, not the `.amxd` location. Editing `src/` does nothing until you rebuild **and** redeploy.

```bash
cd ~/zacharysbrown/m4l-devices/device/setforge-live
PYTHONPATH=../../tools python3 build/build_setforge.py    # concatenates src → loader.js + deploys to ~/Documents/Max N/Packages/setforge-live/javascript/
# then in Live: reload the setforge-loader device (or re-add it)
```

> The build run inside the Cowork sandbox regenerates the repo's `loader.js` but **cannot deploy** (the Max Package dir is a host path the sandbox can't see — it prints `no Max Package targets found`). Run the build **on the host** to deploy, then reload the device.

---

## Part 4 — Automated harness: the MIDI-injection constraint (important)

Preset/chop activation is triggered **only** by a MIDI **note** into the grid device's `[midiin]` (e.g. A1 = note 41). Confirmed empirically:

- `[midiin]` receives MIDI **only from a real input port** (the track's "MIDI From" = hardware Launchpad **or IAC**). It does **not** receive a clip placed on the grid track, nor MIDI routed in from another track via "Track In" (tested both, plus arming — none reach the loader).
- The loader exposes no preset-activation device parameter; the `live-shortcuts`/AbletonOSC MCP has no MIDI-note send. A session clip / Live track-routing / OSC **cannot** trigger a preset.

**Therefore the automated harness must:**
1. Run the MIDI sender **on the host** (the Cowork sandbox is network-isolated — no route to IAC or AbletonOSC 11000). Use the existing `tests/uat/setforge_remote.py` / `tests/curation/loader_bridge.py` (mido → IAC).
2. Set the grid track's **"MIDI From" = IAC Driver** for automated runs (physical Launchpad stays on its own port for live performance).
3. Use **computer-use only to bootstrap** Live (launch, load set, confirm routing), then hand off to the host-side IAC sender and verify state via the MCP + `/tmp/setforge_inspect.json`.

Physical pad taps are for manual aural spot-checks only — never the backbone of the automated harness.

### VERIFIED 2026-06-10 — the full headless drive works
A host-side run (Claude Code) drove and verified preset activation end-to-end with **no GUI and no physical pad**:
- **Set the grid track's MIDI input via OSC** (AbletonOSC *can* do this — no manual routing needed):
  - `/live/track/set/input_routing_type  [<grid_track>, "IAC Driver (Bus 1)"]`
  - `/live/track/set/current_monitoring_state  [<grid_track>, 1]`  (monitor = In)
- **Fire a pad** with mido → IAC Driver (Bus 1): `note_on 41 vel 100` then `note_off` ≈120 ms later (A1 = note 41).
- **Both notes AND CCs** flow the same path: IAC → grid `[midiin]` → `send sf-grid-in` → loader `msg_int`. So CC 102 (inspect), CC 103 (panic), etc. also work over IAC once routing is set.
- **Verify via OSC** (`/live/clip_slot/get/has_clip` per stem slot) and/or `/tmp/setforge_inspect.json`.
- Result: A1 → drums 8/8, bass 8/8, other 8/8, vox 1/8; first clip path clean POSIX. ✅

Pad-note map (loader logical row → MIDI note, `note = (9-row)*10 + col`): drums chops = 81–88, bass = 71–78, other = 61–68, vox = 51–58, **bank A = 41–48**, bank B = 31–38, modifiers = 21–28, scenes = 11–18.
