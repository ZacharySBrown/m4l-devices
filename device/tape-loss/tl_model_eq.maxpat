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
					"id": "tl_model_eq-in-L",
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
					"id": "tl_model_eq-in-R",
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
					"id": "tl_model_eq-pin-0",
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
					"id": "tl_model_eq-pin-1",
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
					"id": "tl_model_eq-out-L",
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
					"id": "tl_model_eq-out-R",
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
					"id": "tl_model_eq-eout-0",
					"maxclass": "outlet",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						140,
						260,
						30,
						30
					],
					"comment": "",
					"index": 3
				}
			},
			{
				"box": {
					"id": "tl_model_eq-js",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"patching_rect": [
						40,
						100,
						200,
						22
					],
					"outlettype": [
						"",
						"float"
					],
					"text": "js model_selector.js @scripting_name model_selector",
					"saved_object_attributes": {
						"filename": "model_selector.js",
						"parameter_enable": 0
					}
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-L-0",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						300,
						100,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-L-1",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						360,
						100,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-L-2",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						420,
						100,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-L-3",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						480,
						100,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-L-4",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						540,
						100,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-L-5",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						600,
						100,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-sel-L",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"patching_rect": [
						700,
						100,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "selector~ 2"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-R-0",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						300,
						130,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-R-1",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						360,
						130,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-R-2",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						420,
						130,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-R-3",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						480,
						130,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-R-4",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						540,
						130,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-bq-R-5",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 1,
					"patching_rect": [
						600,
						130,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "biquad~"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-sel-R",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"patching_rect": [
						700,
						130,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "selector~ 2"
				}
			},
			{
				"box": {
					"id": "tl_model_eq-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						200,
						700,
						60
					],
					"text": "tl_model_eq (SANDBOX-OK): 12-profile cascaded biquad EQ. model=0 passthrough; filter_bypass dominates. Equal-power 12ms crossfade on change. Coeffs from data/model_eq_coefficients.json via model_selector.js (SR-aware). Cross-module: model=11 emits pitch_floor_cents=0.3 to tl_wow (Phase 1.5 contract #2)."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_model_eq-in-L",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-L-0",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-L-1",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-L-2",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-L-3",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-L-4",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-L-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-L-5",
						0
					],
					"destination": [
						"tl_model_eq-sel-L",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-in-L",
						0
					],
					"destination": [
						"tl_model_eq-sel-L",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-pin-1",
						0
					],
					"destination": [
						"tl_model_eq-sel-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-sel-L",
						0
					],
					"destination": [
						"tl_model_eq-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-in-R",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-R-0",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-R-1",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-R-2",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-R-3",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-R-4",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						0
					],
					"destination": [
						"tl_model_eq-bq-R-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-bq-R-5",
						0
					],
					"destination": [
						"tl_model_eq-sel-R",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-in-R",
						0
					],
					"destination": [
						"tl_model_eq-sel-R",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-pin-1",
						0
					],
					"destination": [
						"tl_model_eq-sel-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-sel-R",
						0
					],
					"destination": [
						"tl_model_eq-out-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-pin-0",
						0
					],
					"destination": [
						"tl_model_eq-js",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_model_eq-js",
						1
					],
					"destination": [
						"tl_model_eq-eout-0",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_model_eq",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}