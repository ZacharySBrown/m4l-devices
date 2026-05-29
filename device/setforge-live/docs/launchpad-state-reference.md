# Launchpad LED reference — what the device ACTUALLY drives

Verified by reading `src/loader/loader-controller.js` 2026-05-29.
The spec promises some LED behavior that isn't implemented yet; this
doc reflects the *implementation*, not the spec.

---

## Color palette (RGB 0–127)

| Name          | RGB           | Looks like           |
| ------------- | ------------- | -------------------- |
| drums soft    | 64, 20, 0     | dim orange           |
| drums bright  | 127, 40, 0    | saturated orange     |
| bass soft     | 0, 20, 64     | dim blue             |
| bass bright   | 0, 40, 127    | saturated blue       |
| other soft    | 50, 50, 0     | dim olive            |
| other bright  | 100, 100, 0   | saturated yellow     |
| vox soft      | 0, 50, 20     | dim teal             |
| vox bright    | 0, 127, 40    | saturated green      |
| empty         | 8, 8, 8       | very dim white       |
| off           | 0, 0, 0       | dark                 |
| error         | 127, 0, 0     | red                  |
| disabled      | 40, 0, 0      | dark red             |
| mod idle      | 16, 16, 16    | slightly-brighter dim white |
| mod held      | 127, 127, 127 | full white           |
| mod latched   | 127, 127, 0   | yellow               |
| scene empty   | 0, 0, 0       | dark                 |
| scene built   | 32, 0, 48     | dark magenta         |
| scene playing | 96, 0, 127    | bright magenta       |

---

## State table

### Idle (no active preset, fresh load)

| Region              | What it shows                                  |
| ------------------- | ---------------------------------------------- |
| Row 1 (drums)       | dark (`off`) — stem rows are dark with no active preset |
| Row 2 (bass)        | dark                                           |
| Row 3 (other)       | dark                                           |
| Row 4 (vox)         | dark                                           |
| Row 5 (bank A)      | each slot in its preset color (or `empty` dim white if slot null) |
| Row 6 (bank B)      | each slot in its preset color (or `empty` dim white if slot null) |
| Row 7 (modifiers)   | dim white (`mod idle`) — slightly brighter than `empty` |
| Row 8 (scenes)      | dark unless a scene is saved (`scene built` = dark magenta) |
| All side buttons    | **dark** — device never drives them at idle  |
| Top row buttons     | **dark**                                       |

### After preset activation (e.g. preset A slot 0)

| Region              | What it shows                                  |
| ------------------- | ---------------------------------------------- |
| Row 1 (drums)       | dim orange across, **bright orange on col 1** for MAIN slot if a chop is playing |
| Row 2 (bass)        | dim blue across; bright blue on the playing col |
| Row 3 (other)       | dim olive across                               |
| Row 4 (vox)         | dim teal across                                |
| Row 5 col 1         | brightest (`loaded_active`)                    |
| Rest of row 5       | other slots in `loaded_idle` color             |
| Row 6               | bank B slots in their colors                   |
| Row 7               | dim white                                      |
| Row 8               | dark (no scenes built)                         |
| Side/top buttons    | still **dark**                                 |

### After staging deck X (row 5 slot) and deck Y (row 6 slot)

| Region              | What it shows                                  |
| ------------------- | ---------------------------------------------- |
| Row 5 staged slot   | **flashing — preset color ↔ white** (MK2 native flash) |
| Row 6 staged slot   | **flashing — preset color ↔ soft blue** (MK2 native flash) |
| Top-right side btn  | **still dark** — implementation gap; spec says it should alternate X/Y, code doesn't drive it |
| Deck-setup side btn (right pos 2) | **still dark while held** — spec says bright white, code only sets `staging.stagingHeld = true` and re-renders the grid; the side button LED itself is never touched |

### After SOLO double-tap → per-row mode

| Region              | What it shows                                  |
| ------------------- | ---------------------------------------------- |
| Row 7 col 3 (SOLO)  | **yellow** (`mod latched`)                     |
| Row 1 col 1         | source-preset color tint (per-row source indicator) |
| Other stem rows col 1 | same — source indicator per stem             |
| Side buttons        | unchanged                                      |

### Inside dual-song view

| Region              | What it shows                                  |
| ------------------- | ---------------------------------------------- |
| Rows 1–4            | deck X stems, colored by stem (drums/bass/other/vox) |
| Rows 5–8            | deck Y stems, same colors as rows 1–4         |
| Side/top buttons    | unchanged from before entry                    |

---

## Known implementation gaps (spec says X, code does Y)

| Spec promises                                       | Code does                              |
| --------------------------------------------------- | -------------------------------------- |
| Deck-setup side btn bright white while held         | Nothing — side btn stays dark          |
| Dual-song toggle alternates X/Y when both staged    | Nothing — top-right stays dark         |
| Dim-white side buttons at idle                      | Nothing — all dark                     |
| Red blink on dual-song entry failure (no decks)     | Implemented (`flashSideButtonRed`)     |

These are real gaps worth filling, but they don't affect the audio-fire path. The grid pad LEDs (rows 1–8) are fully driven and accurate.

---

## Diagnosis tip

If you press a side button (e.g. note 79 for deck-setup) and:
- **Nothing visible happens** — that's expected for the side LED, but the staging *state* should still update. Check the Max Console for `setforge-loader: staging mode entered`. If you don't see that line, dispatch isn't reaching the handler (likely cause: stale JS in Live, reload the device).
- **Grid pads update** (e.g. row 5/6 pads start flashing after a held tap) — staging is working even though the side LED isn't.
- **Audio changes / preset activates** — dispatch landed on the wrong handler. Either the note number is wrong, or the device thinks no side button is held when the row 5/6 tap arrives.
