# Companion-app state contract v2

The read-only feed the companion app (Perform + Curate views) consumes. One `GET /state` returns everything needed to render. Schema: `state.schema.json`. Server: `serve.py` (live data when Live is running; sample fallback).

```
GET /state  →  200 application/json
```

## Shape
| key | meaning |
|-----|---------|
| `set` | `{name, bpm, bar, playhead_sec, is_playing, loop}` — current set + transport |
| `set.loop` | `{start_bar, len_bars}` or `null` — active loop region |
| `decks.{A,B}.stems.{drums,bass,other,vox}` | per stem: `source`, `song`, `artist`, `key`, `loaded_chops`, `live_chop`, `progress` (%), `bars_left`, `clip_id`, `peaks_ref` |
| `decks.*.stems.*.clip_id` | stable clip identity string (e.g. `"sf:A1:drums:2"`) |
| `decks.*.stems.*.peaks_ref` | waveform peaks URL path (e.g. `"/peaks?clip=sf:A1:drums:2"`) or `null` |
| `presets.{bankA,bankB}[8]` | per preset: `id`, `song`, `artist`, `key`, `sourcing` (`["drums",…]` or null), `color` |
| `now_playing[]` | live stems: `{deck, stem, source, progress, peaks_ref}` |
| `recommendations[]` | taste-DB: `{song, artist, bpm, key, score, type: congruent\|spicy, action}` |
| `scenes[]` | vetted clip pairings: `{id, name, color, clips:["A·DR1","B·VX3",…]}` |
| `scenes[].id` | stable scene identity string (survives renames) |

Drives: the **surface mirror** (per-source color from `decks` + `presets.color`), the **preset→song legend** (`presets` + `sourcing`), **now-playing** waveforms/progress (via `peaks_ref`), **Mix-Next** (`recommendations`), and the **scenes** board (`scenes`).

## v2 additions (over v1)
- `set.playhead_sec`, `set.is_playing`, `set.loop` — transport state for timeline UI
- `decks.*.stems.*.clip_id` + `peaks_ref` — clip identity for waveform rendering + write-side round-trips
- `scenes[].id` — stable scene identity
- `now_playing[].peaks_ref` — waveform peaks for active clips

## Live wiring
- `set/decks/presets/now_playing` ← loader inspect (CC 102 → `/tmp/setforge_inspect.json`) + AbletonOSC clip/transport.
- `recommendations` ← taste recommend engine (`~/zacharysbrown/taste`) for the current deck songs.

Read-only. No writes.
