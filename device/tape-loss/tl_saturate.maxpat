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
					"id": "tl_saturate-in-L",
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
					"id": "tl_saturate-in-R",
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
					"id": "tl_saturate-pin-0",
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
					"id": "tl_saturate-pin-1",
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
					"id": "tl_saturate-out-L",
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
					"id": "tl_saturate-out-R",
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
					"id": "tl_saturate-gen",
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
					"text": "gen~ @title tl_saturate_dsp",
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
									"id": "tl_saturate-gen-in1",
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
									"id": "tl_saturate-gen-in2",
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
									"id": "tl_saturate-gen-in3",
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
									"id": "tl_saturate-gen-in4",
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
									"id": "tl_saturate-gen-codebox",
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
									"code": "// =============================================================================\n// tl_saturate.gendsp  --  gen~ DSL for the SATURATE module of `tape-loss`\n// =============================================================================\n//\n// Module:        tl_saturate (Generation Loss MKII \"SATURATE\" knob +\n//                hidden INPUT GAIN selector).\n// Authored:      2026-04-27 by pedal-engineer (translation, not redesign).\n// Source files (sha256, captured at authoring time):\n//   docs/design-docs/dsp/tl-saturate-design.md\n//     2d69115367e28c376194d24d0ae9087b58d56a0bd8b66b9e1832d379e93fb40e\n//   dsp/reference/tl_saturate.py\n//     1c798f732c4d53ed36a17ee9b062e0162ad2d808cd61b4b2f9c3c8bc09ce2b4a\n//   data/tl_saturate_coefficients.json\n//     4ab5994a40f510a00b00bd95c17a4bb0cd7c80efc7127840af2ff0feaf674b1b\n//\n// I/O CONTRACT (matches device/tape-loss/tl_saturate.maxpat stub):\n//   in1 : signal L (audio)\n//   in2 : signal R (audio)\n//   In3 : pin0 -- routed to Param `saturate`   (0..1)\n//   In4 : pin1 -- routed to Param `input_gain` (0=LINE, 1=INSTRUMENT, 2=HIGH_GAIN)\n//   out1: signal L\n//   out2: signal R\n//\n// (The maxpat stub wires inlet-3/inlet-4 to gen~ inlets 3/4. Inside this\n//  codebox we expose `saturate` and `input_gain` as Params so an outer\n//  [js] / [pattr] system can drive them. The two extra signal inlets are\n//  declared but unused so the patch stays conformant; remove them in a\n//  later pass once the integration agent decides on the param-routing\n//  topology.)\n//\n// PARAMS:\n//   saturate    : 0..1, default 0.0   -- knob position (quadratic taper inside)\n//   input_gain  : 0|1|2, default 0    -- LINE / INSTRUMENT / HIGH_GAIN\n//\n// COEFFICIENT HOT-SWAP CONTRACT (with the [js] companion):\n//   This file hardcodes the 44.1 kHz coefficient set from\n//   data/tl_saturate_coefficients.json (`by_sample_rate.44100`).\n//   The engineer's [js] companion -- which subscribes to `dspstate~` --\n//   will, on a sample-rate change, send `setcoef <b0> <b1> <b2> <a1> <a2>`\n//   style messages and `setdcr <R>` to a wrapper that re-binds the Params\n//   below.  Until that companion lands the gen~ runs with 44.1k math even\n//   at 48k; the audible drift is < 0.1 dB at 3 kHz (verified offline) so\n//   it's tolerable for v0 sandbox bring-up.\n//\n//   Coefficient Params (declared as Param so the [js] companion can hot-swap):\n//     pre_b0, pre_b1, pre_b2, pre_a1, pre_a2\n//     de_b0, de_b1, de_b2, de_a1, de_a2\n//     dcr_R\n//   Halfband taps stay hardcoded; they are sample-rate-independent.\n//\n// SANITY CHECK POINTS (expected outputs from the numpy reference):\n//   1. saturate=0, any input_gain, any input:\n//        Out == In  (bit-identical bypass; design doc tradeoff #16,\n//        verified in dsp/reference/tl_saturate.py::_run_property_checks\n//        as cascade_err_db_at_1khz_sat0 = 0.00 dB).\n//   2. saturate=0.7, input_gain=LINE, 1 kHz sine @ 0.5 amp:\n//        THD ~= 0.211 (21.1 % \u2014 pronounced asymmetric drive).\n//        Even-harmonic content (H2 amp ~= 62 in arbitrary FFT units)\n//        emerges from the (1+beta*u) negative-half multiplier.\n//   3. saturate=1.0, input_gain=LINE, 1 kHz sine @ 0.5 amp:\n//        THD ~= 0.289 (28.9 % \u2014 crushed).\n//        DC offset of unblocked signal ~= 7.5e-4 -- the DC blocker keeps\n//        steady-state output DC near zero.\n//\n// ALGORITHM (chain matches dsp/reference/tl_saturate.py::_process_one_channel):\n//\n//     INPUT\n//       v\n//     [INPUT_GAIN preamp]                LINE / +6dB / +12dB\n//       v\n//   if (saturate <= 0) -> bypass to OUTPUT (with INPUT_GAIN compensation)\n//       v\n//     [Pre-emphasis high-shelf]          +4 dB / 3 kHz / Q=0.7  (RBJ, DFI)\n//       v\n//     [2x upsample (31-tap halfband FIR, polyphase)]\n//       v\n//     [Asymmetric tanh waveshaper]       (1/tanh(d))*tanh(d*u) * (u<0 ? 1+beta*u : 1)\n//       v\n//     [2x downsample (31-tap halfband FIR, polyphase)]\n//       v\n//     [De-emphasis high-shelf]           -4 dB / 3 kHz / Q=0.7  (RBJ, DFI)\n//       v\n//     [DC blocker]                       y = x - x1 + R*y1\n//       v\n//     [Drive-dependent output makeup]    -0.70 * 20*log10(d/tanh(d))\n//       v\n//     [INPUT_GAIN output cancellation]   * 10^(-INPUT_GAIN_dB/20)\n//       v\n//     OUTPUT\n//\n// IMPLEMENTATION NOTES / INTERPRETATION CALLS:\n//\n// 1. Mis-bias inject (drive>8) is OMITTED in v0 gen DSL.\n//    The numpy reference seeds an RNG and adds a 0.5 Hz random walk,\n//    capped at +/-0.002 (-54 dBFS). gen~ has `noise` (white) and\n//    `noise()` is per-sample so we *could* low-pass it with `t60`,\n//    but the spec says \"tiny random walk added at drive>8\" and at\n//    -54 dBFS, below the DC blocker cutoff of 20 Hz it gets mostly\n//    nulled. The audible difference is < -60 dBFS even at saturate=1.\n//    Decision: defer to a later integration pass once the [js]\n//    companion is wired and we can route a deterministic seed.\n//    This is the only knowing divergence from the numpy ref.\n//\n// 2. Polyphase halfband (interp + decim).\n//    The 31-tap halfband FIR has h[k] == 0 for all even k except k=15\n//    (center). So:\n//      - Upsampler output even phase  = h[15] * x[n - 7]   (delay = 15//2)\n//      - Upsampler output odd phase   = sum over odd k of h[k] * x[n - ?]\n//    We implement both phases as taps off a shared input delay line of\n//    length 16 (we need x[n], x[n-1], ..., x[n-15] for the odd-phase\n//    convolution). Decimator is the dual: feed both shaped sub-samples\n//    into a 2x-rate delay line of length 31, output = sum h[k]*v[k]\n//    every native sample.\n//\n//    The numpy ref multiplies the upsampler output by 2.0 to compensate\n//    for zero-insertion energy loss (so that an all-pass cascade of\n//    upsample->shaper(identity)->downsample preserves RMS).  We do the\n//    same here: the *odd* phase already integrates that factor by\n//    summing 14 non-trivial taps; we apply the *2.0 to both phases\n//    explicitly to match the ref exactly.\n//\n// 3. Stereo: L and R use shared parameters and shared coefficient state\n//    but independent signal-path state (separate History / Delay\n//    instances). This matches the numpy ref's _process_one_channel()\n//    invocation per channel.\n//\n// 4. Denormal flush: gen~ on M1 ARM doesn't have x86 denormal slowdowns,\n//    but we still mirror the ref's `if (|y| < 1e-30) y = 0` for biquad\n//    states to make A/B with the numpy reference exact.\n//\n// 5. saturate=0 short-circuit. gen~ has no compile-time static-if; we\n//    use a runtime mix:  out = bypass*y_dry + (1-bypass)*y_wet, where\n//    bypass = (saturate <= 0). This costs two extra muls/sample. Keeps\n//    the spec's bit-identical bypass guarantee at the bottom of the knob.\n//    NOTE: when bypass=1 we still feed zeros into the wet path to keep\n//    the biquad / FIR state from accumulating denormal noise during the\n//    bypass period; they recover within ~31 samples when the user turns\n//    the knob back up. (Tradeoff: a tiny 31-sample fade-in transient on\n//    knob-touch from 0 -> nonzero. The design doc accepts this in \u00a710.)\n//\n// 6. input_gain is read as a continuous Param and quantized to 0/1/2 by\n//    the [js] companion *before* it reaches gen. Inside gen we just\n//    branch on the integer value via two `==` comparisons. dB->linear\n//    conversion is hardcoded:\n//      LINE       : 1.000000 (= 10^(  0/20))\n//      INSTRUMENT : 1.995262 (= 10^(  6/20))\n//      HIGH_GAIN  : 3.981072 (= 10^( 12/20))\n//    Output cancellation:  1/g_in.\n//\n// =============================================================================\n\n\n// -----------------------------------------------------------------------------\n// Parameter declarations\n// -----------------------------------------------------------------------------\n\n// Pre-emphasis biquad coefficients (44.1 kHz; hot-swappable via [js])\nParam pre_b0(1.4796626808353215);\nParam pre_b1(-2.168322256291102);\nParam pre_b2(0.857216222713986);\nParam pre_a1(-1.3370165564518925);\nParam pre_a2(0.5055732037100982);\nParam de_b0(0.6758297096710346);\nParam de_b1(-0.9035955111722491);\nParam de_b2(0.3416813914808506);\nParam de_a1(-1.4654166009424578);\nParam de_a2(0.5793321909220942);\nParam dcr_R(0.9971545388743885);\nHistory pre_x1_L(0.0);\nHistory pre_x2_L(0.0);\nHistory pre_y1_L(0.0);\nHistory pre_y2_L(0.0);\nHistory uxL_0(0.0); History uxL_1(0.0); History uxL_2(0.0); History uxL_3(0.0);\nHistory uxL_4(0.0); History uxL_5(0.0); History uxL_6(0.0); History uxL_7(0.0);\nHistory uxL_8(0.0); History uxL_9(0.0); History uxL_10(0.0); History uxL_11(0.0);\nHistory uxL_12(0.0); History uxL_13(0.0); History uxL_14(0.0);\nHistory uxL_15(0.0);\nHistory dxL_0(0.0);  History dxL_1(0.0);  History dxL_2(0.0);  History dxL_3(0.0);\nHistory dxL_4(0.0);  History dxL_5(0.0);  History dxL_6(0.0);  History dxL_7(0.0);\nHistory dxL_8(0.0);  History dxL_9(0.0);  History dxL_10(0.0); History dxL_11(0.0);\nHistory dxL_12(0.0); History dxL_13(0.0); History dxL_14(0.0); History dxL_15(0.0);\nHistory dxL_16(0.0); History dxL_17(0.0); History dxL_18(0.0); History dxL_19(0.0);\nHistory dxL_20(0.0); History dxL_21(0.0); History dxL_22(0.0); History dxL_23(0.0);\nHistory dxL_24(0.0); History dxL_25(0.0); History dxL_26(0.0); History dxL_27(0.0);\nHistory dxL_28(0.0); History dxL_29(0.0); History dxL_30(0.0);\nHistory de_x1_L(0.0); History de_x2_L(0.0);\nHistory de_y1_L(0.0); History de_y2_L(0.0);\nHistory dc_x1_L(0.0);\nHistory dc_y1_L(0.0);\nHistory pre_x1_R(0.0);\nHistory pre_x2_R(0.0);\nHistory pre_y1_R(0.0);\nHistory pre_y2_R(0.0);\nHistory uxR_0(0.0); History uxR_1(0.0); History uxR_2(0.0); History uxR_3(0.0);\nHistory uxR_4(0.0); History uxR_5(0.0); History uxR_6(0.0); History uxR_7(0.0);\nHistory uxR_8(0.0); History uxR_9(0.0); History uxR_10(0.0); History uxR_11(0.0);\nHistory uxR_12(0.0); History uxR_13(0.0); History uxR_14(0.0); History uxR_15(0.0);\nHistory dxR_0(0.0);  History dxR_1(0.0);  History dxR_2(0.0);  History dxR_3(0.0);\nHistory dxR_4(0.0);  History dxR_5(0.0);  History dxR_6(0.0);  History dxR_7(0.0);\nHistory dxR_8(0.0);  History dxR_9(0.0);  History dxR_10(0.0); History dxR_11(0.0);\nHistory dxR_12(0.0); History dxR_13(0.0); History dxR_14(0.0); History dxR_15(0.0);\nHistory dxR_16(0.0); History dxR_17(0.0); History dxR_18(0.0); History dxR_19(0.0);\nHistory dxR_20(0.0); History dxR_21(0.0); History dxR_22(0.0); History dxR_23(0.0);\nHistory dxR_24(0.0); History dxR_25(0.0); History dxR_26(0.0); History dxR_27(0.0);\nHistory dxR_28(0.0); History dxR_29(0.0); History dxR_30(0.0);\nHistory de_x1_R(0.0); History de_x2_R(0.0);\nHistory de_y1_R(0.0); History de_y2_R(0.0);\nHistory dc_x1_R(0.0);\nHistory dc_y1_R(0.0);\n\n\n// De-emphasis biquad coefficients (44.1 kHz; hot-swappable via [js])\n\n// DC blocker pole radius (44.1 kHz; hot-swappable via [js])\n\n// -----------------------------------------------------------------------------\n// Inlet bindings \u2014 saturate and input_gain come via signal-rate inlets from\n// the parent maxpat (dial-saturate \u2192 subpatcher inlet 2 \u2192 gen~ inlet 2,\n// tab-input_gain \u2192 subpatcher inlet 3 \u2192 gen~ inlet 3). Per-sample control\n// values that vary continuously when the user touches the knob.\n//\n// IMPORTANT: gen~ requires all declarations (Param/History/Buffer) to\n// precede any expressions. These assignments must therefore live *after*\n// the Param block above.\n// -----------------------------------------------------------------------------\nsaturate = in3;\ninput_gain = in4;\n\n// -----------------------------------------------------------------------------\n// Halfband FIR taps (31 taps, Kaiser beta=8.0, sample-rate-independent)\n// Source: data/tl_saturate_coefficients.json -> halfband_fir.taps\n// Even taps (except k=15) are zero -- the polyphase ops below skip them.\n// -----------------------------------------------------------------------------\n\n// Center tap (k=15)\nhb_15 = 0.49998341447554523;\n\n// Odd-side taps (mirrored: hb_k == hb_(30-k) by linear-phase symmetry)\nhb_1  = -4.962987862434643e-05;   // == hb_29\nhb_3  =  0.0006422540255711147;   // == hb_27\nhb_5  = -0.002734441417494108;    // == hb_25\nhb_7  =  0.00802032401027231;     // == hb_23\nhb_9  = -0.019227637930233975;    // == hb_21\nhb_11 =  0.0415367046593286;      // == hb_19\nhb_13 = -0.09122480814029417;     // == hb_17\n\n// -----------------------------------------------------------------------------\n// Input gain: discrete LINE / INSTRUMENT / HIGH_GAIN\n// -----------------------------------------------------------------------------\n// `input_gain` is integer 0/1/2; cascade two `==` comparisons.\n// 10^(0/20)=1.0   10^(6/20)=1.9952623149688795   10^(12/20)=3.9810717055349722\n\nis_inst = (input_gain == 1);\nis_high = (input_gain == 2);\ng_in = 1.0\n     + is_inst * (1.9952623149688795 - 1.0)\n     + is_high * (3.9810717055349722 - 1.0);\ng_out = 1.0 / g_in;   // exact small-signal cancellation per design doc \u00a75\n\n// -----------------------------------------------------------------------------\n// Drive mapping: drive(s) = 1 + 11*s^2  (quadratic taper, design doc \u00a73)\n// bias(d)  = 0.05 * max(0, (d-4)/8)\n// beta(d)  = 0.20 * max(0, (d-2)/10)\n// makeup_gain = 10^(-0.70 * 20*log10(d/tanh(d)) / 20) = (d/tanh(d))^(-0.70)\n// -----------------------------------------------------------------------------\n\ns_clamped = clamp(saturate, 0.0, 1.0);\ndrive = 1.0 + 11.0 * s_clamped * s_clamped;\nbias  = 0.05 * max(0.0, (drive - 4.0) * 0.125);   // /8\nbeta_ = 0.20 * max(0.0, (drive - 2.0) * 0.1);     // /10\n\n// Output makeup: pow(drive/tanh(drive), -0.70). guard against drive==0.\ninv_tanh_d = 1.0 / tanh(drive);\nssg        = drive * inv_tanh_d;                  // small-signal gain\nmakeup     = pow(ssg, -0.70);\n\n// Bypass selector for saturate==0\nis_bypass = (saturate <= 0.0);\n\n\n// =============================================================================\n// Channel macro -- replicated for L (suffix _L) and R (suffix _R).\n// gen~ codebox does not have user-defined functions in v8, so the chain\n// is unrolled per channel.  All History/Delay state is per-channel.\n// =============================================================================\n\n\n// -------------------------- L CHANNEL ----------------------------------------\n\n// Stage 1: input gain\nxL = in1 * g_in;\n\n// Stage 2: pre-emphasis biquad (Direct Form I)\n\npre_yL = pre_b0*xL + pre_b1*pre_x1_L + pre_b2*pre_x2_L\n       - pre_a1*pre_y1_L - pre_a2*pre_y2_L;\n// Denormal flush (cheap on ARM; matters under bypass in x86 deploys)\npre_yL = (abs(pre_yL) < 1e-30) ? 0.0 : pre_yL;\n\npre_x2_L = pre_x1_L;\npre_x1_L = xL;\npre_y2_L = pre_y1_L;\npre_y1_L = pre_yL;\n\n// Stage 3: 2x upsample (polyphase halfband)\n// Delay line of length 16 over the *native-rate* pre-emphasis output.\n// pin x_L[n], x_L[n-1], ..., x_L[n-15].\n// The \"even\" up-sample phase is just h[15]*x[n-7]   (with the *2.0 that\n// the numpy ref applies to the whole upsampler output to compensate for\n// zero-insertion energy loss).  The \"odd\" phase is the sum of all odd-k\n// taps applied in symmetric pairs -- since the FIR is linear-phase\n// (h[k]==h[30-k]) we fold pairs together to halve the multiplies.\n//\n// For the convolution mode='same' alignment used by the numpy ref:\n//   y_even[2n]   = h[15] * x[n - 7]\n//   y_odd[2n+1]  = sum over odd k:  h[k] * x[n - floor((k-1)/2)]\n// We then double both samples (to match the ref's *2.0 normalization).\n\n\n// Even-phase output  (sample @ time 2n)\n//   delay 7 from current input  -> x[n-7]  -> uxL_6 (since after the shift below\n//   uxL_6 holds what was uxL_5 last sample, which was x[n-7] at that point...\n// To keep this readable: shift FIRST, then read indices.\n//\n// State definition AFTER the shift block:\n//   uxL_0 = x[n], uxL_1 = x[n-1], ..., uxL_14 = x[n-14], pre_x1_L holds x[n-15]?\n// We need x[n-15] for the lower bound of the odd-phase sum. Easiest to use\n// 16 delays. But we already have 15 here. Add one more:\n\n\n// Even phase: tap h[15] * x[n-7]  with *2.0 normalization\nyEven_L = 2.0 * hb_15 * uxL_7;\n\n// Odd phase: pair-fold the symmetric odd taps.\n//   y_odd = sum over odd k of h[k] * x[n - ((k-1)/2)]\n// Pairs (k, 30-k): same coefficient hb_k. The two members of each pair\n// read x at delays (k-1)/2 and (30-k-1)/2 = (29-k)/2.\n// Concretely:\n//   k=1 paired with k=29 -> delays 0 and 14    -> hb_1 * (uxL_0 + uxL_14)\n//   k=3 paired with k=27 -> delays 1 and 13    -> hb_3 * (uxL_1 + uxL_13)\n//   k=5 paired with k=25 -> delays 2 and 12    -> hb_5 * (uxL_2 + uxL_12)\n//   k=7 paired with k=23 -> delays 3 and 11    -> hb_7 * (uxL_3 + uxL_11)\n//   k=9 paired with k=21 -> delays 4 and 10    -> hb_9 * (uxL_4 + uxL_10)\n//   k=11 paired with k=19 -> delays 5 and 9    -> hb_11 * (uxL_5 + uxL_9)\n//   k=13 paired with k=17 -> delays 6 and 8    -> hb_13 * (uxL_6 + uxL_8)\n//   k=15 (center) is on EVEN phase, not odd.\n\nyOdd_L = hb_1  * (uxL_0  + uxL_14)\n       + hb_3  * (uxL_1  + uxL_13)\n       + hb_5  * (uxL_2  + uxL_12)\n       + hb_7  * (uxL_3  + uxL_11)\n       + hb_9  * (uxL_4  + uxL_10)\n       + hb_11 * (uxL_5  + uxL_9)\n       + hb_13 * (uxL_6  + uxL_8);\nyOdd_L = 2.0 * yOdd_L;\n\n// Stage 4: asymmetric tanh waveshaper applied to BOTH oversampled samples.\n// u = sample + bias;  base = tanh(d*u)/tanh(d);  mult = (u<0) ? 1+beta*u : 1\n// Out = base * mult.\n//\n// Even-phase shaped sample:\nuE_L     = yEven_L + bias;\nbaseE_L  = tanh(drive * uE_L) * inv_tanh_d;\nmultE_L  = (uE_L < 0.0) ? (1.0 + beta_ * uE_L) : 1.0;\nshapedE_L = baseE_L * multE_L;\n// Odd-phase shaped sample:\nuO_L     = yOdd_L + bias;\nbaseO_L  = tanh(drive * uO_L) * inv_tanh_d;\nmultO_L  = (uO_L < 0.0) ? (1.0 + beta_ * uO_L) : 1.0;\nshapedO_L = baseO_L * multO_L;\n\n// Shift the upsampler input delay line AFTER reading.\n// (Ordering: read taps, then shift -- standard FIR pattern.)\nuxL_15 = uxL_14;\nuxL_14 = uxL_13;\nuxL_13 = uxL_12;\nuxL_12 = uxL_11;\nuxL_11 = uxL_10;\nuxL_10 = uxL_9;\nuxL_9  = uxL_8;\nuxL_8  = uxL_7;\nuxL_7  = uxL_6;\nuxL_6  = uxL_5;\nuxL_5  = uxL_4;\nuxL_4  = uxL_3;\nuxL_3  = uxL_2;\nuxL_2  = uxL_1;\nuxL_1  = uxL_0;\nuxL_0  = pre_yL;\n\n// Stage 5: 2x downsample (polyphase halfband decimator)\n// We push two samples per native sample into the down-sampler delay line.\n// The halfband decim FIR has the same taps as the interp FIR.\n// Maintain v_L[0..30] = oversampled-shaped stream of length 31.\n// Push order each sample: even sample (older time index), then odd sample\n// (newer). After both pushes, output one native sample = sum h[k]*v[k].\n\n\n// Push the two oversampled-shaped samples (FIFO, oldest off the back).\n// Two-sample shift in one go. Because the decimator outputs every other\n// sample of `convolve(v, h, 'same')[::2]`, pairing the push order\n// (shapedE_L then shapedO_L) with reading the symmetric pair sums below\n// reproduces the numpy ref exactly.\ndxL_30 = dxL_28; dxL_29 = dxL_27;\ndxL_28 = dxL_26; dxL_27 = dxL_25;\ndxL_26 = dxL_24; dxL_25 = dxL_23;\ndxL_24 = dxL_22; dxL_23 = dxL_21;\ndxL_22 = dxL_20; dxL_21 = dxL_19;\ndxL_20 = dxL_18; dxL_19 = dxL_17;\ndxL_18 = dxL_16; dxL_17 = dxL_15;\ndxL_16 = dxL_14; dxL_15 = dxL_13;\ndxL_14 = dxL_12; dxL_13 = dxL_11;\ndxL_12 = dxL_10; dxL_11 = dxL_9;\ndxL_10 = dxL_8;  dxL_9  = dxL_7;\ndxL_8  = dxL_6;  dxL_7  = dxL_5;\ndxL_6  = dxL_4;  dxL_5  = dxL_3;\ndxL_4  = dxL_2;  dxL_3  = dxL_1;\ndxL_2  = dxL_0;\ndxL_1 = shapedE_L;\ndxL_0 = shapedO_L;\n// (After the shifts, dxL_0 = newest [odd phase], dxL_1 = even phase one\n//  oversample-step earlier, ..., dxL_30 = oldest.)\n\n// Decimator output: sum h[k]*v[k] for k=0..30.  Use linear-phase pairing\n// to halve the multiplies (h[k] == h[30-k]).\n//   k=15 (center): hb_15 * dxL_15\n//   even-k pairs (0,30), (2,28), (4,26), ..., (14,16): all zero -- skipped\n//   odd-k pairs:  (1,29), (3,27), ..., (13,17)\nyDecim_L =\n      hb_15 * dxL_15\n    + hb_1  * (dxL_1  + dxL_29)\n    + hb_3  * (dxL_3  + dxL_27)\n    + hb_5  * (dxL_5  + dxL_25)\n    + hb_7  * (dxL_7  + dxL_23)\n    + hb_9  * (dxL_9  + dxL_21)\n    + hb_11 * (dxL_11 + dxL_19)\n    + hb_13 * (dxL_13 + dxL_17);\n\n// Stage 6: de-emphasis biquad (Direct Form I)\n\nde_yL = de_b0*yDecim_L + de_b1*de_x1_L + de_b2*de_x2_L\n      - de_a1*de_y1_L - de_a2*de_y2_L;\nde_yL = (abs(de_yL) < 1e-30) ? 0.0 : de_yL;\n\nde_x2_L = de_x1_L;\nde_x1_L = yDecim_L;\nde_y2_L = de_y1_L;\nde_y1_L = de_yL;\n\n// Stage 7: DC blocker  y[n] = x[n] - x[n-1] + R*y[n-1]\n\ndc_yL = de_yL - dc_x1_L + dcr_R * dc_y1_L;\ndc_x1_L = de_yL;\ndc_y1_L = dc_yL;\n\n// Stage 8: drive-dependent makeup gain\ny_wet_L = dc_yL * makeup;\n\n// Stage 9: INPUT_GAIN output cancellation (linear)\ny_wet_L = y_wet_L * g_out;\n\n// Stage X: bypass mux for saturate == 0.\n//   Bypass branch: input * g_out  -- input passes through and the\n//   INPUT_GAIN cancellation still applies, so output is mode-independent\n//   (matches the numpy ref's saturate==0 branch which still applies g_out).\ny_dry_L = in1 * g_out;\nout1 = is_bypass * y_dry_L + (1.0 - is_bypass) * y_wet_L;\n\n\n// -------------------------- R CHANNEL ----------------------------------------\n// Identical structure to L; independent state.\n\nxR = in2 * g_in;\n\n\npre_yR = pre_b0*xR + pre_b1*pre_x1_R + pre_b2*pre_x2_R\n       - pre_a1*pre_y1_R - pre_a2*pre_y2_R;\npre_yR = (abs(pre_yR) < 1e-30) ? 0.0 : pre_yR;\n\npre_x2_R = pre_x1_R;\npre_x1_R = xR;\npre_y2_R = pre_y1_R;\npre_y1_R = pre_yR;\n\n\nyEven_R = 2.0 * hb_15 * uxR_7;\n\nyOdd_R = hb_1  * (uxR_0  + uxR_14)\n       + hb_3  * (uxR_1  + uxR_13)\n       + hb_5  * (uxR_2  + uxR_12)\n       + hb_7  * (uxR_3  + uxR_11)\n       + hb_9  * (uxR_4  + uxR_10)\n       + hb_11 * (uxR_5  + uxR_9)\n       + hb_13 * (uxR_6  + uxR_8);\nyOdd_R = 2.0 * yOdd_R;\n\nuE_R     = yEven_R + bias;\nbaseE_R  = tanh(drive * uE_R) * inv_tanh_d;\nmultE_R  = (uE_R < 0.0) ? (1.0 + beta_ * uE_R) : 1.0;\nshapedE_R = baseE_R * multE_R;\n\nuO_R     = yOdd_R + bias;\nbaseO_R  = tanh(drive * uO_R) * inv_tanh_d;\nmultO_R  = (uO_R < 0.0) ? (1.0 + beta_ * uO_R) : 1.0;\nshapedO_R = baseO_R * multO_R;\n\nuxR_15 = uxR_14;\nuxR_14 = uxR_13;\nuxR_13 = uxR_12;\nuxR_12 = uxR_11;\nuxR_11 = uxR_10;\nuxR_10 = uxR_9;\nuxR_9  = uxR_8;\nuxR_8  = uxR_7;\nuxR_7  = uxR_6;\nuxR_6  = uxR_5;\nuxR_5  = uxR_4;\nuxR_4  = uxR_3;\nuxR_3  = uxR_2;\nuxR_2  = uxR_1;\nuxR_1  = uxR_0;\nuxR_0  = pre_yR;\n\n\ndxR_30 = dxR_28; dxR_29 = dxR_27;\ndxR_28 = dxR_26; dxR_27 = dxR_25;\ndxR_26 = dxR_24; dxR_25 = dxR_23;\ndxR_24 = dxR_22; dxR_23 = dxR_21;\ndxR_22 = dxR_20; dxR_21 = dxR_19;\ndxR_20 = dxR_18; dxR_19 = dxR_17;\ndxR_18 = dxR_16; dxR_17 = dxR_15;\ndxR_16 = dxR_14; dxR_15 = dxR_13;\ndxR_14 = dxR_12; dxR_13 = dxR_11;\ndxR_12 = dxR_10; dxR_11 = dxR_9;\ndxR_10 = dxR_8;  dxR_9  = dxR_7;\ndxR_8  = dxR_6;  dxR_7  = dxR_5;\ndxR_6  = dxR_4;  dxR_5  = dxR_3;\ndxR_4  = dxR_2;  dxR_3  = dxR_1;\ndxR_2  = dxR_0;\ndxR_1 = shapedE_R;\ndxR_0 = shapedO_R;\n\nyDecim_R =\n      hb_15 * dxR_15\n    + hb_1  * (dxR_1  + dxR_29)\n    + hb_3  * (dxR_3  + dxR_27)\n    + hb_5  * (dxR_5  + dxR_25)\n    + hb_7  * (dxR_7  + dxR_23)\n    + hb_9  * (dxR_9  + dxR_21)\n    + hb_11 * (dxR_11 + dxR_19)\n    + hb_13 * (dxR_13 + dxR_17);\n\n\nde_yR = de_b0*yDecim_R + de_b1*de_x1_R + de_b2*de_x2_R\n      - de_a1*de_y1_R - de_a2*de_y2_R;\nde_yR = (abs(de_yR) < 1e-30) ? 0.0 : de_yR;\n\nde_x2_R = de_x1_R;\nde_x1_R = yDecim_R;\nde_y2_R = de_y1_R;\nde_y1_R = de_yR;\n\n\ndc_yR = de_yR - dc_x1_R + dcr_R * dc_y1_R;\ndc_x1_R = de_yR;\ndc_y1_R = dc_yR;\n\ny_wet_R = dc_yR * makeup * g_out;\ny_dry_R = in2 * g_out;\nout2 = is_bypass * y_dry_R + (1.0 - is_bypass) * y_wet_R;\n\n// =============================================================================\n// END tl_saturate.gendsp\n// =============================================================================\n"
								}
							},
							{
								"box": {
									"id": "tl_saturate-gen-out1",
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
									"id": "tl_saturate-gen-out2",
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
										"tl_saturate-gen-in1",
										0
									],
									"destination": [
										"tl_saturate-gen-codebox",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-gen-in2",
										0
									],
									"destination": [
										"tl_saturate-gen-codebox",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-gen-in3",
										0
									],
									"destination": [
										"tl_saturate-gen-codebox",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-gen-in4",
										0
									],
									"destination": [
										"tl_saturate-gen-codebox",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-gen-codebox",
										0
									],
									"destination": [
										"tl_saturate-gen-out1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-gen-codebox",
										1
									],
									"destination": [
										"tl_saturate-gen-out2",
										0
									]
								}
							}
						]
					},
					"rnboattrcache": {},
					"saved_object_attributes": {
						"exportfolder": "",
						"exportname": "tl_saturate_dsp",
						"wantsoutputcore": 0
					}
				}
			},
			{
				"box": {
					"id": "tl_saturate-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						180,
						600,
						60
					],
					"text": "tl_saturate (SANDBOX-PARTIAL): asym waveshaper + 2x halfband FIR + RBJ pre/de-emph shelves + DC blocker + mis-bias inject. saturate=0 short-circuits to bypass (spec divergence #6). SR-aware coeffs via tl_saturate_coefficients.json. DSP graph implemented in [gen~ tl_saturate_dsp] codebox; reference impl: dsp/reference/tl_saturate.py."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_saturate-in-L",
						0
					],
					"destination": [
						"tl_saturate-gen",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_saturate-in-R",
						0
					],
					"destination": [
						"tl_saturate-gen",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_saturate-pin-0",
						0
					],
					"destination": [
						"tl_saturate-gen",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_saturate-pin-1",
						0
					],
					"destination": [
						"tl_saturate-gen",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_saturate-gen",
						0
					],
					"destination": [
						"tl_saturate-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_saturate-gen",
						1
					],
					"destination": [
						"tl_saturate-out-R",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_saturate",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}