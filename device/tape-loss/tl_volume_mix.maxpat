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
					"id": "tl_volume_mix-in-L",
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
					"id": "tl_volume_mix-in-R",
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
					"id": "tl_volume_mix-pin-0",
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
					"id": "tl_volume_mix-pin-1",
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
					"id": "tl_volume_mix-out-L",
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
					"id": "tl_volume_mix-out-R",
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
					"id": "tl_volume_mix-sum",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						40,
						100,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "+~"
				}
			},
			{
				"box": {
					"id": "tl_volume_mix-half",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						40,
						130,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "*~ 0.5"
				}
			},
			{
				"box": {
					"id": "tl_volume_mix-miso-sel-L",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"patching_rect": [
						140,
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
					"id": "tl_volume_mix-slide-L",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"patching_rect": [
						250,
						130,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "slide~ 441 441"
				}
			},
			{
				"box": {
					"id": "tl_volume_mix-mul-L",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						250,
						170,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "*~"
				}
			},
			{
				"box": {
					"id": "tl_volume_mix-miso-sel-R",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"patching_rect": [
						200,
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
					"id": "tl_volume_mix-slide-R",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"patching_rect": [
						320,
						130,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "slide~ 441 441"
				}
			},
			{
				"box": {
					"id": "tl_volume_mix-mul-R",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						320,
						170,
						50,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "*~"
				}
			},
			{
				"box": {
					"id": "tl_volume_mix-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						220,
						700,
						40
					],
					"text": "tl_volume_mix (SANDBOX-OK): VOLUME (0..2 lin) + MISO mono-sum. One-pole smoother \u03c4=10ms. MISO crossfade also 10ms. No internal limiter at unity+volume_max \u2014 expected behavior."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_volume_mix-in-L",
						0
					],
					"destination": [
						"tl_volume_mix-sum",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-in-R",
						0
					],
					"destination": [
						"tl_volume_mix-sum",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-sum",
						0
					],
					"destination": [
						"tl_volume_mix-half",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-in-L",
						0
					],
					"destination": [
						"tl_volume_mix-miso-sel-L",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-half",
						0
					],
					"destination": [
						"tl_volume_mix-miso-sel-L",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-pin-1",
						0
					],
					"destination": [
						"tl_volume_mix-miso-sel-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-pin-0",
						0
					],
					"destination": [
						"tl_volume_mix-slide-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-miso-sel-L",
						0
					],
					"destination": [
						"tl_volume_mix-mul-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-slide-L",
						0
					],
					"destination": [
						"tl_volume_mix-mul-L",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-mul-L",
						0
					],
					"destination": [
						"tl_volume_mix-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-in-R",
						0
					],
					"destination": [
						"tl_volume_mix-miso-sel-R",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-half",
						0
					],
					"destination": [
						"tl_volume_mix-miso-sel-R",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-pin-1",
						0
					],
					"destination": [
						"tl_volume_mix-miso-sel-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-pin-0",
						0
					],
					"destination": [
						"tl_volume_mix-slide-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-miso-sel-R",
						0
					],
					"destination": [
						"tl_volume_mix-mul-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-slide-R",
						0
					],
					"destination": [
						"tl_volume_mix-mul-R",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_volume_mix-mul-R",
						0
					],
					"destination": [
						"tl_volume_mix-out-R",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_volume_mix",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}