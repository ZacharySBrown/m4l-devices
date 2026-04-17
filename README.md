# m4l-devices

A collection of handcrafted Max for Live audio effect devices — built from scratch, spec-first, with a focus on faithful DSP implementation of specific sonic aesthetics.

Each device starts with a detailed specification before a single patch is wired. The goal is devices that are deeply understood, not just functional.

---

## Devices

### `tape-loss` — Generation Loss MKII Recreation
> *Lo-fi tape degradation: wow, flutter, magnetic saturation, tape malfunction, and VHS/cassette EQ profiles.*

A native DSP recreation of the Chase Bliss Generation Loss MKII pedal, built entirely in Max for Live without third-party plugins or samples (for v0). Designed to run at near-zero latency as an audio effect in Ableton Live.

**Core features:**
- Wow — slow random pitch drift via variable-delay modulation
- Flutter — fast twitchy amplitude + pitch texture
- Saturate — magnetic hysteresis waveshaper with pre/de-emphasis
- Model — 12 EQ profiles (VHS, cassette, dictaphone, toy recorder, reel-to-reel)
- Failure — tape dropout, pitch snag, and crinkle multi-effect engine
- Noise — independent hiss and mechanical noise sources
- Aux — tape stop, filter bypass, full failure, and freeze effects
- Classic Mode — alternative DSP (sample rate reduction + resonant LP/HP)
- IR-ready architecture — swap biquad EQ models for captured IRs from real hardware

**Status:** Specification complete. Build in progress.
**Spec:** [`specs/tape-loss-spec.md`](specs/tape-loss-spec.md)

---

## Repo Structure

```
m4l-devices/
├── README.md
├── specs/                        # Device specifications (written before code)
│   └── tape-loss-spec.md
└── devices/                      # One folder per device
    └── tape-loss/
        ├── tape-loss.amxd        # Compiled device (loaded by Ableton)
        ├── tape-loss.maxpat      # Source patch
        ├── patches/              # DSP subpatches
        ├── js/                   # JavaScript helpers (coefficient math, IR loading)
        ├── irs/                  # Impulse responses (populated separately)
        │   └── README.md         # IR capture guide
        ├── data/                 # Static data (EQ coefficients, etc.)
        └── docs/                 # Device-specific notes
```

---

## Philosophy

**Spec first.** Every device has a written specification before any patching happens. The spec defines the DSP algorithm for each module, the signal flow, parameter ranges, UI layout, and build order. This makes the build process parallelizable and hands-off-able to an AI coding agent.

**Understand the DSP.** The goal isn't to approximate a sound — it's to understand and implement the actual signal processing that produces it. Where possible, algorithms are derived from the source (manuals, frequency analysis, physical modeling literature).

**IR-augmentable.** Devices that model specific hardware include an IR capture workflow. Biquad approximations ship in v0; captured IRs from real hardware can be dropped in later to replace them without changing the patch architecture.

**Ableton-native.** All parameters are exposed as automatable Live parameters. Devices are designed to feel like first-class Live instruments, not bolted-on utilities.

---

## IR Capture Workflow

Several devices (starting with `tape-loss`) model specific hardware whose linear components — primarily EQ and filtering — can be captured as impulse responses from the real device and loaded into the patch.

The general workflow:

1. Route a sine sweep through your audio interface → reamp box → hardware device → back into the interface
2. Record the response at consistent levels (see device-specific IR capture guide)
3. Deconvolve in REW (Room EQ Wizard) or Voxengo Deconvolver
4. Place the resulting WAV files in `devices/{device}/irs/captured/`
5. Send a `reload_irs` message to the device in Max

Devices detect IR files at load time and fall back to biquad approximations if none are found. This means the device always works out of the box, and gets more accurate as you populate IRs from your own hardware.

---

## Build Environment

- **Max for Live** — Max 8.5+
- **Ableton Live** — any version supporting M4L
- **macOS** — Apple Silicon and Intel
- **Node.js** — for testing JS helper files independently of Max
- **Python 3** — for IR utility scripts and placeholder file generation
- **REW (Room EQ Wizard)** — for IR capture (free)

---

## Development Notes

`.maxpat` files are JSON and can be read and written programmatically. Claude Code is used for specification writing, JavaScript helper authoring, data file generation, and patch scaffolding. Audio testing and UI refinement happen locally in Max.

Tasks that can be done in a Claude Code sandbox (including the iOS app) are tagged `SANDBOX-OK` in each device spec. Tasks requiring Max or Ableton are tagged `LOCAL-ONLY`.

---

## License

MIT — do what you want, attribution appreciated.
