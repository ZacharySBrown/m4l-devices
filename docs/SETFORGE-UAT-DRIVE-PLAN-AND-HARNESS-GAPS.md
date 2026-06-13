# Setforge — Acceptance Criteria → Driven UAT Harness + Honest Gap Analysis

**For:** a fresh Claude Code session.
**Purpose:** (1) Materialize the acceptance criteria zak set out ("pull the project together, unify the interfaces, **INCREDIBLY HARDENED WORKFLOWS**, a **well-designed UX**") into a concrete plan, and (2) document **where the full UAT harness fell apart** — i.e. every place an agent was *supposed* to drive the work autonomously but a human had to step in. zak's words: *"I had to do a LOT of manual intervention here. You're supposed to be able to drive most of this."*

This composes with two companion docs (read them too):
- `docs/UAT_PLAN.md` — the 21 end-to-end workflows + pass criteria (the acceptance bar). This plan does **not** restate them; it makes them *drivable*.
- `docs/SETFORGE-LEAN-RECONCILIATION-PLAN.md` — path unification, Spotify guard, lean single-branch, install script. Several harness gaps below are *caused* by the path/env problems that plan fixes; cross-references are noted.

---

## Part 0 — The acceptance bar, in one screen

The product is the 3-repo Setforge ecosystem (taste = curation/DB, stemforge = stems/beats, m4l-devices = Launchpad devices + companion app). "Done / hardened" means the **full UX flow runs end-to-end, reproducibly, on a fresh machine, with an agent driving as much as possible and a human only doing what genuinely needs ears, eyes, or hardware.**

The flow, and the acceptance source for each stage:

| Stage | What it must do | Acceptance source |
|---|---|---|
| Install | one script preps a new machine (M-series + Intel placeholder) | UAT-01; lean plan §C |
| Curate | `forge-set <recipe>.yaml` → DB-deduped tracks → stems → reconciled_continuity chops + vocal warp grid → `set.json`+`manifest.json` | UAT-02, UAT-05 |
| Load | set loads in setforge-loader on the Launchpad; presets + chops playable | UAT-01, UAT-07, UAT-17 |
| Perform | trigger/replace/hot-swap chops, modifiers, scenes, dual-song, panic | UAT-07→13 |
| Arrange | prechop → arranger places clips on the timeline, re-anchor, snapshot | UAT-04, UAT-18, UAT-19 |
| Companion | Perform/Curate/Arrange views mirror live state + recommendations | (Phase-2/3, mirrors above) |
| Cross-machine | build on one machine, sync, perform on another | UAT-03, UAT-06 |
| Calibrate | validate downbeats by ear, write overrides | UAT-20 |

The UAT plan encodes the **hard acceptance criteria** as checkbox pass-lists (e.g. "two stems play in phase, no flam > 15 ms"; "hot-swap migrates held chops at correct quant boundaries"; "forge-set completes all 7 stages, schema valid, all chop paths resolve"). Those checkboxes are the contract. The job is to make a harness that can *assert* as many of them as possible without a human.

---

## Part 1 — The 5-layer harness, and exactly where it falls apart

The intended design (per `setforge-redesign-decisions` memory + `setforge-live-test-harness-rebuild.md`) is a **5-layer pyramid** with three Live control planes (device UDP `7422` / CC `100–108` / `/tmp/setforge_inspect.json`). Here is the honest status of each layer — what an agent can drive vs. where a human had to intervene.

### L0 — build / static (drift guard, packers, verifiers) ✅ DRIVABLE
`make`/pre-commit/CI run the monolith==src drift guard, the 20 M4L pitfall verifiers, schema validators. This layer works headlessly and caught real issues. **No gap.**

### L1 — unit (JS mocha, Python pytest) ✅ DRIVABLE
`npm test`, `pytest`. Fast, deterministic, green. **No gap** — except it gives false confidence (see L2/L3).

### L2 — mocked integration (mock-live-api.js, contract schemas) ⚠️ PARTIAL — false greens
Mocked LiveAPI + JSON contract tests pass while the *real* runtime is broken. Two concrete misses this program already hit:
- **Companion shipped visibly broken while tests were green:** `style.css` had no component CSS (views collapsed to a text column) and `app.js` mounted with null state and never re-rendered on first poll ("Waiting…" until a tab switch). DOM-structure unit tests passed the whole time. A human (zak) caught both by eye. (Guards were added afterward — keep them.)
- **`syncPresetClips` length=0 bug:** the mock exercises clip *loading*, not Live property *reads*, so the `length_sec=0` path that kills drum clips is invisible to L2. Only a hardware run reveals it.
- **The `SendMessage … Bad parameter value` burst** in the loader only appears in the **Max console at runtime** — no mocked test sees it.
**Gap:** L2 cannot see real-LiveAPI behavior or browser render. Needs L3 + a render check.

### L3 — Live-in-the-loop ❌ THIS IS WHERE IT FELL APART
This is the layer that is *supposed* to let an agent drive Ableton headlessly via UDP/CC/inspect.json. In practice, across this program it required near-constant manual intervention:
- **The agent sandbox cannot run the real pipeline at all.** Stemming (demucs/torch/MPS) and even librosa/soundfile/scipy are absent or unrunnable in the agent's Linux sandbox; the taste DB + caches live on the Mac. **Every "build a set" (UAT-02) had to run on zak's Mac.** The agent could only do downstream JSON work. *(Root cause largely = environment + path split; lean plan §A/§C addresses reproducibility, but the sandbox will never run demucs.)*
- **Path divergence forced manual `cp`.** stemforge wrote stems to `~/stemforge/processed/<slug>/` but forge-set reads `~/.cache/setforge/stems/<track_id>/`. Bridging them was a hand `cp` every time (documented in `HANDOFF-hey_mami-forge_set.md`). *(Fixed by lean plan §A3.)*
- **The canonical pipeline wasn't discoverable, so the agent hand-rolled a wrong artifact.** Faced with "get chops onto the grid," the agent built a bespoke full-stem manifest instead of using the real `forge-set` / `reconciled_continuity` pipeline — burning cycles until zak pointed to the actual YAML pipeline. The harness never encoded "THIS is the one true pipeline." *(Fix: the `forge-set` skill + docs must be the single front door.)*
- **Ad-hoc DB registration is manual.** Getting a track a `track_id`, setting `stem_bpm`/`stem_downbeat`, and wiring the stem cache was hand-SQL. No driven "register this loose track" path.
- **Live runtime errors are invisible to the agent.** The load-bearing bugs (`Bad parameter value`, short-clip length) surface only in the **Max console**, which the agent cannot read. zak had to watch the console and report.
- **Computer-use into Live is brittle.** Live opened on a non-primary Space and `open_application` didn't surface it; the Chrome MCP wasn't granted; the agent could not reliably open/observe the app. Browser/Live GUI verification fell back to zak.
- **The cc executor bridge went OFFLINE.** The agent-bridge stopped polling mid-program; device work was done directly in-sandbox instead of through the intended executor. The orchestration layer itself was unreliable.
**Gap:** L3 only works when (a) Live is already running with the device loaded, (b) a human is watching the Max console, and (c) the bridge is up. None of that is currently guaranteed or agent-controlled.

### L4 — manual aural / hardware ⚠️ INHERENTLY HUMAN, but unstructured
Phase, flam, "does the drum-on-drum chord sound tight," faceplate aesthetics, Launchpad pad/LED/aftertouch behavior — these need ears, eyes, and the physical Pro MK2. That's legitimately human. **Gap is not that humans do these — it's that the harness gives no structured queue/record for them.** (`~/zacharysbrown/maad_traash_muzak/mtm/Setforge-Hardware-Session-Checklist.md` is the closest thing; it should be the canonical L4 checklist, generated from the UAT pass-lists.)

### Cross-cutting failures (not a single layer)
- **Version control is not agent-drivable from the sandbox.** `git` writes hit `.git/index.lock` "Operation not permitted/File exists", and GitHub SSH is firewalled (`CONNECT github.com-...:22 Forbidden`). So **commit + push must be handed to cc-on-Mac** (see `SETFORGE-BACKUP-cc-instructions.md`). Any harness step that "saves work" silently can't.
- **Reproducibility / portability.** Hardcoded `/Users/zak/...` paths, no `SETFORGE_HOME`, version drift (Python 3.11 vs 3.13, numba pins) — a fresh machine can't reliably reproduce a run. *(Lean plan §A/§C.)*

---

## Part 2 — The plan: make the harness actually drive it

Each workstream lists what becomes **agent-drivable** vs **human-gated**, tied to the gaps above and the UAT pass-criteria.

### P1 — One true pipeline, one front door (closes: hand-rolled-artifact, discoverability)
- Make the `forge-set` skill (`taste/.claude/skills/forge-set/`) the **only** sanctioned way to build a set. It already: checks the DB first (no dup rows), writes a recipe YAML, runs `register,stem,structure,materialize,export` with `--force`, mandates `grid_mode: reconciled_continuity`, validates. Harden it per the lean plan §B2 and add a one-paragraph "DO NOT hand-roll manifests; this is the pipeline" banner.
- Add a driven **"register a loose track"** helper (artist/title/file → track_id + `stem_bpm`/`stem_downbeat` + cache wiring) so ad-hoc tracks (the hey_mami case) need zero hand-SQL.
- **Agent-drivable:** YAML authoring, DB resolve/register, running the pipeline, schema validation. **Human-gated:** none, on a machine with the env.

### P2 — Path/env unification so runs are reproducible (closes: manual cp, portability)
- Implement lean plan §A (`SETFORGE_HOME` resolver, stem-cache bridge so stemforge output is auto-found by track_id, relative paths in `stems.json`). This deletes the manual `cp` step and makes UAT-02/03/06 actually reproducible.
- **Agent-drivable:** the whole stem→chop→export chain on a configured machine. **Human-gated:** the initial demucs stemming if no GPU — slow but unattended.

### P3 — A real Live-in-the-loop runner (closes: invisible runtime errors, brittle computer-use)
The single highest-leverage harness fix. Build `tests/uat/run_live_uat.py` that an agent can invoke and that drives + *asserts* without a human:
- **Pipe the Max console to a file the agent can read.** Add a `[print]`-to-file (or `error` route → `/tmp/setforge_console.log`) so `Bad parameter value`/short-clip logs become machine-readable. Today these are the bugs that needed zak's eyes — make them assertable.
- Use the existing control planes deterministically: CC `100–108` (`setforge_remote.send_command`), UDP `7422`, and parse `/tmp/setforge_inspect.json`. Drive the UAT-21 sequence (load→inspect→activate→chop→inspect→panic→save→reload) and assert state transitions + zero console errors.
- Provide a **standalone-Max path** (`setforge-loader-debug.maxpat`, already built) for the ~10s iteration loop that needs no Live — covers dispatch logic, though LiveAPI calls no-op there.
- **Agent-drivable once Live is running with the device loaded:** load/inspect/panic/save/reload state assertions, console-error detection. **Human-gated:** launching Live + dropping the devices on tracks + arming the Launchpad MIDI track (one-time per session; or script via computer-use if a Space/grant fix lands).

### P4 — Companion render verification (closes: green-tests-broken-browser)
- Keep the post-mortem guards (CSS class-coverage + jsdom init/first-poll render). **Add a screenshot assertion:** headless-Chrome (or Claude-in-Chrome MCP) loads `localhost:<port>`, asserts the three views render non-empty and match a reference within tolerance. This is what would have caught the collapsed-CSS / blank-until-tab-switch bugs automatically.
- **Agent-drivable:** serve + screenshot + diff. **Human-gated:** first-time reference capture + aesthetic sign-off.

### P5 — Reliable orchestration + version control (closes: bridge offline, git blocked)
- Make the cc-executor bridge **self-healing / observable** (heartbeat + restart), or drop it in favor of direct cc sessions with explicit handoff docs (the pattern that actually worked this program).
- Codify that **commit/push runs on the Mac**, never the sandbox: ship a `tools/backup.sh` (generalizing `SETFORGE-BACKUP-cc-instructions.md`) that an agent on the Mac runs — explicit `git add <path>`, status checkpoints, no force-push.
- **Agent-drivable on the Mac:** the backup/commit/push script. **Sandbox:** cannot do VC — by design, route to Mac.

### P6 — Structured human-gated checklist for L4 (closes: unstructured aural/hardware)
- Generate the L4 checklist **from the UAT pass-lists** (the inherently-aural/hardware boxes: phase < 15 ms flam, drum-on-drum tightness, pad/LED/aftertouch behavior, faceplate aesthetics). Make `mtm/Setforge-Hardware-Session-Checklist.md` the canonical, regenerated artifact, cross-linked from each UAT workflow.
- **Human-gated by definition** — but now tracked, ordered, and tied to specific acceptance boxes instead of living in the agent's head.

---

## Part 3 — Driveability ledger (what "drive most of this" actually means)

| UAT | Agent can drive | Needs human |
|---|---|---|
| 01 Install→first perform | install script, file checks (P2/lean §C) | Launchpad in programmer mode; first audio by ear |
| 02 Build set from files | **fully**, on a configured machine (P1/P2) | demucs time (unattended) |
| 03 / 06 Cross-machine | sync script + path resolution asserts (P2/P5) | 2nd-machine audio sign-off |
| 04 / 18 / 19 Arrangement | prechop + arranger UDP load + snapshot asserts (P3) | "bar 4 sounds right" by ear |
| 05 Recommendation | rec_server API asserts | taste judgment |
| 07–13 Performance/scenes/dual-song/panic | state-transition asserts via CC/inspect + console-error gate (P3) | phase/flam/feel by ear; pad/LED on hardware |
| 14–17 Edge cases | **fully** (empty/missing-stem/wrong-tempo/large set) via fixtures (P3) | — |
| 20 Calibration | load/override-JSON write asserts | downbeat-by-ear (inherent) |
| 21 Automated regression | **fully** — this IS the driven runner (P3) | Live must be running |

The honest summary: **L0–L2 and the edge-case + state-machine slices of L3 are fully drivable; the gaps were (a) environment (sandbox can't stem / can't git-push / can't read the Max console), (b) discoverability (no single pipeline front door), and (c) orchestration (bridge offline).** P1–P5 convert most of L3 from "human watches and intervenes" to "agent asserts," leaving L4 (ears/eyes/hardware) as the legitimate human residue — now structured.

## Suggested order
P2 (paths) and P1 (pipeline front door) first — they unblock reproducible runs. Then P3 (Live runner + console capture) — the biggest autonomy win. P4 (render check) and P5 (orchestration + backup) in parallel. P6 (L4 checklist) last, generated from the finalized pass-lists. Gate each on the relevant `docs/UAT_PLAN.md` checkboxes going green.

## Pointers
- Acceptance criteria (the contract): `docs/UAT_PLAN.md` (+ `docs/FEATURE_INVENTORY.md`).
- Harness as-built: `docs/exec-plans/active/setforge-live-test-harness-rebuild.md`; control planes UDP 7422 / CC 100–108 / `/tmp/setforge_inspect.json`.
- Paths/lean/install: `docs/SETFORGE-LEAN-RECONCILIATION-PLAN.md`.
- Backup/VC reality: `SETFORGE-BACKUP-cc-instructions.md` (sandbox can't push).
- Known issues + runbook: `docs/SETUP_RUNBOOK_AND_KNOWN_ISSUES.md`.
- L4 hardware checklist: `~/zacharysbrown/maad_traash_muzak/mtm/Setforge-Hardware-Session-Checklist.md`.
