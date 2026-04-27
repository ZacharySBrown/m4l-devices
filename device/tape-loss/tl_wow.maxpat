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
					"id": "tl_wow-in-L",
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
					"id": "tl_wow-in-R",
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
					"id": "tl_wow-pin-0",
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
					"id": "tl_wow-pin-1",
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
					"id": "tl_wow-out-L",
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
					"id": "tl_wow-out-R",
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
					"id": "tl_wow-gen",
					"maxclass": "newobj",
					"numinlets": 3,
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
					"text": "gen~ @title tl_wow_lfo",
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
							500.0
						],
						"boxes": [
							{
								"box": {
									"id": "tl_wow-gen-codebox",
									"maxclass": "codebox",
									"numinlets": 3,
									"numoutlets": 2,
									"outlettype": [
										"signal",
										"signal"
									],
									"patching_rect": [
										50.0,
										50.0,
										600.0,
										400.0
									],
									"text": "// =====================================================================\n// tl_wow.gendsp \u2014 gen~ DSL source for the WOW module of tape-loss\n// =====================================================================\n//\n// Module       : tl_wow (Generation Loss MKII \"WOW\" knob)\n// Authored     : 2026-04-27 (Phase 2.5 \u2014 gen~ translation)\n// Author       : pedal-engineer (auto-authored from numpy reference)\n// Source files :\n//   design-doc        : docs/design-docs/dsp/tl-wow-design.md\n//                       sha256: b8c61c53822509337cafb95b9b406d730f5a64c\n//                               cddfa0fb2619898e0f850c44ea\n//   numpy reference   : dsp/reference/tl_wow.py\n//                       sha256: d38076e8ebbbb1bb53e276129f6d764002e02396\n//                               d3828d7e4aa2a7ea117f62f9\n//   parent maxpat stub: device/tape-loss/tl_wow.maxpat (3-inlet contract)\n//\n// Inlets  (3): in1 = signal L, in2 = signal R, in3 = pitch_floor_cents\n//                                                   (control rate, cents)\n// Outlets (2): out1 = signal L, out2 = signal R\n// Params  (1): wow \u2208 [0, 1]    (default 0.0)\n//\n// ---------------------------------------------------------------------\n// Algorithm summary (translated 1:1 from dsp/reference/tl_wow.py):\n//\n//   Per channel:\n//     n1  = noise()                           // independent stream / chan\n//     n2  = noise()                           // second cutoff stream\n//     m_a = onepole_lpf(onepole_lpf(n1, fc=0.5 Hz))   // 12 dB/oct\n//     m_b = onepole_lpf(onepole_lpf(n2, fc=0.7 Hz))   // 12 dB/oct\n//     m_main = (m_a + m_b) * 0.5 * UNIT_PEAK_GAIN     // \u2248 \u00b11\n//\n//     // Phase 1.5 floor LFO (independent \u2014 different cutoff & noise()):\n//     n_f   = noise()\n//     m_flr = onepole_lpf(onepole_lpf(n_f, fc=0.4 Hz))  // 12 dB/oct\n//     m_flr = m_flr * UNIT_PEAK_GAIN                    // \u2248 \u00b11\n//\n//     // Depth tapers\n//     A_main  = A_MAX_SECONDS * (0.30*w\u00b2 + 0.70*w\u00b3)        // seconds\n//     A_floor = pitch_floor_cents / (1731.234 * 4.39)      // seconds\n//\n//     // Combined delay-time signal (seconds \u2192 samples)\n//     D(t) = (BASE_DELAY_S + A_main*m_main + A_floor*m_flr) * samplerate\n//\n//     // Variable delay read: 4-point cubic Hermite (Catmull-Rom form)\n//     write delbuf[n] = x[n]\n//     read  y[n]      = hermite_4pt(delbuf, write_idx - D, frac)\n//\n//     // Short-circuit: bit-identical passthrough when both paths are\n//     // off; preserves the round-1 wow=0 invariant when floor=0 too.\n//     short = (wow <= EPS) && (pitch_floor_cents <= EPS)\n//     out   = if short then x else y\n//\n// ---------------------------------------------------------------------\n// Sanity-check expectations (matches design-doc \u00a75 + \u00a713.5 calibration):\n//\n//   wow=0.0, pitch_floor=0.0  \u2192  bit-identical passthrough (SHORT path)\n//   wow=0.5, pitch_floor=0.0  \u2192  \u2248 \u00b113 c peak  (spec target ~\u00b115 c)\n//   wow=1.0, pitch_floor=0.0  \u2192  \u2248 \u00b170 c peak  (spec target ~\u00b170 c)\n//   wow=0.0, pitch_floor=0.3  \u2192  \u2248 \u00b10.3 c peak (independent floor only)\n//\n// ---------------------------------------------------------------------\n// Hermite kernel (Catmull-Rom form) \u2014 matches numpy ref _hermite_4pt():\n//\n//   c0 = x0\n//   c1 = 0.5 * (x1 - xm1)\n//   c2 = xm1 - 2.5*x0 + 2.0*x1 - 0.5*x2\n//   c3 = 0.5 * (x2 - xm1) + 1.5 * (x0 - x1)\n//   y  = ((c3*frac + c2)*frac + c1)*frac + c0\n//\n// Reference: Niemitalo, \"Polynomial Interpolators for High-Quality\n// Resampling of Oversampled Audio\" (yehar.com, 2001); JOS PASP\n// \"Interpolation\" appendix. Frequency loss at fc=0.5\u00b7Nyquist \u2248 -0.01 dB.\n//\n// ---------------------------------------------------------------------\n// Notes on divergences from the spec sketch (signed-off in design-doc):\n//   * BASE_DELAY = 25 ms (NOT 5 ms). Required headroom for A_max=6 ms\n//     so D(t) stays > 0 across all wow values.\n//   * Per-vector LFO peak normalization (numpy) is replaced by a fixed\n//     gain of 1.0 / 0.95 \u2248 1.0526 (UNIT_PEAK_GAIN). Realtime-safe; see\n//     design-doc \u00a79 (\"Per-vector LFO peak-normalize in Python only\").\n// =====================================================================\n\nParam wow 0.0;\n\n// --- Constants -------------------------------------------------------\n\n// Base mean delay (seconds). Spec divergence #4: 25 ms (not 5 ms).\nBASE_DELAY_S = 0.025;\n\n// Peak modulation amplitude (seconds) at wow=1.0. Calibrated against\n// the multi-seed Hilbert-IF measurement to land at ~\u00b170 c (spec target).\nA_MAX_SECONDS = 0.006;\n\n// LFO cutoffs.\nLFO_FC1_HZ = 0.5;\nLFO_FC2_HZ = 0.7;\nPITCH_FLOOR_LFO_FC_HZ = 0.4;\n\n// Cents-to-delay-derivative conversion: 1200 / ln(2).\nCENTS_PER_DD_DT = 1731.234;\n\n// Empirical |dm/dt|_peak for the floor LFO topology (mean of 20 seeds,\n// 6 s windows). Used to invert the small-shift Doppler relation:\n//     A_floor = pitch_floor_cents / (CENTS_PER_DD_DT \u00b7 this).\nPITCH_FLOOR_DM_DT_PEAK_PER_S = 4.39;\n\n// LFO peak compensation factor \u2014 fixed gain replacing the numpy ref's\n// per-vector peak-normalize. Mean peak \u2248 0.95 \u2192 scale \u2248 1.0526.\nUNIT_PEAK_GAIN = 1.0526;\n\n// Short-circuit epsilon \u2014 guard against denormal-tier residuals.\nEPS = 1e-6;\n\n// --- LFO state (History) ---------------------------------------------\n//\n// Per-channel decorrelation strategy: each `noise()` call site in gen~\n// produces an INDEPENDENT pseudo-random stream. So separate History\n// chains driving separate `noise()` reads is sufficient to guarantee\n// uncorrelated L/R LFOs without any seed plumbing.\n\n// Main wow path, channel L \u2014 two cascaded 1-pole stages \u00d7 two cutoffs.\nHistory lp1L_a, lp1L_b;   // 0.5 Hz cascade (stages a, b)\nHistory lp2L_a, lp2L_b;   // 0.7 Hz cascade\n\n// Main wow path, channel R.\nHistory lp1R_a, lp1R_b;\nHistory lp2R_a, lp2R_b;\n\n// Floor (pitch_floor) path, channel L \u2014 single cascaded 1-pole at 0.4 Hz.\nHistory lpFL_a, lpFL_b;\n\n// Floor path, channel R.\nHistory lpFR_a, lpFR_b;\n\n// --- Delay buffers ---------------------------------------------------\n//\n// Sized for worst-case at 96 kHz: ceil((25 + 6 + ~0.05) ms \u00b7 96000) + 16\n// \u2248 2982 samples. We round up generously to 8192 for headroom and to\n// fit any future depth bump cleanly.\n\nDelay delbuf_L(8192);\nDelay delbuf_R(8192);\n\n// =====================================================================\n// Per-sample DSP\n// =====================================================================\n\n// ----- LFO coefficients (recomputed per sample; samplerate-aware) -----\n//\n// 1-pole LPF coefficient: a = 1 - exp(-2*pi*fc/sr).\n// `samplerate` is a gen DSL keyword; this stays correct across SR changes.\ntwo_pi = 2.0 * 3.14159265358979323846;\na_fc1   = 1.0 - exp(-two_pi * LFO_FC1_HZ            / samplerate);\na_fc2   = 1.0 - exp(-two_pi * LFO_FC2_HZ            / samplerate);\na_floor = 1.0 - exp(-two_pi * PITCH_FLOOR_LFO_FC_HZ / samplerate);\n\n// ----- Channel L main LFO --------------------------------------------\nnL1 = noise();                                  // independent stream\nlp1L_a = lp1L_a + a_fc1 * (nL1    - lp1L_a);\nlp1L_b = lp1L_b + a_fc1 * (lp1L_a - lp1L_b);    // cascade \u2192 12 dB/oct\nmL_a = lp1L_b;\n\nnL2 = noise();\nlp2L_a = lp2L_a + a_fc2 * (nL2    - lp2L_a);\nlp2L_b = lp2L_b + a_fc2 * (lp2L_a - lp2L_b);\nmL_b = lp2L_b;\n\nm_main_L = 0.5 * (mL_a + mL_b) * UNIT_PEAK_GAIN;\n\n// ----- Channel R main LFO --------------------------------------------\nnR1 = noise();\nlp1R_a = lp1R_a + a_fc1 * (nR1    - lp1R_a);\nlp1R_b = lp1R_b + a_fc1 * (lp1R_a - lp1R_b);\nmR_a = lp1R_b;\n\nnR2 = noise();\nlp2R_a = lp2R_a + a_fc2 * (nR2    - lp2R_a);\nlp2R_b = lp2R_b + a_fc2 * (lp2R_a - lp2R_b);\nmR_b = lp2R_b;\n\nm_main_R = 0.5 * (mR_a + mR_b) * UNIT_PEAK_GAIN;\n\n// ----- Floor (pitch_floor_cents) LFO, both channels -------------------\nnFL = noise();                                  // independent of main\nlpFL_a = lpFL_a + a_floor * (nFL    - lpFL_a);\nlpFL_b = lpFL_b + a_floor * (lpFL_a - lpFL_b);\nm_floor_L = lpFL_b * UNIT_PEAK_GAIN;\n\nnFR = noise();\nlpFR_a = lpFR_a + a_floor * (nFR    - lpFR_a);\nlpFR_b = lpFR_b + a_floor * (lpFR_a - lpFR_b);\nm_floor_R = lpFR_b * UNIT_PEAK_GAIN;\n\n// ----- Depth tapers ---------------------------------------------------\n//\n// Main wow:  A(w) = A_MAX_SECONDS \u00b7 (0.30\u00b7w\u00b2 + 0.70\u00b7w\u00b3)\nw  = clamp(wow, 0.0, 1.0);\nw2 = w * w;\nw3 = w2 * w;\nA_main_sec = A_MAX_SECONDS * (0.30 * w2 + 0.70 * w3);\n\n// Floor: A_floor = pitch_floor_cents / (1731.234 \u00b7 4.39) [seconds]\n// in3 carries pitch_floor_cents (control rate; treated as signal here).\npfc = max(in3, 0.0);\nA_floor_sec = pfc / (CENTS_PER_DD_DT * PITCH_FLOOR_DM_DT_PEAK_PER_S);\n\n// Convert seconds \u2192 samples (samplerate-aware).\nbase_samp    = BASE_DELAY_S * samplerate;\na_main_samp  = A_main_sec   * samplerate;\na_floor_samp = A_floor_sec  * samplerate;\n\n// Total delay-time signal (samples). Note: floor & main are SUMMED into\n// the SAME delay-time signal (one delay read per channel), per the\n// numpy ref's _process_channel logic \u2014 NOT a separate read.\nD_L = base_samp + a_main_samp * m_main_L + a_floor_samp * m_floor_L;\nD_R = base_samp + a_main_samp * m_main_R + a_floor_samp * m_floor_R;\n\n// Clamp delay to safe Hermite range: need \u2265 1 sample history (xm1) and\n// \u2264 buf_len - 4 (so x2 stays inside the buffer).\nD_L = clamp(D_L, 1.0, 8192.0 - 4.0);\nD_R = clamp(D_R, 1.0, 8192.0 - 4.0);\n\n// ----- Variable-delay write/read with 4-point Hermite ----------------\n//\n// gen~'s Delay primitive writes the inlet value automatically each\n// sample; reads via `delbuf.read(d, kind)` where `d` is a fractional\n// number of samples behind the current write position. We do four\n// reads at d-1, d, d+1, d+2 (drop-sample interpolation inside each\n// read), then apply the Catmull-Rom Hermite kernel for the fractional\n// position.\n\n// Write current input.\ndelbuf_L.write(in1);\ndelbuf_R.write(in2);\n\n// Integer & fractional split of the requested delay.\niD_L  = floor(D_L);\nfD_L  = D_L - iD_L;\niD_R  = floor(D_R);\nfD_R  = D_R - iD_R;\n\n// Four-tap reads (drop-sample inside the .read call \u2014 the Hermite\n// kernel handles the fractional interpolation across these samples).\nxm1_L = delbuf_L.read(iD_L - 1.0, \"step\");\nx0_L  = delbuf_L.read(iD_L,        \"step\");\nx1_L  = delbuf_L.read(iD_L + 1.0,  \"step\");\nx2_L  = delbuf_L.read(iD_L + 2.0,  \"step\");\n\nxm1_R = delbuf_R.read(iD_R - 1.0, \"step\");\nx0_R  = delbuf_R.read(iD_R,        \"step\");\nx1_R  = delbuf_R.read(iD_R + 1.0,  \"step\");\nx2_R  = delbuf_R.read(iD_R + 2.0,  \"step\");\n\n// Hermite-4 (Catmull-Rom) \u2014 bit-for-bit equivalent to numpy ref\n// _hermite_4pt(). Position frac is the fractional part of the read\n// offset between samples x0 and x1.\n//\n// NOTE: numpy ref uses read_pos_f = write_idx - D, so x0 sits at\n// read_pos_f, and the kernel's frac is read_pos_f - floor(read_pos_f).\n// gen~ Delay.read(d, ...) reads `d` samples behind write, so x0 sits\n// at offset iD_L (= floor(D_L)) and frac is fD_L. Same orientation.\nc0_L = x0_L;\nc1_L = 0.5 * (x1_L - xm1_L);\nc2_L = xm1_L - 2.5 * x0_L + 2.0 * x1_L - 0.5 * x2_L;\nc3_L = 0.5 * (x2_L - xm1_L) + 1.5 * (x0_L - x1_L);\ny_L  = ((c3_L * fD_L + c2_L) * fD_L + c1_L) * fD_L + c0_L;\n\nc0_R = x0_R;\nc1_R = 0.5 * (x1_R - xm1_R);\nc2_R = xm1_R - 2.5 * x0_R + 2.0 * x1_R - 0.5 * x2_R;\nc3_R = 0.5 * (x2_R - xm1_R) + 1.5 * (x0_R - x1_R);\ny_R  = ((c3_R * fD_R + c2_R) * fD_R + c1_R) * fD_R + c0_R;\n\n// ----- Short-circuit (bit-identical bypass) ---------------------------\n//\n// When wow == 0 AND pitch_floor_cents == 0, we MUST emit the input\n// unchanged \u2014 the round-1 invariant. Both flags off \u2192 bypass the\n// delay-line read entirely (the delay buffer keeps writing, which is\n// fine; only the OUTPUT mux is short-circuited).\nshort = (w <= EPS) && (pfc <= EPS);\n\nout1 = (short != 0) ? in1 : y_L;\nout2 = (short != 0) ? in2 : y_R;\n\n// =====================================================================\n// END tl_wow.gendsp\n// =====================================================================\n"
								}
							}
						],
						"lines": []
					},
					"rnboattrcache": {},
					"saved_object_attributes": {
						"exportfolder": "",
						"exportname": "tl_wow_lfo",
						"wantsoutputcore": 0
					}
				}
			},
			{
				"box": {
					"id": "tl_wow-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						180,
						700,
						60
					],
					"text": "tl_wow (SANDBOX-PARTIAL): variable-delay slow random pitch drift. gen~ owns full audio path (internal Delay primitives + 4-pt Hermite read). Base D0=25ms (spec divergence #7), A_max=6ms at wow=1.0. Filtered-noise LFO (0.5+0.7 Hz cutoffs). Cross-module: pitch_floor_cents inlet (=0.3 when model=11). Phase 1.5 buffer-share divergence: private Delay vs shared tape_loss_delay."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_wow-in-L",
						0
					],
					"destination": [
						"tl_wow-gen",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_wow-in-R",
						0
					],
					"destination": [
						"tl_wow-gen",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_wow-pin-1",
						0
					],
					"destination": [
						"tl_wow-gen",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_wow-gen",
						0
					],
					"destination": [
						"tl_wow-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_wow-gen",
						1
					],
					"destination": [
						"tl_wow-out-R",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_wow",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}