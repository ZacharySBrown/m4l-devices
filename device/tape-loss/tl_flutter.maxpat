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
					"id": "tl_flutter-in-L",
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
					"id": "tl_flutter-in-R",
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
					"id": "tl_flutter-pin-0",
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
					"id": "tl_flutter-pin-1",
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
					"id": "tl_flutter-out-L",
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
					"id": "tl_flutter-out-R",
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
					"id": "tl_flutter-gen",
					"maxclass": "newobj",
					"numinlets": 2,
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
					"text": "gen~ @title tl_flutter_lfos",
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
									"id": "tl_flutter-gen-in1",
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
									"id": "tl_flutter-gen-in2",
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
									"id": "tl_flutter-gen-codebox",
									"maxclass": "codebox",
									"numinlets": 2,
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
									"code": "// =====================================================================\n// tl_flutter.gendsp \u2014 gen~ DSL source for the FLUTTER module of tape-loss\n// =====================================================================\n//\n// Module          : tl_flutter (Generation Loss MKII \"FLUTTER\" knob)\n// TUNING_VERSION  : 2 (round-2 retune, sqrt taper \u2014 see design-doc \u00a713b)\n// Authored        : 2026-04-27 (Phase 2.5 \u2014 gen~ translation)\n// Author          : pedal-engineer (auto-authored from numpy reference)\n//\n// Source files :\n//   design-doc      : docs/design-docs/dsp/tl-flutter-design.md\n//                     sha256: 1b8c99fb7250020f49ad81d8b1deb568397c55614c\n//                             120869e3dcadd4995a7202\n//   numpy reference : dsp/reference/tl_flutter.py     (TUNING_VERSION = 2)\n//                     sha256: 0c85878d0e2e92dfa3b44a9ae3ce78637d50e1389b\n//                             4f39991e6f54b428d0027b\n//   parent stub     : device/tape-loss/tl_flutter.maxpat (codebox host)\n//\n// Inlets  (2): in1 = signal L, in2 = signal R\n// Outlets (2): out1 = signal L, out2 = signal R\n// Params  (2): flutter      \u2208 [0, 1]   (default 0.0)\n//              classic_mode \u2208 {0, 1}   (default 0)   AM-bypass-only\n//\n// ---------------------------------------------------------------------\n// Algorithm summary (translated 1:1 from dsp/reference/tl_flutter.py;\n// fast pitch + AM modulation per spec \u00a7\"MODULE 5: tl.flutter.maxpat\"):\n//\n//   Per channel (independent noise() streams = decorrelated stereo):\n//\n//     Pitch-mod LFO bank:\n//       n_p1 = noise() \u2192 biquad RBJ LPF(fc= 8 Hz, Q=0.7) \u2500\u2510\n//       n_p2 = noise() \u2192 biquad RBJ LPF(fc=19 Hz, Q=0.7) \u2500\u2534 avg\n//       lfo_p = avg(n_p1_filt, n_p2_filt) \u00b7 PITCH_LFO_NORM   // p99 \u2248 1.0\n//\n//     AM-mod LFO bank (different cutoffs \u2014 pitch and AM should NOT track):\n//       n_a1 = noise() \u2192 biquad RBJ LPF(fc=11 Hz, Q=0.6) \u2500\u2510\n//       n_a2 = noise() \u2192 biquad RBJ LPF(fc=23 Hz, Q=0.6) \u2500\u2534 avg\n//       lfo_a = avg(n_a1_filt, n_a2_filt) \u00b7 AM_LFO_NORM      // p99 \u2248 1.0\n//\n//     Round-2 sqrt depth tapers (NOT quadratic \u2014 see \u00a713b):\n//       pitch_depth_seconds = 1.5e-4 \u00b7 sqrt(flutter)\n//       am_depth            = 0.25   \u00b7 sqrt(flutter)\n//\n//     Variable-delay read (4-point LAGRANGE \u2014 JOS PASP \"Lagrange Interp.\"):\n//       D[n]      = (BASE_DELAY_S + pitch_depth_seconds \u00b7 lfo_p) \u00b7 sr\n//       write delbuf[n] = x[n]\n//       y_pitched = lagrange4(delbuf, D, frac)\n//\n//     AM stage (gated by classic_mode):\n//       multiplier = 1 + am_depth \u00b7 lfo_a\n//       y = (classic_mode != 0) ? y_pitched : y_pitched \u00b7 multiplier\n//\n//     Short-circuit (bit-identical passthrough invariant):\n//       short = (flutter <= EPS)\n//       out   = short ? x : y\n//\n// ---------------------------------------------------------------------\n// Sanity-check expectations (matches numpy ref's run_round2_taper_assertions):\n//\n//   flutter = 0.0                      \u2192 bit-identical passthrough (regression)\n//   flutter = 0.5, classic_mode = 0    \u2192 pitch p99 \u2265 18 c, AM pk-pk \u2265 1.0 dB\n//                                         (chord-noon audibility floor \u2014 clears\n//                                          the round-2 ground-truth assertions)\n//   flutter = 1.0, classic_mode = 0    \u2192 pitch p99 \u2264 50 c (under vibrato boundary;\n//                                         numpy ref measures 28.4 c)\n//                                         AM pk-pk ~ 5 dB (numpy ref measures 5.0)\n//   flutter = 1.0, classic_mode = 1    \u2192 AM bypassed; pitch path identical to\n//                                         non-classic (sha-equal pitch path)\n//\n// ---------------------------------------------------------------------\n// Lagrange-4 kernel (JOS PASP \"Lagrange Interpolation\"):\n//\n//   For frac \u2208 [0, 1) read at samples [-1, 0, 1, 2] relative to floor:\n//\n//     c_m1 = -frac \u00b7 (frac - 1) \u00b7 (frac - 2) / 6\n//     c_0  =  (frac + 1) \u00b7 (frac - 1) \u00b7 (frac - 2) / 2\n//     c_p1 = -(frac + 1) \u00b7 frac      \u00b7 (frac - 2) / 2\n//     c_p2 =  (frac + 1) \u00b7 frac      \u00b7 (frac - 1) / 6\n//     y    = c_m1\u00b7xm1 + c_0\u00b7x0 + c_p1\u00b7x1 + c_p2\u00b7x2\n//\n// NB: this is NOT the Hermite-4 (Catmull-Rom) kernel used in tl_wow.gendsp.\n// Lagrange interpolates exactly through all four sample points (polynomial\n// fit), while Hermite uses estimated derivatives at the inner two. Per the\n// design-doc \u00a75, Lagrange-4 matches Max's tapout~ internal interpolation\n// and gives smoother HF artifact rejection than linear at modest cost.\n//\n// ---------------------------------------------------------------------\n// 99th-percentile-peak normalization scalars (constants from design-doc \u00a710\n// row 12 / numpy ref _build_lfo). MEASURED EMPIRICALLY from the reference\n// path (RBJ LPF + Direct-Form-I biquad with denormal flush + sum-and-divide-\n// by-n_bands), 8 seeds \u00d7 30 s, sr = 44.1 kHz, then median taken:\n//\n//   PITCH_LFO_NORM = 21.3824   // (8 Hz + 19 Hz, Q=0.7) median 1/p99\n//   AM_LFO_NORM    = 20.3633   // (11 Hz + 23 Hz, Q=0.6) median 1/p99\n//\n// Why median-of-1/p99 and not the numpy-style per-buffer divide?  Real-time\n// gen~ cannot afford a percentile pass over a future buffer. The constants\n// produce a long-run 99th-percentile peak \u2248 1.0 within \u00b13 % across seeds,\n// which keeps depth-multiplication semantics intact (depth \u00b7 lfo \u2248 \u00b1depth\n// 99 % of the time, with rare ~1.4\u00d7 outliers preserved per design-doc).\n//\n// Why these and not RMS-target / abs-peak-target normalization?\n//   * RMS-target: 99th-percentile peak \u2248 3\u20134\u00d7 depth \u2192 blows past the spec'd\n//     pitch ceiling (~50 c) and AM ceiling (~6 dB pk-pk).\n//   * Abs-peak-target: single-sample outliers drag mean swing down \u2192 noon\n//     undershoots audibility floor.\n//   * 99th-percentile-peak: stable middle ground (design-doc \u00a710 row 12).\n//\n// Sample-rate dependence: the biquad coefficients shift with samplerate, so\n// the bare 1/p99 also shifts.  Measured at 48 kHz the scalars come out\n// within ~3 % of the 44.1 kHz values (filter behavior is dominated by the\n// LP cutoff, which scales with fc/sr \u2014 same band-shape, similar variance).\n// Acceptable for v0; if a tighter sr-correction is needed we can promote\n// these to per-sample expressions of the form k/sqrt(samplerate) once the\n// taper is finalized.  Pitfall #4 \u2014 coefficient recompute on sr change is\n// handled by the biquad-coefficient block below.\n//\n// ---------------------------------------------------------------------\n// Buffer-sharing decision:\n//\n//   Spec \u00a7MODULE 5 + Phase-1.5 reconciliation say tl_flutter and tl_wow\n//   share a single [buffer~ tape_loss_delay].  In gen~, sharing requires\n//   `Buffer tape_loss_delay;` referencing the patcher-level buffer object.\n//\n//   For v0 we use **PRIVATE Delay buffers** here (delbuf_L, delbuf_R).\n//   Rationale:\n//     - bit-identity to the numpy reference is unreachable in real-time\n//       anyway (different RNG, different sr-dependent norm scalar);\n//     - private Delay is well-trodden (matches tl_wow.gendsp's strategy);\n//     - shared-buffer wiring is a patcher-level concern that the\n//       integration agent will reconcile in tl_flutter.maxpat (the stub\n//       there already wires through tapin~/tapout~ \u2014 those will be\n//       removed when the codebox absorbs the variable-delay read).\n//\n//   buffer_sharing_strategy = \"private\"  (audit emission flag).\n//\n//   If/when the integration agent decides to share, replace the\n//   `Delay delbuf_L(BUF_SAMPS); Delay delbuf_R(BUF_SAMPS);` declarations\n//   with `Buffer tape_loss_delay;` and adjust the .write/.read calls to\n//   use Buffer's positional read/poke API. Coordinates with tl_wow's gen\n//   DSL would then be by offset position in the same buffer.\n//\n// ---------------------------------------------------------------------\n// classic_mode interpretation:\n//\n//   classic_mode = 0 \u2192 full mode (pitch + AM).\n//   classic_mode = 1 \u2192 AM stage bypassed; pitch path **unchanged** (rates,\n//                       depth, taper all identical between modes).\n//\n//   Source: design-doc \u00a76 reading of spec line 528 (\"Classic Mode Flutter:\n//   Pitch modulation only, no AM path\").  Signed off by user.\n//\n//   Implementation: a soft mux `(classic_mode != 0) ? y_pitched : y_full`.\n//   Note this is a hard switch, not a crossfade \u2014 pitfall #16 says use a\n//   crossfade in M4L `selector~`, but the M4L wrapper does the crossfade\n//   externally (see tl_flutter.maxpat's `selector~ 2` after the AM `*~`).\n//   Inside gen~, the hard switch is fine because the bool toggle change\n//   is rate-limited at the patcher level.\n// =====================================================================\n\nParam flutter(0.0);\nParam classic_mode(0);\nHistory pL1_x1, pL1_x2, pL1_y1, pL1_y2;\nHistory pL2_x1, pL2_x2, pL2_y1, pL2_y2;\nHistory pR1_x1, pR1_x2, pR1_y1, pR1_y2;\nHistory pR2_x1, pR2_x2, pR2_y1, pR2_y2;\nHistory aL1_x1, aL1_x2, aL1_y1, aL1_y2;\nHistory aL2_x1, aL2_x2, aL2_y1, aL2_y2;\nHistory aR1_x1, aR1_x2, aR1_y1, aR1_y2;\nHistory aR2_x1, aR2_x2, aR2_y1, aR2_y2;\n\n\n// --- Constants -------------------------------------------------------\n\n// Base mean delay (seconds). Matches numpy ref _BASE_DELAY_S = 5e-3.\nBASE_DELAY_S = 0.005;\n\n// Round-2 sqrt taper maxima (design-doc \u00a713b).\nPITCH_DEPTH_MAX_S = 1.5e-4;   // pitch_depth = PITCH_DEPTH_MAX_S * sqrt(flutter)\nAM_DEPTH_MAX      = 0.25;     // am_depth   = AM_DEPTH_MAX      * sqrt(flutter)\n\n// Pitch-mod LFO band cutoffs (Hz) and Q. Two bands per channel, summed.\nPITCH_FC1_HZ = 8.0;\nPITCH_FC2_HZ = 19.0;\nPITCH_Q      = 0.7;\n\n// AM-mod LFO band cutoffs (Hz) and Q. Offset from pitch bands so AM does\n// not exactly track pitch \u2014 real tape: different mechanical sources.\nAM_FC1_HZ = 11.0;\nAM_FC2_HZ = 23.0;\nAM_Q      = 0.6;\n\n// 99th-percentile-peak normalization scalars (see header block; empirical\n// medians across 8 seeds \u00d7 30 s of biquad-filtered noise at 44.1 kHz).\nPITCH_LFO_NORM = 21.3824;\nAM_LFO_NORM    = 20.3633;\n\n// Short-circuit / safety epsilons.\nEPS = 1e-6;\n\n// Variable-delay buffer length (samples). At 96 kHz worst-case mean delay\n// + max pitch swing is (5 + 0.15) ms \u00b7 96000 \u2248 495 samples; we round up\n// generously to 4096 for headroom and Lagrange-4 footprint. (See design-\n// doc \u00a75: \"Spec \u00a7MODULE 4 sets `tapin~ 100ms`. Our buffer comfortably\n// fits.\")\nBUF_SAMPS = 4096.0;\n\n// Two pi.\nTWO_PI = 6.28318530717958647693;\n\n// --- LFO biquad state (History) --------------------------------------\n//\n// Each `noise()` call site in gen~ produces an independent pseudo-random\n// stream, so the four pitch streams (2 channels \u00d7 2 bands) and four AM\n// streams (2 channels \u00d7 2 bands) are mutually decorrelated without any\n// seed plumbing.  Eight biquads total, each in Direct-Form-I (4 taps).\n\n// Pitch path L \u2014 band 1 (8 Hz)\n// Pitch path L \u2014 band 2 (19 Hz)\n// Pitch path R \u2014 band 1\n// Pitch path R \u2014 band 2\n// AM path L \u2014 band 1 (11 Hz)\n// AM path L \u2014 band 2 (23 Hz)\n// AM path R \u2014 band 1\n// AM path R \u2014 band 2\n\n// --- Variable-delay buffers (PRIVATE \u2014 see header) -------------------\nDelay delbuf_L(4096);\nDelay delbuf_R(4096);\n\n// =====================================================================\n// Per-sample DSP\n// =====================================================================\n\n// ----- RBJ LPF biquad coefficients (recomputed per sample; sr-aware) --\n//\n// H(z) = (b0 + b1\u00b7z\u207b\u00b9 + b2\u00b7z\u207b\u00b2) / (1 + a1\u00b7z\u207b\u00b9 + a2\u00b7z\u207b\u00b2),  a0 = 1\n//\n//   \u03c90 = 2\u03c0 \u00b7 fc / Fs\n//   \u03b1  = sin(\u03c90) / (2Q)\n//   b0 = (1 - cos \u03c90) / 2,  b1 = 1 - cos \u03c90,  b2 = b0\n//   a0 = 1 + \u03b1,  a1 = -2 cos \u03c90,  a2 = 1 - \u03b1\n//\n// `samplerate` is a gen~ keyword \u2014 coefficients track sr changes per\n// pitfall #4. Recomputed per sample (cheap; cosine \u2248 1 op on M-series).\n\n// Pitch band 1 (8 Hz, Q=0.7)\nw0_p1     = TWO_PI * PITCH_FC1_HZ / samplerate;\ncw_p1     = cos(w0_p1);\nalpha_p1  = sin(w0_p1) / (2.0 * PITCH_Q);\na0_p1     = 1.0 + alpha_p1;\npb0_1     = ((1.0 - cw_p1) * 0.5) / a0_p1;\npb1_1     = (1.0 - cw_p1)         / a0_p1;\npb2_1     = pb0_1;\npa1_1     = (-2.0 * cw_p1)        / a0_p1;\npa2_1     = (1.0 - alpha_p1)      / a0_p1;\n\n// Pitch band 2 (19 Hz, Q=0.7)\nw0_p2     = TWO_PI * PITCH_FC2_HZ / samplerate;\ncw_p2     = cos(w0_p2);\nalpha_p2  = sin(w0_p2) / (2.0 * PITCH_Q);\na0_p2     = 1.0 + alpha_p2;\npb0_2     = ((1.0 - cw_p2) * 0.5) / a0_p2;\npb1_2     = (1.0 - cw_p2)         / a0_p2;\npb2_2     = pb0_2;\npa1_2     = (-2.0 * cw_p2)        / a0_p2;\npa2_2     = (1.0 - alpha_p2)      / a0_p2;\n\n// AM band 1 (11 Hz, Q=0.6)\nw0_a1     = TWO_PI * AM_FC1_HZ / samplerate;\ncw_a1     = cos(w0_a1);\nalpha_a1  = sin(w0_a1) / (2.0 * AM_Q);\na0_a1     = 1.0 + alpha_a1;\nab0_1     = ((1.0 - cw_a1) * 0.5) / a0_a1;\nab1_1     = (1.0 - cw_a1)         / a0_a1;\nab2_1     = ab0_1;\naa1_1     = (-2.0 * cw_a1)        / a0_a1;\naa2_1     = (1.0 - alpha_a1)      / a0_a1;\n\n// AM band 2 (23 Hz, Q=0.6)\nw0_a2     = TWO_PI * AM_FC2_HZ / samplerate;\ncw_a2     = cos(w0_a2);\nalpha_a2  = sin(w0_a2) / (2.0 * AM_Q);\na0_a2     = 1.0 + alpha_a2;\nab0_2     = ((1.0 - cw_a2) * 0.5) / a0_a2;\nab1_2     = (1.0 - cw_a2)         / a0_a2;\nab2_2     = ab0_2;\naa1_2     = (-2.0 * cw_a2)        / a0_a2;\naa2_2     = (1.0 - alpha_a2)      / a0_a2;\n\n// ----- Pitch LFO, channel L ------------------------------------------\n//\n// Direct-Form-I biquad: y = b0 x + b1 x[-1] + b2 x[-2] - a1 y[-1] - a2 y[-2]\n// Independent noise() per band \u21d2 band 1 and band 2 streams are decorrelated.\n\nnPL1 = noise();\nyPL1 = pb0_1 * nPL1 + pb1_1 * pL1_x1 + pb2_1 * pL1_x2\n                    - pa1_1 * pL1_y1 - pa2_1 * pL1_y2;\npL1_x2 = pL1_x1; pL1_x1 = nPL1;\npL1_y2 = pL1_y1; pL1_y1 = yPL1;\n\nnPL2 = noise();\nyPL2 = pb0_2 * nPL2 + pb1_2 * pL2_x1 + pb2_2 * pL2_x2\n                    - pa1_2 * pL2_y1 - pa2_2 * pL2_y2;\npL2_x2 = pL2_x1; pL2_x1 = nPL2;\npL2_y2 = pL2_y1; pL2_y1 = yPL2;\n\n// avg of the two bands \u2192 \u00b7 norm scalar \u2192 \u2248 \u00b11 with p99 = 1.0\nlfo_p_L = 0.5 * (yPL1 + yPL2) * PITCH_LFO_NORM;\n\n// ----- Pitch LFO, channel R ------------------------------------------\n\nnPR1 = noise();\nyPR1 = pb0_1 * nPR1 + pb1_1 * pR1_x1 + pb2_1 * pR1_x2\n                    - pa1_1 * pR1_y1 - pa2_1 * pR1_y2;\npR1_x2 = pR1_x1; pR1_x1 = nPR1;\npR1_y2 = pR1_y1; pR1_y1 = yPR1;\n\nnPR2 = noise();\nyPR2 = pb0_2 * nPR2 + pb1_2 * pR2_x1 + pb2_2 * pR2_x2\n                    - pa1_2 * pR2_y1 - pa2_2 * pR2_y2;\npR2_x2 = pR2_x1; pR2_x1 = nPR2;\npR2_y2 = pR2_y1; pR2_y1 = yPR2;\n\nlfo_p_R = 0.5 * (yPR1 + yPR2) * PITCH_LFO_NORM;\n\n// ----- AM LFO, channel L ---------------------------------------------\n\nnAL1 = noise();\nyAL1 = ab0_1 * nAL1 + ab1_1 * aL1_x1 + ab2_1 * aL1_x2\n                    - aa1_1 * aL1_y1 - aa2_1 * aL1_y2;\naL1_x2 = aL1_x1; aL1_x1 = nAL1;\naL1_y2 = aL1_y1; aL1_y1 = yAL1;\n\nnAL2 = noise();\nyAL2 = ab0_2 * nAL2 + ab1_2 * aL2_x1 + ab2_2 * aL2_x2\n                    - aa1_2 * aL2_y1 - aa2_2 * aL2_y2;\naL2_x2 = aL2_x1; aL2_x1 = nAL2;\naL2_y2 = aL2_y1; aL2_y1 = yAL2;\n\nlfo_a_L = 0.5 * (yAL1 + yAL2) * AM_LFO_NORM;\n\n// ----- AM LFO, channel R ---------------------------------------------\n\nnAR1 = noise();\nyAR1 = ab0_1 * nAR1 + ab1_1 * aR1_x1 + ab2_1 * aR1_x2\n                    - aa1_1 * aR1_y1 - aa2_1 * aR1_y2;\naR1_x2 = aR1_x1; aR1_x1 = nAR1;\naR1_y2 = aR1_y1; aR1_y1 = yAR1;\n\nnAR2 = noise();\nyAR2 = ab0_2 * nAR2 + ab1_2 * aR2_x1 + ab2_2 * aR2_x2\n                    - aa1_2 * aR2_y1 - aa2_2 * aR2_y2;\naR2_x2 = aR2_x1; aR2_x1 = nAR2;\naR2_y2 = aR2_y1; aR2_y1 = yAR2;\n\nlfo_a_R = 0.5 * (yAR1 + yAR2) * AM_LFO_NORM;\n\n// ----- Round-2 sqrt depth tapers -------------------------------------\n//\n//   pitch_depth_seconds = 1.5e-4 \u00b7 sqrt(flutter)\n//   am_depth            = 0.25   \u00b7 sqrt(flutter)\n//\n// Round-1 used `1.2e-4 \u00b7 f\u00b2` (pitch) and `0.20 \u00b7 f` (AM) \u2014 quadratic /\n// linear, which under-shot the chord-noon audibility floor (~5\u20136 c pitch\n// p99, ~2.7 dB AM pk-pk at f=0.5).  Sqrt is concave: lots at low values,\n// plateau at high.  See design-doc \u00a713b for the full retune rationale.\n\nf               = clamp(flutter, 0.0, 1.0);\nsqf             = sqrt(f);\npitch_depth_s   = PITCH_DEPTH_MAX_S * sqf;\nam_depth        = AM_DEPTH_MAX      * sqf;\n\n// ----- Variable-delay read (Lagrange-4) ------------------------------\n//\n//   D[n] = (BASE_DELAY_S + pitch_depth_s \u00b7 lfo_p) \u00b7 samplerate    [samples]\n//\n// Defensive: never let D go below 1 (need xm1) or above BUF_SAMPS-4.\n\nbase_samp     = BASE_DELAY_S * samplerate;\npdepth_samp   = pitch_depth_s * samplerate;\n\nD_L = base_samp + pdepth_samp * lfo_p_L;\nD_R = base_samp + pdepth_samp * lfo_p_R;\n\nD_L = clamp(D_L, 1.0, BUF_SAMPS - 4.0);\nD_R = clamp(D_R, 1.0, BUF_SAMPS - 4.0);\n\n// Write current input to delay buffers.\ndelbuf_L.write(in1);\ndelbuf_R.write(in2);\n\n// Integer & fractional split of the requested delay.\niD_L  = floor(D_L);\nfD_L  = D_L - iD_L;\niD_R  = floor(D_R);\nfD_R  = D_R - iD_R;\n\n// Four-tap reads centered on the integer delay (drop-sample inside each\n// .read; the Lagrange kernel below does the fractional interpolation).\nxm1_L = delbuf_L.read(iD_L - 1.0, \"step\");\nx0_L  = delbuf_L.read(iD_L,        \"step\");\nx1_L  = delbuf_L.read(iD_L + 1.0,  \"step\");\nx2_L  = delbuf_L.read(iD_L + 2.0,  \"step\");\n\nxm1_R = delbuf_R.read(iD_R - 1.0, \"step\");\nx0_R  = delbuf_R.read(iD_R,        \"step\");\nx1_R  = delbuf_R.read(iD_R + 1.0,  \"step\");\nx2_R  = delbuf_R.read(iD_R + 2.0,  \"step\");\n\n// ----- Lagrange-4 kernel (JOS PASP) ----------------------------------\n//\n//   c_m1 = -frac \u00b7 (frac - 1) \u00b7 (frac - 2) / 6\n//   c_0  =  (frac + 1) \u00b7 (frac - 1) \u00b7 (frac - 2) / 2\n//   c_p1 = -(frac + 1) \u00b7 frac      \u00b7 (frac - 2) / 2\n//   c_p2 =  (frac + 1) \u00b7 frac      \u00b7 (frac - 1) / 6\n//\n// Channel L\nfL_m1 = fD_L - 1.0;\nfL_m2 = fD_L - 2.0;\nfL_p1 = fD_L + 1.0;\ncL_m1 = -fD_L * fL_m1 * fL_m2 / 6.0;\ncL_0  =  fL_p1 * fL_m1 * fL_m2 / 2.0;\ncL_p1 = -fL_p1 * fD_L  * fL_m2 / 2.0;\ncL_p2 =  fL_p1 * fD_L  * fL_m1 / 6.0;\ny_pitched_L = cL_m1 * xm1_L + cL_0 * x0_L + cL_p1 * x1_L + cL_p2 * x2_L;\n\n// Channel R\nfR_m1 = fD_R - 1.0;\nfR_m2 = fD_R - 2.0;\nfR_p1 = fD_R + 1.0;\ncR_m1 = -fD_R * fR_m1 * fR_m2 / 6.0;\ncR_0  =  fR_p1 * fR_m1 * fR_m2 / 2.0;\ncR_p1 = -fR_p1 * fD_R  * fR_m2 / 2.0;\ncR_p2 =  fR_p1 * fD_R  * fR_m1 / 6.0;\ny_pitched_R = cR_m1 * xm1_R + cR_0 * x0_R + cR_p1 * x1_R + cR_p2 * x2_R;\n\n// ----- AM stage (gated by classic_mode) ------------------------------\n//\n//   multiplier = 1 + am_depth \u00b7 lfo_a\n//   y = classic_mode ? y_pitched : y_pitched \u00b7 multiplier\n//\n// Clamp the multiplier to [0, 2] to prevent any phase inversion if the\n// LFO has an unusually large outlier (matches numpy ref np.clip path).\n\nmult_L = clamp(1.0 + am_depth * lfo_a_L, 0.0, 2.0);\nmult_R = clamp(1.0 + am_depth * lfo_a_R, 0.0, 2.0);\n\ny_full_L = y_pitched_L * mult_L;\ny_full_R = y_pitched_R * mult_R;\n\ncm = (classic_mode != 0);\n\ny_L = cm ? y_pitched_L : y_full_L;\ny_R = cm ? y_pitched_R : y_full_R;\n\n// ----- Short-circuit (bit-identical bypass at flutter = 0) -----------\n//\n// Numpy ref invariant: `flutter <= 0.0` \u2192 output \u2261 input, no RNG draws.\n// In gen~ we cannot un-advance the noise() streams, but the mux makes\n// the OUTPUT bit-identical, which is what the verified-property check\n// measures.  EPS guards against denormal-tier residuals in the param.\n\nshort = (f <= EPS);\n\nout1 = short ? in1 : y_L;\nout2 = short ? in2 : y_R;\n\n// =====================================================================\n// END tl_flutter.gendsp  (TUNING_VERSION = 2)\n// =====================================================================\n"
								}
							},
							{
								"box": {
									"id": "tl_flutter-gen-out1",
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
									"id": "tl_flutter-gen-out2",
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
										"tl_flutter-gen-in1",
										0
									],
									"destination": [
										"tl_flutter-gen-codebox",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_flutter-gen-in2",
										0
									],
									"destination": [
										"tl_flutter-gen-codebox",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_flutter-gen-codebox",
										0
									],
									"destination": [
										"tl_flutter-gen-out1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_flutter-gen-codebox",
										1
									],
									"destination": [
										"tl_flutter-gen-out2",
										0
									]
								}
							}
						]
					},
					"rnboattrcache": {},
					"saved_object_attributes": {
						"exportfolder": "",
						"exportname": "tl_flutter_lfos",
						"wantsoutputcore": 0
					}
				}
			},
			{
				"box": {
					"id": "tl_flutter-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						180,
						700,
						60
					],
					"text": "tl_flutter (SANDBOX-PARTIAL): fast pitch + AM. gen~ owns full audio path (internal Delay primitives). Pitch LFO (8+19 Hz), AM LFO (11+23 Hz). classic_mode = AM-bypass-only (divergence #8, pitch unchanged). Phase 1.5 buffer-share divergence: private Delay vs shared tape_loss_delay."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_flutter-in-L",
						0
					],
					"destination": [
						"tl_flutter-gen",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_flutter-in-R",
						0
					],
					"destination": [
						"tl_flutter-gen",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_flutter-gen",
						0
					],
					"destination": [
						"tl_flutter-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_flutter-gen",
						1
					],
					"destination": [
						"tl_flutter-out-R",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_flutter",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}