# Next session — agent init message

**Paste this prompt to start the next session, or use it as a briefing if the agent is given access to this file directly.**

---

You're picking up the **tape-loss** M4L device build. The previous session got the build from ~120 console errors down to 7 across the integrated `tape-loss-debug.maxpat`, with all 9 module subpatchers loading cleanly when verified standalone. The full trajectory is in [tape-loss-phase1-checkpoint.md](tape-loss-phase1-checkpoint.md) — read its Phase 3 section first (appended 2026-04-28).

**Your goal for this session: get a functional `tape-loss.amxd` loaded in Ableton Live with audio passing through.** This is the user's stated finish-line for the session; everything else is secondary.

## Read on entry (in order)

1. [tape-loss-phase1-checkpoint.md](tape-loss-phase1-checkpoint.md) — Phase 3 section especially
2. `~/.claude/projects/-Users-zak-zacharysbrown-m4l-devices/memory/MEMORY.md` — auto-memory index
3. [.claude/CLAUDE.md](../../../.claude/CLAUDE.md) — project conventions

## First commands (verify the loop still works)

```bash
cd /Users/zak/zacharysbrown/m4l-devices
git log --oneline | head -5

# Should show ~7 errors on integrated debug, all 9 modules clean standalone
pgrep -f 'App-Resources/Max/Max' || python3 tools/verify_max_load.py device/tape-loss/tape-loss-debug.maxpat
```

## Recommended path

**Try the .amxd in Ableton Live BEFORE diagnosing further.** The 7 verifier errors split: 4 are from a debug-harness wrapper artifact that doesn't apply to the actual .amxd loaded by Live, 3 are in the main patcher and may be cosmetic warnings Live tolerates. Live is the actual target — see what it reports.

```bash
# Confirm the .amxd is built fresh
PYTHONPATH=$HOME/raindog/harness/quickstarts/max-plugin/tools python3 build/build_tape_loss.py
ls -la device/tape-loss/tape-loss.amxd
```

Ask the user to drop `device/tape-loss/tape-loss.amxd` onto an Ableton audio track and play any audio clip. Then ask for:
- Any errors in Live's status bar
- Any errors in Max's console (if they Edit the device)
- Whether audio is passing through (yes/no/silent/distorted)

Branch on the result:

| Result | Next step |
|---|---|
| Audio passes, knobs respond | Move to Phase 5 calibration. Read `project_tape_loss_character_preferences.md`. |
| Audio passes, knobs do nothing | Fix the unused-parent-control-wires issue. See checkpoint Phase 3 §"What's blocking" → Step 2. |
| No audio (silent passthrough) | Most likely a gen~ codebox compiles but isn't routing in1/in2 → out1/out2 correctly under Live's audio context. Bisect by replacing one module's DSL with a trivial passthrough; see if that module passes audio. |
| Errors / crash | Capture the exact errors. If they're patchcord-OOR style, save a reference gen~ patch by hand (see checkpoint § Step 1a) and diff against bridge output. |

## Tools you have

- **`tools/verify_max_load.py`** — the headless load-verifier. Cycle ~10s. Refuses to run if Max is running (intentional — won't kill user's IDE).
- **`build/build_tape_loss.py`** — the build script. Deterministic; same inputs → same .amxd sha.
- The harness at `~/raindog/harness/quickstarts/max-plugin/tools/forge_device/load_verifier.py` is the promoted version. The local copy in this repo is the source-of-truth for now.
- Ableton bundled Max binary: `/Applications/Ableton Live 12 Suite.app/Contents/App-Resources/Max/Max.app/Contents/MacOS/Max`

## Things NOT to do

- **Don't blanket-pkill Max processes.** The verifier already protects against this; if you write something else that launches Max, mirror that protection.
- **Don't commit anything in `~/raindog/harness/`** without explicit user permission — it has lots of unrelated untracked work.
- **Don't tackle calibration before load is clean.** The "failure too crackly" / "flutter weak at noon" feedback is real but premature until audio is verified passing through.
- **Don't refactor the build script broadly.** Each module's structure was hard-won. Surgical fixes only.

## If you get stuck on the 3 main-patcher errors

The path is: ask the user to save a 4-in/2-out gen~ codebox patch by hand at `device/_reference/gen-ref.maxpat`. It's 60 seconds of clicking. Diff its inner patcher's structure against `stemforge_bridge.gen_codebox(numinlets=4, numoutlets=2, ...)`. The remaining bug is in the diff.

## Final note from the previous session

The verifier loop is the actual durable artifact this work produced. Even if tape-loss never ships, future M4L devices built via this harness will benefit from pitfall #24's `LOAD_VERIFIERS` registry. Don't lose sight of that — when iterating on tape-loss, prefer fixes at the bridge / harness level over device-specific patches when they generalize.

---

*Authored 2026-04-28 at the close of session 2. Delete this file after the next session uses it (or supersede it with a new init message).*
