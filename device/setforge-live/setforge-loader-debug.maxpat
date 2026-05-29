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
			1200.0,
			800.0
		],
		"openinpresentation": 0,
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
		"devicewidth": 1100.0,
		"description": "",
		"digest": "",
		"tags": "",
		"style": "",
		"subpatcher_template": "",
		"assistshowspatchername": 0,
		"boxes": [
			{
				"box": {
					"id": "js-loader",
					"maxclass": "newobj",
					"numinlets": 3,
					"numoutlets": 4,
					"patching_rect": [
						400,
						240,
						320,
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
					"id": "print-grid1-out",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						400,
						320,
						150,
						22
					],
					"outlettype": [],
					"text": "print SF-GRID1-OUT"
				}
			},
			{
				"box": {
					"id": "print-grid2-out",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						570,
						320,
						150,
						22
					],
					"outlettype": [],
					"text": "print SF-GRID2-OUT"
				}
			},
			{
				"box": {
					"id": "print-liveapi",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						740,
						320,
						150,
						22
					],
					"outlettype": [],
					"text": "print SF-LIVEAPI"
				}
			},
			{
				"box": {
					"id": "print-status",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						910,
						320,
						150,
						22
					],
					"outlettype": [],
					"text": "print SF-STATUS"
				}
			},
			{
				"box": {
					"id": "loadbang",
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
						20,
						50,
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
					"id": "msg-cmd-90",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						90,
						700,
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
					"id": "msg-cmd-120",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						120,
						200,
						22
					],
					"outlettype": [
						""
					],
					"text": "reload"
				}
			},
			{
				"box": {
					"id": "msg-cmd-150",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						150,
						200,
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
					"id": "msg-cmd-180",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						180,
						200,
						22
					],
					"outlettype": [
						""
					],
					"text": "sync"
				}
			},
			{
				"box": {
					"id": "msg-cmd-210",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						210,
						200,
						22
					],
					"outlettype": [
						""
					],
					"text": "save"
				}
			},
			{
				"box": {
					"id": "msg-cmd-240",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						240,
						200,
						22
					],
					"outlettype": [
						""
					],
					"text": "inspect"
				}
			},
			{
				"box": {
					"id": "msg-cmd-270",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						270,
						200,
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
					"id": "msg-cmd-300",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						300,
						200,
						22
					],
					"outlettype": [
						""
					],
					"text": "debug"
				}
			},
			{
				"box": {
					"id": "msg-cmd-330",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						330,
						200,
						22
					],
					"outlettype": [
						""
					],
					"text": "save_manifest"
				}
			},
			{
				"box": {
					"id": "msg-cmd-360",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						360,
						200,
						22
					],
					"outlettype": [
						""
					],
					"text": "save_set"
				}
			},
			{
				"box": {
					"id": "iter-grid1",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						420,
						600,
						60,
						22
					],
					"outlettype": [
						"int"
					],
					"text": "iter"
				}
			},
			{
				"box": {
					"id": "msg-midi-420-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						180,
						420,
						240,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						180,
						420,
						240,
						18
					],
					"text": "row1 col1 note-on (drums)",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-midi-420",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						420,
						160,
						22
					],
					"outlettype": [
						""
					],
					"text": "144 81 127"
				}
			},
			{
				"box": {
					"id": "msg-midi-450-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						180,
						450,
						240,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						180,
						450,
						240,
						18
					],
					"text": "row1 col1 note-off",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-midi-450",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						450,
						160,
						22
					],
					"outlettype": [
						""
					],
					"text": "144 81 0"
				}
			},
			{
				"box": {
					"id": "msg-midi-480-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						180,
						480,
						240,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						180,
						480,
						240,
						18
					],
					"text": "row2 col2 note-on (bass)",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-midi-480",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						480,
						160,
						22
					],
					"outlettype": [
						""
					],
					"text": "144 72 127"
				}
			},
			{
				"box": {
					"id": "msg-midi-510-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						180,
						510,
						240,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						180,
						510,
						240,
						18
					],
					"text": "row5 col1 note-on (preset A)",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-midi-510",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						510,
						160,
						22
					],
					"outlettype": [
						""
					],
					"text": "144 51 127"
				}
			},
			{
				"box": {
					"id": "msg-midi-540-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						180,
						540,
						240,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						180,
						540,
						240,
						18
					],
					"text": "row7 col3 note-on (SOLO)",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-midi-540",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						540,
						160,
						22
					],
					"outlettype": [
						""
					],
					"text": "144 33 127"
				}
			},
			{
				"box": {
					"id": "msg-midi-570-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						180,
						570,
						240,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						180,
						570,
						240,
						18
					],
					"text": "row7 col3 note-off",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-midi-570",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						20,
						570,
						160,
						22
					],
					"outlettype": [
						""
					],
					"text": "144 33 0"
				}
			},
			{
				"box": {
					"id": "msg-cc-420-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						960,
						420,
						140,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						960,
						420,
						140,
						18
					],
					"text": "CC100 save",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-cc-420",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						800,
						420,
						150,
						22
					],
					"outlettype": [
						""
					],
					"text": "176 100 127"
				}
			},
			{
				"box": {
					"id": "msg-cc-450-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						960,
						450,
						140,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						960,
						450,
						140,
						18
					],
					"text": "CC101 sync",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-cc-450",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						800,
						450,
						150,
						22
					],
					"outlettype": [
						""
					],
					"text": "176 101 127"
				}
			},
			{
				"box": {
					"id": "msg-cc-480-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						960,
						480,
						140,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						960,
						480,
						140,
						18
					],
					"text": "CC102 inspect",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-cc-480",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						800,
						480,
						150,
						22
					],
					"outlettype": [
						""
					],
					"text": "176 102 127"
				}
			},
			{
				"box": {
					"id": "msg-cc-510-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						960,
						510,
						140,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						960,
						510,
						140,
						18
					],
					"text": "CC103 panic",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-cc-510",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						800,
						510,
						150,
						22
					],
					"outlettype": [
						""
					],
					"text": "176 103 127"
				}
			},
			{
				"box": {
					"id": "msg-cc-540-lbl",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						960,
						540,
						140,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						960,
						540,
						140,
						18
					],
					"text": "CC104 eject",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "msg-cc-540",
					"maxclass": "message",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						800,
						540,
						150,
						22
					],
					"outlettype": [
						""
					],
					"text": "176 104 127"
				}
			},
			{
				"box": {
					"id": "title",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						420,
						20,
						600,
						22
					],
					"presentation": 1,
					"presentation_rect": [
						420,
						20,
						600,
						22
					],
					"text": "setforge-loader DEBUG HARNESS \u2014 Max Console = Window menu",
					"fontsize": 12.0
				}
			},
			{
				"box": {
					"id": "subtitle",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						420,
						45,
						600,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						420,
						45,
						600,
						18
					],
					"text": "JS loaded from Max Package: ~/Documents/Max N/Packages/setforge-live/javascript/",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "subtitle2",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						420,
						65,
						600,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						420,
						65,
						600,
						18
					],
					"text": "LiveAPI calls will fail outside Live \u2014 that's expected. Verify dispatch + prints.",
					"fontsize": 10.0
				}
			},
			{
				"box": {
					"id": "subtitle3",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						420,
						85,
						600,
						18
					],
					"presentation": 1,
					"presentation_rect": [
						420,
						85,
						600,
						18
					],
					"text": "Edit loader-controller.js \u2192 rebuild \u2192 autowatch reloads \u2192 click messages.",
					"fontsize": 10.0
				}
			}
		],
		"lines": [
			{
				"patchline": {
					"source": [
						"js-loader",
						0
					],
					"destination": [
						"print-grid1-out",
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
						"print-grid2-out",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js-loader",
						2
					],
					"destination": [
						"print-liveapi",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"js-loader",
						3
					],
					"destination": [
						"print-status",
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
						"msg-cmd-90",
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
						"msg-cmd-120",
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
						"msg-cmd-150",
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
						"msg-cmd-180",
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
						"msg-cmd-210",
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
						"msg-cmd-240",
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
						"msg-cmd-270",
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
						"msg-cmd-300",
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
						"msg-cmd-330",
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
						"msg-cmd-360",
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
						"iter-grid1",
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
						"msg-midi-420",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-midi-450",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-midi-480",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-midi-510",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-midi-540",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-midi-570",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-cc-420",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-cc-450",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-cc-480",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-cc-510",
						0
					],
					"destination": [
						"iter-grid1",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"msg-cc-540",
						0
					],
					"destination": [
						"iter-grid1",
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
			"name": "setforge-loader-debug"
		},
		"dependency_cache": [],
		"autosave": 0
	}
}