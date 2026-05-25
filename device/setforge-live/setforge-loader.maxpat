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
			500.0
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
					"id": "recv-grid-in",
					"maxclass": "newobj",
					"numinlets": 0,
					"numoutlets": 1,
					"patching_rect": [
						150,
						20,
						150,
						22
					],
					"outlettype": [
						""
					],
					"text": "receive sf-grid-in"
				}
			},
			{
				"box": {
					"id": "send-grid-out",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						150,
						120,
						150,
						22
					],
					"outlettype": [],
					"text": "send sf-grid-out"
				}
			},
			{
				"box": {
					"id": "thisdevice",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"patching_rect": [
						150,
						160,
						100,
						22
					],
					"outlettype": [
						"",
						"",
						""
					],
					"text": "live.thisdevice"
				}
			},
			{
				"box": {
					"id": "loadbang",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						300,
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
						300,
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
					"id": "opendialog",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						500,
						160,
						120,
						22
					],
					"outlettype": [
						"",
						"bang"
					],
					"text": "opendialog JSON"
				}
			},
			{
				"box": {
					"id": "btn-browse",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						500,
						130,
						120,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						500,
						10,
						80,
						20
					],
					"varname": "browse",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "browse",
							"parameter_shortname": "browse",
							"parameter_type": 1
						}
					},
					"text": "browse...",
					"texton": "browse...",
					"textoff": "browse...",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "prepend-load",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						500,
						190,
						100,
						22
					],
					"outlettype": [
						""
					],
					"text": "prepend load"
				}
			},
			{
				"box": {
					"id": "msg-test-load",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						650,
						190,
						600,
						22
					],
					"outlettype": [
						""
					],
					"text": "load /Users/zak/zacharysbrown/m4l-devices/.claude/worktrees/setforge-live/device/setforge-live/tests/fixtures/manifests/hiphop_v3.set.json"
				}
			},
			{
				"box": {
					"id": "msg-test-panic",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						650,
						220,
						80,
						22
					],
					"outlettype": [
						""
					],
					"text": "panic"
				}
			},
			{
				"box": {
					"id": "msg-test-eject",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						750,
						220,
						80,
						22
					],
					"outlettype": [
						""
					],
					"text": "eject"
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
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						35,
						400,
						16
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
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						50,
						400,
						16
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
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						65,
						400,
						16
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
						80,
						400,
						16
					],
					"text": "active scene: \u2014",
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
						400,
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						95,
						400,
						16
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
						115,
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
						115,
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
						115,
						200,
						18
					],
					"text": "fx target: all",
					"fontsize": 10.0
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
						"recv-grid-in",
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
						"send-grid-out",
						0
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
						"send-grid-out",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"thisdevice",
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
						"btn-browse",
						0
					],
					"destination": [
						"opendialog",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"opendialog",
						0
					],
					"destination": [
						"prepend-load",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"prepend-load",
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
						"msg-test-load",
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
						"msg-test-panic",
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
						"msg-test-eject",
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