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
			800.0,
			350.0
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
		"devicewidth": 700.0,
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
						700,
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
					"id": "js-calibrate",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 3,
					"patching_rect": [
						150,
						60,
						300,
						22
					],
					"outlettype": [
						"",
						"",
						""
					],
					"text": "js calibrate.js @scripting_name calibrate",
					"saved_object_attributes": {
						"filename": "calibrate.js",
						"parameter_enable": 0
					}
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
						100,
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
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						150,
						130,
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
					"id": "umenu-track",
					"maxclass": "live.menu",
					"numinlets": 1,
					"numoutlets": 3,
					"patching_rect": [
						20,
						200,
						250,
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
						250,
						20
					],
					"varname": "track_chooser",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "track_chooser",
							"parameter_shortname": "track",
							"parameter_type": 2,
							"parameter_enum": [
								"(no track)"
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
					"id": "btn-load-cal",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						330,
						200,
						70,
						20
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						330,
						10,
						70,
						20
					],
					"varname": "load-cal",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "load-cal",
							"parameter_shortname": "load",
							"parameter_type": 1
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
					"id": "btn-next-cal",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						410,
						200,
						70,
						20
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						410,
						10,
						70,
						20
					],
					"varname": "next-cal",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "next-cal",
							"parameter_shortname": "next",
							"parameter_type": 1
						}
					},
					"text": "next",
					"texton": "next",
					"textoff": "next",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "tab-stem",
					"maxclass": "live.tab",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
						240,
						300,
						25
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						40,
						300,
						25
					],
					"varname": "stem_select",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"drums",
								"bass",
								"other",
								"vox"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "stem_select",
							"parameter_shortname": "stem_select",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "cal-downbeat",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						280,
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						75,
						400,
						18
					],
					"text": "calibrated downbeat: \u2014 sec",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "cal-marker",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						305,
						400,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						93,
						400,
						18
					],
					"text": "current marker: \u2014 sec",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "cal-setstate",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						330,
						600,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						155,
						600,
						18
					],
					"text": "set state: \u2014 validated",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "btn-audition",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
						350,
						90,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						120,
						90,
						22
					],
					"varname": "audition",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "audition",
							"parameter_shortname": "audition",
							"parameter_type": 1
						}
					},
					"text": "audition",
					"texton": "audition",
					"textoff": "audition",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "btn-click",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						120,
						350,
						90,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						110,
						120,
						90,
						22
					],
					"varname": "click",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "click",
							"parameter_shortname": "click",
							"parameter_type": 1
						}
					},
					"text": "click",
					"texton": "click",
					"textoff": "click",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "btn-validated",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						220,
						350,
						90,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						210,
						120,
						90,
						22
					],
					"varname": "validated",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "validated",
							"parameter_shortname": "validated",
							"parameter_type": 1
						}
					},
					"text": "validated",
					"texton": "validated",
					"textoff": "validated",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "btn-revert",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						320,
						350,
						90,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						310,
						120,
						90,
						22
					],
					"varname": "revert",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "revert",
							"parameter_shortname": "revert",
							"parameter_type": 1
						}
					},
					"text": "revert",
					"texton": "revert",
					"textoff": "revert",
					"mode": 0
				}
			},
			{
				"box": {
					"id": "title-cal",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						400,
						300,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						10,
						180,
						300,
						22
					],
					"text": "setforge-calibrate",
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
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"umenu-track",
						0
					],
					"destination": [
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-load-cal",
						0
					],
					"destination": [
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-next-cal",
						0
					],
					"destination": [
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tab-stem",
						0
					],
					"destination": [
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-audition",
						0
					],
					"destination": [
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-click",
						0
					],
					"destination": [
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-validated",
						0
					],
					"destination": [
						"js-calibrate",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-revert",
						0
					],
					"destination": [
						"js-calibrate",
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
			"name": "setforge-calibrate"
		},
		"dependency_cache": [],
		"autosave": 0
	}
}