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
					"id": "tl_dry_mix-in-L",
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
					"id": "tl_dry_mix-in-R",
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
					"id": "tl_dry_mix-pin-0",
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
					"id": "tl_dry_mix-out-L",
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
					"id": "tl_dry_mix-out-R",
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
					"id": "tl_dry_mix-dry-in-L",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						200,
						20,
						30,
						30
					],
					"outlettype": [
						"signal"
					],
					"comment": "",
					"index": 5
				}
			},
			{
				"box": {
					"id": "tl_dry_mix-dry-in-R",
					"maxclass": "inlet",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						250,
						20,
						30,
						30
					],
					"outlettype": [
						"signal"
					],
					"comment": "",
					"index": 6
				}
			},
			{
				"box": {
					"id": "tl_dry_mix-zmap",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						40,
						80,
						100,
						22
					],
					"outlettype": [
						""
					],
					"text": "zmap 0 2 0 1"
				}
			},
			{
				"box": {
					"id": "tl_dry_mix-mode-to-gain",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						40,
						110,
						250,
						22
					],
					"outlettype": [
						""
					],
					"text": "expr ($i1==0) ? 0. : ($i1==1) ? 0.3981 : 1.0"
				}
			},
			{
				"box": {
					"id": "tl_dry_mix-slide",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 1,
					"patching_rect": [
						40,
						140,
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
					"id": "tl_dry_mix-mul-L",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						200,
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
					"id": "tl_dry_mix-add-L",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						300,
						170,
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
					"id": "tl_dry_mix-mul-R",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						200,
						210,
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
					"id": "tl_dry_mix-add-R",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						300,
						210,
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
					"id": "tl_dry_mix-note",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						240,
						700,
						40
					],
					"text": "tl_dry_mix (SANDBOX-OK): DRY toggle (NONE/SMALL=-8dB/UNITY). 10ms slide smoothing. Inlets: 1=wetL, 2=wetR, 3=dry_mode, 5=dryL, 6=dryR. Dry source is latency-aligned by main patch's 30ms pre-WOW dry-tap delay (per design doc \u00a72). Positive-polarity sum."
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"tl_dry_mix-pin-0",
						0
					],
					"destination": [
						"tl_dry_mix-mode-to-gain",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-mode-to-gain",
						0
					],
					"destination": [
						"tl_dry_mix-slide",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-dry-in-L",
						0
					],
					"destination": [
						"tl_dry_mix-mul-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-slide",
						0
					],
					"destination": [
						"tl_dry_mix-mul-L",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-in-L",
						0
					],
					"destination": [
						"tl_dry_mix-add-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-mul-L",
						0
					],
					"destination": [
						"tl_dry_mix-add-L",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-add-L",
						0
					],
					"destination": [
						"tl_dry_mix-out-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-dry-in-R",
						0
					],
					"destination": [
						"tl_dry_mix-mul-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-slide",
						0
					],
					"destination": [
						"tl_dry_mix-mul-R",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-in-R",
						0
					],
					"destination": [
						"tl_dry_mix-add-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-mul-R",
						0
					],
					"destination": [
						"tl_dry_mix-add-R",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tl_dry_mix-add-R",
						0
					],
					"destination": [
						"tl_dry_mix-out-R",
						0
					]
				}
			}
		],
		"project": {
			"name": "tl_dry_mix",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}