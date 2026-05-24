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
			900.0,
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
		"devicewidth": 800.0,
		"description": "",
		"digest": "",
		"tags": "",
		"style": "",
		"subpatcher_template": "",
		"assistshowspatchername": 0,
		"boxes": [
			{
				"box": {
					"id": "plugin-in",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"patching_rect": [
						20,
						20,
						80,
						22
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "plugin~"
				}
			},
			{
				"box": {
					"id": "plugout",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 2,
					"patching_rect": [
						20,
						900,
						80,
						22
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "plugout~"
				}
			},
			{
				"box": {
					"id": "js-loader",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 4,
					"patching_rect": [
						150,
						60,
						300,
						22
					],
					"outlettype": [
						"",
						"",
						"",
						""
					],
					"text": "js loader.js @scripting_name loader",
					"saved_object_attributes": {
						"filename": "loader.js",
						"parameter_enable": 0
					}
				}
			},
			{
				"box": {
					"id": "midiin-grid1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						150,
						20,
						300,
						22
					],
					"outlettype": [
						"int"
					],
					"text": "midiin \"Launchpad Pro MK3 LPProMK3 MIDI\""
				}
			},
			{
				"box": {
					"id": "midiout-grid1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						150,
						120,
						300,
						22
					],
					"outlettype": [],
					"text": "midiout \"Launchpad Pro MK3 LPProMK3 MIDI\""
				}
			},
			{
				"box": {
					"id": "midiin-grid2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						500,
						20,
						300,
						22
					],
					"outlettype": [
						"int"
					],
					"text": "midiin \"Launchpad Pro MK3 LPProMK3 MIDI 2\""
				}
			},
			{
				"box": {
					"id": "midiout-grid2",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						500,
						120,
						300,
						22
					],
					"outlettype": [],
					"text": "midiout \"Launchpad Pro MK3 LPProMK3 MIDI 2\""
				}
			},
			{
				"box": {
					"id": "loadbang",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						150,
						160,
						60,
						22
					],
					"outlettype": [
						"bang"
					],
					"text": "loadbang"
				}
			},
			{
				"box": {
					"id": "msg-init",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						150,
						190,
						60,
						22
					],
					"outlettype": [
						""
					],
					"text": "init"
				}
			},
			{
				"box": {
					"id": "umenu-set",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 3,
					"patching_rect": [
						20,
						250,
						200,
						22
					],
					"outlettype": [
						"",
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						70,
						10,
						200,
						20
					],
					"varname": "set_chooser",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "set_chooser",
							"parameter_shortname": "set",
							"parameter_type": 2,
							"parameter_enum": [
								"(no set loaded)"
							],
							"parameter_initial_enable": 1,
							"parameter_initial": [
								0
							]
						}
					}
				}
			},
			{
				"box": {
					"id": "btn-load",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						280,
						250,
						60,
						20
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						280,
						10,
						60,
						20
					],
					"varname": "load",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "load",
							"parameter_shortname": "load",
							"parameter_type": 1,
							"parameter_enum": [
								"load"
							]
						}
					},
					"text": "load",
					"texton": "load",
					"textoff": "load",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "btn-reload",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						350,
						250,
						60,
						20
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						350,
						10,
						60,
						20
					],
					"varname": "reload",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "reload",
							"parameter_shortname": "reload",
							"parameter_type": 1,
							"parameter_enum": [
								"reload"
							]
						}
					},
					"text": "reload",
					"texton": "reload",
					"textoff": "reload",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "btn-eject",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						420,
						250,
						60,
						20
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						420,
						10,
						60,
						20
					],
					"varname": "eject",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "eject",
							"parameter_shortname": "eject",
							"parameter_type": 1,
							"parameter_enum": [
								"eject"
							]
						}
					},
					"text": "eject",
					"texton": "eject",
					"textoff": "eject",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "status-bankA",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						300,
						780,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						40,
						780,
						18
					],
					"text": "bank A: \u2014",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "status-bankB",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						325,
						780,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						58,
						780,
						18
					],
					"text": "bank B: \u2014",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "status-active",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						350,
						780,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						76,
						780,
						18
					],
					"text": "active preset: \u2014",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "status-scene",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						375,
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						94,
						400,
						18
					],
					"text": "active scene: \u2014",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "status-lp1",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						400,
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						112,
						400,
						18
					],
					"text": "launchpad 1: not connected",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "status-lp2",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						425,
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						130,
						400,
						18
					],
					"text": "launchpad 2: not connected",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "status-tempo",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						450,
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						148,
						400,
						18
					],
					"text": "tempo: \u2014 bpm",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "toggle-master",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						20,
						500,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						175,
						80,
						20
					],
					"varname": "master_bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "master_bypass",
							"parameter_shortname": "master_bypass",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "btn-panic",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						150,
						500,
						80,
						25
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						700,
						175,
						80,
						20
					],
					"varname": "panic",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "panic",
							"parameter_shortname": "PANIC",
							"parameter_type": 1
						}
					},
					"text": "PANIC",
					"texton": "PANIC",
					"textoff": "PANIC",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "status-fxtarget",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						250,
						500,
						200,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						400,
						175,
						200,
						18
					],
					"text": "fx target: all",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "title",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						550,
						300,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						200,
						300,
						22
					],
					"text": "setforge-loader",
					"fontsize": 14.0
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"plugin-in",
						0
					],
					"destination": [
						"plugout",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"plugin-in",
						1
					],
					"destination": [
						"plugout",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"midiin-grid1",
						0
					],
					"destination": [
						"js-loader",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js-loader",
						0
					],
					"destination": [
						"midiout-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"midiin-grid2",
						0
					],
					"destination": [
						"js-loader",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js-loader",
						1
					],
					"destination": [
						"midiout-grid2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"loadbang",
						0
					],
					"destination": [
						"msg-init",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-init",
						0
					],
					"destination": [
						"js-loader",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"umenu-set",
						0
					],
					"destination": [
						"js-loader",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-load",
						0
					],
					"destination": [
						"js-loader",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-reload",
						0
					],
					"destination": [
						"js-loader",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-eject",
						0
					],
					"destination": [
						"js-loader",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"toggle-master",
						0
					],
					"destination": [
						"js-loader",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-panic",
						0
					],
					"destination": [
						"js-loader",
						2
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
			"name": "setforge-loader"
		},
		"dependency_cache": [],
		"autosave": 0
	}
}