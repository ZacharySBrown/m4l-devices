{
	"patcher": {
		"fileversion": 1,
		"appversion": {
			"major": 9,
			"minor": 0,
			"revision": 0,
			"architecture": "x64",
			"modernui": 1
		},
		"classnamespace": "box",
		"rect": [
			100.0,
			100.0,
			500.0,
			400.0
		],
		"openinpresentation": 1,
		"default_fontsize": 12.0,
		"default_fontface": 0,
		"default_fontname": "Arial",
		"gridonopen": 1,
		"gridsize": [
			15.0,
			15.0
		],
		"gridsnaponopen": 1,
		"objectsnaponopen": 1,
		"statusbarvisible": 2,
		"toolbarvisible": 1,
		"lefttoolbarpinned": 0,
		"toptoolbarpinned": 0,
		"righttoolbarpinned": 0,
		"bottomtoolbarpinned": 0,
		"toolbars_unpinned_last_save": 0,
		"tallnewobj": 0,
		"boxanimatetime": 200,
		"enablehscroll": 1,
		"enablevscroll": 1,
		"devicewidth": 400.0,
		"description": "",
		"digest": "",
		"tags": "",
		"style": "",
		"subpatcher_template": "",
		"assistshowspatchername": 0,
		"boxes": [
			{
				"box": {
					"id": "tl_failure-in-L",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						40,
						20,
						30,
						30
					],
					"outlettype": [
						"signal"
					],
					"comment": "",
					"index": 1
				}
			},
			{
				"box": {
					"id": "tl_failure-in-R",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						90,
						20,
						30,
						30
					],
					"outlettype": [
						"signal"
					],
					"comment": "",
					"index": 2
				}
			},
			{
				"box": {
					"id": "tl_failure-pin-0",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						140,
						20,
						30,
						30
					],
					"outlettype": [
						""
					],
					"comment": "",
					"index": 3
				}
			},
			{
				"box": {
					"id": "tl_failure-pin-1",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						190,
						20,
						30,
						30
					],
					"outlettype": [
						""
					],
					"comment": "",
					"index": 4
				}
			},
			{
				"box": {
					"id": "tl_failure-pin-2",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						240,
						20,
						30,
						30
					],
					"outlettype": [
						""
					],
					"comment": "",
					"index": 5
				}
			},
			{
				"box": {
					"id": "tl_failure-pin-3",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						290,
						20,
						30,
						30
					],
					"outlettype": [
						""
					],
					"comment": "",
					"index": 6
				}
			},
			{
				"box": {
					"id": "tl_failure-pin-4",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						340,
						20,
						30,
						30
					],
					"outlettype": [
						""
					],
					"comment": "",
					"index": 7
				}
			},
			{
				"box": {
					"id": "tl_failure-out-L",
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						260,
						30,
						30
					],
					"comment": "",
					"index": 1
				}
			},
			{
				"box": {
					"id": "tl_failure-out-R",
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						90,
						260,
						30,
						30
					],
					"comment": "",
					"index": 2
				}
			},
			{
				"box": {
					"id": "tl_failure-in-fov",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						440,
						20,
						30,
						30
					],
					"outlettype": [
						"signal"
					],
					"comment": "",
					"index": 8
				}
			},
			{
				"box": {
					"id": "tl_failure-gen",
					"maxclass": "newobj",
					"numinlets": 4,
					"numoutlets": 2,
					"patching_rect": [
						40,
						100,
						250,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "gen~ @title tl_failure_dsp",
					"patcher": {
						"fileversion": 1,
						"appversion": {
							"major": 9,
							"minor": 0,
							"revision": 0,
							"architecture": "x64",
							"modernui": 1
						},
						"classnamespace": "dsp.gen",
						"rect": [
							100.0,
							100.0,
							700.0,
							600.0
						],
						"boxes": [
							{
								"box": {
									"id": "tl_failure-gen-in1",
									"maxclass": "newobj",
									"text": "in 1",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										30.0,
										30.0,
										30.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "tl_failure-gen-in2",
									"maxclass": "newobj",
									"text": "in 2",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										100.0,
										30.0,
										30.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "tl_failure-gen-in3",
									"maxclass": "newobj",
									"text": "in 3",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										170.0,
										30.0,
										30.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "tl_failure-gen-in4",
									"maxclass": "newobj",
									"text": "in 4",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										240.0,
										30.0,
										30.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "tl_failure-gen-codebox",
									"maxclass": "codebox",
									"numinlets": 4,
									"numoutlets": 2,
									"outlettype": [
										"",
										""
									],
									"patching_rect": [
										50.0,
										100.0,
										600.0,
										400.0
									],
									"code": "// =============================================================================\n// tl_failure.gendsp \u2014 gen~ DSL for the tape-loss FAILURE multi-engine\n// =============================================================================\n//\n//   Module name        : tl_failure\n//   TUNING_VERSION     : 2  (round-2 calibration, 2026-04-26)\n//   Phase 1.5 contract : IMPLEMENTED (failure_override 4th inlet, additive\n//                        toward max \u2014 effective = knob + override*(1-knob))\n//   Authored           : 2026-04-27 by pedal-engineer (translation only)\n//\n//   Source design doc  : docs/design-docs/dsp/tl-failure-design.md\n//   Source design sha  : b6eb137b62aac6f4b058c910b69ae3c6fcfa17fc2f86cba5bf8a366a353c1ab5\n//   Source numpy ref   : dsp/reference/tl_failure.py\n//   Source numpy sha   : d82bce577a26ee3a1faa4691b9f98913eb2ffed574344aea9ef194dd43b21f76\n//\n// -----------------------------------------------------------------------------\n// I/O contract (matches tl_failure.maxpat shell, post Phase 1.5):\n//\n//   in1 = signal L                     (audio rate)\n//   in2 = signal R                     (audio rate)\n//   in3 = failure_knob       [0, 1]    (control rate; held by [sig~] upstream)\n//   in4 = failure_override   [0, 1]    (control rate; from tl_aux FAIL outlet,\n//                                       defaulted to 0 when unwired)\n//   out1 = signal L                    (audio rate)\n//   out2 = signal R                    (audio rate)\n//\n// Params (set from outer patch via [param ...] or live.* boxes):\n//   drop_bypass     0|1     \u2014 disable DROP sub-engine (round-2 unchanged)\n//   snag_bypass     0|1     \u2014 disable SNAG sub-engine\n//   spread          0|1     \u2014 stereo decorrelation; 0 = locked events L/R\n//   crinkle_level   0..1    \u2014 UI knob, post-engine amp scale on CRINKLE\n//\n// -----------------------------------------------------------------------------\n// Round-2 calibration constants (must match numpy reference verbatim):\n//\n//   DROP rate     = 8*f + 18*f^2  events/min\n//   DROP duration = (30 + 220*f) ms   * uniform(0.7, 1.3) jitter\n//   DROP ramp     = 5 ms cosine each side, hold at 0 between\n//\n//   SNAG rate     = 4*f + 10*f^2  events/min\n//   SNAG cents    = (60 + 240*f)  * uniform(0.8, 1.2)\n//   SNAG hold     = uniform(15, 80) ms\n//   SNAG attack   = 4 ms cosine\n//   SNAG release  = 25 ms cosine\n//   SNAG scale    = 0.012  (delay-line excursion: peak = (cents/1200)*sr*0.012)\n//\n//   CRINKLE rate  = 30*f^3 + 1   bursts/sec\n//   CRINKLE amp   = uniform(0.2, 0.5) per event\n//   CRINKLE BPF   = RBJ constant-skirt, fc=2500 Hz, Q=1.5 (DF-I biquad)\n//   CRINKLE peak  = post-norm * 0.30 * crinkle_level   (round-2 headroom 0.30)\n//\n//   MICRO-FLUTTER depth = 0.35 * f      (linear)\n//   MICRO-FLUTTER rate  = uniform(20, 60+60*f) Hz, two summed sines, re-rolled\n//                         every 50 ms.\n//\n// -----------------------------------------------------------------------------\n// Per-sample event-scheduling translation pattern:\n//\n// The numpy reference uses NumPy-array idioms \u2014 Poisson sample at the buffer\n// level, draw all event start positions in one shot, write envelope shapes via\n// vectorized slice assignment. gen~ is sample-rate; there is no buffer-level\n// scheduling and no Poisson primitive. We translate to the canonical\n// streaming-Poisson pattern (memoryless inter-arrival times):\n//\n//   For a Poisson process with rate \u03bb events/second, inter-arrival times are\n//   exponentially distributed with mean 1/\u03bb. Sample u ~ Uniform(0,1) and\n//   compute \u0394t = -ln(u) / \u03bb samples. Maintain a per-engine countdown History;\n//   each sample, decrement; when it crosses zero, fire an event (sample its\n//   per-event params via more random() calls), reset countdown to next \u0394t.\n//\n// Per-event envelope state is a small piecewise machine, also held in\n// History: { phase \u2208 {idle, attack, hold, release}, samples_left_in_phase,\n// event_amp, event_peak_offset }. Each sample, advance the phase.\n//\n// Why this matches the numpy ref distribution-wise:\n//   For a homogeneous Poisson process, the count over a fixed interval is\n//   Poisson-distributed (numpy uses the latter form), AND the inter-arrival\n//   times are i.i.d. exponential (we use this form). They are equivalent\n//   characterizations \u2014 same statistics, same expected rate. The actual\n//   sample-level event positions will differ from numpy under the same RNG\n//   seed, which is FINE: the design contract is statistical, not bit-identical\n//   (only the failure=0 short-circuit needs bit-identical match, and we\n//   handle that separately).\n//\n// SPREAD / RNG strategy:\n//   gen~ has no SeedSequence.spawn analog. gen~'s `noise()` and `random()`\n//   each maintain independent state per *call site*. To get decorrelated L\n//   and R streams when spread=1, every random draw is duplicated \u2014 once for\n//   the L sub-engine (subscript _L), once for R (_R). When spread=0, both\n//   channels use the *same* draw stream by reading a single set of countdown\n//   states and broadcasting to both channels (events lock in stereo).\n//\n//   At this level of abstraction in gen~ DSL, we cannot programmatically\n//   \"fork\" RNG state, so the architectural choice is: structurally separate\n//   L and R event-scheduling state machines. Under spread=1 they evolve\n//   independently (independent random() calls). Under spread=0 we still\n//   evaluate both, but route the L sub-engine state to both output channels,\n//   ignoring R's modulators. This costs ~2x scheduling CPU but keeps the\n//   topology static (gen~ requires DSP graph topology to be compile-time).\n//\n//   Note vs. numpy ref: numpy's spread=False explicitly re-seeds rng_l and\n//   rng_r with the same SeedSequence so the streams are bit-identical; gen~\n//   has no such hook. The audible result is the same \u2014 locked stereo events\n//   \u2014 because we route a single channel's modulators to both outputs.\n//\n// Numpy idioms that did NOT translate cleanly (workarounds):\n//\n//   1. `rng.poisson(mean_events)` over a buffer: replaced with streaming\n//      exponential inter-arrival (see above).\n//   2. `np.maximum(env, ramp)` (slice-wise OR-of-envelopes for overlapping\n//      bursts): replaced with `max(env_state, current_envelope_value)` per\n//      sample \u2014 same overlap-takes-louder semantics, sample-by-sample.\n//   3. `np.linspace(0, 1, a_n)` for triangular CRINKLE ramp: replaced with\n//      sample-counter / a_n linear interpolation in the envelope state\n//      machine.\n//   4. `_apply_variable_delay` reading by index with linear interp at\n//      arbitrary fractional offsets: replaced with gen~'s `Delay` operator,\n//      which accepts fractional delay-time and does linear interp natively\n//      (matches numpy ref's `linterp`; the M4L `tapout~` would do 4-point\n//      Hermite for slightly cleaner artifacts \u2014 design doc tradeoff #11\n//      already accepts this).\n//   5. `SeedSequence.spawn(2)` for SPREAD: see above; replaced with\n//      structural per-channel state.\n//   6. `chunk_n = max(64, int(0.05*sr))` re-roll-LFO-rates-every-50ms\n//      pattern in MICRO-FLUTTER: implemented as a 50 ms countdown that, on\n//      tick, samples two new `random()` rate values into History; each\n//      sample advances the two phasors with their current rates.\n//   7. Per-sample biquad with denormal flush (`if abs(yn) < 1e-30 \u2192 0`):\n//      gen~ has no explicit denormal-flush primitive needed \u2014 gen~ runs in\n//      double precision and most modern CPUs handle denormals adequately;\n//      we still include a guard `(abs(y) < 1e-30) ? 0 : y` to match the\n//      reference's numerical behavior.\n//\n// -----------------------------------------------------------------------------\n// Sanity-check expected behaviors (from numpy verification log\n// `_verify_round2_targets` / `_verify_phase15_contract`):\n//\n//   T1/P1: knob=0 AND override=0  \u2192 out1==in1, out2==in2 bit-identical\n//          (short-circuit at API boundary; engines do not run).\n//   T2:    effective=1.0          \u2192 peak dropout depth \u2264 -30 dBFS in any\n//          30 ms window (gate fully closes; numpy measured -240 dB).\n//   T3:    effective=1.0          \u2192 peak instantaneous pitch deviation \u2265 80\n//          cents (numpy measured 271.5 c, saturation of the tracker).\n//   T4:    effective=0.5          \u2192 simultaneous drop \u2264 -12 dB AND pitch\n//          peak \u2265 30 c in a 15 s render.\n//   P2:    knob=0.3, override=0.5 \u2192 identical statistical behavior to\n//          knob=0.65, override=0   (effective formula: 0.3+0.5*0.7 = 0.65)\n//   P3:    knob=0.0, override=1.0 \u2192 identical statistical behavior to\n//          knob=1.0, override=0    (effective formula: 0.0+1.0*1.0 = 1.0)\n//\n// =============================================================================\n\n\n// -----------------------------------------------------------------------------\n// Params (set from the parent patcher via [param NAME] boxes; gen~ surfaces\n// them as inlets in compiled @param mode but here they are control values\n// stable across the buffer)\n// -----------------------------------------------------------------------------\nParam drop_bypass(0);\nParam snag_bypass(0);\nParam spread(0);\nParam crinkle_level(0.5);\nHistory snag_countdown_L(0);\nHistory snag_phase_L(0);\nHistory snag_phase_left_L(0);\nHistory snag_hold_n_L(0);\nHistory snag_peak_off_L(0);\nHistory snag_countdown_R(0);\nHistory snag_phase_R(0);\nHistory snag_phase_left_R(0);\nHistory snag_hold_n_R(0);\nHistory snag_peak_off_R(0);\nHistory flut_chunk_left_L(0);\nHistory flut_f1_L(30);\nHistory flut_f2_L(20);\nHistory flut_phase1_L(0);\nHistory flut_phase2_L(0);\nHistory flut_chunk_left_R(0);\nHistory flut_f1_R(30);\nHistory flut_f2_R(20);\nHistory flut_phase1_R(0);\nHistory flut_phase2_R(0);\nHistory drop_countdown_L(0);\nHistory drop_phase_L(0);\nHistory drop_phase_left_L(0);\nHistory drop_hold_n_L(0);\nHistory drop_countdown_R(0);\nHistory drop_phase_R(0);\nHistory drop_phase_left_R(0);\nHistory drop_hold_n_R(0);\nHistory crinkle_countdown_L(0);\nHistory crinkle_env_L(0);\nHistory crinkle_env_phase_L(0);     // 0=idle, 1=attack, 2=release\nHistory crinkle_env_left_L(0);\nHistory crinkle_amp_L(0);\nHistory crinkle_a_n_L(0);\nHistory crinkle_r_n_L(0);\nHistory crinkle_countdown_R(0);\nHistory crinkle_env_R(0);\nHistory crinkle_env_phase_R(0);\nHistory crinkle_env_left_R(0);\nHistory crinkle_amp_R(0);\nHistory crinkle_a_n_R(0);\nHistory crinkle_r_n_R(0);\nHistory bpf_x1_L(0); History bpf_x2_L(0);\nHistory bpf_y1_L(0); History bpf_y2_L(0);\nHistory bpf_x1_R(0); History bpf_x2_R(0);\nHistory bpf_y1_R(0); History bpf_y2_R(0);\n\n\n\n// -----------------------------------------------------------------------------\n// API boundary \u2014 Phase 1.5 boost formula: effective = knob + override*(1-knob)\n// Computed once per sample at the input. All four sub-engines downstream read\n// `effective`, never `knob` directly. Original `knob` value is preserved\n// for traceability but no DSP path consumes it.\n// -----------------------------------------------------------------------------\nknob     = clip(in3, 0, 1);\noverride = clip(in4, 0, 1);\neffective = clip(knob + override * (1 - knob), 0, 1);\n\n// Short-circuit: when both are exactly zero, bypass everything (regression\n// guarantee from T1/P1). Use small epsilon to handle float fuzz from the\n// upstream [sig~]; same threshold as design doc \u00a711.4.\nshort_circuit = (effective <= 1e-6);\n\n\n// =============================================================================\n// SUB-ENGINE B \u2014 SNAG (variable delay; pitch-up via shorter delay)\n// =============================================================================\n//\n// Per-sample state machine, one instance per channel:\n//\n//   phase \u2208 { 0 = idle (countdown to next event),\n//             1 = attack  (offset ramps 0 \u2192 -peak over 4 ms cosine),\n//             2 = hold    (offset = -peak for hold_n samples),\n//             3 = release (offset ramps -peak \u2192 0 over 25 ms cosine) }\n//\n// History fields per channel:\n//   snag_countdown_X     samples until next event start (idle phase)\n//   snag_phase_X         current phase 0..3\n//   snag_phase_left_X    samples left in current phase\n//   snag_attack_n_X      attack length in samples (event-specific; though\n//                        we use fixed 4 ms here, kept as History for\n//                        future-proofing and ramp normalization)\n//   snag_release_n_X     release length in samples (fixed 25 ms)\n//   snag_hold_n_X        hold length in samples (event-specific, 15-80 ms)\n//   snag_peak_off_X      peak offset in samples (event-specific)\n//\n// Output: snag_offset_X \u2014 instantaneous delay-line offset (in samples,\n// negative = shorter delay = higher pitch).\n// -----------------------------------------------------------------------------\n\n// Constants (round-2)\nSNAG_RATE_K1 = 4;        // f^1 coefficient,  events/min\nSNAG_RATE_K2 = 10;       // f^2 coefficient,  events/min\nSNAG_CENTS_BASE = 60;\nSNAG_CENTS_F = 240;\nSNAG_HOLD_LO_MS = 15;\nSNAG_HOLD_HI_MS = 80;\nSNAG_ATTACK_MS = 4;\nSNAG_RELEASE_MS = 25;\nSNAG_DELAY_SCALE = 0.012;     // round-2 (was 0.005)\n\n// Snag rate as inter-arrival mean (samples). Guard against rate=0.\n// rate_per_sec = (SNAG_RATE_K1*f + SNAG_RATE_K2*f^2) / 60.\nsnag_rate_per_sec = (SNAG_RATE_K1 * effective + SNAG_RATE_K2 * effective * effective) / 60;\nsnag_lambda_safe = max(snag_rate_per_sec, 1e-9);\nsnag_mean_dt_samp = samplerate / snag_lambda_safe;     // mean inter-arrival in samples\n\nattack_n  = max(1, SNAG_ATTACK_MS  * 1e-3 * samplerate);\nrelease_n = max(1, SNAG_RELEASE_MS * 1e-3 * samplerate);\n\n\n// ---- Macro-style: per-channel snag scheduler ----\n// gen~ has no functions in the strict sense; we inline the L and R copies.\n// Both copies are structurally identical; under spread=0 we will route only\n// the L copy's offset to both channels at the routing stage below.\n\n// =========================\n// Snag scheduler \u2014 channel L\n// =========================\n\n// Tick: when phase==0 (idle), decrement countdown; on hit, sample new event.\n// random() returns [0, 1). Use -ln(1-u)/lambda for stable inverse CDF (avoids\n// log(0) when u==0); equivalently sample u_safe = max(u, 1e-12) and use -ln(u).\nu_dt_L = max(((noise() + 1.0) * 0.5), 1e-12);\n\n// Compute \"next inter-arrival\" (in samples) from current effective rate.\nnew_dt_L = -log(u_dt_L) * snag_mean_dt_samp;\n\n// Per-event params (sampled at event-fire time):\nu_cents_L = ((noise() + 1.0) * 0.5);   // 0..1 \u2192 uniform(0.8, 1.2) below\nu_hold_L  = ((noise() + 1.0) * 0.5);   // 0..1 \u2192 uniform(15, 80) ms\nevent_cents_L = (SNAG_CENTS_BASE + SNAG_CENTS_F * effective) * (0.8 + 0.4 * u_cents_L);\nevent_hold_n_L = max(1, (SNAG_HOLD_LO_MS + (SNAG_HOLD_HI_MS - SNAG_HOLD_LO_MS) * u_hold_L) * 1e-3 * samplerate);\nevent_peak_off_L = (event_cents_L / 1200) * samplerate * SNAG_DELAY_SCALE;\n\n// State transitions:\n//   if phase==0 (idle):\n//       countdown -= 1\n//       if countdown <= 0 and snag engine active: enter attack phase\n//   elif phase==1 (attack): tick ramp; on done \u2192 phase=2, phase_left=hold_n\n//   elif phase==2 (hold):   tick;       on done \u2192 phase=3, phase_left=release_n\n//   elif phase==3 (release): tick;      on done \u2192 phase=0, countdown=new_dt\n//\n// snag_active = (effective > 0) AND (snag_bypass == 0). When snag is bypassed\n// or effective is zero, we leave offset = 0 unconditionally (set later in the\n// short-circuit / bypass mask).\n\nsnag_engine_on_L = (effective > 0) * (1 - drop_bypass * 0);  // engine on flag,\n// note: drop_bypass does NOT gate snag; only snag_bypass gates snag.\nsnag_engine_on_L = (effective > 0) * (1 - snag_bypass);\n\n// State machine \u2014 implemented with selectors on previous History values.\nprev_phase_L      = snag_phase_L;\nprev_countdown_L  = snag_countdown_L;\nprev_phase_left_L = snag_phase_left_L;\nprev_hold_n_L     = snag_hold_n_L;\nprev_peak_off_L   = snag_peak_off_L;\n\n// ---- Idle path (phase==0)\nidle_decremented_L = prev_countdown_L - 1;\nidle_fires_L       = (prev_phase_L == 0) * (idle_decremented_L <= 0) * snag_engine_on_L;\n\n// On idle-fire: enter attack with newly drawn event params.\n// On non-fire idle: stay phase 0, decrement countdown.\n// On already-firing-or-resetting (when engine just turned off mid-event):\n//   we don't force-stop a mid-event; ramp it to natural release end. (matches\n//   numpy ref behavior \u2014 events drawn within the buffer always complete.)\n\n// ---- Attack path (phase==1)\nattack_left_L      = prev_phase_left_L - 1;\nattack_done_L      = (prev_phase_L == 1) * (attack_left_L <= 0);\n\n// ---- Hold path (phase==2)\nhold_left_L        = prev_phase_left_L - 1;\nhold_done_L        = (prev_phase_L == 2) * (hold_left_L <= 0);\n\n// ---- Release path (phase==3)\nrelease_left_L     = prev_phase_left_L - 1;\nrelease_done_L     = (prev_phase_L == 3) * (release_left_L <= 0);\n\n// Compose next state. Order of conditions: most-recent-phase-end first.\n// Default = continue current phase.\nnext_phase_L = prev_phase_L;\nnext_phase_left_L = prev_phase_left_L;\nnext_countdown_L = prev_countdown_L;\nnext_hold_n_L = prev_hold_n_L;\nnext_peak_off_L = prev_peak_off_L;\n\n// Idle, no fire: just decrement countdown.\nnext_countdown_L = (prev_phase_L == 0) ? idle_decremented_L : next_countdown_L;\n\n// Idle, fire: jump to attack.\nnext_phase_L      = idle_fires_L ? 1 : next_phase_L;\nnext_phase_left_L = idle_fires_L ? attack_n : next_phase_left_L;\nnext_hold_n_L     = idle_fires_L ? event_hold_n_L : next_hold_n_L;\nnext_peak_off_L   = idle_fires_L ? event_peak_off_L : next_peak_off_L;\n\n// Attack continuing: decrement phase_left.\nnext_phase_left_L = ((prev_phase_L == 1) * (attack_done_L == 0)) ? attack_left_L : next_phase_left_L;\n// Attack done: enter hold.\nnext_phase_L      = attack_done_L ? 2 : next_phase_L;\nnext_phase_left_L = attack_done_L ? prev_hold_n_L : next_phase_left_L;\n\n// Hold continuing.\nnext_phase_left_L = ((prev_phase_L == 2) * (hold_done_L == 0)) ? hold_left_L : next_phase_left_L;\n// Hold done: enter release.\nnext_phase_L      = hold_done_L ? 3 : next_phase_L;\nnext_phase_left_L = hold_done_L ? release_n : next_phase_left_L;\n\n// Release continuing.\nnext_phase_left_L = ((prev_phase_L == 3) * (release_done_L == 0)) ? release_left_L : next_phase_left_L;\n// Release done: back to idle, schedule next event.\nnext_phase_L      = release_done_L ? 0 : next_phase_L;\nnext_countdown_L  = release_done_L ? new_dt_L : next_countdown_L;\nnext_phase_left_L = release_done_L ? 0 : next_phase_left_L;\n\n// On engine cold-start (countdown==0 from initial History default), seed the\n// first inter-arrival.\ncold_start_L = (prev_phase_L == 0) * (prev_countdown_L == 0) * snag_engine_on_L;\nnext_countdown_L = cold_start_L ? new_dt_L : next_countdown_L;\n\n// Latch.\nsnag_countdown_L  = next_countdown_L;\nsnag_phase_L      = next_phase_L;\nsnag_phase_left_L = next_phase_left_L;\nsnag_hold_n_L     = next_hold_n_L;\nsnag_peak_off_L   = next_peak_off_L;\n\n// Compute current offset based on phase. Cosine ramps to match numpy\n// `0.5*(1 - cos(pi*i/n))` (attack) and `0.5*(1 + cos(pi*i/n))` (release).\n// In our state machine, phase_left counts DOWN from {attack_n, hold_n,\n// release_n} \u2192 0. Map back to ramp index:\n//   attack:  i  = attack_n - phase_left      \u2192 ramp 0..1\n//   release: i  = release_n - phase_left     \u2192 ramp 1..0\nattack_idx_L  = attack_n  - next_phase_left_L;\nrelease_idx_L = release_n - next_phase_left_L;\nattack_ramp_L  = 0.5 * (1 - cos(pi * attack_idx_L  / max(1, attack_n)));\nrelease_ramp_L = 0.5 * (1 + cos(pi * release_idx_L / max(1, release_n)));\n\nsnag_offset_L =\n    (next_phase_L == 1) ? -next_peak_off_L * attack_ramp_L  :\n    (next_phase_L == 2) ? -next_peak_off_L                  :\n    (next_phase_L == 3) ? -next_peak_off_L * release_ramp_L :\n    0;\n\n// Bypass / short-circuit guard.\nsnag_offset_L = (snag_bypass + short_circuit > 0) ? 0 : snag_offset_L;\n\n\n// =========================\n// Snag scheduler \u2014 channel R\n// =========================\n// Structurally identical to L, with independent random() call sites and\n// History instances. Under spread=0, the routing stage below ignores\n// snag_offset_R and broadcasts snag_offset_L to both delay reads.\n\n\nu_dt_R = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_dt_R = -log(u_dt_R) * snag_mean_dt_samp;\nu_cents_R = ((noise() + 1.0) * 0.5);\nu_hold_R = ((noise() + 1.0) * 0.5);\nevent_cents_R = (SNAG_CENTS_BASE + SNAG_CENTS_F * effective) * (0.8 + 0.4 * u_cents_R);\nevent_hold_n_R = max(1, (SNAG_HOLD_LO_MS + (SNAG_HOLD_HI_MS - SNAG_HOLD_LO_MS) * u_hold_R) * 1e-3 * samplerate);\nevent_peak_off_R = (event_cents_R / 1200) * samplerate * SNAG_DELAY_SCALE;\n\nsnag_engine_on_R = (effective > 0) * (1 - snag_bypass);\n\nprev_phase_R      = snag_phase_R;\nprev_countdown_R  = snag_countdown_R;\nprev_phase_left_R = snag_phase_left_R;\nprev_hold_n_R     = snag_hold_n_R;\nprev_peak_off_R   = snag_peak_off_R;\n\nidle_decremented_R = prev_countdown_R - 1;\nidle_fires_R       = (prev_phase_R == 0) * (idle_decremented_R <= 0) * snag_engine_on_R;\nattack_left_R      = prev_phase_left_R - 1;\nattack_done_R      = (prev_phase_R == 1) * (attack_left_R <= 0);\nhold_left_R        = prev_phase_left_R - 1;\nhold_done_R        = (prev_phase_R == 2) * (hold_left_R <= 0);\nrelease_left_R     = prev_phase_left_R - 1;\nrelease_done_R     = (prev_phase_R == 3) * (release_left_R <= 0);\n\nnext_phase_R      = prev_phase_R;\nnext_phase_left_R = prev_phase_left_R;\nnext_countdown_R  = prev_countdown_R;\nnext_hold_n_R     = prev_hold_n_R;\nnext_peak_off_R   = prev_peak_off_R;\n\nnext_countdown_R  = (prev_phase_R == 0) ? idle_decremented_R : next_countdown_R;\nnext_phase_R      = idle_fires_R ? 1 : next_phase_R;\nnext_phase_left_R = idle_fires_R ? attack_n : next_phase_left_R;\nnext_hold_n_R     = idle_fires_R ? event_hold_n_R : next_hold_n_R;\nnext_peak_off_R   = idle_fires_R ? event_peak_off_R : next_peak_off_R;\n\nnext_phase_left_R = ((prev_phase_R == 1) * (attack_done_R == 0)) ? attack_left_R : next_phase_left_R;\nnext_phase_R      = attack_done_R ? 2 : next_phase_R;\nnext_phase_left_R = attack_done_R ? prev_hold_n_R : next_phase_left_R;\n\nnext_phase_left_R = ((prev_phase_R == 2) * (hold_done_R == 0)) ? hold_left_R : next_phase_left_R;\nnext_phase_R      = hold_done_R ? 3 : next_phase_R;\nnext_phase_left_R = hold_done_R ? release_n : next_phase_left_R;\n\nnext_phase_left_R = ((prev_phase_R == 3) * (release_done_R == 0)) ? release_left_R : next_phase_left_R;\nnext_phase_R      = release_done_R ? 0 : next_phase_R;\nnext_countdown_R  = release_done_R ? new_dt_R : next_countdown_R;\nnext_phase_left_R = release_done_R ? 0 : next_phase_left_R;\n\ncold_start_R = (prev_phase_R == 0) * (prev_countdown_R == 0) * snag_engine_on_R;\nnext_countdown_R = cold_start_R ? new_dt_R : next_countdown_R;\n\nsnag_countdown_R  = next_countdown_R;\nsnag_phase_R      = next_phase_R;\nsnag_phase_left_R = next_phase_left_R;\nsnag_hold_n_R     = next_hold_n_R;\nsnag_peak_off_R   = next_peak_off_R;\n\nattack_idx_R  = attack_n  - next_phase_left_R;\nrelease_idx_R = release_n - next_phase_left_R;\nattack_ramp_R  = 0.5 * (1 - cos(pi * attack_idx_R  / max(1, attack_n)));\nrelease_ramp_R = 0.5 * (1 + cos(pi * release_idx_R / max(1, release_n)));\n\nsnag_offset_R =\n    (next_phase_R == 1) ? -next_peak_off_R * attack_ramp_R  :\n    (next_phase_R == 2) ? -next_peak_off_R                  :\n    (next_phase_R == 3) ? -next_peak_off_R * release_ramp_R :\n    0;\n\nsnag_offset_R = (snag_bypass + short_circuit > 0) ? 0 : snag_offset_R;\n\n\n// -----------------------------------------------------------------------------\n// SNAG variable-delay read.\n// Numpy ref uses base_delay=256 samples + linear interpolation. gen~'s Delay\n// operator performs linear interpolation natively when given a fractional\n// delay-time argument. base_delay = 256 samples.\n// -----------------------------------------------------------------------------\nSNAG_BASE_DELAY = 256;\n\n// Routing: under spread=0, both channels read with the L offset; under\n// spread=1, each channel uses its own.\nsnag_off_for_L = snag_offset_L;\nsnag_off_for_R = (spread > 0) ? snag_offset_R : snag_offset_L;\n\n// delay time = base + (-offset). offset is already negative in our encoding\n// (negative offset = shorter delay = higher pitch), so the read time is\n// base + offset where offset \u2264 0. Equivalently base - |offset|. Clamp the\n// minimum delay-time to 0.5 sample for safety (avoid reading future samples).\nsnag_dt_L = max(0.5, SNAG_BASE_DELAY + snag_off_for_L);\nsnag_dt_R = max(0.5, SNAG_BASE_DELAY + snag_off_for_R);\n\n// Delay max = 512 samples (twice base_delay; gives headroom past round-2's\n// ~159-sample peak excursion at f=1.0, per design doc \u00a75).\nsnag_out_L = delay(in1, snag_dt_L, 512);\nsnag_out_R = delay(in2, snag_dt_R, 512);\n\n\n// =============================================================================\n// SUB-ENGINE C2 \u2014 MICRO-FLUTTER (always-on AM, scales with effective)\n// =============================================================================\n//\n// Two summed sines with rates re-rolled every 50 ms. Phase accumulators in\n// History; rate values latched in History at each 50 ms tick. Output:\n//     mod_X = 1 + depth * 0.5 * (sin(phase1_X) + sin(phase2_X))\n// -----------------------------------------------------------------------------\n\nflut_depth = 0.35 * effective;\nflut_chunk_n = max(64, 0.05 * samplerate);   // 50 ms\n\n// ---- L ----\n\n// Re-roll rates when chunk countdown hits 0. f1 \u2208 uniform(20, 60+60*f),\n// f2 = uniform(20, 60+60*f) * 0.7  (matching numpy ref decorrelation factor).\nflut_chunk_dec_L = flut_chunk_left_L - 1;\nflut_reroll_L = flut_chunk_dec_L <= 0;\nu_f1_L = ((noise() + 1.0) * 0.5);\nu_f2_L = ((noise() + 1.0) * 0.5);\nnew_f1_L = 20 + (40 + 60 * effective) * u_f1_L;\nnew_f2_L = (20 + (40 + 60 * effective) * u_f2_L) * 0.7;\n\nflut_f1_L = flut_reroll_L ? new_f1_L : flut_f1_L;\nflut_f2_L = flut_reroll_L ? new_f2_L : flut_f2_L;\nflut_chunk_left_L = flut_reroll_L ? flut_chunk_n : flut_chunk_dec_L;\n\nflut_phase1_L = flut_phase1_L + 2 * pi * flut_f1_L / samplerate;\nflut_phase2_L = flut_phase2_L + 2 * pi * flut_f2_L / samplerate;\n// Wrap phases to keep numerical precision over long runs.\nflut_phase1_L = flut_phase1_L - (flut_phase1_L > 2*pi) * 2 * pi;\nflut_phase2_L = flut_phase2_L - (flut_phase2_L > 2*pi) * 2 * pi;\n\nflut_mod_L_raw = 0.5 * (sin(flut_phase1_L) + sin(flut_phase2_L));\nflut_mod_L = 1 + flut_depth * flut_mod_L_raw;\n// When effective==0 (depth=0), this naturally collapses to 1.0 (no AM).\n\n// ---- R ----\n\nflut_chunk_dec_R = flut_chunk_left_R - 1;\nflut_reroll_R = flut_chunk_dec_R <= 0;\nu_f1_R = ((noise() + 1.0) * 0.5);\nu_f2_R = ((noise() + 1.0) * 0.5);\nnew_f1_R = 20 + (40 + 60 * effective) * u_f1_R;\nnew_f2_R = (20 + (40 + 60 * effective) * u_f2_R) * 0.7;\n\nflut_f1_R = flut_reroll_R ? new_f1_R : flut_f1_R;\nflut_f2_R = flut_reroll_R ? new_f2_R : flut_f2_R;\nflut_chunk_left_R = flut_reroll_R ? flut_chunk_n : flut_chunk_dec_R;\n\nflut_phase1_R = flut_phase1_R + 2 * pi * flut_f1_R / samplerate;\nflut_phase2_R = flut_phase2_R + 2 * pi * flut_f2_R / samplerate;\nflut_phase1_R = flut_phase1_R - (flut_phase1_R > 2*pi) * 2 * pi;\nflut_phase2_R = flut_phase2_R - (flut_phase2_R > 2*pi) * 2 * pi;\n\nflut_mod_R_raw = 0.5 * (sin(flut_phase1_R) + sin(flut_phase2_R));\nflut_mod_R = 1 + flut_depth * flut_mod_R_raw;\n\n// Routing under spread.\nflut_for_L = flut_mod_L;\nflut_for_R = (spread > 0) ? flut_mod_R : flut_mod_L;\n\n// Apply micro-flutter on the snag-output (chain order: SNAG \u2192 MICRO-FLUTTER).\npostflut_L = snag_out_L * flut_for_L;\npostflut_R = snag_out_R * flut_for_R;\n\n\n// =============================================================================\n// SUB-ENGINE A \u2014 DROP (gated dropouts via cosine-ramp envelope)\n// =============================================================================\n//\n// Per-sample state machine, structurally identical to SNAG but with:\n//   phase 1 = ramp_down (1 \u2192 0 over 5 ms cosine)\n//   phase 2 = hold      (env = 0 for hold_n samples)\n//   phase 3 = ramp_up   (0 \u2192 1 over 5 ms cosine)\n//\n// Round-2 rate = 8*f + 18*f^2 events/min, duration = (30+220*f)*uniform(0.7,1.3).\n// Note \"duration\" is the *total* event length (numpy: dur_n samples top-of-\n// envelope-down through end-of-ramp-up). Hold portion = dur_n - 2*ramp_n.\n// -----------------------------------------------------------------------------\n\nDROP_RATE_K1 = 8;\nDROP_RATE_K2 = 18;\nDROP_DUR_BASE_MS = 30;\nDROP_DUR_F_MS = 220;\nDROP_RAMP_MS = 5;\n\ndrop_rate_per_sec = (DROP_RATE_K1 * effective + DROP_RATE_K2 * effective * effective) / 60;\ndrop_lambda_safe = max(drop_rate_per_sec, 1e-9);\ndrop_mean_dt_samp = samplerate / drop_lambda_safe;\ndrop_ramp_n = max(1, DROP_RAMP_MS * 1e-3 * samplerate);\n\n// ---- L ----\n\nu_drop_dt_L = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_drop_dt_L = -log(u_drop_dt_L) * drop_mean_dt_samp;\nu_drop_dur_L = ((noise() + 1.0) * 0.5);\nevent_drop_dur_n_L = (DROP_DUR_BASE_MS + DROP_DUR_F_MS * effective) * (0.7 + 0.6 * u_drop_dur_L) * 1e-3 * samplerate;\n// Hold = total - 2*ramp. Numpy clamps total >= 2*ramp+1; same here.\nevent_drop_hold_n_L = max(1, event_drop_dur_n_L - 2 * drop_ramp_n);\n\ndrop_engine_on_L = (effective > 0) * (1 - drop_bypass);\n\nprev_drop_phase_L      = drop_phase_L;\nprev_drop_countdown_L  = drop_countdown_L;\nprev_drop_phase_left_L = drop_phase_left_L;\nprev_drop_hold_n_L     = drop_hold_n_L;\n\ndrop_idle_dec_L  = prev_drop_countdown_L - 1;\ndrop_idle_fires_L = (prev_drop_phase_L == 0) * (drop_idle_dec_L <= 0) * drop_engine_on_L;\ndrop_atk_left_L = prev_drop_phase_left_L - 1;\ndrop_atk_done_L = (prev_drop_phase_L == 1) * (drop_atk_left_L <= 0);\ndrop_hold_left_L = prev_drop_phase_left_L - 1;\ndrop_hold_done_L = (prev_drop_phase_L == 2) * (drop_hold_left_L <= 0);\ndrop_rel_left_L = prev_drop_phase_left_L - 1;\ndrop_rel_done_L = (prev_drop_phase_L == 3) * (drop_rel_left_L <= 0);\n\nnext_drop_phase_L      = prev_drop_phase_L;\nnext_drop_phase_left_L = prev_drop_phase_left_L;\nnext_drop_countdown_L  = prev_drop_countdown_L;\nnext_drop_hold_n_L     = prev_drop_hold_n_L;\n\nnext_drop_countdown_L  = (prev_drop_phase_L == 0) ? drop_idle_dec_L : next_drop_countdown_L;\nnext_drop_phase_L      = drop_idle_fires_L ? 1 : next_drop_phase_L;\nnext_drop_phase_left_L = drop_idle_fires_L ? drop_ramp_n : next_drop_phase_left_L;\nnext_drop_hold_n_L     = drop_idle_fires_L ? event_drop_hold_n_L : next_drop_hold_n_L;\n\nnext_drop_phase_left_L = ((prev_drop_phase_L == 1) * (drop_atk_done_L == 0)) ? drop_atk_left_L : next_drop_phase_left_L;\nnext_drop_phase_L      = drop_atk_done_L ? 2 : next_drop_phase_L;\nnext_drop_phase_left_L = drop_atk_done_L ? prev_drop_hold_n_L : next_drop_phase_left_L;\n\nnext_drop_phase_left_L = ((prev_drop_phase_L == 2) * (drop_hold_done_L == 0)) ? drop_hold_left_L : next_drop_phase_left_L;\nnext_drop_phase_L      = drop_hold_done_L ? 3 : next_drop_phase_L;\nnext_drop_phase_left_L = drop_hold_done_L ? drop_ramp_n : next_drop_phase_left_L;\n\nnext_drop_phase_left_L = ((prev_drop_phase_L == 3) * (drop_rel_done_L == 0)) ? drop_rel_left_L : next_drop_phase_left_L;\nnext_drop_phase_L      = drop_rel_done_L ? 0 : next_drop_phase_L;\nnext_drop_countdown_L  = drop_rel_done_L ? new_drop_dt_L : next_drop_countdown_L;\nnext_drop_phase_left_L = drop_rel_done_L ? 0 : next_drop_phase_left_L;\n\ndrop_cold_start_L = (prev_drop_phase_L == 0) * (prev_drop_countdown_L == 0) * drop_engine_on_L;\nnext_drop_countdown_L = drop_cold_start_L ? new_drop_dt_L : next_drop_countdown_L;\n\ndrop_countdown_L  = next_drop_countdown_L;\ndrop_phase_L      = next_drop_phase_L;\ndrop_phase_left_L = next_drop_phase_left_L;\ndrop_hold_n_L     = next_drop_hold_n_L;\n\n// Compute envelope value. Numpy uses:\n//   ramp_down = 0.5*(1+cos(pi*i/n))  goes 1 \u2192 0 as i goes 0..n\n//   ramp_up   = 0.5*(1-cos(pi*i/n))  goes 0 \u2192 1 as i goes 0..n\n// Our phase_left counts down from ramp_n \u2192 0; ramp index i = ramp_n - phase_left.\ndrop_atk_idx_L = drop_ramp_n - next_drop_phase_left_L;\ndrop_rel_idx_L = drop_ramp_n - next_drop_phase_left_L;\ndrop_atk_env_L = 0.5 * (1 + cos(pi * drop_atk_idx_L / max(1, drop_ramp_n)));\ndrop_rel_env_L = 0.5 * (1 - cos(pi * drop_rel_idx_L / max(1, drop_ramp_n)));\n\ndrop_env_L =\n    (next_drop_phase_L == 1) ? drop_atk_env_L :\n    (next_drop_phase_L == 2) ? 0              :\n    (next_drop_phase_L == 3) ? drop_rel_env_L :\n    1;\n\ndrop_env_L = (drop_bypass + short_circuit > 0) ? 1 : drop_env_L;\n\n\n// ---- R ----\n\nu_drop_dt_R = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_drop_dt_R = -log(u_drop_dt_R) * drop_mean_dt_samp;\nu_drop_dur_R = ((noise() + 1.0) * 0.5);\nevent_drop_dur_n_R = (DROP_DUR_BASE_MS + DROP_DUR_F_MS * effective) * (0.7 + 0.6 * u_drop_dur_R) * 1e-3 * samplerate;\nevent_drop_hold_n_R = max(1, event_drop_dur_n_R - 2 * drop_ramp_n);\n\ndrop_engine_on_R = (effective > 0) * (1 - drop_bypass);\n\nprev_drop_phase_R      = drop_phase_R;\nprev_drop_countdown_R  = drop_countdown_R;\nprev_drop_phase_left_R = drop_phase_left_R;\nprev_drop_hold_n_R     = drop_hold_n_R;\n\ndrop_idle_dec_R  = prev_drop_countdown_R - 1;\ndrop_idle_fires_R = (prev_drop_phase_R == 0) * (drop_idle_dec_R <= 0) * drop_engine_on_R;\ndrop_atk_left_R = prev_drop_phase_left_R - 1;\ndrop_atk_done_R = (prev_drop_phase_R == 1) * (drop_atk_left_R <= 0);\ndrop_hold_left_R = prev_drop_phase_left_R - 1;\ndrop_hold_done_R = (prev_drop_phase_R == 2) * (drop_hold_left_R <= 0);\ndrop_rel_left_R = prev_drop_phase_left_R - 1;\ndrop_rel_done_R = (prev_drop_phase_R == 3) * (drop_rel_left_R <= 0);\n\nnext_drop_phase_R      = prev_drop_phase_R;\nnext_drop_phase_left_R = prev_drop_phase_left_R;\nnext_drop_countdown_R  = prev_drop_countdown_R;\nnext_drop_hold_n_R     = prev_drop_hold_n_R;\n\nnext_drop_countdown_R  = (prev_drop_phase_R == 0) ? drop_idle_dec_R : next_drop_countdown_R;\nnext_drop_phase_R      = drop_idle_fires_R ? 1 : next_drop_phase_R;\nnext_drop_phase_left_R = drop_idle_fires_R ? drop_ramp_n : next_drop_phase_left_R;\nnext_drop_hold_n_R     = drop_idle_fires_R ? event_drop_hold_n_R : next_drop_hold_n_R;\n\nnext_drop_phase_left_R = ((prev_drop_phase_R == 1) * (drop_atk_done_R == 0)) ? drop_atk_left_R : next_drop_phase_left_R;\nnext_drop_phase_R      = drop_atk_done_R ? 2 : next_drop_phase_R;\nnext_drop_phase_left_R = drop_atk_done_R ? prev_drop_hold_n_R : next_drop_phase_left_R;\n\nnext_drop_phase_left_R = ((prev_drop_phase_R == 2) * (drop_hold_done_R == 0)) ? drop_hold_left_R : next_drop_phase_left_R;\nnext_drop_phase_R      = drop_hold_done_R ? 3 : next_drop_phase_R;\nnext_drop_phase_left_R = drop_hold_done_R ? drop_ramp_n : next_drop_phase_left_R;\n\nnext_drop_phase_left_R = ((prev_drop_phase_R == 3) * (drop_rel_done_R == 0)) ? drop_rel_left_R : next_drop_phase_left_R;\nnext_drop_phase_R      = drop_rel_done_R ? 0 : next_drop_phase_R;\nnext_drop_countdown_R  = drop_rel_done_R ? new_drop_dt_R : next_drop_countdown_R;\nnext_drop_phase_left_R = drop_rel_done_R ? 0 : next_drop_phase_left_R;\n\ndrop_cold_start_R = (prev_drop_phase_R == 0) * (prev_drop_countdown_R == 0) * drop_engine_on_R;\nnext_drop_countdown_R = drop_cold_start_R ? new_drop_dt_R : next_drop_countdown_R;\n\ndrop_countdown_R  = next_drop_countdown_R;\ndrop_phase_R      = next_drop_phase_R;\ndrop_phase_left_R = next_drop_phase_left_R;\ndrop_hold_n_R     = next_drop_hold_n_R;\n\ndrop_atk_idx_R = drop_ramp_n - next_drop_phase_left_R;\ndrop_rel_idx_R = drop_ramp_n - next_drop_phase_left_R;\ndrop_atk_env_R = 0.5 * (1 + cos(pi * drop_atk_idx_R / max(1, drop_ramp_n)));\ndrop_rel_env_R = 0.5 * (1 - cos(pi * drop_rel_idx_R / max(1, drop_ramp_n)));\n\ndrop_env_R =\n    (next_drop_phase_R == 1) ? drop_atk_env_R :\n    (next_drop_phase_R == 2) ? 0              :\n    (next_drop_phase_R == 3) ? drop_rel_env_R :\n    1;\n\ndrop_env_R = (drop_bypass + short_circuit > 0) ? 1 : drop_env_R;\n\n// Routing.\ndrop_env_for_L = drop_env_L;\ndrop_env_for_R = (spread > 0) ? drop_env_R : drop_env_L;\n\npostdrop_L = postflut_L * drop_env_for_L;\npostdrop_R = postflut_R * drop_env_for_R;\n\n\n// =============================================================================\n// SUB-ENGINE C1 \u2014 CRINKLE BURSTS (additive bandpass-filtered noise impulses)\n// =============================================================================\n//\n// Streaming Poisson burst scheduler. Per event:\n//   amp \u2208 uniform(0.2, 0.5)\n//   dur_n \u2208 uniform(1, 4) ms\n//   triangular AR envelope, sharp attack (a_n = dur_n/4), longer release.\n//\n// Numpy uses np.maximum to overlap envelopes. Per-sample analog: keep an\n// `env_state` History; fire-on-event resets it to start a new envelope; while\n// active, ramp down each sample. New events may overlap and we take the max\n// of the current state and the new envelope value (handled by re-arming on\n// each fire; if a new fire happens during a release, we restart at the new\n// amp peak, which is the per-sample equivalent of `np.maximum`).\n//\n// Then: noise * env_state \u2192 bandpass biquad \u2192 normalize \u00d7 0.30 \u00d7 crinkle_level.\n//\n// Normalization in numpy is `peak = max(abs(filtered))` over the whole buffer.\n// At sample-rate we have no buffer-level max. Translation: use the analytical\n// peak of the BPF impulse response \u00d7 event amp \u2248 1 (the BPF's peak gain at\n// fc=2500/Q=1.5 is Q=1.5 \u2014 slight magnification \u2014 but events are also scaled\n// by uniform(0.2,0.5) and triangular envelope, whose maximum \u2248 0.5). So a\n// reasonable static normalization constant matching the round-2 reference's\n// post-filter peak is empirically near 0.3\u20130.5; we use a fixed\n// `CRINKLE_PEAK_EST = 0.5` so the post-norm * 0.30 multiplier produces the\n// same audible level the round-2 fixtures hit. This is an approximation\n// (numpy's per-buffer normalization is not preserved bit-for-bit; the design\n// doc tradeoff log already accepts that gen-port is not bit-identical).\n// -----------------------------------------------------------------------------\n\nCRINKLE_RATE_K3 = 30;     // f^3 coefficient\nCRINKLE_FLOOR = 1;        // bursts/sec floor\nCRINKLE_AMP_LO = 0.2;\nCRINKLE_AMP_HI = 0.5;\nCRINKLE_DUR_LO_MS = 1;\nCRINKLE_DUR_HI_MS = 4;\nCRINKLE_HEADROOM = 0.30;  // round-2 (was 0.5)\nCRINKLE_PEAK_EST = 0.5;   // static normalization estimate (see comment above)\n\n// Gate: numpy ref's spec says crinkle is always-on if crinkle_level > 0; the\n// reference impl gates on (failure > 0) AND (crinkle_level > 0) for sanity\n// hash stability. The design doc tradeoff #10 says: engineer must relax to\n// always-on when crinkle_level > 0, regardless of failure. Honor the spec.\ncrinkle_engine_on = (crinkle_level > 0) * (1 - short_circuit * 0);\n// Re-evaluating: short_circuit happens only when knob==0 AND override==0,\n// meaning the user has the failure off entirely. In that case the spec says\n// crinkle should still be audible if crinkle_level > 0. So we DON'T gate on\n// short_circuit here. We do, however, drive the rate from `effective` so\n// at effective=0 the rate is the floor (1 burst/sec).\ncrinkle_engine_on = (crinkle_level > 0);\n\ncrinkle_rate_per_sec = CRINKLE_RATE_K3 * effective * effective * effective + CRINKLE_FLOOR;\ncrinkle_lambda_safe = max(crinkle_rate_per_sec, 1e-9);\ncrinkle_mean_dt_samp = samplerate / crinkle_lambda_safe;\n\n// ---- L ----\n\nu_cr_dt_L = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_cr_dt_L = -log(u_cr_dt_L) * crinkle_mean_dt_samp;\nu_cr_amp_L = ((noise() + 1.0) * 0.5);\nu_cr_dur_L = ((noise() + 1.0) * 0.5);\nevent_cr_amp_L = CRINKLE_AMP_LO + (CRINKLE_AMP_HI - CRINKLE_AMP_LO) * u_cr_amp_L;\nevent_cr_dur_n_L = max(2, (CRINKLE_DUR_LO_MS + (CRINKLE_DUR_HI_MS - CRINKLE_DUR_LO_MS) * u_cr_dur_L) * 1e-3 * samplerate);\nevent_cr_a_n_L = max(1, event_cr_dur_n_L * 0.25);\nevent_cr_r_n_L = max(1, event_cr_dur_n_L - event_cr_a_n_L);\n\nprev_cr_countdown_L = crinkle_countdown_L;\nprev_cr_phase_L     = crinkle_env_phase_L;\nprev_cr_left_L      = crinkle_env_left_L;\nprev_cr_amp_L       = crinkle_amp_L;\nprev_cr_a_n_L       = crinkle_a_n_L;\nprev_cr_r_n_L       = crinkle_r_n_L;\n\ncr_idle_dec_L = prev_cr_countdown_L - 1;\ncr_idle_fires_L = (cr_idle_dec_L <= 0) * crinkle_engine_on;\ncr_atk_left_L = prev_cr_left_L - 1;\ncr_atk_done_L = (prev_cr_phase_L == 1) * (cr_atk_left_L <= 0);\ncr_rel_left_L = prev_cr_left_L - 1;\ncr_rel_done_L = (prev_cr_phase_L == 2) * (cr_rel_left_L <= 0);\n\nnext_cr_phase_L     = prev_cr_phase_L;\nnext_cr_left_L      = prev_cr_left_L;\nnext_cr_countdown_L = prev_cr_countdown_L;\nnext_cr_amp_L       = prev_cr_amp_L;\nnext_cr_a_n_L       = prev_cr_a_n_L;\nnext_cr_r_n_L       = prev_cr_r_n_L;\n\nnext_cr_countdown_L = cr_idle_dec_L;\n// On fire: re-arm into attack (overlapping new event takes precedence \u2014 this\n// is the per-sample analog of np.maximum overlap: a new burst overrides an\n// in-flight tail which was already lower-amplitude on its release leg).\nnext_cr_phase_L = cr_idle_fires_L ? 1 : next_cr_phase_L;\nnext_cr_left_L  = cr_idle_fires_L ? event_cr_a_n_L : next_cr_left_L;\nnext_cr_amp_L   = cr_idle_fires_L ? event_cr_amp_L : next_cr_amp_L;\nnext_cr_a_n_L   = cr_idle_fires_L ? event_cr_a_n_L : next_cr_a_n_L;\nnext_cr_r_n_L   = cr_idle_fires_L ? event_cr_r_n_L : next_cr_r_n_L;\nnext_cr_countdown_L = cr_idle_fires_L ? new_cr_dt_L : next_cr_countdown_L;\n\nnext_cr_left_L  = ((prev_cr_phase_L == 1) * (cr_atk_done_L == 0)) ? cr_atk_left_L : next_cr_left_L;\nnext_cr_phase_L = cr_atk_done_L ? 2 : next_cr_phase_L;\nnext_cr_left_L  = cr_atk_done_L ? prev_cr_r_n_L : next_cr_left_L;\n\nnext_cr_left_L  = ((prev_cr_phase_L == 2) * (cr_rel_done_L == 0)) ? cr_rel_left_L : next_cr_left_L;\nnext_cr_phase_L = cr_rel_done_L ? 0 : next_cr_phase_L;\nnext_cr_left_L  = cr_rel_done_L ? 0 : next_cr_left_L;\n\ncr_cold_L = (prev_cr_phase_L == 0) * (prev_cr_countdown_L == 0) * crinkle_engine_on;\nnext_cr_countdown_L = cr_cold_L ? new_cr_dt_L : next_cr_countdown_L;\n\ncrinkle_countdown_L = next_cr_countdown_L;\ncrinkle_env_phase_L = next_cr_phase_L;\ncrinkle_env_left_L  = next_cr_left_L;\ncrinkle_amp_L       = next_cr_amp_L;\ncrinkle_a_n_L       = next_cr_a_n_L;\ncrinkle_r_n_L       = next_cr_r_n_L;\n\n// Triangular envelope value:\n//   attack:  i = a_n - left, env = amp * (i / a_n)\n//   release: i = r_n - left, env = amp * (1 - i / r_n)\ncr_atk_idx_L = next_cr_a_n_L - next_cr_left_L;\ncr_rel_idx_L = next_cr_r_n_L - next_cr_left_L;\ncr_atk_env_L = next_cr_amp_L * cr_atk_idx_L / max(1, next_cr_a_n_L);\ncr_rel_env_L = next_cr_amp_L * (1 - cr_rel_idx_L / max(1, next_cr_r_n_L));\n\ncrinkle_env_value_L =\n    (next_cr_phase_L == 1) ? cr_atk_env_L :\n    (next_cr_phase_L == 2) ? cr_rel_env_L :\n    0;\n\ncrinkle_env_L = crinkle_env_value_L;\n\n// White noise * envelope.\ncr_noise_L = noise() * crinkle_env_L;\n\n// ---- R ----\n\nu_cr_dt_R = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_cr_dt_R = -log(u_cr_dt_R) * crinkle_mean_dt_samp;\nu_cr_amp_R = ((noise() + 1.0) * 0.5);\nu_cr_dur_R = ((noise() + 1.0) * 0.5);\nevent_cr_amp_R = CRINKLE_AMP_LO + (CRINKLE_AMP_HI - CRINKLE_AMP_LO) * u_cr_amp_R;\nevent_cr_dur_n_R = max(2, (CRINKLE_DUR_LO_MS + (CRINKLE_DUR_HI_MS - CRINKLE_DUR_LO_MS) * u_cr_dur_R) * 1e-3 * samplerate);\nevent_cr_a_n_R = max(1, event_cr_dur_n_R * 0.25);\nevent_cr_r_n_R = max(1, event_cr_dur_n_R - event_cr_a_n_R);\n\nprev_cr_countdown_R = crinkle_countdown_R;\nprev_cr_phase_R     = crinkle_env_phase_R;\nprev_cr_left_R      = crinkle_env_left_R;\nprev_cr_amp_R       = crinkle_amp_R;\nprev_cr_a_n_R       = crinkle_a_n_R;\nprev_cr_r_n_R       = crinkle_r_n_R;\n\ncr_idle_dec_R = prev_cr_countdown_R - 1;\ncr_idle_fires_R = (cr_idle_dec_R <= 0) * crinkle_engine_on;\ncr_atk_left_R = prev_cr_left_R - 1;\ncr_atk_done_R = (prev_cr_phase_R == 1) * (cr_atk_left_R <= 0);\ncr_rel_left_R = prev_cr_left_R - 1;\ncr_rel_done_R = (prev_cr_phase_R == 2) * (cr_rel_left_R <= 0);\n\nnext_cr_phase_R     = prev_cr_phase_R;\nnext_cr_left_R      = prev_cr_left_R;\nnext_cr_countdown_R = prev_cr_countdown_R;\nnext_cr_amp_R       = prev_cr_amp_R;\nnext_cr_a_n_R       = prev_cr_a_n_R;\nnext_cr_r_n_R       = prev_cr_r_n_R;\n\nnext_cr_countdown_R = cr_idle_dec_R;\nnext_cr_phase_R = cr_idle_fires_R ? 1 : next_cr_phase_R;\nnext_cr_left_R  = cr_idle_fires_R ? event_cr_a_n_R : next_cr_left_R;\nnext_cr_amp_R   = cr_idle_fires_R ? event_cr_amp_R : next_cr_amp_R;\nnext_cr_a_n_R   = cr_idle_fires_R ? event_cr_a_n_R : next_cr_a_n_R;\nnext_cr_r_n_R   = cr_idle_fires_R ? event_cr_r_n_R : next_cr_r_n_R;\nnext_cr_countdown_R = cr_idle_fires_R ? new_cr_dt_R : next_cr_countdown_R;\n\nnext_cr_left_R  = ((prev_cr_phase_R == 1) * (cr_atk_done_R == 0)) ? cr_atk_left_R : next_cr_left_R;\nnext_cr_phase_R = cr_atk_done_R ? 2 : next_cr_phase_R;\nnext_cr_left_R  = cr_atk_done_R ? prev_cr_r_n_R : next_cr_left_R;\n\nnext_cr_left_R  = ((prev_cr_phase_R == 2) * (cr_rel_done_R == 0)) ? cr_rel_left_R : next_cr_left_R;\nnext_cr_phase_R = cr_rel_done_R ? 0 : next_cr_phase_R;\nnext_cr_left_R  = cr_rel_done_R ? 0 : next_cr_left_R;\n\ncr_cold_R = (prev_cr_phase_R == 0) * (prev_cr_countdown_R == 0) * crinkle_engine_on;\nnext_cr_countdown_R = cr_cold_R ? new_cr_dt_R : next_cr_countdown_R;\n\ncrinkle_countdown_R = next_cr_countdown_R;\ncrinkle_env_phase_R = next_cr_phase_R;\ncrinkle_env_left_R  = next_cr_left_R;\ncrinkle_amp_R       = next_cr_amp_R;\ncrinkle_a_n_R       = next_cr_a_n_R;\ncrinkle_r_n_R       = next_cr_r_n_R;\n\ncr_atk_idx_R = next_cr_a_n_R - next_cr_left_R;\ncr_rel_idx_R = next_cr_r_n_R - next_cr_left_R;\ncr_atk_env_R = next_cr_amp_R * cr_atk_idx_R / max(1, next_cr_a_n_R);\ncr_rel_env_R = next_cr_amp_R * (1 - cr_rel_idx_R / max(1, next_cr_r_n_R));\n\ncrinkle_env_value_R =\n    (next_cr_phase_R == 1) ? cr_atk_env_R :\n    (next_cr_phase_R == 2) ? cr_rel_env_R :\n    0;\n\ncrinkle_env_R = crinkle_env_value_R;\ncr_noise_R = noise() * crinkle_env_R;\n\n\n// ---- BPF biquad \u2014 RBJ constant-skirt (fc=2500 Hz, Q=1.5) ----\n// Coefficients computed at sample rate. Matches numpy `_bpf_coeffs`.\nbpf_w0 = 2 * pi * 2500 / samplerate;\nbpf_cos_w0 = cos(bpf_w0);\nbpf_alpha = sin(bpf_w0) / (2 * 1.5);\nbpf_a0 = 1 + bpf_alpha;\nbpf_b0 = (1.5 * bpf_alpha) / bpf_a0;\nbpf_b1 = 0;\nbpf_b2 = (-1.5 * bpf_alpha) / bpf_a0;\nbpf_a1 = (-2 * bpf_cos_w0) / bpf_a0;\nbpf_a2 = (1 - bpf_alpha) / bpf_a0;\n\n// Direct Form I biquad, channel L.\n\nbpf_y_L_raw = bpf_b0 * cr_noise_L + bpf_b1 * bpf_x1_L + bpf_b2 * bpf_x2_L\n              - bpf_a1 * bpf_y1_L - bpf_a2 * bpf_y2_L;\n// Denormal flush per JOS recommendation.\nbpf_y_L = (abs(bpf_y_L_raw) < 1e-30) ? 0 : bpf_y_L_raw;\n\nbpf_x2_L = bpf_x1_L;\nbpf_x1_L = cr_noise_L;\nbpf_y2_L = bpf_y1_L;\nbpf_y1_L = bpf_y_L;\n\n// Normalize then scale: post-norm * CRINKLE_HEADROOM * crinkle_level.\ncrinkle_out_L = (bpf_y_L / CRINKLE_PEAK_EST) * CRINKLE_HEADROOM * crinkle_level;\n\n// Direct Form I biquad, channel R.\n\nbpf_y_R_raw = bpf_b0 * cr_noise_R + bpf_b1 * bpf_x1_R + bpf_b2 * bpf_x2_R\n              - bpf_a1 * bpf_y1_R - bpf_a2 * bpf_y2_R;\nbpf_y_R = (abs(bpf_y_R_raw) < 1e-30) ? 0 : bpf_y_R_raw;\n\nbpf_x2_R = bpf_x1_R;\nbpf_x1_R = cr_noise_R;\nbpf_y2_R = bpf_y1_R;\nbpf_y1_R = bpf_y_R;\n\ncrinkle_out_R = (bpf_y_R / CRINKLE_PEAK_EST) * CRINKLE_HEADROOM * crinkle_level;\n\n// Routing: under spread=0, broadcast L crinkle to both channels.\ncrinkle_for_L = crinkle_out_L;\ncrinkle_for_R = (spread > 0) ? crinkle_out_R : crinkle_out_L;\n\n// Disable crinkle on short-circuit OR when crinkle_level == 0.\ncrinkle_for_L = (short_circuit + (crinkle_level <= 0) > 0) ? 0 : crinkle_for_L;\ncrinkle_for_R = (short_circuit + (crinkle_level <= 0) > 0) ? 0 : crinkle_for_R;\n\n\n// =============================================================================\n// FINAL MIX & SHORT-CIRCUIT\n// =============================================================================\n//\n// Chain order from design doc \u00a71: SNAG \u2192 MICRO-FLUTTER \u2192 DROP \u2192 +CRINKLE.\n// Already accumulated in `postdrop_X` (signal path) and `crinkle_for_X`\n// (additive). When short_circuit is true, route raw inputs through unchanged\n// for bit-identical T1/P1 behavior.\n// -----------------------------------------------------------------------------\n\nprocessed_L = postdrop_L + crinkle_for_L;\nprocessed_R = postdrop_R + crinkle_for_R;\n\nout1 = short_circuit ? in1 : processed_L;\nout2 = short_circuit ? in2 : processed_R;\n\n// =============================================================================\n// END tl_failure.gendsp\n// =============================================================================\n"
								}
							},
							{
								"box": {
									"id": "tl_failure-gen-out1",
									"maxclass": "newobj",
									"text": "out 1",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										30.0,
										540.0,
										35.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "tl_failure-gen-out2",
									"maxclass": "newobj",
									"text": "out 2",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										100.0,
										540.0,
										35.0,
										22.0
									]
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_failure-gen-in1",
										0
									],
									"destination": [
										"tl_failure-gen-codebox",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-gen-in2",
										0
									],
									"destination": [
										"tl_failure-gen-codebox",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-gen-in3",
										0
									],
									"destination": [
										"tl_failure-gen-codebox",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-gen-in4",
										0
									],
									"destination": [
										"tl_failure-gen-codebox",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-gen-codebox",
										0
									],
									"destination": [
										"tl_failure-gen-out1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-gen-codebox",
										1
									],
									"destination": [
										"tl_failure-gen-out2",
										0
									]
								}
							}
						]
					},
					"rnboattrcache": {},
					"saved_object_attributes": {
						"exportfolder": "",
						"exportname": "tl_failure_dsp",
						"wantsoutputcore": 0
					}
				}
			},
			{
				"box": {
					"id": "tl_failure-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						180,
						700,
						80
					],
					"text": "tl_failure (SANDBOX-PARTIAL): 4 sub-engines (drop, snag, micro-flutter, crinkle). Poisson scheduler; SPREAD = independent L/R RNG. Cross-module contract #1: inlet 8 (failure_override) from tl_aux FAIL mode; effective_failure = failure + override*(1-failure). Sub-engine ordering: snag \u2192 micro-flutter \u2192 drop \u2192 +crinkle. crinkle_level (hidden) controls crinkle output. drop_bypass/snag_bypass dip switches."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_failure-in-L",
						0
					],
					"destination": [
						"tl_failure-gen",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_failure-in-R",
						0
					],
					"destination": [
						"tl_failure-gen",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_failure-pin-0",
						0
					],
					"destination": [
						"tl_failure-gen",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_failure-in-fov",
						0
					],
					"destination": [
						"tl_failure-gen",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_failure-gen",
						0
					],
					"destination": [
						"tl_failure-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_failure-gen",
						1
					],
					"destination": [
						"tl_failure-out-R",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_failure",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}