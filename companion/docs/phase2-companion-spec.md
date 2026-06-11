# Phase 2 — Companion App: Implementation Spec

**Status:** spec (2026-06-11) · supersedes the build-plan stub for Phase 2 · canonical product intent in `~/zacharysbrown/maad_traash_muzak/mtm/Setforge-Product-Definition.md`

## 0. North star
During performance the companion app **fully replaces the need to watch Ableton** — eyes on the app, hands on the Launchpad. Two views: **Perform** (live, glanceable) and **Curate** (interactive set-building). Everything begins from curation; both feed the same set/scene data.

This phase turns the approved hi-fi **mockups** (`docs/mockups/perform-view-v2.html`, `curate-view-v2.html`) into a **live, interactive app** backed by the companion server.

## 1. Architecture & stack (decided)

**Stack = vanilla ES-module SPA served by the existing Python `companion/serve.py`.** No build toolchain, no framework. Rationale: the mockups are already vanilla HTML/CSS/JS, `serve.py` is a stdlib `http.server`, and this keeps the whole companion a single zero-install `python3 serve.py` to run. (Alternatives — React/Electron — rejected: they add a toolchain for no benefit at this scale. Door left open: render logic is framework-free pure functions, portable later.)

```
companion/
  serve.py                 # GET /state (live) + NEW: GET /peaks, POST /action, static file serving
  app/                     # NEW — the SPA (served at GET /)
    index.html             #   shell: <header tabs> + <main #view> ; imports app.js as module
    app.js                 #   router + data layer (poll /state, local progress interpolation, store)
    render/                #   PURE render functions: state -> DOM (no side effects -> unit-testable in node)
      surface-mirror.js    #   Launchpad grid + side buttons, colored from state
      now-playing.js       #   waveform + progress + bars-left per live stem
      legend.js            #   preset -> song map, per-source color
      recommendations.js   #   Mix-Next cards
      scenes.js            #   vetted-pairings board
      curate.js            #   clip-grid selection + A<->B swap controls
    style.css              #   v1 palette (amber A / cyan B on slate) + glow, lifted from the mockups
    actions.js             #   POST /action helpers (tag_scene, swap_ab, queue_set, trigger_clip)
  peaks/                   # NEW — waveform peaks cache (clip_id -> downsampled peaks json)
  docs/                    # this spec + the exec plan
  tests/                   # NEW — pytest (endpoints) + node DOM tests (render fns)
```

**Key design rule — pure render functions.** Each `render/*.js` exports `render(state) -> HTMLElement | htmlString`. No fetching, no globals. The data layer (`app.js`) owns polling + state; it calls render fns and mounts results. This makes every visual unit-testable in node (jsdom) without a browser, and keeps the harness UAT simple.

**Progress without high-frequency polling.** Poll `/state` every ~1 s. Between polls, animate clip progress locally by interpolating from `bpm` + `bars_left` (requestAnimationFrame), snapping to the server value each poll. Smooth bars, light network.

## 2. Data contract v2 (read + write)

### 2.1 Read — `GET /state` (extend existing)
Keep the v1 shape (`set, decks, presets, now_playing, recommendations, scenes`). **Add:**
- `decks.{A,B}.stems.{stem}.clip_id` — stable id linking a live clip to its waveform peaks.
- `decks.{A,B}.stems.{stem}.peaks_ref` — `"/peaks?clip=<clip_id>"` (or null until cached).
- `scenes[].id` — stable scene id (for tag/untag/recall round-trips); keep `name,color,clips`.
- `set.playhead_sec`, `set.loop` — for progress interpolation correctness.
- `transport.is_playing` already implied by `set`; make explicit `set.is_playing`.

### 2.2 Waveform peaks — `GET /peaks?clip=<clip_id>` (new)
Returns `{clip_id, sr, samples_per_peak, peaks:[[min,max],…]}` — a downsampled min/max envelope (≈600–1000 points/clip) generated from the stem WAV. Cached under `companion/peaks/<clip_id>.json`; generated lazily on first request or precomputed at set-load. Pure Python (wave/`numpy` if present, else stdlib `wave` + manual decimation).

### 2.3 Write — `POST /action` (new)
One endpoint, `{type, …args}`, returns `{ok, …}`. Types:
| type | args | effect |
|------|------|--------|
| `tag_scene` | `name`, `clips[]` | persist current clip combo as a vetted scene (→ loader `scene-memory` / a scenes store) |
| `untag_scene` | `id` | remove a scene |
| `recall_scene` | `id` | fire the scene's clips (→ loader UDP/CC or AbletonOSC) |
| `swap_ab` | — | swap deck A ↔ B sourcing (→ loader command) |
| `queue_set` | `set_name` | tee up another set to transition after a break |
| `select_clip` | `deck`,`stem`,`chop` | set the audition/selected clip (Curate) |

**Transport/command path:** `/action` proxies to the loader (UDP 7422 / CC remote) and/or AbletonOSC (127.0.0.1:11000), exactly the planes already used by `serve.py` reads. **No external side effects** — all localhost dev control. Tag/untag/queue persist to a small JSON store (`companion/state/scenes.json`, `queue.json`) and/or the loader's `scene-memory`.

> Safety note for cc: these are local-only control/persistence calls. Do not add auth, external calls, or destructive ops. `untag_scene` removes a row from a local JSON file (reversible-enough); no hard deletes of audio.

## 3. Perform view (live, glanceable)
Layout (locked in the mockup): **surface mirror = centerpiece** (large, glowing); **now-playing = compact, left**; **preset→song legend = right** (the single biggest at-a-glance value); **Mix-Next recs + Queue = bottom**.

Components & data:
- **Surface mirror** (`surface-mirror.js`) — render the 8×8 grid + side buttons; color each stem row + its source preset button by `presets[].color` / `decks.*.stems.*.source`; highlight the live chop (`live_chop`); show the punch/scene side buttons. Mirrors the physical Launchpad 1:1.
- **Now-playing** (`now-playing.js`) — for each `now_playing[]` stem: song/artist/key, a **waveform** (`peaks_ref`) with a **progress** playhead + **bars-left** countdown; tinted by source color.
- **Legend** (`legend.js`) — `presets.bankA/bankB[8]`: preset id → song/artist/key, the source color chip, and which stems it's currently sourcing (`sourcing[]`). This is "what's loaded where."
- **Recommendations** (`recommendations.js`) — Mix-Next cards from `recommendations[]` (congruent vs spicy), each with a `queue_set`/cue action.
- **Queue** — teed-up sets (from the queue store).

## 4. Curate view (interactive)
Set-building per the mockup: select clips, swap songs, tag scenes.
- **Clip grid** (`curate.js`) — per deck/stem, the chops as a selectable grid; click to **select/audition** (`select_clip`); show compatibility hints.
- **A↔B swap** — one control → `swap_ab` (swap which song sits on deck A vs B).
- **Scene board** (`scenes.js`) — list vetted pairings (`scenes[]`); **tag** the current combo (`tag_scene`), **untag** (`untag_scene`), **recall** (`recall_scene`). Scenes **track their clips across A↔B swaps** (persisted by clip identity, not slot). Feeds the Arrangement view later.
- **Audition** — selecting clips previews the combo (fire via `/action`), non-destructive.

## 5. Real-data wiring
- `/state` live hooks already exist in `serve.py` (`_read_inspect`, `_osc_*`, taste `_get_recommendations`). Extend for the v2 fields (clip_id/peaks_ref/scene ids/playhead).
- **Recommendations** already wired to `~/zacharysbrown/taste` `taste_recommend`. Surface in Perform.
- **Fallback:** when Live is down, `/state` serves `sample_state.json` (already the behavior) so the app renders for dev/tests.

## 6. Testing strategy
- **Python (pytest):** `/peaks` (shape + decimation on a fixture WAV), `/action` (each type, with the loader/OSC calls **mocked** — assert the right command is emitted, no real Live needed), `/state` v2 fields against `state.schema.json`.
- **Render fns (node + jsdom):** each `render/*.js` fed `sample_state.json` → assert DOM (right rows, colors, progress %, legend mapping, scene cards). Pure fns = fast, no browser.
- **Contract:** extend `schemas/` validation for state v2; keep `state.schema.json` authoritative.
- All wired into `scripts/setforge-test.sh` as a **companion** stage (alongside L0 drift + L1 schema + JS e2e).

## 7. Harness UAT (the L4-ish layer, headless)
A scripted end-to-end that needs **no GUI**:
1. Boot `serve.py` on a test port with `sample_state.json` (Live-down path) — deterministic.
2. **Perform:** GET `/state` + `/peaks`, render each view fn, assert the surface mirror colors, now-playing progress, and legend match the state.
3. **Curate:** POST each `/action` type against a **mock loader/OSC sink**; assert the emitted command + the persisted scenes/queue JSON.
4. **"Replace the Ableton window" checklist** — assert every perform-critical datum (what's playing, source per stem, bars-left, mix-next) is present in the rendered Perform DOM.
Runs in CI/`setforge-test`. A separate **live** smoke (Live up, real loader) stays a manual/zak step.

## 8. Acceptance (phase)
- `python3 companion/serve.py` serves a working Perform + Curate app at `/`, live data when Live is up, sample data when not.
- Waveforms + interpolated progress render; legend shows preset→song + source color; Mix-Next from taste.
- Curate actions round-trip through `/action` (tag/untag/recall scene, swap, queue, select) — verified against mocks.
- Scenes persist + track clips across A↔B swaps.
- Full headless UAT + `setforge-test` green. zak does the live aural/visual pass.

## 9. Deferred / out of scope (this phase)
- Arrangement view productionization (Phase 3) — Curate's scenes feed it later.
- Refined-preset editing (Phase 3).
- Native Ableton persistence (revisit later).
- Real-time audio waveform *scrubbing* (we show progress, not interactive scrub).
