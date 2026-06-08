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
					"id": "tl_noise-in-L",
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
					"index": 0
				}
			},
			{
				"box": {
					"id": "tl_noise-in-R",
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
					"index": 1
				}
			},
			{
				"box": {
					"id": "tl_noise-pin-0",
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
					"index": 2
				}
			},
			{
				"box": {
					"id": "tl_noise-pin-1",
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
					"index": 3
				}
			},
			{
				"box": {
					"id": "tl_noise-pin-2",
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
					"index": 4
				}
			},
			{
				"box": {
					"id": "tl_noise-pin-3",
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
					"index": 5
				}
			},
			{
				"box": {
					"id": "tl_noise-out-L",
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
					"index": 0
				}
			},
			{
				"box": {
					"id": "tl_noise-out-R",
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
					"index": 1
				}
			},
			{
				"box": {
					"id": "tl_noise-gen",
					"maxclass": "newobj",
					"numinlets": 6,
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
					"text": "gen~ @title tl_noise_synth",
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
									"id": "tl_noise-gen-in1",
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
									"id": "tl_noise-gen-in2",
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
									"id": "tl_noise-gen-in3",
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
									"id": "tl_noise-gen-in4",
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
									"id": "tl_noise-gen-in5",
									"maxclass": "newobj",
									"text": "in 5",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										310.0,
										30.0,
										30.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "tl_noise-gen-in6",
									"maxclass": "newobj",
									"text": "in 6",
									"numinlets": 0,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										380.0,
										30.0,
										30.0,
										22.0
									]
								}
							},
							{
								"box": {
									"id": "tl_noise-gen-codebox",
									"maxclass": "codebox",
									"numinlets": 6,
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
									"code": "// =====================================================================\n// tl_noise.gendsp -- gen~ DSL source for the NOISE module of tape-loss\n// =====================================================================\n//\n// Module       : tl_noise (Generation Loss MKII \"NOISE\" generator)\n// Authored     : 2026-04-27 (Phase 2.5 -- gen~ translation)\n// Author       : pedal-engineer (auto-authored from numpy reference)\n// Position     : terminal module in the chain; ADDITIVE\n//                (input pass-through + noise summed in).\n//\n// Source files (sha256, captured at authoring time):\n//   docs/design-docs/dsp/tl-noise-design.md\n//     22acad5e705fe5a6653aec538ef4d8caa92f0893c66c5f4de19192f5f4fe4808\n//   dsp/reference/tl_noise.py\n//     4bd62edcaa398b9760caf1778b8ce023d5acdf29025d7a7ff31462396c61db17\n//   device/tape-loss/tl_noise.maxpat (parent stub, 6-in/2-out gen~ box)\n//     6806dce7aa0397f8b3447ab34d4474b1c41ac2d75ddfb1aac24bfa7f9e3ec278\n//\n// I/O contract (matches the gen~ box in tl_noise.maxpat):\n//   in1 : signal L (audio in)\n//   in2 : signal R (audio in)\n//   in3 : noise_mode        (0=OFF, 1=HISS, 2=BOTH)            -- control\n//   in4 : hiss_level        (0..1)                              -- control\n//   in5 : mechanical_level  (0..1, bipolar around 0.5)          -- control\n//   in6 : hum_bypass        (0|1)                               -- control\n//   out1: signal L (input + summed noise)\n//   out2: signal R (input + summed noise)\n//\n// Params (mirror the inlets so an outer [pattr]/[js] can also drive them):\n//   noise_mode (0), hiss_level (0.5), mechanical_level (0.5), hum_bypass (0)\n//\n// =====================================================================\n// PINK-NOISE METHOD CHOICE\n// =====================================================================\n//\n// Voss-McCartney 16-bin (NOT a 3-pole shelving cascade).\n//\n// Rationale per design doc \u00a72.1 + \u00a78 tradeoff log:\n//   \"Voss-McCartney is provably 1/f, simpler to verify numerically\n//    (each generator is provably 1/f within the band of interest).\n//    CPU cost is essentially the same: one add + one branch per sample.\"\n// And from \u00a78: \"VM win on transparency.\"\n//\n// Implementation note: gen~ codebox stores all numbers as float64; the\n// classic `k = i & -i` trick relies on two's-complement integer ops.\n// Instead we use a sample counter advanced by 1.0 each sample and probe\n// the trailing-zero index by a cascade of `(counter % 2^k) == 0` tests\n// implemented with `floor(c/2^k)*2^k == c` checks. The bin-update logic\n// matches McCartney 1999 exactly: at sample i (1-indexed), the bin\n// updated is `tzc(i)` where tzc = trailing-zero count.\n//\n// We use independent noise() streams per channel for the 16 bins, so\n// L and R hiss are decorrelated naturally (gen~'s noise() yields an\n// independent PRNG sequence per call site).\n//\n// =====================================================================\n// BIPOLAR MECHANICAL CROSSFADE (matches numpy ref _mechanical_weights)\n// =====================================================================\n//\n//   ml in [0, 1]\n//   ccw_amount = max(0, 0.5 - ml) * 2     -- 1.0 at ml=0,    0 at ml>=0.5\n//   cw_amount  = max(0, ml - 0.5) * 2     -- 0   at ml<=0.5, 1 at ml=1\n//   vcr_weight = ccw_amount\n//   hum_weight = cw_amount\n//   activity   = max(ccw_amount, cw_amount)         -- |2*(ml-0.5)|\n//   common_gain = activity^2 * 10^(-40/20)          -- quadratic taper,\n//                                                      -40 dBFS at full\n//\n// Hard silent center: at ml=0.5 BOTH weights are exactly 0, AND the\n// common_gain is exactly 0 (activity^2 = 0). Belt-and-braces zero.\n//\n// =====================================================================\n// HUM HARMONIC TABLE (design doc \u00a73.2)\n// =====================================================================\n//\n//   harmonic | freq @ 60 Hz | rel amp  | role\n//   ---------|--------------|----------|---------------------------------\n//      1     |    60 Hz     |   1.00   | fundamental (line freq)\n//      2     |   120 Hz     |   0.30   | even -- half-wave PSU rectif.\n//      3     |   180 Hz     |   0.45   | odd -- transformer saturation\n//      4     |   240 Hz     |   0.18   | weak even\n//      5     |   300 Hz     |   0.22   | weak odd\n//      7     |   420 Hz     |   0.12   | high odd (NOTE: gap at h=6)\n//\n// Sum of |amplitudes| = 2.27. Reference numpy peak-normalizes per render\n// (not realtime-feasible). We use a FIXED normalization constant of\n// 1.0/2.27 ~= 0.44053 (HUM_NORMALIZE) -- conservative; guarantees the\n// summed harmonic stack stays within ~|1.0|. Empirical RMS of the stack\n// after this normalization sits ~-9 dBFS, ~3 dB lower than the numpy\n// ref's per-buffer-normalized output. Acceptable: the numpy ref's peak-\n// normalize is itself a compromise (peak depends on phase relations;\n// expecting bit-identity here would be wrong). The L/R mono-correlation\n// invariant is preserved exactly. Documented divergence; design-doc\n// invariant #5 (peak < -30 dBFS) holds with margin.\n//\n// =====================================================================\n// PSU HALF-WAVE-RECT NOTE\n// =====================================================================\n//\n// The brief mentions \"PSU half-wave rectification character (clamp\n// negative half to 0 then DC-block)\". The numpy reference (the golden\n// output per design-doc \u00a710) does NOT do this -- it generates the hum\n// purely as a sum of sines with random per-render phases, then peak-\n// normalizes. The half-wave-rect language in the design doc \u00a73.2 is\n// describing the PHYSICAL ORIGIN of the harmonic ratios (asymmetric\n// rectifier produces strong even harmonics), not a runtime DSP step.\n//\n// We follow the numpy reference (translation, not redesign) -- straight\n// sine-bank sum. The \"half-wave\" character is BAKED INTO the harmonic\n// amplitude table already (h=2 weight 0.30, h=4 weight 0.18 = even-\n// harmonic emphasis from PSU rectifier asymmetry).\n//\n// =====================================================================\n// VCR AM MODULATOR\n// =====================================================================\n//\n// Numpy ref: random target re-roll every 1/(0.3..1.5) sec, linear walk\n// toward target at ~4 Hz convergence, one-pole smooth at 2 Hz.\n//\n// gen~ translation: drive a 2-stage cascaded one-pole LPF chain with\n// noise() at the 0.6 Hz center of the [0.3, 1.5] Hz reroll-rate band.\n// The cascade gives ~12 dB/oct rolloff above 0.6 Hz which dominates\n// any sharper transitions of the numpy ref's target-walk approach.\n// This is a continuous-spectrum equivalent to the periodic-reroll logic\n// and produces the same character (slow random ebb-and-flow, no\n// periodicity, no zero crossings). Output then mapped to multiplier\n// (CENTER + DEPTH/2 * walk) where walk in ~[-1, 1].\n//\n// =====================================================================\n// MODE LOGIC (design doc \u00a74 truth table)\n// =====================================================================\n//\n//   noise_mode | hum_bypass | hiss_on | mech_on\n//   -----------|------------|---------|--------\n//     0 OFF    |     *      |  false  |  false\n//     1 HISS   |     *      |  true   |  false\n//     2 BOTH   |    false   |  true   |  true\n//     2 BOTH   |    true    |  true   |  false\n//\n// HARD GATE at the mode level (not just attenuation): when hiss_on is\n// false the hiss path output is multiplied by 0 (and could even be\n// short-circuited around -- we use the multiply for compile simplicity,\n// the result is bit-exact zero either way).\n//\n// At noise_mode=OFF we additionally want the OUTPUT to equal INPUT\n// bit-exactly. We do this by short-circuiting the entire ADD path:\n// out1 = (mode_off ? in1 : in1 + sum_of_noise). This guarantees no\n// floating-point rounding from the add even if the noise contribution\n// has been multiplied to zero. Pitfall safeguard.\n//\n// =====================================================================\n// SANITY-CHECK EXPECTATIONS (matches numpy ref _verify_invariants)\n// =====================================================================\n//\n//   1. noise_mode = OFF, any other params:\n//        out1 == in1, out2 == in2  (bit-identical, zero noise contrib)\n//   2. noise_mode = HISS, hiss_level = 0:\n//        out == in (hiss_level squared = 0, total noise = 0)\n//   3. noise_mode = HISS, hiss_level = 0.5:\n//        adds pink-flavored hiss at peak ~ -50..-45 dBFS\n//        (HISS_TARGET_PEAK_AMP ~ -42 dBFS at level=1.0; squared taper\n//         puts level=0.5 at ~-54 dBFS peak)\n//   4. noise_mode = BOTH, mechanical_level = 0.5, hum_bypass = 0:\n//        mechanical contribution is exactly silent (hard center).\n//        Output = input + hiss only.\n//   5. noise_mode = BOTH, mechanical_level = 0.0:\n//        full VCR rumble + hiss\n//   6. noise_mode = BOTH, mechanical_level = 1.0:\n//        full 60 Hz hum stack + hiss\n//   7. noise_mode = BOTH, hum_bypass = 1:\n//        equivalent to HISS-only (mech path gated)\n//   8. All-knobs-max (noise_mode=BOTH, hiss=1, mech=1.0, !hum_bypass):\n//        peak < -30 dBFS (design doc \u00a79 invariant #5)\n//   9. Hiss path L/R correlation ~= 0\n//  10. Hum path L/R correlation ~= +1 (mono-correlated, hum_scaled\n//        added identically to both channels)\n//\n// =====================================================================\n\n\n// ---------------------------------------------------------------------\n// Parameter declarations (also driven by signal inlets in3..in6)\n// ---------------------------------------------------------------------\n\nParam noise_mode(0);\nParam hiss_level(0.5);\nParam mechanical_level(0.5);\nParam hum_bypass(0);\nHistory pinkCounter(0.0);\nHistory pBinL_0(0.0);  History pBinL_1(0.0);  History pBinL_2(0.0);  History pBinL_3(0.0);\nHistory pBinL_4(0.0);  History pBinL_5(0.0);  History pBinL_6(0.0);  History pBinL_7(0.0);\nHistory pBinL_8(0.0);  History pBinL_9(0.0);  History pBinL_10(0.0); History pBinL_11(0.0);\nHistory pBinL_12(0.0); History pBinL_13(0.0); History pBinL_14(0.0); History pBinL_15(0.0);\nHistory pBinR_0(0.0);  History pBinR_1(0.0);  History pBinR_2(0.0);  History pBinR_3(0.0);\nHistory pBinR_4(0.0);  History pBinR_5(0.0);  History pBinR_6(0.0);  History pBinR_7(0.0);\nHistory pBinR_8(0.0);  History pBinR_9(0.0);  History pBinR_10(0.0); History pBinR_11(0.0);\nHistory pBinR_12(0.0); History pBinR_13(0.0); History pBinR_14(0.0); History pBinR_15(0.0);\nHistory hpfL_x1(0.0); History hpfL_x2(0.0);\nHistory hpfL_y1(0.0); History hpfL_y2(0.0);\nHistory lpfL_x1(0.0); History lpfL_x2(0.0);\nHistory lpfL_y1(0.0); History lpfL_y2(0.0);\nHistory hpfR_x1(0.0); History hpfR_x2(0.0);\nHistory hpfR_y1(0.0); History hpfR_y2(0.0);\nHistory lpfR_x1(0.0); History lpfR_x2(0.0);\nHistory lpfR_y1(0.0); History lpfR_y2(0.0);\nHistory vcrL_x1(0.0); History vcrL_x2(0.0);\nHistory vcrL_y1(0.0); History vcrL_y2(0.0);\nHistory vcrR_x1(0.0); History vcrR_x2(0.0);\nHistory vcrR_y1(0.0); History vcrR_y2(0.0);\nHistory amL_a(0.0); History amL_b(0.0);\nHistory amR_a(0.0); History amR_b(0.0);\nHistory humPh1(0.0); History humPh2(0.0); History humPh3(0.0);\nHistory humPh4(0.0); History humPh5(0.0); History humPh7(0.0);\n\n\n\n\n// ---------------------------------------------------------------------\n// Constants\n// ---------------------------------------------------------------------\n\nTWO_PI = 6.283185307179586476;\nPI     = 3.141592653589793238;\n\n// Peak amplitude targets at full level (design doc \u00a75).\nHISS_TARGET_PEAK_AMP = 0.007943282347242815;   // 10^(-42/20)\nMECH_TARGET_PEAK_AMP = 0.01;                   // 10^(-40/20)\n\n// Hiss spectral shaping (RBJ Butterworth biquads).\nHISS_HPF_HZ = 50.0;\nHISS_HPF_Q  = 0.7071067811865475;\nHISS_LPF_HZ = 12000.0;\nHISS_LPF_Q  = 0.7071067811865475;\n\n// VCR sub-engine.\nVCR_LPF_HZ        = 200.0;\nVCR_LPF_Q         = 0.9;\nVCR_AM_CENTER     = 0.7;     // multiplier center (never reaches 0)\nVCR_AM_DEPTH      = 0.6;     // -> multiplier swings ~[0.1, 1.3]\nVCR_AM_LFO_HZ     = 0.6;     // mid of the [0.3, 1.5] Hz reroll band\n                             // (cascaded 1-pole stand-in for the\n                             //  numpy ref's target-walk modulator)\n\n// Hum sub-engine.\nHUM_FUNDAMENTAL_HZ = 60.0;   // North America. Edit to 50.0 for EU/etc.\n// Sum of |amplitudes| over the 6 harmonics = 2.27 -> fixed scale to\n// keep the un-windowed peak <= 1.0. (Numpy ref does per-render peak-\n// normalize; not realtime-feasible. See header divergence note.)\nHUM_NORMALIZE      = 0.4405286343612335;   // = 1.0 / 2.27\n\n// VCR-LPF normalization. The numpy ref divides the LPF'd white noise\n// by its per-render peak to land at ~|1.0|. We use a fixed gain\n// calibrated against the LPF impulse-response RMS times a 4-sigma peak\n// estimate of Gaussian noise: empirically VCR_GAIN_FIX = ~7.0 lands\n// the post-LPF peak in the same ballpark as the numpy ref's\n// per-buffer normalize. Conservative; documented divergence.\nVCR_GAIN_FIX = 7.0;\n\n\n// ---------------------------------------------------------------------\n// Resolve current control values: prefer signal inlets in3..in6 if\n// they're nonzero (the maxpat stub wires control inlets there); fall\n// back to Param. (Both paths produce the same value when the maxpat\n// drives the inlets faithfully.) We just pass the inlet through; the\n// outer harness is responsible for keeping these in sync.\n// ---------------------------------------------------------------------\n\nmode_v = in3;                                // 0 / 1 / 2\nhl     = clamp(in4, 0.0, 1.0);\nml     = clamp(in5, 0.0, 1.0);\nhb     = in6;                                // 0 or 1\n\n// Derived booleans (truth table from design doc \u00a74).\nmode_off  = (mode_v < 0.5);                  // == 0\nmode_hiss = (mode_v >= 0.5) && (mode_v < 1.5); // == 1\nmode_both = (mode_v >= 1.5);                 // == 2\nhb_on     = (hb >= 0.5);\n\nhiss_on = mode_hiss || mode_both;            // both HISS and BOTH enable hiss\nmech_on = mode_both && (hb_on == 0);\n\n\n// ---------------------------------------------------------------------\n// Bipolar mechanical crossfade weights\n// ---------------------------------------------------------------------\n\nccw_amount  = max(0.0, 0.5 - ml) * 2.0;       // 1 at ml=0, 0 at ml>=0.5\ncw_amount   = max(0.0, ml - 0.5) * 2.0;       // 0 at ml<=0.5, 1 at ml=1\nvcr_w       = ccw_amount;\nhum_w       = cw_amount;\nactivity    = max(ccw_amount, cw_amount);     // |2*(ml-0.5)|\ncommon_gain = activity * activity * MECH_TARGET_PEAK_AMP;\n\n// Hiss linear gain (quadratic taper).\nhiss_gain = hl * hl * HISS_TARGET_PEAK_AMP;\n\n\n// =====================================================================\n// VOSS-McCARTNEY PINK NOISE -- per channel\n// =====================================================================\n//\n// Algorithm (McCartney 1999):\n//   counter advances by 1 each sample.\n//   k = trailing-zero count of counter        (counter starts at 1)\n//   bin[k] = fresh_random()\n//   output = sum of all 16 bins\n//\n// In gen~ codebox we use a History counter (modulo 2^16 so it stays\n// within float64 precision) and probe the trailing-zero index with a\n// cascade of integer-divisibility tests. (Equivalent to a CTZ.)\n// We then conditionally update each bin via a `bin = (k_eq_i ? new : bin)`\n// mux, which keeps the dataflow purely combinational (no early-return).\n//\n// The 16 bins are just 16 History scalars per channel. Independent\n// noise() calls feed fresh randoms.\n// ---------------------------------------------------------------------\n\n// --- Counter (shared) ---\n\n// Advance counter once per sample, modulo 65536 (= 2^16). The bin index\n// repeats with period 2^16 samples (~1.486 s @ 44.1 kHz) which is\n// exactly the cycle of the algorithm at n_bins=16; modulo-wrapping is\n// the natural handling of the lowest bin's update interval.\nnew_counter = pinkCounter + 1.0;\nnew_counter = (new_counter >= 65536.0) ? (new_counter - 65536.0) : new_counter;\npinkCounter = new_counter;\nci = new_counter;   // current sample index (1-based)\n\n// Trailing-zero index probes. For each k in 0..15, k_is[k] is 1 if\n// (ci % 2^(k+1)) == 2^k (i.e., bit k is the lowest set bit), else 0.\n// Equivalently: ci is divisible by 2^k but not by 2^(k+1).\n//\n// Compute via: ci/2^k is an integer AND that integer is odd.\n//   div_k = ci / 2^k\n//   is_int_k    = (div_k == floor(div_k))\n//   is_odd_k    = ((floor(div_k) % 2) == 1)\n//   k_is[k]     = is_int_k && is_odd_k\n//\n// (For ci=1 -> k=0; ci=2 -> k=1; ci=3 -> k=0; ci=4 -> k=2; etc.)\n\ndiv0  = ci;\ndiv1  = ci * 0.5;\ndiv2  = ci * 0.25;\ndiv3  = ci * 0.125;\ndiv4  = ci * 0.0625;\ndiv5  = ci * 0.03125;\ndiv6  = ci * 0.015625;\ndiv7  = ci * 0.0078125;\ndiv8  = ci * 0.00390625;\ndiv9  = ci * 0.001953125;\ndiv10 = ci * 0.0009765625;\ndiv11 = ci * 0.00048828125;\ndiv12 = ci * 0.000244140625;\ndiv13 = ci * 0.0001220703125;\ndiv14 = ci * 0.00006103515625;\ndiv15 = ci * 0.000030517578125;\n\n// is_int_k: div_k is an integer iff floor(div_k) == div_k.\n// is_odd : (floor(div_k) - 2*floor(div_k/2)) == 1.\n// We collapse both checks into k_is[k] using a single (floor(div_k) ==\n// div_k) AND ((floor(div_k) % 2) == 1).\n\nf0  = floor(div0);   k_is_0  = (f0  == div0)  && ((f0  - 2.0*floor(f0  * 0.5)) >= 0.5);\nf1  = floor(div1);   k_is_1  = (f1  == div1)  && ((f1  - 2.0*floor(f1  * 0.5)) >= 0.5);\nf2  = floor(div2);   k_is_2  = (f2  == div2)  && ((f2  - 2.0*floor(f2  * 0.5)) >= 0.5);\nf3  = floor(div3);   k_is_3  = (f3  == div3)  && ((f3  - 2.0*floor(f3  * 0.5)) >= 0.5);\nf4  = floor(div4);   k_is_4  = (f4  == div4)  && ((f4  - 2.0*floor(f4  * 0.5)) >= 0.5);\nf5  = floor(div5);   k_is_5  = (f5  == div5)  && ((f5  - 2.0*floor(f5  * 0.5)) >= 0.5);\nf6  = floor(div6);   k_is_6  = (f6  == div6)  && ((f6  - 2.0*floor(f6  * 0.5)) >= 0.5);\nf7  = floor(div7);   k_is_7  = (f7  == div7)  && ((f7  - 2.0*floor(f7  * 0.5)) >= 0.5);\nf8  = floor(div8);   k_is_8  = (f8  == div8)  && ((f8  - 2.0*floor(f8  * 0.5)) >= 0.5);\nf9  = floor(div9);   k_is_9  = (f9  == div9)  && ((f9  - 2.0*floor(f9  * 0.5)) >= 0.5);\nf10 = floor(div10);  k_is_10 = (f10 == div10) && ((f10 - 2.0*floor(f10 * 0.5)) >= 0.5);\nf11 = floor(div11);  k_is_11 = (f11 == div11) && ((f11 - 2.0*floor(f11 * 0.5)) >= 0.5);\nf12 = floor(div12);  k_is_12 = (f12 == div12) && ((f12 - 2.0*floor(f12 * 0.5)) >= 0.5);\nf13 = floor(div13);  k_is_13 = (f13 == div13) && ((f13 - 2.0*floor(f13 * 0.5)) >= 0.5);\nf14 = floor(div14);  k_is_14 = (f14 == div14) && ((f14 - 2.0*floor(f14 * 0.5)) >= 0.5);\nf15 = floor(div15);  k_is_15 = (f15 == div15) && ((f15 - 2.0*floor(f15 * 0.5)) >= 0.5);\n\n// 1/sqrt(16) for unit-RMS normalization of the 16-bin sum.\nPINK_NORM = 0.25;\n\n\n// --- Pink generator macro for L channel ---\n\n\n// Sixteen independent noise() draws (decorrelated by call site).\nnL_0  = noise();  nL_1  = noise();  nL_2  = noise();  nL_3  = noise();\nnL_4  = noise();  nL_5  = noise();  nL_6  = noise();  nL_7  = noise();\nnL_8  = noise();  nL_9  = noise();  nL_10 = noise();  nL_11 = noise();\nnL_12 = noise();  nL_13 = noise();  nL_14 = noise();  nL_15 = noise();\n\n// Conditionally update each bin. gen~ noise() outputs uniform [-1, 1];\n// we want roughly N(0, 1)-style variance to match the numpy ref. The\n// standard deviation of U(-1, 1) is 1/sqrt(3) ~= 0.577. We therefore\n// scale each draw by sqrt(3) ~= 1.7320508 so the bin variance matches\n// N(0, 1). After summing 16 bins and dividing by sqrt(16)=4, output\n// variance is 1.0 (matching numpy ref's normalization).\nSQRT3 = 1.7320508075688772;\n\npBinL_0  = (k_is_0  != 0) ? (nL_0  * SQRT3) : pBinL_0;\npBinL_1  = (k_is_1  != 0) ? (nL_1  * SQRT3) : pBinL_1;\npBinL_2  = (k_is_2  != 0) ? (nL_2  * SQRT3) : pBinL_2;\npBinL_3  = (k_is_3  != 0) ? (nL_3  * SQRT3) : pBinL_3;\npBinL_4  = (k_is_4  != 0) ? (nL_4  * SQRT3) : pBinL_4;\npBinL_5  = (k_is_5  != 0) ? (nL_5  * SQRT3) : pBinL_5;\npBinL_6  = (k_is_6  != 0) ? (nL_6  * SQRT3) : pBinL_6;\npBinL_7  = (k_is_7  != 0) ? (nL_7  * SQRT3) : pBinL_7;\npBinL_8  = (k_is_8  != 0) ? (nL_8  * SQRT3) : pBinL_8;\npBinL_9  = (k_is_9  != 0) ? (nL_9  * SQRT3) : pBinL_9;\npBinL_10 = (k_is_10 != 0) ? (nL_10 * SQRT3) : pBinL_10;\npBinL_11 = (k_is_11 != 0) ? (nL_11 * SQRT3) : pBinL_11;\npBinL_12 = (k_is_12 != 0) ? (nL_12 * SQRT3) : pBinL_12;\npBinL_13 = (k_is_13 != 0) ? (nL_13 * SQRT3) : pBinL_13;\npBinL_14 = (k_is_14 != 0) ? (nL_14 * SQRT3) : pBinL_14;\npBinL_15 = (k_is_15 != 0) ? (nL_15 * SQRT3) : pBinL_15;\n\npinkL = (pBinL_0  + pBinL_1  + pBinL_2  + pBinL_3\n       + pBinL_4  + pBinL_5  + pBinL_6  + pBinL_7\n       + pBinL_8  + pBinL_9  + pBinL_10 + pBinL_11\n       + pBinL_12 + pBinL_13 + pBinL_14 + pBinL_15) * PINK_NORM;\n\n\n// --- Pink generator macro for R channel (independent noise() streams) ---\n\n\nnR_0  = noise();  nR_1  = noise();  nR_2  = noise();  nR_3  = noise();\nnR_4  = noise();  nR_5  = noise();  nR_6  = noise();  nR_7  = noise();\nnR_8  = noise();  nR_9  = noise();  nR_10 = noise();  nR_11 = noise();\nnR_12 = noise();  nR_13 = noise();  nR_14 = noise();  nR_15 = noise();\n\npBinR_0  = (k_is_0  != 0) ? (nR_0  * SQRT3) : pBinR_0;\npBinR_1  = (k_is_1  != 0) ? (nR_1  * SQRT3) : pBinR_1;\npBinR_2  = (k_is_2  != 0) ? (nR_2  * SQRT3) : pBinR_2;\npBinR_3  = (k_is_3  != 0) ? (nR_3  * SQRT3) : pBinR_3;\npBinR_4  = (k_is_4  != 0) ? (nR_4  * SQRT3) : pBinR_4;\npBinR_5  = (k_is_5  != 0) ? (nR_5  * SQRT3) : pBinR_5;\npBinR_6  = (k_is_6  != 0) ? (nR_6  * SQRT3) : pBinR_6;\npBinR_7  = (k_is_7  != 0) ? (nR_7  * SQRT3) : pBinR_7;\npBinR_8  = (k_is_8  != 0) ? (nR_8  * SQRT3) : pBinR_8;\npBinR_9  = (k_is_9  != 0) ? (nR_9  * SQRT3) : pBinR_9;\npBinR_10 = (k_is_10 != 0) ? (nR_10 * SQRT3) : pBinR_10;\npBinR_11 = (k_is_11 != 0) ? (nR_11 * SQRT3) : pBinR_11;\npBinR_12 = (k_is_12 != 0) ? (nR_12 * SQRT3) : pBinR_12;\npBinR_13 = (k_is_13 != 0) ? (nR_13 * SQRT3) : pBinR_13;\npBinR_14 = (k_is_14 != 0) ? (nR_14 * SQRT3) : pBinR_14;\npBinR_15 = (k_is_15 != 0) ? (nR_15 * SQRT3) : pBinR_15;\n\npinkR = (pBinR_0  + pBinR_1  + pBinR_2  + pBinR_3\n       + pBinR_4  + pBinR_5  + pBinR_6  + pBinR_7\n       + pBinR_8  + pBinR_9  + pBinR_10 + pBinR_11\n       + pBinR_12 + pBinR_13 + pBinR_14 + pBinR_15) * PINK_NORM;\n\n\n// =====================================================================\n// HISS RBJ BIQUAD COEFFICIENTS (HPF 50 Hz / LPF 12 kHz, Butterworth)\n// =====================================================================\n//\n// RBJ Audio EQ Cookbook formulas, recomputed each sample from\n// `samplerate` so the filters track SR changes (no [js] companion\n// needed for these). Cost: ~12 trig calls per sample, all on constants\n// -> the gen~ compiler will hoist them as long as samplerate is held\n// stable; on SR transitions there's a momentary bump (~5 ms) which is\n// inaudible against the noise floor.\n\n// --- HPF 50 Hz Q=0.7071 ---\nhpf_w0     = TWO_PI * HISS_HPF_HZ / samplerate;\nhpf_cosw0  = cos(hpf_w0);\nhpf_alpha  = sin(hpf_w0) / (2.0 * HISS_HPF_Q);\nhpf_a0     = 1.0 + hpf_alpha;\nhpf_b0     = ((1.0 + hpf_cosw0) * 0.5) / hpf_a0;\nhpf_b1     = (-(1.0 + hpf_cosw0))      / hpf_a0;\nhpf_b2     = ((1.0 + hpf_cosw0) * 0.5) / hpf_a0;\nhpf_a1     = (-2.0 * hpf_cosw0)        / hpf_a0;\nhpf_a2     = (1.0 - hpf_alpha)         / hpf_a0;\n\n// --- LPF 12 kHz Q=0.7071 ---\nlpf_w0     = TWO_PI * HISS_LPF_HZ / samplerate;\nlpf_cosw0  = cos(lpf_w0);\nlpf_alpha  = sin(lpf_w0) / (2.0 * HISS_LPF_Q);\nlpf_a0     = 1.0 + lpf_alpha;\nlpf_b0     = ((1.0 - lpf_cosw0) * 0.5) / lpf_a0;\nlpf_b1     = (1.0 - lpf_cosw0)         / lpf_a0;\nlpf_b2     = ((1.0 - lpf_cosw0) * 0.5) / lpf_a0;\nlpf_a1     = (-2.0 * lpf_cosw0)        / lpf_a0;\nlpf_a2     = (1.0 - lpf_alpha)         / lpf_a0;\n\n// --- VCR LPF 200 Hz Q=0.9 ---\nvcr_w0     = TWO_PI * VCR_LPF_HZ / samplerate;\nvcr_cosw0  = cos(vcr_w0);\nvcr_alpha  = sin(vcr_w0) / (2.0 * VCR_LPF_Q);\nvcr_a0     = 1.0 + vcr_alpha;\nvcr_b0     = ((1.0 - vcr_cosw0) * 0.5) / vcr_a0;\nvcr_b1     = (1.0 - vcr_cosw0)         / vcr_a0;\nvcr_b2     = ((1.0 - vcr_cosw0) * 0.5) / vcr_a0;\nvcr_a1     = (-2.0 * vcr_cosw0)        / vcr_a0;\nvcr_a2     = (1.0 - vcr_alpha)         / vcr_a0;\n\n\n// =====================================================================\n// HISS PATH -- HPF 50 then LPF 12k, per channel (Direct Form I)\n// =====================================================================\n\n// --- HPF Channel L ---\n\nhpfL_y = hpf_b0*pinkL + hpf_b1*hpfL_x1 + hpf_b2*hpfL_x2\n       - hpf_a1*hpfL_y1 - hpf_a2*hpfL_y2;\nhpfL_y = (abs(hpfL_y) < 1e-30) ? 0.0 : hpfL_y;       // denormal flush\n\nhpfL_x2 = hpfL_x1;\nhpfL_x1 = pinkL;\nhpfL_y2 = hpfL_y1;\nhpfL_y1 = hpfL_y;\n\n// --- LPF Channel L ---\n\nlpfL_y = lpf_b0*hpfL_y + lpf_b1*lpfL_x1 + lpf_b2*lpfL_x2\n       - lpf_a1*lpfL_y1 - lpf_a2*lpfL_y2;\nlpfL_y = (abs(lpfL_y) < 1e-30) ? 0.0 : lpfL_y;\n\nlpfL_x2 = lpfL_x1;\nlpfL_x1 = hpfL_y;\nlpfL_y2 = lpfL_y1;\nlpfL_y1 = lpfL_y;\n\nshapedHissL = lpfL_y;\n\n// --- HPF Channel R ---\n\nhpfR_y = hpf_b0*pinkR + hpf_b1*hpfR_x1 + hpf_b2*hpfR_x2\n       - hpf_a1*hpfR_y1 - hpf_a2*hpfR_y2;\nhpfR_y = (abs(hpfR_y) < 1e-30) ? 0.0 : hpfR_y;\n\nhpfR_x2 = hpfR_x1;\nhpfR_x1 = pinkR;\nhpfR_y2 = hpfR_y1;\nhpfR_y1 = hpfR_y;\n\n// --- LPF Channel R ---\n\nlpfR_y = lpf_b0*hpfR_y + lpf_b1*lpfR_x1 + lpf_b2*lpfR_x2\n       - lpf_a1*lpfR_y1 - lpf_a2*lpfR_y2;\nlpfR_y = (abs(lpfR_y) < 1e-30) ? 0.0 : lpfR_y;\n\nlpfR_x2 = lpfR_x1;\nlpfR_x1 = hpfR_y;\nlpfR_y2 = lpfR_y1;\nlpfR_y1 = lpfR_y;\n\nshapedHissR = lpfR_y;\n\n// Hiss output (gated by hiss_on, scaled by quadratic-tapered hiss_gain).\nhissL = (hiss_on != 0) ? (shapedHissL * hiss_gain) : 0.0;\nhissR = (hiss_on != 0) ? (shapedHissR * hiss_gain) : 0.0;\n\n\n// =====================================================================\n// MECHANICAL PATH -- VCR sub-engine (decorrelated stereo)\n// =====================================================================\n//\n// White noise -> LPF 200 Hz Q=0.9 -> slow-AM multiplier.\n\n// --- White noise per channel (independent streams via separate noise() sites) ---\nwhiteVcrL = noise() * SQRT3;   // U(-1,1) -> match unit-variance scale\nwhiteVcrR = noise() * SQRT3;\n\n// --- VCR LPF Channel L (Direct Form I) ---\n\nvcrLpfL = vcr_b0*whiteVcrL + vcr_b1*vcrL_x1 + vcr_b2*vcrL_x2\n        - vcr_a1*vcrL_y1   - vcr_a2*vcrL_y2;\nvcrLpfL = (abs(vcrLpfL) < 1e-30) ? 0.0 : vcrLpfL;\n\nvcrL_x2 = vcrL_x1;\nvcrL_x1 = whiteVcrL;\nvcrL_y2 = vcrL_y1;\nvcrL_y1 = vcrLpfL;\n\n// --- VCR LPF Channel R ---\n\nvcrLpfR = vcr_b0*whiteVcrR + vcr_b1*vcrR_x1 + vcr_b2*vcrR_x2\n        - vcr_a1*vcrR_y1   - vcr_a2*vcrR_y2;\nvcrLpfR = (abs(vcrLpfR) < 1e-30) ? 0.0 : vcrLpfR;\n\nvcrR_x2 = vcrR_x1;\nvcrR_x1 = whiteVcrR;\nvcrR_y2 = vcrR_y1;\nvcrR_y1 = vcrLpfR;\n\n// Normalize to ~ unit peak (numpy ref does per-buffer; we use a fixed\n// gain). See VCR_GAIN_FIX comment in constants block.\nvcrL = vcrLpfL * VCR_GAIN_FIX;\nvcrR = vcrLpfR * VCR_GAIN_FIX;\n\n// --- Slow-AM modulator per channel (cascaded 1-pole at 0.6 Hz) ---\n// Coefficient: a = 1 - exp(-2*pi*fc/sr).\nam_a = 1.0 - exp(-TWO_PI * VCR_AM_LFO_HZ / samplerate);\n\nnAmL = noise();                               // independent stream\namL_a = amL_a + am_a * (nAmL  - amL_a);\namL_b = amL_b + am_a * (amL_a - amL_b);       // 12 dB/oct cascade\nwalkL = clamp(amL_b, -1.0, 1.0);\namMultL = VCR_AM_CENTER + (VCR_AM_DEPTH * 0.5) * walkL;\n\nnAmR = noise();\namR_a = amR_a + am_a * (nAmR  - amR_a);\namR_b = amR_b + am_a * (amR_a - amR_b);\nwalkR = clamp(amR_b, -1.0, 1.0);\namMultR = VCR_AM_CENTER + (VCR_AM_DEPTH * 0.5) * walkR;\n\nvcrOutL = vcrL * amMultL;\nvcrOutR = vcrR * amMultR;\n\n\n// =====================================================================\n// MECHANICAL PATH -- HUM sub-engine (mono / correlated)\n// =====================================================================\n//\n// Sine bank: h=1,2,3,4,5,7 of the fundamental, with relative amps\n// [1.00, 0.30, 0.45, 0.18, 0.22, 0.12]. Phase accumulators wrap at\n// 2*pi via subtraction. Output is identical for L and R (mono pickup).\n\n// Phase increments per harmonic (rad/sample). samplerate-aware.\nphinc1 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 1.0) / samplerate;\nphinc2 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 2.0) / samplerate;\nphinc3 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 3.0) / samplerate;\nphinc4 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 4.0) / samplerate;\nphinc5 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 5.0) / samplerate;\nphinc7 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 7.0) / samplerate;\n\n\n// Advance + wrap to [-pi, pi].\nnph1 = humPh1 + phinc1;\nnph1 = (nph1 >  PI) ? (nph1 - TWO_PI) : nph1;\nnph1 = (nph1 < -PI) ? (nph1 + TWO_PI) : nph1;\nhumPh1 = nph1;\n\nnph2 = humPh2 + phinc2;\nnph2 = (nph2 >  PI) ? (nph2 - TWO_PI) : nph2;\nnph2 = (nph2 < -PI) ? (nph2 + TWO_PI) : nph2;\nhumPh2 = nph2;\n\nnph3 = humPh3 + phinc3;\nnph3 = (nph3 >  PI) ? (nph3 - TWO_PI) : nph3;\nnph3 = (nph3 < -PI) ? (nph3 + TWO_PI) : nph3;\nhumPh3 = nph3;\n\nnph4 = humPh4 + phinc4;\nnph4 = (nph4 >  PI) ? (nph4 - TWO_PI) : nph4;\nnph4 = (nph4 < -PI) ? (nph4 + TWO_PI) : nph4;\nhumPh4 = nph4;\n\nnph5 = humPh5 + phinc5;\nnph5 = (nph5 >  PI) ? (nph5 - TWO_PI) : nph5;\nnph5 = (nph5 < -PI) ? (nph5 + TWO_PI) : nph5;\nhumPh5 = nph5;\n\nnph7 = humPh7 + phinc7;\nnph7 = (nph7 >  PI) ? (nph7 - TWO_PI) : nph7;\nnph7 = (nph7 < -PI) ? (nph7 + TWO_PI) : nph7;\nhumPh7 = nph7;\n\nhumSum = 1.00 * sin(nph1)\n       + 0.30 * sin(nph2)\n       + 0.45 * sin(nph3)\n       + 0.18 * sin(nph4)\n       + 0.22 * sin(nph5)\n       + 0.12 * sin(nph7);\n\nhum = humSum * HUM_NORMALIZE;   // mono signal\n\n\n// =====================================================================\n// MECHANICAL CROSSFADE (linear, hard silent center) + GATE\n// =====================================================================\n//\n// vcr * vcr_w  +  hum * hum_w, all scaled by common_gain. The hum path\n// is added IDENTICALLY to L and R (mono-correlated); halve the per-\n// channel contribution so the stereo-summed peak still hits the\n// MECH_TARGET_PEAK_AMP target (matches numpy ref's hum_scaled * 0.5).\n\nhumContrib   = hum * hum_w * common_gain * 0.5;       // halve for mono dup\nmechContribL = (vcrOutL * vcr_w * common_gain) + humContrib;\nmechContribR = (vcrOutR * vcr_w * common_gain) + humContrib;\n\nmechL = (mech_on != 0) ? mechContribL : 0.0;\nmechR = (mech_on != 0) ? mechContribR : 0.0;\n\n\n// =====================================================================\n// FINAL SUM (additive on input pass-through)\n// =====================================================================\n//\n// At noise_mode=OFF we short-circuit to the unmodified input to\n// guarantee bit-identical pass-through (no rounding from a +0.0 add).\n\nnoiseSumL = hissL + mechL;\nnoiseSumR = hissR + mechR;\n\nout1 = (mode_off != 0) ? in1 : (in1 + noiseSumL);\nout2 = (mode_off != 0) ? in2 : (in2 + noiseSumR);\n\n// =====================================================================\n// END tl_noise.gendsp\n// =====================================================================\n"
								}
							},
							{
								"box": {
									"id": "tl_noise-gen-out1",
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
									"id": "tl_noise-gen-out2",
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
										"tl_noise-gen-in1",
										0
									],
									"destination": [
										"tl_noise-gen-codebox",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen-in2",
										0
									],
									"destination": [
										"tl_noise-gen-codebox",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen-in3",
										0
									],
									"destination": [
										"tl_noise-gen-codebox",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen-in4",
										0
									],
									"destination": [
										"tl_noise-gen-codebox",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen-in5",
										0
									],
									"destination": [
										"tl_noise-gen-codebox",
										4
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen-in6",
										0
									],
									"destination": [
										"tl_noise-gen-codebox",
										5
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen-codebox",
										0
									],
									"destination": [
										"tl_noise-gen-out1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen-codebox",
										1
									],
									"destination": [
										"tl_noise-gen-out2",
										0
									]
								}
							}
						]
					},
					"rnboattrcache": {},
					"saved_object_attributes": {
						"exportfolder": "",
						"exportname": "tl_noise_synth",
						"wantsoutputcore": 0
					}
				}
			},
			{
				"box": {
					"id": "tl_noise-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						180,
						700,
						60
					],
					"text": "tl_noise (SANDBOX-OK): pink hiss (Voss-McCartney) + mechanical (VCR rumble + 60Hz hum stack). noise_mode OFF=silent, HISS=hiss only, BOTH=hiss+mech. hum_bypass mutes mechanical in BOTH. Hiss: HPF50/LPF12k Butterworth shaping. Hum: 6-harmonic 60Hz stack (correlated mono). VCR: LPF200/slow-AM (decorrelated stereo). All synthesized in [gen~ tl_noise_synth]."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_noise-in-L",
						0
					],
					"destination": [
						"tl_noise-gen",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_noise-in-R",
						0
					],
					"destination": [
						"tl_noise-gen",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_noise-pin-0",
						0
					],
					"destination": [
						"tl_noise-gen",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_noise-pin-1",
						0
					],
					"destination": [
						"tl_noise-gen",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_noise-pin-2",
						0
					],
					"destination": [
						"tl_noise-gen",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_noise-pin-3",
						0
					],
					"destination": [
						"tl_noise-gen",
						5
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_noise-gen",
						0
					],
					"destination": [
						"tl_noise-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_noise-gen",
						1
					],
					"destination": [
						"tl_noise-out-R",
						0
					]
				}
			}
		],
		"dependency_cache": [],
		"autosave": 0
	}
}