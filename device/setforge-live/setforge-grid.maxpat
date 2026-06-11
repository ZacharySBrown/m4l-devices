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
			300.0
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
		"devicewidth": 300.0,
		"description": "",
		"digest": "",
		"tags": "",
		"style": "",
		"subpatcher_template": "",
		"assistshowspatchername": 0,
		"boxes": [
			{
				"box": {
					"id": "sf-bg",
					"maxclass": "panel",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						0,
						0,
						300.0,
						90.0
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						300.0,
						90.0
					],
					"mode": 0,
					"bgfillcolor_type": "color",
					"bgfillcolor_color": [
						0.0745,
						0.0863,
						0.1137,
						1.0
					],
					"border": 0.0,
					"bordercolor": [
						0.145,
						0.169,
						0.22,
						1.0
					],
					"rounded": 0.0
				}
			},
			{
				"box": {
					"id": "sf-header",
					"maxclass": "panel",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						0,
						0,
						300.0,
						30.0
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						300.0,
						30.0
					],
					"mode": 0,
					"bgfillcolor_type": "color",
					"bgfillcolor_color": [
						0.055,
						0.067,
						0.094,
						1.0
					],
					"border": 0.0,
					"bordercolor": [
						0.145,
						0.169,
						0.22,
						1.0
					],
					"rounded": 0.0
				}
			},
			{
				"box": {
					"id": "sf-stripe",
					"maxclass": "panel",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						0,
						0,
						6,
						90.0
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						6,
						90.0
					],
					"mode": 0,
					"bgfillcolor_type": "color",
					"bgfillcolor_color": [
						0.204,
						0.784,
						0.91,
						1.0
					],
					"border": 0.0,
					"bordercolor": [
						0.145,
						0.169,
						0.22,
						1.0
					],
					"rounded": 0.0
				}
			},
			{
				"box": {
					"id": "sf-led",
					"maxclass": "panel",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						16,
						11,
						9,
						9
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						16,
						11,
						9,
						9
					],
					"mode": 0,
					"bgfillcolor_type": "color",
					"bgfillcolor_color": [
						0.357,
						0.851,
						0.541,
						1.0
					],
					"border": 0.0,
					"bordercolor": [
						0.145,
						0.169,
						0.22,
						1.0
					],
					"rounded": 9.0
				}
			},
			{
				"box": {
					"id": "sf-status",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						188.0,
						9,
						104,
						14
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						188.0,
						9,
						104,
						14
					],
					"text": "BRIDGED",
					"fontsize": 9.0,
					"textcolor": [
						0.545,
						0.58,
						0.655,
						1.0
					],
					"fontname": "Arial",
					"fontface": 0
				}
			},
			{
				"box": {
					"id": "sf-brand",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						32,
						3,
						90,
						12
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						32,
						3,
						90,
						12
					],
					"text": "SETFORGE",
					"fontsize": 8.0,
					"textcolor": [
						0.545,
						0.58,
						0.655,
						1.0
					],
					"fontname": "Arial",
					"fontface": 0
				}
			},
			{
				"box": {
					"id": "sf-name",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						32,
						12,
						280,
						17
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						32,
						12,
						280,
						17
					],
					"text": "GRID",
					"fontsize": 14.0,
					"textcolor": [
						0.204,
						0.784,
						0.91,
						1.0
					],
					"fontname": "Arial",
					"fontface": 1
				}
			},
			{
				"box": {
					"id": "midiin",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						20,
						20,
						60,
						22
					],
					"outlettype": [
						"int"
					],
					"text": "midiin"
				}
			},
			{
				"box": {
					"id": "midiout",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						120,
						60,
						22
					],
					"outlettype": [],
					"text": "midiout"
				}
			},
			{
				"box": {
					"id": "send-to-loader",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						150,
						50,
						150,
						22
					],
					"outlettype": [],
					"text": "send sf-grid-in"
				}
			},
			{
				"box": {
					"id": "recv-from-loader",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						150,
						90,
						150,
						22
					],
					"outlettype": [
						""
					],
					"text": "receive sf-grid-out"
				}
			},
			{
				"box": {
					"id": "print-midi-in",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						50,
						140,
						22
					],
					"outlettype": [],
					"text": "print sf-grid-midiin"
				}
			},
			{
				"box": {
					"id": "print-midi-out",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						150,
						115,
						140,
						22
					],
					"outlettype": [],
					"text": "print sf-grid-to-lp"
				}
			},
			{
				"box": {
					"id": "title-grid",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						160,
						300,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						38.0,
						280,
						16
					],
					"text": "setforge-grid",
					"fontsize": 10.0,
					"textcolor": [
						0.545,
						0.58,
						0.655,
						1.0
					]
				}
			},
			{
				"box": {
					"id": "status-grid",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						185,
						300,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						58.0,
						280,
						14
					],
					"text": "MIDI bridge \u2192 Launchpad",
					"fontsize": 9.0,
					"textcolor": [
						0.545,
						0.58,
						0.655,
						1.0
					]
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"midiin",
						0
					],
					"destination": [
						"send-to-loader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"recv-from-loader",
						0
					],
					"destination": [
						"midiout",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"midiin",
						0
					],
					"destination": [
						"print-midi-in",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"recv-from-loader",
						0
					],
					"destination": [
						"print-midi-out",
						0
					]
				}
			}
		],
		"project": {
			"version": 1,
			"creationdate": 0,
			"modificationdate": 0,
			"viewrect": [
				0.0,
				0.0,
				300.0,
				500.0
			],
			"autoorganize": 1,
			"hideprojectwindow": 1,
			"showdependencies": 1,
			"autolocalize": 0,
			"contents": {
				"patchers": {}
			},
			"layout": {},
			"searchpath": {},
			"detailsvisible": 0,
			"amxdtype": 1633771873,
			"readonly": 0,
			"devpathtype": 0,
			"devpath": ".",
			"sortmode": 0,
			"viewmode": 0,
			"name": "setforge-grid"
		},
		"dependency_cache": [],
		"autosave": 0
	}
}