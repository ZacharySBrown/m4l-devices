# Companion-app state contract

The read-only feed the companion app (Perform + Curate views) consumes. One `GET /state` returns everything needed to render. Schema: `state.schema.json`. Stub: `serve.py` (sample now; live hooks marked TODO).

```
GET /state  →  200 application/json
```

## Shape
| key | meaning |
|-----|---------|
| `set` | `{name, bpm, bar}` — current set + transport |
| `decks.{A,B}.stems.{drums,bass,other,vox}` | per stem: `source` (preset id), `song`, `artist`, `key`, `loaded_chops`, `live_chop` (index or null), `progress` (%), `bars_left` |
| `presets.{bankA,bankB}[8]` | per preset: `id`, `song`, `artist`, `key`, `sourcing` (`["drums",…]` or null), `color` (its source-legend color or null) |
| `now_playing[]` | the live stems: `{deck, stem, source, progress}` |
| `recommendations[]` | taste-DB: `{song, artist, bpm, key, score, type: congruent\|spicy, action}` |
| `scenes[]` | vetted clip pairings: `{name, color, clips:["A·DR1","B·VX3",…]}` |

Drives: the **surface mirror** (per-source color from `decks` + `presets.color`), the **preset→song legend** (`presets` + `sourcing`), **now-playing** waveforms/progress, **Mix-Next** (`recommendations`), and the **scenes** board (`scenes`).

## Live wiring (TODO — host/Live; cc)
- `set/decks/presets/now_playing` ← loader inspect (CC 102 → `/tmp/setforge_inspect.json`) + AbletonOSC clip/transport.
- `recommendations` ← taste recommend engine (`~/zacharysbrown/taste`) for the current deck songs.

Read-only. No writes.
