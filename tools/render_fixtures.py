"""
Lightweight A/B fixture renderer for tape-loss DSP designs.

Walks dsp/reference/fixtures/, groups WAVs by module, pairs dry inputs with
wet/demo outputs, and emits a static HTML page with embedded audio elements
and per-fixture "what to listen for" blurbs.

Run from the repo root:
    python3 tools/render_fixtures.py
    python3 -m http.server 8000

Then open http://localhost:8000/docs/fixtures-viewer/

The server MUST be rooted at the repo root, not the viewer dir, because the
HTML references audio files at ../../dsp/reference/fixtures/*.wav (relative to
docs/fixtures-viewer/index.html). A server rooted at the viewer dir can't
serve files above its own root.
"""

from __future__ import annotations

import html
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES_DIR = REPO_ROOT / "dsp" / "reference" / "fixtures"
OUT_DIR = REPO_ROOT / "docs" / "fixtures-viewer"
OUT_HTML = OUT_DIR / "index.html"

# Signal-chain order from specs/tape-loss.pedal.yaml
SIGNAL_CHAIN_ORDER = [
    "tl_saturate",
    "tl_model_eq",
    "tl_failure",
    "tl_wow",
    "tl_flutter",
    "tl_aux",
    "tl_volume_mix",
    "tl_dry_mix",
    "tl_noise",
]

MODULE_PREAMBLES = {
    "tl_saturate": (
        "Memoryless asymmetric tanh waveshaper with NAB/IEC pre/de-emphasis shelves "
        "bracketing the shaper. 2× oversampling around the nonlinearity (31-tap halfband "
        "Kaiser-β=8 FIR). Drive-gated negative-half multiplier produces even-harmonic content. "
        "<b>Listen overall for:</b> warm, asymmetric harmonic richness; no audible aliasing on "
        "the 1k sweep; clean unity at sat=0."
    ),
    "tl_model_eq": (
        "12 boutique-tape-medium EQ profiles, RBJ biquads recomputed at runtime per sample rate. "
        "Profile changes use a 12 ms equal-power crossfade between two parallel chains (no clicks). "
        "<b>Listen overall for:</b> distinctive spectral fingerprint per profile; band limiting "
        "and head-bump bumps consistent with the modeled medium."
    ),
    "tl_failure": (
        "Multi-engine event scheduler: drop (gated dropouts), snag (variable-delay pitch jumps), "
        "crinkle (filtered impulse trains), micro-flutter AM. Poisson scheduling with quadratic/cubic "
        "rate tapers. <b>Round-2 recalibration applied (2026-04-26):</b> drop rate +50%, drop duration "
        "3×, snag rate 3.5×, snag peak cents 1.5× (transients much higher on steep ramps), crinkle rate "
        "and amplitude halved. <b>Listen overall for:</b> headline drama from dropouts and pitch snags; "
        "crackle now sits under the action, not over it. f=1.0 should feel <i>broken-but-musical</i>."
    ),
    "tl_wow": (
        "Slow random pitch drift via variable-delay-line read with 4-point Hermite cubic interpolation. "
        "LFO = two filtered-noise streams (0.5 + 0.7 Hz, 1-pole LPF cascaded). 25 ms base delay (departs "
        "from spec's 5 ms — see flag). <b>Listen overall for:</b> drift that wanders rather than oscillates; "
        "calibration target is ±15c at noon, ±70c at max."
    ),
    "tl_flutter": (
        "Fast pitch + AM modulation. Two summed filtered-noise bands per path (pitch: 8+19 Hz LP; "
        "AM: 11+23 Hz LP), 99th-percentile-peak normalized. 4-point Lagrange interp. <b>Round-2 "
        "retune (2026-04-26):</b> taper changed quadratic → <b>sqrt</b> (concave) so noon is "
        "noticeably stronger; max bumped 25%. Noon pitch now ~20c p99 / AM ~3.4 dB; max ~28c / "
        "5 dB. classic_mode = AM-bypass-only (still flagged for review). <b>Listen overall for:</b> "
        "f=0.5 chord must clearly flutter; f=1.0 watch AM — ~5 dB may exceed spec target."
    ),
    "tl_aux": (
        "Three modes selected by aux_mode: STOP (tape-stop deceleration), FILTER (TPT-SVF log sweep "
        "18kHz→200Hz), FAIL (sidechain control to tl_failure, no local audio destruction). Onset "
        "envelope = exponential one-pole over aux_onset_ms. <b>Listen overall for:</b> mechanical-feel "
        "ramps; STOP should slow pitch-and-amplitude smoothly; FILTER sweep should resonate gently; "
        "FAIL audio is bit-identical to dry (it's a control signal — listen to demo_fail_ctrl mono trace)."
    ),
    "tl_volume_mix": (
        "Wet output gain + optional MISO mono-sum-and-duplicate. Gain coefficient one-pole-smoothed "
        "(τ=10 ms) for zipper-noise-free knob movement. MISO sum: (L+R)/2. <b>Listen overall for:</b> "
        "perceptually clean unity, expected +6 dB at volume=2.0, dead-quiet zipper test."
    ),
    "tl_dry_mix": (
        "Mode-switched dry+wet mixer: NONE / SMALL (-8 dB) / UNITY. 10 ms Hann crossfade on mode change. "
        "Engineer's responsibility: align dry-tap latency with WOW's 30 ms nominal upstream — reference "
        "tests injection separately. <b>Listen overall for:</b> NONE = wet only (bit-identical to "
        "input_wet); UNITY of pitch-shifted wet vs dry produces natural chorus."
    ),
    "tl_noise": (
        "Tape hiss (Voss-McCartney pink + 50Hz HPF / 12kHz LPF) + mechanical noise (CCW=VCR motor whir, "
        "CW=60Hz mains hum with 6-harmonic stack and half-wave-rectified PSU character). mechanical_level "
        "is bipolar with a hard silent center at 0.5. Mono-correlated hum, decorrelated hiss/VCR. "
        "<b>Listen overall for:</b> hiss should sit below program; VCR (low values) sounds rumbly; "
        "hum (high values) sounds buzzy and pitched."
    ),
}

# Per-fixture blurbs. Keyed by basename without .wav.
# Curated from design docs + agent reports.
FIXTURE_BLURBS = {
    # tl_saturate
    "tl_saturate_input_dry": (
        "Dry probe for the saturator. Likely a sweep, sine, or guitar-like tone — "
        "use as your A/B baseline."
    ),
    "tl_saturate_demo_sat0p0_LINE": (
        "saturate=0.0, LINE input gain. <b>Should be near-bit-identical to dry</b> "
        "(short-circuit bypass — flagged divergence from strict spec). If you hear "
        "any difference, that's a bug."
    ),
    "tl_saturate_demo_sat0p3_LINE": (
        "saturate=0.3, LINE input gain. Subtle warmth; tiny added even-harmonic content. "
        "Should still feel transparent and unsaturated."
    ),
    "tl_saturate_demo_sat0p7_LINE": (
        "saturate=0.7, LINE input gain. Audible asymmetric saturation with even+odd "
        "harmonics. Pre/de-emphasis means HF content gets driven harder than LF."
    ),
    "tl_saturate_demo_sat0p7_INSTRUMENT": (
        "saturate=0.7, INSTRUMENT input gain (hotter pre-stage). Should sound thicker / "
        "more compressed than the LINE version — same drive, more level into the BH curve."
    ),
    "tl_saturate_demo_sat0p7_HIGH_GAIN": (
        "saturate=0.7, HIGH_GAIN input gain. Most aggressive operating point; near "
        "soft-clipping at peaks. Compare to LINE/INSTRUMENT to confirm input_gain is "
        "doing real work."
    ),
    "tl_saturate_demo_sat1p0_LINE": (
        "saturate=1.0, LINE input gain. Full drive. Aliasing should be inaudible "
        "(2× oversampling pushes images below -50 dBFS). If you hear high-pitched whine, "
        "the halfband filter is misbehaving."
    ),
    "tl_saturate_demo_sweep1k": (
        "1 kHz sine sweep at high drive — the aliasing test. Listen for foldback whistles "
        "above the fundamental's harmonics. None should be audible."
    ),

    # tl_model_eq
    "tl_model_eq_input_dry": (
        "Dry probe for the EQ chain — likely pink noise, a chord, or a frequency sweep "
        "to expose spectral character clearly."
    ),
    "tl_model_eq_profile_01_cpr_3300_gen_1": "CPR-3300 Gen 1 — first-generation cassette dub. Mild HF rolloff, slight head-bump in the lows, generally still hi-fi.",
    "tl_model_eq_profile_02_cpr_3300_gen_2": "CPR-3300 Gen 2 — second-generation dub. More HF loss, more low-mid emphasis. Should sound noticeably duller than Gen 1.",
    "tl_model_eq_profile_03_cpr_3300_gen_3": "CPR-3300 Gen 3 — third-generation. Significant bandwidth narrowing, mid-forward, lo-fi territory.",
    "tl_model_eq_profile_04_portamax_rt": "Portamax RT — reel-to-reel character. Wider bandwidth than the cassette gens; subtle head-gap HF rolloff but full lows.",
    "tl_model_eq_profile_05_portamax_ht": "Portamax HT — alternate reel-to-reel head/tape combo. Should sound similar to RT with subtle midrange differences.",
    "tl_model_eq_profile_06_cam_8": "CAM-8 — 8mm camcorder audio. Narrow bandwidth, telephone-like, plenty of mid hump.",
    "tl_model_eq_profile_07_dictatron": "Dictatron — dictaphone. Heavily band-limited (think voicemail). Anything below ~200 Hz and above ~4 kHz should be gone.",
    "tl_model_eq_profile_08_dictatron_mic": "Dictatron MIC — same dictaphone format with a colored built-in mic curve. Slightly thinner than profile 07.",
    "tl_model_eq_profile_09_fishy_60": "FISHY 60 — toy/novelty cassette. <b>Narrow midband peak around 1-2 kHz</b> dominates. Should sound honky and small.",
    "tl_model_eq_profile_10_ms_walker": "MS-Walker — Walkman-style smile EQ (boosted lows + highs, scooped mids). The most consumer-flattering of the 12.",
    "tl_model_eq_profile_11_amu_2": "AMU-2 — AMU-2 deck. <b>Spec calls for ±0.3c pitch drift</b> on this profile (delegated to tl_wow; not heard here). EQ alone should sound mid-forward and slightly muffled.",
    "tl_model_eq_profile_12_m_pex": "M-PEX — premium pro-grade tape. <b>Nearly flat response</b> — should sound closest to dry of the 12 profiles.",

    # tl_failure
    "tl_failure_input_dry": (
        "Dry probe — likely 2-second guitar-like or noise burst input. Reference for "
        "all the failure variants."
    ),
    "tl_failure_demo_0p0": (
        "failure=0.0. <b>Should be near-identical to dry</b> in the reference (crinkle "
        "short-circuited at 0 for hash stability). No drops, no snags. Verifies the round-2 "
        "tuning didn't break passthrough."
    ),
    "tl_failure_demo_0p3": (
        "failure=0.3 (round 2). Now noticeably more present than round 1 — short dropouts every "
        "few seconds, small pitch snags. Should feel like a <b>slightly worn cassette</b>, not "
        "pristine. Crinkle now sits under the dropouts."
    ),
    "tl_failure_demo_0p7" : (
        "failure=0.7 (round 2). <b>Struggling tape</b>: dropouts are deeper (~-12 dB) and longer "
        "(~150 ms typical), pitch snags reach ±60c with longer hold. Crinkle deliberately "
        "suppressed vs round 1. <b>This is the sweet-spot listen</b> — does the failure feel "
        "musical and intentional, or noisy?"
    ),
    "tl_failure_demo_1p0": (
        "failure=1.0 — <b>GO CRAZY</b> (round 2). Drop rate ~26/min × ~250 ms duration → ~10% "
        "silence duty cycle. Pitch snags up to several hundred cents on steep ramps. <b>Expect:</b> "
        "broken silence punctuated by pitch-bent bursts. <b>Concern from agent:</b> watch whether "
        "fast pitch transients feel like glitchy clicks rather than musical bends — flag if they do."
    ),
    "tl_failure_demo_0p7_spread": (
        "failure=0.7 + spread=true. L/R should have <b>independent</b> failure events — pan around "
        "with headphones to verify drops/snags don't align."
    ),
    "tl_failure_demo_0p7_no_drops": (
        "failure=0.7 with drop sub-engine bypassed. <b>No gating-style dropouts</b> — only snags + "
        "(suppressed) crinkle. Isolates snag character. Round-2 snags are more dramatic than round 1."
    ),
    "tl_failure_demo_0p7_no_snags": (
        "failure=0.7 with snag sub-engine bypassed. <b>No pitch jumps</b> — only drops + crinkle. "
        "Isolates drop character. Round-2 drops are deeper and longer."
    ),

    # tl_wow
    "tl_wow_input_dry_tone": (
        "Pure 440 Hz tone — the pitch-drift audibility test. Use this to hear cents-level "
        "pitch wandering clearly."
    ),
    "tl_wow_input_dry_pad": (
        "Sustained 4-note pad — exposes wow as a smear/chorus rather than discrete pitch shifts."
    ),
    "tl_wow_demo_tone_0p0": (
        "wow=0.0 on tone. <b>Bit-identical passthrough</b>. If you hear any pitch wobble, "
        "buffer-init is broken."
    ),
    "tl_wow_demo_tone_0p5": (
        "wow=0.5 on tone (noon). Calibrated to <b>±13.1c</b> peak (target ~15c). Pitch should "
        "drift slowly and aperiodically — never a clean LFO."
    ),
    "tl_wow_demo_tone_1p0": (
        "wow=1.0 on tone (max). Calibrated to <b>±69.8c</b> peak (target ~70c). Heavy slow "
        "pitch drift; should sound like a struggling capstan."
    ),
    "tl_wow_demo_pad_0p0": "wow=0.0 on pad. Passthrough.",
    "tl_wow_demo_pad_0p5": (
        "wow=0.5 on pad. Listen for chorus-like smear from the same pitch drift acting on "
        "harmonically rich material. This is what feeds the spec's 'WOW + DRY UNITY = chorus' "
        "behavior downstream."
    ),
    "tl_wow_demo_pad_1p0": (
        "wow=1.0 on pad. Pronounced phasing/smear. Heavy material may sound unstable."
    ),
    "tl_wow_demo_amu2_floor": (
        "<b>Phase 1.5 cross-module contract demo.</b> wow=0.0, "
        "pitch_floor_cents=0.3 on pad. This is the always-on baseline drift "
        "tl_model_eq's AMU-2 profile (#11) requires; tl_wow honors it via the "
        "new pitch_floor_cents API. A/B against tl_wow_demo_pad_0p0.wav "
        "(true passthrough) to hear the floor drift in isolation — should be "
        "very subtle, ~±0.3 c (median ground-truth peak 0.27 c over 8 seeds), "
        "0.4 Hz LFO. Independent of the main wow LFO (different cutoff, "
        "different RNG sub-stream)."
    ),

    # tl_flutter
    "tl_flutter_input_sine": "440 Hz sine — the pitch-mod audibility test for flutter.",
    "tl_flutter_input_chord": "A2/E3/A3 chord — exposes flutter as texture/instability on harmonic content.",
    "tl_flutter_demo_f0p0": (
        "flutter=0.0 on sine. <b>Bit-identical passthrough</b> (regression-verified post-retune)."
    ),
    "tl_flutter_demo_f0p5": (
        "flutter=0.5 on sine (round 2). New sqrt taper: <b>~20c p99 pitch + ~3.4 dB AM swing</b>. "
        "Should feel obviously fluttery — not subtle. Round 1 was ~6c here; this is the headline change."
    ),
    "tl_flutter_demo_f1p0": (
        "flutter=1.0 on sine (round 2). <b>~28c p99 pitch + ~5 dB peak AM swing</b>. AM is the watch "
        "item — round 1 was ~3 dB; if 5 dB feels too tremolo-y, agent suggests reverting AM max to 0.20 "
        "while keeping the sqrt shape (would give ~2.7 dB at noon, well above the 1 dB floor)."
    ),
    "tl_flutter_demo_f1p0_classic": (
        "flutter=1.0 + classic_mode=true. <b>AM bypassed</b> (agent's interpretation; flagged for review). "
        "Pitch unchanged from demo_f1p0. A/B against demo_f1p0 to isolate the AM contribution — "
        "especially relevant now that AM is heavier in round 2."
    ),
    "tl_flutter_demo_chord_f0p5": (
        "<b>THE round-2 acceptance test.</b> flutter=0.5 on chord — should now <b>clearly flutter</b>. "
        "If this still feels non-existent like round 1 did, the retune didn't land."
    ),
    "tl_flutter_demo_chord_f1p0": (
        "flutter=1.0 on chord. Texture should feel agitated; AM may be more present than you remember "
        "from round 1."
    ),

    # tl_aux
    "tl_aux_input_dry": "Dry probe for AUX. 4 seconds total: 1s dry / 2s effect-on / 1s dry.",
    "tl_aux_demo_stop": (
        "aux_mode=STOP, footswitch press at 1s. <b>Tape-stop deceleration</b>: pitch and amplitude "
        "ramp down via (1-e)^2.5 read-rate × √(1-e) gain. Should sound like releasing a cassette "
        "play button."
    ),
    "tl_aux_demo_filter": (
        "aux_mode=FILTER. <b>TPT-SVF log sweep 18kHz → 200Hz</b>, Q rises 0.707 → 4.0 during the press. "
        "Should sound like a slow auto-wah closing down with subtle resonance build."
    ),
    "tl_aux_demo_fail": (
        "aux_mode=FAIL audio. <b>Should be bit-identical to dry</b> — FAIL is a sidechain control "
        "signal to tl_failure, not local destruction. Listen to demo_fail_ctrl for the actual envelope."
    ),
    "tl_aux_demo_fail_ctrl": (
        "Mono control trace for FAIL mode — the failure_override signal that would feed tl_failure's "
        "new 4th inlet (cross-module contract pending). Should ramp 0 → 1 with onset envelope, hold, "
        "release on footswitch off."
    ),

    # tl_volume_mix
    "tl_volume_mix_input_dry": "Stereo source for the gain/MISO checks below. A/B reference.",
    "tl_volume_mix_unity": (
        "<b>Should sound IDENTICAL to dry.</b> If you can hear ANY difference, that's a bug — "
        "this is the unity-passthrough check."
    ),
    "tl_volume_mix_plus6dB": (
        "<b>Should sound noticeably louder than dry</b> — about doubled in perceived volume "
        "(volume=2.0 = +6 dB). Will clip if your dry is already hot."
    ),
    "tl_volume_mix_miso_stereo": (
        "Stereo dry collapsed to mono. <b>Both ears should now be identical</b>. With headphones, "
        "anything panned hard L or R in the dry should now sit dead-center."
    ),
    "tl_volume_mix_miso_white_noise": (
        "Decorrelated noise mono-summed. <b>Volume should drop ~3 dB</b> vs the dry probe "
        "(mono-summing uncorrelated content loses energy). Subtle but audible on careful A/B."
    ),
    "tl_volume_mix_zipper_test": (
        "Volume ramp 0→1 over 100 ms on a sustained tone. <b>Should sound like a smooth fade-in</b> — "
        "no crunchy/grainy texture on the way up. (That texture is zipper noise; the smoother kills it.)"
    ),
    "tl_volume_mix_miso_toggle_test": (
        "MISO toggled mid-fixture. <b>Stereo collapses to mono mid-buffer with NO click or pop</b> "
        "at the transition. (You confirmed this — smooth.)"
    ),

    # tl_dry_mix
    "tl_dry_mix_input_dry": "Dry probe (the unaffected source — A2/E3/A3 chord).",
    "tl_dry_mix_input_wet": (
        "Wet probe = <b>tl_wow(wow=0.5, seed=42)</b> applied to the dry. This is a real "
        "WOW render, not a stand-in — so dry vs wet is the actual upstream-WOW relationship "
        "the dry-mix is designed to operate on."
    ),
    "tl_dry_mix_NONE": (
        "dry_mode=NONE. <b>Output = wet only</b> (sha matches input_wet — bit-identical). "
        "You hear the WOW-modulated signal alone."
    ),
    "tl_dry_mix_SMALL": (
        "dry_mode=SMALL = <b>-8 dB dry</b> blended into wet (agent diverged from spec's "
        "-12 dB; flagged). Wow dominates with a thin dry tail underneath. Single-constant "
        "override exists for recalibration."
    ),
    "tl_dry_mix_UNITY": (
        "dry_mode=UNITY. Full dry summed with wow-processed wet — this is the spec's "
        "<b>'WOW + DRY UNITY = classic chorus'</b> behavior. Comb-filtering between the "
        "stable dry and the pitch-modulated wet produces the chorus character. WAV peak "
        "happens to land below full-scale on this material so no peak-scaling was needed."
    ),
    "tl_dry_mix_xfade": (
        "10 ms Hann crossfade between modes (NONE → SMALL → UNITY → NONE every 750 ms). "
        "<b>Should be click-free</b> at each mode change. With the new wow-based wet, you "
        "should hear the dry/wet character morphing across the four sections rather than "
        "just brief crossfade artifacts."
    ),

    # tl_noise (additive — no dry input; just listen to each mode)
    "tl_noise_off": "noise_mode=OFF. <b>Bit-exact silence</b>.",
    "tl_noise_hiss_0p5": (
        "noise_mode=HISS, hiss_level=0.5. Pink-noise-flavored tape hiss with HPF50/LPF12k bandshaping "
        "(models cassette head-gap). Should sit around -45 dBFS."
    ),
    "tl_noise_hiss_1p0": (
        "noise_mode=HISS, hiss_level=1.0. Maximum hiss. Still should be audible but not dominant."
    ),
    "tl_noise_both_vcr_0p0": (
        "noise_mode=BOTH, mechanical_level=0.0 (full CCW). <b>VCR motor whir</b>: white noise into "
        "an LPF~200 Hz with slow random-walk AM (0.3-1.5 Hz). Rumbly and irregular. Plus hiss in "
        "the background."
    ),
    "tl_noise_both_vcr_0p2": (
        "noise_mode=BOTH, mechanical_level=0.2. Lighter VCR noise blended with hiss."
    ),
    "tl_noise_both_noon": (
        "noise_mode=BOTH, mechanical_level=0.5. <b>Hard silent center</b> — mechanical sub-engine "
        "should be dead. Hiss only. Verifies the bipolar crossfade's silent point."
    ),
    "tl_noise_both_hum_0p8": (
        "noise_mode=BOTH, mechanical_level=0.8. Lighter mains hum + hiss. 60Hz fundamental + harmonic stack."
    ),
    "tl_noise_both_hum_1p0": (
        "noise_mode=BOTH, mechanical_level=1.0 (full CW). <b>Maximum mains hum</b>: 60Hz + odd "
        "harmonics, half-wave-rectified PSU character. Mono-correlated (real mains pickup is common-mode)."
    ),
    "tl_noise_both_humbyp": (
        "noise_mode=BOTH + hum_bypass=true. <b>Mechanical disabled</b> — should sound like HISS-only "
        "regardless of mechanical_level."
    ),
}


def parse_filename(stem: str) -> dict:
    """Extract module + role + variant from a fixture stem.

    Returns: {"module": str, "role": "input"|"demo"|"profile", "variant": str}
    """
    for module in SIGNAL_CHAIN_ORDER:
        if not stem.startswith(module):
            continue
        rest = stem[len(module):].lstrip("_")
        if rest.startswith("input"):
            role = "input"
        elif rest.startswith("demo"):
            role = "demo"
        elif rest.startswith("profile"):
            role = "profile"
        else:
            role = "demo"  # fallback for tl_noise (no input/demo prefix) and tl_volume_mix variants
        return {"module": module, "role": role, "variant": rest, "stem": stem}
    return {"module": "_unknown", "role": "demo", "variant": stem, "stem": stem}


def collect_fixtures() -> dict:
    """Group fixtures by module, in signal-chain order, with inputs first."""
    if not FIXTURES_DIR.exists():
        raise SystemExit(f"Fixtures dir not found: {FIXTURES_DIR}")
    by_module = {m: {"inputs": [], "outputs": []} for m in SIGNAL_CHAIN_ORDER}
    for path in sorted(FIXTURES_DIR.iterdir()):
        if path.suffix.lower() != ".wav":
            continue
        info = parse_filename(path.stem)
        bucket = by_module.setdefault(info["module"], {"inputs": [], "outputs": []})
        target = "inputs" if info["role"] == "input" else "outputs"
        bucket[target].append({
            "stem": path.stem,
            "path": str(path.relative_to(REPO_ROOT)),
            "bytes": path.stat().st_size,
            "blurb": FIXTURE_BLURBS.get(path.stem, "<i>(blurb missing — add to FIXTURE_BLURBS)</i>"),
        })
    return by_module


def render_html(by_module: dict) -> str:
    parts = []
    parts.append("""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>tape-loss — DSP fixture review</title>
<style>
  :root {
    --bg: #fafaf7;
    --fg: #1a1a1a;
    --muted: #666;
    --accent: #c84a3c;
    --card-bg: #fff;
    --card-border: #e0ddd5;
    --code-bg: #f0ede5;
  }
  * { box-sizing: border-box; }
  body {
    font: 14px/1.5 -apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif;
    background: var(--bg);
    color: var(--fg);
    margin: 0;
    padding: 0;
    display: grid;
    grid-template-columns: 220px 1fr;
    min-height: 100vh;
  }
  nav {
    background: #efece5;
    border-right: 1px solid var(--card-border);
    padding: 24px 16px;
    position: sticky;
    top: 0;
    align-self: start;
    height: 100vh;
    overflow-y: auto;
  }
  nav h1 { font-size: 13px; margin: 0 0 12px; letter-spacing: 0.5px; text-transform: uppercase; color: var(--muted); }
  nav ul { list-style: none; padding: 0; margin: 0; }
  nav li { margin: 4px 0; }
  nav a { color: var(--fg); text-decoration: none; display: block; padding: 4px 8px; border-radius: 4px; }
  nav a:hover { background: var(--card-bg); }
  main { padding: 32px 40px; max-width: 900px; }
  h1.device { font-size: 22px; margin: 0 0 8px; }
  p.subtitle { color: var(--muted); margin: 0 0 32px; }
  section.module { margin-bottom: 48px; padding-bottom: 32px; border-bottom: 1px solid var(--card-border); }
  section.module:last-of-type { border-bottom: none; }
  h2.module-name { font-size: 18px; margin: 0 0 4px; color: var(--accent); font-family: ui-monospace, "SF Mono", monospace; }
  p.module-desc { color: var(--muted); margin: 0 0 20px; line-height: 1.55; }
  .input-group, .output-group { margin: 16px 0; }
  .input-group h3, .output-group h3 {
    font-size: 11px; text-transform: uppercase; letter-spacing: 0.7px; color: var(--muted);
    margin: 0 0 8px;
  }
  .card {
    background: var(--card-bg);
    border: 1px solid var(--card-border);
    border-radius: 6px;
    padding: 12px 14px;
    margin: 6px 0;
    display: grid;
    grid-template-columns: minmax(220px, 1fr) 320px;
    gap: 16px;
    align-items: start;
  }
  .card.input { background: #f6f3eb; }
  .card .stem { font-family: ui-monospace, "SF Mono", monospace; font-size: 12px; color: var(--fg); margin: 0 0 6px; word-break: break-all; }
  .card .blurb { font-size: 13px; line-height: 1.5; color: var(--fg); }
  .card .blurb b { color: var(--accent); font-weight: 600; }
  .card audio { width: 100%; height: 32px; }
  .meta { color: var(--muted); font-size: 11px; margin-top: 4px; }
  details summary { cursor: pointer; color: var(--muted); font-size: 12px; padding: 4px 0; }
  details summary:hover { color: var(--fg); }
</style>
</head>
<body>
<nav>
  <h1>tape-loss</h1>
  <ul>
""")
    for module in SIGNAL_CHAIN_ORDER:
        parts.append(f'    <li><a href="#{module}">{module}</a></li>\n')
    parts.append("""  </ul>
</nav>
<main>
<h1 class="device">tape-loss — DSP fixture review</h1>
<p class="subtitle">9 modules, Phase 1 sanity renders. Click play; A/B against the dry input above each output group. Bold callouts in blurbs are the specific things to listen for.</p>
""")

    for module in SIGNAL_CHAIN_ORDER:
        bucket = by_module.get(module, {"inputs": [], "outputs": []})
        parts.append(f'<section class="module" id="{module}">\n')
        parts.append(f'<h2 class="module-name">{module}</h2>\n')
        parts.append(f'<p class="module-desc">{MODULE_PREAMBLES.get(module, "")}</p>\n')

        if bucket["inputs"]:
            parts.append('<div class="input-group">\n<h3>Dry input(s)</h3>\n')
            for fx in bucket["inputs"]:
                parts.append(_render_card(fx, is_input=True))
            parts.append('</div>\n')

        if bucket["outputs"]:
            parts.append('<div class="output-group">\n<h3>Outputs</h3>\n')
            for fx in bucket["outputs"]:
                parts.append(_render_card(fx, is_input=False))
            parts.append('</div>\n')

        parts.append('</section>\n')

    parts.append("""</main>
</body>
</html>
""")
    return "".join(parts)


def _render_card(fx: dict, is_input: bool) -> str:
    cls = "card input" if is_input else "card"
    rel = "../../" + fx["path"]  # docs/fixtures-viewer/index.html → repo root
    kb = fx["bytes"] // 1024
    return (
        f'<div class="{cls}">\n'
        f'  <div>\n'
        f'    <p class="stem">{html.escape(fx["stem"])}</p>\n'
        f'    <audio controls preload="none" src="{rel}"></audio>\n'
        f'    <div class="meta">{kb} KB</div>\n'
        f'  </div>\n'
        f'  <div class="blurb">{fx["blurb"]}</div>\n'
        f'</div>\n'
    )


def main() -> None:
    by_module = collect_fixtures()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_HTML.write_text(render_html(by_module), encoding="utf-8")

    total = sum(len(b["inputs"]) + len(b["outputs"]) for b in by_module.values())
    missing_blurbs = []
    for bucket in by_module.values():
        for fx in bucket["inputs"] + bucket["outputs"]:
            if fx["stem"] not in FIXTURE_BLURBS:
                missing_blurbs.append(fx["stem"])

    print(f"Wrote {OUT_HTML.relative_to(REPO_ROOT)}")
    print(f"  {total} fixtures across {len(SIGNAL_CHAIN_ORDER)} modules")
    if missing_blurbs:
        print(f"  WARNING: {len(missing_blurbs)} blurbs missing:")
        for stem in missing_blurbs:
            print(f"    - {stem}")
    else:
        print("  All fixtures have blurbs.")
    print()
    print("To view (run from repo root):")
    print("  python3 -m http.server 8000")
    print("  open http://localhost:8000/docs/fixtures-viewer/")


if __name__ == "__main__":
    main()
