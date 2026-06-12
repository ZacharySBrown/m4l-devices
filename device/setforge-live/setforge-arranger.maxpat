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
					"id": "sf-glow",
					"maxclass": "fpic",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						0,
						0,
						400.0,
						200.0
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						0,
						0,
						400.0,
						200.0
					],
					"pic": "/Users/zak/zacharysbrown/m4l-devices/device/setforge-live/assets/arranger-faceplate.png",
					"embed": 0,
					"background": 1
				}
			},
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
						600,
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
					"id": "js-arranger",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"patching_rect": [
						150,
						60,
						200,
						22
					],
					"outlettype": [
						"",
						"",
						""
					],
					"text": "js arranger-main.js @scripting_name arranger",
					"saved_object_attributes": {
						"filename": "arranger-main.js",
						"parameter_enable": 0
					}
				}
			},
			{
				"box": {
					"id": "shell-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						350,
						100,
						80,
						22
					],
					"outlettype": [
						""
					],
					"text": "shell"
				}
			},
			{
				"box": {
					"id": "prepend-anchor-complete",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						350,
						130,
						180,
						22
					],
					"outlettype": [
						""
					],
					"text": "prepend anchor_complete"
				}
			},
			{
				"box": {
					"id": "prepend-reload",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						350,
						160,
						250,
						22
					],
					"outlettype": [
						""
					],
					"text": "prepend loadArrangementFromManifest"
				}
			},
			{
				"box": {
					"id": "thisdevice-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 3,
					"patching_rect": [
						150,
						100,
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
					"id": "loadbang-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						300,
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
					"id": "msg-init-arr",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						300,
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
					"id": "udp-recv-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						350,
						60,
						140,
						22
					],
					"outlettype": [
						""
					],
					"text": "udpreceive 7423 0"
				}
			},
			{
				"box": {
					"id": "opendialog-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
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
					"id": "regexp-posix-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
						190,
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
					"id": "prepend-load-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						20,
						220,
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
					"id": "btn-browse-arr",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
						130,
						80,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						38.0,
						70,
						22
					],
					"varname": "arr_browse",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "arr_browse",
							"parameter_shortname": "browse",
							"parameter_type": 1
						}
					},
					"text": "Browse...",
					"texton": "Browse...",
					"textoff": "Browse...",
					"mode": 0,
					"bgcolor": [
						0.71,
						0.549,
						1.0,
						0.1
					],
					"bordercolor": [
						0.71,
						0.549,
						1.0,
						0.45
					],
					"textcolor": [
						0.914,
						0.929,
						0.965,
						1.0
					],
					"bgoncolor": [
						0.71,
						0.549,
						1.0,
						0.45
					]
				}
			},
			{
				"box": {
					"id": "btn-load-arr",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						110,
						130,
						60,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						86,
						38.0,
						70,
						22
					],
					"varname": "arr_load",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "arr_load",
							"parameter_shortname": "load",
							"parameter_type": 1
						}
					},
					"text": "Load",
					"texton": "Load",
					"textoff": "Load",
					"mode": 0,
					"bgcolor": [
						0.71,
						0.549,
						1.0,
						0.8
					],
					"bordercolor": [
						0.71,
						0.549,
						1.0,
						0.95
					],
					"textcolor": [
						0.043,
						0.051,
						0.071,
						1.0
					],
					"bgoncolor": [
						0.71,
						0.549,
						1.0,
						1.0
					]
				}
			},
			{
				"box": {
					"id": "msg-load-arr",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						110,
						155,
						60,
						22
					],
					"outlettype": [
						""
					],
					"text": "load"
				}
			},
			{
				"box": {
					"id": "btn-export-arr",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						180,
						130,
						80,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						164,
						38.0,
						70,
						22
					],
					"varname": "arr_export",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "arr_export",
							"parameter_shortname": "export",
							"parameter_type": 1
						}
					},
					"text": "Export",
					"texton": "Export",
					"textoff": "Export",
					"mode": 0,
					"bgcolor": [
						0.71,
						0.549,
						1.0,
						0.8
					],
					"bordercolor": [
						0.71,
						0.549,
						1.0,
						0.95
					],
					"textcolor": [
						0.043,
						0.051,
						0.071,
						1.0
					],
					"bgoncolor": [
						0.71,
						0.549,
						1.0,
						1.0
					]
				}
			},
			{
				"box": {
					"id": "msg-export-arr",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						180,
						155,
						80,
						22
					],
					"outlettype": [
						""
					],
					"text": "export"
				}
			},
			{
				"box": {
					"id": "btn-reanchor-arr",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						270,
						130,
						70,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						242,
						38.0,
						70,
						22
					],
					"varname": "arr_reanchor",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "arr_reanchor",
							"parameter_shortname": "reanchor",
							"parameter_type": 1
						}
					},
					"text": "Re-anchor",
					"texton": "Re-anchor",
					"textoff": "Re-anchor",
					"mode": 0,
					"bgcolor": [
						0.71,
						0.549,
						1.0,
						0.1
					],
					"bordercolor": [
						0.71,
						0.549,
						1.0,
						0.45
					],
					"textcolor": [
						0.914,
						0.929,
						0.965,
						1.0
					],
					"bgoncolor": [
						0.71,
						0.549,
						1.0,
						0.45
					]
				}
			},
			{
				"box": {
					"id": "prepend-reanchor-arr",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						270,
						160,
						120,
						22
					],
					"outlettype": [
						""
					],
					"text": "prepend reanchor"
				}
			},
			{
				"box": {
					"id": "btn-eject-arr",
					"maxclass": "live.text",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
						260,
						60,
						22
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						126.0,
						70,
						22
					],
					"varname": "arr_eject",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_longname": "arr_eject",
							"parameter_shortname": "eject",
							"parameter_type": 1
						}
					},
					"text": "Eject",
					"texton": "Eject",
					"textoff": "Eject",
					"mode": 0,
					"bgcolor": [
						1.0,
						0.42,
						0.42,
						0.05
					],
					"bordercolor": [
						1.0,
						0.42,
						0.42,
						0.7
					],
					"textcolor": [
						1.0,
						0.42,
						0.42,
						1.0
					],
					"bgoncolor": [
						1.0,
						0.42,
						0.42,
						0.3
					]
				}
			},
			{
				"box": {
					"id": "msg-eject-arr",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						285,
						60,
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
					"id": "status-manifest",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						320,
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						68.0,
						380,
						14
					],
					"text": "manifest: (none)",
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
					"id": "status-bpm",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						345,
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						84.0,
						380,
						14
					],
					"text": "bpm: --",
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
					"id": "status-clips",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						370,
						380,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						8,
						100.0,
						380,
						14
					],
					"text": "clips: 0",
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
					"id": "title-arr",
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
						8,
						178.0,
						200,
						14
					],
					"text": "setforge-arranger",
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
					"text": "Arranger",
					"fontsize": 15.0,
					"textcolor": [
						0.71,
						0.549,
						1.0,
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
						232.0,
						11,
						152,
						14
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						232.0,
						11,
						152,
						14
					],
					"text": "Ready",
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
						"js-arranger",
						1
					],
					"destination": [
						"shell-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"shell-arr",
						0
					],
					"destination": [
						"prepend-anchor-complete",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"prepend-anchor-complete",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js-arranger",
						2
					],
					"destination": [
						"prepend-reload",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"prepend-reload",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"thisdevice-arr",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"loadbang-arr",
						0
					],
					"destination": [
						"msg-init-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-init-arr",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"udp-recv-arr",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"opendialog-arr",
						0
					],
					"destination": [
						"regexp-posix-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"regexp-posix-arr",
						0
					],
					"destination": [
						"prepend-load-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"prepend-load-arr",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-browse-arr",
						0
					],
					"destination": [
						"opendialog-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-load-arr",
						0
					],
					"destination": [
						"msg-load-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-load-arr",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-export-arr",
						0
					],
					"destination": [
						"msg-export-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-export-arr",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-reanchor-arr",
						0
					],
					"destination": [
						"prepend-reanchor-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"prepend-reanchor-arr",
						0
					],
					"destination": [
						"js-arranger",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"btn-eject-arr",
						0
					],
					"destination": [
						"msg-eject-arr",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-eject-arr",
						0
					],
					"destination": [
						"js-arranger",
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
			"name": "setforge-arranger"
		},
		"dependency_cache": [],
		"autosave": 0
	}
}