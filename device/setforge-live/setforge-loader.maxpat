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
					"id": "udp-recv",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						450,
						60,
						140,
						22
					],
					"outlettype": [
						""
					],
					"text": "udpreceive 7422 0"
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
						450,
						8,
						70,
						22
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
					"id": "regexp-posix",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						500,
						220,
						240,
						22
					],
					"outlettype": [
						"",
						""
					],
					"text": "regexp (.+):(/.*) @substitute %2"
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
						250,
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
					"text": "load /Users/zak/zacharysbrown/m4l-devices/device/setforge-live/tests/fixtures/manifests/hiphop_v3.set.json"
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
						8,
						8,
						200,
						22
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
						216,
						8,
						70,
						22
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
						294,
						8,
						70,
						22
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
						372,
						8,
						70,
						22
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
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						38,
						380,
						14
					],
					"text": "bank A: \u2014",
					"fontsize": 9.0
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
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						54,
						380,
						14
					],
					"text": "bank B: \u2014",
					"fontsize": 9.0
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
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						70,
						380,
						14
					],
					"text": "active preset: \u2014",
					"fontsize": 9.0
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
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						86,
						380,
						14
					],
					"text": "active scene: \u2014",
					"fontsize": 9.0
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
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						102,
						380,
						14
					],
					"text": "tempo: \u2014 bpm",
					"fontsize": 9.0
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
						8,
						120,
						70,
						22
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
						694,
						120,
						70,
						22
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
						300,
						122,
						200,
						14
					],
					"text": "fx target: all",
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "btn-preset-0",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						100,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						400,
						38,
						40,
						18
					],
					"varname": "preset_A1",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A1",
							"parameter_shortname": "A1",
							"parameter_type": 1,
							"parameter_enum": [
								"A1"
							]
						}
					},
					"text": "A1",
					"texton": "A1",
					"textoff": "A1",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-0",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						100,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 0"
				}
			},
			{
				"box": {
					"id": "btn-preset-1",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						190,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						444,
						38,
						40,
						18
					],
					"varname": "preset_A2",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A2",
							"parameter_shortname": "A2",
							"parameter_type": 1,
							"parameter_enum": [
								"A2"
							]
						}
					},
					"text": "A2",
					"texton": "A2",
					"textoff": "A2",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-1",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						190,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 1"
				}
			},
			{
				"box": {
					"id": "btn-preset-2",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						280,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						488,
						38,
						40,
						18
					],
					"varname": "preset_A3",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A3",
							"parameter_shortname": "A3",
							"parameter_type": 1,
							"parameter_enum": [
								"A3"
							]
						}
					},
					"text": "A3",
					"texton": "A3",
					"textoff": "A3",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-2",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						280,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 2"
				}
			},
			{
				"box": {
					"id": "btn-preset-3",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						370,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						532,
						38,
						40,
						18
					],
					"varname": "preset_A4",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A4",
							"parameter_shortname": "A4",
							"parameter_type": 1,
							"parameter_enum": [
								"A4"
							]
						}
					},
					"text": "A4",
					"texton": "A4",
					"textoff": "A4",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-3",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						370,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 3"
				}
			},
			{
				"box": {
					"id": "btn-preset-4",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						460,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						576,
						38,
						40,
						18
					],
					"varname": "preset_A5",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A5",
							"parameter_shortname": "A5",
							"parameter_type": 1,
							"parameter_enum": [
								"A5"
							]
						}
					},
					"text": "A5",
					"texton": "A5",
					"textoff": "A5",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-4",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						460,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 4"
				}
			},
			{
				"box": {
					"id": "btn-preset-5",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						550,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						620,
						38,
						40,
						18
					],
					"varname": "preset_A6",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A6",
							"parameter_shortname": "A6",
							"parameter_type": 1,
							"parameter_enum": [
								"A6"
							]
						}
					},
					"text": "A6",
					"texton": "A6",
					"textoff": "A6",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-5",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						550,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 5"
				}
			},
			{
				"box": {
					"id": "btn-preset-6",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						640,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						664,
						38,
						40,
						18
					],
					"varname": "preset_A7",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A7",
							"parameter_shortname": "A7",
							"parameter_type": 1,
							"parameter_enum": [
								"A7"
							]
						}
					},
					"text": "A7",
					"texton": "A7",
					"textoff": "A7",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-6",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						640,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 6"
				}
			},
			{
				"box": {
					"id": "btn-preset-7",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						730,
						560,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						708,
						38,
						40,
						18
					],
					"varname": "preset_A8",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_A8",
							"parameter_shortname": "A8",
							"parameter_type": 1,
							"parameter_enum": [
								"A8"
							]
						}
					},
					"text": "A8",
					"texton": "A8",
					"textoff": "A8",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-7",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						730,
						582,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 7"
				}
			},
			{
				"box": {
					"id": "btn-preset-8",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						100,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						400,
						60,
						40,
						18
					],
					"varname": "preset_B1",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B1",
							"parameter_shortname": "B1",
							"parameter_type": 1,
							"parameter_enum": [
								"B1"
							]
						}
					},
					"text": "B1",
					"texton": "B1",
					"textoff": "B1",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-8",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						100,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 8"
				}
			},
			{
				"box": {
					"id": "btn-preset-9",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						190,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						444,
						60,
						40,
						18
					],
					"varname": "preset_B2",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B2",
							"parameter_shortname": "B2",
							"parameter_type": 1,
							"parameter_enum": [
								"B2"
							]
						}
					},
					"text": "B2",
					"texton": "B2",
					"textoff": "B2",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-9",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						190,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 9"
				}
			},
			{
				"box": {
					"id": "btn-preset-10",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						280,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						488,
						60,
						40,
						18
					],
					"varname": "preset_B3",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B3",
							"parameter_shortname": "B3",
							"parameter_type": 1,
							"parameter_enum": [
								"B3"
							]
						}
					},
					"text": "B3",
					"texton": "B3",
					"textoff": "B3",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-10",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						280,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 10"
				}
			},
			{
				"box": {
					"id": "btn-preset-11",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						370,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						532,
						60,
						40,
						18
					],
					"varname": "preset_B4",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B4",
							"parameter_shortname": "B4",
							"parameter_type": 1,
							"parameter_enum": [
								"B4"
							]
						}
					},
					"text": "B4",
					"texton": "B4",
					"textoff": "B4",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-11",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						370,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 11"
				}
			},
			{
				"box": {
					"id": "btn-preset-12",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						460,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						576,
						60,
						40,
						18
					],
					"varname": "preset_B5",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B5",
							"parameter_shortname": "B5",
							"parameter_type": 1,
							"parameter_enum": [
								"B5"
							]
						}
					},
					"text": "B5",
					"texton": "B5",
					"textoff": "B5",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-12",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						460,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 12"
				}
			},
			{
				"box": {
					"id": "btn-preset-13",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						550,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						620,
						60,
						40,
						18
					],
					"varname": "preset_B6",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B6",
							"parameter_shortname": "B6",
							"parameter_type": 1,
							"parameter_enum": [
								"B6"
							]
						}
					},
					"text": "B6",
					"texton": "B6",
					"textoff": "B6",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-13",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						550,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 13"
				}
			},
			{
				"box": {
					"id": "btn-preset-14",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						640,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						664,
						60,
						40,
						18
					],
					"varname": "preset_B7",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B7",
							"parameter_shortname": "B7",
							"parameter_type": 1,
							"parameter_enum": [
								"B7"
							]
						}
					},
					"text": "B7",
					"texton": "B7",
					"textoff": "B7",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-14",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						640,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 14"
				}
			},
			{
				"box": {
					"id": "btn-preset-15",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						730,
						610,
						32,
						18
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						708,
						60,
						40,
						18
					],
					"varname": "preset_B8",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "preset_B8",
							"parameter_shortname": "B8",
							"parameter_type": 1,
							"parameter_enum": [
								"B8"
							]
						}
					},
					"text": "B8",
					"texton": "B8",
					"textoff": "B8",
					"mode": 0,
					"fontsize": 9.0
				}
			},
			{
				"box": {
					"id": "msg-preset-15",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						730,
						632,
						140,
						20
					],
					"outlettype": [
						""
					],
					"text": "activate_preset 15"
				}
			},
			{
				"box": {
					"id": "btn-save",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						150,
						660,
						80,
						25
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						616,
						120,
						70,
						22
					],
					"varname": "save",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "save",
							"parameter_shortname": "SAVE",
							"parameter_type": 1,
							"parameter_enum": [
								"save"
							]
						}
					},
					"text": "SAVE",
					"texton": "SAVE",
					"textoff": "SAVE",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "msg-save",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						150,
						690,
						80,
						20
					],
					"outlettype": [
						""
					],
					"text": "save"
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
						"udp-recv",
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
						"regexp-posix",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"regexp-posix",
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
			},
			{
				"patchline": {
					"source": [
						"btn-preset-0",
						0
					],
					"destination": [
						"msg-preset-0",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-0",
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
						"btn-preset-1",
						0
					],
					"destination": [
						"msg-preset-1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-1",
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
						"btn-preset-2",
						0
					],
					"destination": [
						"msg-preset-2",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-2",
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
						"btn-preset-3",
						0
					],
					"destination": [
						"msg-preset-3",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-3",
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
						"btn-preset-4",
						0
					],
					"destination": [
						"msg-preset-4",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-4",
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
						"btn-preset-5",
						0
					],
					"destination": [
						"msg-preset-5",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-5",
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
						"btn-preset-6",
						0
					],
					"destination": [
						"msg-preset-6",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-6",
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
						"btn-preset-7",
						0
					],
					"destination": [
						"msg-preset-7",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-7",
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
						"btn-preset-8",
						0
					],
					"destination": [
						"msg-preset-8",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-8",
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
						"btn-preset-9",
						0
					],
					"destination": [
						"msg-preset-9",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-9",
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
						"btn-preset-10",
						0
					],
					"destination": [
						"msg-preset-10",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-10",
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
						"btn-preset-11",
						0
					],
					"destination": [
						"msg-preset-11",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-11",
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
						"btn-preset-12",
						0
					],
					"destination": [
						"msg-preset-12",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-12",
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
						"btn-preset-13",
						0
					],
					"destination": [
						"msg-preset-13",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-13",
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
						"btn-preset-14",
						0
					],
					"destination": [
						"msg-preset-14",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-14",
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
						"btn-preset-15",
						0
					],
					"destination": [
						"msg-preset-15",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-preset-15",
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
						"btn-save",
						0
					],
					"destination": [
						"msg-save",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-save",
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