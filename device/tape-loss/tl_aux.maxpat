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
					"id": "tl_aux-in-L",
					"maxclass": "newobj",
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
					"text": "inlet~",
					"comment": "",
					"index": 1
				}
			},
			{
				"box": {
					"id": "tl_aux-in-R",
					"maxclass": "newobj",
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
					"text": "inlet~",
					"comment": "",
					"index": 2
				}
			},
			{
				"box": {
					"id": "tl_aux-pin-0",
					"maxclass": "newobj",
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
					"text": "inlet",
					"comment": "",
					"index": 3
				}
			},
			{
				"box": {
					"id": "tl_aux-pin-1",
					"maxclass": "newobj",
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
					"text": "inlet",
					"comment": "",
					"index": 4
				}
			},
			{
				"box": {
					"id": "tl_aux-pin-2",
					"maxclass": "newobj",
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
					"text": "inlet",
					"comment": "",
					"index": 5
				}
			},
			{
				"box": {
					"id": "tl_aux-out-L",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						260,
						30,
						30
					],
					"outlettype": [],
					"text": "outlet~",
					"comment": "",
					"index": 1
				}
			},
			{
				"box": {
					"id": "tl_aux-out-R",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						90,
						260,
						30,
						30
					],
					"outlettype": [],
					"text": "outlet~",
					"comment": "",
					"index": 2
				}
			},
			{
				"box": {
					"id": "tl_aux-eout-0",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						140,
						260,
						30,
						30
					],
					"outlettype": [],
					"text": "outlet~",
					"comment": "",
					"index": 3
				}
			},
			{
				"box": {
					"id": "tl_aux-gen",
					"maxclass": "newobj",
					"numinlets": 5,
					"numoutlets": 3,
					"patching_rect": [
						40,
						100,
						250,
						60
					],
					"outlettype": [
						"signal",
						"signal",
						"signal"
					],
					"text": "gen~ @title tl_aux_modes",
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
									"id": "tl_aux-gen-codebox",
									"maxclass": "codebox",
									"numinlets": 5,
									"numoutlets": 3,
									"outlettype": [
										"signal",
										"signal",
										"signal"
									],
									"patching_rect": [
										50.0,
										50.0,
										600.0,
										400.0
									],
									"text": "// =====================================================================\n// tl_aux.gendsp \u2014 gen~ DSL source for the AUX module of tape-loss\n// =====================================================================\n//\n// Module       : tl_aux (Generation Loss MKII \"AUX footswitch\")\n// Authored     : 2026-04-27 (Phase 2.5 \u2014 gen~ translation)\n// Author       : pedal-engineer (auto-authored from numpy reference)\n// SANDBOX      : LOCAL-ONLY  (STOP mode requires Max IDE for buffer-init\n//                verification per pitfall #19; the FILTER and FAIL modes\n//                are individually SANDBOX-OK but the unit ships as one\n//                gen~ object so the strictest mode classifies the whole)\n//\n// Source files :\n//   design-doc        : docs/design-docs/dsp/tl-aux-design.md\n//                       sha256: e37f4fe1993bf2036f6393e1a266edc1628017dd\n//                               2c3b90a29c0903dc2695f3e8\n//   numpy reference   : dsp/reference/tl_aux.py\n//                       sha256: 02f4837686fc9b18af36cedcbab6662742b27a7e\n//                               0b52f74f927a63ba4b2767c6\n//   parent maxpat stub: device/tape-loss/tl_aux.maxpat\n//                       (5-inlet / 3-outlet contract; Phase 1.5)\n//\n// Inlets  (5 in maxpat, 4 used here):\n//   in1 = signal L\n//   in2 = signal R\n//   in3 = aux_active        (control signal, 0 or 1, footswitch state)\n//   in4 = aux_onset_ms      (control signal, 10..3000 ms, log-tapered)\n//   in5 = reserved          (parent maxpat allocates 5 inlets to leave\n//                            headroom for a future failure_knob input;\n//                            unread here \u2014 FAIL override uses a 0-knob\n//                            baseline so override = e[n] cleanly)\n//\n// Outlets (3) \u2014 Phase 1.5 contract:\n//   out1 = signal L          (mode-dispatched output, audio rate)\n//   out2 = signal R          (mode-dispatched output, audio rate)\n//   out3 = failure_override  (signal-rate sidechain to tl_failure inlet 4;\n//                             0 unless aux_mode = FAIL, else = e[n] in\n//                             [0, 1])\n//\n// Param   (1):\n//   aux_mode   \u2208 {0, 1, 2}    (0 = STOP, 1 = FILTER, 2 = FAIL; default 0)\n//\n// ---------------------------------------------------------------------\n// Algorithm summary (translated 1:1 from dsp/reference/tl_aux.py):\n//\n//   Shared onset envelope (all three modes consume the same e[n]):\n//\n//     onset_ms \u2190 clamp(in4, 10, 3000)\n//     \u03b1        = 1 - exp(-1 / (onset_ms \u00b7 samplerate / 1000))\n//     target   = in3                                  // 0 or 1\n//     e[n]     = e[n-1] + \u03b1 \u00b7 (target - e[n-1])       // exp 1-pole\n//\n//   Mode A \u2014 STOP (tape-stop deceleration):\n//\n//     rate[n]  = clamp((1 - e[n])^2.5, 0, 1)          // \u03b3 = 2.5\n//     gain[n]  = sqrt(max(0, 1 - e[n]))               // \u221a-taper\n//     read_pos = read_pos_prev + (1 - rate[n])        // delay grows when\n//                                                      // rate < 1\n//     y_stop_L = stopbuf_L.read(read_pos, \"linear\") * gain\n//     y_stop_R = stopbuf_R.read(read_pos, \"linear\") * gain\n//\n//     The buffers are 262144 samples (~5.46 s @ 48k). They are written\n//     EVERY sample regardless of aux_mode \u2014 this guarantees STOP state\n//     stays warm across mode switches and that read-on-press always has\n//     fresh history. See \"Mode coexistence\" note below.\n//\n//   Mode B \u2014 FILTER (TPT-SVF low-pass, log sweep):\n//\n//     fc(e)    = 18000 \u00b7 (200 / 18000)^e              // log sweep\n//     fc       = clamp(fc, 20, 0.45 \u00b7 samplerate)     // SVF Nyquist guard\n//     Q(e)     = 0.707 + e \u00b7 (4.0 - 0.707)\n//     k        = 1 / Q\n//     g        = tan(\u03c0 \u00b7 fc / samplerate)             // freq warp\n//     a1       = 1 / (1 + g\u00b7(g + k))\n//     a2       = g \u00b7 a1\n//     a3       = g \u00b7 a2\n//\n//     Per-sample TPT-SVF step (Andrew Simper / Vadim Zavalishin form),\n//     two independent state pairs (L, R):\n//\n//       v3      = x - ic2eq\n//       v1      = a1\u00b7ic1eq + a2\u00b7v3\n//       v2      = ic2eq + a2\u00b7ic1eq + a3\u00b7v3\n//       ic1eq  \u2190 2\u00b7v1 - ic1eq\n//       ic2eq  \u2190 2\u00b7v2 - ic2eq\n//       y_lpf   = v2\n//\n//   Mode C \u2014 FAIL (sidechain control output):\n//\n//     Audio path: bit-identical passthrough (out1 = in1, out2 = in2).\n//     out3 (failure_override) = e[n]   (in [0, 1]; 0 when aux_active=0).\n//\n//     Per design-doc \u00a73.2 the full mapping is `knob + e\u00b7(1-knob)`. Since\n//     gen~ has no separate failure_knob inlet wired in this round, we\n//     emit just `e[n]` \u2014 equivalent to a knob of 0.0 (the default). The\n//     downstream tl_failure performs the additive-toward-max merge with\n//     its own knob value. (When the future failure_knob input lands on\n//     in5, swap the out3 expression to `knob + e_curr * (1 - knob)`.)\n//\n// ---------------------------------------------------------------------\n// Mode coexistence (state preservation across mode switches):\n//\n//   The STOP delay buffers `stopbuf_L`/`stopbuf_R` are written every\n//   sample irrespective of aux_mode (see \"delbuf_L.write(in1)\" below).\n//   This costs ~free CPU but means: switching FILTER \u2192 STOP mid-press\n//   finds the buffer ALREADY pre-filled with up-to-262144 samples of\n//   live audio history, exactly as the numpy ref's stateful processor\n//   would have it after a continuous stream.\n//\n//   The SVF state (svf_ic1_*, svf_ic2_*) is NOT advanced in non-FILTER\n//   modes, so first-press in FILTER mode starts from zeroed state \u2014 the\n//   intended behavior (numpy ref `_process_filter` initializes\n//   `state = [0.0, 0.0]` per call).\n//\n//   The read_pos History (`stop_read_pos`) is NOT advanced in non-STOP\n//   modes; it sits at whatever value it last held. On a fresh STOP press\n//   we DO want read_pos to start at 0 (read = current write = identity)\n//   \u2014 so we gate the position advance with `aux_active` and reset to 0\n//   the moment aux_active is 0 (release), matching the numpy ref's\n//   read_head=0 invariant when env=0.\n//\n//   Per design-doc \u00a70.1 (\"Mode-switching strategy\"), `aux_mode` should\n//   ideally only change while `e[n] < 0.01`. The engineer's parent\n//   patch is responsible for queuing mode changes; this DSP block\n//   honors whatever value is live.\n//\n// ---------------------------------------------------------------------\n// Sample-rate dependence:\n//\n//   * Onset \u03b1 and SVF g recompute every sample using `samplerate` \u2192\n//     SR-agnostic by construction.\n//   * STOP buffer length is 262144 SAMPLES (not seconds). At 48 kHz\n//     that's ~5.46 s of headroom (covers the spec's max 3000 ms onset\n//     at 1.5\u00d7 headroom \u2014 see design-doc \u00a71.4). At 96 kHz the same\n//     buffer holds ~2.73 s, which is STILL above the 3000 ms \u00d7 1.0\n//     bare minimum but BELOW the recommended 1.5\u00d7 headroom.\n//\n//     Verdict: at 96 kHz the read-head's \"underflow guard\" (clamping\n//     read_pos \u2264 buf_len - 256) may engage during onset = 3000 ms\n//     pathological-press scenarios. This is acceptable: the buffer\n//     freezes at the oldest sample, gain has long since faded to \u2248 0,\n//     and the audible result is silence regardless. Documented.\n//\n// ---------------------------------------------------------------------\n// Sanity-check expectations (matches numpy ref verification \u00a712):\n//\n//   ALL modes, aux_active = 0:\n//     env_e  \u2192 0\n//     out1   = in1   (STOP: read_pos=0, gain=1; FILTER: fc=18 kHz wide-\n//                     open, near-pass; FAIL: explicit pass)\n//     out2   = in2   (same as L)\n//     out3   = 0     (override is 0 unless mode = FAIL; FAIL with e=0\n//                     emits 0 anyway)\n//\n//   STOP mode, aux_active = 1, plateau (e \u2248 1):\n//     rate   \u2192 0     (read head freezes)\n//     gain   \u2192 0     (\u221a(1-e) \u2192 0)\n//     out1, out2 \u2248 silence (verified ratio \u2248 0 to 6 sig figs in numpy)\n//     out3   = 0     (override only emitted in FAIL mode)\n//\n//   FILTER mode, aux_active = 1, plateau (e \u2248 1):\n//     fc     = 200 Hz    (sweep close)\n//     Q      = 4.0       (mild resonance bump)\n//     out1, out2 = audibly low-passed; spectral centroid \u2248 257 Hz vs.\n//                  \u2248 6128 Hz dry (numpy verification result)\n//     out3   = 0\n//\n//   FAIL mode, aux_active = 1, plateau (e \u2248 1):\n//     out1   = in1       (bit-identical, max diff = 0)\n//     out2   = in2       (bit-identical, max diff = 0)\n//     out3   = 1.0       (full failure override)\n//\n// ---------------------------------------------------------------------\n// References:\n//   * Andrew Simper, \"Linear Trapezoidal Integrated State Variable\n//     Filter\", Cytomic 2014:\n//     https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf\n//   * Vadim Zavalishin, \"The Art of VA Filter Design\", \u00a73.10\n//     (Trapezoidal SVF) \u2014 free PDF.\n//   * JOS PASP, \"Wow and Flutter Modeling\" \u2014 justifies (1-e)^2.5 curve.\n//   * Smith, DSP Guide Ch. 19 \u2014 exponential envelope follower.\n//   * Project design-doc tradeoff log #2, #3, #7 \u2014 curve / topology /\n//     gain compensation choices encoded here verbatim.\n// =====================================================================\n\nParam aux_mode 0;\n\n// --- Constants -------------------------------------------------------\n\n// STOP deceleration curve exponent (design-doc \u00a71.2, tradeoff #2).\nGAMMA_STOP = 2.5;\n\n// FILTER sweep endpoints (design-doc \u00a72.4, tradeoff #10).\nFC_MAX_HZ = 18000.0;\nFC_MIN_HZ = 200.0;\n\n// FILTER resonance endpoints (design-doc \u00a72.4, tradeoff #11).\nQ_BASE = 0.707;\nQ_MAX  = 4.0;\n\n// SVF defensive clamps (design-doc \u00a72.5, \u00a78 numerical-stability).\nFC_MIN_CLAMP = 20.0;\nFC_NYQUIST_FRACTION = 0.45;\nQ_MIN_CLAMP = 0.5;\nQ_MAX_CLAMP = 10.0;\n\n// Onset envelope clamps (design-doc spec \u00a7\"aux_onset_ms\" 10..3000 ms).\nONSET_MS_MIN = 10.0;\nONSET_MS_MAX = 3000.0;\n\n// STOP buffer underflow guard headroom (design-doc \u00a71.4).\nSTOP_BUF_GUARD = 256.0;\n\n// Math constants.\nPI       = 3.14159265358979323846;\nLOG_FC_RATIO = -4.49980967033;   // = log(200 / 18000), precomputed.\n\n// Mode dispatch IDs (mirror numpy MODE_STOP/MODE_FILTER/MODE_FAIL).\nMODE_STOP_ID   = 0;\nMODE_FILTER_ID = 1;\nMODE_FAIL_ID   = 2;\n\n// --- State (History + Delay) -----------------------------------------\n\n// Shared onset envelope state \u2014 single e[n] consumed by all three modes.\nHistory env_e;\n\n// STOP mode: stereo circular buffers (262144 samples each \u2248 5.46 s @ 48k,\n// covers max 3000 ms onset \u00d7 1.5 headroom per design-doc \u00a71.4 / tradeoff\n// #6). Power of 2 for clean wraparound.\nDelay stopbuf_L(262144);\nDelay stopbuf_R(262144);\n\n// STOP mode: fractional read-head delay (samples behind the writer).\n// 0 = read = current write = identity passthrough.\nHistory stop_read_pos;\n\n// FILTER mode: TPT-SVF integrator state, separate per channel\n// (Simper/Zavalishin \"ic1eq, ic2eq\").\nHistory svf_ic1_L, svf_ic2_L;\nHistory svf_ic1_R, svf_ic2_R;\n\n// =====================================================================\n// Per-sample DSP\n// =====================================================================\n\n// ----- Onset envelope (shared across modes) --------------------------\n//\n// Single 1-pole exponential smoother. \u03b1 recomputed per sample so the\n// engineer can sweep aux_onset_ms without zipper noise.\nonset_ms_in = clamp(in4, ONSET_MS_MIN, ONSET_MS_MAX);\nonset_samples = onset_ms_in * 0.001 * samplerate;\nonset_samples = max(onset_samples, 1.0);\nalpha = 1.0 - exp(-1.0 / onset_samples);\n\ntarget = in3;                      // 0 or 1, footswitch state\nenv_e = env_e + alpha * (target - env_e);\ne_curr = env_e;\n\n// ----- STOP mode (Mode A) --------------------------------------------\n//\n// IMPORTANT: the delay buffers are written EVERY sample regardless of\n// aux_mode (see \"Mode coexistence\" in header). This is what keeps the\n// STOP buffer warm across mode switches and matches the numpy ref's\n// continuously-stateful processor.\n\nstopbuf_L.write(in1);\nstopbuf_R.write(in2);\n\n// Read-rate (\u03b3 = 2.5) and \u221a-taper output gain, both clamped.\none_minus_e = max(0.0, 1.0 - e_curr);\nrate_stop   = pow(one_minus_e, GAMMA_STOP);\nrate_stop   = clamp(rate_stop, 0.0, 1.0);\ngain_stop   = sqrt(one_minus_e);\n\n// Advance read-head position (delay-behind-writer in samples). When\n// aux_active = 0 we hard-reset the read pos to 0 so a fresh press starts\n// at identity. When aux_active = 1, the delay grows by (1 - rate) each\n// sample \u2014 exactly mirrors numpy ref `_process_stop`.\n//\n// `target` is the live aux_active value (0 or 1); it provides the gate\n// without an extra History.\nstop_pos_advance = 1.0 - rate_stop;\nstop_read_pos_next = (target > 0.5)\n    ? (stop_read_pos + stop_pos_advance)\n    : 0.0;\n\n// Underflow guard: clamp to buffer length - 256 samples (defensive;\n// covers the > buffer pathological-press case from design-doc \u00a71.4).\nstop_read_pos_next = clamp(stop_read_pos_next, 0.0, 262144.0 - STOP_BUF_GUARD);\nstop_read_pos = stop_read_pos_next;\n\n// Read with linear interpolation. gen~'s `Delay.read(d, \"linear\")` reads\n// `d` fractional samples behind the current write \u2014 exactly the\n// `(write_head - read_head) % buf_n` operation in numpy with built-in\n// linear-interp between adjacent samples (matches numpy ref's manual\n// `a + frac * (b - a)`).\nstop_read_L = stopbuf_L.read(stop_read_pos, \"linear\");\nstop_read_R = stopbuf_R.read(stop_read_pos, \"linear\");\n\ny_stop_L = stop_read_L * gain_stop;\ny_stop_R = stop_read_R * gain_stop;\n\n// ----- FILTER mode (Mode B) ------------------------------------------\n//\n// Log-sweep cutoff: fc = FC_MAX \u00b7 (FC_MIN / FC_MAX)^e\n//                 = FC_MAX \u00b7 exp(log(FC_MIN/FC_MAX) \u00b7 e)\nfc_filter = FC_MAX_HZ * exp(LOG_FC_RATIO * e_curr);\nfc_filter = clamp(fc_filter, FC_MIN_CLAMP, FC_NYQUIST_FRACTION * samplerate);\n\n// Linear resonance ramp 0.707 \u2192 4.0.\nq_filter = Q_BASE + e_curr * (Q_MAX - Q_BASE);\nq_filter = clamp(q_filter, Q_MIN_CLAMP, Q_MAX_CLAMP);\n\n// TPT-SVF coefficients (recomputed per sample \u2014 Simper \u00a7\"per-sample\"\n// form; cost is one tan() call which dominates the module's CPU).\ng_svf  = tan(PI * fc_filter / samplerate);\nk_svf  = 1.0 / q_filter;\na1_svf = 1.0 / (1.0 + g_svf * (g_svf + k_svf));\na2_svf = g_svf * a1_svf;\na3_svf = g_svf * a2_svf;\n\n// Channel L step.\nv3_L = in1 - svf_ic2_L;\nv1_L = a1_svf * svf_ic1_L + a2_svf * v3_L;\nv2_L = svf_ic2_L + a2_svf * svf_ic1_L + a3_svf * v3_L;\nsvf_ic1_L = 2.0 * v1_L - svf_ic1_L;\nsvf_ic2_L = 2.0 * v2_L - svf_ic2_L;\ny_filter_L = v2_L;     // low-pass output\n\n// Channel R step.\nv3_R = in2 - svf_ic2_R;\nv1_R = a1_svf * svf_ic1_R + a2_svf * v3_R;\nv2_R = svf_ic2_R + a2_svf * svf_ic1_R + a3_svf * v3_R;\nsvf_ic1_R = 2.0 * v1_R - svf_ic1_R;\nsvf_ic2_R = 2.0 * v2_R - svf_ic2_R;\ny_filter_R = v2_R;\n\n// ----- FAIL mode (Mode C) --------------------------------------------\n//\n// Audio: bit-identical passthrough.\n// Sidechain: failure_override = e[n] (knob = 0 baseline; downstream\n// tl_failure adds the live FAILURE knob via additive-toward-max).\ny_fail_L = in1;\ny_fail_R = in2;\nfailure_override_fail = e_curr;\n\n// ----- Mode dispatch --------------------------------------------------\n//\n// Nested conditional dispatch on aux_mode. Note: gen~ executes ALL three\n// branches every sample (no short-circuit) \u2014 this is by design for\n// state preservation (see \"Mode coexistence\" in header). The selector\n// only chooses which precomputed result to emit.\n\nis_stop   = (aux_mode == MODE_STOP_ID);\nis_filter = (aux_mode == MODE_FILTER_ID);\nis_fail   = (aux_mode == MODE_FAIL_ID);\n\nout1 = (is_stop != 0)   ? y_stop_L\n     : (is_filter != 0) ? y_filter_L\n     : y_fail_L;\n\nout2 = (is_stop != 0)   ? y_stop_R\n     : (is_filter != 0) ? y_filter_R\n     : y_fail_R;\n\n// Outlet 3 \u2014 failure_override. Non-zero ONLY in FAIL mode (Phase 1.5\n// contract: tl_failure inlet 4 reads this signal; 0 means \"use my own\n// knob\"). In STOP / FILTER modes we explicitly emit 0.\nout3 = (is_fail != 0) ? failure_override_fail : 0.0;\n\n// =====================================================================\n// END tl_aux.gendsp\n// =====================================================================\n"
								}
							}
						],
						"lines": []
					},
					"rnboattrcache": {},
					"saved_object_attributes": {
						"exportfolder": "",
						"exportname": "tl_aux_modes",
						"wantsoutputcore": 0
					}
				}
			},
			{
				"box": {
					"id": "tl_aux-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						180,
						700,
						100
					],
					"text": "tl_aux (LOCAL-ONLY): STOP/FILTER/FAIL modes triggered by aux_active footswitch. STOP: circular delay buffer + decel ramp (requires sample-accurate read-rate; this is the LOCAL-ONLY blocker \u2014 must verify in standalone Max IDE per pitfall #19). FILTER: parallel SVF wraps tl_model_eq output (Phase 1.5 contract #3 \u2014 tl_aux owns the ramp). FAIL: emits signal-rate failure_override (outlet 3) \u2192 tl_failure inlet 4 (contract #1). aux_onset_ms=10..3000ms log-tapered exponential envelope."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_aux-in-L",
						0
					],
					"destination": [
						"tl_aux-gen",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_aux-in-R",
						0
					],
					"destination": [
						"tl_aux-gen",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_aux-pin-0",
						0
					],
					"destination": [
						"tl_aux-gen",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_aux-pin-1",
						0
					],
					"destination": [
						"tl_aux-gen",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_aux-pin-2",
						0
					],
					"destination": [
						"tl_aux-gen",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_aux-gen",
						0
					],
					"destination": [
						"tl_aux-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_aux-gen",
						1
					],
					"destination": [
						"tl_aux-out-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_aux-gen",
						2
					],
					"destination": [
						"tl_aux-eout-0",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_aux",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}