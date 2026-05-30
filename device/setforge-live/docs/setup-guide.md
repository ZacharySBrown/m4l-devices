# setforge-live — Setup Guide

## Device pair

setforge-live uses **two M4L devices** that communicate via Max's `send`/`receive`:

| Device | Type | Track type | Purpose |
|--------|------|------------|---------|
| `setforge-loader.amxd` | Audio Effect | Audio track | Clip management, LiveAPI, state machine |
| `setforge-grid.amxd` | MIDI Effect | MIDI track | Bridges MIDI between Launchpad and loader |

## Setup (step by step)

### 1. MIDI Preferences (Live → Settings → Link, Tempo & MIDI)

- **Control Surface**: Set any Launchpad Pro entries to **None**. The M4L device handles communication directly — Live's built-in Launchpad script will conflict.
- **Input Ports → Launchpad Pro (Standalone Port)**: **Track: ON**
- **Output Ports → Launchpad Pro (Standalone Port)**: **Track: ON**
- All other Launchpad ports: leave as-is (don't matter)

### 2. MIDI track (for the grid bridge)

1. Create a **MIDI track**
2. Drop `setforge-grid.amxd` onto it
3. Set **MIDI From**: `Launchpad Pro (Standalone Port)`
4. Set **MIDI To**: `Launchpad Pro (Standalone Port)`
5. **CRITICAL: Set Monitor to "In"** — without this, MIDI will not flow through the device and the Launchpad will not respond

### 3. Audio track (for the loader)

1. Create an **Audio track** (or use an existing one)
2. Drop `setforge-loader.amxd` onto it
3. Place `loader.js` in the same directory as the `.amxd` file

### 4. Load a set

1. In the loader device, click **browse...** and select a `.set.json` file
2. The `.manifest.json` must be in the same directory as the `.set.json`, with matching name (e.g. `taste_mix.set.json` looks for `taste_mix.manifest.json`)
3. Wait for "set loaded" in the Max console

### 5. Play

1. Tap a **preset pad** (row 1 = bank A, row 7 = bank B) to activate a song
2. Tap **chop pads** (rows 2-5: drums/bass/other/vox) to play stem chops
3. Tap a different preset pad to hot-swap to another song

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Launchpad stays in default Note mode | Check MIDI track Monitor is set to **In** |
| No pad colors | Check MIDI track output is set to Launchpad Standalone Port |
| "can't find file loader.js" | Place `loader.js` next to `setforge-loader.amxd` |
| "manifest is null" on load | Ensure `.manifest.json` is in the same directory as `.set.json` |
| Pads light up but no clips appear | Must tap a preset pad first to activate a song |
| No MIDI signal on MIDI track | Check MIDI From is set to Launchpad Standalone Port, Monitor is **In** |
| Control Surface conflict | Set all Launchpad entries to None in MIDI preferences |
