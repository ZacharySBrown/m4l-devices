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
						10,
						10,
						380,
						18
					],
					"text": "setforge-grid \u2014 MIDI bridge to Launchpad",
					"fontsize": 10.0
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
						10,
						28,
						380,
						16
					],
					"text": "Set track I/O to Launchpad Standalone Port",
					"fontsize": 9.0
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