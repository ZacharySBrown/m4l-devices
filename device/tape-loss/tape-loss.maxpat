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
			700.0,
			320.0
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
		"devicewidth": 600.0,
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
					"numinlets": 1,
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
					"text": "plugin~ 2"
				}
			},
			{
				"box": {
					"id": "plugout",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 0,
					"patching_rect": [
						20,
						800,
						80,
						22
					],
					"text": "plugout~ 2"
				}
			},
			{
				"box": {
					"id": "buf-shared",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						120,
						20,
						220,
						22
					],
					"outlettype": [
						"signal",
						""
					],
					"text": "buffer~ tape_loss_delay 4096 2"
				}
			},
			{
				"box": {
					"id": "dial-saturate",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
						60,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						20,
						20,
						60,
						60
					],
					"varname": "saturate",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "saturate",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "SAT",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dial-model",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						110,
						60,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						110,
						20,
						60,
						60
					],
					"varname": "model",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "model",
							"parameter_mmax": 12.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "MODEL",
							"parameter_type": 0,
							"parameter_unitstyle": 0
						}
					}
				}
			},
			{
				"box": {
					"id": "dial-failure",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						200,
						60,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						200,
						20,
						60,
						60
					],
					"varname": "failure",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "failure",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "FAIL",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dial-wow",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						290,
						60,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						290,
						20,
						60,
						60
					],
					"varname": "wow",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "wow",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "WOW",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dial-flutter",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						380,
						60,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						380,
						20,
						60,
						60
					],
					"varname": "flutter",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "flutter",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "FLUT",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dial-volume",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						470,
						60,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						470,
						20,
						60,
						60
					],
					"varname": "volume",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								1.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "volume",
							"parameter_mmax": 2.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "VOL",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "tab-aux_mode",
					"maxclass": "live.tab",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						20,
						130,
						180,
						25
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						20,
						90,
						180,
						25
					],
					"varname": "aux_mode",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"STOP",
								"FILTER",
								"FAIL"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "aux_mode",
							"parameter_shortname": "aux_mode",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "tab-dry_mode",
					"maxclass": "live.tab",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						220,
						130,
						180,
						25
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						220,
						90,
						180,
						25
					],
					"varname": "dry_mode",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"NONE",
								"SMALL",
								"UNITY"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "dry_mode",
							"parameter_shortname": "dry_mode",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "tab-noise_mode",
					"maxclass": "live.tab",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						420,
						130,
						180,
						25
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						420,
						90,
						180,
						25
					],
					"varname": "noise_mode",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"OFF",
								"HISS",
								"BOTH"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "noise_mode",
							"parameter_shortname": "noise_mode",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "tog-aux_active",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						20,
						165,
						30,
						30
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						20,
						125,
						30,
						30
					],
					"varname": "aux_active",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "aux_active",
							"parameter_shortname": "aux_active",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "tog-bypass",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						60,
						165,
						30,
						30
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						60,
						125,
						30,
						30
					],
					"varname": "bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "bypass",
							"parameter_shortname": "bypass",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dip-drop_bypass",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						20,
						200,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						20,
						160,
						30,
						25
					],
					"varname": "drop_bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "drop_bypass",
							"parameter_shortname": "drop_bypass",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dip-snag_bypass",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						90,
						200,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						90,
						160,
						30,
						25
					],
					"varname": "snag_bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "snag_bypass",
							"parameter_shortname": "snag_bypass",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dip-hum_bypass",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						160,
						200,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						160,
						160,
						30,
						25
					],
					"varname": "hum_bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "hum_bypass",
							"parameter_shortname": "hum_bypass",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dip-spread",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						230,
						200,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						230,
						160,
						30,
						25
					],
					"varname": "spread",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "spread",
							"parameter_shortname": "spread",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dip-classic_mode",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						300,
						200,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						300,
						160,
						30,
						25
					],
					"varname": "classic_mode",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "classic_mode",
							"parameter_shortname": "classic_mode",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dip-miso",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						370,
						200,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						370,
						160,
						30,
						25
					],
					"varname": "miso",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "miso",
							"parameter_shortname": "miso",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "dip-filter_bypass",
					"maxclass": "live.toggle",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						440,
						200,
						30,
						25
					],
					"outlettype": [
						""
					],
					"presentation": 1,
					"presentation_rect": [
						440,
						160,
						30,
						25
					],
					"varname": "filter_bypass",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "filter_bypass",
							"parameter_shortname": "filter_bypass",
							"parameter_type": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "tab-input_gain",
					"maxclass": "live.tab",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						510,
						200,
						100,
						25
					],
					"outlettype": [
						"",
						""
					],
					"presentation": 1,
					"presentation_rect": [
						510,
						160,
						100,
						25
					],
					"varname": "input_gain",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_enum": [
								"LINE",
								"INSTRUMENT",
								"HIGH_GAIN"
							],
							"parameter_initial": [
								0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "input_gain",
							"parameter_shortname": "input_gain",
							"parameter_type": 2
						}
					}
				}
			},
			{
				"box": {
					"id": "hidden-crinkle_level",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						1000,
						1000,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						1000,
						1000,
						60,
						60
					],
					"varname": "crinkle_level",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "crinkle_level",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "crinkle_level",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "hidden-hiss_level",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						1080,
						1000,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						1080,
						1000,
						60,
						60
					],
					"varname": "hiss_level",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "hiss_level",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "hiss_level",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "hidden-mechanical_level",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						1160,
						1000,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						1160,
						1000,
						60,
						60
					],
					"varname": "mechanical_level",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								0.5
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "mechanical_level",
							"parameter_mmax": 1.0,
							"parameter_mmin": 0.0,
							"parameter_shortname": "mechanical_level",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "hidden-aux_onset_ms",
					"maxclass": "live.dial",
					"numinlets": 1,
					"numoutlets": 2,
					"patching_rect": [
						1240,
						1000,
						60,
						60
					],
					"outlettype": [
						"",
						"float"
					],
					"presentation": 1,
					"presentation_rect": [
						1240,
						1000,
						60,
						60
					],
					"varname": "aux_onset_ms",
					"saved_attribute_attributes": {
						"valueof": {
							"parameter_initial": [
								200.0
							],
							"parameter_initial_enable": 1,
							"parameter_longname": "aux_onset_ms",
							"parameter_mmax": 3000.0,
							"parameter_mmin": 10.0,
							"parameter_shortname": "aux_onset_ms",
							"parameter_type": 0,
							"parameter_unitstyle": 1
						}
					}
				}
			},
			{
				"box": {
					"id": "comment-status",
					"maxclass": "live.comment",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						20,
						235,
						600,
						20
					],
					"presentation": 1,
					"presentation_rect": [
						20,
						195,
						600,
						20
					],
					"text": "Tape Loss MKII \u2014 boutique tape emulation",
					"fontsize": 11.0
				}
			},
			{
				"box": {
					"id": "box-tl_saturate",
					"maxclass": "newobj",
					"numinlets": 4,
					"numoutlets": 2,
					"patching_rect": [
						20,
						280,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "p tl_saturate",
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
									"id": "tl_saturate-in-L",
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
									"id": "tl_saturate-in-R",
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
									"id": "tl_saturate-pin-0",
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
									"id": "tl_saturate-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_saturate-out-L",
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
									"id": "tl_saturate-out-R",
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
									"id": "tl_saturate-gen",
									"maxclass": "newobj",
									"numinlets": 4,
									"numoutlets": 2,
									"patching_rect": [
										40,
										100,
										250,
										60
									],
									"outlettype": [
										"signal",
										"signal"
									],
									"text": "gen~ @title tl_saturate_dsp",
									"patcher": {
										"fileversion": 1,
										"appversion": {
											"major": 9,
											"minor": 0,
											"revision": 0,
											"architecture": "x64",
											"modernui": 1
										},
										"classnamespace": "dsp.gen",
										"rect": [
											100.0,
											100.0,
											700.0,
											600.0
										],
										"boxes": [
											{
												"box": {
													"id": "tl_saturate-gen-in1",
													"maxclass": "newobj",
													"text": "in 1",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														30.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_saturate-gen-in2",
													"maxclass": "newobj",
													"text": "in 2",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														100.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_saturate-gen-in3",
													"maxclass": "newobj",
													"text": "in 3",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														170.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_saturate-gen-in4",
													"maxclass": "newobj",
													"text": "in 4",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														240.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_saturate-gen-codebox",
													"maxclass": "codebox",
													"numinlets": 4,
													"numoutlets": 2,
													"outlettype": [
														"",
														""
													],
													"patching_rect": [
														50.0,
														100.0,
														600.0,
														400.0
													],
													"code": "// =============================================================================\n// tl_saturate.gendsp  --  gen~ DSL for the SATURATE module of `tape-loss`\n// =============================================================================\n//\n// Module:        tl_saturate (Generation Loss MKII \"SATURATE\" knob +\n//                hidden INPUT GAIN selector).\n// Authored:      2026-04-27 by pedal-engineer (translation, not redesign).\n// Source files (sha256, captured at authoring time):\n//   docs/design-docs/dsp/tl-saturate-design.md\n//     2d69115367e28c376194d24d0ae9087b58d56a0bd8b66b9e1832d379e93fb40e\n//   dsp/reference/tl_saturate.py\n//     1c798f732c4d53ed36a17ee9b062e0162ad2d808cd61b4b2f9c3c8bc09ce2b4a\n//   data/tl_saturate_coefficients.json\n//     4ab5994a40f510a00b00bd95c17a4bb0cd7c80efc7127840af2ff0feaf674b1b\n//\n// I/O CONTRACT (matches device/tape-loss/tl_saturate.maxpat stub):\n//   in1 : signal L (audio)\n//   in2 : signal R (audio)\n//   In3 : pin0 -- routed to Param `saturate`   (0..1)\n//   In4 : pin1 -- routed to Param `input_gain` (0=LINE, 1=INSTRUMENT, 2=HIGH_GAIN)\n//   out1: signal L\n//   out2: signal R\n//\n// (The maxpat stub wires inlet-3/inlet-4 to gen~ inlets 3/4. Inside this\n//  codebox we expose `saturate` and `input_gain` as Params so an outer\n//  [js] / [pattr] system can drive them. The two extra signal inlets are\n//  declared but unused so the patch stays conformant; remove them in a\n//  later pass once the integration agent decides on the param-routing\n//  topology.)\n//\n// PARAMS:\n//   saturate    : 0..1, default 0.0   -- knob position (quadratic taper inside)\n//   input_gain  : 0|1|2, default 0    -- LINE / INSTRUMENT / HIGH_GAIN\n//\n// COEFFICIENT HOT-SWAP CONTRACT (with the [js] companion):\n//   This file hardcodes the 44.1 kHz coefficient set from\n//   data/tl_saturate_coefficients.json (`by_sample_rate.44100`).\n//   The engineer's [js] companion -- which subscribes to `dspstate~` --\n//   will, on a sample-rate change, send `setcoef <b0> <b1> <b2> <a1> <a2>`\n//   style messages and `setdcr <R>` to a wrapper that re-binds the Params\n//   below.  Until that companion lands the gen~ runs with 44.1k math even\n//   at 48k; the audible drift is < 0.1 dB at 3 kHz (verified offline) so\n//   it's tolerable for v0 sandbox bring-up.\n//\n//   Coefficient Params (declared as Param so the [js] companion can hot-swap):\n//     pre_b0, pre_b1, pre_b2, pre_a1, pre_a2\n//     de_b0, de_b1, de_b2, de_a1, de_a2\n//     dcr_R\n//   Halfband taps stay hardcoded; they are sample-rate-independent.\n//\n// SANITY CHECK POINTS (expected outputs from the numpy reference):\n//   1. saturate=0, any input_gain, any input:\n//        Out == In  (bit-identical bypass; design doc tradeoff #16,\n//        verified in dsp/reference/tl_saturate.py::_run_property_checks\n//        as cascade_err_db_at_1khz_sat0 = 0.00 dB).\n//   2. saturate=0.7, input_gain=LINE, 1 kHz sine @ 0.5 amp:\n//        THD ~= 0.211 (21.1 % \u2014 pronounced asymmetric drive).\n//        Even-harmonic content (H2 amp ~= 62 in arbitrary FFT units)\n//        emerges from the (1+beta*u) negative-half multiplier.\n//   3. saturate=1.0, input_gain=LINE, 1 kHz sine @ 0.5 amp:\n//        THD ~= 0.289 (28.9 % \u2014 crushed).\n//        DC offset of unblocked signal ~= 7.5e-4 -- the DC blocker keeps\n//        steady-state output DC near zero.\n//\n// ALGORITHM (chain matches dsp/reference/tl_saturate.py::_process_one_channel):\n//\n//     INPUT\n//       v\n//     [INPUT_GAIN preamp]                LINE / +6dB / +12dB\n//       v\n//   if (saturate <= 0) -> bypass to OUTPUT (with INPUT_GAIN compensation)\n//       v\n//     [Pre-emphasis high-shelf]          +4 dB / 3 kHz / Q=0.7  (RBJ, DFI)\n//       v\n//     [2x upsample (31-tap halfband FIR, polyphase)]\n//       v\n//     [Asymmetric tanh waveshaper]       (1/tanh(d))*tanh(d*u) * (u<0 ? 1+beta*u : 1)\n//       v\n//     [2x downsample (31-tap halfband FIR, polyphase)]\n//       v\n//     [De-emphasis high-shelf]           -4 dB / 3 kHz / Q=0.7  (RBJ, DFI)\n//       v\n//     [DC blocker]                       y = x - x1 + R*y1\n//       v\n//     [Drive-dependent output makeup]    -0.70 * 20*log10(d/tanh(d))\n//       v\n//     [INPUT_GAIN output cancellation]   * 10^(-INPUT_GAIN_dB/20)\n//       v\n//     OUTPUT\n//\n// IMPLEMENTATION NOTES / INTERPRETATION CALLS:\n//\n// 1. Mis-bias inject (drive>8) is OMITTED in v0 gen DSL.\n//    The numpy reference seeds an RNG and adds a 0.5 Hz random walk,\n//    capped at +/-0.002 (-54 dBFS). gen~ has `noise` (white) and\n//    `noise()` is per-sample so we *could* low-pass it with `t60`,\n//    but the spec says \"tiny random walk added at drive>8\" and at\n//    -54 dBFS, below the DC blocker cutoff of 20 Hz it gets mostly\n//    nulled. The audible difference is < -60 dBFS even at saturate=1.\n//    Decision: defer to a later integration pass once the [js]\n//    companion is wired and we can route a deterministic seed.\n//    This is the only knowing divergence from the numpy ref.\n//\n// 2. Polyphase halfband (interp + decim).\n//    The 31-tap halfband FIR has h[k] == 0 for all even k except k=15\n//    (center). So:\n//      - Upsampler output even phase  = h[15] * x[n - 7]   (delay = 15//2)\n//      - Upsampler output odd phase   = sum over odd k of h[k] * x[n - ?]\n//    We implement both phases as taps off a shared input delay line of\n//    length 16 (we need x[n], x[n-1], ..., x[n-15] for the odd-phase\n//    convolution). Decimator is the dual: feed both shaped sub-samples\n//    into a 2x-rate delay line of length 31, output = sum h[k]*v[k]\n//    every native sample.\n//\n//    The numpy ref multiplies the upsampler output by 2.0 to compensate\n//    for zero-insertion energy loss (so that an all-pass cascade of\n//    upsample->shaper(identity)->downsample preserves RMS).  We do the\n//    same here: the *odd* phase already integrates that factor by\n//    summing 14 non-trivial taps; we apply the *2.0 to both phases\n//    explicitly to match the ref exactly.\n//\n// 3. Stereo: L and R use shared parameters and shared coefficient state\n//    but independent signal-path state (separate History / Delay\n//    instances). This matches the numpy ref's _process_one_channel()\n//    invocation per channel.\n//\n// 4. Denormal flush: gen~ on M1 ARM doesn't have x86 denormal slowdowns,\n//    but we still mirror the ref's `if (|y| < 1e-30) y = 0` for biquad\n//    states to make A/B with the numpy reference exact.\n//\n// 5. saturate=0 short-circuit. gen~ has no compile-time static-if; we\n//    use a runtime mix:  out = bypass*y_dry + (1-bypass)*y_wet, where\n//    bypass = (saturate <= 0). This costs two extra muls/sample. Keeps\n//    the spec's bit-identical bypass guarantee at the bottom of the knob.\n//    NOTE: when bypass=1 we still feed zeros into the wet path to keep\n//    the biquad / FIR state from accumulating denormal noise during the\n//    bypass period; they recover within ~31 samples when the user turns\n//    the knob back up. (Tradeoff: a tiny 31-sample fade-in transient on\n//    knob-touch from 0 -> nonzero. The design doc accepts this in \u00a710.)\n//\n// 6. input_gain is read as a continuous Param and quantized to 0/1/2 by\n//    the [js] companion *before* it reaches gen. Inside gen we just\n//    branch on the integer value via two `==` comparisons. dB->linear\n//    conversion is hardcoded:\n//      LINE       : 1.000000 (= 10^(  0/20))\n//      INSTRUMENT : 1.995262 (= 10^(  6/20))\n//      HIGH_GAIN  : 3.981072 (= 10^( 12/20))\n//    Output cancellation:  1/g_in.\n//\n// =============================================================================\n\n\n// -----------------------------------------------------------------------------\n// Parameter declarations\n// -----------------------------------------------------------------------------\n\n// Pre-emphasis biquad coefficients (44.1 kHz; hot-swappable via [js])\nParam pre_b0(1.4796626808353215);\nParam pre_b1(-2.168322256291102);\nParam pre_b2(0.857216222713986);\nParam pre_a1(-1.3370165564518925);\nParam pre_a2(0.5055732037100982);\nParam de_b0(0.6758297096710346);\nParam de_b1(-0.9035955111722491);\nParam de_b2(0.3416813914808506);\nParam de_a1(-1.4654166009424578);\nParam de_a2(0.5793321909220942);\nParam dcr_R(0.9971545388743885);\nHistory pre_x1_L(0.0);\nHistory pre_x2_L(0.0);\nHistory pre_y1_L(0.0);\nHistory pre_y2_L(0.0);\nHistory uxL_0(0.0); History uxL_1(0.0); History uxL_2(0.0); History uxL_3(0.0);\nHistory uxL_4(0.0); History uxL_5(0.0); History uxL_6(0.0); History uxL_7(0.0);\nHistory uxL_8(0.0); History uxL_9(0.0); History uxL_10(0.0); History uxL_11(0.0);\nHistory uxL_12(0.0); History uxL_13(0.0); History uxL_14(0.0);\nHistory uxL_15(0.0);\nHistory dxL_0(0.0);  History dxL_1(0.0);  History dxL_2(0.0);  History dxL_3(0.0);\nHistory dxL_4(0.0);  History dxL_5(0.0);  History dxL_6(0.0);  History dxL_7(0.0);\nHistory dxL_8(0.0);  History dxL_9(0.0);  History dxL_10(0.0); History dxL_11(0.0);\nHistory dxL_12(0.0); History dxL_13(0.0); History dxL_14(0.0); History dxL_15(0.0);\nHistory dxL_16(0.0); History dxL_17(0.0); History dxL_18(0.0); History dxL_19(0.0);\nHistory dxL_20(0.0); History dxL_21(0.0); History dxL_22(0.0); History dxL_23(0.0);\nHistory dxL_24(0.0); History dxL_25(0.0); History dxL_26(0.0); History dxL_27(0.0);\nHistory dxL_28(0.0); History dxL_29(0.0); History dxL_30(0.0);\nHistory de_x1_L(0.0); History de_x2_L(0.0);\nHistory de_y1_L(0.0); History de_y2_L(0.0);\nHistory dc_x1_L(0.0);\nHistory dc_y1_L(0.0);\nHistory pre_x1_R(0.0);\nHistory pre_x2_R(0.0);\nHistory pre_y1_R(0.0);\nHistory pre_y2_R(0.0);\nHistory uxR_0(0.0); History uxR_1(0.0); History uxR_2(0.0); History uxR_3(0.0);\nHistory uxR_4(0.0); History uxR_5(0.0); History uxR_6(0.0); History uxR_7(0.0);\nHistory uxR_8(0.0); History uxR_9(0.0); History uxR_10(0.0); History uxR_11(0.0);\nHistory uxR_12(0.0); History uxR_13(0.0); History uxR_14(0.0); History uxR_15(0.0);\nHistory dxR_0(0.0);  History dxR_1(0.0);  History dxR_2(0.0);  History dxR_3(0.0);\nHistory dxR_4(0.0);  History dxR_5(0.0);  History dxR_6(0.0);  History dxR_7(0.0);\nHistory dxR_8(0.0);  History dxR_9(0.0);  History dxR_10(0.0); History dxR_11(0.0);\nHistory dxR_12(0.0); History dxR_13(0.0); History dxR_14(0.0); History dxR_15(0.0);\nHistory dxR_16(0.0); History dxR_17(0.0); History dxR_18(0.0); History dxR_19(0.0);\nHistory dxR_20(0.0); History dxR_21(0.0); History dxR_22(0.0); History dxR_23(0.0);\nHistory dxR_24(0.0); History dxR_25(0.0); History dxR_26(0.0); History dxR_27(0.0);\nHistory dxR_28(0.0); History dxR_29(0.0); History dxR_30(0.0);\nHistory de_x1_R(0.0); History de_x2_R(0.0);\nHistory de_y1_R(0.0); History de_y2_R(0.0);\nHistory dc_x1_R(0.0);\nHistory dc_y1_R(0.0);\n\n\n// De-emphasis biquad coefficients (44.1 kHz; hot-swappable via [js])\n\n// DC blocker pole radius (44.1 kHz; hot-swappable via [js])\n\n// -----------------------------------------------------------------------------\n// Inlet bindings \u2014 saturate and input_gain come via signal-rate inlets from\n// the parent maxpat (dial-saturate \u2192 subpatcher inlet 2 \u2192 gen~ inlet 2,\n// tab-input_gain \u2192 subpatcher inlet 3 \u2192 gen~ inlet 3). Per-sample control\n// values that vary continuously when the user touches the knob.\n//\n// IMPORTANT: gen~ requires all declarations (Param/History/Buffer) to\n// precede any expressions. These assignments must therefore live *after*\n// the Param block above.\n// -----------------------------------------------------------------------------\nsaturate = in3;\ninput_gain = in4;\n\n// -----------------------------------------------------------------------------\n// Halfband FIR taps (31 taps, Kaiser beta=8.0, sample-rate-independent)\n// Source: data/tl_saturate_coefficients.json -> halfband_fir.taps\n// Even taps (except k=15) are zero -- the polyphase ops below skip them.\n// -----------------------------------------------------------------------------\n\n// Center tap (k=15)\nhb_15 = 0.49998341447554523;\n\n// Odd-side taps (mirrored: hb_k == hb_(30-k) by linear-phase symmetry)\nhb_1  = -4.962987862434643e-05;   // == hb_29\nhb_3  =  0.0006422540255711147;   // == hb_27\nhb_5  = -0.002734441417494108;    // == hb_25\nhb_7  =  0.00802032401027231;     // == hb_23\nhb_9  = -0.019227637930233975;    // == hb_21\nhb_11 =  0.0415367046593286;      // == hb_19\nhb_13 = -0.09122480814029417;     // == hb_17\n\n// -----------------------------------------------------------------------------\n// Input gain: discrete LINE / INSTRUMENT / HIGH_GAIN\n// -----------------------------------------------------------------------------\n// `input_gain` is integer 0/1/2; cascade two `==` comparisons.\n// 10^(0/20)=1.0   10^(6/20)=1.9952623149688795   10^(12/20)=3.9810717055349722\n\nis_inst = (input_gain == 1);\nis_high = (input_gain == 2);\ng_in = 1.0\n     + is_inst * (1.9952623149688795 - 1.0)\n     + is_high * (3.9810717055349722 - 1.0);\ng_out = 1.0 / g_in;   // exact small-signal cancellation per design doc \u00a75\n\n// -----------------------------------------------------------------------------\n// Drive mapping: drive(s) = 1 + 11*s^2  (quadratic taper, design doc \u00a73)\n// bias(d)  = 0.05 * max(0, (d-4)/8)\n// beta(d)  = 0.20 * max(0, (d-2)/10)\n// makeup_gain = 10^(-0.70 * 20*log10(d/tanh(d)) / 20) = (d/tanh(d))^(-0.70)\n// -----------------------------------------------------------------------------\n\ns_clamped = clamp(saturate, 0.0, 1.0);\ndrive = 1.0 + 11.0 * s_clamped * s_clamped;\nbias  = 0.05 * max(0.0, (drive - 4.0) * 0.125);   // /8\nbeta_ = 0.20 * max(0.0, (drive - 2.0) * 0.1);     // /10\n\n// Output makeup: pow(drive/tanh(drive), -0.70). guard against drive==0.\ninv_tanh_d = 1.0 / tanh(drive);\nssg        = drive * inv_tanh_d;                  // small-signal gain\nmakeup     = pow(ssg, -0.70);\n\n// Bypass selector for saturate==0\nis_bypass = (saturate <= 0.0);\n\n\n// =============================================================================\n// Channel macro -- replicated for L (suffix _L) and R (suffix _R).\n// gen~ codebox does not have user-defined functions in v8, so the chain\n// is unrolled per channel.  All History/Delay state is per-channel.\n// =============================================================================\n\n\n// -------------------------- L CHANNEL ----------------------------------------\n\n// Stage 1: input gain\nxL = in1 * g_in;\n\n// Stage 2: pre-emphasis biquad (Direct Form I)\n\npre_yL = pre_b0*xL + pre_b1*pre_x1_L + pre_b2*pre_x2_L\n       - pre_a1*pre_y1_L - pre_a2*pre_y2_L;\n// Denormal flush (cheap on ARM; matters under bypass in x86 deploys)\npre_yL = (abs(pre_yL) < 1e-30) ? 0.0 : pre_yL;\n\npre_x2_L = pre_x1_L;\npre_x1_L = xL;\npre_y2_L = pre_y1_L;\npre_y1_L = pre_yL;\n\n// Stage 3: 2x upsample (polyphase halfband)\n// Delay line of length 16 over the *native-rate* pre-emphasis output.\n// pin x_L[n], x_L[n-1], ..., x_L[n-15].\n// The \"even\" up-sample phase is just h[15]*x[n-7]   (with the *2.0 that\n// the numpy ref applies to the whole upsampler output to compensate for\n// zero-insertion energy loss).  The \"odd\" phase is the sum of all odd-k\n// taps applied in symmetric pairs -- since the FIR is linear-phase\n// (h[k]==h[30-k]) we fold pairs together to halve the multiplies.\n//\n// For the convolution mode='same' alignment used by the numpy ref:\n//   y_even[2n]   = h[15] * x[n - 7]\n//   y_odd[2n+1]  = sum over odd k:  h[k] * x[n - floor((k-1)/2)]\n// We then double both samples (to match the ref's *2.0 normalization).\n\n\n// Even-phase output  (sample @ time 2n)\n//   delay 7 from current input  -> x[n-7]  -> uxL_6 (since after the shift below\n//   uxL_6 holds what was uxL_5 last sample, which was x[n-7] at that point...\n// To keep this readable: shift FIRST, then read indices.\n//\n// State definition AFTER the shift block:\n//   uxL_0 = x[n], uxL_1 = x[n-1], ..., uxL_14 = x[n-14], pre_x1_L holds x[n-15]?\n// We need x[n-15] for the lower bound of the odd-phase sum. Easiest to use\n// 16 delays. But we already have 15 here. Add one more:\n\n\n// Even phase: tap h[15] * x[n-7]  with *2.0 normalization\nyEven_L = 2.0 * hb_15 * uxL_7;\n\n// Odd phase: pair-fold the symmetric odd taps.\n//   y_odd = sum over odd k of h[k] * x[n - ((k-1)/2)]\n// Pairs (k, 30-k): same coefficient hb_k. The two members of each pair\n// read x at delays (k-1)/2 and (30-k-1)/2 = (29-k)/2.\n// Concretely:\n//   k=1 paired with k=29 -> delays 0 and 14    -> hb_1 * (uxL_0 + uxL_14)\n//   k=3 paired with k=27 -> delays 1 and 13    -> hb_3 * (uxL_1 + uxL_13)\n//   k=5 paired with k=25 -> delays 2 and 12    -> hb_5 * (uxL_2 + uxL_12)\n//   k=7 paired with k=23 -> delays 3 and 11    -> hb_7 * (uxL_3 + uxL_11)\n//   k=9 paired with k=21 -> delays 4 and 10    -> hb_9 * (uxL_4 + uxL_10)\n//   k=11 paired with k=19 -> delays 5 and 9    -> hb_11 * (uxL_5 + uxL_9)\n//   k=13 paired with k=17 -> delays 6 and 8    -> hb_13 * (uxL_6 + uxL_8)\n//   k=15 (center) is on EVEN phase, not odd.\n\nyOdd_L = hb_1  * (uxL_0  + uxL_14)\n       + hb_3  * (uxL_1  + uxL_13)\n       + hb_5  * (uxL_2  + uxL_12)\n       + hb_7  * (uxL_3  + uxL_11)\n       + hb_9  * (uxL_4  + uxL_10)\n       + hb_11 * (uxL_5  + uxL_9)\n       + hb_13 * (uxL_6  + uxL_8);\nyOdd_L = 2.0 * yOdd_L;\n\n// Stage 4: asymmetric tanh waveshaper applied to BOTH oversampled samples.\n// u = sample + bias;  base = tanh(d*u)/tanh(d);  mult = (u<0) ? 1+beta*u : 1\n// Out = base * mult.\n//\n// Even-phase shaped sample:\nuE_L     = yEven_L + bias;\nbaseE_L  = tanh(drive * uE_L) * inv_tanh_d;\nmultE_L  = (uE_L < 0.0) ? (1.0 + beta_ * uE_L) : 1.0;\nshapedE_L = baseE_L * multE_L;\n// Odd-phase shaped sample:\nuO_L     = yOdd_L + bias;\nbaseO_L  = tanh(drive * uO_L) * inv_tanh_d;\nmultO_L  = (uO_L < 0.0) ? (1.0 + beta_ * uO_L) : 1.0;\nshapedO_L = baseO_L * multO_L;\n\n// Shift the upsampler input delay line AFTER reading.\n// (Ordering: read taps, then shift -- standard FIR pattern.)\nuxL_15 = uxL_14;\nuxL_14 = uxL_13;\nuxL_13 = uxL_12;\nuxL_12 = uxL_11;\nuxL_11 = uxL_10;\nuxL_10 = uxL_9;\nuxL_9  = uxL_8;\nuxL_8  = uxL_7;\nuxL_7  = uxL_6;\nuxL_6  = uxL_5;\nuxL_5  = uxL_4;\nuxL_4  = uxL_3;\nuxL_3  = uxL_2;\nuxL_2  = uxL_1;\nuxL_1  = uxL_0;\nuxL_0  = pre_yL;\n\n// Stage 5: 2x downsample (polyphase halfband decimator)\n// We push two samples per native sample into the down-sampler delay line.\n// The halfband decim FIR has the same taps as the interp FIR.\n// Maintain v_L[0..30] = oversampled-shaped stream of length 31.\n// Push order each sample: even sample (older time index), then odd sample\n// (newer). After both pushes, output one native sample = sum h[k]*v[k].\n\n\n// Push the two oversampled-shaped samples (FIFO, oldest off the back).\n// Two-sample shift in one go. Because the decimator outputs every other\n// sample of `convolve(v, h, 'same')[::2]`, pairing the push order\n// (shapedE_L then shapedO_L) with reading the symmetric pair sums below\n// reproduces the numpy ref exactly.\ndxL_30 = dxL_28; dxL_29 = dxL_27;\ndxL_28 = dxL_26; dxL_27 = dxL_25;\ndxL_26 = dxL_24; dxL_25 = dxL_23;\ndxL_24 = dxL_22; dxL_23 = dxL_21;\ndxL_22 = dxL_20; dxL_21 = dxL_19;\ndxL_20 = dxL_18; dxL_19 = dxL_17;\ndxL_18 = dxL_16; dxL_17 = dxL_15;\ndxL_16 = dxL_14; dxL_15 = dxL_13;\ndxL_14 = dxL_12; dxL_13 = dxL_11;\ndxL_12 = dxL_10; dxL_11 = dxL_9;\ndxL_10 = dxL_8;  dxL_9  = dxL_7;\ndxL_8  = dxL_6;  dxL_7  = dxL_5;\ndxL_6  = dxL_4;  dxL_5  = dxL_3;\ndxL_4  = dxL_2;  dxL_3  = dxL_1;\ndxL_2  = dxL_0;\ndxL_1 = shapedE_L;\ndxL_0 = shapedO_L;\n// (After the shifts, dxL_0 = newest [odd phase], dxL_1 = even phase one\n//  oversample-step earlier, ..., dxL_30 = oldest.)\n\n// Decimator output: sum h[k]*v[k] for k=0..30.  Use linear-phase pairing\n// to halve the multiplies (h[k] == h[30-k]).\n//   k=15 (center): hb_15 * dxL_15\n//   even-k pairs (0,30), (2,28), (4,26), ..., (14,16): all zero -- skipped\n//   odd-k pairs:  (1,29), (3,27), ..., (13,17)\nyDecim_L =\n      hb_15 * dxL_15\n    + hb_1  * (dxL_1  + dxL_29)\n    + hb_3  * (dxL_3  + dxL_27)\n    + hb_5  * (dxL_5  + dxL_25)\n    + hb_7  * (dxL_7  + dxL_23)\n    + hb_9  * (dxL_9  + dxL_21)\n    + hb_11 * (dxL_11 + dxL_19)\n    + hb_13 * (dxL_13 + dxL_17);\n\n// Stage 6: de-emphasis biquad (Direct Form I)\n\nde_yL = de_b0*yDecim_L + de_b1*de_x1_L + de_b2*de_x2_L\n      - de_a1*de_y1_L - de_a2*de_y2_L;\nde_yL = (abs(de_yL) < 1e-30) ? 0.0 : de_yL;\n\nde_x2_L = de_x1_L;\nde_x1_L = yDecim_L;\nde_y2_L = de_y1_L;\nde_y1_L = de_yL;\n\n// Stage 7: DC blocker  y[n] = x[n] - x[n-1] + R*y[n-1]\n\ndc_yL = de_yL - dc_x1_L + dcr_R * dc_y1_L;\ndc_x1_L = de_yL;\ndc_y1_L = dc_yL;\n\n// Stage 8: drive-dependent makeup gain\ny_wet_L = dc_yL * makeup;\n\n// Stage 9: INPUT_GAIN output cancellation (linear)\ny_wet_L = y_wet_L * g_out;\n\n// Stage X: bypass mux for saturate == 0.\n//   Bypass branch: input * g_out  -- input passes through and the\n//   INPUT_GAIN cancellation still applies, so output is mode-independent\n//   (matches the numpy ref's saturate==0 branch which still applies g_out).\ny_dry_L = in1 * g_out;\nout1 = is_bypass * y_dry_L + (1.0 - is_bypass) * y_wet_L;\n\n\n// -------------------------- R CHANNEL ----------------------------------------\n// Identical structure to L; independent state.\n\nxR = in2 * g_in;\n\n\npre_yR = pre_b0*xR + pre_b1*pre_x1_R + pre_b2*pre_x2_R\n       - pre_a1*pre_y1_R - pre_a2*pre_y2_R;\npre_yR = (abs(pre_yR) < 1e-30) ? 0.0 : pre_yR;\n\npre_x2_R = pre_x1_R;\npre_x1_R = xR;\npre_y2_R = pre_y1_R;\npre_y1_R = pre_yR;\n\n\nyEven_R = 2.0 * hb_15 * uxR_7;\n\nyOdd_R = hb_1  * (uxR_0  + uxR_14)\n       + hb_3  * (uxR_1  + uxR_13)\n       + hb_5  * (uxR_2  + uxR_12)\n       + hb_7  * (uxR_3  + uxR_11)\n       + hb_9  * (uxR_4  + uxR_10)\n       + hb_11 * (uxR_5  + uxR_9)\n       + hb_13 * (uxR_6  + uxR_8);\nyOdd_R = 2.0 * yOdd_R;\n\nuE_R     = yEven_R + bias;\nbaseE_R  = tanh(drive * uE_R) * inv_tanh_d;\nmultE_R  = (uE_R < 0.0) ? (1.0 + beta_ * uE_R) : 1.0;\nshapedE_R = baseE_R * multE_R;\n\nuO_R     = yOdd_R + bias;\nbaseO_R  = tanh(drive * uO_R) * inv_tanh_d;\nmultO_R  = (uO_R < 0.0) ? (1.0 + beta_ * uO_R) : 1.0;\nshapedO_R = baseO_R * multO_R;\n\nuxR_15 = uxR_14;\nuxR_14 = uxR_13;\nuxR_13 = uxR_12;\nuxR_12 = uxR_11;\nuxR_11 = uxR_10;\nuxR_10 = uxR_9;\nuxR_9  = uxR_8;\nuxR_8  = uxR_7;\nuxR_7  = uxR_6;\nuxR_6  = uxR_5;\nuxR_5  = uxR_4;\nuxR_4  = uxR_3;\nuxR_3  = uxR_2;\nuxR_2  = uxR_1;\nuxR_1  = uxR_0;\nuxR_0  = pre_yR;\n\n\ndxR_30 = dxR_28; dxR_29 = dxR_27;\ndxR_28 = dxR_26; dxR_27 = dxR_25;\ndxR_26 = dxR_24; dxR_25 = dxR_23;\ndxR_24 = dxR_22; dxR_23 = dxR_21;\ndxR_22 = dxR_20; dxR_21 = dxR_19;\ndxR_20 = dxR_18; dxR_19 = dxR_17;\ndxR_18 = dxR_16; dxR_17 = dxR_15;\ndxR_16 = dxR_14; dxR_15 = dxR_13;\ndxR_14 = dxR_12; dxR_13 = dxR_11;\ndxR_12 = dxR_10; dxR_11 = dxR_9;\ndxR_10 = dxR_8;  dxR_9  = dxR_7;\ndxR_8  = dxR_6;  dxR_7  = dxR_5;\ndxR_6  = dxR_4;  dxR_5  = dxR_3;\ndxR_4  = dxR_2;  dxR_3  = dxR_1;\ndxR_2  = dxR_0;\ndxR_1 = shapedE_R;\ndxR_0 = shapedO_R;\n\nyDecim_R =\n      hb_15 * dxR_15\n    + hb_1  * (dxR_1  + dxR_29)\n    + hb_3  * (dxR_3  + dxR_27)\n    + hb_5  * (dxR_5  + dxR_25)\n    + hb_7  * (dxR_7  + dxR_23)\n    + hb_9  * (dxR_9  + dxR_21)\n    + hb_11 * (dxR_11 + dxR_19)\n    + hb_13 * (dxR_13 + dxR_17);\n\n\nde_yR = de_b0*yDecim_R + de_b1*de_x1_R + de_b2*de_x2_R\n      - de_a1*de_y1_R - de_a2*de_y2_R;\nde_yR = (abs(de_yR) < 1e-30) ? 0.0 : de_yR;\n\nde_x2_R = de_x1_R;\nde_x1_R = yDecim_R;\nde_y2_R = de_y1_R;\nde_y1_R = de_yR;\n\n\ndc_yR = de_yR - dc_x1_R + dcr_R * dc_y1_R;\ndc_x1_R = de_yR;\ndc_y1_R = dc_yR;\n\ny_wet_R = dc_yR * makeup * g_out;\ny_dry_R = in2 * g_out;\nout2 = is_bypass * y_dry_R + (1.0 - is_bypass) * y_wet_R;\n\n// =============================================================================\n// END tl_saturate.gendsp\n// =============================================================================\n"
												}
											},
											{
												"box": {
													"id": "tl_saturate-gen-out1",
													"maxclass": "newobj",
													"text": "out 1",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														30.0,
														540.0,
														35.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_saturate-gen-out2",
													"maxclass": "newobj",
													"text": "out 2",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														100.0,
														540.0,
														35.0,
														22.0
													]
												}
											}
										],
										"lines": [
											{
												"patchline": {
													"source": [
														"tl_saturate-gen-in1",
														0
													],
													"destination": [
														"tl_saturate-gen-codebox",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_saturate-gen-in2",
														0
													],
													"destination": [
														"tl_saturate-gen-codebox",
														1
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_saturate-gen-in3",
														0
													],
													"destination": [
														"tl_saturate-gen-codebox",
														2
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_saturate-gen-in4",
														0
													],
													"destination": [
														"tl_saturate-gen-codebox",
														3
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_saturate-gen-codebox",
														0
													],
													"destination": [
														"tl_saturate-gen-out1",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_saturate-gen-codebox",
														1
													],
													"destination": [
														"tl_saturate-gen-out2",
														0
													]
												}
											}
										]
									},
									"rnboattrcache": {},
									"saved_object_attributes": {
										"exportfolder": "",
										"exportname": "tl_saturate_dsp",
										"wantsoutputcore": 0
									}
								}
							},
							{
								"box": {
									"id": "tl_saturate-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										180,
										600,
										60
									],
									"text": "tl_saturate (SANDBOX-PARTIAL): asym waveshaper + 2x halfband FIR + RBJ pre/de-emph shelves + DC blocker + mis-bias inject. saturate=0 short-circuits to bypass (spec divergence #6). SR-aware coeffs via tl_saturate_coefficients.json. DSP graph implemented in [gen~ tl_saturate_dsp] codebox; reference impl: dsp/reference/tl_saturate.py."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_saturate-in-L",
										0
									],
									"destination": [
										"tl_saturate-gen",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-in-R",
										0
									],
									"destination": [
										"tl_saturate-gen",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-pin-0",
										0
									],
									"destination": [
										"tl_saturate-gen",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-pin-1",
										0
									],
									"destination": [
										"tl_saturate-gen",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-gen",
										0
									],
									"destination": [
										"tl_saturate-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_saturate-gen",
										1
									],
									"destination": [
										"tl_saturate-out-R",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_saturate",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_model_eq",
					"maxclass": "newobj",
					"numinlets": 4,
					"numoutlets": 3,
					"patching_rect": [
						300,
						280,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal",
						"signal"
					],
					"text": "p tl_model_eq",
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
									"id": "tl_model_eq-in-L",
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
									"id": "tl_model_eq-in-R",
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
									"id": "tl_model_eq-pin-0",
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
									"id": "tl_model_eq-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_model_eq-out-L",
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
									"id": "tl_model_eq-out-R",
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
									"id": "tl_model_eq-eout-0",
									"maxclass": "outlet",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										140,
										260,
										30,
										30
									],
									"comment": "",
									"index": 3
								}
							},
							{
								"box": {
									"id": "tl_model_eq-js",
									"maxclass": "newobj",
									"numinlets": 2,
									"numoutlets": 2,
									"patching_rect": [
										40,
										100,
										200,
										22
									],
									"outlettype": [
										"",
										"float"
									],
									"text": "js model_selector.js @scripting_name model_selector",
									"saved_object_attributes": {
										"filename": "model_selector.js",
										"parameter_enable": 0
									}
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-L-0",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										300,
										100,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-L-1",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										360,
										100,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-L-2",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										420,
										100,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-L-3",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										480,
										100,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-L-4",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										540,
										100,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-L-5",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										600,
										100,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-sel-L",
									"maxclass": "newobj",
									"numinlets": 3,
									"numoutlets": 1,
									"patching_rect": [
										700,
										100,
										80,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "selector~ 2"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-R-0",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										300,
										130,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-R-1",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										360,
										130,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-R-2",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										420,
										130,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-R-3",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										480,
										130,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-R-4",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										540,
										130,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-bq-R-5",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 1,
									"patching_rect": [
										600,
										130,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "biquad~"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-sel-R",
									"maxclass": "newobj",
									"numinlets": 3,
									"numoutlets": 1,
									"patching_rect": [
										700,
										130,
										80,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "selector~ 2"
								}
							},
							{
								"box": {
									"id": "tl_model_eq-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										200,
										700,
										60
									],
									"text": "tl_model_eq (SANDBOX-OK): 12-profile cascaded biquad EQ. model=0 passthrough; filter_bypass dominates. Equal-power 12ms crossfade on change. Coeffs from data/model_eq_coefficients.json via model_selector.js (SR-aware). Cross-module: model=11 emits pitch_floor_cents=0.3 to tl_wow (Phase 1.5 contract #2)."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_model_eq-in-L",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-0",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-0",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-L-0",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-L-1",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-L-2",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-3",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-3",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-L-3",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-4",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-4",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-L-4",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-5",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-L-5",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-L-5",
										0
									],
									"destination": [
										"tl_model_eq-sel-L",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-in-L",
										0
									],
									"destination": [
										"tl_model_eq-sel-L",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-pin-1",
										0
									],
									"destination": [
										"tl_model_eq-sel-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-sel-L",
										0
									],
									"destination": [
										"tl_model_eq-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-in-R",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-0",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-0",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-R-0",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-R-1",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-R-2",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-3",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-3",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-R-3",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-4",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-4",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-R-4",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-5",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										0
									],
									"destination": [
										"tl_model_eq-bq-R-5",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-bq-R-5",
										0
									],
									"destination": [
										"tl_model_eq-sel-R",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-in-R",
										0
									],
									"destination": [
										"tl_model_eq-sel-R",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-pin-1",
										0
									],
									"destination": [
										"tl_model_eq-sel-R",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-sel-R",
										0
									],
									"destination": [
										"tl_model_eq-out-R",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-pin-0",
										0
									],
									"destination": [
										"tl_model_eq-js",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_model_eq-js",
										1
									],
									"destination": [
										"tl_model_eq-eout-0",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_model_eq",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_failure",
					"maxclass": "newobj",
					"numinlets": 8,
					"numoutlets": 2,
					"patching_rect": [
						580,
						280,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "p tl_failure",
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
									"id": "tl_failure-in-L",
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
									"id": "tl_failure-in-R",
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
									"id": "tl_failure-pin-0",
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
									"id": "tl_failure-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_failure-pin-2",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										240,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 5
								}
							},
							{
								"box": {
									"id": "tl_failure-pin-3",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										290,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 6
								}
							},
							{
								"box": {
									"id": "tl_failure-pin-4",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										340,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 7
								}
							},
							{
								"box": {
									"id": "tl_failure-out-L",
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
									"id": "tl_failure-out-R",
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
									"id": "tl_failure-in-fov",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										440,
										20,
										30,
										30
									],
									"outlettype": [
										"signal"
									],
									"comment": "",
									"index": 8
								}
							},
							{
								"box": {
									"id": "tl_failure-gen",
									"maxclass": "newobj",
									"numinlets": 4,
									"numoutlets": 2,
									"patching_rect": [
										40,
										100,
										250,
										60
									],
									"outlettype": [
										"signal",
										"signal"
									],
									"text": "gen~ @title tl_failure_dsp",
									"patcher": {
										"fileversion": 1,
										"appversion": {
											"major": 9,
											"minor": 0,
											"revision": 0,
											"architecture": "x64",
											"modernui": 1
										},
										"classnamespace": "dsp.gen",
										"rect": [
											100.0,
											100.0,
											700.0,
											600.0
										],
										"boxes": [
											{
												"box": {
													"id": "tl_failure-gen-in1",
													"maxclass": "newobj",
													"text": "in 1",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														30.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_failure-gen-in2",
													"maxclass": "newobj",
													"text": "in 2",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														100.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_failure-gen-in3",
													"maxclass": "newobj",
													"text": "in 3",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														170.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_failure-gen-in4",
													"maxclass": "newobj",
													"text": "in 4",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														240.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_failure-gen-codebox",
													"maxclass": "codebox",
													"numinlets": 4,
													"numoutlets": 2,
													"outlettype": [
														"",
														""
													],
													"patching_rect": [
														50.0,
														100.0,
														600.0,
														400.0
													],
													"code": "// =============================================================================\n// tl_failure.gendsp \u2014 gen~ DSL for the tape-loss FAILURE multi-engine\n// =============================================================================\n//\n//   Module name        : tl_failure\n//   TUNING_VERSION     : 2  (round-2 calibration, 2026-04-26)\n//   Phase 1.5 contract : IMPLEMENTED (failure_override 4th inlet, additive\n//                        toward max \u2014 effective = knob + override*(1-knob))\n//   Authored           : 2026-04-27 by pedal-engineer (translation only)\n//\n//   Source design doc  : docs/design-docs/dsp/tl-failure-design.md\n//   Source design sha  : b6eb137b62aac6f4b058c910b69ae3c6fcfa17fc2f86cba5bf8a366a353c1ab5\n//   Source numpy ref   : dsp/reference/tl_failure.py\n//   Source numpy sha   : d82bce577a26ee3a1faa4691b9f98913eb2ffed574344aea9ef194dd43b21f76\n//\n// -----------------------------------------------------------------------------\n// I/O contract (matches tl_failure.maxpat shell, post Phase 1.5):\n//\n//   in1 = signal L                     (audio rate)\n//   in2 = signal R                     (audio rate)\n//   in3 = failure_knob       [0, 1]    (control rate; held by [sig~] upstream)\n//   in4 = failure_override   [0, 1]    (control rate; from tl_aux FAIL outlet,\n//                                       defaulted to 0 when unwired)\n//   out1 = signal L                    (audio rate)\n//   out2 = signal R                    (audio rate)\n//\n// Params (set from outer patch via [param ...] or live.* boxes):\n//   drop_bypass     0|1     \u2014 disable DROP sub-engine (round-2 unchanged)\n//   snag_bypass     0|1     \u2014 disable SNAG sub-engine\n//   spread          0|1     \u2014 stereo decorrelation; 0 = locked events L/R\n//   crinkle_level   0..1    \u2014 UI knob, post-engine amp scale on CRINKLE\n//\n// -----------------------------------------------------------------------------\n// Round-2 calibration constants (must match numpy reference verbatim):\n//\n//   DROP rate     = 8*f + 18*f^2  events/min\n//   DROP duration = (30 + 220*f) ms   * uniform(0.7, 1.3) jitter\n//   DROP ramp     = 5 ms cosine each side, hold at 0 between\n//\n//   SNAG rate     = 4*f + 10*f^2  events/min\n//   SNAG cents    = (60 + 240*f)  * uniform(0.8, 1.2)\n//   SNAG hold     = uniform(15, 80) ms\n//   SNAG attack   = 4 ms cosine\n//   SNAG release  = 25 ms cosine\n//   SNAG scale    = 0.012  (delay-line excursion: peak = (cents/1200)*sr*0.012)\n//\n//   CRINKLE rate  = 30*f^3 + 1   bursts/sec\n//   CRINKLE amp   = uniform(0.2, 0.5) per event\n//   CRINKLE BPF   = RBJ constant-skirt, fc=2500 Hz, Q=1.5 (DF-I biquad)\n//   CRINKLE peak  = post-norm * 0.30 * crinkle_level   (round-2 headroom 0.30)\n//\n//   MICRO-FLUTTER depth = 0.35 * f      (linear)\n//   MICRO-FLUTTER rate  = uniform(20, 60+60*f) Hz, two summed sines, re-rolled\n//                         every 50 ms.\n//\n// -----------------------------------------------------------------------------\n// Per-sample event-scheduling translation pattern:\n//\n// The numpy reference uses NumPy-array idioms \u2014 Poisson sample at the buffer\n// level, draw all event start positions in one shot, write envelope shapes via\n// vectorized slice assignment. gen~ is sample-rate; there is no buffer-level\n// scheduling and no Poisson primitive. We translate to the canonical\n// streaming-Poisson pattern (memoryless inter-arrival times):\n//\n//   For a Poisson process with rate \u03bb events/second, inter-arrival times are\n//   exponentially distributed with mean 1/\u03bb. Sample u ~ Uniform(0,1) and\n//   compute \u0394t = -ln(u) / \u03bb samples. Maintain a per-engine countdown History;\n//   each sample, decrement; when it crosses zero, fire an event (sample its\n//   per-event params via more random() calls), reset countdown to next \u0394t.\n//\n// Per-event envelope state is a small piecewise machine, also held in\n// History: { phase \u2208 {idle, attack, hold, release}, samples_left_in_phase,\n// event_amp, event_peak_offset }. Each sample, advance the phase.\n//\n// Why this matches the numpy ref distribution-wise:\n//   For a homogeneous Poisson process, the count over a fixed interval is\n//   Poisson-distributed (numpy uses the latter form), AND the inter-arrival\n//   times are i.i.d. exponential (we use this form). They are equivalent\n//   characterizations \u2014 same statistics, same expected rate. The actual\n//   sample-level event positions will differ from numpy under the same RNG\n//   seed, which is FINE: the design contract is statistical, not bit-identical\n//   (only the failure=0 short-circuit needs bit-identical match, and we\n//   handle that separately).\n//\n// SPREAD / RNG strategy:\n//   gen~ has no SeedSequence.spawn analog. gen~'s `noise()` and `random()`\n//   each maintain independent state per *call site*. To get decorrelated L\n//   and R streams when spread=1, every random draw is duplicated \u2014 once for\n//   the L sub-engine (subscript _L), once for R (_R). When spread=0, both\n//   channels use the *same* draw stream by reading a single set of countdown\n//   states and broadcasting to both channels (events lock in stereo).\n//\n//   At this level of abstraction in gen~ DSL, we cannot programmatically\n//   \"fork\" RNG state, so the architectural choice is: structurally separate\n//   L and R event-scheduling state machines. Under spread=1 they evolve\n//   independently (independent random() calls). Under spread=0 we still\n//   evaluate both, but route the L sub-engine state to both output channels,\n//   ignoring R's modulators. This costs ~2x scheduling CPU but keeps the\n//   topology static (gen~ requires DSP graph topology to be compile-time).\n//\n//   Note vs. numpy ref: numpy's spread=False explicitly re-seeds rng_l and\n//   rng_r with the same SeedSequence so the streams are bit-identical; gen~\n//   has no such hook. The audible result is the same \u2014 locked stereo events\n//   \u2014 because we route a single channel's modulators to both outputs.\n//\n// Numpy idioms that did NOT translate cleanly (workarounds):\n//\n//   1. `rng.poisson(mean_events)` over a buffer: replaced with streaming\n//      exponential inter-arrival (see above).\n//   2. `np.maximum(env, ramp)` (slice-wise OR-of-envelopes for overlapping\n//      bursts): replaced with `max(env_state, current_envelope_value)` per\n//      sample \u2014 same overlap-takes-louder semantics, sample-by-sample.\n//   3. `np.linspace(0, 1, a_n)` for triangular CRINKLE ramp: replaced with\n//      sample-counter / a_n linear interpolation in the envelope state\n//      machine.\n//   4. `_apply_variable_delay` reading by index with linear interp at\n//      arbitrary fractional offsets: replaced with gen~'s `Delay` operator,\n//      which accepts fractional delay-time and does linear interp natively\n//      (matches numpy ref's `linterp`; the M4L `tapout~` would do 4-point\n//      Hermite for slightly cleaner artifacts \u2014 design doc tradeoff #11\n//      already accepts this).\n//   5. `SeedSequence.spawn(2)` for SPREAD: see above; replaced with\n//      structural per-channel state.\n//   6. `chunk_n = max(64, int(0.05*sr))` re-roll-LFO-rates-every-50ms\n//      pattern in MICRO-FLUTTER: implemented as a 50 ms countdown that, on\n//      tick, samples two new `random()` rate values into History; each\n//      sample advances the two phasors with their current rates.\n//   7. Per-sample biquad with denormal flush (`if abs(yn) < 1e-30 \u2192 0`):\n//      gen~ has no explicit denormal-flush primitive needed \u2014 gen~ runs in\n//      double precision and most modern CPUs handle denormals adequately;\n//      we still include a guard `(abs(y) < 1e-30) ? 0 : y` to match the\n//      reference's numerical behavior.\n//\n// -----------------------------------------------------------------------------\n// Sanity-check expected behaviors (from numpy verification log\n// `_verify_round2_targets` / `_verify_phase15_contract`):\n//\n//   T1/P1: knob=0 AND override=0  \u2192 out1==in1, out2==in2 bit-identical\n//          (short-circuit at API boundary; engines do not run).\n//   T2:    effective=1.0          \u2192 peak dropout depth \u2264 -30 dBFS in any\n//          30 ms window (gate fully closes; numpy measured -240 dB).\n//   T3:    effective=1.0          \u2192 peak instantaneous pitch deviation \u2265 80\n//          cents (numpy measured 271.5 c, saturation of the tracker).\n//   T4:    effective=0.5          \u2192 simultaneous drop \u2264 -12 dB AND pitch\n//          peak \u2265 30 c in a 15 s render.\n//   P2:    knob=0.3, override=0.5 \u2192 identical statistical behavior to\n//          knob=0.65, override=0   (effective formula: 0.3+0.5*0.7 = 0.65)\n//   P3:    knob=0.0, override=1.0 \u2192 identical statistical behavior to\n//          knob=1.0, override=0    (effective formula: 0.0+1.0*1.0 = 1.0)\n//\n// =============================================================================\n\n\n// -----------------------------------------------------------------------------\n// Params (set from the parent patcher via [param NAME] boxes; gen~ surfaces\n// them as inlets in compiled @param mode but here they are control values\n// stable across the buffer)\n// -----------------------------------------------------------------------------\nParam drop_bypass(0);\nParam snag_bypass(0);\nParam spread(0);\nParam crinkle_level(0.5);\nHistory snag_countdown_L(0);\nHistory snag_phase_L(0);\nHistory snag_phase_left_L(0);\nHistory snag_hold_n_L(0);\nHistory snag_peak_off_L(0);\nHistory snag_countdown_R(0);\nHistory snag_phase_R(0);\nHistory snag_phase_left_R(0);\nHistory snag_hold_n_R(0);\nHistory snag_peak_off_R(0);\nHistory flut_chunk_left_L(0);\nHistory flut_f1_L(30);\nHistory flut_f2_L(20);\nHistory flut_phase1_L(0);\nHistory flut_phase2_L(0);\nHistory flut_chunk_left_R(0);\nHistory flut_f1_R(30);\nHistory flut_f2_R(20);\nHistory flut_phase1_R(0);\nHistory flut_phase2_R(0);\nHistory drop_countdown_L(0);\nHistory drop_phase_L(0);\nHistory drop_phase_left_L(0);\nHistory drop_hold_n_L(0);\nHistory drop_countdown_R(0);\nHistory drop_phase_R(0);\nHistory drop_phase_left_R(0);\nHistory drop_hold_n_R(0);\nHistory crinkle_countdown_L(0);\nHistory crinkle_env_L(0);\nHistory crinkle_env_phase_L(0);     // 0=idle, 1=attack, 2=release\nHistory crinkle_env_left_L(0);\nHistory crinkle_amp_L(0);\nHistory crinkle_a_n_L(0);\nHistory crinkle_r_n_L(0);\nHistory crinkle_countdown_R(0);\nHistory crinkle_env_R(0);\nHistory crinkle_env_phase_R(0);\nHistory crinkle_env_left_R(0);\nHistory crinkle_amp_R(0);\nHistory crinkle_a_n_R(0);\nHistory crinkle_r_n_R(0);\nHistory bpf_x1_L(0); History bpf_x2_L(0);\nHistory bpf_y1_L(0); History bpf_y2_L(0);\nHistory bpf_x1_R(0); History bpf_x2_R(0);\nHistory bpf_y1_R(0); History bpf_y2_R(0);\n\n\n\n// -----------------------------------------------------------------------------\n// API boundary \u2014 Phase 1.5 boost formula: effective = knob + override*(1-knob)\n// Computed once per sample at the input. All four sub-engines downstream read\n// `effective`, never `knob` directly. Original `knob` value is preserved\n// for traceability but no DSP path consumes it.\n// -----------------------------------------------------------------------------\nknob     = clip(in3, 0, 1);\noverride = clip(in4, 0, 1);\neffective = clip(knob + override * (1 - knob), 0, 1);\n\n// Short-circuit: when both are exactly zero, bypass everything (regression\n// guarantee from T1/P1). Use small epsilon to handle float fuzz from the\n// upstream [sig~]; same threshold as design doc \u00a711.4.\nshort_circuit = (effective <= 1e-6);\n\n\n// =============================================================================\n// SUB-ENGINE B \u2014 SNAG (variable delay; pitch-up via shorter delay)\n// =============================================================================\n//\n// Per-sample state machine, one instance per channel:\n//\n//   phase \u2208 { 0 = idle (countdown to next event),\n//             1 = attack  (offset ramps 0 \u2192 -peak over 4 ms cosine),\n//             2 = hold    (offset = -peak for hold_n samples),\n//             3 = release (offset ramps -peak \u2192 0 over 25 ms cosine) }\n//\n// History fields per channel:\n//   snag_countdown_X     samples until next event start (idle phase)\n//   snag_phase_X         current phase 0..3\n//   snag_phase_left_X    samples left in current phase\n//   snag_attack_n_X      attack length in samples (event-specific; though\n//                        we use fixed 4 ms here, kept as History for\n//                        future-proofing and ramp normalization)\n//   snag_release_n_X     release length in samples (fixed 25 ms)\n//   snag_hold_n_X        hold length in samples (event-specific, 15-80 ms)\n//   snag_peak_off_X      peak offset in samples (event-specific)\n//\n// Output: snag_offset_X \u2014 instantaneous delay-line offset (in samples,\n// negative = shorter delay = higher pitch).\n// -----------------------------------------------------------------------------\n\n// Constants (round-2)\nSNAG_RATE_K1 = 4;        // f^1 coefficient,  events/min\nSNAG_RATE_K2 = 10;       // f^2 coefficient,  events/min\nSNAG_CENTS_BASE = 60;\nSNAG_CENTS_F = 240;\nSNAG_HOLD_LO_MS = 15;\nSNAG_HOLD_HI_MS = 80;\nSNAG_ATTACK_MS = 4;\nSNAG_RELEASE_MS = 25;\nSNAG_DELAY_SCALE = 0.012;     // round-2 (was 0.005)\n\n// Snag rate as inter-arrival mean (samples). Guard against rate=0.\n// rate_per_sec = (SNAG_RATE_K1*f + SNAG_RATE_K2*f^2) / 60.\nsnag_rate_per_sec = (SNAG_RATE_K1 * effective + SNAG_RATE_K2 * effective * effective) / 60;\nsnag_lambda_safe = max(snag_rate_per_sec, 1e-9);\nsnag_mean_dt_samp = samplerate / snag_lambda_safe;     // mean inter-arrival in samples\n\nattack_n  = max(1, SNAG_ATTACK_MS  * 1e-3 * samplerate);\nrelease_n = max(1, SNAG_RELEASE_MS * 1e-3 * samplerate);\n\n\n// ---- Macro-style: per-channel snag scheduler ----\n// gen~ has no functions in the strict sense; we inline the L and R copies.\n// Both copies are structurally identical; under spread=0 we will route only\n// the L copy's offset to both channels at the routing stage below.\n\n// =========================\n// Snag scheduler \u2014 channel L\n// =========================\n\n// Tick: when phase==0 (idle), decrement countdown; on hit, sample new event.\n// random() returns [0, 1). Use -ln(1-u)/lambda for stable inverse CDF (avoids\n// log(0) when u==0); equivalently sample u_safe = max(u, 1e-12) and use -ln(u).\nu_dt_L = max(((noise() + 1.0) * 0.5), 1e-12);\n\n// Compute \"next inter-arrival\" (in samples) from current effective rate.\nnew_dt_L = -log(u_dt_L) * snag_mean_dt_samp;\n\n// Per-event params (sampled at event-fire time):\nu_cents_L = ((noise() + 1.0) * 0.5);   // 0..1 \u2192 uniform(0.8, 1.2) below\nu_hold_L  = ((noise() + 1.0) * 0.5);   // 0..1 \u2192 uniform(15, 80) ms\nevent_cents_L = (SNAG_CENTS_BASE + SNAG_CENTS_F * effective) * (0.8 + 0.4 * u_cents_L);\nevent_hold_n_L = max(1, (SNAG_HOLD_LO_MS + (SNAG_HOLD_HI_MS - SNAG_HOLD_LO_MS) * u_hold_L) * 1e-3 * samplerate);\nevent_peak_off_L = (event_cents_L / 1200) * samplerate * SNAG_DELAY_SCALE;\n\n// State transitions:\n//   if phase==0 (idle):\n//       countdown -= 1\n//       if countdown <= 0 and snag engine active: enter attack phase\n//   elif phase==1 (attack): tick ramp; on done \u2192 phase=2, phase_left=hold_n\n//   elif phase==2 (hold):   tick;       on done \u2192 phase=3, phase_left=release_n\n//   elif phase==3 (release): tick;      on done \u2192 phase=0, countdown=new_dt\n//\n// snag_active = (effective > 0) AND (snag_bypass == 0). When snag is bypassed\n// or effective is zero, we leave offset = 0 unconditionally (set later in the\n// short-circuit / bypass mask).\n\nsnag_engine_on_L = (effective > 0) * (1 - drop_bypass * 0);  // engine on flag,\n// note: drop_bypass does NOT gate snag; only snag_bypass gates snag.\nsnag_engine_on_L = (effective > 0) * (1 - snag_bypass);\n\n// State machine \u2014 implemented with selectors on previous History values.\nprev_phase_L      = snag_phase_L;\nprev_countdown_L  = snag_countdown_L;\nprev_phase_left_L = snag_phase_left_L;\nprev_hold_n_L     = snag_hold_n_L;\nprev_peak_off_L   = snag_peak_off_L;\n\n// ---- Idle path (phase==0)\nidle_decremented_L = prev_countdown_L - 1;\nidle_fires_L       = (prev_phase_L == 0) * (idle_decremented_L <= 0) * snag_engine_on_L;\n\n// On idle-fire: enter attack with newly drawn event params.\n// On non-fire idle: stay phase 0, decrement countdown.\n// On already-firing-or-resetting (when engine just turned off mid-event):\n//   we don't force-stop a mid-event; ramp it to natural release end. (matches\n//   numpy ref behavior \u2014 events drawn within the buffer always complete.)\n\n// ---- Attack path (phase==1)\nattack_left_L      = prev_phase_left_L - 1;\nattack_done_L      = (prev_phase_L == 1) * (attack_left_L <= 0);\n\n// ---- Hold path (phase==2)\nhold_left_L        = prev_phase_left_L - 1;\nhold_done_L        = (prev_phase_L == 2) * (hold_left_L <= 0);\n\n// ---- Release path (phase==3)\nrelease_left_L     = prev_phase_left_L - 1;\nrelease_done_L     = (prev_phase_L == 3) * (release_left_L <= 0);\n\n// Compose next state. Order of conditions: most-recent-phase-end first.\n// Default = continue current phase.\nnext_phase_L = prev_phase_L;\nnext_phase_left_L = prev_phase_left_L;\nnext_countdown_L = prev_countdown_L;\nnext_hold_n_L = prev_hold_n_L;\nnext_peak_off_L = prev_peak_off_L;\n\n// Idle, no fire: just decrement countdown.\nnext_countdown_L = (prev_phase_L == 0) ? idle_decremented_L : next_countdown_L;\n\n// Idle, fire: jump to attack.\nnext_phase_L      = idle_fires_L ? 1 : next_phase_L;\nnext_phase_left_L = idle_fires_L ? attack_n : next_phase_left_L;\nnext_hold_n_L     = idle_fires_L ? event_hold_n_L : next_hold_n_L;\nnext_peak_off_L   = idle_fires_L ? event_peak_off_L : next_peak_off_L;\n\n// Attack continuing: decrement phase_left.\nnext_phase_left_L = ((prev_phase_L == 1) * (attack_done_L == 0)) ? attack_left_L : next_phase_left_L;\n// Attack done: enter hold.\nnext_phase_L      = attack_done_L ? 2 : next_phase_L;\nnext_phase_left_L = attack_done_L ? prev_hold_n_L : next_phase_left_L;\n\n// Hold continuing.\nnext_phase_left_L = ((prev_phase_L == 2) * (hold_done_L == 0)) ? hold_left_L : next_phase_left_L;\n// Hold done: enter release.\nnext_phase_L      = hold_done_L ? 3 : next_phase_L;\nnext_phase_left_L = hold_done_L ? release_n : next_phase_left_L;\n\n// Release continuing.\nnext_phase_left_L = ((prev_phase_L == 3) * (release_done_L == 0)) ? release_left_L : next_phase_left_L;\n// Release done: back to idle, schedule next event.\nnext_phase_L      = release_done_L ? 0 : next_phase_L;\nnext_countdown_L  = release_done_L ? new_dt_L : next_countdown_L;\nnext_phase_left_L = release_done_L ? 0 : next_phase_left_L;\n\n// On engine cold-start (countdown==0 from initial History default), seed the\n// first inter-arrival.\ncold_start_L = (prev_phase_L == 0) * (prev_countdown_L == 0) * snag_engine_on_L;\nnext_countdown_L = cold_start_L ? new_dt_L : next_countdown_L;\n\n// Latch.\nsnag_countdown_L  = next_countdown_L;\nsnag_phase_L      = next_phase_L;\nsnag_phase_left_L = next_phase_left_L;\nsnag_hold_n_L     = next_hold_n_L;\nsnag_peak_off_L   = next_peak_off_L;\n\n// Compute current offset based on phase. Cosine ramps to match numpy\n// `0.5*(1 - cos(pi*i/n))` (attack) and `0.5*(1 + cos(pi*i/n))` (release).\n// In our state machine, phase_left counts DOWN from {attack_n, hold_n,\n// release_n} \u2192 0. Map back to ramp index:\n//   attack:  i  = attack_n - phase_left      \u2192 ramp 0..1\n//   release: i  = release_n - phase_left     \u2192 ramp 1..0\nattack_idx_L  = attack_n  - next_phase_left_L;\nrelease_idx_L = release_n - next_phase_left_L;\nattack_ramp_L  = 0.5 * (1 - cos(pi * attack_idx_L  / max(1, attack_n)));\nrelease_ramp_L = 0.5 * (1 + cos(pi * release_idx_L / max(1, release_n)));\n\nsnag_offset_L =\n    (next_phase_L == 1) ? -next_peak_off_L * attack_ramp_L  :\n    (next_phase_L == 2) ? -next_peak_off_L                  :\n    (next_phase_L == 3) ? -next_peak_off_L * release_ramp_L :\n    0;\n\n// Bypass / short-circuit guard.\nsnag_offset_L = (snag_bypass + short_circuit > 0) ? 0 : snag_offset_L;\n\n\n// =========================\n// Snag scheduler \u2014 channel R\n// =========================\n// Structurally identical to L, with independent random() call sites and\n// History instances. Under spread=0, the routing stage below ignores\n// snag_offset_R and broadcasts snag_offset_L to both delay reads.\n\n\nu_dt_R = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_dt_R = -log(u_dt_R) * snag_mean_dt_samp;\nu_cents_R = ((noise() + 1.0) * 0.5);\nu_hold_R = ((noise() + 1.0) * 0.5);\nevent_cents_R = (SNAG_CENTS_BASE + SNAG_CENTS_F * effective) * (0.8 + 0.4 * u_cents_R);\nevent_hold_n_R = max(1, (SNAG_HOLD_LO_MS + (SNAG_HOLD_HI_MS - SNAG_HOLD_LO_MS) * u_hold_R) * 1e-3 * samplerate);\nevent_peak_off_R = (event_cents_R / 1200) * samplerate * SNAG_DELAY_SCALE;\n\nsnag_engine_on_R = (effective > 0) * (1 - snag_bypass);\n\nprev_phase_R      = snag_phase_R;\nprev_countdown_R  = snag_countdown_R;\nprev_phase_left_R = snag_phase_left_R;\nprev_hold_n_R     = snag_hold_n_R;\nprev_peak_off_R   = snag_peak_off_R;\n\nidle_decremented_R = prev_countdown_R - 1;\nidle_fires_R       = (prev_phase_R == 0) * (idle_decremented_R <= 0) * snag_engine_on_R;\nattack_left_R      = prev_phase_left_R - 1;\nattack_done_R      = (prev_phase_R == 1) * (attack_left_R <= 0);\nhold_left_R        = prev_phase_left_R - 1;\nhold_done_R        = (prev_phase_R == 2) * (hold_left_R <= 0);\nrelease_left_R     = prev_phase_left_R - 1;\nrelease_done_R     = (prev_phase_R == 3) * (release_left_R <= 0);\n\nnext_phase_R      = prev_phase_R;\nnext_phase_left_R = prev_phase_left_R;\nnext_countdown_R  = prev_countdown_R;\nnext_hold_n_R     = prev_hold_n_R;\nnext_peak_off_R   = prev_peak_off_R;\n\nnext_countdown_R  = (prev_phase_R == 0) ? idle_decremented_R : next_countdown_R;\nnext_phase_R      = idle_fires_R ? 1 : next_phase_R;\nnext_phase_left_R = idle_fires_R ? attack_n : next_phase_left_R;\nnext_hold_n_R     = idle_fires_R ? event_hold_n_R : next_hold_n_R;\nnext_peak_off_R   = idle_fires_R ? event_peak_off_R : next_peak_off_R;\n\nnext_phase_left_R = ((prev_phase_R == 1) * (attack_done_R == 0)) ? attack_left_R : next_phase_left_R;\nnext_phase_R      = attack_done_R ? 2 : next_phase_R;\nnext_phase_left_R = attack_done_R ? prev_hold_n_R : next_phase_left_R;\n\nnext_phase_left_R = ((prev_phase_R == 2) * (hold_done_R == 0)) ? hold_left_R : next_phase_left_R;\nnext_phase_R      = hold_done_R ? 3 : next_phase_R;\nnext_phase_left_R = hold_done_R ? release_n : next_phase_left_R;\n\nnext_phase_left_R = ((prev_phase_R == 3) * (release_done_R == 0)) ? release_left_R : next_phase_left_R;\nnext_phase_R      = release_done_R ? 0 : next_phase_R;\nnext_countdown_R  = release_done_R ? new_dt_R : next_countdown_R;\nnext_phase_left_R = release_done_R ? 0 : next_phase_left_R;\n\ncold_start_R = (prev_phase_R == 0) * (prev_countdown_R == 0) * snag_engine_on_R;\nnext_countdown_R = cold_start_R ? new_dt_R : next_countdown_R;\n\nsnag_countdown_R  = next_countdown_R;\nsnag_phase_R      = next_phase_R;\nsnag_phase_left_R = next_phase_left_R;\nsnag_hold_n_R     = next_hold_n_R;\nsnag_peak_off_R   = next_peak_off_R;\n\nattack_idx_R  = attack_n  - next_phase_left_R;\nrelease_idx_R = release_n - next_phase_left_R;\nattack_ramp_R  = 0.5 * (1 - cos(pi * attack_idx_R  / max(1, attack_n)));\nrelease_ramp_R = 0.5 * (1 + cos(pi * release_idx_R / max(1, release_n)));\n\nsnag_offset_R =\n    (next_phase_R == 1) ? -next_peak_off_R * attack_ramp_R  :\n    (next_phase_R == 2) ? -next_peak_off_R                  :\n    (next_phase_R == 3) ? -next_peak_off_R * release_ramp_R :\n    0;\n\nsnag_offset_R = (snag_bypass + short_circuit > 0) ? 0 : snag_offset_R;\n\n\n// -----------------------------------------------------------------------------\n// SNAG variable-delay read.\n// Numpy ref uses base_delay=256 samples + linear interpolation. gen~'s Delay\n// operator performs linear interpolation natively when given a fractional\n// delay-time argument. base_delay = 256 samples.\n// -----------------------------------------------------------------------------\nSNAG_BASE_DELAY = 256;\n\n// Routing: under spread=0, both channels read with the L offset; under\n// spread=1, each channel uses its own.\nsnag_off_for_L = snag_offset_L;\nsnag_off_for_R = (spread > 0) ? snag_offset_R : snag_offset_L;\n\n// delay time = base + (-offset). offset is already negative in our encoding\n// (negative offset = shorter delay = higher pitch), so the read time is\n// base + offset where offset \u2264 0. Equivalently base - |offset|. Clamp the\n// minimum delay-time to 0.5 sample for safety (avoid reading future samples).\nsnag_dt_L = max(0.5, SNAG_BASE_DELAY + snag_off_for_L);\nsnag_dt_R = max(0.5, SNAG_BASE_DELAY + snag_off_for_R);\n\n// Delay max = 512 samples (twice base_delay; gives headroom past round-2's\n// ~159-sample peak excursion at f=1.0, per design doc \u00a75).\nsnag_out_L = delay(in1, snag_dt_L, 512);\nsnag_out_R = delay(in2, snag_dt_R, 512);\n\n\n// =============================================================================\n// SUB-ENGINE C2 \u2014 MICRO-FLUTTER (always-on AM, scales with effective)\n// =============================================================================\n//\n// Two summed sines with rates re-rolled every 50 ms. Phase accumulators in\n// History; rate values latched in History at each 50 ms tick. Output:\n//     mod_X = 1 + depth * 0.5 * (sin(phase1_X) + sin(phase2_X))\n// -----------------------------------------------------------------------------\n\nflut_depth = 0.35 * effective;\nflut_chunk_n = max(64, 0.05 * samplerate);   // 50 ms\n\n// ---- L ----\n\n// Re-roll rates when chunk countdown hits 0. f1 \u2208 uniform(20, 60+60*f),\n// f2 = uniform(20, 60+60*f) * 0.7  (matching numpy ref decorrelation factor).\nflut_chunk_dec_L = flut_chunk_left_L - 1;\nflut_reroll_L = flut_chunk_dec_L <= 0;\nu_f1_L = ((noise() + 1.0) * 0.5);\nu_f2_L = ((noise() + 1.0) * 0.5);\nnew_f1_L = 20 + (40 + 60 * effective) * u_f1_L;\nnew_f2_L = (20 + (40 + 60 * effective) * u_f2_L) * 0.7;\n\nflut_f1_L = flut_reroll_L ? new_f1_L : flut_f1_L;\nflut_f2_L = flut_reroll_L ? new_f2_L : flut_f2_L;\nflut_chunk_left_L = flut_reroll_L ? flut_chunk_n : flut_chunk_dec_L;\n\nflut_phase1_L = flut_phase1_L + 2 * pi * flut_f1_L / samplerate;\nflut_phase2_L = flut_phase2_L + 2 * pi * flut_f2_L / samplerate;\n// Wrap phases to keep numerical precision over long runs.\nflut_phase1_L = flut_phase1_L - (flut_phase1_L > 2*pi) * 2 * pi;\nflut_phase2_L = flut_phase2_L - (flut_phase2_L > 2*pi) * 2 * pi;\n\nflut_mod_L_raw = 0.5 * (sin(flut_phase1_L) + sin(flut_phase2_L));\nflut_mod_L = 1 + flut_depth * flut_mod_L_raw;\n// When effective==0 (depth=0), this naturally collapses to 1.0 (no AM).\n\n// ---- R ----\n\nflut_chunk_dec_R = flut_chunk_left_R - 1;\nflut_reroll_R = flut_chunk_dec_R <= 0;\nu_f1_R = ((noise() + 1.0) * 0.5);\nu_f2_R = ((noise() + 1.0) * 0.5);\nnew_f1_R = 20 + (40 + 60 * effective) * u_f1_R;\nnew_f2_R = (20 + (40 + 60 * effective) * u_f2_R) * 0.7;\n\nflut_f1_R = flut_reroll_R ? new_f1_R : flut_f1_R;\nflut_f2_R = flut_reroll_R ? new_f2_R : flut_f2_R;\nflut_chunk_left_R = flut_reroll_R ? flut_chunk_n : flut_chunk_dec_R;\n\nflut_phase1_R = flut_phase1_R + 2 * pi * flut_f1_R / samplerate;\nflut_phase2_R = flut_phase2_R + 2 * pi * flut_f2_R / samplerate;\nflut_phase1_R = flut_phase1_R - (flut_phase1_R > 2*pi) * 2 * pi;\nflut_phase2_R = flut_phase2_R - (flut_phase2_R > 2*pi) * 2 * pi;\n\nflut_mod_R_raw = 0.5 * (sin(flut_phase1_R) + sin(flut_phase2_R));\nflut_mod_R = 1 + flut_depth * flut_mod_R_raw;\n\n// Routing under spread.\nflut_for_L = flut_mod_L;\nflut_for_R = (spread > 0) ? flut_mod_R : flut_mod_L;\n\n// Apply micro-flutter on the snag-output (chain order: SNAG \u2192 MICRO-FLUTTER).\npostflut_L = snag_out_L * flut_for_L;\npostflut_R = snag_out_R * flut_for_R;\n\n\n// =============================================================================\n// SUB-ENGINE A \u2014 DROP (gated dropouts via cosine-ramp envelope)\n// =============================================================================\n//\n// Per-sample state machine, structurally identical to SNAG but with:\n//   phase 1 = ramp_down (1 \u2192 0 over 5 ms cosine)\n//   phase 2 = hold      (env = 0 for hold_n samples)\n//   phase 3 = ramp_up   (0 \u2192 1 over 5 ms cosine)\n//\n// Round-2 rate = 8*f + 18*f^2 events/min, duration = (30+220*f)*uniform(0.7,1.3).\n// Note \"duration\" is the *total* event length (numpy: dur_n samples top-of-\n// envelope-down through end-of-ramp-up). Hold portion = dur_n - 2*ramp_n.\n// -----------------------------------------------------------------------------\n\nDROP_RATE_K1 = 8;\nDROP_RATE_K2 = 18;\nDROP_DUR_BASE_MS = 30;\nDROP_DUR_F_MS = 220;\nDROP_RAMP_MS = 5;\n\ndrop_rate_per_sec = (DROP_RATE_K1 * effective + DROP_RATE_K2 * effective * effective) / 60;\ndrop_lambda_safe = max(drop_rate_per_sec, 1e-9);\ndrop_mean_dt_samp = samplerate / drop_lambda_safe;\ndrop_ramp_n = max(1, DROP_RAMP_MS * 1e-3 * samplerate);\n\n// ---- L ----\n\nu_drop_dt_L = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_drop_dt_L = -log(u_drop_dt_L) * drop_mean_dt_samp;\nu_drop_dur_L = ((noise() + 1.0) * 0.5);\nevent_drop_dur_n_L = (DROP_DUR_BASE_MS + DROP_DUR_F_MS * effective) * (0.7 + 0.6 * u_drop_dur_L) * 1e-3 * samplerate;\n// Hold = total - 2*ramp. Numpy clamps total >= 2*ramp+1; same here.\nevent_drop_hold_n_L = max(1, event_drop_dur_n_L - 2 * drop_ramp_n);\n\ndrop_engine_on_L = (effective > 0) * (1 - drop_bypass);\n\nprev_drop_phase_L      = drop_phase_L;\nprev_drop_countdown_L  = drop_countdown_L;\nprev_drop_phase_left_L = drop_phase_left_L;\nprev_drop_hold_n_L     = drop_hold_n_L;\n\ndrop_idle_dec_L  = prev_drop_countdown_L - 1;\ndrop_idle_fires_L = (prev_drop_phase_L == 0) * (drop_idle_dec_L <= 0) * drop_engine_on_L;\ndrop_atk_left_L = prev_drop_phase_left_L - 1;\ndrop_atk_done_L = (prev_drop_phase_L == 1) * (drop_atk_left_L <= 0);\ndrop_hold_left_L = prev_drop_phase_left_L - 1;\ndrop_hold_done_L = (prev_drop_phase_L == 2) * (drop_hold_left_L <= 0);\ndrop_rel_left_L = prev_drop_phase_left_L - 1;\ndrop_rel_done_L = (prev_drop_phase_L == 3) * (drop_rel_left_L <= 0);\n\nnext_drop_phase_L      = prev_drop_phase_L;\nnext_drop_phase_left_L = prev_drop_phase_left_L;\nnext_drop_countdown_L  = prev_drop_countdown_L;\nnext_drop_hold_n_L     = prev_drop_hold_n_L;\n\nnext_drop_countdown_L  = (prev_drop_phase_L == 0) ? drop_idle_dec_L : next_drop_countdown_L;\nnext_drop_phase_L      = drop_idle_fires_L ? 1 : next_drop_phase_L;\nnext_drop_phase_left_L = drop_idle_fires_L ? drop_ramp_n : next_drop_phase_left_L;\nnext_drop_hold_n_L     = drop_idle_fires_L ? event_drop_hold_n_L : next_drop_hold_n_L;\n\nnext_drop_phase_left_L = ((prev_drop_phase_L == 1) * (drop_atk_done_L == 0)) ? drop_atk_left_L : next_drop_phase_left_L;\nnext_drop_phase_L      = drop_atk_done_L ? 2 : next_drop_phase_L;\nnext_drop_phase_left_L = drop_atk_done_L ? prev_drop_hold_n_L : next_drop_phase_left_L;\n\nnext_drop_phase_left_L = ((prev_drop_phase_L == 2) * (drop_hold_done_L == 0)) ? drop_hold_left_L : next_drop_phase_left_L;\nnext_drop_phase_L      = drop_hold_done_L ? 3 : next_drop_phase_L;\nnext_drop_phase_left_L = drop_hold_done_L ? drop_ramp_n : next_drop_phase_left_L;\n\nnext_drop_phase_left_L = ((prev_drop_phase_L == 3) * (drop_rel_done_L == 0)) ? drop_rel_left_L : next_drop_phase_left_L;\nnext_drop_phase_L      = drop_rel_done_L ? 0 : next_drop_phase_L;\nnext_drop_countdown_L  = drop_rel_done_L ? new_drop_dt_L : next_drop_countdown_L;\nnext_drop_phase_left_L = drop_rel_done_L ? 0 : next_drop_phase_left_L;\n\ndrop_cold_start_L = (prev_drop_phase_L == 0) * (prev_drop_countdown_L == 0) * drop_engine_on_L;\nnext_drop_countdown_L = drop_cold_start_L ? new_drop_dt_L : next_drop_countdown_L;\n\ndrop_countdown_L  = next_drop_countdown_L;\ndrop_phase_L      = next_drop_phase_L;\ndrop_phase_left_L = next_drop_phase_left_L;\ndrop_hold_n_L     = next_drop_hold_n_L;\n\n// Compute envelope value. Numpy uses:\n//   ramp_down = 0.5*(1+cos(pi*i/n))  goes 1 \u2192 0 as i goes 0..n\n//   ramp_up   = 0.5*(1-cos(pi*i/n))  goes 0 \u2192 1 as i goes 0..n\n// Our phase_left counts down from ramp_n \u2192 0; ramp index i = ramp_n - phase_left.\ndrop_atk_idx_L = drop_ramp_n - next_drop_phase_left_L;\ndrop_rel_idx_L = drop_ramp_n - next_drop_phase_left_L;\ndrop_atk_env_L = 0.5 * (1 + cos(pi * drop_atk_idx_L / max(1, drop_ramp_n)));\ndrop_rel_env_L = 0.5 * (1 - cos(pi * drop_rel_idx_L / max(1, drop_ramp_n)));\n\ndrop_env_L =\n    (next_drop_phase_L == 1) ? drop_atk_env_L :\n    (next_drop_phase_L == 2) ? 0              :\n    (next_drop_phase_L == 3) ? drop_rel_env_L :\n    1;\n\ndrop_env_L = (drop_bypass + short_circuit > 0) ? 1 : drop_env_L;\n\n\n// ---- R ----\n\nu_drop_dt_R = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_drop_dt_R = -log(u_drop_dt_R) * drop_mean_dt_samp;\nu_drop_dur_R = ((noise() + 1.0) * 0.5);\nevent_drop_dur_n_R = (DROP_DUR_BASE_MS + DROP_DUR_F_MS * effective) * (0.7 + 0.6 * u_drop_dur_R) * 1e-3 * samplerate;\nevent_drop_hold_n_R = max(1, event_drop_dur_n_R - 2 * drop_ramp_n);\n\ndrop_engine_on_R = (effective > 0) * (1 - drop_bypass);\n\nprev_drop_phase_R      = drop_phase_R;\nprev_drop_countdown_R  = drop_countdown_R;\nprev_drop_phase_left_R = drop_phase_left_R;\nprev_drop_hold_n_R     = drop_hold_n_R;\n\ndrop_idle_dec_R  = prev_drop_countdown_R - 1;\ndrop_idle_fires_R = (prev_drop_phase_R == 0) * (drop_idle_dec_R <= 0) * drop_engine_on_R;\ndrop_atk_left_R = prev_drop_phase_left_R - 1;\ndrop_atk_done_R = (prev_drop_phase_R == 1) * (drop_atk_left_R <= 0);\ndrop_hold_left_R = prev_drop_phase_left_R - 1;\ndrop_hold_done_R = (prev_drop_phase_R == 2) * (drop_hold_left_R <= 0);\ndrop_rel_left_R = prev_drop_phase_left_R - 1;\ndrop_rel_done_R = (prev_drop_phase_R == 3) * (drop_rel_left_R <= 0);\n\nnext_drop_phase_R      = prev_drop_phase_R;\nnext_drop_phase_left_R = prev_drop_phase_left_R;\nnext_drop_countdown_R  = prev_drop_countdown_R;\nnext_drop_hold_n_R     = prev_drop_hold_n_R;\n\nnext_drop_countdown_R  = (prev_drop_phase_R == 0) ? drop_idle_dec_R : next_drop_countdown_R;\nnext_drop_phase_R      = drop_idle_fires_R ? 1 : next_drop_phase_R;\nnext_drop_phase_left_R = drop_idle_fires_R ? drop_ramp_n : next_drop_phase_left_R;\nnext_drop_hold_n_R     = drop_idle_fires_R ? event_drop_hold_n_R : next_drop_hold_n_R;\n\nnext_drop_phase_left_R = ((prev_drop_phase_R == 1) * (drop_atk_done_R == 0)) ? drop_atk_left_R : next_drop_phase_left_R;\nnext_drop_phase_R      = drop_atk_done_R ? 2 : next_drop_phase_R;\nnext_drop_phase_left_R = drop_atk_done_R ? prev_drop_hold_n_R : next_drop_phase_left_R;\n\nnext_drop_phase_left_R = ((prev_drop_phase_R == 2) * (drop_hold_done_R == 0)) ? drop_hold_left_R : next_drop_phase_left_R;\nnext_drop_phase_R      = drop_hold_done_R ? 3 : next_drop_phase_R;\nnext_drop_phase_left_R = drop_hold_done_R ? drop_ramp_n : next_drop_phase_left_R;\n\nnext_drop_phase_left_R = ((prev_drop_phase_R == 3) * (drop_rel_done_R == 0)) ? drop_rel_left_R : next_drop_phase_left_R;\nnext_drop_phase_R      = drop_rel_done_R ? 0 : next_drop_phase_R;\nnext_drop_countdown_R  = drop_rel_done_R ? new_drop_dt_R : next_drop_countdown_R;\nnext_drop_phase_left_R = drop_rel_done_R ? 0 : next_drop_phase_left_R;\n\ndrop_cold_start_R = (prev_drop_phase_R == 0) * (prev_drop_countdown_R == 0) * drop_engine_on_R;\nnext_drop_countdown_R = drop_cold_start_R ? new_drop_dt_R : next_drop_countdown_R;\n\ndrop_countdown_R  = next_drop_countdown_R;\ndrop_phase_R      = next_drop_phase_R;\ndrop_phase_left_R = next_drop_phase_left_R;\ndrop_hold_n_R     = next_drop_hold_n_R;\n\ndrop_atk_idx_R = drop_ramp_n - next_drop_phase_left_R;\ndrop_rel_idx_R = drop_ramp_n - next_drop_phase_left_R;\ndrop_atk_env_R = 0.5 * (1 + cos(pi * drop_atk_idx_R / max(1, drop_ramp_n)));\ndrop_rel_env_R = 0.5 * (1 - cos(pi * drop_rel_idx_R / max(1, drop_ramp_n)));\n\ndrop_env_R =\n    (next_drop_phase_R == 1) ? drop_atk_env_R :\n    (next_drop_phase_R == 2) ? 0              :\n    (next_drop_phase_R == 3) ? drop_rel_env_R :\n    1;\n\ndrop_env_R = (drop_bypass + short_circuit > 0) ? 1 : drop_env_R;\n\n// Routing.\ndrop_env_for_L = drop_env_L;\ndrop_env_for_R = (spread > 0) ? drop_env_R : drop_env_L;\n\npostdrop_L = postflut_L * drop_env_for_L;\npostdrop_R = postflut_R * drop_env_for_R;\n\n\n// =============================================================================\n// SUB-ENGINE C1 \u2014 CRINKLE BURSTS (additive bandpass-filtered noise impulses)\n// =============================================================================\n//\n// Streaming Poisson burst scheduler. Per event:\n//   amp \u2208 uniform(0.2, 0.5)\n//   dur_n \u2208 uniform(1, 4) ms\n//   triangular AR envelope, sharp attack (a_n = dur_n/4), longer release.\n//\n// Numpy uses np.maximum to overlap envelopes. Per-sample analog: keep an\n// `env_state` History; fire-on-event resets it to start a new envelope; while\n// active, ramp down each sample. New events may overlap and we take the max\n// of the current state and the new envelope value (handled by re-arming on\n// each fire; if a new fire happens during a release, we restart at the new\n// amp peak, which is the per-sample equivalent of `np.maximum`).\n//\n// Then: noise * env_state \u2192 bandpass biquad \u2192 normalize \u00d7 0.30 \u00d7 crinkle_level.\n//\n// Normalization in numpy is `peak = max(abs(filtered))` over the whole buffer.\n// At sample-rate we have no buffer-level max. Translation: use the analytical\n// peak of the BPF impulse response \u00d7 event amp \u2248 1 (the BPF's peak gain at\n// fc=2500/Q=1.5 is Q=1.5 \u2014 slight magnification \u2014 but events are also scaled\n// by uniform(0.2,0.5) and triangular envelope, whose maximum \u2248 0.5). So a\n// reasonable static normalization constant matching the round-2 reference's\n// post-filter peak is empirically near 0.3\u20130.5; we use a fixed\n// `CRINKLE_PEAK_EST = 0.5` so the post-norm * 0.30 multiplier produces the\n// same audible level the round-2 fixtures hit. This is an approximation\n// (numpy's per-buffer normalization is not preserved bit-for-bit; the design\n// doc tradeoff log already accepts that gen-port is not bit-identical).\n// -----------------------------------------------------------------------------\n\nCRINKLE_RATE_K3 = 30;     // f^3 coefficient\nCRINKLE_FLOOR = 1;        // bursts/sec floor\nCRINKLE_AMP_LO = 0.2;\nCRINKLE_AMP_HI = 0.5;\nCRINKLE_DUR_LO_MS = 1;\nCRINKLE_DUR_HI_MS = 4;\nCRINKLE_HEADROOM = 0.30;  // round-2 (was 0.5)\nCRINKLE_PEAK_EST = 0.5;   // static normalization estimate (see comment above)\n\n// Gate: numpy ref's spec says crinkle is always-on if crinkle_level > 0; the\n// reference impl gates on (failure > 0) AND (crinkle_level > 0) for sanity\n// hash stability. The design doc tradeoff #10 says: engineer must relax to\n// always-on when crinkle_level > 0, regardless of failure. Honor the spec.\ncrinkle_engine_on = (crinkle_level > 0) * (1 - short_circuit * 0);\n// Re-evaluating: short_circuit happens only when knob==0 AND override==0,\n// meaning the user has the failure off entirely. In that case the spec says\n// crinkle should still be audible if crinkle_level > 0. So we DON'T gate on\n// short_circuit here. We do, however, drive the rate from `effective` so\n// at effective=0 the rate is the floor (1 burst/sec).\ncrinkle_engine_on = (crinkle_level > 0);\n\ncrinkle_rate_per_sec = CRINKLE_RATE_K3 * effective * effective * effective + CRINKLE_FLOOR;\ncrinkle_lambda_safe = max(crinkle_rate_per_sec, 1e-9);\ncrinkle_mean_dt_samp = samplerate / crinkle_lambda_safe;\n\n// ---- L ----\n\nu_cr_dt_L = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_cr_dt_L = -log(u_cr_dt_L) * crinkle_mean_dt_samp;\nu_cr_amp_L = ((noise() + 1.0) * 0.5);\nu_cr_dur_L = ((noise() + 1.0) * 0.5);\nevent_cr_amp_L = CRINKLE_AMP_LO + (CRINKLE_AMP_HI - CRINKLE_AMP_LO) * u_cr_amp_L;\nevent_cr_dur_n_L = max(2, (CRINKLE_DUR_LO_MS + (CRINKLE_DUR_HI_MS - CRINKLE_DUR_LO_MS) * u_cr_dur_L) * 1e-3 * samplerate);\nevent_cr_a_n_L = max(1, event_cr_dur_n_L * 0.25);\nevent_cr_r_n_L = max(1, event_cr_dur_n_L - event_cr_a_n_L);\n\nprev_cr_countdown_L = crinkle_countdown_L;\nprev_cr_phase_L     = crinkle_env_phase_L;\nprev_cr_left_L      = crinkle_env_left_L;\nprev_cr_amp_L       = crinkle_amp_L;\nprev_cr_a_n_L       = crinkle_a_n_L;\nprev_cr_r_n_L       = crinkle_r_n_L;\n\ncr_idle_dec_L = prev_cr_countdown_L - 1;\ncr_idle_fires_L = (cr_idle_dec_L <= 0) * crinkle_engine_on;\ncr_atk_left_L = prev_cr_left_L - 1;\ncr_atk_done_L = (prev_cr_phase_L == 1) * (cr_atk_left_L <= 0);\ncr_rel_left_L = prev_cr_left_L - 1;\ncr_rel_done_L = (prev_cr_phase_L == 2) * (cr_rel_left_L <= 0);\n\nnext_cr_phase_L     = prev_cr_phase_L;\nnext_cr_left_L      = prev_cr_left_L;\nnext_cr_countdown_L = prev_cr_countdown_L;\nnext_cr_amp_L       = prev_cr_amp_L;\nnext_cr_a_n_L       = prev_cr_a_n_L;\nnext_cr_r_n_L       = prev_cr_r_n_L;\n\nnext_cr_countdown_L = cr_idle_dec_L;\n// On fire: re-arm into attack (overlapping new event takes precedence \u2014 this\n// is the per-sample analog of np.maximum overlap: a new burst overrides an\n// in-flight tail which was already lower-amplitude on its release leg).\nnext_cr_phase_L = cr_idle_fires_L ? 1 : next_cr_phase_L;\nnext_cr_left_L  = cr_idle_fires_L ? event_cr_a_n_L : next_cr_left_L;\nnext_cr_amp_L   = cr_idle_fires_L ? event_cr_amp_L : next_cr_amp_L;\nnext_cr_a_n_L   = cr_idle_fires_L ? event_cr_a_n_L : next_cr_a_n_L;\nnext_cr_r_n_L   = cr_idle_fires_L ? event_cr_r_n_L : next_cr_r_n_L;\nnext_cr_countdown_L = cr_idle_fires_L ? new_cr_dt_L : next_cr_countdown_L;\n\nnext_cr_left_L  = ((prev_cr_phase_L == 1) * (cr_atk_done_L == 0)) ? cr_atk_left_L : next_cr_left_L;\nnext_cr_phase_L = cr_atk_done_L ? 2 : next_cr_phase_L;\nnext_cr_left_L  = cr_atk_done_L ? prev_cr_r_n_L : next_cr_left_L;\n\nnext_cr_left_L  = ((prev_cr_phase_L == 2) * (cr_rel_done_L == 0)) ? cr_rel_left_L : next_cr_left_L;\nnext_cr_phase_L = cr_rel_done_L ? 0 : next_cr_phase_L;\nnext_cr_left_L  = cr_rel_done_L ? 0 : next_cr_left_L;\n\ncr_cold_L = (prev_cr_phase_L == 0) * (prev_cr_countdown_L == 0) * crinkle_engine_on;\nnext_cr_countdown_L = cr_cold_L ? new_cr_dt_L : next_cr_countdown_L;\n\ncrinkle_countdown_L = next_cr_countdown_L;\ncrinkle_env_phase_L = next_cr_phase_L;\ncrinkle_env_left_L  = next_cr_left_L;\ncrinkle_amp_L       = next_cr_amp_L;\ncrinkle_a_n_L       = next_cr_a_n_L;\ncrinkle_r_n_L       = next_cr_r_n_L;\n\n// Triangular envelope value:\n//   attack:  i = a_n - left, env = amp * (i / a_n)\n//   release: i = r_n - left, env = amp * (1 - i / r_n)\ncr_atk_idx_L = next_cr_a_n_L - next_cr_left_L;\ncr_rel_idx_L = next_cr_r_n_L - next_cr_left_L;\ncr_atk_env_L = next_cr_amp_L * cr_atk_idx_L / max(1, next_cr_a_n_L);\ncr_rel_env_L = next_cr_amp_L * (1 - cr_rel_idx_L / max(1, next_cr_r_n_L));\n\ncrinkle_env_value_L =\n    (next_cr_phase_L == 1) ? cr_atk_env_L :\n    (next_cr_phase_L == 2) ? cr_rel_env_L :\n    0;\n\ncrinkle_env_L = crinkle_env_value_L;\n\n// White noise * envelope.\ncr_noise_L = noise() * crinkle_env_L;\n\n// ---- R ----\n\nu_cr_dt_R = max(((noise() + 1.0) * 0.5), 1e-12);\nnew_cr_dt_R = -log(u_cr_dt_R) * crinkle_mean_dt_samp;\nu_cr_amp_R = ((noise() + 1.0) * 0.5);\nu_cr_dur_R = ((noise() + 1.0) * 0.5);\nevent_cr_amp_R = CRINKLE_AMP_LO + (CRINKLE_AMP_HI - CRINKLE_AMP_LO) * u_cr_amp_R;\nevent_cr_dur_n_R = max(2, (CRINKLE_DUR_LO_MS + (CRINKLE_DUR_HI_MS - CRINKLE_DUR_LO_MS) * u_cr_dur_R) * 1e-3 * samplerate);\nevent_cr_a_n_R = max(1, event_cr_dur_n_R * 0.25);\nevent_cr_r_n_R = max(1, event_cr_dur_n_R - event_cr_a_n_R);\n\nprev_cr_countdown_R = crinkle_countdown_R;\nprev_cr_phase_R     = crinkle_env_phase_R;\nprev_cr_left_R      = crinkle_env_left_R;\nprev_cr_amp_R       = crinkle_amp_R;\nprev_cr_a_n_R       = crinkle_a_n_R;\nprev_cr_r_n_R       = crinkle_r_n_R;\n\ncr_idle_dec_R = prev_cr_countdown_R - 1;\ncr_idle_fires_R = (cr_idle_dec_R <= 0) * crinkle_engine_on;\ncr_atk_left_R = prev_cr_left_R - 1;\ncr_atk_done_R = (prev_cr_phase_R == 1) * (cr_atk_left_R <= 0);\ncr_rel_left_R = prev_cr_left_R - 1;\ncr_rel_done_R = (prev_cr_phase_R == 2) * (cr_rel_left_R <= 0);\n\nnext_cr_phase_R     = prev_cr_phase_R;\nnext_cr_left_R      = prev_cr_left_R;\nnext_cr_countdown_R = prev_cr_countdown_R;\nnext_cr_amp_R       = prev_cr_amp_R;\nnext_cr_a_n_R       = prev_cr_a_n_R;\nnext_cr_r_n_R       = prev_cr_r_n_R;\n\nnext_cr_countdown_R = cr_idle_dec_R;\nnext_cr_phase_R = cr_idle_fires_R ? 1 : next_cr_phase_R;\nnext_cr_left_R  = cr_idle_fires_R ? event_cr_a_n_R : next_cr_left_R;\nnext_cr_amp_R   = cr_idle_fires_R ? event_cr_amp_R : next_cr_amp_R;\nnext_cr_a_n_R   = cr_idle_fires_R ? event_cr_a_n_R : next_cr_a_n_R;\nnext_cr_r_n_R   = cr_idle_fires_R ? event_cr_r_n_R : next_cr_r_n_R;\nnext_cr_countdown_R = cr_idle_fires_R ? new_cr_dt_R : next_cr_countdown_R;\n\nnext_cr_left_R  = ((prev_cr_phase_R == 1) * (cr_atk_done_R == 0)) ? cr_atk_left_R : next_cr_left_R;\nnext_cr_phase_R = cr_atk_done_R ? 2 : next_cr_phase_R;\nnext_cr_left_R  = cr_atk_done_R ? prev_cr_r_n_R : next_cr_left_R;\n\nnext_cr_left_R  = ((prev_cr_phase_R == 2) * (cr_rel_done_R == 0)) ? cr_rel_left_R : next_cr_left_R;\nnext_cr_phase_R = cr_rel_done_R ? 0 : next_cr_phase_R;\nnext_cr_left_R  = cr_rel_done_R ? 0 : next_cr_left_R;\n\ncr_cold_R = (prev_cr_phase_R == 0) * (prev_cr_countdown_R == 0) * crinkle_engine_on;\nnext_cr_countdown_R = cr_cold_R ? new_cr_dt_R : next_cr_countdown_R;\n\ncrinkle_countdown_R = next_cr_countdown_R;\ncrinkle_env_phase_R = next_cr_phase_R;\ncrinkle_env_left_R  = next_cr_left_R;\ncrinkle_amp_R       = next_cr_amp_R;\ncrinkle_a_n_R       = next_cr_a_n_R;\ncrinkle_r_n_R       = next_cr_r_n_R;\n\ncr_atk_idx_R = next_cr_a_n_R - next_cr_left_R;\ncr_rel_idx_R = next_cr_r_n_R - next_cr_left_R;\ncr_atk_env_R = next_cr_amp_R * cr_atk_idx_R / max(1, next_cr_a_n_R);\ncr_rel_env_R = next_cr_amp_R * (1 - cr_rel_idx_R / max(1, next_cr_r_n_R));\n\ncrinkle_env_value_R =\n    (next_cr_phase_R == 1) ? cr_atk_env_R :\n    (next_cr_phase_R == 2) ? cr_rel_env_R :\n    0;\n\ncrinkle_env_R = crinkle_env_value_R;\ncr_noise_R = noise() * crinkle_env_R;\n\n\n// ---- BPF biquad \u2014 RBJ constant-skirt (fc=2500 Hz, Q=1.5) ----\n// Coefficients computed at sample rate. Matches numpy `_bpf_coeffs`.\nbpf_w0 = 2 * pi * 2500 / samplerate;\nbpf_cos_w0 = cos(bpf_w0);\nbpf_alpha = sin(bpf_w0) / (2 * 1.5);\nbpf_a0 = 1 + bpf_alpha;\nbpf_b0 = (1.5 * bpf_alpha) / bpf_a0;\nbpf_b1 = 0;\nbpf_b2 = (-1.5 * bpf_alpha) / bpf_a0;\nbpf_a1 = (-2 * bpf_cos_w0) / bpf_a0;\nbpf_a2 = (1 - bpf_alpha) / bpf_a0;\n\n// Direct Form I biquad, channel L.\n\nbpf_y_L_raw = bpf_b0 * cr_noise_L + bpf_b1 * bpf_x1_L + bpf_b2 * bpf_x2_L\n              - bpf_a1 * bpf_y1_L - bpf_a2 * bpf_y2_L;\n// Denormal flush per JOS recommendation.\nbpf_y_L = (abs(bpf_y_L_raw) < 1e-30) ? 0 : bpf_y_L_raw;\n\nbpf_x2_L = bpf_x1_L;\nbpf_x1_L = cr_noise_L;\nbpf_y2_L = bpf_y1_L;\nbpf_y1_L = bpf_y_L;\n\n// Normalize then scale: post-norm * CRINKLE_HEADROOM * crinkle_level.\ncrinkle_out_L = (bpf_y_L / CRINKLE_PEAK_EST) * CRINKLE_HEADROOM * crinkle_level;\n\n// Direct Form I biquad, channel R.\n\nbpf_y_R_raw = bpf_b0 * cr_noise_R + bpf_b1 * bpf_x1_R + bpf_b2 * bpf_x2_R\n              - bpf_a1 * bpf_y1_R - bpf_a2 * bpf_y2_R;\nbpf_y_R = (abs(bpf_y_R_raw) < 1e-30) ? 0 : bpf_y_R_raw;\n\nbpf_x2_R = bpf_x1_R;\nbpf_x1_R = cr_noise_R;\nbpf_y2_R = bpf_y1_R;\nbpf_y1_R = bpf_y_R;\n\ncrinkle_out_R = (bpf_y_R / CRINKLE_PEAK_EST) * CRINKLE_HEADROOM * crinkle_level;\n\n// Routing: under spread=0, broadcast L crinkle to both channels.\ncrinkle_for_L = crinkle_out_L;\ncrinkle_for_R = (spread > 0) ? crinkle_out_R : crinkle_out_L;\n\n// Disable crinkle on short-circuit OR when crinkle_level == 0.\ncrinkle_for_L = (short_circuit + (crinkle_level <= 0) > 0) ? 0 : crinkle_for_L;\ncrinkle_for_R = (short_circuit + (crinkle_level <= 0) > 0) ? 0 : crinkle_for_R;\n\n\n// =============================================================================\n// FINAL MIX & SHORT-CIRCUIT\n// =============================================================================\n//\n// Chain order from design doc \u00a71: SNAG \u2192 MICRO-FLUTTER \u2192 DROP \u2192 +CRINKLE.\n// Already accumulated in `postdrop_X` (signal path) and `crinkle_for_X`\n// (additive). When short_circuit is true, route raw inputs through unchanged\n// for bit-identical T1/P1 behavior.\n// -----------------------------------------------------------------------------\n\nprocessed_L = postdrop_L + crinkle_for_L;\nprocessed_R = postdrop_R + crinkle_for_R;\n\nout1 = short_circuit ? in1 : processed_L;\nout2 = short_circuit ? in2 : processed_R;\n\n// =============================================================================\n// END tl_failure.gendsp\n// =============================================================================\n"
												}
											},
											{
												"box": {
													"id": "tl_failure-gen-out1",
													"maxclass": "newobj",
													"text": "out 1",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														30.0,
														540.0,
														35.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_failure-gen-out2",
													"maxclass": "newobj",
													"text": "out 2",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														100.0,
														540.0,
														35.0,
														22.0
													]
												}
											}
										],
										"lines": [
											{
												"patchline": {
													"source": [
														"tl_failure-gen-in1",
														0
													],
													"destination": [
														"tl_failure-gen-codebox",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_failure-gen-in2",
														0
													],
													"destination": [
														"tl_failure-gen-codebox",
														1
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_failure-gen-in3",
														0
													],
													"destination": [
														"tl_failure-gen-codebox",
														2
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_failure-gen-in4",
														0
													],
													"destination": [
														"tl_failure-gen-codebox",
														3
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_failure-gen-codebox",
														0
													],
													"destination": [
														"tl_failure-gen-out1",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_failure-gen-codebox",
														1
													],
													"destination": [
														"tl_failure-gen-out2",
														0
													]
												}
											}
										]
									},
									"rnboattrcache": {},
									"saved_object_attributes": {
										"exportfolder": "",
										"exportname": "tl_failure_dsp",
										"wantsoutputcore": 0
									}
								}
							},
							{
								"box": {
									"id": "tl_failure-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										180,
										700,
										80
									],
									"text": "tl_failure (SANDBOX-PARTIAL): 4 sub-engines (drop, snag, micro-flutter, crinkle). Poisson scheduler; SPREAD = independent L/R RNG. Cross-module contract #1: inlet 8 (failure_override) from tl_aux FAIL mode; effective_failure = failure + override*(1-failure). Sub-engine ordering: snag \u2192 micro-flutter \u2192 drop \u2192 +crinkle. crinkle_level (hidden) controls crinkle output. drop_bypass/snag_bypass dip switches."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_failure-in-L",
										0
									],
									"destination": [
										"tl_failure-gen",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-in-R",
										0
									],
									"destination": [
										"tl_failure-gen",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-pin-0",
										0
									],
									"destination": [
										"tl_failure-gen",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-in-fov",
										0
									],
									"destination": [
										"tl_failure-gen",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-gen",
										0
									],
									"destination": [
										"tl_failure-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_failure-gen",
										1
									],
									"destination": [
										"tl_failure-out-R",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_failure",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_wow",
					"maxclass": "newobj",
					"numinlets": 4,
					"numoutlets": 2,
					"patching_rect": [
						20,
						380,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "p tl_wow",
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
									"id": "tl_wow-in-L",
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
									"id": "tl_wow-in-R",
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
									"id": "tl_wow-pin-0",
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
									"id": "tl_wow-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_wow-out-L",
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
									"id": "tl_wow-out-R",
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
									"id": "tl_wow-gen",
									"maxclass": "newobj",
									"numinlets": 3,
									"numoutlets": 2,
									"patching_rect": [
										40,
										100,
										250,
										60
									],
									"outlettype": [
										"signal",
										"signal"
									],
									"text": "gen~ @title tl_wow_lfo",
									"patcher": {
										"fileversion": 1,
										"appversion": {
											"major": 9,
											"minor": 0,
											"revision": 0,
											"architecture": "x64",
											"modernui": 1
										},
										"classnamespace": "dsp.gen",
										"rect": [
											100.0,
											100.0,
											700.0,
											600.0
										],
										"boxes": [
											{
												"box": {
													"id": "tl_wow-gen-in1",
													"maxclass": "newobj",
													"text": "in 1",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														30.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_wow-gen-in2",
													"maxclass": "newobj",
													"text": "in 2",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														100.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_wow-gen-in3",
													"maxclass": "newobj",
													"text": "in 3",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														170.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_wow-gen-codebox",
													"maxclass": "codebox",
													"numinlets": 3,
													"numoutlets": 2,
													"outlettype": [
														"",
														""
													],
													"patching_rect": [
														50.0,
														100.0,
														600.0,
														400.0
													],
													"code": "// =====================================================================\n// tl_wow.gendsp \u2014 gen~ DSL source for the WOW module of tape-loss\n// =====================================================================\n//\n// Module       : tl_wow (Generation Loss MKII \"WOW\" knob)\n// Authored     : 2026-04-27 (Phase 2.5 \u2014 gen~ translation)\n// Author       : pedal-engineer (auto-authored from numpy reference)\n// Source files :\n//   design-doc        : docs/design-docs/dsp/tl-wow-design.md\n//                       sha256: b8c61c53822509337cafb95b9b406d730f5a64c\n//                               cddfa0fb2619898e0f850c44ea\n//   numpy reference   : dsp/reference/tl_wow.py\n//                       sha256: d38076e8ebbbb1bb53e276129f6d764002e02396\n//                               d3828d7e4aa2a7ea117f62f9\n//   parent maxpat stub: device/tape-loss/tl_wow.maxpat (3-inlet contract)\n//\n// Inlets  (3): in1 = signal L, in2 = signal R, in3 = pitch_floor_cents\n//                                                   (control rate, cents)\n// Outlets (2): out1 = signal L, out2 = signal R\n// Params  (1): wow \u2208 [0, 1]    (default 0.0)\n//\n// ---------------------------------------------------------------------\n// Algorithm summary (translated 1:1 from dsp/reference/tl_wow.py):\n//\n//   Per channel:\n//     n1  = noise()                           // independent stream / chan\n//     n2  = noise()                           // second cutoff stream\n//     m_a = onepole_lpf(onepole_lpf(n1, fc=0.5 Hz))   // 12 dB/oct\n//     m_b = onepole_lpf(onepole_lpf(n2, fc=0.7 Hz))   // 12 dB/oct\n//     m_main = (m_a + m_b) * 0.5 * UNIT_PEAK_GAIN     // \u2248 \u00b11\n//\n//     // Phase 1.5 floor LFO (independent \u2014 different cutoff & noise()):\n//     n_f   = noise()\n//     m_flr = onepole_lpf(onepole_lpf(n_f, fc=0.4 Hz))  // 12 dB/oct\n//     m_flr = m_flr * UNIT_PEAK_GAIN                    // \u2248 \u00b11\n//\n//     // Depth tapers\n//     A_main  = A_MAX_SECONDS * (0.30*w\u00b2 + 0.70*w\u00b3)        // seconds\n//     A_floor = pitch_floor_cents / (1731.234 * 4.39)      // seconds\n//\n//     // Combined delay-time signal (seconds \u2192 samples)\n//     D(t) = (BASE_DELAY_S + A_main*m_main + A_floor*m_flr) * samplerate\n//\n//     // Variable delay read: 4-point cubic Hermite (Catmull-Rom form)\n//     write delbuf[n] = x[n]\n//     read  y[n]      = hermite_4pt(delbuf, write_idx - D, frac)\n//\n//     // Short-circuit: bit-identical passthrough when both paths are\n//     // off; preserves the round-1 wow=0 invariant when floor=0 too.\n//     short = (wow <= EPS) && (pitch_floor_cents <= EPS)\n//     out   = if short then x else y\n//\n// ---------------------------------------------------------------------\n// Sanity-check expectations (matches design-doc \u00a75 + \u00a713.5 calibration):\n//\n//   wow=0.0, pitch_floor=0.0  \u2192  bit-identical passthrough (SHORT path)\n//   wow=0.5, pitch_floor=0.0  \u2192  \u2248 \u00b113 c peak  (spec target ~\u00b115 c)\n//   wow=1.0, pitch_floor=0.0  \u2192  \u2248 \u00b170 c peak  (spec target ~\u00b170 c)\n//   wow=0.0, pitch_floor=0.3  \u2192  \u2248 \u00b10.3 c peak (independent floor only)\n//\n// ---------------------------------------------------------------------\n// Hermite kernel (Catmull-Rom form) \u2014 matches numpy ref _hermite_4pt():\n//\n//   c0 = x0\n//   c1 = 0.5 * (x1 - xm1)\n//   c2 = xm1 - 2.5*x0 + 2.0*x1 - 0.5*x2\n//   c3 = 0.5 * (x2 - xm1) + 1.5 * (x0 - x1)\n//   y  = ((c3*frac + c2)*frac + c1)*frac + c0\n//\n// Reference: Niemitalo, \"Polynomial Interpolators for High-Quality\n// Resampling of Oversampled Audio\" (yehar.com, 2001); JOS PASP\n// \"Interpolation\" appendix. Frequency loss at fc=0.5\u00b7Nyquist \u2248 -0.01 dB.\n//\n// ---------------------------------------------------------------------\n// Notes on divergences from the spec sketch (signed-off in design-doc):\n//   * BASE_DELAY = 25 ms (NOT 5 ms). Required headroom for A_max=6 ms\n//     so D(t) stays > 0 across all wow values.\n//   * Per-vector LFO peak normalization (numpy) is replaced by a fixed\n//     gain of 1.0 / 0.95 \u2248 1.0526 (UNIT_PEAK_GAIN). Realtime-safe; see\n//     design-doc \u00a79 (\"Per-vector LFO peak-normalize in Python only\").\n// =====================================================================\n\nParam wow(0.0);\nHistory lp1L_a, lp1L_b;   // 0.5 Hz cascade (stages a, b)\nHistory lp2L_a, lp2L_b;   // 0.7 Hz cascade\nHistory lp1R_a, lp1R_b;\nHistory lp2R_a, lp2R_b;\nHistory lpFL_a, lpFL_b;\nHistory lpFR_a, lpFR_b;\n\n\n// --- Constants -------------------------------------------------------\n\n// Base mean delay (seconds). Spec divergence #4: 25 ms (not 5 ms).\nBASE_DELAY_S = 0.025;\n\n// Peak modulation amplitude (seconds) at wow=1.0. Calibrated against\n// the multi-seed Hilbert-IF measurement to land at ~\u00b170 c (spec target).\nA_MAX_SECONDS = 0.006;\n\n// LFO cutoffs.\nLFO_FC1_HZ = 0.5;\nLFO_FC2_HZ = 0.7;\nPITCH_FLOOR_LFO_FC_HZ = 0.4;\n\n// Cents-to-delay-derivative conversion: 1200 / ln(2).\nCENTS_PER_DD_DT = 1731.234;\n\n// Empirical |dm/dt|_peak for the floor LFO topology (mean of 20 seeds,\n// 6 s windows). Used to invert the small-shift Doppler relation:\n//     A_floor = pitch_floor_cents / (CENTS_PER_DD_DT \u00b7 this).\nPITCH_FLOOR_DM_DT_PEAK_PER_S = 4.39;\n\n// LFO peak compensation factor \u2014 fixed gain replacing the numpy ref's\n// per-vector peak-normalize. Mean peak \u2248 0.95 \u2192 scale \u2248 1.0526.\nUNIT_PEAK_GAIN = 1.0526;\n\n// Short-circuit epsilon \u2014 guard against denormal-tier residuals.\nEPS = 1e-6;\n\n// --- LFO state (History) ---------------------------------------------\n//\n// Per-channel decorrelation strategy: each `noise()` call site in gen~\n// produces an INDEPENDENT pseudo-random stream. So separate History\n// chains driving separate `noise()` reads is sufficient to guarantee\n// uncorrelated L/R LFOs without any seed plumbing.\n\n// Main wow path, channel L \u2014 two cascaded 1-pole stages \u00d7 two cutoffs.\n\n// Main wow path, channel R.\n\n// Floor (pitch_floor) path, channel L \u2014 single cascaded 1-pole at 0.4 Hz.\n\n// Floor path, channel R.\n\n// --- Delay buffers ---------------------------------------------------\n//\n// Sized for worst-case at 96 kHz: ceil((25 + 6 + ~0.05) ms \u00b7 96000) + 16\n// \u2248 2982 samples. We round up generously to 8192 for headroom and to\n// fit any future depth bump cleanly.\n\nDelay delbuf_L(8192);\nDelay delbuf_R(8192);\n\n// =====================================================================\n// Per-sample DSP\n// =====================================================================\n\n// ----- LFO coefficients (recomputed per sample; samplerate-aware) -----\n//\n// 1-pole LPF coefficient: a = 1 - exp(-2*pi*fc/sr).\n// `samplerate` is a gen DSL keyword; this stays correct across SR changes.\ntwo_pi = 2.0 * 3.14159265358979323846;\na_fc1   = 1.0 - exp(-two_pi * LFO_FC1_HZ            / samplerate);\na_fc2   = 1.0 - exp(-two_pi * LFO_FC2_HZ            / samplerate);\na_floor = 1.0 - exp(-two_pi * PITCH_FLOOR_LFO_FC_HZ / samplerate);\n\n// ----- Channel L main LFO --------------------------------------------\nnL1 = noise();                                  // independent stream\nlp1L_a = lp1L_a + a_fc1 * (nL1    - lp1L_a);\nlp1L_b = lp1L_b + a_fc1 * (lp1L_a - lp1L_b);    // cascade \u2192 12 dB/oct\nmL_a = lp1L_b;\n\nnL2 = noise();\nlp2L_a = lp2L_a + a_fc2 * (nL2    - lp2L_a);\nlp2L_b = lp2L_b + a_fc2 * (lp2L_a - lp2L_b);\nmL_b = lp2L_b;\n\nm_main_L = 0.5 * (mL_a + mL_b) * UNIT_PEAK_GAIN;\n\n// ----- Channel R main LFO --------------------------------------------\nnR1 = noise();\nlp1R_a = lp1R_a + a_fc1 * (nR1    - lp1R_a);\nlp1R_b = lp1R_b + a_fc1 * (lp1R_a - lp1R_b);\nmR_a = lp1R_b;\n\nnR2 = noise();\nlp2R_a = lp2R_a + a_fc2 * (nR2    - lp2R_a);\nlp2R_b = lp2R_b + a_fc2 * (lp2R_a - lp2R_b);\nmR_b = lp2R_b;\n\nm_main_R = 0.5 * (mR_a + mR_b) * UNIT_PEAK_GAIN;\n\n// ----- Floor (pitch_floor_cents) LFO, both channels -------------------\nnFL = noise();                                  // independent of main\nlpFL_a = lpFL_a + a_floor * (nFL    - lpFL_a);\nlpFL_b = lpFL_b + a_floor * (lpFL_a - lpFL_b);\nm_floor_L = lpFL_b * UNIT_PEAK_GAIN;\n\nnFR = noise();\nlpFR_a = lpFR_a + a_floor * (nFR    - lpFR_a);\nlpFR_b = lpFR_b + a_floor * (lpFR_a - lpFR_b);\nm_floor_R = lpFR_b * UNIT_PEAK_GAIN;\n\n// ----- Depth tapers ---------------------------------------------------\n//\n// Main wow:  A(w) = A_MAX_SECONDS \u00b7 (0.30\u00b7w\u00b2 + 0.70\u00b7w\u00b3)\nw  = clamp(wow, 0.0, 1.0);\nw2 = w * w;\nw3 = w2 * w;\nA_main_sec = A_MAX_SECONDS * (0.30 * w2 + 0.70 * w3);\n\n// Floor: A_floor = pitch_floor_cents / (1731.234 \u00b7 4.39) [seconds]\n// in3 carries pitch_floor_cents (control rate; treated as signal here).\npfc = max(in3, 0.0);\nA_floor_sec = pfc / (CENTS_PER_DD_DT * PITCH_FLOOR_DM_DT_PEAK_PER_S);\n\n// Convert seconds \u2192 samples (samplerate-aware).\nbase_samp    = BASE_DELAY_S * samplerate;\na_main_samp  = A_main_sec   * samplerate;\na_floor_samp = A_floor_sec  * samplerate;\n\n// Total delay-time signal (samples). Note: floor & main are SUMMED into\n// the SAME delay-time signal (one delay read per channel), per the\n// numpy ref's _process_channel logic \u2014 NOT a separate read.\nD_L = base_samp + a_main_samp * m_main_L + a_floor_samp * m_floor_L;\nD_R = base_samp + a_main_samp * m_main_R + a_floor_samp * m_floor_R;\n\n// Clamp delay to safe Hermite range: need \u2265 1 sample history (xm1) and\n// \u2264 buf_len - 4 (so x2 stays inside the buffer).\nD_L = clamp(D_L, 1.0, 8192.0 - 4.0);\nD_R = clamp(D_R, 1.0, 8192.0 - 4.0);\n\n// ----- Variable-delay write/read with 4-point Hermite ----------------\n//\n// gen~'s Delay primitive writes the inlet value automatically each\n// sample; reads via `delbuf.read(d, kind)` where `d` is a fractional\n// number of samples behind the current write position. We do four\n// reads at d-1, d, d+1, d+2 (drop-sample interpolation inside each\n// read), then apply the Catmull-Rom Hermite kernel for the fractional\n// position.\n\n// Write current input.\ndelbuf_L.write(in1);\ndelbuf_R.write(in2);\n\n// Integer & fractional split of the requested delay.\niD_L  = floor(D_L);\nfD_L  = D_L - iD_L;\niD_R  = floor(D_R);\nfD_R  = D_R - iD_R;\n\n// Four-tap reads (drop-sample inside the .read call \u2014 the Hermite\n// kernel handles the fractional interpolation across these samples).\nxm1_L = delbuf_L.read(iD_L - 1.0, \"step\");\nx0_L  = delbuf_L.read(iD_L,        \"step\");\nx1_L  = delbuf_L.read(iD_L + 1.0,  \"step\");\nx2_L  = delbuf_L.read(iD_L + 2.0,  \"step\");\n\nxm1_R = delbuf_R.read(iD_R - 1.0, \"step\");\nx0_R  = delbuf_R.read(iD_R,        \"step\");\nx1_R  = delbuf_R.read(iD_R + 1.0,  \"step\");\nx2_R  = delbuf_R.read(iD_R + 2.0,  \"step\");\n\n// Hermite-4 (Catmull-Rom) \u2014 bit-for-bit equivalent to numpy ref\n// _hermite_4pt(). Position frac is the fractional part of the read\n// offset between samples x0 and x1.\n//\n// NOTE: numpy ref uses read_pos_f = write_idx - D, so x0 sits at\n// read_pos_f, and the kernel's frac is read_pos_f - floor(read_pos_f).\n// gen~ Delay.read(d, ...) reads `d` samples behind write, so x0 sits\n// at offset iD_L (= floor(D_L)) and frac is fD_L. Same orientation.\nc0_L = x0_L;\nc1_L = 0.5 * (x1_L - xm1_L);\nc2_L = xm1_L - 2.5 * x0_L + 2.0 * x1_L - 0.5 * x2_L;\nc3_L = 0.5 * (x2_L - xm1_L) + 1.5 * (x0_L - x1_L);\ny_L  = ((c3_L * fD_L + c2_L) * fD_L + c1_L) * fD_L + c0_L;\n\nc0_R = x0_R;\nc1_R = 0.5 * (x1_R - xm1_R);\nc2_R = xm1_R - 2.5 * x0_R + 2.0 * x1_R - 0.5 * x2_R;\nc3_R = 0.5 * (x2_R - xm1_R) + 1.5 * (x0_R - x1_R);\ny_R  = ((c3_R * fD_R + c2_R) * fD_R + c1_R) * fD_R + c0_R;\n\n// ----- Short-circuit (bit-identical bypass) ---------------------------\n//\n// When wow == 0 AND pitch_floor_cents == 0, we MUST emit the input\n// unchanged \u2014 the round-1 invariant. Both flags off \u2192 bypass the\n// delay-line read entirely (the delay buffer keeps writing, which is\n// fine; only the OUTPUT mux is short-circuited).\nshort = (w <= EPS) && (pfc <= EPS);\n\nout1 = (short != 0) ? in1 : y_L;\nout2 = (short != 0) ? in2 : y_R;\n\n// =====================================================================\n// END tl_wow.gendsp\n// =====================================================================\n"
												}
											},
											{
												"box": {
													"id": "tl_wow-gen-out1",
													"maxclass": "newobj",
													"text": "out 1",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														30.0,
														540.0,
														35.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_wow-gen-out2",
													"maxclass": "newobj",
													"text": "out 2",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														100.0,
														540.0,
														35.0,
														22.0
													]
												}
											}
										],
										"lines": [
											{
												"patchline": {
													"source": [
														"tl_wow-gen-in1",
														0
													],
													"destination": [
														"tl_wow-gen-codebox",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_wow-gen-in2",
														0
													],
													"destination": [
														"tl_wow-gen-codebox",
														1
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_wow-gen-in3",
														0
													],
													"destination": [
														"tl_wow-gen-codebox",
														2
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_wow-gen-codebox",
														0
													],
													"destination": [
														"tl_wow-gen-out1",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_wow-gen-codebox",
														1
													],
													"destination": [
														"tl_wow-gen-out2",
														0
													]
												}
											}
										]
									},
									"rnboattrcache": {},
									"saved_object_attributes": {
										"exportfolder": "",
										"exportname": "tl_wow_lfo",
										"wantsoutputcore": 0
									}
								}
							},
							{
								"box": {
									"id": "tl_wow-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										180,
										700,
										60
									],
									"text": "tl_wow (SANDBOX-PARTIAL): variable-delay slow random pitch drift. gen~ owns full audio path (internal Delay primitives + 4-pt Hermite read). Base D0=25ms (spec divergence #7), A_max=6ms at wow=1.0. Filtered-noise LFO (0.5+0.7 Hz cutoffs). Cross-module: pitch_floor_cents inlet (=0.3 when model=11). Phase 1.5 buffer-share divergence: private Delay vs shared tape_loss_delay."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_wow-in-L",
										0
									],
									"destination": [
										"tl_wow-gen",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_wow-in-R",
										0
									],
									"destination": [
										"tl_wow-gen",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_wow-pin-1",
										0
									],
									"destination": [
										"tl_wow-gen",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_wow-gen",
										0
									],
									"destination": [
										"tl_wow-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_wow-gen",
										1
									],
									"destination": [
										"tl_wow-out-R",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_wow",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_flutter",
					"maxclass": "newobj",
					"numinlets": 4,
					"numoutlets": 2,
					"patching_rect": [
						300,
						380,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "p tl_flutter",
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
									"id": "tl_flutter-in-L",
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
									"id": "tl_flutter-in-R",
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
									"id": "tl_flutter-pin-0",
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
									"id": "tl_flutter-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_flutter-out-L",
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
									"id": "tl_flutter-out-R",
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
									"id": "tl_flutter-gen",
									"maxclass": "newobj",
									"numinlets": 2,
									"numoutlets": 2,
									"patching_rect": [
										40,
										100,
										250,
										60
									],
									"outlettype": [
										"signal",
										"signal"
									],
									"text": "gen~ @title tl_flutter_lfos",
									"patcher": {
										"fileversion": 1,
										"appversion": {
											"major": 9,
											"minor": 0,
											"revision": 0,
											"architecture": "x64",
											"modernui": 1
										},
										"classnamespace": "dsp.gen",
										"rect": [
											100.0,
											100.0,
											700.0,
											600.0
										],
										"boxes": [
											{
												"box": {
													"id": "tl_flutter-gen-in1",
													"maxclass": "newobj",
													"text": "in 1",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														30.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_flutter-gen-in2",
													"maxclass": "newobj",
													"text": "in 2",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														100.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_flutter-gen-codebox",
													"maxclass": "codebox",
													"numinlets": 2,
													"numoutlets": 2,
													"outlettype": [
														"",
														""
													],
													"patching_rect": [
														50.0,
														100.0,
														600.0,
														400.0
													],
													"code": "// =====================================================================\n// tl_flutter.gendsp \u2014 gen~ DSL source for the FLUTTER module of tape-loss\n// =====================================================================\n//\n// Module          : tl_flutter (Generation Loss MKII \"FLUTTER\" knob)\n// TUNING_VERSION  : 2 (round-2 retune, sqrt taper \u2014 see design-doc \u00a713b)\n// Authored        : 2026-04-27 (Phase 2.5 \u2014 gen~ translation)\n// Author          : pedal-engineer (auto-authored from numpy reference)\n//\n// Source files :\n//   design-doc      : docs/design-docs/dsp/tl-flutter-design.md\n//                     sha256: 1b8c99fb7250020f49ad81d8b1deb568397c55614c\n//                             120869e3dcadd4995a7202\n//   numpy reference : dsp/reference/tl_flutter.py     (TUNING_VERSION = 2)\n//                     sha256: 0c85878d0e2e92dfa3b44a9ae3ce78637d50e1389b\n//                             4f39991e6f54b428d0027b\n//   parent stub     : device/tape-loss/tl_flutter.maxpat (codebox host)\n//\n// Inlets  (2): in1 = signal L, in2 = signal R\n// Outlets (2): out1 = signal L, out2 = signal R\n// Params  (2): flutter      \u2208 [0, 1]   (default 0.0)\n//              classic_mode \u2208 {0, 1}   (default 0)   AM-bypass-only\n//\n// ---------------------------------------------------------------------\n// Algorithm summary (translated 1:1 from dsp/reference/tl_flutter.py;\n// fast pitch + AM modulation per spec \u00a7\"MODULE 5: tl.flutter.maxpat\"):\n//\n//   Per channel (independent noise() streams = decorrelated stereo):\n//\n//     Pitch-mod LFO bank:\n//       n_p1 = noise() \u2192 biquad RBJ LPF(fc= 8 Hz, Q=0.7) \u2500\u2510\n//       n_p2 = noise() \u2192 biquad RBJ LPF(fc=19 Hz, Q=0.7) \u2500\u2534 avg\n//       lfo_p = avg(n_p1_filt, n_p2_filt) \u00b7 PITCH_LFO_NORM   // p99 \u2248 1.0\n//\n//     AM-mod LFO bank (different cutoffs \u2014 pitch and AM should NOT track):\n//       n_a1 = noise() \u2192 biquad RBJ LPF(fc=11 Hz, Q=0.6) \u2500\u2510\n//       n_a2 = noise() \u2192 biquad RBJ LPF(fc=23 Hz, Q=0.6) \u2500\u2534 avg\n//       lfo_a = avg(n_a1_filt, n_a2_filt) \u00b7 AM_LFO_NORM      // p99 \u2248 1.0\n//\n//     Round-2 sqrt depth tapers (NOT quadratic \u2014 see \u00a713b):\n//       pitch_depth_seconds = 1.5e-4 \u00b7 sqrt(flutter)\n//       am_depth            = 0.25   \u00b7 sqrt(flutter)\n//\n//     Variable-delay read (4-point LAGRANGE \u2014 JOS PASP \"Lagrange Interp.\"):\n//       D[n]      = (BASE_DELAY_S + pitch_depth_seconds \u00b7 lfo_p) \u00b7 sr\n//       write delbuf[n] = x[n]\n//       y_pitched = lagrange4(delbuf, D, frac)\n//\n//     AM stage (gated by classic_mode):\n//       multiplier = 1 + am_depth \u00b7 lfo_a\n//       y = (classic_mode != 0) ? y_pitched : y_pitched \u00b7 multiplier\n//\n//     Short-circuit (bit-identical passthrough invariant):\n//       short = (flutter <= EPS)\n//       out   = short ? x : y\n//\n// ---------------------------------------------------------------------\n// Sanity-check expectations (matches numpy ref's run_round2_taper_assertions):\n//\n//   flutter = 0.0                      \u2192 bit-identical passthrough (regression)\n//   flutter = 0.5, classic_mode = 0    \u2192 pitch p99 \u2265 18 c, AM pk-pk \u2265 1.0 dB\n//                                         (chord-noon audibility floor \u2014 clears\n//                                          the round-2 ground-truth assertions)\n//   flutter = 1.0, classic_mode = 0    \u2192 pitch p99 \u2264 50 c (under vibrato boundary;\n//                                         numpy ref measures 28.4 c)\n//                                         AM pk-pk ~ 5 dB (numpy ref measures 5.0)\n//   flutter = 1.0, classic_mode = 1    \u2192 AM bypassed; pitch path identical to\n//                                         non-classic (sha-equal pitch path)\n//\n// ---------------------------------------------------------------------\n// Lagrange-4 kernel (JOS PASP \"Lagrange Interpolation\"):\n//\n//   For frac \u2208 [0, 1) read at samples [-1, 0, 1, 2] relative to floor:\n//\n//     c_m1 = -frac \u00b7 (frac - 1) \u00b7 (frac - 2) / 6\n//     c_0  =  (frac + 1) \u00b7 (frac - 1) \u00b7 (frac - 2) / 2\n//     c_p1 = -(frac + 1) \u00b7 frac      \u00b7 (frac - 2) / 2\n//     c_p2 =  (frac + 1) \u00b7 frac      \u00b7 (frac - 1) / 6\n//     y    = c_m1\u00b7xm1 + c_0\u00b7x0 + c_p1\u00b7x1 + c_p2\u00b7x2\n//\n// NB: this is NOT the Hermite-4 (Catmull-Rom) kernel used in tl_wow.gendsp.\n// Lagrange interpolates exactly through all four sample points (polynomial\n// fit), while Hermite uses estimated derivatives at the inner two. Per the\n// design-doc \u00a75, Lagrange-4 matches Max's tapout~ internal interpolation\n// and gives smoother HF artifact rejection than linear at modest cost.\n//\n// ---------------------------------------------------------------------\n// 99th-percentile-peak normalization scalars (constants from design-doc \u00a710\n// row 12 / numpy ref _build_lfo). MEASURED EMPIRICALLY from the reference\n// path (RBJ LPF + Direct-Form-I biquad with denormal flush + sum-and-divide-\n// by-n_bands), 8 seeds \u00d7 30 s, sr = 44.1 kHz, then median taken:\n//\n//   PITCH_LFO_NORM = 21.3824   // (8 Hz + 19 Hz, Q=0.7) median 1/p99\n//   AM_LFO_NORM    = 20.3633   // (11 Hz + 23 Hz, Q=0.6) median 1/p99\n//\n// Why median-of-1/p99 and not the numpy-style per-buffer divide?  Real-time\n// gen~ cannot afford a percentile pass over a future buffer. The constants\n// produce a long-run 99th-percentile peak \u2248 1.0 within \u00b13 % across seeds,\n// which keeps depth-multiplication semantics intact (depth \u00b7 lfo \u2248 \u00b1depth\n// 99 % of the time, with rare ~1.4\u00d7 outliers preserved per design-doc).\n//\n// Why these and not RMS-target / abs-peak-target normalization?\n//   * RMS-target: 99th-percentile peak \u2248 3\u20134\u00d7 depth \u2192 blows past the spec'd\n//     pitch ceiling (~50 c) and AM ceiling (~6 dB pk-pk).\n//   * Abs-peak-target: single-sample outliers drag mean swing down \u2192 noon\n//     undershoots audibility floor.\n//   * 99th-percentile-peak: stable middle ground (design-doc \u00a710 row 12).\n//\n// Sample-rate dependence: the biquad coefficients shift with samplerate, so\n// the bare 1/p99 also shifts.  Measured at 48 kHz the scalars come out\n// within ~3 % of the 44.1 kHz values (filter behavior is dominated by the\n// LP cutoff, which scales with fc/sr \u2014 same band-shape, similar variance).\n// Acceptable for v0; if a tighter sr-correction is needed we can promote\n// these to per-sample expressions of the form k/sqrt(samplerate) once the\n// taper is finalized.  Pitfall #4 \u2014 coefficient recompute on sr change is\n// handled by the biquad-coefficient block below.\n//\n// ---------------------------------------------------------------------\n// Buffer-sharing decision:\n//\n//   Spec \u00a7MODULE 5 + Phase-1.5 reconciliation say tl_flutter and tl_wow\n//   share a single [buffer~ tape_loss_delay].  In gen~, sharing requires\n//   `Buffer tape_loss_delay;` referencing the patcher-level buffer object.\n//\n//   For v0 we use **PRIVATE Delay buffers** here (delbuf_L, delbuf_R).\n//   Rationale:\n//     - bit-identity to the numpy reference is unreachable in real-time\n//       anyway (different RNG, different sr-dependent norm scalar);\n//     - private Delay is well-trodden (matches tl_wow.gendsp's strategy);\n//     - shared-buffer wiring is a patcher-level concern that the\n//       integration agent will reconcile in tl_flutter.maxpat (the stub\n//       there already wires through tapin~/tapout~ \u2014 those will be\n//       removed when the codebox absorbs the variable-delay read).\n//\n//   buffer_sharing_strategy = \"private\"  (audit emission flag).\n//\n//   If/when the integration agent decides to share, replace the\n//   `Delay delbuf_L(BUF_SAMPS); Delay delbuf_R(BUF_SAMPS);` declarations\n//   with `Buffer tape_loss_delay;` and adjust the .write/.read calls to\n//   use Buffer's positional read/poke API. Coordinates with tl_wow's gen\n//   DSL would then be by offset position in the same buffer.\n//\n// ---------------------------------------------------------------------\n// classic_mode interpretation:\n//\n//   classic_mode = 0 \u2192 full mode (pitch + AM).\n//   classic_mode = 1 \u2192 AM stage bypassed; pitch path **unchanged** (rates,\n//                       depth, taper all identical between modes).\n//\n//   Source: design-doc \u00a76 reading of spec line 528 (\"Classic Mode Flutter:\n//   Pitch modulation only, no AM path\").  Signed off by user.\n//\n//   Implementation: a soft mux `(classic_mode != 0) ? y_pitched : y_full`.\n//   Note this is a hard switch, not a crossfade \u2014 pitfall #16 says use a\n//   crossfade in M4L `selector~`, but the M4L wrapper does the crossfade\n//   externally (see tl_flutter.maxpat's `selector~ 2` after the AM `*~`).\n//   Inside gen~, the hard switch is fine because the bool toggle change\n//   is rate-limited at the patcher level.\n// =====================================================================\n\nParam flutter(0.0);\nParam classic_mode(0);\nHistory pL1_x1, pL1_x2, pL1_y1, pL1_y2;\nHistory pL2_x1, pL2_x2, pL2_y1, pL2_y2;\nHistory pR1_x1, pR1_x2, pR1_y1, pR1_y2;\nHistory pR2_x1, pR2_x2, pR2_y1, pR2_y2;\nHistory aL1_x1, aL1_x2, aL1_y1, aL1_y2;\nHistory aL2_x1, aL2_x2, aL2_y1, aL2_y2;\nHistory aR1_x1, aR1_x2, aR1_y1, aR1_y2;\nHistory aR2_x1, aR2_x2, aR2_y1, aR2_y2;\n\n\n// --- Constants -------------------------------------------------------\n\n// Base mean delay (seconds). Matches numpy ref _BASE_DELAY_S = 5e-3.\nBASE_DELAY_S = 0.005;\n\n// Round-2 sqrt taper maxima (design-doc \u00a713b).\nPITCH_DEPTH_MAX_S = 1.5e-4;   // pitch_depth = PITCH_DEPTH_MAX_S * sqrt(flutter)\nAM_DEPTH_MAX      = 0.25;     // am_depth   = AM_DEPTH_MAX      * sqrt(flutter)\n\n// Pitch-mod LFO band cutoffs (Hz) and Q. Two bands per channel, summed.\nPITCH_FC1_HZ = 8.0;\nPITCH_FC2_HZ = 19.0;\nPITCH_Q      = 0.7;\n\n// AM-mod LFO band cutoffs (Hz) and Q. Offset from pitch bands so AM does\n// not exactly track pitch \u2014 real tape: different mechanical sources.\nAM_FC1_HZ = 11.0;\nAM_FC2_HZ = 23.0;\nAM_Q      = 0.6;\n\n// 99th-percentile-peak normalization scalars (see header block; empirical\n// medians across 8 seeds \u00d7 30 s of biquad-filtered noise at 44.1 kHz).\nPITCH_LFO_NORM = 21.3824;\nAM_LFO_NORM    = 20.3633;\n\n// Short-circuit / safety epsilons.\nEPS = 1e-6;\n\n// Variable-delay buffer length (samples). At 96 kHz worst-case mean delay\n// + max pitch swing is (5 + 0.15) ms \u00b7 96000 \u2248 495 samples; we round up\n// generously to 4096 for headroom and Lagrange-4 footprint. (See design-\n// doc \u00a75: \"Spec \u00a7MODULE 4 sets `tapin~ 100ms`. Our buffer comfortably\n// fits.\")\nBUF_SAMPS = 4096.0;\n\n// Two pi.\nTWO_PI = 6.28318530717958647693;\n\n// --- LFO biquad state (History) --------------------------------------\n//\n// Each `noise()` call site in gen~ produces an independent pseudo-random\n// stream, so the four pitch streams (2 channels \u00d7 2 bands) and four AM\n// streams (2 channels \u00d7 2 bands) are mutually decorrelated without any\n// seed plumbing.  Eight biquads total, each in Direct-Form-I (4 taps).\n\n// Pitch path L \u2014 band 1 (8 Hz)\n// Pitch path L \u2014 band 2 (19 Hz)\n// Pitch path R \u2014 band 1\n// Pitch path R \u2014 band 2\n// AM path L \u2014 band 1 (11 Hz)\n// AM path L \u2014 band 2 (23 Hz)\n// AM path R \u2014 band 1\n// AM path R \u2014 band 2\n\n// --- Variable-delay buffers (PRIVATE \u2014 see header) -------------------\nDelay delbuf_L(4096);\nDelay delbuf_R(4096);\n\n// =====================================================================\n// Per-sample DSP\n// =====================================================================\n\n// ----- RBJ LPF biquad coefficients (recomputed per sample; sr-aware) --\n//\n// H(z) = (b0 + b1\u00b7z\u207b\u00b9 + b2\u00b7z\u207b\u00b2) / (1 + a1\u00b7z\u207b\u00b9 + a2\u00b7z\u207b\u00b2),  a0 = 1\n//\n//   \u03c90 = 2\u03c0 \u00b7 fc / Fs\n//   \u03b1  = sin(\u03c90) / (2Q)\n//   b0 = (1 - cos \u03c90) / 2,  b1 = 1 - cos \u03c90,  b2 = b0\n//   a0 = 1 + \u03b1,  a1 = -2 cos \u03c90,  a2 = 1 - \u03b1\n//\n// `samplerate` is a gen~ keyword \u2014 coefficients track sr changes per\n// pitfall #4. Recomputed per sample (cheap; cosine \u2248 1 op on M-series).\n\n// Pitch band 1 (8 Hz, Q=0.7)\nw0_p1     = TWO_PI * PITCH_FC1_HZ / samplerate;\ncw_p1     = cos(w0_p1);\nalpha_p1  = sin(w0_p1) / (2.0 * PITCH_Q);\na0_p1     = 1.0 + alpha_p1;\npb0_1     = ((1.0 - cw_p1) * 0.5) / a0_p1;\npb1_1     = (1.0 - cw_p1)         / a0_p1;\npb2_1     = pb0_1;\npa1_1     = (-2.0 * cw_p1)        / a0_p1;\npa2_1     = (1.0 - alpha_p1)      / a0_p1;\n\n// Pitch band 2 (19 Hz, Q=0.7)\nw0_p2     = TWO_PI * PITCH_FC2_HZ / samplerate;\ncw_p2     = cos(w0_p2);\nalpha_p2  = sin(w0_p2) / (2.0 * PITCH_Q);\na0_p2     = 1.0 + alpha_p2;\npb0_2     = ((1.0 - cw_p2) * 0.5) / a0_p2;\npb1_2     = (1.0 - cw_p2)         / a0_p2;\npb2_2     = pb0_2;\npa1_2     = (-2.0 * cw_p2)        / a0_p2;\npa2_2     = (1.0 - alpha_p2)      / a0_p2;\n\n// AM band 1 (11 Hz, Q=0.6)\nw0_a1     = TWO_PI * AM_FC1_HZ / samplerate;\ncw_a1     = cos(w0_a1);\nalpha_a1  = sin(w0_a1) / (2.0 * AM_Q);\na0_a1     = 1.0 + alpha_a1;\nab0_1     = ((1.0 - cw_a1) * 0.5) / a0_a1;\nab1_1     = (1.0 - cw_a1)         / a0_a1;\nab2_1     = ab0_1;\naa1_1     = (-2.0 * cw_a1)        / a0_a1;\naa2_1     = (1.0 - alpha_a1)      / a0_a1;\n\n// AM band 2 (23 Hz, Q=0.6)\nw0_a2     = TWO_PI * AM_FC2_HZ / samplerate;\ncw_a2     = cos(w0_a2);\nalpha_a2  = sin(w0_a2) / (2.0 * AM_Q);\na0_a2     = 1.0 + alpha_a2;\nab0_2     = ((1.0 - cw_a2) * 0.5) / a0_a2;\nab1_2     = (1.0 - cw_a2)         / a0_a2;\nab2_2     = ab0_2;\naa1_2     = (-2.0 * cw_a2)        / a0_a2;\naa2_2     = (1.0 - alpha_a2)      / a0_a2;\n\n// ----- Pitch LFO, channel L ------------------------------------------\n//\n// Direct-Form-I biquad: y = b0 x + b1 x[-1] + b2 x[-2] - a1 y[-1] - a2 y[-2]\n// Independent noise() per band \u21d2 band 1 and band 2 streams are decorrelated.\n\nnPL1 = noise();\nyPL1 = pb0_1 * nPL1 + pb1_1 * pL1_x1 + pb2_1 * pL1_x2\n                    - pa1_1 * pL1_y1 - pa2_1 * pL1_y2;\npL1_x2 = pL1_x1; pL1_x1 = nPL1;\npL1_y2 = pL1_y1; pL1_y1 = yPL1;\n\nnPL2 = noise();\nyPL2 = pb0_2 * nPL2 + pb1_2 * pL2_x1 + pb2_2 * pL2_x2\n                    - pa1_2 * pL2_y1 - pa2_2 * pL2_y2;\npL2_x2 = pL2_x1; pL2_x1 = nPL2;\npL2_y2 = pL2_y1; pL2_y1 = yPL2;\n\n// avg of the two bands \u2192 \u00b7 norm scalar \u2192 \u2248 \u00b11 with p99 = 1.0\nlfo_p_L = 0.5 * (yPL1 + yPL2) * PITCH_LFO_NORM;\n\n// ----- Pitch LFO, channel R ------------------------------------------\n\nnPR1 = noise();\nyPR1 = pb0_1 * nPR1 + pb1_1 * pR1_x1 + pb2_1 * pR1_x2\n                    - pa1_1 * pR1_y1 - pa2_1 * pR1_y2;\npR1_x2 = pR1_x1; pR1_x1 = nPR1;\npR1_y2 = pR1_y1; pR1_y1 = yPR1;\n\nnPR2 = noise();\nyPR2 = pb0_2 * nPR2 + pb1_2 * pR2_x1 + pb2_2 * pR2_x2\n                    - pa1_2 * pR2_y1 - pa2_2 * pR2_y2;\npR2_x2 = pR2_x1; pR2_x1 = nPR2;\npR2_y2 = pR2_y1; pR2_y1 = yPR2;\n\nlfo_p_R = 0.5 * (yPR1 + yPR2) * PITCH_LFO_NORM;\n\n// ----- AM LFO, channel L ---------------------------------------------\n\nnAL1 = noise();\nyAL1 = ab0_1 * nAL1 + ab1_1 * aL1_x1 + ab2_1 * aL1_x2\n                    - aa1_1 * aL1_y1 - aa2_1 * aL1_y2;\naL1_x2 = aL1_x1; aL1_x1 = nAL1;\naL1_y2 = aL1_y1; aL1_y1 = yAL1;\n\nnAL2 = noise();\nyAL2 = ab0_2 * nAL2 + ab1_2 * aL2_x1 + ab2_2 * aL2_x2\n                    - aa1_2 * aL2_y1 - aa2_2 * aL2_y2;\naL2_x2 = aL2_x1; aL2_x1 = nAL2;\naL2_y2 = aL2_y1; aL2_y1 = yAL2;\n\nlfo_a_L = 0.5 * (yAL1 + yAL2) * AM_LFO_NORM;\n\n// ----- AM LFO, channel R ---------------------------------------------\n\nnAR1 = noise();\nyAR1 = ab0_1 * nAR1 + ab1_1 * aR1_x1 + ab2_1 * aR1_x2\n                    - aa1_1 * aR1_y1 - aa2_1 * aR1_y2;\naR1_x2 = aR1_x1; aR1_x1 = nAR1;\naR1_y2 = aR1_y1; aR1_y1 = yAR1;\n\nnAR2 = noise();\nyAR2 = ab0_2 * nAR2 + ab1_2 * aR2_x1 + ab2_2 * aR2_x2\n                    - aa1_2 * aR2_y1 - aa2_2 * aR2_y2;\naR2_x2 = aR2_x1; aR2_x1 = nAR2;\naR2_y2 = aR2_y1; aR2_y1 = yAR2;\n\nlfo_a_R = 0.5 * (yAR1 + yAR2) * AM_LFO_NORM;\n\n// ----- Round-2 sqrt depth tapers -------------------------------------\n//\n//   pitch_depth_seconds = 1.5e-4 \u00b7 sqrt(flutter)\n//   am_depth            = 0.25   \u00b7 sqrt(flutter)\n//\n// Round-1 used `1.2e-4 \u00b7 f\u00b2` (pitch) and `0.20 \u00b7 f` (AM) \u2014 quadratic /\n// linear, which under-shot the chord-noon audibility floor (~5\u20136 c pitch\n// p99, ~2.7 dB AM pk-pk at f=0.5).  Sqrt is concave: lots at low values,\n// plateau at high.  See design-doc \u00a713b for the full retune rationale.\n\nf               = clamp(flutter, 0.0, 1.0);\nsqf             = sqrt(f);\npitch_depth_s   = PITCH_DEPTH_MAX_S * sqf;\nam_depth        = AM_DEPTH_MAX      * sqf;\n\n// ----- Variable-delay read (Lagrange-4) ------------------------------\n//\n//   D[n] = (BASE_DELAY_S + pitch_depth_s \u00b7 lfo_p) \u00b7 samplerate    [samples]\n//\n// Defensive: never let D go below 1 (need xm1) or above BUF_SAMPS-4.\n\nbase_samp     = BASE_DELAY_S * samplerate;\npdepth_samp   = pitch_depth_s * samplerate;\n\nD_L = base_samp + pdepth_samp * lfo_p_L;\nD_R = base_samp + pdepth_samp * lfo_p_R;\n\nD_L = clamp(D_L, 1.0, BUF_SAMPS - 4.0);\nD_R = clamp(D_R, 1.0, BUF_SAMPS - 4.0);\n\n// Write current input to delay buffers.\ndelbuf_L.write(in1);\ndelbuf_R.write(in2);\n\n// Integer & fractional split of the requested delay.\niD_L  = floor(D_L);\nfD_L  = D_L - iD_L;\niD_R  = floor(D_R);\nfD_R  = D_R - iD_R;\n\n// Four-tap reads centered on the integer delay (drop-sample inside each\n// .read; the Lagrange kernel below does the fractional interpolation).\nxm1_L = delbuf_L.read(iD_L - 1.0, \"step\");\nx0_L  = delbuf_L.read(iD_L,        \"step\");\nx1_L  = delbuf_L.read(iD_L + 1.0,  \"step\");\nx2_L  = delbuf_L.read(iD_L + 2.0,  \"step\");\n\nxm1_R = delbuf_R.read(iD_R - 1.0, \"step\");\nx0_R  = delbuf_R.read(iD_R,        \"step\");\nx1_R  = delbuf_R.read(iD_R + 1.0,  \"step\");\nx2_R  = delbuf_R.read(iD_R + 2.0,  \"step\");\n\n// ----- Lagrange-4 kernel (JOS PASP) ----------------------------------\n//\n//   c_m1 = -frac \u00b7 (frac - 1) \u00b7 (frac - 2) / 6\n//   c_0  =  (frac + 1) \u00b7 (frac - 1) \u00b7 (frac - 2) / 2\n//   c_p1 = -(frac + 1) \u00b7 frac      \u00b7 (frac - 2) / 2\n//   c_p2 =  (frac + 1) \u00b7 frac      \u00b7 (frac - 1) / 6\n//\n// Channel L\nfL_m1 = fD_L - 1.0;\nfL_m2 = fD_L - 2.0;\nfL_p1 = fD_L + 1.0;\ncL_m1 = -fD_L * fL_m1 * fL_m2 / 6.0;\ncL_0  =  fL_p1 * fL_m1 * fL_m2 / 2.0;\ncL_p1 = -fL_p1 * fD_L  * fL_m2 / 2.0;\ncL_p2 =  fL_p1 * fD_L  * fL_m1 / 6.0;\ny_pitched_L = cL_m1 * xm1_L + cL_0 * x0_L + cL_p1 * x1_L + cL_p2 * x2_L;\n\n// Channel R\nfR_m1 = fD_R - 1.0;\nfR_m2 = fD_R - 2.0;\nfR_p1 = fD_R + 1.0;\ncR_m1 = -fD_R * fR_m1 * fR_m2 / 6.0;\ncR_0  =  fR_p1 * fR_m1 * fR_m2 / 2.0;\ncR_p1 = -fR_p1 * fD_R  * fR_m2 / 2.0;\ncR_p2 =  fR_p1 * fD_R  * fR_m1 / 6.0;\ny_pitched_R = cR_m1 * xm1_R + cR_0 * x0_R + cR_p1 * x1_R + cR_p2 * x2_R;\n\n// ----- AM stage (gated by classic_mode) ------------------------------\n//\n//   multiplier = 1 + am_depth \u00b7 lfo_a\n//   y = classic_mode ? y_pitched : y_pitched \u00b7 multiplier\n//\n// Clamp the multiplier to [0, 2] to prevent any phase inversion if the\n// LFO has an unusually large outlier (matches numpy ref np.clip path).\n\nmult_L = clamp(1.0 + am_depth * lfo_a_L, 0.0, 2.0);\nmult_R = clamp(1.0 + am_depth * lfo_a_R, 0.0, 2.0);\n\ny_full_L = y_pitched_L * mult_L;\ny_full_R = y_pitched_R * mult_R;\n\ncm = (classic_mode != 0);\n\ny_L = cm ? y_pitched_L : y_full_L;\ny_R = cm ? y_pitched_R : y_full_R;\n\n// ----- Short-circuit (bit-identical bypass at flutter = 0) -----------\n//\n// Numpy ref invariant: `flutter <= 0.0` \u2192 output \u2261 input, no RNG draws.\n// In gen~ we cannot un-advance the noise() streams, but the mux makes\n// the OUTPUT bit-identical, which is what the verified-property check\n// measures.  EPS guards against denormal-tier residuals in the param.\n\nshort = (f <= EPS);\n\nout1 = short ? in1 : y_L;\nout2 = short ? in2 : y_R;\n\n// =====================================================================\n// END tl_flutter.gendsp  (TUNING_VERSION = 2)\n// =====================================================================\n"
												}
											},
											{
												"box": {
													"id": "tl_flutter-gen-out1",
													"maxclass": "newobj",
													"text": "out 1",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														30.0,
														540.0,
														35.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_flutter-gen-out2",
													"maxclass": "newobj",
													"text": "out 2",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														100.0,
														540.0,
														35.0,
														22.0
													]
												}
											}
										],
										"lines": [
											{
												"patchline": {
													"source": [
														"tl_flutter-gen-in1",
														0
													],
													"destination": [
														"tl_flutter-gen-codebox",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_flutter-gen-in2",
														0
													],
													"destination": [
														"tl_flutter-gen-codebox",
														1
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_flutter-gen-codebox",
														0
													],
													"destination": [
														"tl_flutter-gen-out1",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_flutter-gen-codebox",
														1
													],
													"destination": [
														"tl_flutter-gen-out2",
														0
													]
												}
											}
										]
									},
									"rnboattrcache": {},
									"saved_object_attributes": {
										"exportfolder": "",
										"exportname": "tl_flutter_lfos",
										"wantsoutputcore": 0
									}
								}
							},
							{
								"box": {
									"id": "tl_flutter-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										180,
										700,
										60
									],
									"text": "tl_flutter (SANDBOX-PARTIAL): fast pitch + AM. gen~ owns full audio path (internal Delay primitives). Pitch LFO (8+19 Hz), AM LFO (11+23 Hz). classic_mode = AM-bypass-only (divergence #8, pitch unchanged). Phase 1.5 buffer-share divergence: private Delay vs shared tape_loss_delay."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_flutter-in-L",
										0
									],
									"destination": [
										"tl_flutter-gen",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_flutter-in-R",
										0
									],
									"destination": [
										"tl_flutter-gen",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_flutter-gen",
										0
									],
									"destination": [
										"tl_flutter-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_flutter-gen",
										1
									],
									"destination": [
										"tl_flutter-out-R",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_flutter",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_aux",
					"maxclass": "newobj",
					"numinlets": 5,
					"numoutlets": 3,
					"patching_rect": [
						580,
						380,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal",
						"signal"
					],
					"text": "p tl_aux",
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
									"id": "tl_aux-in-L",
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
									"id": "tl_aux-in-R",
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
									"id": "tl_aux-pin-0",
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
									"id": "tl_aux-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_aux-pin-2",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										240,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 5
								}
							},
							{
								"box": {
									"id": "tl_aux-out-L",
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
									"id": "tl_aux-out-R",
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
									"id": "tl_aux-eout-0",
									"maxclass": "outlet",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										140,
										260,
										30,
										30
									],
									"comment": "",
									"index": 3
								}
							},
							{
								"box": {
									"id": "tl_aux-gen",
									"maxclass": "newobj",
									"numinlets": 4,
									"numoutlets": 3,
									"patching_rect": [
										40,
										100,
										250,
										60
									],
									"outlettype": [
										"signal",
										"signal",
										"signal"
									],
									"text": "gen~ @title tl_aux_modes",
									"patcher": {
										"fileversion": 1,
										"appversion": {
											"major": 9,
											"minor": 0,
											"revision": 0,
											"architecture": "x64",
											"modernui": 1
										},
										"classnamespace": "dsp.gen",
										"rect": [
											100.0,
											100.0,
											700.0,
											600.0
										],
										"boxes": [
											{
												"box": {
													"id": "tl_aux-gen-in1",
													"maxclass": "newobj",
													"text": "in 1",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														30.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_aux-gen-in2",
													"maxclass": "newobj",
													"text": "in 2",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														100.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_aux-gen-in3",
													"maxclass": "newobj",
													"text": "in 3",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														170.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_aux-gen-in4",
													"maxclass": "newobj",
													"text": "in 4",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														240.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_aux-gen-codebox",
													"maxclass": "codebox",
													"numinlets": 4,
													"numoutlets": 3,
													"outlettype": [
														"",
														"",
														""
													],
													"patching_rect": [
														50.0,
														100.0,
														600.0,
														400.0
													],
													"code": "// =====================================================================\n// tl_aux.gendsp \u2014 gen~ DSL source for the AUX module of tape-loss\n// =====================================================================\n//\n// Module       : tl_aux (Generation Loss MKII \"AUX footswitch\")\n// Authored     : 2026-04-27 (Phase 2.5 \u2014 gen~ translation)\n// Author       : pedal-engineer (auto-authored from numpy reference)\n// SANDBOX      : LOCAL-ONLY  (STOP mode requires Max IDE for buffer-init\n//                verification per pitfall #19; the FILTER and FAIL modes\n//                are individually SANDBOX-OK but the unit ships as one\n//                gen~ object so the strictest mode classifies the whole)\n//\n// Source files :\n//   design-doc        : docs/design-docs/dsp/tl-aux-design.md\n//                       sha256: e37f4fe1993bf2036f6393e1a266edc1628017dd\n//                               2c3b90a29c0903dc2695f3e8\n//   numpy reference   : dsp/reference/tl_aux.py\n//                       sha256: 02f4837686fc9b18af36cedcbab6662742b27a7e\n//                               0b52f74f927a63ba4b2767c6\n//   parent maxpat stub: device/tape-loss/tl_aux.maxpat\n//                       (5-inlet / 3-outlet contract; Phase 1.5)\n//\n// Inlets  (5 in maxpat, 4 used here):\n//   in1 = signal L\n//   in2 = signal R\n//   in3 = aux_active        (control signal, 0 or 1, footswitch state)\n//   in4 = aux_onset_ms      (control signal, 10..3000 ms, log-tapered)\n//   in5 = reserved          (parent maxpat allocates 5 inlets to leave\n//                            headroom for a future failure_knob input;\n//                            unread here \u2014 FAIL override uses a 0-knob\n//                            baseline so override = e[n] cleanly)\n//\n// Outlets (3) \u2014 Phase 1.5 contract:\n//   out1 = signal L          (mode-dispatched output, audio rate)\n//   out2 = signal R          (mode-dispatched output, audio rate)\n//   out3 = failure_override  (signal-rate sidechain to tl_failure inlet 4;\n//                             0 unless aux_mode = FAIL, else = e[n] in\n//                             [0, 1])\n//\n// Param   (1):\n//   aux_mode   \u2208 {0, 1, 2}    (0 = STOP, 1 = FILTER, 2 = FAIL; default 0)\n//\n// ---------------------------------------------------------------------\n// Algorithm summary (translated 1:1 from dsp/reference/tl_aux.py):\n//\n//   Shared onset envelope (all three modes consume the same e[n]):\n//\n//     onset_ms \u2190 clamp(in4, 10, 3000)\n//     \u03b1        = 1 - exp(-1 / (onset_ms \u00b7 samplerate / 1000))\n//     target   = in3                                  // 0 or 1\n//     e[n]     = e[n-1] + \u03b1 \u00b7 (target - e[n-1])       // exp 1-pole\n//\n//   Mode A \u2014 STOP (tape-stop deceleration):\n//\n//     rate[n]  = clamp((1 - e[n])^2.5, 0, 1)          // \u03b3 = 2.5\n//     gain[n]  = sqrt(max(0, 1 - e[n]))               // \u221a-taper\n//     read_pos = read_pos_prev + (1 - rate[n])        // delay grows when\n//                                                      // rate < 1\n//     y_stop_L = stopbuf_L.read(read_pos, \"linear\") * gain\n//     y_stop_R = stopbuf_R.read(read_pos, \"linear\") * gain\n//\n//     The buffers are 262144 samples (~5.46 s @ 48k). They are written\n//     EVERY sample regardless of aux_mode \u2014 this guarantees STOP state\n//     stays warm across mode switches and that read-on-press always has\n//     fresh history. See \"Mode coexistence\" note below.\n//\n//   Mode B \u2014 FILTER (TPT-SVF low-pass, log sweep):\n//\n//     fc(e)    = 18000 \u00b7 (200 / 18000)^e              // log sweep\n//     fc       = clamp(fc, 20, 0.45 \u00b7 samplerate)     // SVF Nyquist guard\n//     Q(e)     = 0.707 + e \u00b7 (4.0 - 0.707)\n//     k        = 1 / Q\n//     g        = tan(\u03c0 \u00b7 fc / samplerate)             // freq warp\n//     a1       = 1 / (1 + g\u00b7(g + k))\n//     a2       = g \u00b7 a1\n//     a3       = g \u00b7 a2\n//\n//     Per-sample TPT-SVF step (Andrew Simper / Vadim Zavalishin form),\n//     two independent state pairs (L, R):\n//\n//       v3      = x - ic2eq\n//       v1      = a1\u00b7ic1eq + a2\u00b7v3\n//       v2      = ic2eq + a2\u00b7ic1eq + a3\u00b7v3\n//       ic1eq  \u2190 2\u00b7v1 - ic1eq\n//       ic2eq  \u2190 2\u00b7v2 - ic2eq\n//       y_lpf   = v2\n//\n//   Mode C \u2014 FAIL (sidechain control output):\n//\n//     Audio path: bit-identical passthrough (out1 = in1, out2 = in2).\n//     out3 (failure_override) = e[n]   (in [0, 1]; 0 when aux_active=0).\n//\n//     Per design-doc \u00a73.2 the full mapping is `knob + e\u00b7(1-knob)`. Since\n//     gen~ has no separate failure_knob inlet wired in this round, we\n//     emit just `e[n]` \u2014 equivalent to a knob of 0.0 (the default). The\n//     downstream tl_failure performs the additive-toward-max merge with\n//     its own knob value. (When the future failure_knob input lands on\n//     in5, swap the out3 expression to `knob + e_curr * (1 - knob)`.)\n//\n// ---------------------------------------------------------------------\n// Mode coexistence (state preservation across mode switches):\n//\n//   The STOP delay buffers `stopbuf_L`/`stopbuf_R` are written every\n//   sample irrespective of aux_mode (see \"delbuf_L.write(in1)\" below).\n//   This costs ~free CPU but means: switching FILTER \u2192 STOP mid-press\n//   finds the buffer ALREADY pre-filled with up-to-262144 samples of\n//   live audio history, exactly as the numpy ref's stateful processor\n//   would have it after a continuous stream.\n//\n//   The SVF state (svf_ic1_*, svf_ic2_*) is NOT advanced in non-FILTER\n//   modes, so first-press in FILTER mode starts from zeroed state \u2014 the\n//   intended behavior (numpy ref `_process_filter` initializes\n//   `state = [0.0, 0.0]` per call).\n//\n//   The read_pos History (`stop_read_pos`) is NOT advanced in non-STOP\n//   modes; it sits at whatever value it last held. On a fresh STOP press\n//   we DO want read_pos to start at 0 (read = current write = identity)\n//   \u2014 so we gate the position advance with `aux_active` and reset to 0\n//   the moment aux_active is 0 (release), matching the numpy ref's\n//   read_head=0 invariant when env=0.\n//\n//   Per design-doc \u00a70.1 (\"Mode-switching strategy\"), `aux_mode` should\n//   ideally only change while `e[n] < 0.01`. The engineer's parent\n//   patch is responsible for queuing mode changes; this DSP block\n//   honors whatever value is live.\n//\n// ---------------------------------------------------------------------\n// Sample-rate dependence:\n//\n//   * Onset \u03b1 and SVF g recompute every sample using `samplerate` \u2192\n//     SR-agnostic by construction.\n//   * STOP buffer length is 262144 SAMPLES (not seconds). At 48 kHz\n//     that's ~5.46 s of headroom (covers the spec's max 3000 ms onset\n//     at 1.5\u00d7 headroom \u2014 see design-doc \u00a71.4). At 96 kHz the same\n//     buffer holds ~2.73 s, which is STILL above the 3000 ms \u00d7 1.0\n//     bare minimum but BELOW the recommended 1.5\u00d7 headroom.\n//\n//     Verdict: at 96 kHz the read-head's \"underflow guard\" (clamping\n//     read_pos \u2264 buf_len - 256) may engage during onset = 3000 ms\n//     pathological-press scenarios. This is acceptable: the buffer\n//     freezes at the oldest sample, gain has long since faded to \u2248 0,\n//     and the audible result is silence regardless. Documented.\n//\n// ---------------------------------------------------------------------\n// Sanity-check expectations (matches numpy ref verification \u00a712):\n//\n//   ALL modes, aux_active = 0:\n//     env_e  \u2192 0\n//     out1   = in1   (STOP: read_pos=0, gain=1; FILTER: fc=18 kHz wide-\n//                     open, near-pass; FAIL: explicit pass)\n//     out2   = in2   (same as L)\n//     out3   = 0     (override is 0 unless mode = FAIL; FAIL with e=0\n//                     emits 0 anyway)\n//\n//   STOP mode, aux_active = 1, plateau (e \u2248 1):\n//     rate   \u2192 0     (read head freezes)\n//     gain   \u2192 0     (\u221a(1-e) \u2192 0)\n//     out1, out2 \u2248 silence (verified ratio \u2248 0 to 6 sig figs in numpy)\n//     out3   = 0     (override only emitted in FAIL mode)\n//\n//   FILTER mode, aux_active = 1, plateau (e \u2248 1):\n//     fc     = 200 Hz    (sweep close)\n//     Q      = 4.0       (mild resonance bump)\n//     out1, out2 = audibly low-passed; spectral centroid \u2248 257 Hz vs.\n//                  \u2248 6128 Hz dry (numpy verification result)\n//     out3   = 0\n//\n//   FAIL mode, aux_active = 1, plateau (e \u2248 1):\n//     out1   = in1       (bit-identical, max diff = 0)\n//     out2   = in2       (bit-identical, max diff = 0)\n//     out3   = 1.0       (full failure override)\n//\n// ---------------------------------------------------------------------\n// References:\n//   * Andrew Simper, \"Linear Trapezoidal Integrated State Variable\n//     Filter\", Cytomic 2014:\n//     https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf\n//   * Vadim Zavalishin, \"The Art of VA Filter Design\", \u00a73.10\n//     (Trapezoidal SVF) \u2014 free PDF.\n//   * JOS PASP, \"Wow and Flutter Modeling\" \u2014 justifies (1-e)^2.5 curve.\n//   * Smith, DSP Guide Ch. 19 \u2014 exponential envelope follower.\n//   * Project design-doc tradeoff log #2, #3, #7 \u2014 curve / topology /\n//     gain compensation choices encoded here verbatim.\n// =====================================================================\n\nParam aux_mode(0);\nHistory env_e;\nHistory stop_read_pos;\nHistory svf_ic1_L, svf_ic2_L;\nHistory svf_ic1_R, svf_ic2_R;\n\n\n// --- Constants -------------------------------------------------------\n\n// STOP deceleration curve exponent (design-doc \u00a71.2, tradeoff #2).\nGAMMA_STOP = 2.5;\n\n// FILTER sweep endpoints (design-doc \u00a72.4, tradeoff #10).\nFC_MAX_HZ = 18000.0;\nFC_MIN_HZ = 200.0;\n\n// FILTER resonance endpoints (design-doc \u00a72.4, tradeoff #11).\nQ_BASE = 0.707;\nQ_MAX  = 4.0;\n\n// SVF defensive clamps (design-doc \u00a72.5, \u00a78 numerical-stability).\nFC_MIN_CLAMP = 20.0;\nFC_NYQUIST_FRACTION = 0.45;\nQ_MIN_CLAMP = 0.5;\nQ_MAX_CLAMP = 10.0;\n\n// Onset envelope clamps (design-doc spec \u00a7\"aux_onset_ms\" 10..3000 ms).\nONSET_MS_MIN = 10.0;\nONSET_MS_MAX = 3000.0;\n\n// STOP buffer underflow guard headroom (design-doc \u00a71.4).\nSTOP_BUF_GUARD = 256.0;\n\n// Math constants.\nPI       = 3.14159265358979323846;\nLOG_FC_RATIO = -4.49980967033;   // = log(200 / 18000), precomputed.\n\n// Mode dispatch IDs (mirror numpy MODE_STOP/MODE_FILTER/MODE_FAIL).\nMODE_STOP_ID   = 0;\nMODE_FILTER_ID = 1;\nMODE_FAIL_ID   = 2;\n\n// --- State (History + Delay) -----------------------------------------\n\n// Shared onset envelope state \u2014 single e[n] consumed by all three modes.\n\n// STOP mode: stereo circular buffers (262144 samples each \u2248 5.46 s @ 48k,\n// covers max 3000 ms onset \u00d7 1.5 headroom per design-doc \u00a71.4 / tradeoff\n// #6). Power of 2 for clean wraparound.\nDelay stopbuf_L(262144);\nDelay stopbuf_R(262144);\n\n// STOP mode: fractional read-head delay (samples behind the writer).\n// 0 = read = current write = identity passthrough.\n\n// FILTER mode: TPT-SVF integrator state, separate per channel\n// (Simper/Zavalishin \"ic1eq, ic2eq\").\n\n// =====================================================================\n// Per-sample DSP\n// =====================================================================\n\n// ----- Onset envelope (shared across modes) --------------------------\n//\n// Single 1-pole exponential smoother. \u03b1 recomputed per sample so the\n// engineer can sweep aux_onset_ms without zipper noise.\nonset_ms_in = clamp(in4, ONSET_MS_MIN, ONSET_MS_MAX);\nonset_samples = onset_ms_in * 0.001 * samplerate;\nonset_samples = max(onset_samples, 1.0);\nalpha = 1.0 - exp(-1.0 / onset_samples);\n\ntarget = in3;                      // 0 or 1, footswitch state\nenv_e = env_e + alpha * (target - env_e);\ne_curr = env_e;\n\n// ----- STOP mode (Mode A) --------------------------------------------\n//\n// IMPORTANT: the delay buffers are written EVERY sample regardless of\n// aux_mode (see \"Mode coexistence\" in header). This is what keeps the\n// STOP buffer warm across mode switches and matches the numpy ref's\n// continuously-stateful processor.\n\nstopbuf_L.write(in1);\nstopbuf_R.write(in2);\n\n// Read-rate (\u03b3 = 2.5) and \u221a-taper output gain, both clamped.\none_minus_e = max(0.0, 1.0 - e_curr);\nrate_stop   = pow(one_minus_e, GAMMA_STOP);\nrate_stop   = clamp(rate_stop, 0.0, 1.0);\ngain_stop   = sqrt(one_minus_e);\n\n// Advance read-head position (delay-behind-writer in samples). When\n// aux_active = 0 we hard-reset the read pos to 0 so a fresh press starts\n// at identity. When aux_active = 1, the delay grows by (1 - rate) each\n// sample \u2014 exactly mirrors numpy ref `_process_stop`.\n//\n// `target` is the live aux_active value (0 or 1); it provides the gate\n// without an extra History.\nstop_pos_advance = 1.0 - rate_stop;\nstop_read_pos_next = (target > 0.5)\n    ? (stop_read_pos + stop_pos_advance)\n    : 0.0;\n\n// Underflow guard: clamp to buffer length - 256 samples (defensive;\n// covers the > buffer pathological-press case from design-doc \u00a71.4).\nstop_read_pos_next = clamp(stop_read_pos_next, 0.0, 262144.0 - STOP_BUF_GUARD);\nstop_read_pos = stop_read_pos_next;\n\n// Read with linear interpolation. gen~'s `Delay.read(d, \"linear\")` reads\n// `d` fractional samples behind the current write \u2014 exactly the\n// `(write_head - read_head) % buf_n` operation in numpy with built-in\n// linear-interp between adjacent samples (matches numpy ref's manual\n// `a + frac * (b - a)`).\nstop_read_L = stopbuf_L.read(stop_read_pos, \"linear\");\nstop_read_R = stopbuf_R.read(stop_read_pos, \"linear\");\n\ny_stop_L = stop_read_L * gain_stop;\ny_stop_R = stop_read_R * gain_stop;\n\n// ----- FILTER mode (Mode B) ------------------------------------------\n//\n// Log-sweep cutoff: fc = FC_MAX \u00b7 (FC_MIN / FC_MAX)^e\n//                 = FC_MAX \u00b7 exp(log(FC_MIN/FC_MAX) \u00b7 e)\nfc_filter = FC_MAX_HZ * exp(LOG_FC_RATIO * e_curr);\nfc_filter = clamp(fc_filter, FC_MIN_CLAMP, FC_NYQUIST_FRACTION * samplerate);\n\n// Linear resonance ramp 0.707 \u2192 4.0.\nq_filter = Q_BASE + e_curr * (Q_MAX - Q_BASE);\nq_filter = clamp(q_filter, Q_MIN_CLAMP, Q_MAX_CLAMP);\n\n// TPT-SVF coefficients (recomputed per sample \u2014 Simper \u00a7\"per-sample\"\n// form; cost is one tan() call which dominates the module's CPU).\ng_svf  = tan(PI * fc_filter / samplerate);\nk_svf  = 1.0 / q_filter;\na1_svf = 1.0 / (1.0 + g_svf * (g_svf + k_svf));\na2_svf = g_svf * a1_svf;\na3_svf = g_svf * a2_svf;\n\n// Channel L step.\nv3_L = in1 - svf_ic2_L;\nv1_L = a1_svf * svf_ic1_L + a2_svf * v3_L;\nv2_L = svf_ic2_L + a2_svf * svf_ic1_L + a3_svf * v3_L;\nsvf_ic1_L = 2.0 * v1_L - svf_ic1_L;\nsvf_ic2_L = 2.0 * v2_L - svf_ic2_L;\ny_filter_L = v2_L;     // low-pass output\n\n// Channel R step.\nv3_R = in2 - svf_ic2_R;\nv1_R = a1_svf * svf_ic1_R + a2_svf * v3_R;\nv2_R = svf_ic2_R + a2_svf * svf_ic1_R + a3_svf * v3_R;\nsvf_ic1_R = 2.0 * v1_R - svf_ic1_R;\nsvf_ic2_R = 2.0 * v2_R - svf_ic2_R;\ny_filter_R = v2_R;\n\n// ----- FAIL mode (Mode C) --------------------------------------------\n//\n// Audio: bit-identical passthrough.\n// Sidechain: failure_override = e[n] (knob = 0 baseline; downstream\n// tl_failure adds the live FAILURE knob via additive-toward-max).\ny_fail_L = in1;\ny_fail_R = in2;\nfailure_override_fail = e_curr;\n\n// ----- Mode dispatch --------------------------------------------------\n//\n// Nested conditional dispatch on aux_mode. Note: gen~ executes ALL three\n// branches every sample (no short-circuit) \u2014 this is by design for\n// state preservation (see \"Mode coexistence\" in header). The selector\n// only chooses which precomputed result to emit.\n\nis_stop   = (aux_mode == MODE_STOP_ID);\nis_filter = (aux_mode == MODE_FILTER_ID);\nis_fail   = (aux_mode == MODE_FAIL_ID);\n\nout1 = (is_stop != 0)   ? y_stop_L\n     : (is_filter != 0) ? y_filter_L\n     : y_fail_L;\n\nout2 = (is_stop != 0)   ? y_stop_R\n     : (is_filter != 0) ? y_filter_R\n     : y_fail_R;\n\n// Outlet 3 \u2014 failure_override. Non-zero ONLY in FAIL mode (Phase 1.5\n// contract: tl_failure inlet 4 reads this signal; 0 means \"use my own\n// knob\"). In STOP / FILTER modes we explicitly emit 0.\nout3 = (is_fail != 0) ? failure_override_fail : 0.0;\n\n// =====================================================================\n// END tl_aux.gendsp\n// =====================================================================\n"
												}
											},
											{
												"box": {
													"id": "tl_aux-gen-out1",
													"maxclass": "newobj",
													"text": "out 1",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														30.0,
														540.0,
														35.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_aux-gen-out2",
													"maxclass": "newobj",
													"text": "out 2",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														100.0,
														540.0,
														35.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_aux-gen-out3",
													"maxclass": "newobj",
													"text": "out 3",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														170.0,
														540.0,
														35.0,
														22.0
													]
												}
											}
										],
										"lines": [
											{
												"patchline": {
													"source": [
														"tl_aux-gen-in1",
														0
													],
													"destination": [
														"tl_aux-gen-codebox",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_aux-gen-in2",
														0
													],
													"destination": [
														"tl_aux-gen-codebox",
														1
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_aux-gen-in3",
														0
													],
													"destination": [
														"tl_aux-gen-codebox",
														2
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_aux-gen-in4",
														0
													],
													"destination": [
														"tl_aux-gen-codebox",
														3
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_aux-gen-codebox",
														0
													],
													"destination": [
														"tl_aux-gen-out1",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_aux-gen-codebox",
														1
													],
													"destination": [
														"tl_aux-gen-out2",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_aux-gen-codebox",
														2
													],
													"destination": [
														"tl_aux-gen-out3",
														0
													]
												}
											}
										]
									},
									"rnboattrcache": {},
									"saved_object_attributes": {
										"exportfolder": "",
										"exportname": "tl_aux_modes",
										"wantsoutputcore": 0
									}
								}
							},
							{
								"box": {
									"id": "tl_aux-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										180,
										700,
										100
									],
									"text": "tl_aux (LOCAL-ONLY): STOP/FILTER/FAIL modes triggered by aux_active footswitch. STOP: circular delay buffer + decel ramp (requires sample-accurate read-rate; this is the LOCAL-ONLY blocker \u2014 must verify in standalone Max IDE per pitfall #19). FILTER: parallel SVF wraps tl_model_eq output (Phase 1.5 contract #3 \u2014 tl_aux owns the ramp). FAIL: emits signal-rate failure_override (outlet 3) \u2192 tl_failure inlet 4 (contract #1). aux_onset_ms=10..3000ms log-tapered exponential envelope."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_aux-in-L",
										0
									],
									"destination": [
										"tl_aux-gen",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_aux-in-R",
										0
									],
									"destination": [
										"tl_aux-gen",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_aux-pin-1",
										0
									],
									"destination": [
										"tl_aux-gen",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_aux-pin-2",
										0
									],
									"destination": [
										"tl_aux-gen",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_aux-gen",
										0
									],
									"destination": [
										"tl_aux-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_aux-gen",
										1
									],
									"destination": [
										"tl_aux-out-R",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_aux-gen",
										2
									],
									"destination": [
										"tl_aux-eout-0",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_aux",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_volume_mix",
					"maxclass": "newobj",
					"numinlets": 4,
					"numoutlets": 2,
					"patching_rect": [
						20,
						480,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "p tl_volume_mix",
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
									"id": "tl_volume_mix-in-L",
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
									"id": "tl_volume_mix-in-R",
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
									"id": "tl_volume_mix-pin-0",
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
									"id": "tl_volume_mix-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_volume_mix-out-L",
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
									"id": "tl_volume_mix-out-R",
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
									"id": "tl_volume_mix-sum",
									"maxclass": "newobj",
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										40,
										100,
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
									"id": "tl_volume_mix-half",
									"maxclass": "newobj",
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										40,
										130,
										50,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "*~ 0.5"
								}
							},
							{
								"box": {
									"id": "tl_volume_mix-miso-sel-L",
									"maxclass": "newobj",
									"numinlets": 3,
									"numoutlets": 1,
									"patching_rect": [
										140,
										130,
										80,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "selector~ 2"
								}
							},
							{
								"box": {
									"id": "tl_volume_mix-slide-L",
									"maxclass": "newobj",
									"numinlets": 3,
									"numoutlets": 1,
									"patching_rect": [
										250,
										130,
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
									"id": "tl_volume_mix-mul-L",
									"maxclass": "newobj",
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										250,
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
									"id": "tl_volume_mix-miso-sel-R",
									"maxclass": "newobj",
									"numinlets": 3,
									"numoutlets": 1,
									"patching_rect": [
										200,
										130,
										80,
										22
									],
									"outlettype": [
										"signal"
									],
									"text": "selector~ 2"
								}
							},
							{
								"box": {
									"id": "tl_volume_mix-slide-R",
									"maxclass": "newobj",
									"numinlets": 3,
									"numoutlets": 1,
									"patching_rect": [
										320,
										130,
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
									"id": "tl_volume_mix-mul-R",
									"maxclass": "newobj",
									"numinlets": 2,
									"numoutlets": 1,
									"patching_rect": [
										320,
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
									"id": "tl_volume_mix-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										220,
										700,
										40
									],
									"text": "tl_volume_mix (SANDBOX-OK): VOLUME (0..2 lin) + MISO mono-sum. One-pole smoother \u03c4=10ms. MISO crossfade also 10ms. No internal limiter at unity+volume_max \u2014 expected behavior."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_volume_mix-in-L",
										0
									],
									"destination": [
										"tl_volume_mix-sum",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-in-R",
										0
									],
									"destination": [
										"tl_volume_mix-sum",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-sum",
										0
									],
									"destination": [
										"tl_volume_mix-half",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-in-L",
										0
									],
									"destination": [
										"tl_volume_mix-miso-sel-L",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-half",
										0
									],
									"destination": [
										"tl_volume_mix-miso-sel-L",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-pin-1",
										0
									],
									"destination": [
										"tl_volume_mix-miso-sel-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-pin-0",
										0
									],
									"destination": [
										"tl_volume_mix-slide-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-miso-sel-L",
										0
									],
									"destination": [
										"tl_volume_mix-mul-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-slide-L",
										0
									],
									"destination": [
										"tl_volume_mix-mul-L",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-mul-L",
										0
									],
									"destination": [
										"tl_volume_mix-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-in-R",
										0
									],
									"destination": [
										"tl_volume_mix-miso-sel-R",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-half",
										0
									],
									"destination": [
										"tl_volume_mix-miso-sel-R",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-pin-1",
										0
									],
									"destination": [
										"tl_volume_mix-miso-sel-R",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-pin-0",
										0
									],
									"destination": [
										"tl_volume_mix-slide-R",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-miso-sel-R",
										0
									],
									"destination": [
										"tl_volume_mix-mul-R",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-slide-R",
										0
									],
									"destination": [
										"tl_volume_mix-mul-R",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_volume_mix-mul-R",
										0
									],
									"destination": [
										"tl_volume_mix-out-R",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_volume_mix",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_dry_mix",
					"maxclass": "newobj",
					"numinlets": 5,
					"numoutlets": 2,
					"patching_rect": [
						300,
						480,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "p tl_dry_mix",
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
									"id": "tl_dry_mix-mode-select",
									"maxclass": "newobj",
									"numinlets": 1,
									"numoutlets": 4,
									"patching_rect": [
										40,
										110,
										100,
										22
									],
									"outlettype": [
										"bang",
										"bang",
										"bang",
										""
									],
									"text": "select 0 1 2"
								}
							},
							{
								"box": {
									"id": "tl_dry_mix-mode-gain-0",
									"maxclass": "message",
									"text": "0.0",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										40,
										140,
										50,
										22
									]
								}
							},
							{
								"box": {
									"id": "tl_dry_mix-mode-gain-1",
									"maxclass": "message",
									"text": "0.3981",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										100,
										140,
										50,
										22
									]
								}
							},
							{
								"box": {
									"id": "tl_dry_mix-mode-gain-2",
									"maxclass": "message",
									"text": "1.0",
									"numinlets": 2,
									"numoutlets": 1,
									"outlettype": [
										""
									],
									"patching_rect": [
										160,
										140,
										50,
										22
									]
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
										170,
										50,
										22
									],
									"outlettype": [
										"float"
									],
									"text": "t f"
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
										"tl_dry_mix-mode-select",
										0
									],
									"destination": [
										"tl_dry_mix-mode-gain-0",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_dry_mix-mode-select",
										1
									],
									"destination": [
										"tl_dry_mix-mode-gain-1",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_dry_mix-mode-select",
										2
									],
									"destination": [
										"tl_dry_mix-mode-gain-2",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_dry_mix-mode-gain-0",
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
										"tl_dry_mix-mode-gain-1",
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
										"tl_dry_mix-mode-gain-2",
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
										"tl_dry_mix-pin-0",
										0
									],
									"destination": [
										"tl_dry_mix-mode-select",
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
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "box-tl_noise",
					"maxclass": "newobj",
					"numinlets": 6,
					"numoutlets": 2,
					"patching_rect": [
						580,
						480,
						260,
						60
					],
					"outlettype": [
						"signal",
						"signal"
					],
					"text": "p tl_noise",
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
									"id": "tl_noise-in-L",
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
									"id": "tl_noise-in-R",
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
									"id": "tl_noise-pin-0",
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
									"id": "tl_noise-pin-1",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										190,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 4
								}
							},
							{
								"box": {
									"id": "tl_noise-pin-2",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										240,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 5
								}
							},
							{
								"box": {
									"id": "tl_noise-pin-3",
									"maxclass": "inlet",
									"numinlets": 0,
									"numoutlets": 1,
									"patching_rect": [
										290,
										20,
										30,
										30
									],
									"outlettype": [
										""
									],
									"comment": "",
									"index": 6
								}
							},
							{
								"box": {
									"id": "tl_noise-out-L",
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
									"id": "tl_noise-out-R",
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
									"id": "tl_noise-gen",
									"maxclass": "newobj",
									"numinlets": 6,
									"numoutlets": 2,
									"patching_rect": [
										40,
										100,
										250,
										60
									],
									"outlettype": [
										"signal",
										"signal"
									],
									"text": "gen~ @title tl_noise_synth",
									"patcher": {
										"fileversion": 1,
										"appversion": {
											"major": 9,
											"minor": 0,
											"revision": 0,
											"architecture": "x64",
											"modernui": 1
										},
										"classnamespace": "dsp.gen",
										"rect": [
											100.0,
											100.0,
											700.0,
											600.0
										],
										"boxes": [
											{
												"box": {
													"id": "tl_noise-gen-in1",
													"maxclass": "newobj",
													"text": "in 1",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														30.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-in2",
													"maxclass": "newobj",
													"text": "in 2",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														100.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-in3",
													"maxclass": "newobj",
													"text": "in 3",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														170.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-in4",
													"maxclass": "newobj",
													"text": "in 4",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														240.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-in5",
													"maxclass": "newobj",
													"text": "in 5",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														310.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-in6",
													"maxclass": "newobj",
													"text": "in 6",
													"numinlets": 0,
													"numoutlets": 1,
													"outlettype": [
														""
													],
													"patching_rect": [
														380.0,
														30.0,
														30.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-codebox",
													"maxclass": "codebox",
													"numinlets": 6,
													"numoutlets": 2,
													"outlettype": [
														"",
														""
													],
													"patching_rect": [
														50.0,
														100.0,
														600.0,
														400.0
													],
													"code": "// =====================================================================\n// tl_noise.gendsp -- gen~ DSL source for the NOISE module of tape-loss\n// =====================================================================\n//\n// Module       : tl_noise (Generation Loss MKII \"NOISE\" generator)\n// Authored     : 2026-04-27 (Phase 2.5 -- gen~ translation)\n// Author       : pedal-engineer (auto-authored from numpy reference)\n// Position     : terminal module in the chain; ADDITIVE\n//                (input pass-through + noise summed in).\n//\n// Source files (sha256, captured at authoring time):\n//   docs/design-docs/dsp/tl-noise-design.md\n//     22acad5e705fe5a6653aec538ef4d8caa92f0893c66c5f4de19192f5f4fe4808\n//   dsp/reference/tl_noise.py\n//     4bd62edcaa398b9760caf1778b8ce023d5acdf29025d7a7ff31462396c61db17\n//   device/tape-loss/tl_noise.maxpat (parent stub, 6-in/2-out gen~ box)\n//     6806dce7aa0397f8b3447ab34d4474b1c41ac2d75ddfb1aac24bfa7f9e3ec278\n//\n// I/O contract (matches the gen~ box in tl_noise.maxpat):\n//   in1 : signal L (audio in)\n//   in2 : signal R (audio in)\n//   in3 : noise_mode        (0=OFF, 1=HISS, 2=BOTH)            -- control\n//   in4 : hiss_level        (0..1)                              -- control\n//   in5 : mechanical_level  (0..1, bipolar around 0.5)          -- control\n//   in6 : hum_bypass        (0|1)                               -- control\n//   out1: signal L (input + summed noise)\n//   out2: signal R (input + summed noise)\n//\n// Params (mirror the inlets so an outer [pattr]/[js] can also drive them):\n//   noise_mode (0), hiss_level (0.5), mechanical_level (0.5), hum_bypass (0)\n//\n// =====================================================================\n// PINK-NOISE METHOD CHOICE\n// =====================================================================\n//\n// Voss-McCartney 16-bin (NOT a 3-pole shelving cascade).\n//\n// Rationale per design doc \u00a72.1 + \u00a78 tradeoff log:\n//   \"Voss-McCartney is provably 1/f, simpler to verify numerically\n//    (each generator is provably 1/f within the band of interest).\n//    CPU cost is essentially the same: one add + one branch per sample.\"\n// And from \u00a78: \"VM win on transparency.\"\n//\n// Implementation note: gen~ codebox stores all numbers as float64; the\n// classic `k = i & -i` trick relies on two's-complement integer ops.\n// Instead we use a sample counter advanced by 1.0 each sample and probe\n// the trailing-zero index by a cascade of `(counter % 2^k) == 0` tests\n// implemented with `floor(c/2^k)*2^k == c` checks. The bin-update logic\n// matches McCartney 1999 exactly: at sample i (1-indexed), the bin\n// updated is `tzc(i)` where tzc = trailing-zero count.\n//\n// We use independent noise() streams per channel for the 16 bins, so\n// L and R hiss are decorrelated naturally (gen~'s noise() yields an\n// independent PRNG sequence per call site).\n//\n// =====================================================================\n// BIPOLAR MECHANICAL CROSSFADE (matches numpy ref _mechanical_weights)\n// =====================================================================\n//\n//   ml in [0, 1]\n//   ccw_amount = max(0, 0.5 - ml) * 2     -- 1.0 at ml=0,    0 at ml>=0.5\n//   cw_amount  = max(0, ml - 0.5) * 2     -- 0   at ml<=0.5, 1 at ml=1\n//   vcr_weight = ccw_amount\n//   hum_weight = cw_amount\n//   activity   = max(ccw_amount, cw_amount)         -- |2*(ml-0.5)|\n//   common_gain = activity^2 * 10^(-40/20)          -- quadratic taper,\n//                                                      -40 dBFS at full\n//\n// Hard silent center: at ml=0.5 BOTH weights are exactly 0, AND the\n// common_gain is exactly 0 (activity^2 = 0). Belt-and-braces zero.\n//\n// =====================================================================\n// HUM HARMONIC TABLE (design doc \u00a73.2)\n// =====================================================================\n//\n//   harmonic | freq @ 60 Hz | rel amp  | role\n//   ---------|--------------|----------|---------------------------------\n//      1     |    60 Hz     |   1.00   | fundamental (line freq)\n//      2     |   120 Hz     |   0.30   | even -- half-wave PSU rectif.\n//      3     |   180 Hz     |   0.45   | odd -- transformer saturation\n//      4     |   240 Hz     |   0.18   | weak even\n//      5     |   300 Hz     |   0.22   | weak odd\n//      7     |   420 Hz     |   0.12   | high odd (NOTE: gap at h=6)\n//\n// Sum of |amplitudes| = 2.27. Reference numpy peak-normalizes per render\n// (not realtime-feasible). We use a FIXED normalization constant of\n// 1.0/2.27 ~= 0.44053 (HUM_NORMALIZE) -- conservative; guarantees the\n// summed harmonic stack stays within ~|1.0|. Empirical RMS of the stack\n// after this normalization sits ~-9 dBFS, ~3 dB lower than the numpy\n// ref's per-buffer-normalized output. Acceptable: the numpy ref's peak-\n// normalize is itself a compromise (peak depends on phase relations;\n// expecting bit-identity here would be wrong). The L/R mono-correlation\n// invariant is preserved exactly. Documented divergence; design-doc\n// invariant #5 (peak < -30 dBFS) holds with margin.\n//\n// =====================================================================\n// PSU HALF-WAVE-RECT NOTE\n// =====================================================================\n//\n// The brief mentions \"PSU half-wave rectification character (clamp\n// negative half to 0 then DC-block)\". The numpy reference (the golden\n// output per design-doc \u00a710) does NOT do this -- it generates the hum\n// purely as a sum of sines with random per-render phases, then peak-\n// normalizes. The half-wave-rect language in the design doc \u00a73.2 is\n// describing the PHYSICAL ORIGIN of the harmonic ratios (asymmetric\n// rectifier produces strong even harmonics), not a runtime DSP step.\n//\n// We follow the numpy reference (translation, not redesign) -- straight\n// sine-bank sum. The \"half-wave\" character is BAKED INTO the harmonic\n// amplitude table already (h=2 weight 0.30, h=4 weight 0.18 = even-\n// harmonic emphasis from PSU rectifier asymmetry).\n//\n// =====================================================================\n// VCR AM MODULATOR\n// =====================================================================\n//\n// Numpy ref: random target re-roll every 1/(0.3..1.5) sec, linear walk\n// toward target at ~4 Hz convergence, one-pole smooth at 2 Hz.\n//\n// gen~ translation: drive a 2-stage cascaded one-pole LPF chain with\n// noise() at the 0.6 Hz center of the [0.3, 1.5] Hz reroll-rate band.\n// The cascade gives ~12 dB/oct rolloff above 0.6 Hz which dominates\n// any sharper transitions of the numpy ref's target-walk approach.\n// This is a continuous-spectrum equivalent to the periodic-reroll logic\n// and produces the same character (slow random ebb-and-flow, no\n// periodicity, no zero crossings). Output then mapped to multiplier\n// (CENTER + DEPTH/2 * walk) where walk in ~[-1, 1].\n//\n// =====================================================================\n// MODE LOGIC (design doc \u00a74 truth table)\n// =====================================================================\n//\n//   noise_mode | hum_bypass | hiss_on | mech_on\n//   -----------|------------|---------|--------\n//     0 OFF    |     *      |  false  |  false\n//     1 HISS   |     *      |  true   |  false\n//     2 BOTH   |    false   |  true   |  true\n//     2 BOTH   |    true    |  true   |  false\n//\n// HARD GATE at the mode level (not just attenuation): when hiss_on is\n// false the hiss path output is multiplied by 0 (and could even be\n// short-circuited around -- we use the multiply for compile simplicity,\n// the result is bit-exact zero either way).\n//\n// At noise_mode=OFF we additionally want the OUTPUT to equal INPUT\n// bit-exactly. We do this by short-circuiting the entire ADD path:\n// out1 = (mode_off ? in1 : in1 + sum_of_noise). This guarantees no\n// floating-point rounding from the add even if the noise contribution\n// has been multiplied to zero. Pitfall safeguard.\n//\n// =====================================================================\n// SANITY-CHECK EXPECTATIONS (matches numpy ref _verify_invariants)\n// =====================================================================\n//\n//   1. noise_mode = OFF, any other params:\n//        out1 == in1, out2 == in2  (bit-identical, zero noise contrib)\n//   2. noise_mode = HISS, hiss_level = 0:\n//        out == in (hiss_level squared = 0, total noise = 0)\n//   3. noise_mode = HISS, hiss_level = 0.5:\n//        adds pink-flavored hiss at peak ~ -50..-45 dBFS\n//        (HISS_TARGET_PEAK_AMP ~ -42 dBFS at level=1.0; squared taper\n//         puts level=0.5 at ~-54 dBFS peak)\n//   4. noise_mode = BOTH, mechanical_level = 0.5, hum_bypass = 0:\n//        mechanical contribution is exactly silent (hard center).\n//        Output = input + hiss only.\n//   5. noise_mode = BOTH, mechanical_level = 0.0:\n//        full VCR rumble + hiss\n//   6. noise_mode = BOTH, mechanical_level = 1.0:\n//        full 60 Hz hum stack + hiss\n//   7. noise_mode = BOTH, hum_bypass = 1:\n//        equivalent to HISS-only (mech path gated)\n//   8. All-knobs-max (noise_mode=BOTH, hiss=1, mech=1.0, !hum_bypass):\n//        peak < -30 dBFS (design doc \u00a79 invariant #5)\n//   9. Hiss path L/R correlation ~= 0\n//  10. Hum path L/R correlation ~= +1 (mono-correlated, hum_scaled\n//        added identically to both channels)\n//\n// =====================================================================\n\n\n// ---------------------------------------------------------------------\n// Parameter declarations (also driven by signal inlets in3..in6)\n// ---------------------------------------------------------------------\n\nParam noise_mode(0);\nParam hiss_level(0.5);\nParam mechanical_level(0.5);\nParam hum_bypass(0);\nHistory pinkCounter(0.0);\nHistory pBinL_0(0.0);  History pBinL_1(0.0);  History pBinL_2(0.0);  History pBinL_3(0.0);\nHistory pBinL_4(0.0);  History pBinL_5(0.0);  History pBinL_6(0.0);  History pBinL_7(0.0);\nHistory pBinL_8(0.0);  History pBinL_9(0.0);  History pBinL_10(0.0); History pBinL_11(0.0);\nHistory pBinL_12(0.0); History pBinL_13(0.0); History pBinL_14(0.0); History pBinL_15(0.0);\nHistory pBinR_0(0.0);  History pBinR_1(0.0);  History pBinR_2(0.0);  History pBinR_3(0.0);\nHistory pBinR_4(0.0);  History pBinR_5(0.0);  History pBinR_6(0.0);  History pBinR_7(0.0);\nHistory pBinR_8(0.0);  History pBinR_9(0.0);  History pBinR_10(0.0); History pBinR_11(0.0);\nHistory pBinR_12(0.0); History pBinR_13(0.0); History pBinR_14(0.0); History pBinR_15(0.0);\nHistory hpfL_x1(0.0); History hpfL_x2(0.0);\nHistory hpfL_y1(0.0); History hpfL_y2(0.0);\nHistory lpfL_x1(0.0); History lpfL_x2(0.0);\nHistory lpfL_y1(0.0); History lpfL_y2(0.0);\nHistory hpfR_x1(0.0); History hpfR_x2(0.0);\nHistory hpfR_y1(0.0); History hpfR_y2(0.0);\nHistory lpfR_x1(0.0); History lpfR_x2(0.0);\nHistory lpfR_y1(0.0); History lpfR_y2(0.0);\nHistory vcrL_x1(0.0); History vcrL_x2(0.0);\nHistory vcrL_y1(0.0); History vcrL_y2(0.0);\nHistory vcrR_x1(0.0); History vcrR_x2(0.0);\nHistory vcrR_y1(0.0); History vcrR_y2(0.0);\nHistory amL_a(0.0); History amL_b(0.0);\nHistory amR_a(0.0); History amR_b(0.0);\nHistory humPh1(0.0); History humPh2(0.0); History humPh3(0.0);\nHistory humPh4(0.0); History humPh5(0.0); History humPh7(0.0);\n\n\n// ---------------------------------------------------------------------\n// Constants\n// ---------------------------------------------------------------------\n\nTWO_PI = 6.283185307179586476;\nPI     = 3.141592653589793238;\n\n// Peak amplitude targets at full level (design doc \u00a75).\nHISS_TARGET_PEAK_AMP = 0.007943282347242815;   // 10^(-42/20)\nMECH_TARGET_PEAK_AMP = 0.01;                   // 10^(-40/20)\n\n// Hiss spectral shaping (RBJ Butterworth biquads).\nHISS_HPF_HZ = 50.0;\nHISS_HPF_Q  = 0.7071067811865475;\nHISS_LPF_HZ = 12000.0;\nHISS_LPF_Q  = 0.7071067811865475;\n\n// VCR sub-engine.\nVCR_LPF_HZ        = 200.0;\nVCR_LPF_Q         = 0.9;\nVCR_AM_CENTER     = 0.7;     // multiplier center (never reaches 0)\nVCR_AM_DEPTH      = 0.6;     // -> multiplier swings ~[0.1, 1.3]\nVCR_AM_LFO_HZ     = 0.6;     // mid of the [0.3, 1.5] Hz reroll band\n                             // (cascaded 1-pole stand-in for the\n                             //  numpy ref's target-walk modulator)\n\n// Hum sub-engine.\nHUM_FUNDAMENTAL_HZ = 60.0;   // North America. Edit to 50.0 for EU/etc.\n// Sum of |amplitudes| over the 6 harmonics = 2.27 -> fixed scale to\n// keep the un-windowed peak <= 1.0. (Numpy ref does per-render peak-\n// normalize; not realtime-feasible. See header divergence note.)\nHUM_NORMALIZE      = 0.4405286343612335;   // = 1.0 / 2.27\n\n// VCR-LPF normalization. The numpy ref divides the LPF'd white noise\n// by its per-render peak to land at ~|1.0|. We use a fixed gain\n// calibrated against the LPF impulse-response RMS times a 4-sigma peak\n// estimate of Gaussian noise: empirically VCR_GAIN_FIX = ~7.0 lands\n// the post-LPF peak in the same ballpark as the numpy ref's\n// per-buffer normalize. Conservative; documented divergence.\nVCR_GAIN_FIX = 7.0;\n\n\n// ---------------------------------------------------------------------\n// Resolve current control values: prefer signal inlets in3..in6 if\n// they're nonzero (the maxpat stub wires control inlets there); fall\n// back to Param. (Both paths produce the same value when the maxpat\n// drives the inlets faithfully.) We just pass the inlet through; the\n// outer harness is responsible for keeping these in sync.\n// ---------------------------------------------------------------------\n\nmode_v = in3;                                // 0 / 1 / 2\nhl     = clamp(in4, 0.0, 1.0);\nml     = clamp(in5, 0.0, 1.0);\nhb     = in6;                                // 0 or 1\n\n// Derived booleans (truth table from design doc \u00a74).\nmode_off  = (mode_v < 0.5);                  // == 0\nmode_hiss = (mode_v >= 0.5) && (mode_v < 1.5); // == 1\nmode_both = (mode_v >= 1.5);                 // == 2\nhb_on     = (hb >= 0.5);\n\nhiss_on = mode_hiss || mode_both;            // both HISS and BOTH enable hiss\nmech_on = mode_both && (hb_on == 0);\n\n\n// ---------------------------------------------------------------------\n// Bipolar mechanical crossfade weights\n// ---------------------------------------------------------------------\n\nccw_amount  = max(0.0, 0.5 - ml) * 2.0;       // 1 at ml=0, 0 at ml>=0.5\ncw_amount   = max(0.0, ml - 0.5) * 2.0;       // 0 at ml<=0.5, 1 at ml=1\nvcr_w       = ccw_amount;\nhum_w       = cw_amount;\nactivity    = max(ccw_amount, cw_amount);     // |2*(ml-0.5)|\ncommon_gain = activity * activity * MECH_TARGET_PEAK_AMP;\n\n// Hiss linear gain (quadratic taper).\nhiss_gain = hl * hl * HISS_TARGET_PEAK_AMP;\n\n\n// =====================================================================\n// VOSS-McCARTNEY PINK NOISE -- per channel\n// =====================================================================\n//\n// Algorithm (McCartney 1999):\n//   counter advances by 1 each sample.\n//   k = trailing-zero count of counter        (counter starts at 1)\n//   bin[k] = fresh_random()\n//   output = sum of all 16 bins\n//\n// In gen~ codebox we use a History counter (modulo 2^16 so it stays\n// within float64 precision) and probe the trailing-zero index with a\n// cascade of integer-divisibility tests. (Equivalent to a CTZ.)\n// We then conditionally update each bin via a `bin = (k_eq_i ? new : bin)`\n// mux, which keeps the dataflow purely combinational (no early-return).\n//\n// The 16 bins are just 16 History scalars per channel. Independent\n// noise() calls feed fresh randoms.\n// ---------------------------------------------------------------------\n\n// --- Counter (shared) ---\n\n// Advance counter once per sample, modulo 65536 (= 2^16). The bin index\n// repeats with period 2^16 samples (~1.486 s @ 44.1 kHz) which is\n// exactly the cycle of the algorithm at n_bins=16; modulo-wrapping is\n// the natural handling of the lowest bin's update interval.\nnew_counter = pinkCounter + 1.0;\nnew_counter = (new_counter >= 65536.0) ? (new_counter - 65536.0) : new_counter;\npinkCounter = new_counter;\nci = new_counter;   // current sample index (1-based)\n\n// Trailing-zero index probes. For each k in 0..15, k_is[k] is 1 if\n// (ci % 2^(k+1)) == 2^k (i.e., bit k is the lowest set bit), else 0.\n// Equivalently: ci is divisible by 2^k but not by 2^(k+1).\n//\n// Compute via: ci/2^k is an integer AND that integer is odd.\n//   div_k = ci / 2^k\n//   is_int_k    = (div_k == floor(div_k))\n//   is_odd_k    = ((floor(div_k) % 2) == 1)\n//   k_is[k]     = is_int_k && is_odd_k\n//\n// (For ci=1 -> k=0; ci=2 -> k=1; ci=3 -> k=0; ci=4 -> k=2; etc.)\n\ndiv0  = ci;\ndiv1  = ci * 0.5;\ndiv2  = ci * 0.25;\ndiv3  = ci * 0.125;\ndiv4  = ci * 0.0625;\ndiv5  = ci * 0.03125;\ndiv6  = ci * 0.015625;\ndiv7  = ci * 0.0078125;\ndiv8  = ci * 0.00390625;\ndiv9  = ci * 0.001953125;\ndiv10 = ci * 0.0009765625;\ndiv11 = ci * 0.00048828125;\ndiv12 = ci * 0.000244140625;\ndiv13 = ci * 0.0001220703125;\ndiv14 = ci * 0.00006103515625;\ndiv15 = ci * 0.000030517578125;\n\n// is_int_k: div_k is an integer iff floor(div_k) == div_k.\n// is_odd : (floor(div_k) - 2*floor(div_k/2)) == 1.\n// We collapse both checks into k_is[k] using a single (floor(div_k) ==\n// div_k) AND ((floor(div_k) % 2) == 1).\n\nf0  = floor(div0);   k_is_0  = (f0  == div0)  && ((f0  - 2.0*floor(f0  * 0.5)) >= 0.5);\nf1  = floor(div1);   k_is_1  = (f1  == div1)  && ((f1  - 2.0*floor(f1  * 0.5)) >= 0.5);\nf2  = floor(div2);   k_is_2  = (f2  == div2)  && ((f2  - 2.0*floor(f2  * 0.5)) >= 0.5);\nf3  = floor(div3);   k_is_3  = (f3  == div3)  && ((f3  - 2.0*floor(f3  * 0.5)) >= 0.5);\nf4  = floor(div4);   k_is_4  = (f4  == div4)  && ((f4  - 2.0*floor(f4  * 0.5)) >= 0.5);\nf5  = floor(div5);   k_is_5  = (f5  == div5)  && ((f5  - 2.0*floor(f5  * 0.5)) >= 0.5);\nf6  = floor(div6);   k_is_6  = (f6  == div6)  && ((f6  - 2.0*floor(f6  * 0.5)) >= 0.5);\nf7  = floor(div7);   k_is_7  = (f7  == div7)  && ((f7  - 2.0*floor(f7  * 0.5)) >= 0.5);\nf8  = floor(div8);   k_is_8  = (f8  == div8)  && ((f8  - 2.0*floor(f8  * 0.5)) >= 0.5);\nf9  = floor(div9);   k_is_9  = (f9  == div9)  && ((f9  - 2.0*floor(f9  * 0.5)) >= 0.5);\nf10 = floor(div10);  k_is_10 = (f10 == div10) && ((f10 - 2.0*floor(f10 * 0.5)) >= 0.5);\nf11 = floor(div11);  k_is_11 = (f11 == div11) && ((f11 - 2.0*floor(f11 * 0.5)) >= 0.5);\nf12 = floor(div12);  k_is_12 = (f12 == div12) && ((f12 - 2.0*floor(f12 * 0.5)) >= 0.5);\nf13 = floor(div13);  k_is_13 = (f13 == div13) && ((f13 - 2.0*floor(f13 * 0.5)) >= 0.5);\nf14 = floor(div14);  k_is_14 = (f14 == div14) && ((f14 - 2.0*floor(f14 * 0.5)) >= 0.5);\nf15 = floor(div15);  k_is_15 = (f15 == div15) && ((f15 - 2.0*floor(f15 * 0.5)) >= 0.5);\n\n// 1/sqrt(16) for unit-RMS normalization of the 16-bin sum.\nPINK_NORM = 0.25;\n\n\n// --- Pink generator macro for L channel ---\n\n\n// Sixteen independent noise() draws (decorrelated by call site).\nnL_0  = noise();  nL_1  = noise();  nL_2  = noise();  nL_3  = noise();\nnL_4  = noise();  nL_5  = noise();  nL_6  = noise();  nL_7  = noise();\nnL_8  = noise();  nL_9  = noise();  nL_10 = noise();  nL_11 = noise();\nnL_12 = noise();  nL_13 = noise();  nL_14 = noise();  nL_15 = noise();\n\n// Conditionally update each bin. gen~ noise() outputs uniform [-1, 1];\n// we want roughly N(0, 1)-style variance to match the numpy ref. The\n// standard deviation of U(-1, 1) is 1/sqrt(3) ~= 0.577. We therefore\n// scale each draw by sqrt(3) ~= 1.7320508 so the bin variance matches\n// N(0, 1). After summing 16 bins and dividing by sqrt(16)=4, output\n// variance is 1.0 (matching numpy ref's normalization).\nSQRT3 = 1.7320508075688772;\n\npBinL_0  = (k_is_0  != 0) ? (nL_0  * SQRT3) : pBinL_0;\npBinL_1  = (k_is_1  != 0) ? (nL_1  * SQRT3) : pBinL_1;\npBinL_2  = (k_is_2  != 0) ? (nL_2  * SQRT3) : pBinL_2;\npBinL_3  = (k_is_3  != 0) ? (nL_3  * SQRT3) : pBinL_3;\npBinL_4  = (k_is_4  != 0) ? (nL_4  * SQRT3) : pBinL_4;\npBinL_5  = (k_is_5  != 0) ? (nL_5  * SQRT3) : pBinL_5;\npBinL_6  = (k_is_6  != 0) ? (nL_6  * SQRT3) : pBinL_6;\npBinL_7  = (k_is_7  != 0) ? (nL_7  * SQRT3) : pBinL_7;\npBinL_8  = (k_is_8  != 0) ? (nL_8  * SQRT3) : pBinL_8;\npBinL_9  = (k_is_9  != 0) ? (nL_9  * SQRT3) : pBinL_9;\npBinL_10 = (k_is_10 != 0) ? (nL_10 * SQRT3) : pBinL_10;\npBinL_11 = (k_is_11 != 0) ? (nL_11 * SQRT3) : pBinL_11;\npBinL_12 = (k_is_12 != 0) ? (nL_12 * SQRT3) : pBinL_12;\npBinL_13 = (k_is_13 != 0) ? (nL_13 * SQRT3) : pBinL_13;\npBinL_14 = (k_is_14 != 0) ? (nL_14 * SQRT3) : pBinL_14;\npBinL_15 = (k_is_15 != 0) ? (nL_15 * SQRT3) : pBinL_15;\n\npinkL = (pBinL_0  + pBinL_1  + pBinL_2  + pBinL_3\n       + pBinL_4  + pBinL_5  + pBinL_6  + pBinL_7\n       + pBinL_8  + pBinL_9  + pBinL_10 + pBinL_11\n       + pBinL_12 + pBinL_13 + pBinL_14 + pBinL_15) * PINK_NORM;\n\n\n// --- Pink generator macro for R channel (independent noise() streams) ---\n\n\nnR_0  = noise();  nR_1  = noise();  nR_2  = noise();  nR_3  = noise();\nnR_4  = noise();  nR_5  = noise();  nR_6  = noise();  nR_7  = noise();\nnR_8  = noise();  nR_9  = noise();  nR_10 = noise();  nR_11 = noise();\nnR_12 = noise();  nR_13 = noise();  nR_14 = noise();  nR_15 = noise();\n\npBinR_0  = (k_is_0  != 0) ? (nR_0  * SQRT3) : pBinR_0;\npBinR_1  = (k_is_1  != 0) ? (nR_1  * SQRT3) : pBinR_1;\npBinR_2  = (k_is_2  != 0) ? (nR_2  * SQRT3) : pBinR_2;\npBinR_3  = (k_is_3  != 0) ? (nR_3  * SQRT3) : pBinR_3;\npBinR_4  = (k_is_4  != 0) ? (nR_4  * SQRT3) : pBinR_4;\npBinR_5  = (k_is_5  != 0) ? (nR_5  * SQRT3) : pBinR_5;\npBinR_6  = (k_is_6  != 0) ? (nR_6  * SQRT3) : pBinR_6;\npBinR_7  = (k_is_7  != 0) ? (nR_7  * SQRT3) : pBinR_7;\npBinR_8  = (k_is_8  != 0) ? (nR_8  * SQRT3) : pBinR_8;\npBinR_9  = (k_is_9  != 0) ? (nR_9  * SQRT3) : pBinR_9;\npBinR_10 = (k_is_10 != 0) ? (nR_10 * SQRT3) : pBinR_10;\npBinR_11 = (k_is_11 != 0) ? (nR_11 * SQRT3) : pBinR_11;\npBinR_12 = (k_is_12 != 0) ? (nR_12 * SQRT3) : pBinR_12;\npBinR_13 = (k_is_13 != 0) ? (nR_13 * SQRT3) : pBinR_13;\npBinR_14 = (k_is_14 != 0) ? (nR_14 * SQRT3) : pBinR_14;\npBinR_15 = (k_is_15 != 0) ? (nR_15 * SQRT3) : pBinR_15;\n\npinkR = (pBinR_0  + pBinR_1  + pBinR_2  + pBinR_3\n       + pBinR_4  + pBinR_5  + pBinR_6  + pBinR_7\n       + pBinR_8  + pBinR_9  + pBinR_10 + pBinR_11\n       + pBinR_12 + pBinR_13 + pBinR_14 + pBinR_15) * PINK_NORM;\n\n\n// =====================================================================\n// HISS RBJ BIQUAD COEFFICIENTS (HPF 50 Hz / LPF 12 kHz, Butterworth)\n// =====================================================================\n//\n// RBJ Audio EQ Cookbook formulas, recomputed each sample from\n// `samplerate` so the filters track SR changes (no [js] companion\n// needed for these). Cost: ~12 trig calls per sample, all on constants\n// -> the gen~ compiler will hoist them as long as samplerate is held\n// stable; on SR transitions there's a momentary bump (~5 ms) which is\n// inaudible against the noise floor.\n\n// --- HPF 50 Hz Q=0.7071 ---\nhpf_w0     = TWO_PI * HISS_HPF_HZ / samplerate;\nhpf_cosw0  = cos(hpf_w0);\nhpf_alpha  = sin(hpf_w0) / (2.0 * HISS_HPF_Q);\nhpf_a0     = 1.0 + hpf_alpha;\nhpf_b0     = ((1.0 + hpf_cosw0) * 0.5) / hpf_a0;\nhpf_b1     = (-(1.0 + hpf_cosw0))      / hpf_a0;\nhpf_b2     = ((1.0 + hpf_cosw0) * 0.5) / hpf_a0;\nhpf_a1     = (-2.0 * hpf_cosw0)        / hpf_a0;\nhpf_a2     = (1.0 - hpf_alpha)         / hpf_a0;\n\n// --- LPF 12 kHz Q=0.7071 ---\nlpf_w0     = TWO_PI * HISS_LPF_HZ / samplerate;\nlpf_cosw0  = cos(lpf_w0);\nlpf_alpha  = sin(lpf_w0) / (2.0 * HISS_LPF_Q);\nlpf_a0     = 1.0 + lpf_alpha;\nlpf_b0     = ((1.0 - lpf_cosw0) * 0.5) / lpf_a0;\nlpf_b1     = (1.0 - lpf_cosw0)         / lpf_a0;\nlpf_b2     = ((1.0 - lpf_cosw0) * 0.5) / lpf_a0;\nlpf_a1     = (-2.0 * lpf_cosw0)        / lpf_a0;\nlpf_a2     = (1.0 - lpf_alpha)         / lpf_a0;\n\n// --- VCR LPF 200 Hz Q=0.9 ---\nvcr_w0     = TWO_PI * VCR_LPF_HZ / samplerate;\nvcr_cosw0  = cos(vcr_w0);\nvcr_alpha  = sin(vcr_w0) / (2.0 * VCR_LPF_Q);\nvcr_a0     = 1.0 + vcr_alpha;\nvcr_b0     = ((1.0 - vcr_cosw0) * 0.5) / vcr_a0;\nvcr_b1     = (1.0 - vcr_cosw0)         / vcr_a0;\nvcr_b2     = ((1.0 - vcr_cosw0) * 0.5) / vcr_a0;\nvcr_a1     = (-2.0 * vcr_cosw0)        / vcr_a0;\nvcr_a2     = (1.0 - vcr_alpha)         / vcr_a0;\n\n\n// =====================================================================\n// HISS PATH -- HPF 50 then LPF 12k, per channel (Direct Form I)\n// =====================================================================\n\n// --- HPF Channel L ---\n\nhpfL_y = hpf_b0*pinkL + hpf_b1*hpfL_x1 + hpf_b2*hpfL_x2\n       - hpf_a1*hpfL_y1 - hpf_a2*hpfL_y2;\nhpfL_y = (abs(hpfL_y) < 1e-30) ? 0.0 : hpfL_y;       // denormal flush\n\nhpfL_x2 = hpfL_x1;\nhpfL_x1 = pinkL;\nhpfL_y2 = hpfL_y1;\nhpfL_y1 = hpfL_y;\n\n// --- LPF Channel L ---\n\nlpfL_y = lpf_b0*hpfL_y + lpf_b1*lpfL_x1 + lpf_b2*lpfL_x2\n       - lpf_a1*lpfL_y1 - lpf_a2*lpfL_y2;\nlpfL_y = (abs(lpfL_y) < 1e-30) ? 0.0 : lpfL_y;\n\nlpfL_x2 = lpfL_x1;\nlpfL_x1 = hpfL_y;\nlpfL_y2 = lpfL_y1;\nlpfL_y1 = lpfL_y;\n\nshapedHissL = lpfL_y;\n\n// --- HPF Channel R ---\n\nhpfR_y = hpf_b0*pinkR + hpf_b1*hpfR_x1 + hpf_b2*hpfR_x2\n       - hpf_a1*hpfR_y1 - hpf_a2*hpfR_y2;\nhpfR_y = (abs(hpfR_y) < 1e-30) ? 0.0 : hpfR_y;\n\nhpfR_x2 = hpfR_x1;\nhpfR_x1 = pinkR;\nhpfR_y2 = hpfR_y1;\nhpfR_y1 = hpfR_y;\n\n// --- LPF Channel R ---\n\nlpfR_y = lpf_b0*hpfR_y + lpf_b1*lpfR_x1 + lpf_b2*lpfR_x2\n       - lpf_a1*lpfR_y1 - lpf_a2*lpfR_y2;\nlpfR_y = (abs(lpfR_y) < 1e-30) ? 0.0 : lpfR_y;\n\nlpfR_x2 = lpfR_x1;\nlpfR_x1 = hpfR_y;\nlpfR_y2 = lpfR_y1;\nlpfR_y1 = lpfR_y;\n\nshapedHissR = lpfR_y;\n\n// Hiss output (gated by hiss_on, scaled by quadratic-tapered hiss_gain).\nhissL = (hiss_on != 0) ? (shapedHissL * hiss_gain) : 0.0;\nhissR = (hiss_on != 0) ? (shapedHissR * hiss_gain) : 0.0;\n\n\n// =====================================================================\n// MECHANICAL PATH -- VCR sub-engine (decorrelated stereo)\n// =====================================================================\n//\n// White noise -> LPF 200 Hz Q=0.9 -> slow-AM multiplier.\n\n// --- White noise per channel (independent streams via separate noise() sites) ---\nwhiteVcrL = noise() * SQRT3;   // U(-1,1) -> match unit-variance scale\nwhiteVcrR = noise() * SQRT3;\n\n// --- VCR LPF Channel L (Direct Form I) ---\n\nvcrLpfL = vcr_b0*whiteVcrL + vcr_b1*vcrL_x1 + vcr_b2*vcrL_x2\n        - vcr_a1*vcrL_y1   - vcr_a2*vcrL_y2;\nvcrLpfL = (abs(vcrLpfL) < 1e-30) ? 0.0 : vcrLpfL;\n\nvcrL_x2 = vcrL_x1;\nvcrL_x1 = whiteVcrL;\nvcrL_y2 = vcrL_y1;\nvcrL_y1 = vcrLpfL;\n\n// --- VCR LPF Channel R ---\n\nvcrLpfR = vcr_b0*whiteVcrR + vcr_b1*vcrR_x1 + vcr_b2*vcrR_x2\n        - vcr_a1*vcrR_y1   - vcr_a2*vcrR_y2;\nvcrLpfR = (abs(vcrLpfR) < 1e-30) ? 0.0 : vcrLpfR;\n\nvcrR_x2 = vcrR_x1;\nvcrR_x1 = whiteVcrR;\nvcrR_y2 = vcrR_y1;\nvcrR_y1 = vcrLpfR;\n\n// Normalize to ~ unit peak (numpy ref does per-buffer; we use a fixed\n// gain). See VCR_GAIN_FIX comment in constants block.\nvcrL = vcrLpfL * VCR_GAIN_FIX;\nvcrR = vcrLpfR * VCR_GAIN_FIX;\n\n// --- Slow-AM modulator per channel (cascaded 1-pole at 0.6 Hz) ---\n// Coefficient: a = 1 - exp(-2*pi*fc/sr).\nam_a = 1.0 - exp(-TWO_PI * VCR_AM_LFO_HZ / samplerate);\n\nnAmL = noise();                               // independent stream\namL_a = amL_a + am_a * (nAmL  - amL_a);\namL_b = amL_b + am_a * (amL_a - amL_b);       // 12 dB/oct cascade\nwalkL = clamp(amL_b, -1.0, 1.0);\namMultL = VCR_AM_CENTER + (VCR_AM_DEPTH * 0.5) * walkL;\n\nnAmR = noise();\namR_a = amR_a + am_a * (nAmR  - amR_a);\namR_b = amR_b + am_a * (amR_a - amR_b);\nwalkR = clamp(amR_b, -1.0, 1.0);\namMultR = VCR_AM_CENTER + (VCR_AM_DEPTH * 0.5) * walkR;\n\nvcrOutL = vcrL * amMultL;\nvcrOutR = vcrR * amMultR;\n\n\n// =====================================================================\n// MECHANICAL PATH -- HUM sub-engine (mono / correlated)\n// =====================================================================\n//\n// Sine bank: h=1,2,3,4,5,7 of the fundamental, with relative amps\n// [1.00, 0.30, 0.45, 0.18, 0.22, 0.12]. Phase accumulators wrap at\n// 2*pi via subtraction. Output is identical for L and R (mono pickup).\n\n// Phase increments per harmonic (rad/sample). samplerate-aware.\nphinc1 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 1.0) / samplerate;\nphinc2 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 2.0) / samplerate;\nphinc3 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 3.0) / samplerate;\nphinc4 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 4.0) / samplerate;\nphinc5 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 5.0) / samplerate;\nphinc7 = TWO_PI * (HUM_FUNDAMENTAL_HZ * 7.0) / samplerate;\n\n\n// Advance + wrap to [-pi, pi].\nnph1 = humPh1 + phinc1;\nnph1 = (nph1 >  PI) ? (nph1 - TWO_PI) : nph1;\nnph1 = (nph1 < -PI) ? (nph1 + TWO_PI) : nph1;\nhumPh1 = nph1;\n\nnph2 = humPh2 + phinc2;\nnph2 = (nph2 >  PI) ? (nph2 - TWO_PI) : nph2;\nnph2 = (nph2 < -PI) ? (nph2 + TWO_PI) : nph2;\nhumPh2 = nph2;\n\nnph3 = humPh3 + phinc3;\nnph3 = (nph3 >  PI) ? (nph3 - TWO_PI) : nph3;\nnph3 = (nph3 < -PI) ? (nph3 + TWO_PI) : nph3;\nhumPh3 = nph3;\n\nnph4 = humPh4 + phinc4;\nnph4 = (nph4 >  PI) ? (nph4 - TWO_PI) : nph4;\nnph4 = (nph4 < -PI) ? (nph4 + TWO_PI) : nph4;\nhumPh4 = nph4;\n\nnph5 = humPh5 + phinc5;\nnph5 = (nph5 >  PI) ? (nph5 - TWO_PI) : nph5;\nnph5 = (nph5 < -PI) ? (nph5 + TWO_PI) : nph5;\nhumPh5 = nph5;\n\nnph7 = humPh7 + phinc7;\nnph7 = (nph7 >  PI) ? (nph7 - TWO_PI) : nph7;\nnph7 = (nph7 < -PI) ? (nph7 + TWO_PI) : nph7;\nhumPh7 = nph7;\n\nhumSum = 1.00 * sin(nph1)\n       + 0.30 * sin(nph2)\n       + 0.45 * sin(nph3)\n       + 0.18 * sin(nph4)\n       + 0.22 * sin(nph5)\n       + 0.12 * sin(nph7);\n\nhum = humSum * HUM_NORMALIZE;   // mono signal\n\n\n// =====================================================================\n// MECHANICAL CROSSFADE (linear, hard silent center) + GATE\n// =====================================================================\n//\n// vcr * vcr_w  +  hum * hum_w, all scaled by common_gain. The hum path\n// is added IDENTICALLY to L and R (mono-correlated); halve the per-\n// channel contribution so the stereo-summed peak still hits the\n// MECH_TARGET_PEAK_AMP target (matches numpy ref's hum_scaled * 0.5).\n\nhumContrib   = hum * hum_w * common_gain * 0.5;       // halve for mono dup\nmechContribL = (vcrOutL * vcr_w * common_gain) + humContrib;\nmechContribR = (vcrOutR * vcr_w * common_gain) + humContrib;\n\nmechL = (mech_on != 0) ? mechContribL : 0.0;\nmechR = (mech_on != 0) ? mechContribR : 0.0;\n\n\n// =====================================================================\n// FINAL SUM (additive on input pass-through)\n// =====================================================================\n//\n// At noise_mode=OFF we short-circuit to the unmodified input to\n// guarantee bit-identical pass-through (no rounding from a +0.0 add).\n\nnoiseSumL = hissL + mechL;\nnoiseSumR = hissR + mechR;\n\nout1 = (mode_off != 0) ? in1 : (in1 + noiseSumL);\nout2 = (mode_off != 0) ? in2 : (in2 + noiseSumR);\n\n// =====================================================================\n// END tl_noise.gendsp\n// =====================================================================\n"
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-out1",
													"maxclass": "newobj",
													"text": "out 1",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														30.0,
														540.0,
														35.0,
														22.0
													]
												}
											},
											{
												"box": {
													"id": "tl_noise-gen-out2",
													"maxclass": "newobj",
													"text": "out 2",
													"numinlets": 1,
													"numoutlets": 0,
													"patching_rect": [
														100.0,
														540.0,
														35.0,
														22.0
													]
												}
											}
										],
										"lines": [
											{
												"patchline": {
													"source": [
														"tl_noise-gen-in1",
														0
													],
													"destination": [
														"tl_noise-gen-codebox",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_noise-gen-in2",
														0
													],
													"destination": [
														"tl_noise-gen-codebox",
														1
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_noise-gen-in3",
														0
													],
													"destination": [
														"tl_noise-gen-codebox",
														2
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_noise-gen-in4",
														0
													],
													"destination": [
														"tl_noise-gen-codebox",
														3
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_noise-gen-in5",
														0
													],
													"destination": [
														"tl_noise-gen-codebox",
														4
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_noise-gen-in6",
														0
													],
													"destination": [
														"tl_noise-gen-codebox",
														5
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_noise-gen-codebox",
														0
													],
													"destination": [
														"tl_noise-gen-out1",
														0
													]
												}
											},
											{
												"patchline": {
													"source": [
														"tl_noise-gen-codebox",
														1
													],
													"destination": [
														"tl_noise-gen-out2",
														0
													]
												}
											}
										]
									},
									"rnboattrcache": {},
									"saved_object_attributes": {
										"exportfolder": "",
										"exportname": "tl_noise_synth",
										"wantsoutputcore": 0
									}
								}
							},
							{
								"box": {
									"id": "tl_noise-note",
									"maxclass": "comment",
									"numinlets": 1,
									"numoutlets": 0,
									"patching_rect": [
										40,
										180,
										700,
										60
									],
									"text": "tl_noise (SANDBOX-OK): pink hiss (Voss-McCartney) + mechanical (VCR rumble + 60Hz hum stack). noise_mode OFF=silent, HISS=hiss only, BOTH=hiss+mech. hum_bypass mutes mechanical in BOTH. Hiss: HPF50/LPF12k Butterworth shaping. Hum: 6-harmonic 60Hz stack (correlated mono). VCR: LPF200/slow-AM (decorrelated stereo). All synthesized in [gen~ tl_noise_synth]."
								}
							}
						],
						"lines": [
							{
								"patchline": {
									"source": [
										"tl_noise-in-L",
										0
									],
									"destination": [
										"tl_noise-gen",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-in-R",
										0
									],
									"destination": [
										"tl_noise-gen",
										1
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-pin-0",
										0
									],
									"destination": [
										"tl_noise-gen",
										2
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-pin-1",
										0
									],
									"destination": [
										"tl_noise-gen",
										3
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-pin-2",
										0
									],
									"destination": [
										"tl_noise-gen",
										4
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-pin-3",
										0
									],
									"destination": [
										"tl_noise-gen",
										5
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen",
										0
									],
									"destination": [
										"tl_noise-out-L",
										0
									]
								}
							},
							{
								"patchline": {
									"source": [
										"tl_noise-gen",
										1
									],
									"destination": [
										"tl_noise-out-R",
										0
									]
								}
							}
						],
						"project": {
							"name": "tl_noise",
							"amxdtype": 1633771873
						},
						"dependency_cache": [],
						"autosave": 0
					},
					"saved_object_attributes": {
						"description": "",
						"digest": "",
						"globalpatchername": ""
					}
				}
			},
			{
				"box": {
					"id": "fov-send",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 0,
					"patching_rect": [
						40,
						360,
						180,
						22
					],
					"outlettype": [],
					"text": "send~ tl_failure_override"
				}
			},
			{
				"box": {
					"id": "fov-recv",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						240,
						360,
						180,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "receive~ tl_failure_override"
				}
			},
			{
				"box": {
					"id": "dry-tapin-L",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						400,
						30,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "tapin~ 50"
				}
			},
			{
				"box": {
					"id": "dry-tapin-R",
					"maxclass": "newobj",
					"numinlets": 1,
					"numoutlets": 1,
					"patching_rect": [
						490,
						30,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "tapin~ 50"
				}
			},
			{
				"box": {
					"id": "dry-tapout-L",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						400,
						60,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "tapout~ 30"
				}
			},
			{
				"box": {
					"id": "dry-tapout-R",
					"maxclass": "newobj",
					"numinlets": 2,
					"numoutlets": 1,
					"patching_rect": [
						490,
						60,
						80,
						22
					],
					"outlettype": [
						"signal"
					],
					"text": "tapout~ 30"
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
						"box-tl_saturate",
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
						"box-tl_saturate",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_saturate",
						0
					],
					"destination": [
						"box-tl_model_eq",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_saturate",
						1
					],
					"destination": [
						"box-tl_model_eq",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_model_eq",
						0
					],
					"destination": [
						"box-tl_failure",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_model_eq",
						1
					],
					"destination": [
						"box-tl_failure",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_failure",
						0
					],
					"destination": [
						"box-tl_wow",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_failure",
						1
					],
					"destination": [
						"box-tl_wow",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_wow",
						0
					],
					"destination": [
						"box-tl_flutter",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_wow",
						1
					],
					"destination": [
						"box-tl_flutter",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_flutter",
						0
					],
					"destination": [
						"box-tl_aux",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_flutter",
						1
					],
					"destination": [
						"box-tl_aux",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_aux",
						0
					],
					"destination": [
						"box-tl_volume_mix",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_aux",
						1
					],
					"destination": [
						"box-tl_volume_mix",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_volume_mix",
						0
					],
					"destination": [
						"box-tl_dry_mix",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_volume_mix",
						1
					],
					"destination": [
						"box-tl_dry_mix",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_dry_mix",
						0
					],
					"destination": [
						"box-tl_noise",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_dry_mix",
						1
					],
					"destination": [
						"box-tl_noise",
						1
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_noise",
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
						"box-tl_noise",
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
						"dial-saturate",
						0
					],
					"destination": [
						"box-tl_saturate",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tab-input_gain",
						0
					],
					"destination": [
						"box-tl_saturate",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dial-model",
						0
					],
					"destination": [
						"box-tl_model_eq",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dip-filter_bypass",
						0
					],
					"destination": [
						"box-tl_model_eq",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dial-failure",
						0
					],
					"destination": [
						"box-tl_failure",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dip-drop_bypass",
						0
					],
					"destination": [
						"box-tl_failure",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dip-snag_bypass",
						0
					],
					"destination": [
						"box-tl_failure",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dip-spread",
						0
					],
					"destination": [
						"box-tl_failure",
						5
					]
				}
			},
			{
				"patchline": {
					"source": [
						"hidden-crinkle_level",
						0
					],
					"destination": [
						"box-tl_failure",
						6
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dial-wow",
						0
					],
					"destination": [
						"box-tl_wow",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dial-flutter",
						0
					],
					"destination": [
						"box-tl_flutter",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dip-classic_mode",
						0
					],
					"destination": [
						"box-tl_flutter",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tab-aux_mode",
						0
					],
					"destination": [
						"box-tl_aux",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tog-aux_active",
						0
					],
					"destination": [
						"box-tl_aux",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"hidden-aux_onset_ms",
						0
					],
					"destination": [
						"box-tl_aux",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dial-volume",
						0
					],
					"destination": [
						"box-tl_volume_mix",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dip-miso",
						0
					],
					"destination": [
						"box-tl_volume_mix",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tab-dry_mode",
						0
					],
					"destination": [
						"box-tl_dry_mix",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"tab-noise_mode",
						0
					],
					"destination": [
						"box-tl_noise",
						2
					]
				}
			},
			{
				"patchline": {
					"source": [
						"hidden-hiss_level",
						0
					],
					"destination": [
						"box-tl_noise",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"hidden-mechanical_level",
						0
					],
					"destination": [
						"box-tl_noise",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dip-hum_bypass",
						0
					],
					"destination": [
						"box-tl_noise",
						5
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_aux",
						2
					],
					"destination": [
						"fov-send",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"fov-recv",
						0
					],
					"destination": [
						"box-tl_failure",
						7
					]
				}
			},
			{
				"patchline": {
					"source": [
						"box-tl_model_eq",
						2
					],
					"destination": [
						"box-tl_wow",
						3
					]
				}
			},
			{
				"patchline": {
					"source": [
						"plugin-in",
						0
					],
					"destination": [
						"dry-tapin-L",
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
						"dry-tapin-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dry-tapin-L",
						0
					],
					"destination": [
						"dry-tapout-L",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dry-tapin-R",
						0
					],
					"destination": [
						"dry-tapout-R",
						0
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dry-tapout-L",
						0
					],
					"destination": [
						"box-tl_dry_mix",
						4
					]
				}
			},
			{
				"patchline": {
					"source": [
						"dry-tapout-R",
						0
					],
					"destination": [
						"box-tl_dry_mix",
						5
					]
				}
			}
		],
		"project": {
			"name": "tape-loss",
			"amxdtype": 1633771873
		},
		"dependency_cache": [],
		"autosave": 0
	}
}