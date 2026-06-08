# punch-fx — Build Spec v0.1.0

A Max for Live audio effect that recreates four pressure-sensitive punch-in effects from the Teenage Engineering EP-133 K.O. II: **Beat Repeat**, **Stutter**, **Mute Slicer**, and **Octave Down**. Designed for the `m4l-devices` repo, alongside `tape-loss`.

This document is the **complete build specification**. A Claude Code instance with access to a working M4L development environment should be able to build, test, and ship v0.1.0 of this device from this doc alone, using the task list at the bottom.

---

## 0. Context and design intent

### What the EP-133 punch-in FX feel like

Hold the EP-133's FX button and press a pad, and a momentary effect chops, gates, or warps the audio. The expression comes from finger pressure on the pad: harder press = more intense effect. Release the pad = effect disengages cleanly. Multiple pads can be held simultaneously with independent pressure.

The character is deliberately lo-fi and gestural. These are performance effects, not studio polish.

### What `punch-fx` is and is not

`punch-fx` is **a single M4L audio effect** that drops on any track (audio track, return, or master). It exposes:

- **4 momentary on/off triggers**, one per effect, MIDI-mappable
- **4 continuous pressure values**, one per effect, MIDI-mappable (0.0–1.0)
- **A handful of per-effect character parameters** (curves, grain sizes, etc.) — set once, not for performance use

Users MIDI-map a controller of their choice (Launchpad Pro MK2 with poly aftertouch is the reference target, but any controller with pressure data works) to drive the device. The device itself has no controller-specific code.

**Effects are only active while their trigger is on.** Release = bypass. The four effects run in a fixed order in series; if multiple are active, they stack.

### What this device is *not*:

- Not a clone of the EP-133's exact DSP — these are educated-guess implementations, not measured replicas
- Not extensible to the other 6 EP-133 effects — fixed at 4
- Not a MIDI device or controller surface — pure audio effect with mappable params
- Not a faithful pitch-preserving plugin — character > accuracy

### Companion to `tape-loss`

This device follows the same patterns as `tape-loss` in `m4l-devices`:

- gen~ for DSP, JS for parameter routing and state machine
- Task tagging (SANDBOX-OK / SANDBOX-PARTIAL / LOCAL-ONLY) for mobile-friendly contribution via Claude Code iOS
- Headless test harness (offline rendering + null/characteristic tests) for autonomous validation
- Spec-and-build pattern with explicit acceptance criteria

---

## 1. Architecture

### 1.1 Signal flow (top level)

```
Audio In
   ↓
[Beat Repeat]   ← trigger_1, pressure_1
   ↓
[Stutter]       ← trigger_2, pressure_2
   ↓
[Mute Slicer]   ← trigger_3, pressure_3
   ↓
[Octave Down]   ← trigger_4, pressure_4
   ↓
[Output mix]    (smooth dry/wet on each effect's trigger to prevent clicks)
   ↓
Audio Out
```

Each effect runs continuously in gen~. The trigger gates a smoothed dry/wet between the effect's output and the pre-effect signal. This means **no effect is ever "off" in the DSP sense** — it's always running and the trigger crossfades into its output. This avoids click artifacts and lets us implement attack/release shapes cleanly.

### 1.2 Per-effect trigger/pressure pipeline

Each of the four effect slots has the same control envelope shape:

```
trigger (bool) ─┐
                ├──► gate envelope (1ms attack, 8ms release, exponential)
                │      ↓
pressure (0-1) ─┴──► smoothed pressure (3ms slew)
                       ↓
                  curve_fn(pressure)  ← per-effect curve (linear/exp/s-curve)
                       ↓
                  DSP parameter
```

- **Trigger** drives the dry/wet crossfade (ramps up when on, ramps down when off — release slightly longer than attack to soften the tail).
- **Pressure** drives the effect's primary modulation target, after smoothing and curve-shaping.
- **Smoothing constants** are conservative — fast enough to feel responsive, slow enough to avoid zipper noise.

### 1.3 Velocity-to-pressure fallback

For controllers without aftertouch (e.g. Launchpad MK2, basic MIDI pads):

- A per-effect mode toggle: `pressure_source = aftertouch | velocity`
- In `velocity` mode: note-on velocity sets pressure value; pressure is held at that level until note-off; aftertouch input is ignored
- In `aftertouch` mode: note-on engages trigger, aftertouch drives pressure, note-off releases (default)

This is a global device setting (one toggle for all four effects), not per-effect, to keep the UI simple. Default: `aftertouch`.

### 1.4 MIDI mapping surface

Live exposes parameters to MIDI mapping. The device's mappable parameters:

| Parameter | Type | Range | Notes |
|---|---|---|---|
| `BR On` | bool | 0/1 | Beat Repeat trigger |
| `BR Pressure` | float | 0.0–1.0 | Beat Repeat pressure |
| `ST On` | bool | 0/1 | Stutter trigger |
| `ST Pressure` | float | 0.0–1.0 | Stutter pressure |
| `MS On` | bool | 0/1 | Mute Slicer trigger |
| `MS Pressure` | float | 0.0–1.0 | Mute Slicer pressure |
| `OD On` | bool | 0/1 | Octave Down trigger |
| `OD Pressure` | float | 0.0–1.0 | Octave Down pressure |

Users right-click → MIDI map → press their controller's pad. Live handles the rest.

### 1.5 Character parameters (not for performance)

These live in a collapsed "Character" panel, set once per project:

| Parameter | Range | Default | Effect |
|---|---|---|---|
| `Pressure Source` | aftertouch / velocity | aftertouch | Global fallback mode |
| `BR Curve` | linear / exp / s-curve | exp | Pressure response |
| `BR Min Length` | 1/32 – 1/4 note | 1/32 | Tightest repeat at full pressure |
| `BR Max Length` | 1/8 – 1 bar | 1/4 | Longest repeat at zero pressure |
| `ST Slice Length` | 20–150ms | 50ms | Fixed slice length |
| `ST Jitter Curve` | linear / exp | exp | Pressure → randomness response |
| `MS Min Rate` | 1/8 – 1/2 | 1/4 | Slowest gate at zero pressure |
| `MS Max Rate` | 1/32 – 1/8 | 1/32 | Fastest gate at full pressure |
| `MS Shape` | hard / soft | hard | Gate edge shape |
| `OD Mode` | tempo-preserve / varispeed | tempo-preserve | Pitch shift method |
| `OD Curve` | linear / exp / s-curve | exp | Pressure response |
| `OD Grain Size` | 10–200ms | 50ms | Tempo-preserve mode only |
| `Master Wet` | 0.0–1.0 | 1.0 | Final dry/wet for whole device |

---

## 2. DSP specifications per effect

### 2.1 Beat Repeat

**Concept**: On trigger, capture a slice of incoming audio into a buffer. Loop that buffer for as long as the trigger is held. Loop length is a function of pressure: more pressure = shorter loop = faster repeats. Tempo-synced — loop lengths quantize to musical divisions.

**DSP**:
- Ring buffer, 2 seconds at host sample rate, stereo
- Write pointer always advances at sample rate (continuously captures)
- On trigger-on: latch current write position as `loop_start`
- Compute `loop_length_samples` from pressure:
  ```
  pressure_curved = curve(pressure_smoothed, BR_Curve)
  loop_length_musical = lerp(BR_Max_Length, BR_Min_Length, pressure_curved)
  loop_length_samples = musical_to_samples(loop_length_musical, host_bpm, host_sr)
  ```
- Read pointer starts at `loop_start`, advances at sample rate, wraps back to `loop_start` when it reaches `loop_start + loop_length_samples`
- Output: read pointer's current value, with small (5ms) crossfade at wrap points to hide clicks
- On trigger-off: gate envelope ramps wet → dry over release time

**Pressure mapping**:
- pressure 0.0 → loop length = `BR_Max_Length` (default 1/4 note — slow, deliberate)
- pressure 1.0 → loop length = `BR_Min_Length` (default 1/32 — buzz roll)
- Default curve: `exp` (most expression in middle range)

**Lengths quantize** to musical divisions at trigger-on. While held, length is recomputed from pressure each block (every 64 samples). Length changes are smoothed over 50ms to prevent jarring jumps.

**Edge case — tempo divisions**: snap loop length to nearest valid musical division from the set `{1/32, 1/24, 1/16, 1/12, 1/8, 1/6, 1/4, 1/3, 1/2, 1}`. This prevents continuous loop-length changes from producing musically incoherent rates.

### 2.2 Stutter

**Concept**: A much shorter version of Beat Repeat with retriggering and randomness. Captures a short slice (~50ms by default), loops it tightly, and at higher pressure introduces jitter — random variations in slice length and retrigger timing — for a glitchier feel.

**DSP**:
- Ring buffer, 500ms at host sample rate, stereo
- Write pointer always advances
- On trigger-on: latch `loop_start = current_write_pos`
- Base loop length = `ST_Slice_Length` (not tempo-synced — fixed time)
- Each loop iteration, jitter is applied:
  ```
  jitter_amount = curve(pressure_smoothed, ST_Jitter_Curve)  // 0.0 to 1.0
  length_jitter = random(-0.5, 0.5) * jitter_amount * base_loop_length
  retrigger_offset = random(0, jitter_amount * base_loop_length)
  effective_length = base_loop_length + length_jitter
  ```
- Pressure 0 = exact repeating slice (no jitter)
- Pressure 1 = each iteration has up to ±50% length variation and random retrigger offset within the source buffer

**Pressure mapping**:
- pressure 0.0 → clean stutter (predictable, glitch-free)
- pressure 1.0 → maximum chaos (granular/broken sound)

**Why this differs from Beat Repeat**: Beat Repeat is *deterministic and rhythmic* (tempo-synced, monotonic loop length). Stutter is *chaotic and timbral* (fixed short slice, randomness scaled by pressure). They feel different in performance even though they share the buffer infrastructure.

### 2.3 Mute Slicer

**Concept**: Tempo-synced amplitude gate. The audio is rhythmically chopped on/off at a rate set by pressure. Light press = slow gate (quarter notes), heavy press = fast gate (32nds and faster).

**DSP**:
- Phasor synced to host transport, running at the gate rate
- Gate rate computed from pressure:
  ```
  pressure_curved = curve(pressure_smoothed, exp)
  gate_rate = lerp(MS_Min_Rate, MS_Max_Rate, pressure_curved)
  phasor_freq_hz = bpm_to_hz(host_bpm, gate_rate)
  ```
- Gate shape from phasor:
  - `hard` mode: gate = (phasor < 0.5) ? 1.0 : 0.0
  - `soft` mode: gate = smoothstep over short edges (1ms attack, 1ms release on each transition)
- Output: `input * gate_value`

**Pressure mapping**:
- pressure 0.0 → gate rate = `MS_Min_Rate` (default 1/4 note)
- pressure 1.0 → gate rate = `MS_Max_Rate` (default 1/32 note)
- Snap to nearest division from `{1/4, 1/8, 1/12, 1/16, 1/24, 1/32}` to prevent inharmonic gating

**Phase sync**: On trigger-on, the phasor resets to 0 *aligned to the nearest beat boundary*. This makes the slicer feel locked to the music rather than starting at random phase.

### 2.4 Octave Down

**Concept**: Pitch the audio down by up to one octave, controlled by pressure. Two modes are supported (set as character parameter, not performance):

- **`tempo-preserve`** (default): Granular pitch shift. Pitch drops, tempo stays.
- **`varispeed`**: Playback-speed pitch shift. Pitch drops, audio slows (classic sampler character).

#### 2.4.1 `tempo-preserve` mode (granular)

**DSP**:
- Ring buffer, 500ms at host sample rate, stereo
- Write pointer always advances
- Grain size = `OD_Grain_Size` (default 50ms)
- Run two grains in parallel, 180° offset, each with a Hann window envelope, summed
- Each grain reads from buffer at rate `r = 2^(-semitones/12)`:
  - 0 semitones → r = 1.0 (no shift)
  - -12 semitones → r = 0.5 (octave down)
- When a grain reaches its window end, it restarts from a new buffer position, set so the next grain's start is "behind" the write pointer enough to never read uninitialized data
- Crossfade between grains is implicit in the Hann window overlap-add

**Pressure mapping**:
- pressure 0.0 → semitones = 0 (no shift)
- pressure 1.0 → semitones = -12 (full octave down)
- Curve: `exp` default (light press = subtle, heavy = full drop)

**Why two grains, 180° offset**: standard granular pitch-shift trick. One grain alone produces audible amplitude modulation at the grain rate; two grains 180° apart with Hann windows sum to constant amplitude. Three grains would be cleaner but cost more CPU; two is the typical compromise and gives a slightly characterful sound at large pitch shifts (which is what we want).

#### 2.4.2 `varispeed` mode (playback-rate)

**DSP**:
- Same ring buffer
- Single read pointer, advancing at rate `r = 2^(-semitones/12)`
- No grain windowing, no overlap
- Read pointer trails write pointer at safe distance (e.g. always 100ms behind to prevent overrun)

**Effect on tempo**: Output is slower than input by factor `1/r`. At full octave down (r=0.5), output is half-speed. This is the desired character — it's the chopped-and-screwed / lo-fi sampler sound.

**Important note**: In varispeed mode, the output stream's audio events drift in time from the input. This is by design. The user is opting in to that sound when they pick this mode.

**Pressure mapping**: same as tempo-preserve mode.

---

## 3. Curve functions

Three curve types are available for parameters with a `Curve` setting:

```
linear:  y = x
exp:     y = x^2.5          (more expression in low/mid range)
s-curve: y = 0.5 * (1 - cos(π * x))   (smooth at both ends)
```

Implementation: as a gen~ subpatch or codebox snippet, taking `(x, curve_id)` and returning `y`.

---

## 4. UI

### 4.1 Layout

Plain Live device UI, fits in standard M4L device strip.

```
┌─ punch-fx ─────────────────────────────────────────────────────────┐
│                                                                    │
│  [BR]──[ST]──[MS]──[OD]    ◆ Master Wet ●─────────                  │
│   ●●    ●●    ●●    ●●                                             │
│   ▓▓    ▓▓    ▓▓    ▓▓                                             │
│   On    On    On    On                                             │
│   Pres  Pres  Pres  Pres                                           │
│                                            ▼ Character             │
└────────────────────────────────────────────────────────────────────┘
```

- Each effect column shows: a name button (lit when active), an LED ring for current pressure, and two small live.button/live.dial widgets exposing the On and Pressure params for direct manipulation and clear MIDI-map targets.
- The lit-when-active state gives visual feedback that mapping is working.
- Pressure ring color: dim gray at 0, brightens to white at 1.0. Color choice for each effect from `tape-loss` palette to keep visual consistency across `m4l-devices`.

### 4.2 Character panel

Disclosure triangle opens a second row with the character parameters. Standard live.dial / live.menu widgets, well-labeled. Tooltips for each parameter explain its effect.

### 4.3 Help and docs

A small `?` button opens a Live `live.comment` overlay or links to a README in the device's folder, explaining:
- MIDI mapping workflow
- Aftertouch vs velocity fallback toggle
- The four effects in one line each

---

## 5. Repository structure

```
m4l-devices/
├── tape-loss/                  (existing)
├── punch-fx/                   (new)
│   ├── punch-fx.amxd           (the device — binary, hand-built in Live)
│   ├── README.md
│   ├── CHANGELOG.md
│   ├── spec/
│   │   └── punch-fx-spec.md    (this document)
│   ├── src/
│   │   ├── gen/
│   │   │   ├── punch-fx.gendsp           (top-level gen patch)
│   │   │   ├── beat-repeat.gendsp        (BR DSP)
│   │   │   ├── stutter.gendsp            (Stutter DSP)
│   │   │   ├── mute-slicer.gendsp        (MS DSP)
│   │   │   ├── octave-down-grain.gendsp  (OD tempo-preserve)
│   │   │   ├── octave-down-vari.gendsp   (OD varispeed)
│   │   │   ├── curves.gendsp             (shared curve fns)
│   │   │   └── envelope.gendsp           (shared gate env)
│   │   └── js/
│   │       ├── params.js                 (parameter routing, scope: M4L)
│   │       ├── pressure-fallback.js      (velocity → pressure)
│   │       └── tempo-sync.js             (musical division → samples)
│   ├── tests/
│   │   ├── README.md
│   │   ├── harness/
│   │   │   ├── render.py                 (offline render driver)
│   │   │   ├── analyze.py                (audio analysis utilities)
│   │   │   └── assertions.py             (test assertions)
│   │   ├── fixtures/
│   │   │   └── test-signals.wav          (sine, click train, white noise, drum loop)
│   │   ├── unit/
│   │   │   ├── test_curves.py
│   │   │   ├── test_tempo_sync.py
│   │   │   └── test_pressure_fallback.py
│   │   ├── dsp/
│   │   │   ├── test_beat_repeat.py
│   │   │   ├── test_stutter.py
│   │   │   ├── test_mute_slicer.py
│   │   │   └── test_octave_down.py
│   │   └── integration/
│   │       └── test_signal_chain.py
│   └── docs/
│       ├── design-notes.md       (rationale, references)
│       └── midi-mapping.md       (user-facing guide)
```

---

## 6. Test harness

Test strategy: render audio offline through the gen~ DSP, validate audio properties against assertions.

### 6.1 Rendering approach

Two paths, prefer the first:

**Path A: gen~ export to C++ → standalone executable**

`gen~` patches can be exported as C++ code. The harness compiles each gen subpatch as a small standalone executable that reads input WAV + parameter automation CSV, writes output WAV.

- Pros: pure CLI, runs in CI, no Max required for tests
- Cons: requires gen~ export step; some Max-specific features (host transport, BPM) need stubbing

For each DSP subpatch (BR/Stutter/MS/OD-grain/OD-vari), export to standalone, run with test signals, analyze output.

**Path B: NRT (non-realtime) Max scripting**

If Path A is impractical for some patches, fall back to a Max patch that loads `punch-fx.amxd`, drives parameters via a JS script, and exports rendered audio to disk via `sfrecord~` or similar. Driven from CLI via Max's `-batch` or `runtimedir` flags.

Default to Path A. Fall back to Path B only where needed.

### 6.2 Test signals (fixtures)

Stored as 16-bit 48kHz stereo WAV in `tests/fixtures/`:

- `sine_1k.wav` — 1kHz sine, 4 seconds, -12 dBFS
- `click_train_120bpm.wav` — single-sample clicks at 16th-note intervals at 120 BPM, 4 bars
- `pink_noise.wav` — pink noise, 4 seconds, -12 dBFS
- `drum_loop_120bpm.wav` — a real drum loop at 120 BPM, 8 bars (royalty-free or self-recorded)

### 6.3 Assertions per effect

#### Beat Repeat
- **Capture-and-loop test**: Feed `click_train_120bpm` at 120 BPM. Trigger BR at t=1.0s, pressure=0.5, hold for 2 seconds. Output's autocorrelation in the held window should show a strong peak at the expected loop length (1/8 note = 0.25s at 120 BPM). **Acceptance**: peak at expected lag ± 5% of lag length.
- **Pressure-length monotonicity**: At pressures `[0.0, 0.25, 0.5, 0.75, 1.0]`, measure detected loop period. Period should monotonically decrease with pressure. **Acceptance**: monotonic, no ties.
- **No clicks at trigger boundaries**: Sample-difference at trigger-on and trigger-off transitions should not exceed input's largest sample-difference. **Acceptance**: peak `|d/dt|` at transitions ≤ 1.5× peak `|d/dt|` in source.

#### Stutter
- **Fixed slice length test**: At pressure=0.0, output should be a clean loop of `ST_Slice_Length` (default 50ms). Autocorrelation peak at 50ms ± 5%. **Acceptance**: peak detected.
- **Jitter increases with pressure**: Compute output's autocorrelation peak height (normalized) at pressures `[0.0, 0.5, 1.0]`. Peak height should *decrease* with pressure (more jitter = less periodic). **Acceptance**: monotonic decrease, value at p=1.0 less than 70% of value at p=0.0.

#### Mute Slicer
- **Gate-rate test**: Feed sine, trigger MS with pressure=0.5 at 120 BPM. Output envelope should have periodic zero-crossings at expected gate rate. **Acceptance**: envelope FFT shows strong peak at expected gate frequency ± 5%.
- **Beat alignment**: At trigger-on aligned with a beat in source, output gate phase should also be at start-of-cycle. **Acceptance**: first gate close occurs at expected beat-relative offset ± 1ms.
- **Gate depth**: In `hard` mode at gate-closed phase, output sample magnitude should be ≤ -60 dB. **Acceptance**: max magnitude in closed window ≤ -60 dB.

#### Octave Down — tempo-preserve
- **Spectral centroid shift**: Feed pink noise. At pressure=1.0 (full octave down), output's spectral centroid should be approximately half the input's. **Acceptance**: ratio ∈ [0.45, 0.55].
- **Tempo preservation**: Feed `click_train_120bpm`. At any pressure, click times in output should align with click times in input ± grain size. **Acceptance**: cross-correlation peak at lag=0 within ±50ms.
- **No transients at grain boundaries**: Output amplitude envelope (envelope follower) should not have periodic spikes at grain rate. **Acceptance**: envelope FFT peak at grain rate ≤ -20 dB below DC.

#### Octave Down — varispeed
- **Spectral centroid shift**: Same as tempo-preserve. **Acceptance**: ratio ∈ [0.45, 0.55].
- **Tempo drop**: Feed `click_train_120bpm` at pressure=1.0. Detected click interval in output should be 2× input interval. **Acceptance**: ratio ∈ [1.95, 2.05].

#### Integration: Signal chain
- **Series ordering**: With all four triggers on at pressure=0.5, render through full chain. Output should not clip, not contain DC offset > 1%, and not contain NaN/Inf samples. **Acceptance**: max abs ≤ 0.99, mean ≤ 0.01, no non-finite samples.
- **Bypass identity**: With all triggers off, output should equal input within numerical noise. **Acceptance**: max abs(output - input) ≤ -100 dBFS.

### 6.4 Running tests

```
cd m4l-devices/punch-fx
pip install -r tests/requirements.txt   # numpy, scipy, soundfile, pytest
pytest tests/ -v
```

Tests should run in under 60 seconds total on a modern laptop.

---

## 7. Implementation guidance

### 7.1 gen~ patterns to use

- **Ring buffers**: use `data` operator with `peek`/`poke` for sample-accurate ring buffers
- **Phasor for slicer**: `phasor` operator with frequency input from BPM math
- **Grain envelopes**: `kink` or polynomial approximation of Hann window; pre-compute lookup table via `data` for efficiency
- **Crossfades**: linear or equal-power; equal-power for trigger envelopes, linear for grain overlap
- **Smoothing**: one-pole filters (`history` + math) tuned to specified slew times

### 7.2 Sample-rate independence

All time constants are specified in milliseconds. Convert to samples in code as `samples = ms * sr / 1000`. Test at 44.1kHz and 48kHz at minimum. The device must work at any host sample rate Live supports.

### 7.3 Tempo sync

Read `live.thisdevice` tempo via JS, push to gen~ inlets every block. Convert musical divisions to samples in JS using:

```javascript
function divisionToSamples(division, bpm, sr) {
    // division: 1/32 = 0.03125, 1/4 = 0.25, etc.
    var seconds = (60 / bpm) * 4 * division;
    return Math.round(seconds * sr);
}
```

### 7.4 Polyphonic aftertouch input

Live's MIDI mapping reads channel pressure but not polyphonic aftertouch directly. There are two paths:

**Recommended**: Use a tiny upstream MIDI effect (or a `midiparse` chain inside the device) that listens for polyphonic AT messages, picks out the AT values for the four mapped notes, and converts each to a CC value the audio device can MIDI-map.

**Alternative**: Document that the user should put a "Pitch + Mod" or similar M4L MIDI tool upstream that converts poly AT → CCs.

For v0.1.0, document the alternative path and ship a recommended companion MIDI device (`punch-fx-poly-at.amxd`) that does the conversion. Make this optional — channel-pressure-mapped controllers work without it.

### 7.5 What "feels right" looks like

Without calibration, these are the design choices that should make it feel close to the EP-133:

- **Trigger attack 1ms, release 8ms** — snappy on, soft off. The EP-133 feels instant when you press but doesn't click on release.
- **Pressure smoothing 3ms** — fast enough to feel direct, slow enough to suppress ADC noise on the input controller.
- **Default curve `exp` everywhere** — gives most expression in the light-to-medium press range.
- **Tempo-sync everywhere it makes sense** — Beat Repeat and Mute Slicer feel "musical" because they snap to divisions. Stutter and Octave Down don't need it.

If these defaults feel off after a play-test, the most likely tuning targets are: increase trigger release to 15ms if releases feel abrupt; switch curves to `s-curve` if the response feels twitchy; adjust the BR/MS division sets if some divisions feel rhythmically wrong.

---

## 8. Acceptance criteria for v0.1.0

The release is shippable when:

1. All tests in `tests/` pass.
2. The device loads in Ableton Live 11.x and 12.x without warnings.
3. All 8 performance parameters MIDI-map cleanly to a controller.
4. The aftertouch-vs-velocity toggle works as specified.
5. The character panel collapse/expand works.
6. With all 4 triggers off, the device passes audio without measurable degradation (null test).
7. README.md includes: install instructions, MIDI-map walkthrough, parameter reference, known issues.
8. CHANGELOG.md lists v0.1.0.

---

## 9. Task list

Tasks tagged for sandbox-friendly execution. SANDBOX-OK tasks can run in Claude Code's sandbox. SANDBOX-PARTIAL needs sandbox plus a Mac for verification. LOCAL-ONLY requires Max/Live on the local machine.

### Phase 1 — Scaffolding (SANDBOX-OK)
- [ ] T1.1 Create `m4l-devices/punch-fx/` directory tree per §5
- [ ] T1.2 Write `README.md` skeleton (will fill in as build progresses)
- [ ] T1.3 Initialize `CHANGELOG.md` with v0.1.0 in-progress entry
- [ ] T1.4 Copy this spec to `spec/punch-fx-spec.md`
- [ ] T1.5 Create `tests/requirements.txt` (numpy, scipy, soundfile, pytest, click)
- [ ] T1.6 Set up `pytest.ini` and basic test discovery

### Phase 2 — Test fixtures (SANDBOX-OK)
- [ ] T2.1 Generate `sine_1k.wav` programmatically
- [ ] T2.2 Generate `click_train_120bpm.wav` programmatically
- [ ] T2.3 Generate `pink_noise.wav` programmatically
- [ ] T2.4 Source or generate `drum_loop_120bpm.wav` (use a CC0 source or generate synthetic)
- [ ] T2.5 Commit fixtures with a README explaining their construction

### Phase 3 — Reference DSP in Python (SANDBOX-OK)

The point of this phase: build Python reference implementations of all five DSP subpatches, validated by the test harness, *before* writing any gen~ code. This separates DSP correctness from gen~ implementation correctness.

- [ ] T3.1 `harness/render.py` — offline DSP runner skeleton
- [ ] T3.2 `harness/analyze.py` — autocorrelation, FFT, spectral centroid, click detection utilities
- [ ] T3.3 `harness/assertions.py` — assertion helpers per §6.3
- [ ] T3.4 Python reference: `ref/beat_repeat.py`
- [ ] T3.5 Python reference: `ref/stutter.py`
- [ ] T3.6 Python reference: `ref/mute_slicer.py`
- [ ] T3.7 Python reference: `ref/octave_down_grain.py`
- [ ] T3.8 Python reference: `ref/octave_down_vari.py`
- [ ] T3.9 Python reference: `ref/curves.py` and `ref/envelope.py`
- [ ] T3.10 Wire Python references to test harness — all DSP tests pass against Python reference

**Gate**: Phase 3 is complete when `pytest tests/dsp/` passes 100% against Python reference implementations. This proves the DSP design is correct; only then do we port to gen~.

### Phase 4 — gen~ DSP port (LOCAL-ONLY)
- [ ] T4.1 Port `curves` and `envelope` shared subpatches
- [ ] T4.2 Port `beat-repeat.gendsp`
- [ ] T4.3 Port `stutter.gendsp`
- [ ] T4.4 Port `mute-slicer.gendsp`
- [ ] T4.5 Port `octave-down-grain.gendsp`
- [ ] T4.6 Port `octave-down-vari.gendsp`
- [ ] T4.7 Compose top-level `punch-fx.gendsp` chaining the four effects
- [ ] T4.8 Export each subpatch to C++; verify standalone executables match Python reference on the same fixtures (within numerical tolerance, e.g. -80 dBFS)

### Phase 5 — M4L device shell (LOCAL-ONLY)
- [ ] T5.1 Create `punch-fx.amxd` with gen~ patch loaded
- [ ] T5.2 Implement `params.js` — parameter exposure, MIDI mapping targets
- [ ] T5.3 Implement `pressure-fallback.js` — velocity-as-pressure mode
- [ ] T5.4 Implement `tempo-sync.js` — division-to-samples for BR and MS
- [ ] T5.5 Build the UI per §4.1
- [ ] T5.6 Build the character panel per §4.2
- [ ] T5.7 Add help/README link

### Phase 6 — Poly AT companion (LOCAL-ONLY, optional but recommended)
- [ ] T6.1 Build `punch-fx-poly-at.amxd` — MIDI device, listens for poly AT, outputs CC per mapped note
- [ ] T6.2 Document its use in the user guide

### Phase 7 — Integration testing (SANDBOX-PARTIAL)
- [ ] T7.1 Run gen~ standalone C++ exports through full test suite — assertions match Python reference
- [ ] T7.2 NRT render through `.amxd` in Max (LOCAL-ONLY portion) — output matches gen~ standalone within numerical tolerance
- [ ] T7.3 Live-load test: open in Live 11 and Live 12, confirm no warnings, params map cleanly

### Phase 8 — Documentation and release (SANDBOX-OK)
- [ ] T8.1 Complete `README.md` — install, MIDI map, parameter reference, known issues
- [ ] T8.2 Complete `docs/midi-mapping.md` — user-facing walkthrough with Launchpad Pro MK2 as reference example
- [ ] T8.3 Complete `docs/design-notes.md` — rationale, references to EP-133, future calibration plans
- [ ] T8.4 Update `CHANGELOG.md` to v0.1.0 released
- [ ] T8.5 Tag release in git

---

## 10. Out of scope for v0.1.0

Explicitly deferred:

- Calibration against EP-133 measurements (IR-based, future work)
- Adding the other 6 EP-133 effects
- Visualization beyond pressure LED rings
- Preset management beyond Live's built-in
- Hardware-specific controller support beyond MIDI-mapping
- MPE support
- Sidechain inputs for triggering from audio
- A "freeze" / latching mode (FX persists after release)

---

## 11. References

- EP-133 K.O. II official guide: https://teenage.engineering/guides/ep-133/effects
- EP-133 punch-in FX community table: https://github.com/neilbaldwin/KOII-tips-and-tricks
- Sound on Sound EP-133 review: https://www.soundonsound.com/reviews/teenage-engineering-ep-133-ko-ii
- Granular pitch shifting (textbook reference): Roads, *Microsound* (MIT Press, 2001), ch. 5
- Sister project: `m4l-devices/tape-loss`

---

*End of spec v0.1.0.*
