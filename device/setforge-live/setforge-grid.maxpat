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
					"id": "sf-glow",
					"maxclass": "fpic",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						0,
						0,
						300.0,
						172.0
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						300.0,
						172.0
					],
					"pic": "/Users/zak/zacharysbrown/m4l-devices/device/setforge-live/assets/grid-faceplate.png",
					"embed": 0,
					"background": 1
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
			},
			{
				"box": {
					"id": "sf-co-brand",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						16,
						6,
						120,
						12
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						16,
						6,
						120,
						12
					],
					"text": "Setforge",
					"fontsize": 7.5,
					"textcolor": [
						0.545,
						0.58,
						0.655,
						1.0
					],
					"fontname": "Arial",
					"fontface": 0,
					"textjustification": 0
				}
			},
			{
				"box": {
					"id": "sf-co-name",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						16,
						15,
						260,
						18
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						16,
						15,
						260,
						18
					],
					"text": "Grid",
					"fontsize": 15.0,
					"textcolor": [
						0.204,
						0.784,
						0.91,
						1.0
					],
					"fontname": "Arial",
					"fontface": 1,
					"textjustification": 0
				}
			},
			{
				"box": {
					"id": "sf-co-conn",
					"maxclass": "comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						132.0,
						11,
						152,
						14
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						132.0,
						11,
						152,
						14
					],
					"text": "Bridged",
					"fontsize": 9.0,
					"textcolor": [
						0.545,
						0.58,
						0.655,
						1.0
					],
					"fontname": "Arial",
					"fontface": 0,
					"textjustification": 2
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