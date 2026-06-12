// ═══════════════════════════════════════════════════════════
//  setforge-loader — main controller
// ═══════════════════════════════════════════════════════════
//
// Loaded by [js loader.js] in the Max patch (after concat build).
// Implements: chop routing, preset banks, scene memory,
// modifier layer, FX bus, pad color rendering, LiveAPI integration.
//
// Surface I/O goes through the `surface` object (created above
// by the concat'd launchpad-surface files).
//
// Max [js] uses SpiderMonkey (ES5). No require(), no modules.

autowatch = 1;
inlets = 3;   // 0: Grid 1 MIDI, 1: Grid 2 MIDI, 2: messages/UI
outlets = 4;  // 0: Grid 1 MIDI out, 1: Grid 2 MIDI out, 2: LiveAPI, 3: status

// Console verbosity gate (M4L guideline: minimize Max Console output).
// SF_VERBOSE is undefined in Max (→ silent); test harness sets it true.
function dbg(s) { if (typeof SF_VERBOSE !== "undefined" && SF_VERBOSE) { post(s); } }

// Patcher handle — lets JS color panel UI objects directly (live preset glow).
// Guarded: null in the headless test harness (no real patcher).
var SF_PATCHER = null;
try { SF_PATCHER = this.patcher || null; } catch (e) { SF_PATCHER = null; }

// ── Surface instance (created by launchpad-surface.js dispatcher) ──
var surface = createSurface("mk2");

// ═══════════════════════════════════════════════════════════
//  Constants
// ═══════════════════════════════════════════════════════════

var BARS_PER_CHOP = 4;
var BEATS_PER_BAR = 4;
var NUM_CHOPS = 8;
var SLOTS_PER_BANK = 8;
var TOTAL_SLOTS = 16;
var NUM_SCENES = 8;
var DOUBLE_TAP_WINDOW_MS = 400;

var STEM_NAMES = ["drums", "bass", "other", "vox"];
var STEM_ROW = { drums: 1, bass: 2, other: 3, vox: 4 };
var ROW_STEM = { 1: "drums", 2: "bass", 3: "other", 4: "vox" };

var MODIFIERS = ["HOLD", "MUTE", "SOLO", "REV", "STUT", "HALF", "DBL", "KILL"];

// Launch quantization (Live enum values)
var LAUNCH_QUANT = { "1/16": 4, "1/8": 5, "1/4": 6, "1/2": 7, "1bar": 8 };
var ROW_QUANT = {
    drums: LAUNCH_QUANT["1/16"],
    bass:  LAUNCH_QUANT["1bar"],
    other: LAUNCH_QUANT["1/4"],
    vox:   LAUNCH_QUANT["1/2"]
};

// Side button function assignments (single-grid mode, left side top-to-bottom)
var SIDE_FUNC = ["MODE_TOGGLE", "TAP", "SYNC", "BPM_DOWN", "BPM_UP", "LOOP_IN", "LOOP_OUT", "PANIC"];

// Grid view mode (single-grid only)
var viewMode = "performance"; // "performance" or "control"
var viewModeLatched = false;
var viewModeLastPress = 0;
var singleGridMode = true; // true until second Launchpad detected

// ── Multi-song mode state ──
// Four-view model: solo | perRow | dualSong | control
var performanceView = "solo"; // "solo" or "perRow" (within performance mode)
var dualSongActive = false;
var dualSongLatched = false;
var dualSongLastPress = 0;
var preDualSongView = "solo"; // view to restore on dual-song exit

// Per-row mode: each stem row can source from its own preset
var rowSources = { drums: null, bass: null, other: null, vox: null };

// Track which pads are physically held (for hold-chop + tap-preset gesture)
var heldPads = {}; // key: "row,col", value: true

// Staging state for dual-song decks
var staging = { deckX: null, deckY: null, stagingHeld: false };
var loadedDecks = { deckX: null, deckY: null };
var lastActiveBankA = null;
var lastActiveBankB = null;

// Side button function assignments (right side)
var SIDE_FUNC_RIGHT = ["DUAL_SONG_TOGGLE", "DECK_SETUP", null, null, null, null, null, null];
var SIDE_BUTTONS_RIGHT = [89, 79, 69, 59, 49, 39, 29, 19];

// Module-level: flash SysEx messages queued by updateGrid1Colors, sent by sendSurfaceRgb
var pendingFlashMessages = [];

// ── Color palette (7-bit, 0-127) ──

var STEM_COLORS = {
    drums: { soft: [64, 20, 0],   bright: [127, 40, 0] },
    bass:  { soft: [0, 20, 64],   bright: [0, 40, 127] },
    other: { soft: [50, 50, 0],   bright: [100, 100, 0] },
    vox:   { soft: [0, 50, 20],   bright: [0, 127, 40] }
};

var GENRE_COLORS = {
    hiphop:  [127, 50, 0],
    idm:     [0, 60, 127],
    ambient: [0, 127, 50],
    rock:    [100, 100, 100],
    funk:    [127, 100, 0]
};

var STATE_COLORS = {
    empty:    [8, 8, 8],
    error:    [127, 0, 0],
    disabled: [40, 0, 0],
    off:      [0, 0, 0]
};

var MOD_COLORS = {
    idle:    [16, 16, 16],
    held:    [127, 127, 127],
    latched: [127, 127, 0]
};

var SCENE_COLORS = {
    empty:   [0, 0, 0],
    built:   [32, 0, 48],
    playing: [96, 0, 127]
};

var FX_TARGETS = ["drums", "bass", "other", "vox", "all", "deckA", "deckB", "master"];

var FILTER_POSITIONS = [
    { type: "lp", freq: 0 },
    { type: "lp", freq: 100 },
    { type: "lp", freq: 300 },
    { type: "bypass", freq: 0 },
    { type: "hp", freq: 300 },
    { type: "hp", freq: 1000 },
    { type: "hp", freq: 3000 },
    { type: "hp", freq: 20000 }
];

// MK2 palette indices for flash/pulse SysEx (from Novation reference).
// Only the entries we actually need for staging/indicator visuals.
var MK2_PALETTE = {
    OFF: 0,
    WHITE: 3,        // bright white
    RED: 5,          // bright red
    ORANGE: 9,       // warm orange (drums hue)
    YELLOW: 13,      // bright yellow
    GREEN: 21,       // bright green
    CYAN: 37,        // cyan
    BLUE: 45,        // bright blue
    PURPLE: 49,      // purple
    PINK: 53,        // pink
    DIM_WHITE: 1,    // dim white
    SOFT_BLUE: 41,   // closest to #7799cc — light blue/steel
};

// Map PRESET_PALETTE RGB values to nearest MK2 palette indices.
// These are hand-matched to the 8 preset colors for flash SysEx.
var PRESET_PALETTE_INDICES = [9, 45, 21, 53, 13, 37, 49, 57];

var PRESET_PALETTE = [
    [127, 40, 0],
    [0, 40, 127],
    [0, 127, 40],
    [127, 0, 80],
    [127, 100, 0],
    [0, 100, 127],
    [80, 0, 127],
    [127, 80, 80]
];

// ═══════════════════════════════════════════════════════════
//  Chop Math
// ═══════════════════════════════════════════════════════════

function secondsPerBar(bpm) {
    return (BEATS_PER_BAR * 60) / bpm;
}

function chopClipStart(col, bpm, downbeatSec) {
    var barIndex = (col - 1) * BARS_PER_CHOP;
    return downbeatSec + barIndex * secondsPerBar(bpm);
}

function chopClipLength(bpm) {
    return BARS_PER_CHOP * secondsPerBar(bpm);
}

// Derive a clip's loop length (in beats) from its loop length (in seconds)
// at the track's BPM, rounded to the nearest integer beat so the loop locks
// to the global grid. `length_sec` is the source of truth for loop duration
// (user-edits update it precisely via syncPresetClips); `length_bars` is a
// coarse integer hint that can't represent sub-bar loops. If trackBpm is
// missing, degrade to the old `lengthBars * 4` behavior so a bad-data chop
// gets a wrong *length* rather than a wrong *tempo*.
function chopBeatCount(chop, trackBpm) {
    if (trackBpm && trackBpm > 0 && chop && chop.clipLength > 0) {
        var beats = Math.round(chop.clipLength / (60.0 / trackBpm));
        return beats;
    }
    return (chop && chop.lengthBars) ? chop.lengthBars * BEATS_PER_BAR : 0;
}

function computeTrackChops(track) {
    var result = {};
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stemName = STEM_NAMES[s];
        var stem = track.stems ? track.stems[stemName] : null;
        if (!stem || !stem.path) {
            result[stemName] = null;
            continue;
        }

        var chops = [];

        // Full-stem mode (e.g. vocals): a single long clip warped by its own
        // Ableton .asd sidecar. taste exports vocals.wav + vocals.wav.asd with
        // a per-beat warp grid; Live auto-imports it on create_audio_clip. We
        // expose it as ONE enabled clip on column 1 (the rest disabled) and
        // flag it fullVocal so the load + warp-fix paths leave its markers and
        // length alone — no blind 4-bar slicing, no re-linearizing. You chop it
        // yourself in Ableton.
        if (stem.mode === "full_stem") {
            // Cleaned per-bar warp anchors [[beat_time, sample_time_sec], ...]
            // from taste; written into Live via add_warp_marker (Live can't read
            // taste's gzip .asd). See writeVocalWarpGrid().
            var voxGrid = stem.warp_grid || null;
            if (stem.chops && stem.chops.length > 0) {
                // Restore the user's saved vocal regions: one clip per chop,
                // each the full warped vocal limited to its [start, start+len]
                // region. fullVocal:true → trusts the warp grid (no re-warp);
                // the region markers are applied in the deferred warp pass.
                var nv = Math.min(stem.chops.length, NUM_CHOPS);
                for (var vc = 0; vc < nv; vc++) {
                    var vm = stem.chops[vc];
                    chops.push({
                        column: (vm.column !== undefined && vm.column !== null) ? vm.column : (vc + 1),
                        clipStart: vm.start_sec || 0,
                        clipLength: vm.length_sec || 0,
                        stemPath: stem.path,
                        disabled: false,
                        label: vm.label || "vocals", kind: vm.kind || "full",
                        fullVocal: true, warpGrid: voxGrid,
                        // Exact beats the user set (grid-independent restore).
                        startMarkerBeat: vm.start_marker_beat,
                        endMarkerBeat: vm.end_marker_beat,
                        loopStartBeat: vm.loop_start_beat,
                        loopEndBeat: vm.loop_end_beat
                    });
                }
                for (var vd = nv; vd < NUM_CHOPS; vd++) {
                    chops.push({ column: vd + 1, clipStart: 0, clipLength: 0, stemPath: stem.path, disabled: true });
                }
            } else {
                // No saved regions → one full-length warped clip.
                chops.push({
                    column: 1, clipStart: 0, clipLength: 0, stemPath: stem.path,
                    disabled: false, label: stem.label || "vocals", kind: "full",
                    fullVocal: true, warpGrid: voxGrid
                });
                for (var fc = 1; fc < NUM_CHOPS; fc++) {
                    chops.push({ column: fc + 1, clipStart: 0, clipLength: 0, stemPath: stem.path, disabled: true });
                }
            }
            result[stemName] = chops;
            continue;
        }

        // Use manifest chops if available (variable-length, song-structure-aware)
        if (stem.chops && stem.chops.length > 0) {
            var numChops = Math.min(stem.chops.length, NUM_CHOPS);
            for (var c = 0; c < numChops; c++) {
                var mc = stem.chops[c];
                // Prefer materialized chop WAV (chop_path) over stem + loop markers
                var chopPath = mc.chop_path || stem.path;
                var loopStart, loopEnd;
                if (mc.chop_path && mc.loop_start_sec !== undefined) {
                    // Materialized chop: loop region within the pre-cut WAV
                    loopStart = mc.loop_start_sec;
                    loopEnd = mc.loop_end_sec;
                } else {
                    // Fallback: loop into full stem
                    loopStart = mc.start_sec || 0;
                    loopEnd = (mc.start_sec || 0) + (mc.length_sec || 0);
                }
                chops.push({
                    // Honor the persisted column when present (post-sync,
                    // post-move, post-delete) so structural ops survive
                    // reload. Legacy / pre-sync manifests fall back to
                    // sequential numbering.
                    column: (mc.column !== undefined && mc.column !== null) ? mc.column : (c + 1),
                    clipStart: loopStart,
                    clipLength: loopEnd - loopStart,
                    stemPath: chopPath,
                    disabled: false,
                    label: mc.label || "",
                    kind: mc.kind || "",
                    bpm: mc.bpm,
                    lengthBars: mc.length_bars || 0
                });
            }
            // Fill remaining columns as disabled
            for (var c = numChops; c < NUM_CHOPS; c++) {
                chops.push({ column: c + 1, clipStart: 0, clipLength: 0, stemPath: stem.path, disabled: true });
            }
        } else if (stem.curated) {
            // User curated this stem and deleted ALL its clips. Honor the empty
            // state on reload — do NOT blind-grid it back. (The `curated` flag
            // is stamped by syncPresetClips when the user saves.)
            for (var ec = 1; ec <= NUM_CHOPS; ec++) {
                chops.push({ column: ec, clipStart: 0, clipLength: 0, stemPath: stem.path, disabled: true });
            }
        } else {
            // Fallback: fixed 4-bar grid from downbeat + BPM (never curated)
            var length = track.varying ? 0 : chopClipLength(track.bpm);
            for (var c = 1; c <= NUM_CHOPS; c++) {
                if (track.varying) {
                    chops.push({ column: c, clipStart: 0, clipLength: 0, stemPath: stem.path, disabled: true });
                } else {
                    chops.push({
                        column: c,
                        clipStart: chopClipStart(c, track.bpm, track.downbeat_sec || 0),
                        clipLength: length,
                        stemPath: stem.path,
                        disabled: false
                    });
                }
            }
        }

        result[stemName] = chops;
    }
    return result;
}

// ═══════════════════════════════════════════════════════════
//  Surface Output Helpers
// ═══════════════════════════════════════════════════════════

// Send SysEx messages from surface.flushRgb() to the right outlet.
// Prepends programmer mode enter before every flush — the LP may
// reset at any time (USB power glitch) and revert to Note mode.
// The SysEx is 9 bytes; the LP ignores it if already in programmer mode.
function sendSurfaceRgb(grid) {
    if (grid === 1) {
        outlet(0, surface.enterProgrammerMode());
    }
    var messages = surface.flushRgb(grid);
    var outletIdx = (singleGridMode || grid === 1) ? 0 : 1;
    for (var i = 0; i < messages.length; i++) {
        outlet(outletIdx, messages[i]);
    }
    // Send any pending flash SysEx (staging visuals)
    if (grid === 1 && pendingFlashMessages && pendingFlashMessages.length > 0) {
        for (var f = 0; f < pendingFlashMessages.length; f++) {
            outlet(outletIdx, pendingFlashMessages[f]);
        }
        pendingFlashMessages = [];
    }
}

// ═══════════════════════════════════════════════════════════
//  State: Preset Banks
// ═══════════════════════════════════════════════════════════

var presetSlots = [];
var activeSlotIndex = -1;

function initPresetBanks() {
    presetSlots = [];
    for (var i = 0; i < TOTAL_SLOTS; i++) {
        presetSlots.push({
            index: i,
            state: "empty",
            trackId: null,
            track: null,
            chops: null,
            bank: (i < SLOTS_PER_BANK) ? "A" : "B"
        });
    }
    activeSlotIndex = -1;
}

function loadPresetSlot(index, trackId, track, chops) {
    var slot = presetSlots[index];
    slot.state = "loaded_idle";
    slot.trackId = trackId;
    slot.track = track;
    slot.chops = chops;
}

function activatePreset(index) {
    var slot = presetSlots[index];
    if (!slot || (slot.state !== "loaded_idle" && slot.state !== "loaded_active")) return null;

    var previous = activeSlotIndex;
    if (previous >= 0 && previous !== index) {
        presetSlots[previous].state = "loaded_idle";
    }
    slot.state = "loaded_active";
    activeSlotIndex = index;
    return { previous: previous, current: index };
}

function getActivePreset() {
    if (activeSlotIndex < 0) return null;
    return presetSlots[activeSlotIndex];
}

// ═══════════════════════════════════════════════════════════
//  State: Chop Router
// ═══════════════════════════════════════════════════════════

var playingChops = { drums: -1, bass: -1, other: -1, vox: -1 };

function getHeldChops() {
    var held = [];
    for (var i = 0; i < STEM_NAMES.length; i++) {
        var stem = STEM_NAMES[i];
        if (playingChops[stem] >= 1) {
            held.push({ stem: stem, col: playingChops[stem], row: STEM_ROW[stem] });
        }
    }
    return held;
}

function pressChop(row, col) {
    var stem = ROW_STEM[row];
    if (!stem) return null;

    var active = getEffectivePreset(stem);
    if (!active || !active.chops || !active.chops[stem]) return null;

    var chopList = active.chops[stem];
    var chop = null;
    for (var i = 0; i < chopList.length; i++) {
        if (chopList[i].column === col) { chop = chopList[i]; break; }
    }
    if (!chop) return null;

    if (chop.disabled) {
        if (stem === "drums" && col === 1) {
            return { action: "play_full", stem: stem, column: col, chop: chop };
        }
        return null;
    }

    var current = playingChops[stem];

    if (modState.HOLD === "held" || modState.HOLD === "latched") {
        return { action: "one_shot", stem: stem, column: col, chop: chop };
    }

    var action;
    if (current === col) {
        action = "stop";
        playingChops[stem] = -1;
    } else {
        action = (current >= 1) ? "replace" : "start";
        playingChops[stem] = col;
    }

    return { action: action, stem: stem, column: col, chop: chop };
}

function hotSwapChops(newChops) {
    var migrations = [];
    for (var i = 0; i < STEM_NAMES.length; i++) {
        var stem = STEM_NAMES[i];
        var col = playingChops[stem];
        if (col < 1) continue;

        var newStemChops = newChops ? newChops[stem] : null;
        var newChop = null;
        if (newStemChops) {
            for (var j = 0; j < newStemChops.length; j++) {
                if (newStemChops[j].column === col && !newStemChops[j].disabled) {
                    newChop = newStemChops[j];
                    break;
                }
            }
        }
        if (!newChop) {
            playingChops[stem] = -1;
        }
        migrations.push({ stem: stem, column: col, newChop: newChop });
    }
    return migrations;
}

function stopAllChops() {
    for (var i = 0; i < STEM_NAMES.length; i++) {
        playingChops[STEM_NAMES[i]] = -1;
    }
}

// ═══════════════════════════════════════════════════════════
//  State: Modifier Layer
// ═══════════════════════════════════════════════════════════

var modState = {};
var modLastPress = {};

function initModifiers() {
    for (var i = 0; i < MODIFIERS.length; i++) {
        modState[MODIFIERS[i]] = "idle";
        modLastPress[MODIFIERS[i]] = 0;
    }
}

function pressModifier(modIndex, timestamp) {
    var mod = MODIFIERS[modIndex];
    if (!mod) return;
    var now = timestamp || Date.now();

    if (modState[mod] === "latched") {
        modState[mod] = "idle";
        return;
    }

    var delta = now - (modLastPress[mod] || 0);
    if (delta < DOUBLE_TAP_WINDOW_MS && delta > 0) {
        modState[mod] = "latched";
    } else {
        modState[mod] = "held";
    }
    modLastPress[mod] = now;
}

function releaseModifier(modIndex) {
    var mod = MODIFIERS[modIndex];
    if (!mod) return;
    if (modState[mod] === "held") {
        modState[mod] = "idle";
    }
}

function clearModifiers() {
    for (var i = 0; i < MODIFIERS.length; i++) {
        modState[MODIFIERS[i]] = "idle";
        modLastPress[MODIFIERS[i]] = 0;
    }
}

function modifierSnapshot() {
    var snap = {};
    for (var i = 0; i < MODIFIERS.length; i++) {
        snap[MODIFIERS[i]] = modState[MODIFIERS[i]];
    }
    return snap;
}

function restoreModifiers(snap) {
    if (!snap) return;
    for (var i = 0; i < MODIFIERS.length; i++) {
        if (snap[MODIFIERS[i]]) {
            modState[MODIFIERS[i]] = snap[MODIFIERS[i]];
        }
    }
}

// ═══════════════════════════════════════════════════════════
//  State: Scene Memory
// ═══════════════════════════════════════════════════════════

var scenes = [];
var lastTriggeredScene = -1;

function initScenes() {
    scenes = [];
    for (var i = 0; i < NUM_SCENES; i++) {
        scenes.push({ state: "empty", snapshot: null });
    }
    lastTriggeredScene = -1;
}

function saveScene(index) {
    if (index < 0 || index >= NUM_SCENES) return;
    var snap = {
        activePresetIndex: activeSlotIndex,
        heldChops: getHeldChops(),
        modifiers: modifierSnapshot(),
        view: dualSongActive ? "dualSong" : performanceView,
        rowSources: null,
        stagingDeckX: staging.deckX,
        stagingDeckY: staging.deckY
    };
    if (performanceView === "perRow") {
        snap.rowSources = {};
        for (var i = 0; i < STEM_NAMES.length; i++) {
            snap.rowSources[STEM_NAMES[i]] = rowSources[STEM_NAMES[i]];
        }
    }
    scenes[index] = { state: "built", snapshot: snap };
}

function recallScene(index) {
    if (index < 0 || index >= NUM_SCENES) return null;
    var scene = scenes[index];
    if (scene.state === "empty" || !scene.snapshot) return null;

    if (lastTriggeredScene >= 0 && lastTriggeredScene !== index) {
        if (scenes[lastTriggeredScene].state === "playing") {
            scenes[lastTriggeredScene].state = "built";
        }
    }
    scene.state = "playing";
    lastTriggeredScene = index;
    return scene.snapshot;
}

// ═══════════════════════════════════════════════════════════
//  State: FX Bus
// ═══════════════════════════════════════════════════════════

var fxTarget = "all";
var fxFilterCol = 4;
var fxFilterLatched = false;
var fxThrowCol = -1;
var fxFilterLastPress = 0;

function bypassFx() {
    fxFilterCol = 4;
    fxFilterLatched = false;
    fxThrowCol = -1;
}

// ═══════════════════════════════════════════════════════════
//  LiveAPI Integration
// ═══════════════════════════════════════════════════════════

var liveApi = null;
var stemTrackIds = {};       // SOLO / active-preset tracks: sf-drums, sf-bass, ...
var stemTrackIndices = {};
var stemTrackIdsX = {};      // Deck X (multi-song) tracks: sf-drums-x, sf-bass-x, ...
var stemTrackIndicesX = {};
var stemTrackIdsY = {};      // Deck Y (multi-song) tracks: sf-drums-y, sf-bass-y, ...
var stemTrackIndicesY = {};

var WARP_MODES = { drums: 0, bass: 0, other: 4, vox: 4 };

function initLiveApi() {
    try {
        liveApi = new LiveAPI("live_set");
        dbg("setforge-loader: LiveAPI ready, tracks=" + liveApi.get("tracks").length + "\n");
    } catch (e) {
        post("setforge-loader: LiveAPI init failed: " + e + "\n");
    }
}

function ensureScenes(n) {
    if (!liveApi) return;
    try {
        var current = liveApi.getcount("scenes");
        var created = 0;
        while (current < n) {
            liveApi.call("create_scene", current);
            current++;
            created++;
        }
        if (created > 0) {
            post("setforge-loader: created " + created + " scenes (total: " + current + ")\n");
        }
    } catch (e) {
        post("setforge-loader: ensureScenes error: " + e + "\n");
    }
}

function ensureStemTracks() {
    if (!liveApi) { post("setforge-loader: no LiveAPI\n"); return false; }

    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackName = "sf-" + stem;
        var trackIdx = findTrackByName(trackName);

        if (trackIdx < 0) {
            post("setforge-loader: creating track '" + trackName + "'\n");
            try {
                var trackCount = liveApi.get("tracks").length / 2;
                var insertIdx = Math.max(0, trackCount - 1);
                liveApi.call("create_audio_track", insertIdx);

                var newCount = liveApi.get("tracks").length / 2;
                trackIdx = insertIdx;

                var tApi = new LiveAPI("live_set tracks " + trackIdx);
                tApi.set("name", trackName);

                var verifyName = tApi.get("name").toString();
                post("setforge-loader: created '" + trackName + "' at index " + trackIdx + " (verify: " + verifyName + ")\n");
            } catch (e) {
                post("setforge-loader: error creating track '" + trackName + "': " + e + "\n");
                continue;
            }
        } else {
            dbg("setforge-loader: found track '" + trackName + "' at index " + trackIdx + "\n");
        }

        stemTrackIndices[stem] = trackIdx;
        stemTrackIds[stem] = "live_set tracks " + trackIdx;
    }

    // ── Deck X tracks (multi-song: separate from solo so staging doesn't
    //    overwrite the currently-playing preset) ──
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackName = "sf-" + stem + "-x";
        var trackIdx = findTrackByName(trackName);

        if (trackIdx < 0) {
            post("setforge-loader: creating deck-X track '" + trackName + "'\n");
            try {
                var trackCount = liveApi.get("tracks").length / 2;
                var insertIdx = Math.max(0, trackCount - 1);
                liveApi.call("create_audio_track", insertIdx);
                trackIdx = insertIdx;

                var tApi = new LiveAPI("live_set tracks " + trackIdx);
                tApi.set("name", trackName);
                post("setforge-loader: created '" + trackName + "' at index " + trackIdx + "\n");
            } catch (e) {
                post("setforge-loader: error creating deck-X track '" + trackName + "': " + e + "\n");
                continue;
            }
        } else {
            dbg("setforge-loader: found deck-X track '" + trackName + "' at index " + trackIdx + "\n");
        }

        stemTrackIndicesX[stem] = trackIdx;
        stemTrackIdsX[stem] = "live_set tracks " + trackIdx;
    }

    // ── Deck Y tracks (for dual-song mode) ──
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackName = "sf-" + stem + "-y";
        var trackIdx = findTrackByName(trackName);

        if (trackIdx < 0) {
            post("setforge-loader: creating deck-Y track '" + trackName + "'\n");
            try {
                var trackCount = liveApi.get("tracks").length / 2;
                var insertIdx = Math.max(0, trackCount - 1);
                liveApi.call("create_audio_track", insertIdx);
                trackIdx = insertIdx;

                var tApi = new LiveAPI("live_set tracks " + trackIdx);
                tApi.set("name", trackName);
                post("setforge-loader: created '" + trackName + "' at index " + trackIdx + "\n");
            } catch (e) {
                post("setforge-loader: error creating deck-Y track '" + trackName + "': " + e + "\n");
                continue;
            }
        } else {
            dbg("setforge-loader: found deck-Y track '" + trackName + "' at index " + trackIdx + "\n");
        }

        stemTrackIndicesY[stem] = trackIdx;
        stemTrackIdsY[stem] = "live_set tracks " + trackIdx;
    }

    return true;
}

function findTrackByName(name) {
    if (!liveApi) return -1;
    try {
        var trackIds = liveApi.get("tracks");
        var numTracks = trackIds.length / 2;
        for (var i = 0; i < numTracks; i++) {
            var tApi = new LiveAPI("live_set tracks " + i);
            var tName = tApi.get("name").toString();
            if (tName === name) return i;
        }
    } catch (e) {
        post("setforge-loader: findTrackByName error: " + e + "\n");
    }
    return -1;
}

// ── Fixed bank→slot-set mapping ──
// Bank A presets (preset index 0..7) ALWAYS load their clips into Live slots
// 0..7; Bank B presets (index 8..15) ALWAYS into slots 8..15. The slot-set is
// DERIVED from the preset's bank, not an alternating "active set" flag. This
// guarantees the offset used to LOAD a preset and the offset used to
// SYNC/SAVE it are identical — eliminating the bug where a B-bank preset
// loaded into one set but save read the other and silently wiped its chops.
var stagingPresetIndex = -1;
var stagingReady = false;

function bankSetOffset(presetIdx) {
    return (presetIdx != null && presetIdx >= SLOTS_PER_BANK) ? SLOTS_PER_BANK : 0;
}
function activeSetOffset() { return bankSetOffset(activeSlotIndex); }
function stagingSetOffset() { return bankSetOffset(stagingPresetIndex); }
function activeBankLabel() { return (activeSlotIndex >= SLOTS_PER_BANK) ? "B" : "A"; }

function loadClipsToSlotSet(presetIdx, offset) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops) return 0;

    var totalLoaded = 0;
    post("setforge-loader: loading clips for " + slot.trackId + " into set " +
         (offset === 0 ? "A" : "B") + " (slots " + offset + "-" + (offset + 7) + ")\n");

    // Clear all slots in this bank range (offset..offset+7) on every stem
    // track BEFORE creating new clips. This prevents stale clips from a
    // previous preset bleeding through when the new preset uses fewer slots.
    for (var cs = 0; cs < STEM_NAMES.length; cs++) {
        var clearTrack = stemTrackIds[STEM_NAMES[cs]];
        if (!clearTrack) continue;
        for (var ci = 0; ci < SLOTS_PER_BANK; ci++) {
            try {
                var clearApi = new LiveAPI(clearTrack + " clip_slots " + (offset + ci));
                var clearHas = clearApi.get("has_clip");
                if (clearHas && clearHas.toString() === "1") {
                    clearApi.call("delete_clip");
                }
            } catch (_) {}
        }
    }

    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var chopList = slot.chops[stem];
        if (!chopList) { continue; }

        var trackPath = stemTrackIds[stem];
        if (!trackPath) { continue; }

        var loaded = 0;
        for (var c = 0; c < chopList.length; c++) {
            var chop = chopList[c];
            if (chop.disabled) continue;

            var clipSlot = offset + (chop.column - 1);
            var csPath = trackPath + " clip_slots " + clipSlot;

            try {
                var csApi = new LiveAPI(csPath);

                csApi.call("create_audio_clip", String(chop.stemPath));

                var clipApi = new LiveAPI(csPath + " clip");
                if (clipApi && clipApi.id !== "0") {
                    var clipLabel = (chop.label ? chop.label : "chop") +
                        (chop.kind ? " [" + chop.kind + "]" : "");

                    var beatCount = chopBeatCount(chop, slot.track && slot.track.bpm);

                    // Identity-prefix the clip name so sync can reconcile
                    // moves / deletes / copies. Format: [sf:trackId/stem/idx]
                    // where idx is the chop's position in the manifest's
                    // chop list. Sync parses this off the name; falls back
                    // to positional mapping if absent.
                    var identityKey = slot.trackId + "/" + stem + "/" + c;
                    clipApi.set("name", "[sf:" + identityKey + "] " + clipLabel);

                    if (chop.fullVocal) {
                        // Full vocal: trust the .asd warp grid. A saved REGION
                        // (a chop the user set) LOOPS; an un-chopped full vocal
                        // plays through. The exact loop + start/end markers are
                        // restored in the deferred pass once the grid is placed.
                        var voxHasRegion = (chop.startMarkerBeat !== undefined && chop.startMarkerBeat !== null) || chop.clipLength > 0;
                        clipApi.set("warping", 1);
                        clipApi.set("warp_mode", WARP_MODES[stem] || 0);
                        clipApi.set("looping", voxHasRegion ? 1 : 0);
                        clipApi.set("start_marker", 0);
                        clipApi.set("loop_start", 0);
                        clipApi.set("launch_quantization", ROW_QUANT[stem]);
                    } else if (beatCount > 0) {
                        clipApi.set("warping", 1);
                        // Op 2: per-clip BPM override. If the manifest carries
                        // a chop.bpm field, write it to Live as warp_bpm before
                        // the warp-marker correction pass runs (which still
                        // computes marker positions from clipStart/clipLength,
                        // independently). The sacred BPM-correction code is
                        // untouched; this is additive.
                        if (chop.bpm) {
                            try { clipApi.set("warp_bpm", chop.bpm); } catch (_) {}
                        }
                        clipApi.set("warp_mode", WARP_MODES[stem] || 0);
                        clipApi.set("looping", 1);
                        clipApi.set("start_marker", 0);
                        clipApi.set("end_marker", beatCount);
                        clipApi.set("loop_start", 0);
                        clipApi.set("loop_end", beatCount);
                        clipApi.set("launch_quantization", ROW_QUANT[stem]);
                    } else {
                        clipApi.set("warping", 0);
                        clipApi.set("looping", 0);
                        clipApi.set("start_marker", chop.clipStart);
                        clipApi.set("end_marker", chop.clipStart + chop.clipLength);
                        clipApi.set("launch_quantization", ROW_QUANT[stem]);
                    }
                    loaded++;
                }
            } catch (e) {
                post("  " + stem + " col " + chop.column + ": error: " + e + "\n");
            }
        }
        post("  " + stem + ": " + loaded + "/" + chopList.length + " clips\n");
        totalLoaded += loaded;
    }
    return totalLoaded;
}

// Load clips for a single stem from a preset into a specific track at a given offset.
// Used by per-row mode (reload one stem) and dual-song staging (load into Y tracks).
function loadStemClipsToTrack(stem, presetIdx, offset, trackPath) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops || !slot.chops[stem]) return 0;

    var chopList = slot.chops[stem];
    if (!trackPath) return 0;

    var loaded = 0;
    for (var c = 0; c < chopList.length; c++) {
        var chop = chopList[c];
        if (chop.disabled) continue;

        var clipSlot = offset + (chop.column - 1);
        var csPath = trackPath + " clip_slots " + clipSlot;

        try {
            var csApi = new LiveAPI(csPath);
            try {
                var hasClip = csApi.get("has_clip");
                if (hasClip && hasClip.toString() === "1") {
                    csApi.call("delete_clip");
                }
            } catch (_) {}

            csApi.call("create_audio_clip", String(chop.stemPath));

            var clipApi = new LiveAPI(csPath + " clip");
            if (clipApi && clipApi.id !== "0") {
                var clipLabel = (chop.label ? chop.label : "chop") +
                    (chop.kind ? " [" + chop.kind + "]" : "");
                var beatCount = chopBeatCount(chop, slot.track && slot.track.bpm);

                // Identity-prefixed name; sync uses it to track moves/copies.
                var identityKey = slot.trackId + "/" + stem + "/" + c;
                clipApi.set("name", "[sf:" + identityKey + "] " + clipLabel);

                if (chop.fullVocal) {
                    // Full vocal: trust the imported .asd warp grid; a saved
                    // region LOOPS, an un-chopped full vocal plays through.
                    // Loop + markers restored in the deferred pass.
                    var voxHasRegionY = (chop.startMarkerBeat !== undefined && chop.startMarkerBeat !== null) || chop.clipLength > 0;
                    clipApi.set("warping", 1);
                    clipApi.set("warp_mode", WARP_MODES[stem] || 0);
                    clipApi.set("looping", voxHasRegionY ? 1 : 0);
                    clipApi.set("start_marker", 0);
                    clipApi.set("loop_start", 0);
                    clipApi.set("launch_quantization", ROW_QUANT[stem]);
                } else if (beatCount > 0) {
                    clipApi.set("warping", 1);
                    if (chop.bpm) {
                        try { clipApi.set("warp_bpm", chop.bpm); } catch (_) {}
                    }
                    clipApi.set("warp_mode", WARP_MODES[stem] || 0);
                    clipApi.set("looping", 1);
                    clipApi.set("start_marker", 0);
                    clipApi.set("end_marker", beatCount);
                    clipApi.set("loop_start", 0);
                    clipApi.set("loop_end", beatCount);
                    clipApi.set("launch_quantization", ROW_QUANT[stem]);
                } else {
                    clipApi.set("warping", 0);
                    clipApi.set("looping", 0);
                    clipApi.set("start_marker", chop.clipStart);
                    clipApi.set("end_marker", chop.clipStart + chop.clipLength);
                    clipApi.set("launch_quantization", ROW_QUANT[stem]);
                }
                loaded++;
            }
        } catch (e) {
            post("  " + stem + " col " + chop.column + ": error: " + e + "\n");
        }
    }
    return loaded;
}

// Load all 4 stems of a preset into deck Y tracks (for dual-song staging).
function loadPresetToDeckY(presetIdx) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops) return 0;

    post("setforge-loader: loading preset " + slot.trackId + " into deck Y tracks\n");
    var totalLoaded = 0;
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackPath = stemTrackIdsY[stem];
        if (!trackPath) continue;
        var loaded = loadStemClipsToTrack(stem, presetIdx, 0, trackPath);
        post("  " + stem + "-y: " + loaded + " clips\n");
        totalLoaded += loaded;
    }

    // Deferred warp fix for deck Y tracks
    var fixTask = new Task(function() {
        fixWarpMarkersOnTracks(presetIdx, 0, stemTrackIdsY);
    });
    fixTask.schedule(4000);

    return totalLoaded;
}

// Load all 4 stems of a preset into deck X tracks (dedicated sf-{stem}-x tracks,
// separate from solo's active-preset tracks — staging pre-loads here without
// disturbing what solo is playing).
function loadPresetToDeckX(presetIdx) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops) return 0;

    post("setforge-loader: loading preset " + slot.trackId + " into deck X tracks\n");
    var totalLoaded = 0;
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackPath = stemTrackIdsX[stem];
        if (!trackPath) continue;
        var loaded = loadStemClipsToTrack(stem, presetIdx, 0, trackPath);
        post("  " + stem + "-x: " + loaded + " clips\n");
        totalLoaded += loaded;
    }

    var fixTask = new Task(function() {
        fixWarpMarkersOnTracks(presetIdx, 0, stemTrackIdsX);
    });
    fixTask.schedule(4000);

    return totalLoaded;
}

function loadClipsForPreset(presetIdx) {
    var offset = bankSetOffset(presetIdx);
    loadClipsToSlotSet(presetIdx, offset);
    // Defer warp marker adjustment — Live needs time to analyze new clips
    // before we can read and move its auto-generated markers.
    var fixTask = new Task(function() {
        fixWarpMarkers(presetIdx, offset);
    });
    fixTask.schedule(4000); // 4 seconds for Live to finish analysis (long clips need more time)
}

// Write taste's cleaned per-bar warp grid into a (warped) vocal clip via the
// LOM. grid = [[beat_time, sample_time_sec], ...]. sample_time is in SECONDS —
// the same unit the chop warp-fix already uses successfully (see the
// add_warp_marker / loopEndSec calls below). Live ignores taste's .asd, so this
// is how the per-bar grid actually reaches Live. We add a marker at each grid
// beat; Live's own auto markers occupy a beat or two already, so collisions are
// caught and skipped. The trailing non-movable "shadow" marker is left alone.
function writeVocalWarpGrid(clipApi, grid) {
    if (!grid || !grid.length) return 0;

    // Audio-length guard (defensive; taste's reconciled Step-5 cap already
    // bounds this). Never write a marker whose sample_time exceeds the clip's
    // audio length — that's what truncated long tracks (e.g. 8051). Materialized
    // vocal stems are 44.1 kHz. If sample_length is unreadable, skip the guard.
    var maxSec = null;
    try {
        var sl = Number(clipApi.get("sample_length"));
        if (sl && sl > 0) maxSec = sl / 44100.0;
    } catch (e) {}

    // Beat-0 fix: Live auto-creates a default warp marker at [beat 0 -> sample 0]
    // for a warped clip. add_warp_marker(beat=0,...) COLLIDES with it and is
    // silently skipped, pinning beat 0 to sample 0 and cramming the whole intro
    // into bar 1 (the "chipmunk intro") on every track. Fix: add beats >= 4
    // first (no collision), then remove the [0,0] default (now safe — siblings
    // exist) and re-add beat 0 at its true sample_time. Verified empirically:
    // sample_time is SECONDS, and remove+re-add round-trips exactly.
    var added = 0;
    var beat0sec = null;
    for (var g = 0; g < grid.length; g++) {
        var beat = grid[g][0];
        var sec = grid[g][1];
        if (maxSec !== null && sec > maxSec) continue;   // tail guard
        if (beat === 0 || beat < 0.5) { beat0sec = sec; continue; }  // defer beat 0
        try {
            var d = new Dict();
            d.set("beat_time", beat);
            d.set("sample_time", sec);
            clipApi.call("add_warp_marker", d);
            added++;
        } catch (e) { /* beat already has a marker — skip */ }
    }
    // Now relocate the beat-0 default to its true position.
    if (beat0sec !== null && (maxSec === null || beat0sec <= maxSec)) {
        try { clipApi.call("remove_warp_marker", 0); } catch (e) {}
        try {
            var d0 = new Dict();
            d0.set("beat_time", 0);
            d0.set("sample_time", beat0sec);
            clipApi.call("add_warp_marker", d0);
            added++;
        } catch (e) {
            // Fallback: if re-add failed, the default [0,0] may still be there;
            // leave it rather than end up with no beat-0 marker.
            post("  writeVocalWarpGrid: beat-0 relocate failed: " + e + "\n");
        }
    }
    return added;
}

// Map a source-audio time (seconds) to a beat position using the warp grid
// [[beat, sec], ...] (ascending). Linear interpolation between anchors, with
// linear extrapolation past the ends. Used to place a vocal clip's region
// (start/end markers, in beats) from its saved [start_sec, len_sec] region.
function secToBeatGrid(grid, sec) {
    if (!grid || !grid.length) return 0;
    if (sec <= grid[0][1]) return grid[0][0];
    for (var i = 1; i < grid.length; i++) {
        if (sec <= grid[i][1]) {
            var b0 = grid[i-1][0], s0 = grid[i-1][1], b1 = grid[i][0], s1 = grid[i][1];
            return (s1 === s0) ? b1 : b0 + (sec - s0) * (b1 - b0) / (s1 - s0);
        }
    }
    var n = grid.length, pb0 = grid[n-2][0], ps0 = grid[n-2][1], pb1 = grid[n-1][0], ps1 = grid[n-1][1];
    return (ps1 === ps0) ? pb1 : pb1 + (sec - ps1) * (pb1 - pb0) / (ps1 - ps0);
}

// Deferred pass: read Live's auto-generated warp markers and move them
// to match our known BPM. Called after create_audio_clip has had time
// to complete Live's async analysis.
function fixWarpMarkers(presetIdx, offset) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops) return;

    post("setforge-loader: fixing warp markers for " + slot.trackId + "...\n");
    var trackBpm = (slot.track && slot.track.bpm) ? slot.track.bpm : 0;

    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var chopList = slot.chops[stem];
        if (!chopList) continue;

        var trackPath = stemTrackIds[stem];
        if (!trackPath) continue;

        for (var c = 0; c < chopList.length; c++) {
            var chop = chopList[c];
            if (chop.disabled) continue;
            if (chop.fullVocal) {
                // Full vocal: write taste's cleaned per-bar grid into the clip.
                // Done in this deferred pass so Live has finished its own
                // analysis first (otherwise the markers don't stick).
                var fvSlot = offset + (chop.column - 1);
                var fvPath = trackPath + " clip_slots " + fvSlot;
                try {
                    var fvCs = new LiveAPI(fvPath);
                    if (fvCs.get("has_clip").toString() === "1") {
                        var fvClip = new LiveAPI(fvPath + " clip");
                        if (fvClip && fvClip.id !== "0") {
                            var nWrote = writeVocalWarpGrid(fvClip, chop.warpGrid);
                            post("  " + stem + ": wrote " + nWrote + " vocal warp markers\n");
                            // Restore the user's region. PREFER the exact beats
                            // captured at save time (grid-independent — a chop
                            // comes back identical). Fall back to the lossy
                            // seconds→grid reprojection only for legacy chops
                            // saved before beat capture existed.
                            if (chop.startMarkerBeat !== undefined && chop.startMarkerBeat !== null) {
                                var lsB = (chop.loopStartBeat !== undefined && chop.loopStartBeat !== null) ? chop.loopStartBeat : chop.startMarkerBeat;
                                var leB = (chop.loopEndBeat !== undefined && chop.loopEndBeat !== null) ? chop.loopEndBeat : chop.endMarkerBeat;
                                try {
                                    // Enable looping so the region repeats, then set
                                    // markers in a clamp-safe order: push end_marker
                                    // out first (so loop/start can move freely),
                                    // then the loop, then the start. Region == loop.
                                    fvClip.set("looping", 1);
                                    fvClip.set("end_marker", chop.endMarkerBeat);
                                    fvClip.set("loop_end", leB);
                                    fvClip.set("loop_start", lsB);
                                    fvClip.set("start_marker", chop.startMarkerBeat);
                                    post("  " + stem + " col " + chop.column + ": region beats " +
                                         chop.startMarkerBeat.toFixed(2) + "-" + chop.endMarkerBeat.toFixed(2) + " looping (exact)\n");
                                } catch (e) { post("  " + stem + ": region marker error: " + e + "\n"); }
                            } else if (chop.clipLength > 0 && chop.warpGrid && chop.warpGrid.length) {
                                var rb0 = secToBeatGrid(chop.warpGrid, chop.clipStart);
                                var rb1 = secToBeatGrid(chop.warpGrid, chop.clipStart + chop.clipLength);
                                try {
                                    fvClip.set("start_marker", rb0);
                                    fvClip.set("loop_start", rb0);
                                    fvClip.set("end_marker", rb1);
                                    fvClip.set("loop_end", rb1);
                                    post("  " + stem + " col " + chop.column + ": region beats " +
                                         rb0.toFixed(1) + "-" + rb1.toFixed(1) + " (legacy grid)\n");
                                } catch (e) { post("  " + stem + ": region marker error: " + e + "\n"); }
                            }
                        }
                    }
                } catch (e) { post("  " + stem + ": vocal grid error: " + e + "\n"); }
                continue;
            }

            var beatCount = chopBeatCount(chop, trackBpm);
            if (beatCount <= 0) {
                post("  " + stem + "[" + c + "]: skipping warp fix (beatCount=0, clipLength=" + chop.clipLength + ", bpm=" + trackBpm + ")\n");
                continue;
            }

            var clipSlot = offset + (chop.column - 1);
            var csPath = trackPath + " clip_slots " + clipSlot;

            try {
                var csApi = new LiveAPI(csPath);
                var hasClip = csApi.get("has_clip");
                if (!hasClip || hasClip.toString() !== "1") continue;

                var clipApi = new LiveAPI(csPath + " clip");
                if (!clipApi || clipApi.id === "0") continue;

                var loopStartSec = chop.clipStart;
                var loopEndSec = chop.clipStart + chop.clipLength;
                var secToBeat = beatCount / (loopEndSec - loopStartSec);

                // Read current warp markers
                var existingMarkers = [];
                try {
                    var rawWm = clipApi.get("warp_markers");
                    if (rawWm && rawWm.length > 0) {
                        var wmStr = (typeof rawWm[0] === "string") ? rawWm[0] : String(rawWm[0]);
                        var wmParsed = JSON.parse(wmStr);
                        if (wmParsed && wmParsed.warp_markers) {
                            existingMarkers = wmParsed.warp_markers;
                        } else if (wmParsed && wmParsed.length) {
                            existingMarkers = wmParsed;
                        }
                    }
                } catch (_) {}

                // Move existing markers to correct beat positions
                var moved = 0;
                for (var ei = 0; ei < existingMarkers.length; ei++) {
                    var em = existingMarkers[ei];
                    var correctBeat = (em.sample_time - loopStartSec) * secToBeat;
                    var delta = correctBeat - em.beat_time;
                    if (Math.abs(delta) >= 0.0001) {
                        try {
                            clipApi.call("move_warp_marker", em.beat_time, delta);
                            moved++;
                        } catch (_) {}
                    }
                }

                // If there's no marker near the end of the clip, add one.
                // This is critical for long clips where Live only auto-generates
                // markers near sample 0.
                var hasEndMarker = false;
                for (var ei = 0; ei < existingMarkers.length; ei++) {
                    if (existingMarkers[ei].sample_time > loopEndSec * 0.5) {
                        hasEndMarker = true;
                        break;
                    }
                }
                if (!hasEndMarker) {
                    try {
                        var wmEnd = new Dict();
                        wmEnd.set("beat_time", beatCount);
                        wmEnd.set("sample_time", loopEndSec);
                        clipApi.call("add_warp_marker", wmEnd);
                    } catch (_) {}
                }

                // Re-set clip boundaries
                clipApi.set("start_marker", 0);
                clipApi.set("end_marker", beatCount);
                clipApi.set("loop_start", 0);
                clipApi.set("loop_end", beatCount);

            } catch (e) {
                post("  " + stem + "[" + c + "]: warp fix error: " + e + "\n");
            }
        }
    }
    post("setforge-loader: warp markers fixed\n");

    // Now inspect (deferred so test harness gets correct data)
    inspectClips();
}

// Fix warp markers on arbitrary track paths (for deck Y tracks).
function fixWarpMarkersOnTracks(presetIdx, offset, trackIdMap) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops) return;

    post("setforge-loader: fixing warp markers (deck Y) for " + slot.trackId + "...\n");
    var trackBpm = (slot.track && slot.track.bpm) ? slot.track.bpm : 0;

    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var chopList = slot.chops[stem];
        if (!chopList) continue;

        var trackPath = trackIdMap[stem];
        if (!trackPath) continue;

        for (var c = 0; c < chopList.length; c++) {
            var chop = chopList[c];
            if (chop.disabled) continue;
            if (chop.fullVocal) continue; // .asd owns the grid — never re-warp

            var beatCount = chopBeatCount(chop, trackBpm);
            if (beatCount <= 0) {
                post("  " + stem + "[" + c + "]: skipping warp fix (beatCount=0, clipLength=" + chop.clipLength + ", bpm=" + trackBpm + ")\n");
                continue;
            }

            var clipSlot = offset + (chop.column - 1);
            var csPath = trackPath + " clip_slots " + clipSlot;

            try {
                var csApi = new LiveAPI(csPath);
                var hasClip = csApi.get("has_clip");
                if (!hasClip || hasClip.toString() !== "1") continue;

                var clipApi = new LiveAPI(csPath + " clip");
                if (!clipApi || clipApi.id === "0") continue;

                var loopStartSec = chop.clipStart;
                var loopEndSec = chop.clipStart + chop.clipLength;
                var secToBeat = beatCount / (loopEndSec - loopStartSec);

                var existingMarkers = [];
                try {
                    var rawWm = clipApi.get("warp_markers");
                    if (rawWm && rawWm.length > 0) {
                        var wmStr = (typeof rawWm[0] === "string") ? rawWm[0] : String(rawWm[0]);
                        var wmParsed = JSON.parse(wmStr);
                        if (wmParsed && wmParsed.warp_markers) existingMarkers = wmParsed.warp_markers;
                        else if (wmParsed && wmParsed.length) existingMarkers = wmParsed;
                    }
                } catch (_) {}

                for (var ei = 0; ei < existingMarkers.length; ei++) {
                    var em = existingMarkers[ei];
                    var correctBeat = (em.sample_time - loopStartSec) * secToBeat;
                    var delta = correctBeat - em.beat_time;
                    if (Math.abs(delta) >= 0.0001) {
                        try { clipApi.call("move_warp_marker", em.beat_time, delta); } catch (_) {}
                    }
                }

                var hasEndMarker = false;
                for (var ei = 0; ei < existingMarkers.length; ei++) {
                    if (existingMarkers[ei].sample_time > loopEndSec * 0.5) { hasEndMarker = true; break; }
                }
                if (!hasEndMarker) {
                    try {
                        var wmEnd = new Dict();
                        wmEnd.set("beat_time", beatCount);
                        wmEnd.set("sample_time", loopEndSec);
                        clipApi.call("add_warp_marker", wmEnd);
                    } catch (_) {}
                }

                clipApi.set("start_marker", 0);
                clipApi.set("end_marker", beatCount);
                clipApi.set("loop_start", 0);
                clipApi.set("loop_end", beatCount);
            } catch (e) {
                post("  " + stem + "[" + c + "]: warp fix error: " + e + "\n");
            }
        }
    }
    post("setforge-loader: deck Y warp markers fixed\n");
}

function stagePreset(presetIdx) {
    stagingPresetIndex = presetIdx;
    stagingReady = false;
    var loaded = loadClipsToSlotSet(presetIdx, stagingSetOffset());
    stagingReady = (loaded > 0);
    dbg("setforge-loader: staging " + (stagingReady ? "ready" : "failed") +
         " for preset " + presetIdx + "\n");

    // Defer warp marker fix for staged clips too
    var offset = stagingSetOffset();
    var fixTask = new Task(function() {
        fixWarpMarkers(presetIdx, offset);
    });
    fixTask.schedule(2000);
}

function commitStagedPreset() {
    // No set-flip: the active preset's bank determines its slot-set.
    stagingPresetIndex = -1;
    stagingReady = false;
    post("setforge-loader: committed, active set now " + activeBankLabel() + "\n");
}

function launchClipInTrack(stemName, slotIndex, chop) {
    if (!liveApi) return;

    var trackPath = stemTrackIds[stemName];
    if (!trackPath) {
        post("setforge-loader: no track for " + stemName + "\n");
        return;
    }

    var clipSlot = activeSetOffset() + (chop.column - 1);

    post("setforge-loader: launch " + stemName + " slot=" + clipSlot +
         " start=" + chop.clipStart.toFixed(2) + "\n");

    try {
        var csApi = new LiveAPI(trackPath + " clip_slots " + clipSlot);
        csApi.call("fire");
    } catch (e) {
        post("setforge-loader: launch error: " + e + "\n");
    }
}

function launchStagingClip(stemName, chop) {
    if (!liveApi) return;

    var trackPath = stemTrackIds[stemName];
    if (!trackPath) return;

    var clipSlot = stagingSetOffset() + (chop.column - 1);

    try {
        var csApi = new LiveAPI(trackPath + " clip_slots " + clipSlot);
        csApi.call("fire");
    } catch (e) {
        post("setforge-loader: staging launch error: " + e + "\n");
    }
}

function stopClipInTrack(stemName, slotIndex) {
    if (!liveApi) return;

    var trackPath = stemTrackIds[stemName];
    if (!trackPath) return;

    var clipSlot = activeSetOffset() + slotIndex;
    try {
        var csApi = new LiveAPI(trackPath + " clip_slots " + clipSlot);
        csApi.call("stop");
    } catch (e) {
        post("setforge-loader: stop error: " + e + "\n");
    }
}

function stopAllClips() {
    if (!liveApi) return;

    // Stop deck X tracks
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var trackPath = stemTrackIds[STEM_NAMES[s]];
        if (!trackPath) continue;
        try {
            var tApi = new LiveAPI(trackPath);
            tApi.call("stop_all_clips");
        } catch (e) {
            post("setforge-loader: stopAll error: " + e + "\n");
        }
    }
    // Stop deck Y tracks
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var trackPath = stemTrackIdsY[STEM_NAMES[s]];
        if (!trackPath) continue;
        try {
            var tApi = new LiveAPI(trackPath);
            tApi.call("stop_all_clips");
        } catch (e) {
            post("setforge-loader: stopAll-Y error: " + e + "\n");
        }
    }
}

// Launch a clip on a specific track (for dual-song deck routing).
function launchClipOnTrack(trackPath, chop) {
    if (!liveApi || !trackPath) return;
    var clipSlot = chop.column - 1;
    try {
        var csApi = new LiveAPI(trackPath + " clip_slots " + clipSlot);
        csApi.call("fire");
    } catch (e) {
        post("setforge-loader: deck launch error: " + e + "\n");
    }
}

function stopClipOnTrack(trackPath, col) {
    if (!liveApi || !trackPath) return;
    var clipSlot = col - 1;
    try {
        var csApi = new LiveAPI(trackPath + " clip_slots " + clipSlot);
        csApi.call("stop");
    } catch (e) {
        post("setforge-loader: deck stop error: " + e + "\n");
    }
}

// ═══════════════════════════════════════════════════════════
//  Manifest / Set Loading
// ═══════════════════════════════════════════════════════════

var manifest = null;
var setData = null;
var manifestFilePath = null;

function resolveManifestPaths(mf, baseDir) {
    var tracks = mf && mf.tracks ? mf.tracks : (Array.isArray(mf) ? mf : []);
    var resolved = 0;
    for (var t = 0; t < tracks.length; t++) {
        var stems = tracks[t].stems;
        if (!stems) continue;
        for (var sn in stems) {
            if (!stems.hasOwnProperty(sn)) continue;
            var stem = stems[sn];
            if (stem.path && stem.path.charAt(0) !== "/") {
                stem.path = baseDir + stem.path;
                resolved++;
            }
            var chops = stem.chops;
            if (!chops) continue;
            for (var c = 0; c < chops.length; c++) {
                if (chops[c].chop_path && chops[c].chop_path.charAt(0) !== "/") {
                    chops[c].chop_path = baseDir + chops[c].chop_path;
                    resolved++;
                }
            }
        }
    }
    if (resolved > 0) {
        post("setforge-loader: resolved " + resolved + " relative paths against " + baseDir + "\n");
    }
}

// Max file dialogs (the browse… button) hand back HFS-style paths like
// "Macintosh HD:/Users/...". The boot-volume name contains a space, which
// breaks LiveAPI.call("create_audio_clip", path): the call tokenizes its
// argument on the space → "Invalid syntax" → 0 clips created. Normalize any
// HFS path to POSIX so every entry point (browse, UDP load, autowatch reload)
// is space-safe. Maps the boot volume only ("Vol:/rest" → "/rest"); non-boot
// volumes would need "/Volumes/<Vol>/rest" — fine here since sets live on the
// boot volume.
function hfsToPosix(p) {
    if (!p || p.charAt(0) === "/") return p;   // already POSIX (or empty)
    var m = p.match(/^([^\/:]+):\/(.*)$/);      // "<Volume>:/rest"
    return m ? "/" + m[2] : p;
}

function loadSet(path) {
    path = hfsToPosix(path);
    dbg("setforge-loader: loading set from " + path + "\n");

    try {
        var setFile = new File(path, "r");
        if (!setFile.isopen) {
            post("setforge-loader: cannot open set file: " + path + "\n");
            return;
        }
        // Chunked read — Max's readstring caps at ~64KB; a non-chunked read of a
        // large file (e.g. someone points this at a .manifest.json) truncates it
        // and JSON.parse throws a cryptic SyntaxError.
        var setStr = "";
        while (setFile.position < setFile.eof) {
            setStr += setFile.readstring(16384);
        }
        setFile.close();
        setData = JSON.parse(setStr);

        var setDir = path.replace(/[^\/\\]*$/, "");
        var manifestPath = setDir + setData.name + ".manifest.json";
        manifestFilePath = manifestPath;

        var mFile = new File(manifestPath, "r");
        if (!mFile.isopen) {
            post("setforge-loader: cannot open manifest: " + manifestPath + "\n");
            return;
        }
        // Read in chunks — Max's readstring has a ~64KB buffer limit
        var mStr = "";
        var chunkSize = 16384;
        while (mFile.position < mFile.eof) {
            mStr += mFile.readstring(chunkSize);
        }
        mFile.close();
        dbg("setforge-loader: manifest read " + mStr.length + " chars\n");
        manifest = JSON.parse(mStr);

        // Resolve relative paths in the manifest against the set directory.
        // Manifests can use relative paths (e.g. "29679/drums/drums_0_main.wav")
        // for portability — Live's create_audio_clip requires absolute paths,
        // so we resolve them here at load time.
        resolveManifestPaths(manifest, setDir);

        // Always try to init LiveAPI and find/create stem tracks.
        // After autowatch reload, deviceReady is false but LiveAPI still works.
        if (!liveApi) initLiveApi();
        ensureScenes(NUM_CHOPS * 2);
        ensureStemTracks();

        populateBanks();

        updateStatus();
        updateAllPadColors();

        // Remember this path for autowatch re-load
        saveLastSetPath(path);

        dbg("setforge-loader: set loaded (" + (manifest.tracks ? manifest.tracks.length : 0) + " tracks)\n");
        dumpState();
    } catch (e) {
        post("setforge-loader: load error: " + e + "\n");
    }
}

function populateBanks() {
    initPresetBanks();
    stopAllChops();
    initScenes();

    if (!setData || !manifest || !manifest.tracks) return;

    if (setData.preset_bank_A) {
        for (var i = 0; i < Math.min(setData.preset_bank_A.length, SLOTS_PER_BANK); i++) {
            var entry = setData.preset_bank_A[i];
            if (!entry || !entry.track_id) continue;
            var track = resolveTrack(entry.track_id);
            if (!track) {
                presetSlots[i].state = "error";
                continue;
            }
            try {
                var chops = computeTrackChops(track);
                loadPresetSlot(i, entry.track_id, track, chops);
                if (entry.scenes && i === 0) {
                    for (var si = 0; si < Math.min(entry.scenes.length, NUM_SCENES); si++) {
                        if (entry.scenes[si]) {
                            scenes[si] = { state: "built", snapshot: entry.scenes[si] };
                        }
                    }
                }
            } catch (e) {
                post("setforge-loader: error loading slot " + i + ": " + e + "\n");
                presetSlots[i].state = "error";
            }
        }
    }

    if (setData.preset_bank_B) {
        for (var i = 0; i < Math.min(setData.preset_bank_B.length, SLOTS_PER_BANK); i++) {
            var entry = setData.preset_bank_B[i];
            if (!entry || !entry.track_id) continue;
            var track = resolveTrack(entry.track_id);
            if (!track) {
                presetSlots[i + SLOTS_PER_BANK].state = "error";
                continue;
            }
            try {
                var chops = computeTrackChops(track);
                loadPresetSlot(i + SLOTS_PER_BANK, entry.track_id, track, chops);
            } catch (e) {
                presetSlots[i + SLOTS_PER_BANK].state = "error";
            }
        }
    }
}

function resolveTrack(trackId) {
    if (!manifest || !manifest.tracks) return null;
    for (var i = 0; i < manifest.tracks.length; i++) {
        if (manifest.tracks[i].id === trackId) return manifest.tracks[i];
    }
    return null;
}

// ═══════════════════════════════════════════════════════════
//  Pad Color Updates
// ═══════════════════════════════════════════════════════════

function updateAllPadColors() {
    if (singleGridMode) {
        if (viewMode === "performance") {
            updateGrid1Colors();
        } else {
            updateControlViewColors();
        }
        sendSurfaceRgb(1);
    } else {
        updateGrid1Colors();
        updateGrid2Colors();
        sendSurfaceRgb(1);
        sendSurfaceRgb(2);
    }
}

function updateControlViewColors() {
    for (var i = 0; i < 32; i++) {
        var r = Math.floor(i / 8) + 1;
        var c = (i % 8) + 1;
        if (setData && setData.setlist && i < setData.setlist.length) {
            var trackId = setData.setlist[i];
            var track = resolveTrack(trackId);
            if (track) {
                var color = genreColor(track.genre, track.color_hue);
                color = scaleBrightness(color, track.energy || 0.5);
                var inSlot = false;
                for (var si = 0; si < TOTAL_SLOTS; si++) {
                    if (presetSlots[si].trackId === trackId) { inSlot = true; break; }
                }
                if (!inSlot) color = scaleBrightness(color, 0.5);
                surface.queueRgb(1, r, c, color);
            } else {
                surface.queueRgb(1, r, c, STATE_COLORS.empty);
            }
        } else {
            surface.queueRgb(1, r, c, STATE_COLORS.off);
        }
    }

    var targetColors = [
        STEM_COLORS.drums.bright, STEM_COLORS.bass.bright,
        STEM_COLORS.other.bright, STEM_COLORS.vox.bright,
        [127, 127, 127], [127, 127, 0], [127, 127, 0], [127, 0, 0]
    ];
    var targetIdx = FX_TARGETS.indexOf(fxTarget);
    for (var c = 1; c <= 8; c++) {
        var isBright = (c - 1 === targetIdx);
        var tc = targetColors[c - 1];
        surface.queueRgb(1, 5, c, isBright ? tc : scaleBrightness(tc, 0.3));
    }

    for (var c = 1; c <= 8; c++) {
        var isActive = (c === fxFilterCol);
        if (isActive && fxFilterLatched) surface.queueRgb(1, 6, c, [127, 127, 127]);
        else if (isActive) surface.queueRgb(1, 6, c, [64, 64, 64]);
        else surface.queueRgb(1, 6, c, [16, 16, 16]);
    }

    for (var c = 1; c <= 8; c++) {
        surface.queueRgb(1, 7, c, (c === fxThrowCol) ? [127, 80, 0] : [16, 16, 16]);
    }

    for (var c = 1; c <= 8; c++) {
        var scene = scenes[c - 1];
        surface.queueRgb(1, 8, c, SCENE_COLORS[scene.state] || SCENE_COLORS.empty);
    }
}

function updateGrid1Colors() {
    if (dualSongActive) {
        updateDualSongColors();
        return;
    }

    var active = getActivePreset();

    // Rows 1-4: stems (drums, bass, other, vox)
    for (var r = 1; r <= 4; r++) {
        var stem = ROW_STEM[r];
        for (var c = 1; c <= 8; c++) {
            surface.queueRgb(1, r, c, chopPadColor(stem, c, active));
        }
    }

    // Row 5: bank A presets (slots 0-7)
    // Collect flash SysEx for staged pads (sent after RGB flush)
    var pendingFlash = [];
    for (var c = 1; c <= 8; c++) {
        var slotIdx = c - 1;
        var slot = presetSlots[slotIdx];
        var isStaged = (staging.deckX === slotIdx);
        var isActive = (slot.state === "loaded_active");

        if (isStaged && !isActive) {
            // MK2 native flash: preset color ↔ white
            var presetPalIdx = PRESET_PALETTE_INDICES[slotIdx % PRESET_PALETTE_INDICES.length];
            var padNote = surface.rowColToNote(5, c);
            pendingFlash.push(surface.buildFlashSysex(padNote, presetPalIdx, MK2_PALETTE.WHITE));
            // Still set base RGB (flash overrides it, but clearing needs a base)
            surface.queueRgb(1, 5, c, presetSlotColor(slot));
        } else {
            surface.queueRgb(1, 5, c, presetSlotColor(slot));
        }
    }

    // Row 6: bank B presets (slots 8-15)
    for (var c = 1; c <= 8; c++) {
        var slotIdx = c - 1 + SLOTS_PER_BANK;
        var slot = presetSlots[slotIdx];
        var isStaged = (staging.deckY === slotIdx);
        var isActive = (slot.state === "loaded_active");

        if (isStaged && !isActive) {
            // MK2 native flash: preset color ↔ soft blue
            var presetPalIdx = PRESET_PALETTE_INDICES[(slotIdx - SLOTS_PER_BANK) % PRESET_PALETTE_INDICES.length];
            var padNote = surface.rowColToNote(6, c);
            pendingFlash.push(surface.buildFlashSysex(padNote, presetPalIdx, MK2_PALETTE.SOFT_BLUE));
            surface.queueRgb(1, 6, c, presetSlotColor(slot));
        } else {
            surface.queueRgb(1, 6, c, presetSlotColor(slot));
        }
    }

    // Row 7: modifiers
    for (var c = 1; c <= 8; c++) {
        var mod = MODIFIERS[c - 1];
        var ms = modState[mod] || "idle";
        surface.queueRgb(1, 7, c, MOD_COLORS[ms] || MOD_COLORS.idle);
    }

    // Row 8: scenes
    for (var c = 1; c <= 8; c++) {
        var scene = scenes[c - 1];
        surface.queueRgb(1, 8, c, SCENE_COLORS[scene.state] || SCENE_COLORS.empty);
    }

    // Queue flash SysEx for staged pads (sent after RGB flush in sendSurfaceRgb)
    pendingFlashMessages = pendingFlash;

    // Refresh the dual-song toggle side button LED so it reflects staging state.
    updateDualSongToggleLed();
}

function updateDualSongColors() {
    // Dual-song mode: all 8 rows are stems
    // Rows 1-4: deck X stems, rows 5-8: deck Y stems
    for (var r = 1; r <= 8; r++) {
        var deck, stemIdx;
        if (r <= 4) {
            deck = "deckX";
            stemIdx = r - 1;
        } else {
            deck = "deckY";
            stemIdx = r - 5;
        }
        var stem = STEM_NAMES[stemIdx];
        var presetIdx = loadedDecks[deck];
        var slot = (presetIdx !== null && presetIdx >= 0) ? presetSlots[presetIdx] : null;

        for (var c = 1; c <= 8; c++) {
            if (!slot || !slot.chops || !slot.chops[stem]) {
                surface.queueRgb(1, r, c, STATE_COLORS.off);
                continue;
            }
            var chopList = slot.chops[stem];
            var chop = null;
            for (var i = 0; i < chopList.length; i++) {
                if (chopList[i].column === c) { chop = chopList[i]; break; }
            }
            if (!chop) {
                surface.queueRgb(1, r, c, STATE_COLORS.off);
            } else if (chop.disabled) {
                surface.queueRgb(1, r, c, STATE_COLORS.disabled);
            } else {
                var dualKey = deck + "_" + stem;
                var isPlaying = (dualSongPlaying[dualKey] === c);
                surface.queueRgb(1, r, c, isPlaying ? STEM_COLORS[stem].bright : STEM_COLORS[stem].soft);
            }
        }
    }
}

function updateGrid2Colors() {
    for (var i = 0; i < 32; i++) {
        var r = Math.floor(i / 8) + 1;
        var c = (i % 8) + 1;
        if (setData && setData.setlist && i < setData.setlist.length) {
            var trackId = setData.setlist[i];
            var track = resolveTrack(trackId);
            if (track) {
                var color = genreColor(track.genre, track.color_hue);
                color = scaleBrightness(color, track.energy || 0.5);
                var inSlot = false;
                for (var si = 0; si < TOTAL_SLOTS; si++) {
                    if (presetSlots[si].trackId === trackId) { inSlot = true; break; }
                }
                if (!inSlot) color = scaleBrightness(color, 0.5);
                surface.queueRgb(2, r, c, color);
            } else {
                surface.queueRgb(2, r, c, STATE_COLORS.empty);
            }
        } else {
            surface.queueRgb(2, r, c, STATE_COLORS.off);
        }
    }

    var targetColors = [
        STEM_COLORS.drums.bright, STEM_COLORS.bass.bright,
        STEM_COLORS.other.bright, STEM_COLORS.vox.bright,
        [127, 127, 127], [127, 127, 0], [127, 127, 0], [127, 0, 0]
    ];
    var targetIdx = FX_TARGETS.indexOf(fxTarget);
    for (var c = 1; c <= 8; c++) {
        var isBright = (c - 1 === targetIdx);
        var tc = targetColors[c - 1];
        surface.queueRgb(2, 5, c, isBright ? tc : scaleBrightness(tc, 0.3));
    }

    for (var c = 1; c <= 8; c++) {
        var isActive = (c === fxFilterCol);
        if (isActive && fxFilterLatched) {
            surface.queueRgb(2, 6, c, [127, 127, 127]);
        } else if (isActive) {
            surface.queueRgb(2, 6, c, [64, 64, 64]);
        } else {
            surface.queueRgb(2, 6, c, [16, 16, 16]);
        }
    }

    for (var c = 1; c <= 8; c++) {
        surface.queueRgb(2, 7, c, (c === fxThrowCol) ? [127, 80, 0] : [16, 16, 16]);
    }

    var transportColors = [
        [64, 64, 64], [64, 64, 64], [40, 40, 64], [40, 40, 64],
        [64, 64, 40], [64, 64, 40], [127, 0, 0], [127, 0, 0]
    ];
    for (var c = 1; c <= 8; c++) {
        surface.queueRgb(2, 8, c, transportColors[c - 1]);
    }
}

function presetSlotColor(slot) {
    if (slot.state === "empty") return STATE_COLORS.empty;
    if (slot.state === "error") return STATE_COLORS.error;
    if (slot.state === "loading") return [64, 64, 64];
    var color = presetColor(slot.index);
    if (slot.state === "loaded_active") return color;
    return scaleBrightness(color, 0.4);
}

function chopPadColor(stem, col, activeSlot) {
    // In per-row mode, use the row's own source preset
    var slot = activeSlot;
    if (performanceView === "perRow" && rowSources[stem] !== null) {
        var idx = rowSources[stem];
        if (idx >= 0 && idx < presetSlots.length) {
            slot = presetSlots[idx];
        }
    }
    if (!slot || !slot.chops || !slot.chops[stem]) return STATE_COLORS.off;
    var chopList = slot.chops[stem];
    var chop = null;
    for (var i = 0; i < chopList.length; i++) {
        if (chopList[i].column === col) { chop = chopList[i]; break; }
    }
    if (!chop) return STATE_COLORS.off;
    if (chop.disabled) return STATE_COLORS.disabled;
    if (playingChops[stem] === col) return STEM_COLORS[stem].bright;

    // Per-row mode: leftmost pad (col 1) shows source-preset color
    if (performanceView === "perRow" && col === 1 && rowSources[stem] !== null) {
        return presetColor(rowSources[stem]);
    }

    return STEM_COLORS[stem].soft;
}

function presetColor(slotIndex) {
    return PRESET_PALETTE[slotIndex % PRESET_PALETTE.length];
}

function genreColor(genre, colorHue) {
    if (GENRE_COLORS[genre]) return GENRE_COLORS[genre];
    if (colorHue) return hexToRgb7(colorHue);
    return STATE_COLORS.empty;
}

function hexToRgb7(hex) {
    if (!hex) return STATE_COLORS.empty;
    var clean = hex.replace("#", "");
    if (clean.length !== 6) return STATE_COLORS.empty;
    return [
        Math.round(parseInt(clean.substr(0, 2), 16) / 2),
        Math.round(parseInt(clean.substr(2, 2), 16) / 2),
        Math.round(parseInt(clean.substr(4, 2), 16) / 2)
    ];
}

function scaleBrightness(rgb, energy) {
    var e = Math.max(0, Math.min(1, energy || 0));
    var minScale = 0.3;
    var scale = minScale + (1 - minScale) * e;
    return [
        Math.round(rgb[0] * scale),
        Math.round(rgb[1] * scale),
        Math.round(rgb[2] * scale)
    ];
}

// ═══════════════════════════════════════════════════════════
//  Status Display
// ═══════════════════════════════════════════════════════════

function updateStatus() {
    var bankA = "";
    for (var i = 0; i < SLOTS_PER_BANK; i++) {
        var s = presetSlots[i];
        bankA += (s.trackId ? s.trackId.substr(0, 8) : "_");
        if (i < SLOTS_PER_BANK - 1) bankA += " \u00b7 ";
    }
    outlet(3, "set", "status-bankA", "bank A: " + bankA);

    var bankB = "";
    for (var i = 0; i < SLOTS_PER_BANK; i++) {
        var s = presetSlots[i + SLOTS_PER_BANK];
        bankB += (s.trackId ? s.trackId.substr(0, 8) : "_");
        if (i < SLOTS_PER_BANK - 1) bankB += " \u00b7 ";
    }
    outlet(3, "set", "status-bankB", "bank B: " + bankB);

    var active = getActivePreset();
    outlet(3, "set", "status-active", "active preset: " + (active ? active.trackId : "\u2014"));
    outlet(3, "set", "status-scene", "active scene: " +
        (lastTriggeredScene >= 0 ? String.fromCharCode(65 + lastTriggeredScene) : "\u2014"));
    outlet(3, "set", "status-fxtarget", "fx target: " + fxTarget);
    updatePanelPresets();
}

// Live preset glow: color each panel preset button by its loaded source color
// (active slot = brightest). Empty slots keep the static per-bank tint.
// Direct getnamed/message — guarded so it no-ops headlessly.
// Cache the panel preset objects (getnamed once) so the refresh tick is cheap.
var _sfPresetObjs = null;
function sfPresetObj(i) {
    if (!SF_PATCHER || typeof SF_PATCHER.getnamed !== "function") return null;
    if (!_sfPresetObjs) {
        _sfPresetObjs = [];
        for (var k = 0; k < TOTAL_SLOTS; k++) {
            var b = (k < SLOTS_PER_BANK) ? "A" : "B";
            var o = null;
            try { o = SF_PATCHER.getnamed("preset_" + b + ((k % SLOTS_PER_BANK) + 1)); } catch (e) {}
            _sfPresetObjs.push(o);
        }
    }
    return _sfPresetObjs[i];
}

function updatePanelPresets() {
    if (!SF_PATCHER || typeof SF_PATCHER.getnamed !== "function") return;
    var TINT = { A: [0.961, 0.651, 0.137], B: [0.204, 0.784, 0.910] };
    for (var i = 0; i < presetSlots.length; i++) {
        var slot = presetSlots[i];
        var bank = (i < SLOTS_PER_BANK) ? "A" : "B";
        var obj = sfPresetObj(i);
        if (!obj) continue;
        // "loaded" = the slot has a track. Use trackId (stable) rather than the
        // transient state, which flickers through stage/commit and was making the
        // fill vanish a moment after activation.
        var loaded = !!slot.trackId;
        // Active = the live preset on either deck (one per bank — always-dual).
        var active = (i === lastActiveBankA) || (i === lastActiveBankB) ||
                     (i === loadedDecks.deckX) || (i === loadedDecks.deckY) ||
                     (slot.state === "loaded_active");
        var c, bgA, bdA;
        if (loaded) {
            var rgb = presetColor(i);
            c = [rgb[0] / 127, rgb[1] / 127, rgb[2] / 127];
            bgA = active ? 0.72 : 0.30;   // filled when loaded; brightest when active
            bdA = active ? 1.0 : 0.6;
        } else {
            c = TINT[bank]; bgA = 0.05; bdA = 0.22;
        }
        try {
            obj.message("bgcolor", c[0], c[1], c[2], bgA);
            obj.message("bordercolor", c[0], c[1], c[2], bdA);
        } catch (e) {}
    }
}

// Re-assert preset colors on a fast tick. live.text is a parameter object, so
// Live repaints it from its STORED color on hover — wiping the runtime color.
// Re-applying restores it within a frame (no-op when already correct).
var sfColorTask = null;
function startColorRefresh() {
    if (typeof Task === "undefined") return;
    try {
        if (sfColorTask) sfColorTask.cancel();
        sfColorTask = new Task(function() {
            updatePanelPresets();
            sfColorTask.schedule(80);
        });
        sfColorTask.schedule(80);
    } catch (e) {}
}

// ═══════════════════════════════════════════════════════════
//  MIDI Input Handling
// ═══════════════════════════════════════════════════════════

var midiBytes1 = [];
var midiBytes2 = [];

// ── Aftertouch pressure state ──
// Stores normalized 0–1 pressure per pad (poly AT) or per grid (channel AT).
// Consumed by the punch-FX system (Phase 1) to drive effect amount.
// TODO: confirm on hardware — which AT message the Pro MK2 sends in programmer
// mode (poly key pressure 0xA0, channel pressure 0xD0, or both).
var padPressure = {};

function handlePolyAftertouch(grid, note, pressure) {
    var normalized = pressure / 127;
    padPressure[grid + ":" + note] = normalized;
    post("setforge-loader: poly-AT grid=" + grid + " note=" + note + " pressure=" + normalized.toFixed(3) + "\n");
}

function handleChannelPressure(grid, pressure) {
    var normalized = pressure / 127;
    padPressure[grid + ":ch"] = normalized;
    post("setforge-loader: channel-AT grid=" + grid + " pressure=" + normalized.toFixed(3) + "\n");
}

function getPadPressure(grid, note) {
    // Poly AT takes precedence; fall back to channel AT for the grid
    var polyKey = grid + ":" + note;
    if (padPressure[polyKey] !== undefined) return padPressure[polyKey];
    var chKey = grid + ":ch";
    if (padPressure[chKey] !== undefined) return padPressure[chKey];
    return 0;
}

// ── Remote command interface (file-based) ──
// External tools write a command to /tmp/setforge_cmd.txt
// A polling Task checks for it every 500ms and executes it.
var CMD_FILE = "/tmp/setforge_cmd.txt";
var cmdPollTask = null;

function pollCommandFile() {
    try {
        var f = new File(CMD_FILE, "r");
        if (!f.isopen) return;
        var content = "";
        while (f.position < f.eof) {
            content += f.readstring(1024);
        }
        f.close();

        if (!content || content.length === 0) return;

        // Clear the file so we don't re-execute
        var del = new File(CMD_FILE, "w");
        if (del.isopen) { del.eof = 0; del.writestring(""); del.close(); }

        content = content.replace(/[\r\n\0]/g, "").trim();
        if (content.length > 0) {
            post("setforge-loader: remote cmd: " + content + "\n");
            var parts = content.split(" ");
            handleMessage(parts[0], parts.slice(1));
        }
    } catch (e) {
        post("setforge-loader: pollCmd error: " + e + "\n");
    }
}

function startCmdPoll() {
    if (cmdPollTask) cmdPollTask.cancel();
    cmdPollTask = new Task(function() {
        pollCommandFile();
        cmdPollTask.schedule(500);
    });
    cmdPollTask.schedule(500);
    dbg("setforge-loader: command poll started (/tmp/setforge_cmd.txt)\n");
}

function msg_int(v) {
    var inletIdx = inlet;
    if (inletIdx === 0) {
        processMidiByte(v, 1, midiBytes1);
    } else if (inletIdx === 1) {
        processMidiByte(v, 2, midiBytes2);
    }
}

function processMidiByte(b, grid, buffer) {
    if (b >= 128) {
        buffer.length = 0;
        buffer.push(b);
        return;
    }
    buffer.push(b);
    if (buffer.length < 2) return;

    var status = buffer[0] & 0xF0;
    var channel = buffer[0] & 0x0F;

    if (status === 0x90 && buffer.length >= 3) {
        var note = buffer[1];
        var vel = buffer[2];
        if (vel > 0) handleNoteOn(grid, note, vel);
        else handleNoteOff(grid, note);
        buffer.length = 0;
        buffer.push(status | channel);
    } else if (status === 0x80 && buffer.length >= 3) {
        handleNoteOff(grid, buffer[1]);
        buffer.length = 0;
        buffer.push(status | channel);
    } else if (status === 0xB0 && buffer.length >= 3) {
        // Control Change — used by UAT runner to invoke handleMessage commands
        // deterministically (replaces the flaky /tmp/setforge_cmd.txt poll).
        handleControlChange(buffer[1], buffer[2]);
        buffer.length = 0;
        buffer.push(status | channel);
    } else if (status === 0xA0 && buffer.length >= 3) {
        // Polyphonic Key Pressure (aftertouch) — 3 bytes: status, note, pressure
        // TODO: confirm on hardware — Pro MK2 may send this for per-pad pressure
        handlePolyAftertouch(grid, buffer[1], buffer[2]);
        buffer.length = 0;
        buffer.push(status | channel);
    } else if (status === 0xD0 && buffer.length >= 2) {
        // Channel Pressure (aftertouch) — 2 bytes: status, pressure
        // TODO: confirm on hardware — Pro MK2 may send this instead of poly AT
        handleChannelPressure(grid, buffer[1]);
        buffer.length = 0;
        buffer.push(status | channel);
    }
}

// ── Remote command CC map ──
// External tools (the UAT harness, scripts) trigger handleMessage commands by
// sending MIDI CCs on the loader's grid input. CC value 127 = invoke; CC 0 =
// no-op (so the trailing CC release event from a Python helper is harmless).
//
// Pick numbers in the unassigned/general-purpose range so they don't collide
// with standard MIDI semantics. Adjust here if any grid hardware sends these.
var REMOTE_CC_MAP = {
    100: "save",
    101: "sync",
    102: "inspect",
    103: "panic",
    104: "eject",
    105: "reload",
    106: "debug",
    107: "save_manifest",
    108: "save_set"
};

function handleControlChange(cc, value) {
    if (value === 0) return;  // release / off
    var cmd = REMOTE_CC_MAP[cc];
    if (!cmd) return;
    post("setforge-loader: remote cc " + cc + " → " + cmd + "\n");
    handleMessage(cmd, []);
}

function rightSideButtonIndex(note) {
    return SIDE_BUTTONS_RIGHT.indexOf(note);
}

function handleNoteOn(grid, note, velocity) {
    // (Remote commands now arrive as MIDI CCs via handleControlChange,
    // not via /tmp/setforge_cmd.txt file polling. See REMOTE_CC_MAP.)

    // Check for left side buttons via surface
    var sideIdx = surface.sideButtonIndex(note);
    if (sideIdx >= 0) {
        handleSideButtonPress(sideIdx);
        return;
    }

    // Check for right side buttons
    var rightIdx = rightSideButtonIndex(note);
    if (rightIdx >= 0) {
        handleRightSideButtonPress(rightIdx);
        return;
    }

    var pos = surface.noteToRowCol(note);
    if (!pos) return;

    if (singleGridMode && viewMode === "control") {
        if (pos.row === 8) {
            handleGrid1Press(pos.row, pos.col);
        } else {
            handleGrid2Press(pos.row, pos.col);
        }
    } else if (grid === 1) {
        handleGrid1Press(pos.row, pos.col);
    } else {
        handleGrid2Press(pos.row, pos.col);
    }
}

function handleNoteOff(grid, note) {
    var sideIdx = surface.sideButtonIndex(note);
    if (sideIdx >= 0) {
        handleSideButtonRelease(sideIdx);
        return;
    }

    var rightIdx = rightSideButtonIndex(note);
    if (rightIdx >= 0) {
        handleRightSideButtonRelease(rightIdx);
        return;
    }

    var pos = surface.noteToRowCol(note);
    if (!pos) return;

    if (singleGridMode && viewMode === "control") {
        if (pos.row === 8) {
            handleGrid1Release(pos.row, pos.col);
        } else {
            handleGrid2Release(pos.row, pos.col);
        }
    } else if (grid === 1) {
        handleGrid1Release(pos.row, pos.col);
    } else {
        handleGrid2Release(pos.row, pos.col);
    }
}

// ═══════════════════════════════════════════════════════════
//  Side Button Handlers (single-grid transport)
// ═══════════════════════════════════════════════════════════

function handleSideButtonPress(sideIdx) {
    var func = SIDE_FUNC[sideIdx];

    if (func === "MODE_TOGGLE") {
        var now = Date.now();
        var delta = now - viewModeLastPress;
        if (delta < DOUBLE_TAP_WINDOW_MS && delta > 0) {
            viewModeLatched = !viewModeLatched;
            post("setforge-loader: view mode " + (viewModeLatched ? "latched" : "unlatched") + " to " + viewMode + "\n");
        } else {
            if (!viewModeLatched) {
                viewMode = (viewMode === "performance") ? "control" : "performance";
                post("setforge-loader: view mode -> " + viewMode + " (momentary)\n");
            }
        }
        viewModeLastPress = now;
        updateAllPadColors();
    } else if (func === "TAP") {
        outlet(2, "tap_tempo");
    } else if (func === "SYNC") {
        outlet(2, "sync");
    } else if (func === "BPM_DOWN") {
        outlet(2, "bpm_nudge", -0.1);
    } else if (func === "BPM_UP") {
        outlet(2, "bpm_nudge", 0.1);
    } else if (func === "LOOP_IN") {
        outlet(2, "loop_in");
    } else if (func === "LOOP_OUT") {
        outlet(2, "loop_out");
    } else if (func === "PANIC") {
        var now = Date.now();
        if (now - panicLastTap > 1000) panicTapCount = 1;
        else panicTapCount++;
        panicLastTap = now;
        if (panicTapCount >= 3) {
            executePanic();
            panicTapCount = 0;
        } else {
            post("setforge-loader: panic " + panicTapCount + "/3\n");
        }
    }
}

function handleSideButtonRelease(sideIdx) {
    var func = SIDE_FUNC[sideIdx];
    if (func === "MODE_TOGGLE" && !viewModeLatched) {
        viewMode = "performance";
        post("setforge-loader: view mode -> performance (released)\n");
        updateAllPadColors();
    }
}

// ═══════════════════════════════════════════════════════════
//  Right Side Button Handlers
// ═══════════════════════════════════════════════════════════

function handleRightSideButtonPress(rightIdx) {
    var func = SIDE_FUNC_RIGHT[rightIdx];

    if (func === "DUAL_SONG_TOGGLE") {
        var now = Date.now();
        var delta = now - dualSongLastPress;
        if (delta < DOUBLE_TAP_WINDOW_MS && delta > 0) {
            // Double-tap: latch
            dualSongLatched = !dualSongLatched;
            if (dualSongLatched && !dualSongActive) {
                enterDualSongMode(true);
            } else if (!dualSongLatched && dualSongActive) {
                exitDualSongMode();
            }
        } else {
            // Single tap: momentary peek
            if (!dualSongActive && !dualSongLatched) {
                enterDualSongMode(false);
            } else if (dualSongLatched && dualSongActive) {
                // Tap while latched: unlatch and exit
                dualSongLatched = false;
                exitDualSongMode();
            }
        }
        dualSongLastPress = now;
    } else if (func === "DECK_SETUP") {
        staging.stagingHeld = true;
        dbg("setforge-loader: staging mode entered\n");
        // Light the side button bright white per spec §5.1
        surface.queueRgbNote(1, SIDE_BUTTONS_RIGHT[rightIdx], [127, 127, 127]);
        updateAllPadColors();
        sendSurfaceRgb(1);
    }
}

function handleRightSideButtonRelease(rightIdx) {
    var func = SIDE_FUNC_RIGHT[rightIdx];

    if (func === "DUAL_SONG_TOGGLE") {
        // Release: if momentary (not latched), exit dual-song
        if (dualSongActive && !dualSongLatched) {
            exitDualSongMode();
        }
    } else if (func === "DECK_SETUP") {
        staging.stagingHeld = false;
        dbg("setforge-loader: staging mode exited\n");
        // Dim the side button back down — color reflects staging state
        surface.queueRgbNote(1, SIDE_BUTTONS_RIGHT[rightIdx], deckSetupIdleColor());
        updateAllPadColors();
        sendSurfaceRgb(1);
    }
}

// While held: full white. Released, decks staged: dim white (low signal).
// Released, no staging: off. Independent of dual-song toggle visual.
function deckSetupIdleColor() {
    var hasStage = (staging.deckX !== null) || (staging.deckY !== null);
    return hasStage ? [16, 16, 16] : [0, 0, 0];
}

// Top-right side button visual:
// - Both decks staged: solid dim white (full alternation flash deferred)
// - One deck staged:   solid dim white
// - Neither staged:    off
// Called from updateAllPadColors / dual-song entry/exit / staging changes.
function updateDualSongToggleLed() {
    var anyStaged = (staging.deckX !== null) || (staging.deckY !== null);
    var color;
    if (dualSongActive) {
        color = [127, 127, 127];     // bright white when in dual-song
    } else if (anyStaged) {
        color = [40, 40, 40];        // mid white when something's staged
    } else {
        color = [0, 0, 0];           // off
    }
    surface.queueRgbNote(1, SIDE_BUTTONS_RIGHT[0], color);
}

// Flash a side button red for ~500ms, then revert to dim white.
function flashSideButtonRed(sideNote) {
    surface.queueRgbNote(1, sideNote, STATE_COLORS.error);
    sendSurfaceRgb(1);
    var revertTask = new Task(function() {
        surface.queueRgbNote(1, sideNote, [8, 8, 8]); // dim white
        sendSurfaceRgb(1);
    });
    revertTask.schedule(500);
}

function enterDualSongMode(latched) {
    // Resolve deck sources
    var deckX = staging.deckX !== null ? staging.deckX : lastActiveBankA;
    var deckY = staging.deckY !== null ? staging.deckY : lastActiveBankB;

    if (deckX === null && deckY === null) {
        post("setforge-loader: dual-song entry failed — no decks\n");
        flashSideButtonRed(SIDE_BUTTONS_RIGHT[0]); // dual-song toggle = note 89
        return;
    }

    if (deckX === null || deckY === null) {
        var missing = (deckX === null) ? "deckX" : "deckY";
        post("setforge-loader: dual-song entry failed — " + missing + " unresolved\n");
        flashSideButtonRed(SIDE_BUTTONS_RIGHT[0]); // dual-song toggle = note 89
        return;
    }

    preDualSongView = performanceView;
    dualSongActive = true;
    dualSongLatched = latched;
    loadedDecks.deckX = deckX;
    loadedDecks.deckY = deckY;

    post("setforge-loader: entered dual-song mode (X=" + deckX + ", Y=" + deckY + ")\n");
    updateAllPadColors();
    sendSurfaceRgb(1);
}

function exitDualSongMode() {
    dualSongActive = false;
    performanceView = preDualSongView || "solo";
    post("setforge-loader: exited dual-song mode → " + performanceView + "\n");
    updateAllPadColors();
    sendSurfaceRgb(1);
}

// ═══════════════════════════════════════════════════════════
//  Grid 1 Event Handlers
// ═══════════════════════════════════════════════════════════

function handleGrid1Press(row, col) {
    if (dualSongActive) {
        // In dual-song mode: all 8 rows are stems
        if (row >= 1 && row <= 8) {
            onDualSongChopPress(row, col);
        }
        return;
    }

    if (row >= 1 && row <= 4) {
        heldPads[row + "," + col] = true;

        // In per-row mode: check if this is hold-chop + tap-preset
        // (The actual reassignment happens in onPresetPress when it
        //  detects held stem pads)
        onChopPress(row, col);
    } else if (row === 5) {
        if (staging.stagingHeld) {
            // Staging gesture: assign deck X from bank A
            onStageDeck("deckX", col - 1);
        } else if (performanceView === "perRow" && hasHeldStemPad()) {
            onPerRowReassign(col - 1);
        } else {
            onPresetPress(col - 1);
        }
    } else if (row === 6) {
        if (staging.stagingHeld) {
            // Staging gesture: assign deck Y from bank B
            onStageDeck("deckY", col - 1 + SLOTS_PER_BANK);
        } else if (performanceView === "perRow" && hasHeldStemPad()) {
            onPerRowReassign(col - 1 + SLOTS_PER_BANK);
        } else {
            onPresetPress(col - 1 + SLOTS_PER_BANK);
        }
    } else if (row === 7) {
        var modIndex = col - 1;
        pressModifier(modIndex, Date.now());

        // Check for SOLO double-tap → per-row mode toggle
        if (modIndex === 2 && modState.SOLO === "latched") {
            togglePerRowMode();
        }

        updateGrid1Colors();
        sendSurfaceRgb(1);
    } else if (row === 8) {
        onScenePress(col - 1);
    }
}

function handleGrid1Release(row, col) {
    if (row >= 1 && row <= 4) {
        delete heldPads[row + "," + col];
    }
    if (row === 7) {
        releaseModifier(col - 1);
        updateGrid1Colors();
        sendSurfaceRgb(1);
    }
    // Staging: release deck-setup side button handled in handleSideButtonRelease
}

// ═══════════════════════════════════════════════════════════
//  Per-Row Mode
// ═══════════════════════════════════════════════════════════

function togglePerRowMode() {
    if (performanceView === "solo") {
        // Enter per-row mode
        performanceView = "perRow";
        // Initialize rowSources to all pointing at current active preset
        for (var i = 0; i < STEM_NAMES.length; i++) {
            rowSources[STEM_NAMES[i]] = activeSlotIndex;
        }
        post("setforge-loader: entered per-row mode\n");
    } else if (performanceView === "perRow") {
        // Exit per-row mode
        // activePreset becomes whatever drums row's source was
        var drumsSource = rowSources.drums;
        if (drumsSource !== null && drumsSource >= 0) {
            activatePreset(drumsSource);
        }
        performanceView = "solo";
        modState.SOLO = "idle";
        post("setforge-loader: exited per-row mode\n");
    }
    updateAllPadColors();
}

function hasHeldStemPad() {
    for (var key in heldPads) {
        if (heldPads.hasOwnProperty(key)) {
            var parts = key.split(",");
            var r = parseInt(parts[0]);
            if (r >= 1 && r <= 4) return true;
        }
    }
    return false;
}

function getHeldStemRows() {
    var rows = {};
    for (var key in heldPads) {
        if (heldPads.hasOwnProperty(key)) {
            var parts = key.split(",");
            var r = parseInt(parts[0]);
            if (r >= 1 && r <= 4) {
                rows[ROW_STEM[r]] = true;
            }
        }
    }
    return rows;
}

function onPerRowReassign(slotIndex) {
    var slot = presetSlots[slotIndex];
    if (!slot || slot.state === "empty" || slot.state === "loading" || slot.state === "error") return;

    // Find which stem rows have held pads
    var heldRows = getHeldStemRows();
    for (var stem in heldRows) {
        if (heldRows.hasOwnProperty(stem)) {
            var oldSource = rowSources[stem];
            rowSources[stem] = slotIndex;
            post("setforge-loader: per-row reassign " + stem + " → slot " + slotIndex + "\n");

            // Load this stem's clips from the new preset into the stem track
            var trackPath = stemTrackIds[stem];
            var loaded = loadStemClipsToTrack(stem, slotIndex, activeSetOffset(), trackPath);
            post("  per-row: loaded " + loaded + " clips for " + stem + " from slot " + slotIndex + "\n");

            // Deferred warp fix for just this stem
            (function(s, si, o, tp) {
                var fixTask = new Task(function() {
                    fixWarpMarkersForStem(s, si, o, tp);
                });
                fixTask.schedule(4000);
            })(stem, slotIndex, activeSetOffset(), trackPath);

            // Hot-swap: if a chop is held in this row, migrate it
            if (playingChops[stem] >= 1 && oldSource !== slotIndex) {
                var col = playingChops[stem];
                var newStemChops = slot.chops ? slot.chops[stem] : null;
                var newChop = null;
                if (newStemChops) {
                    for (var j = 0; j < newStemChops.length; j++) {
                        if (newStemChops[j].column === col && !newStemChops[j].disabled) {
                            newChop = newStemChops[j];
                            break;
                        }
                    }
                }
                if (newChop) {
                    launchClipInTrack(stem, col - 1, newChop);
                } else {
                    stopClipInTrack(stem, col - 1);
                    playingChops[stem] = -1;
                }
            }
        }
    }
    updateAllPadColors();
    sendSurfaceRgb(1);
}

// Fix warp markers for a single stem on a specific track.
function fixWarpMarkersForStem(stem, presetIdx, offset, trackPath) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops || !slot.chops[stem]) return;

    var trackBpm = (slot.track && slot.track.bpm) ? slot.track.bpm : 0;
    var chopList = slot.chops[stem];
    for (var c = 0; c < chopList.length; c++) {
        var chop = chopList[c];
        if (chop.disabled) continue;
        if (chop.fullVocal) continue; // .asd owns the grid — never re-warp

        var beatCount = chopBeatCount(chop, trackBpm);
        if (beatCount <= 0) {
            post("  " + stem + "[" + c + "]: skipping warp fix (beatCount=0, clipLength=" + chop.clipLength + ", bpm=" + trackBpm + ")\n");
            continue;
        }

        var clipSlot = offset + (chop.column - 1);
        var csPath = trackPath + " clip_slots " + clipSlot;

        try {
            var csApi = new LiveAPI(csPath);
            var hasClip = csApi.get("has_clip");
            if (!hasClip || hasClip.toString() !== "1") continue;

            var clipApi = new LiveAPI(csPath + " clip");
            if (!clipApi || clipApi.id === "0") continue;

            var loopStartSec = chop.clipStart;
            var loopEndSec = chop.clipStart + chop.clipLength;
            var secToBeat = beatCount / (loopEndSec - loopStartSec);

            var existingMarkers = [];
            try {
                var rawWm = clipApi.get("warp_markers");
                if (rawWm && rawWm.length > 0) {
                    var wmStr = (typeof rawWm[0] === "string") ? rawWm[0] : String(rawWm[0]);
                    var wmParsed = JSON.parse(wmStr);
                    if (wmParsed && wmParsed.warp_markers) existingMarkers = wmParsed.warp_markers;
                    else if (wmParsed && wmParsed.length) existingMarkers = wmParsed;
                }
            } catch (_) {}

            for (var ei = 0; ei < existingMarkers.length; ei++) {
                var em = existingMarkers[ei];
                var correctBeat = (em.sample_time - loopStartSec) * secToBeat;
                var delta = correctBeat - em.beat_time;
                if (Math.abs(delta) >= 0.0001) {
                    try { clipApi.call("move_warp_marker", em.beat_time, delta); } catch (_) {}
                }
            }

            clipApi.set("start_marker", 0);
            clipApi.set("end_marker", beatCount);
            clipApi.set("loop_start", 0);
            clipApi.set("loop_end", beatCount);
        } catch (e) {
            post("  " + stem + "[" + c + "]: warp fix error: " + e + "\n");
        }
    }
    post("setforge-loader: per-row warp fix done for " + stem + "\n");
}

// Get the effective preset for a given stem (respects per-row mode)
function getEffectivePreset(stem) {
    if (performanceView === "perRow" && rowSources[stem] !== null) {
        var idx = rowSources[stem];
        if (idx >= 0 && idx < presetSlots.length) {
            return presetSlots[idx];
        }
    }
    return getActivePreset();
}

// ═══════════════════════════════════════════════════════════
//  Dual-Song Mode Chop Press (Phase 4)
// ═══════════════════════════════════════════════════════════

function onDualSongChopPress(row, col) {
    var deck, stem, trackIds;
    if (row >= 1 && row <= 4) {
        deck = "deckX";
        stem = STEM_NAMES[row - 1];
        trackIds = stemTrackIdsX; // deck X uses -x tracks (separate from solo)
    } else {
        deck = "deckY";
        stem = STEM_NAMES[row - 5];
        trackIds = stemTrackIdsY; // deck Y uses -y tracks
    }

    var presetId = loadedDecks[deck];
    if (presetId === null || presetId === undefined) return;

    var slot = (typeof presetId === "number") ? presetSlots[presetId] : null;
    if (!slot || !slot.chops || !slot.chops[stem]) return;

    var chopList = slot.chops[stem];
    var chop = null;
    for (var i = 0; i < chopList.length; i++) {
        if (chopList[i].column === col) { chop = chopList[i]; break; }
    }
    if (!chop || chop.disabled) return;

    var trackPath = trackIds[stem];
    if (!trackPath) return;

    // Composite key for dual-song playing state
    var dualKey = deck + "_" + stem;
    var current = dualSongPlaying[dualKey] || -1;

    var action;
    if (current === col) {
        action = "stop";
        dualSongPlaying[dualKey] = -1;
    } else {
        action = (current >= 1) ? "replace" : "start";
        dualSongPlaying[dualKey] = col;
    }

    if (action === "start" || action === "replace") {
        launchClipOnTrack(trackPath, chop);
        post("setforge-loader: dual-song " + deck + " " + stem + " chop " + col + "\n");
    } else if (action === "stop") {
        stopClipOnTrack(trackPath, col);
    }

    updateAllPadColors();
    sendSurfaceRgb(1);
}

var dualSongPlaying = {};

// ═══════════════════════════════════════════════════════════
//  Staging (Phase 3)
// ═══════════════════════════════════════════════════════════

function onStageDeck(deck, slotIndex) {
    var slot = presetSlots[slotIndex];
    if (!slot || slot.state === "empty" || slot.state === "loading" || slot.state === "error") {
        // Red flash on the staged pad
        var padNote = surface.rowColToNote(slotIndex < SLOTS_PER_BANK ? 5 : 6,
            (slotIndex < SLOTS_PER_BANK ? slotIndex : slotIndex - SLOTS_PER_BANK) + 1);
        surface.queueRgbNote(1, padNote, STATE_COLORS.error);
        sendSurfaceRgb(1);
        var revertTask = new Task(function() {
            surface.queueRgbNote(1, padNote, STATE_COLORS.empty);
            sendSurfaceRgb(1);
        });
        revertTask.schedule(500);
        dbg("setforge-loader: staging " + deck + " failed — empty slot " + slotIndex + "\n");
        return;
    }

    staging[deck] = slotIndex;
    loadedDecks[deck] = slotIndex;

    // Actually pre-load clips into the correct deck's tracks
    if (deck === "deckX") {
        loadPresetToDeckX(slotIndex);
    } else if (deck === "deckY") {
        loadPresetToDeckY(slotIndex);
    }

    post("setforge-loader: staged " + deck + " → slot " + slotIndex + " (" + slot.trackId + ")\n");

    updateAllPadColors();
    sendSurfaceRgb(1);
}

function onPresetPress(slotIndex) {
    var slot = presetSlots[slotIndex];
    if (!slot || slot.state === "empty" || slot.state === "loading" || slot.state === "error") return;

    // Track last-active per bank for dual-song fallback
    if (slotIndex < SLOTS_PER_BANK) {
        lastActiveBankA = slotIndex;
    } else {
        lastActiveBankB = slotIndex;
    }

    // Auto-save disabled — was corrupting the manifest JSON.
    // Use the "save" message to save manually after nudging.
    // TODO: fix saveManifest to write valid compact JSON
    // if (manifestFilePath && activeSlotIndex >= 0) {
    //     saveManifest();
    // }

    var isFirstActivation = (activeSlotIndex < 0);
    var shiftMode = (modState.HOLD === "held" || modState.HOLD === "latched");
    var result = activatePreset(slotIndex);
    if (!result) return;

    if (isFirstActivation) {
        loadClipsForPreset(slotIndex);
    } else if (!shiftMode) {
        stagePreset(slotIndex);

        if (stagingReady) {
            var migrations = hotSwapChops(presetSlots[slotIndex].chops);
            for (var i = 0; i < migrations.length; i++) {
                var m = migrations[i];
                if (m.newChop) {
                    launchStagingClip(m.stem, m.newChop);
                } else {
                    stopClipInTrack(m.stem, m.column - 1);
                }
            }
            commitStagedPreset();
        }
    } else {
        var held = getHeldChops();
        for (var i = 0; i < held.length; i++) {
            stopClipInTrack(held[i].stem, held[i].col - 1);
        }
        stopAllChops();
        stagePreset(slotIndex);
        if (stagingReady) commitStagedPreset();
    }

    // Sync session tempo to the active preset's BPM
    var activePreset = getActivePreset();
    if (activePreset && activePreset.track && activePreset.track.bpm && liveApi) {
        try {
            liveApi.set("tempo", activePreset.track.bpm);
            post("setforge-loader: tempo → " + activePreset.track.bpm.toFixed(1) + "\n");
        } catch (e) {
            post("setforge-loader: tempo set error: " + e + "\n");
        }
    }

    updateAllPadColors();
    updateStatus();
    // inspectClips() is called by the deferred fixWarpMarkers task
}

function onChopPress(row, col) {
    var result = pressChop(row, col);
    if (!result) return;

    if (result.action === "start" || result.action === "replace" || result.action === "one_shot") {
        launchClipInTrack(result.stem, result.column - 1, result.chop);
    } else if (result.action === "stop") {
        stopClipInTrack(result.stem, result.column - 1);
    } else if (result.action === "play_full") {
        launchClipInTrack(result.stem, 0, { clipStart: 0, clipLength: 0 });
    }

    updateGrid1Colors();
    sendSurfaceRgb(1);
}

function onScenePress(sceneIndex) {
    if (modState.HOLD === "held" || modState.HOLD === "latched") {
        saveScene(sceneIndex);
        post("setforge-loader: saved scene " + String.fromCharCode(65 + sceneIndex) + "\n");
    } else {
        var snapshot = recallScene(sceneIndex);
        if (!snapshot) return;

        // Restore view state
        var savedView = snapshot.view || "solo";
        if (savedView === "perRow") {
            performanceView = "perRow";
            modState.SOLO = "latched";
            if (snapshot.rowSources) {
                for (var i = 0; i < STEM_NAMES.length; i++) {
                    var s = STEM_NAMES[i];
                    rowSources[s] = (snapshot.rowSources[s] !== undefined) ? snapshot.rowSources[s] : null;
                }
            }
        } else if (savedView === "dualSong") {
            // Restore staging then enter dual-song
            if (snapshot.stagingDeckX !== undefined) staging.deckX = snapshot.stagingDeckX;
            if (snapshot.stagingDeckY !== undefined) staging.deckY = snapshot.stagingDeckY;
            enterDualSongMode(true);
        } else {
            performanceView = "solo";
            modState.SOLO = "idle";
        }

        if (snapshot.activePresetIndex >= 0 && snapshot.activePresetIndex !== activeSlotIndex) {
            activatePreset(snapshot.activePresetIndex);
        }

        stopAllChops();
        if (snapshot.heldChops) {
            for (var i = 0; i < snapshot.heldChops.length; i++) {
                var hc = snapshot.heldChops[i];
                playingChops[hc.stem] = hc.col;
                var effectiveSlot = getEffectivePreset(hc.stem);
                if (effectiveSlot && effectiveSlot.chops && effectiveSlot.chops[hc.stem]) {
                    var chopList = effectiveSlot.chops[hc.stem];
                    for (var j = 0; j < chopList.length; j++) {
                        if (chopList[j].column === hc.col && !chopList[j].disabled) {
                            launchClipInTrack(hc.stem, hc.col - 1, chopList[j]);
                            break;
                        }
                    }
                }
            }
        }

        if (snapshot.modifiers) restoreModifiers(snapshot.modifiers);

        post("setforge-loader: recalled scene " + String.fromCharCode(65 + sceneIndex) + "\n");
    }

    updateAllPadColors();
    updateStatus();
}

// ═══════════════════════════════════════════════════════════
//  Grid 2 Event Handlers
// ═══════════════════════════════════════════════════════════

function handleGrid2Press(row, col) {
    if (row >= 1 && row <= 4) {
        var trackIndex = (row - 1) * 8 + (col - 1);
        onSetlistTrackPress(trackIndex);
    } else if (row === 5) {
        fxTarget = FX_TARGETS[col - 1] || "all";
        updateGrid2Colors();
        sendSurfaceRgb(2);
        updateStatus();
    } else if (row === 6) {
        var now = Date.now();
        var delta = now - fxFilterLastPress;
        if (fxFilterCol === col && delta < DOUBLE_TAP_WINDOW_MS && delta > 0) {
            fxFilterLatched = true;
        } else {
            fxFilterLatched = false;
        }
        fxFilterCol = col;
        fxFilterLastPress = now;
        updateGrid2Colors();
        sendSurfaceRgb(2);
    } else if (row === 7) {
        fxThrowCol = col;
        updateGrid2Colors();
        sendSurfaceRgb(2);
    } else if (row === 8) {
        onTransportPress(col);
    }
}

function handleGrid2Release(row, col) {
    if (row === 6 && !fxFilterLatched) {
        fxFilterCol = 4;
        updateGrid2Colors();
        sendSurfaceRgb(2);
    } else if (row === 7) {
        fxThrowCol = -1;
        updateGrid2Colors();
        sendSurfaceRgb(2);
    }
}

function onSetlistTrackPress(trackIndex) {
    if (!setData || !setData.setlist || trackIndex >= setData.setlist.length) return;
    var trackId = setData.setlist[trackIndex];
    post("setforge-loader: setlist track: " + trackId + "\n");
}

var panicTapCount = 0;
var panicLastTap = 0;

function onTransportPress(col) {
    if (col === 1) outlet(2, "tap_tempo");
    else if (col === 2) outlet(2, "sync");
    else if (col === 3) outlet(2, "bpm_nudge", -0.1);
    else if (col === 4) outlet(2, "bpm_nudge", 0.1);
    else if (col === 5) outlet(2, "loop_in");
    else if (col === 6) outlet(2, "loop_out");
    else if (col === 7) outlet(2, "record_toggle");
    else if (col === 8) {
        var now = Date.now();
        if (now - panicLastTap > 1000) panicTapCount = 1;
        else panicTapCount++;
        panicLastTap = now;

        if (panicTapCount >= 3) {
            executePanic();
            panicTapCount = 0;
        } else {
            post("setforge-loader: panic " + panicTapCount + "/3\n");
        }
    }
}

// ═══════════════════════════════════════════════════════════
//  Panic
// ═══════════════════════════════════════════════════════════

function executePanic() {
    post("setforge-loader: PANIC\n");
    stopAllChops();
    clearModifiers();
    bypassFx();
    stopAllClips();

    // Reset multi-song state
    if (dualSongActive) {
        dualSongActive = false;
        dualSongLatched = false;
    }
    performanceView = "solo";
    for (var i = 0; i < STEM_NAMES.length; i++) {
        rowSources[STEM_NAMES[i]] = null;
    }
    dualSongPlaying = {};

    updateAllPadColors();
    updateStatus();
}

// ═══════════════════════════════════════════════════════════
//  Downbeat Nudge + Save
// ═══════════════════════════════════════════════════════════

// Nudge active preset's downbeat_sec by delta (seconds).
// Recomputes chops and reloads clips in the active set.
function nudgeDownbeat(delta) {
    var active = getActivePreset();
    if (!active || !active.track) {
        post("setforge-loader: nudge — no active preset\n");
        return;
    }

    var track = active.track;
    var oldDown = track.downbeat_sec || 0;
    track.downbeat_sec = Math.max(0, oldDown + delta);

    // Also update the manifest's copy
    var mTrack = resolveTrack(active.trackId);
    if (mTrack) mTrack.downbeat_sec = track.downbeat_sec;

    // Recompute chops
    active.chops = computeTrackChops(track);

    post("setforge-loader: nudge " + active.trackId +
         " downbeat " + oldDown.toFixed(3) + " → " + track.downbeat_sec.toFixed(3) +
         " (" + (delta >= 0 ? "+" : "") + delta.toFixed(3) + "s)\n");

    // Reload clips
    loadClipsForPreset(active.index);
    updateAllPadColors();
}

// Set the active preset's downbeat_sec to an absolute value.
function setDownbeat(sec) {
    var active = getActivePreset();
    if (!active || !active.track) {
        post("setforge-loader: set_downbeat — no active preset\n");
        return;
    }

    var track = active.track;
    var oldDown = track.downbeat_sec || 0;
    track.downbeat_sec = Math.max(0, sec);

    var mTrack = resolveTrack(active.trackId);
    if (mTrack) mTrack.downbeat_sec = track.downbeat_sec;

    active.chops = computeTrackChops(track);

    post("setforge-loader: set_downbeat " + active.trackId +
         " " + oldDown.toFixed(3) + " → " + track.downbeat_sec.toFixed(3) + "\n");

    loadClipsForPreset(active.index);
    updateAllPadColors();
}

// Set the active preset's BPM.
function setBpm(bpm) {
    var active = getActivePreset();
    if (!active || !active.track) {
        post("setforge-loader: set_bpm — no active preset\n");
        return;
    }

    var track = active.track;
    var oldBpm = track.bpm;
    track.bpm = bpm;

    var mTrack = resolveTrack(active.trackId);
    if (mTrack) mTrack.bpm = bpm;

    active.chops = computeTrackChops(track);

    post("setforge-loader: set_bpm " + active.trackId +
         " " + oldBpm.toFixed(2) + " → " + bpm.toFixed(2) + "\n");

    loadClipsForPreset(active.index);
    updateAllPadColors();
}

// Save manifest back to disk with all modified downbeats/bpms.
// Write a string to a file in chunks (Max's writestring has a ~64KB buffer limit).
function writeStringChunked(filePath, str) {
    var f = new File(filePath, "w");
    if (!f.isopen) {
        post("setforge-loader: cannot open for write: " + filePath + "\n");
        return false;
    }
    f.eof = 0;  // truncate — Max's "w" mode does not by default
    var chunkSize = 16384;
    for (var i = 0; i < str.length; i += chunkSize) {
        f.writestring(str.substring(i, Math.min(i + chunkSize, str.length)));
    }
    f.close();
    return true;
}

function saveManifest() {
    if (!manifest || !manifestFilePath) {
        post("setforge-loader: save — no manifest loaded\n");
        return false;
    }

    try {
        var jsonStr = JSON.stringify(manifest, null, 2);
        if (writeStringChunked(manifestFilePath, jsonStr)) {
            post("setforge-loader: saved manifest (" + jsonStr.length + " bytes) to " + manifestFilePath + "\n");
            return true;
        }
    } catch (e) {
        post("setforge-loader: save manifest error: " + e + "\n");
    }
    return false;
}

function saveSet() {
    if (!setData || !manifestFilePath) {
        post("setforge-loader: save set — no set loaded\n");
        return false;
    }

    // Rebuild set.json from current state
    var bankA = [];
    var bankB = [];
    for (var i = 0; i < SLOTS_PER_BANK; i++) {
        var slotA = presetSlots[i];
        bankA.push(slotA.trackId ? { track_id: slotA.trackId, scenes: [] } : null);
        var slotB = presetSlots[i + SLOTS_PER_BANK];
        bankB.push(slotB.trackId ? { track_id: slotB.trackId, scenes: [] } : null);
    }

    // Save scene snapshots into bank A slot 0 (convention from populateBanks)
    if (bankA[0] && scenes) {
        var sceneData = [];
        for (var si = 0; si < NUM_SCENES; si++) {
            sceneData.push(scenes[si].state !== "empty" ? scenes[si].snapshot : null);
        }
        bankA[0].scenes = sceneData;
    }

    setData.preset_bank_A = bankA;
    setData.preset_bank_B = bankB;

    try {
        var setDir = manifestFilePath.replace(/[^\/\\]*$/, "");
        var setPath = setDir + setData.name + ".set.json";
        var jsonStr = JSON.stringify(setData, null, 2);
        if (writeStringChunked(setPath, jsonStr)) {
            post("setforge-loader: saved set (" + jsonStr.length + " bytes) to " + setPath + "\n");
            return true;
        }
    } catch (e) {
        post("setforge-loader: save set error: " + e + "\n");
    }
    return false;
}

// ═══════════════════════════════════════════════════════════
//  Message Handling (from UI / Max)
// ═══════════════════════════════════════════════════════════

function handleMessage(msg, args) {
    if (msg === "init") {
        doInit();
    } else if (msg === "load") {
        if (args.length > 0) loadSet(args[0]);
        else {
            // No path given (bare UI button press) — fall back to reload
            // behavior: restore the last-loaded set from disk.
            var lastPath = loadLastSetPath();
            if (lastPath) {
                loadSet(hfsToPosix(lastPath));
            } else {
                post("setforge-loader: load — no path given and no last set saved\n");
            }
        }
    } else if (msg === "reload") {
        // Re-READ the saved set from disk (not just re-populate from memory),
        // so reload restores exactly what was last saved. Falls back to an
        // in-memory repopulate only if no saved path is known.
        var reloadPath = loadLastSetPath();
        if (reloadPath) {
            loadSet(reloadPath);
        } else if (setData) {
            populateBanks();
            updateAllPadColors();
            updateStatus();
        } else {
            post("setforge-loader: reload — no saved set path; use 'load <path>'\n");
        }
    } else if (msg === "eject") {
        initPresetBanks();
        stopAllChops();
        initScenes();
        clearModifiers();
        bypassFx();
        stopAllClips();
        manifest = null;
        setData = null;
        updateAllPadColors();
        updateStatus();
        post("setforge-loader: ejected\n");
    } else if (msg === "nudge") {
        // nudge <seconds> — e.g. "nudge 0.05" or "nudge -0.1"
        nudgeDownbeat(args.length > 0 ? parseFloat(args[0]) : 0.05);
    } else if (msg === "set_downbeat") {
        // set_downbeat <seconds> — absolute
        if (args.length > 0) setDownbeat(parseFloat(args[0]));
    } else if (msg === "set_bpm") {
        // set_bpm <bpm> — change active preset's BPM
        if (args.length > 0) setBpm(parseFloat(args[0]));
    } else if (msg === "save") {
        fullSave();
    } else if (msg === "sync") {
        syncFromLive();
    } else if (msg === "save_manifest") {
        saveManifest();
    } else if (msg === "save_set") {
        saveSet();
    } else if (msg === "panic") {
        executePanic();
    } else if (msg === "bar_tick") {
        sendSurfaceRgb(1);
        sendSurfaceRgb(2);
    } else if (msg === "debug") {
        dumpState();
    } else if (msg === "inspect") {
        inspectClips();
    } else if (msg === "activate_preset") {
        // UI-driven preset activation (for curation without Launchpad)
        // — same code path as a pad press on the surface.
        if (args.length > 0) {
            var idx = parseInt(args[0], 10);
            if (!isNaN(idx) && idx >= 0 && idx < TOTAL_SLOTS) {
                onPresetPress(idx);
            } else {
                post("setforge-loader: activate_preset out of range: " + args[0] + "\n");
            }
        }
    }
}

// Max [js] anything() handler — delegates to handleMessage
function anything() {
    var msg = messagename;
    var args = arrayfromargs(arguments);
    handleMessage(msg, args);
}

// ═══════════════════════════════════════════════════════════
//  Inspect — dump detailed clip state from LiveAPI
// ═══════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════
//  Sync From Live — read clip state back into manifest
// ═══════════════════════════════════════════════════════════

function syncFromLive() {
    if (!liveApi || !manifest || !manifest.tracks) {
        post("setforge-loader: sync — no manifest or LiveAPI\n");
        return;
    }

    // Sync the active preset (its clips are currently in the stem tracks)
    var active = getActivePreset();
    if (!active) {
        post("setforge-loader: sync — no active preset\n");
        return;
    }

    var mTrack = resolveTrack(active.trackId);
    if (!mTrack) {
        post("setforge-loader: sync — track not found: " + active.trackId + "\n");
        return;
    }

    var offset = activeSetOffset();
    var synced = syncPresetClips(active, mTrack, offset, stemTrackIds);
    post("setforge-loader: synced " + synced + " clips for " + active.trackId + "\n");

    // Also sync deck X (-x tracks) if staged
    if (loadedDecks.deckX !== null && loadedDecks.deckX !== undefined &&
        loadedDecks.deckX !== presetSlots.indexOf(active)) {
        var deckXSlot = presetSlots[loadedDecks.deckX];
        if (deckXSlot && deckXSlot.trackId) {
            var mTrackX = resolveTrack(deckXSlot.trackId);
            if (mTrackX) {
                var syncedX = syncPresetClips(deckXSlot, mTrackX, 0, stemTrackIdsX);
                post("setforge-loader: synced " + syncedX + " deck-X clips for " + deckXSlot.trackId + "\n");
                synced += syncedX;
            }
        }
    }

    // Also sync deck Y if loaded
    if (loadedDecks.deckY !== null && loadedDecks.deckY !== undefined) {
        var deckYSlot = presetSlots[loadedDecks.deckY];
        if (deckYSlot && deckYSlot.trackId) {
            var mTrackY = resolveTrack(deckYSlot.trackId);
            if (mTrackY) {
                var syncedY = syncPresetClips(deckYSlot, mTrackY, 0, stemTrackIdsY);
                post("setforge-loader: synced " + syncedY + " deck-Y clips for " + deckYSlot.trackId + "\n");
                synced += syncedY;
            }
        }
    }

    return synced;
}

// Parse a clip name's identity prefix "[sf:trackId/stem/IDX] …" → numeric IDX.
// Returns null if the prefix is missing or malformed (legacy / user-renamed).
function parseClipIdentity(name) {
    if (!name) return null;
    var m = String(name).match(/^\[sf:[^\/]+\/[^\/]+\/(\d+)\]/);
    return m ? parseInt(m[1], 10) : null;
}

function syncPresetClips(preset, mTrack, offset, trackIds) {
    var synced = 0;

    post("setforge-loader: syncing clips from Live → manifest for " + preset.trackId + "...\n");

    // ── Safety net: never wipe a whole track on an empty read ──
    // If EVERY stem track reports zero clips at this offset, the read almost
    // certainly hit the wrong slot-set (or Live isn't ready) — a real edit
    // never deletes all four stems at once. Abort without mutating so a bad
    // read can't silently erase the track's curation. (A legitimate per-stem
    // full deletion still syncs, because the other stems still have clips.)
    var totalLive = 0;
    for (var ps = 0; ps < STEM_NAMES.length; ps++) {
        var psPath = trackIds[STEM_NAMES[ps]];
        if (!psPath) continue;
        for (var psl = 0; psl < SLOTS_PER_BANK; psl++) {
            try {
                var psApi = new LiveAPI(psPath + " clip_slots " + (offset + psl));
                var psHas = psApi.get("has_clip");
                if (psHas && psHas.toString() === "1") totalLive++;
            } catch (_) {}
        }
    }
    if (totalLive === 0) {
        post("setforge-loader: sync ABORTED — 0 clips found at offset " + offset +
             " across all stems; refusing to wipe " + preset.trackId + "\n");
        return 0;
    }

    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackPath = trackIds[stem];
        if (!trackPath) continue;

        var mStem = mTrack.stems ? mTrack.stems[stem] : null;
        if (!mStem || !mStem.chops) continue;

        var presetChops = preset.chops ? preset.chops[stem] : null;

        // ── Pass 1: scan all 8 slots, build live-clip list ─────────────
        var liveClips = []; // {slot, clipApi, identity, name}
        for (var ls = 0; ls < 8; ls++) {
            var actualSlot = offset + ls;
            var lcsPath = trackPath + " clip_slots " + actualSlot;
            try {
                var lcsApi = new LiveAPI(lcsPath);
                var lhasClip = lcsApi.get("has_clip");
                if (!lhasClip || lhasClip.toString() !== "1") continue;
                var lclipApi = new LiveAPI(lcsPath + " clip");
                if (!lclipApi || lclipApi.id === "0") continue;
                var lname = "";
                try { lname = String(lclipApi.get("name") || ""); } catch (_) {}
                liveClips.push({
                    slot: ls,
                    clipApi: lclipApi,
                    identity: parseClipIdentity(lname),
                    name: lname
                });
            } catch (_) {}
        }

        // ── Pass 2: reconcile manifest.chops with live clips by identity ──
        var matchedMc = {};      // manifest-chop-index → true
        var seenIdentity = {};   // identity → true (dup detection)
        var newChops = [];       // freshly-added chops for copy/new clips

        for (var lci = 0; lci < liveClips.length; lci++) {
            var lc = liveClips[lci];
            var mc = null;
            var c = lc.slot; // for the legacy per-slot property branch below

            if (lc.identity !== null && !seenIdentity[lc.identity] &&
                lc.identity < mStem.chops.length) {
                // Original clip from this preset — maps to its manifest entry
                mc = mStem.chops[lc.identity];
                matchedMc[lc.identity] = true;
                seenIdentity[lc.identity] = true;
                mc.column = lc.slot + 1;
            } else if (lc.identity === null && !matchedMc[lc.slot] &&
                       lc.slot < mStem.chops.length) {
                // Legacy clip (no identity prefix): fall back to positional
                // mapping — slot N → manifest chop[N]. Stamp identity in
                // Live so future syncs are identity-tracked.
                mc = mStem.chops[lc.slot];
                matchedMc[lc.slot] = true;
                mc.column = lc.slot + 1;
                try {
                    var stampLabel = lc.name || ((mc.label || "chop") +
                        (mc.kind ? " [" + mc.kind + "]" : ""));
                    lc.clipApi.set("name",
                        "[sf:" + preset.trackId + "/" + stem + "/" + lc.slot + "] " + stampLabel);
                } catch (_) {}
            } else {
                // Either a duplicate of an existing identity (the copy case),
                // OR a clip whose identity points to a missing manifest entry.
                // Either way, treat it as a brand-new chop and stamp a fresh
                // identity in Live so the next sync pass disambiguates it.
                var srcMc = (lc.identity !== null && lc.identity < mStem.chops.length)
                    ? mStem.chops[lc.identity] : null;
                mc = srcMc ? cloneChop(srcMc) : { column: lc.slot + 1 };
                mc.column = lc.slot + 1;
                newChops.push(mc);
                try {
                    var freshIdx = mStem.chops.length + newChops.length - 1;
                    var labelTail = lc.name.replace(/^\[sf:[^\]]+\]\s*/, "");
                    lc.clipApi.set("name",
                        "[sf:" + preset.trackId + "/" + stem + "/" + freshIdx + "] " + labelTail);
                } catch (_) {}
            }

            // Continue into existing property-extraction body with this mc
            var clipApi = lc.clipApi;
            var hasClip = "1"; // we already confirmed
            var clipSlot = offset + lc.slot;
            var csPath = trackPath + " clip_slots " + clipSlot;
            var csApi = null;
            try { csApi = new LiveAPI(csPath); } catch (_) {}

            try {

                // Read clip properties from Live
                var warping = 0, loopStart = 0, loopEnd = 0;
                var startMarker = 0, endMarker = 0, warpMode = 0, warpBpm = 0;
                var clipName = "";

                try { warping = Number(clipApi.get("warping")); } catch (_) {}
                try { loopStart = Number(clipApi.get("loop_start")); } catch (_) {}
                try { loopEnd = Number(clipApi.get("loop_end")); } catch (_) {}
                try { startMarker = Number(clipApi.get("start_marker")); } catch (_) {}
                try { endMarker = Number(clipApi.get("end_marker")); } catch (_) {}
                try { warpMode = Number(clipApi.get("warp_mode")); } catch (_) {}
                try { warpBpm = Number(clipApi.get("warp_bpm")); } catch (_) {}
                try {
                    var rawName = clipApi.get("name");
                    if (rawName) clipName = String(rawName);
                } catch (_) {}

                // Op 2: capture per-clip BPM into manifest if user changed it
                // in Live. Only record if it differs notably from the track-
                // level BPM; otherwise the track default applies.
                if (warpBpm > 0 && mTrack.bpm && Math.abs(warpBpm - mTrack.bpm) > 0.5) {
                    mc.bpm = warpBpm;
                } else if (warpBpm > 0 && !mTrack.bpm) {
                    mc.bpm = warpBpm;
                }

                // Read warp markers to compute sample-time offsets
                var markers = [];
                try {
                    var rawWm = clipApi.get("warp_markers");
                    if (rawWm && rawWm.length > 0) {
                        var wmStr = (typeof rawWm[0] === "string") ? rawWm[0] : String(rawWm[0]);
                        var wmParsed = JSON.parse(wmStr);
                        if (wmParsed && wmParsed.warp_markers) markers = wmParsed.warp_markers;
                        else if (wmParsed && wmParsed.length) markers = wmParsed;
                    }
                } catch (_) {}

                // Diagnostic: dump raw clip props for every synced clip so the
                // next hardware run reveals which branch each short-clip drum hits.
                post("    [sync raw] " + stem + "[" + c + "] warping=" + warping +
                     " loop=[" + loopStart.toFixed(3) + "," + loopEnd.toFixed(3) + "]" +
                     " markers=[" + startMarker.toFixed(3) + "," + endMarker.toFixed(3) + "]" +
                     " wmCount=" + markers.length + "\n");

                if (warping === 1 && loopEnd > loopStart) {
                    // Warped clip: loop_start/end are in beats.
                    var beatSpan = loopEnd - loopStart;
                    var bars = Math.round(beatSpan / BEATS_PER_BAR);

                    // Compute sample-time from warp markers + BPM.
                    // Strategy: find an anchor marker, then use the beat→sample
                    // relationship to compute start and end sample times.
                    var trackBpm = (mTrack.bpm) ? mTrack.bpm : 95;
                    var secPerBeat = 60.0 / trackBpm;
                    var startSec = mc.start_sec || 0;
                    var lengthSec = bars * BEATS_PER_BAR * secPerBeat;

                    if (markers.length >= 1) {
                        // Find the anchor marker (closest to beat 0)
                        var anchor = markers[0];
                        for (var mi = 1; mi < markers.length; mi++) {
                            if (Math.abs(markers[mi].beat_time) < Math.abs(anchor.beat_time)) {
                                anchor = markers[mi];
                            }
                        }

                        // Compute beat→sample rate from two markers if available
                        var secPerBeatFromMarkers = secPerBeat;
                        if (markers.length >= 2) {
                            // Use the two most-separated markers for best accuracy
                            var first = markers[0];
                            var last = markers[markers.length - 1];
                            var dtBeat = last.beat_time - first.beat_time;
                            var dtSec = last.sample_time - first.sample_time;
                            if (dtBeat > 0 && dtSec > 0) {
                                secPerBeatFromMarkers = dtSec / dtBeat;
                            }
                        }

                        // Compute loop start in sample time
                        // loopStart is in beats (usually 0)
                        startSec = anchor.sample_time + (loopStart - anchor.beat_time) * secPerBeatFromMarkers;
                        lengthSec = beatSpan * secPerBeatFromMarkers;
                    }

                    // Sanity: if lengthSec is unreasonable, fall back to BPM calc
                    if (lengthSec <= 0 || lengthSec > 600) {
                        lengthSec = bars * BEATS_PER_BAR * secPerBeat;
                    }
                    if (startSec < 0) startSec = 0;

                    // Update manifest chop
                    mc.length_bars = bars;
                    mc.start_sec = startSec;
                    mc.length_sec = lengthSec;
                    if (mc.loop_start_sec !== undefined) {
                        // PRESERVE the within-WAV offset (materialized chops are
                        // padded; the real loop starts `startSec` into the WAV).
                        // Zeroing this (the old behavior) made reload loop from
                        // the WAV start (the pad) → every chop a bar early.
                        // Verified: pristine = 2.81s, sync was overwriting → 0.
                        mc.loop_start_sec = startSec;
                        mc.loop_end_sec = startSec + lengthSec;
                    }

                    // Beats-faithful region capture: store the EXACT Live
                    // marker/loop beats. Reload restores these directly, so a
                    // region the user sets comes back identical — no lossy
                    // sec↔beat reprojection through the warp grid (the cause of
                    // vocal regions shifting / clamping to bar 1 on reload).
                    mc.start_marker_beat = startMarker;
                    mc.end_marker_beat = endMarker;
                    mc.loop_start_beat = loopStart;
                    mc.loop_end_beat = loopEnd;

                    // Update in-memory preset chops too
                    if (presetChops && presetChops[c]) {
                        presetChops[c].clipStart = startSec;
                        presetChops[c].clipLength = lengthSec;
                        presetChops[c].lengthBars = bars;
                    }

                    synced++;
                    post("  " + stem + "[" + c + "]: " + bars + " bars, start=" +
                         startSec.toFixed(2) + "s, len=" + lengthSec.toFixed(2) + "s\n");

                } else if (warping === 0) {
                    // Unwarped clip: start/end markers are in seconds
                    mc.start_sec = startMarker;
                    mc.length_sec = endMarker - startMarker;
                    mc.length_bars = 0;

                    if (presetChops && presetChops[c]) {
                        presetChops[c].clipStart = startMarker;
                        presetChops[c].clipLength = endMarker - startMarker;
                        presetChops[c].lengthBars = 0;
                    }

                    synced++;
                    post("  " + stem + "[" + c + "]: oneshot, start=" +
                         startMarker.toFixed(2) + "s, end=" + endMarker.toFixed(2) + "s\n");
                }

                // Unconditional fallback: if length_sec ended up <= 0 (e.g. both
                // branches above bailed out, or Live reported loop_end=loop_start
                // for a short drum clip), derive it from track BPM + length_bars.
                // Better a reasonable default than zero — zero kills clip firing.
                if (!mc.length_sec || mc.length_sec <= 0) {
                    var fbBpm = (mTrack.bpm) ? mTrack.bpm : 95;
                    var fbBars = mc.length_bars || 1;
                    mc.length_sec = fbBars * BEATS_PER_BAR * (60.0 / fbBpm);
                    mc.length_bars = fbBars;
                    if (presetChops && presetChops[c]) {
                        presetChops[c].clipLength = mc.length_sec;
                        presetChops[c].lengthBars = fbBars;
                    }
                    post("  " + stem + "[" + c + "]: fallback len=" +
                         mc.length_sec.toFixed(2) + "s (bpm=" + fbBpm + ", bars=" + fbBars + ")\n");
                }

            } catch (e) {
                post("  " + stem + "[" + c + "]: sync error: " + e + "\n");
            }
        } // end live-clip loop

        // ── Pass 3: structural reconciliation ───────────────────────────
        // Drop manifest chops whose identity didn't appear in Live (deletes),
        // append newChops collected during the loop (copies / new clips),
        // and re-sort by column so the manifest stays in display order.
        var survivors = [];
        var removed = 0;
        for (var mci = 0; mci < mStem.chops.length; mci++) {
            if (matchedMc[mci]) {
                survivors.push(mStem.chops[mci]);
            } else {
                removed++;
            }
        }
        for (var ni = 0; ni < newChops.length; ni++) {
            survivors.push(newChops[ni]);
        }
        survivors.sort(function(a, b) { return (a.column || 0) - (b.column || 0); });
        if (removed > 0 || newChops.length > 0) {
            post("  " + stem + ": structural-sync removed=" + removed +
                 " added=" + newChops.length + " total=" + survivors.length + "\n");
        }
        mStem.chops = survivors;
        // Mark the stem user-curated so reload honors an empty chops list
        // literally (load NOTHING) instead of falling back to a blind grid.
        // This is what lets "delete all the 'other' clips" actually stick.
        mStem.curated = true;
    } // end stem loop

    return synced;
}

// Shallow-copy a chop's manifest entry. Used when sync sees a duplicate of an
// existing identity (the user copied a clip in Live) — we clone the source
// chop's properties as the seed for the new manifest entry.
function cloneChop(src) {
    var dst = {};
    for (var k in src) {
        if (src.hasOwnProperty(k)) dst[k] = src[k];
    }
    return dst;
}

// Full save: sync from Live, then write manifest + set to disk
function fullSave() {
    post("setforge-loader: === FULL SAVE ===\n");
    var synced = syncFromLive();
    var mOk = saveManifest();
    var sOk = saveSet();
    post("setforge-loader: save complete — synced " + (synced || 0) +
         " clips, manifest=" + (mOk ? "OK" : "FAIL") +
         ", set=" + (sOk ? "OK" : "FAIL") + "\n");
}

function inspectClips() {
    var active = getActivePreset();
    if (!active) {
        post("inspect: no active preset\n");
        return;
    }
    if (!liveApi) {
        post("inspect: no LiveAPI\n");
        return;
    }

    var offset = activeSetOffset();
    var result = {
        preset_index: activeSlotIndex,
        track_id: active.trackId || null,
        track_bpm: (active.track && active.track.bpm) ? active.track.bpm : null,
        clip_set: activeBankLabel(),
        clip_offset: offset,
        session_tempo: null,
        stems: {}
    };

    // Read session tempo
    try { result.session_tempo = liveApi.get("tempo"); } catch (_) {}

    post("\n=== inspect: preset " + activeSlotIndex + " (" + (active.trackId || "?") + ") ===\n");

    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackPath = stemTrackIds[stem];
        if (!trackPath) {
            post("inspect " + stem + ": no track\n");
            continue;
        }

        var stemClips = [];

        for (var c = 0; c < NUM_CHOPS; c++) {
            var clipSlot = offset + c;
            var csPath = trackPath + " clip_slots " + clipSlot;

            try {
                var csApi = new LiveAPI(csPath);
                var hasClip = csApi.get("has_clip");
                if (!hasClip || hasClip.toString() !== "1") continue;

                var clipApi = new LiveAPI(csPath + " clip");
                if (!clipApi || clipApi.id === "0") continue;

                var clipData = {
                    slot: c,
                    name: "",
                    warping: 0,
                    warp_mode: 0,
                    warp_bpm: 0,
                    loop_start: 0,
                    loop_end: 0,
                    start_marker: 0,
                    end_marker: 0,
                    length: 0,
                    warp_markers: []
                };

                try { clipData.name = String(clipApi.get("name")); } catch (_) {}
                try { clipData.warping = Number(clipApi.get("warping")); } catch (_) {}
                try { clipData.warp_mode = Number(clipApi.get("warp_mode")); } catch (_) {}
                // Note: clipApi.get("warp_bpm") always returns 0 in M4L LiveAPI
                // — Live exposes warp_bpm via Python LOM but not via the M4L
                // bridge. Per-clip BPM persistence is documented as out-of-scope
                // pending a warp-marker-manipulation redesign.
                try { clipData.warp_bpm = Number(clipApi.get("warp_bpm")); } catch (_) {}
                try { clipData.loop_start = Number(clipApi.get("loop_start")); } catch (_) {}
                try { clipData.loop_end = Number(clipApi.get("loop_end")); } catch (_) {}
                try { clipData.start_marker = Number(clipApi.get("start_marker")); } catch (_) {}
                try { clipData.end_marker = Number(clipApi.get("end_marker")); } catch (_) {}
                try { clipData.length = Number(clipApi.get("length")); } catch (_) {}

                // Read warp markers
                try {
                    var raw = clipApi.get("warp_markers");
                    if (raw && raw.length > 0) {
                        var jsonStr = (typeof raw[0] === "string") ? raw[0] : String(raw[0]);
                        var parsed = JSON.parse(jsonStr);
                        if (parsed && parsed.warp_markers) {
                            clipData.warp_markers = parsed.warp_markers;
                        } else if (parsed && parsed.length) {
                            clipData.warp_markers = parsed;
                        }
                    }
                } catch (_) {}

                // Also read chop metadata from the active preset
                var chopMeta = null;
                if (active.chops && active.chops[stem]) {
                    for (var ci = 0; ci < active.chops[stem].length; ci++) {
                        if (active.chops[stem][ci].column === c + 1) {
                            var ch = active.chops[stem][ci];
                            chopMeta = {
                                label: ch.label || "",
                                kind: ch.kind || "",
                                lengthBars: ch.lengthBars || 0,
                                clipStart: ch.clipStart,
                                clipLength: ch.clipLength,
                                stemPath: ch.stemPath
                            };
                            break;
                        }
                    }
                }
                clipData.chop = chopMeta;

                stemClips.push(clipData);

                // Console output
                var markerStr = "";
                for (var m = 0; m < clipData.warp_markers.length; m++) {
                    var mk = clipData.warp_markers[m];
                    markerStr += " [b=" + (mk.beat_time || "?") + ",s=" + (mk.sample_time || "?") + "]";
                }
                post("inspect " + stem + "[" + c + "]: " +
                    "warping=" + clipData.warping +
                    " mode=" + clipData.warp_mode +
                    " start=" + clipData.start_marker.toFixed(2) +
                    " loop=" + clipData.loop_start.toFixed(2) + ".." + clipData.loop_end.toFixed(2) +
                    " end=" + clipData.end_marker.toFixed(2) +
                    " len=" + clipData.length.toFixed(2) +
                    " markers=" + clipData.warp_markers.length + markerStr +
                    (chopMeta ? " [" + chopMeta.label + " " + chopMeta.lengthBars + "bar]" : "") +
                    "\n");

            } catch (e) {
                post("inspect " + stem + "[" + c + "]: error: " + e + "\n");
            }
        }

        result.stems[stem] = stemClips;
    }

    post("=== end inspect ===\n");

    // Write JSON to file for automated test consumption
    try {
        var jsonOut = JSON.stringify(result, null, 2);
        var outFile = new File("/tmp/setforge_inspect.json", "w");
        if (outFile.isopen) {
            outFile.eof = 0;
            outFile.writestring(jsonOut);
            outFile.close();
            post("inspect: wrote /tmp/setforge_inspect.json\n");
        }
    } catch (e) {
        post("inspect: file write error: " + e + "\n");
    }
}

// ═══════════════════════════════════════════════════════════
//  Debug
// ═══════════════════════════════════════════════════════════

function dumpState() {
    post("\n=== setforge-loader state ===\n");
    post("deviceReady: " + deviceReady + "\n");
    post("surface: " + surface.model + "\n");
    post("manifest: " + (manifest ? manifest.tracks.length + " tracks" : "null") + "\n");
    post("setData: " + (setData ? setData.name : "null") + "\n");
    post("activeSlot: " + activeSlotIndex + "\n");

    for (var i = 0; i < TOTAL_SLOTS; i++) {
        var s = presetSlots[i];
        if (s.state !== "empty") {
            post("  slot[" + i + "] " + s.bank + ": " + s.trackId + " (" + s.state + ")");
            if (s.chops) {
                var stemCount = 0;
                for (var j = 0; j < STEM_NAMES.length; j++) {
                    if (s.chops[STEM_NAMES[j]]) stemCount++;
                }
                post(" " + stemCount + " stems");
            }
            post("\n");
        }
    }

    var held = getHeldChops();
    post("playing: " + (held.length > 0 ? held.map(function(h) { return h.stem + ":" + h.col; }).join(", ") : "none") + "\n");

    var activeMods = [];
    for (var i = 0; i < MODIFIERS.length; i++) {
        if (modState[MODIFIERS[i]] !== "idle") {
            activeMods.push(MODIFIERS[i] + "=" + modState[MODIFIERS[i]]);
        }
    }
    post("modifiers: " + (activeMods.length > 0 ? activeMods.join(", ") : "none") + "\n");

    var builtScenes = [];
    for (var i = 0; i < NUM_SCENES; i++) {
        if (scenes[i].state !== "empty") {
            builtScenes.push(String.fromCharCode(65 + i) + "=" + scenes[i].state);
        }
    }
    post("scenes: " + (builtScenes.length > 0 ? builtScenes.join(", ") : "none") + "\n");

    post("fx: target=" + fxTarget + " filter=" + fxFilterCol + (fxFilterLatched ? "(latched)" : "") + " throw=" + fxThrowCol + "\n");

    for (var i = 0; i < STEM_NAMES.length; i++) {
        var stem = STEM_NAMES[i];
        post("  track[" + stem + "]:   " + (stemTrackIds[stem]  || "not created") +
             "   X=" + (stemTrackIdsX[stem] || "—") +
             "   Y=" + (stemTrackIdsY[stem] || "—") + "\n");
    }
    post("=== end state ===\n\n");
}

// ═══════════════════════════════════════════════════════════
//  Init
// ═══════════════════════════════════════════════════════════

var deviceReady = false;

function doInit() {
    post("setforge-loader: init\n");
    initPresetBanks();
    initModifiers();
    initScenes();
    bypassFx();
    // startCmdPoll is deferred — Task may not be available at global init time
}

function bang() {
    if (deviceReady) return;
    deviceReady = true;
    dbg("setforge-loader: device ready (model=" + surface.model + ", single-grid=" + singleGridMode + ")\n");
    initLiveApi();

    // Enter programmer mode via surface
    var enterCmd = surface.enterProgrammerMode();
    if (enterCmd) {
        outlet(0, enterCmd);
        dbg("setforge-loader: sent programmer mode enter\n");
    }

    updateAllPadColors();
    updateStatus();
}

// Persist last loaded set path so autowatch reloads can re-load it
var LAST_SET_PATH_FILE = "/tmp/setforge_last_set.txt";

function saveLastSetPath(path) {
    try {
        var f = new File(LAST_SET_PATH_FILE, "w");
        if (f.isopen) { f.eof = 0; f.writestring(path); f.close(); }
    } catch (_) {}
}

function loadLastSetPath() {
    try {
        var f = new File(LAST_SET_PATH_FILE, "r");
        if (!f.isopen) return null;
        var path = f.readstring(f.eof);
        f.close();
        return path && path.length > 0 ? path.trim() : null;
    } catch (_) { return null; }
}

// Init data structures only (no outlet calls at load time)
doInit();

// After autowatch reload, try to re-load the last set
var lastPath = loadLastSetPath();
if (lastPath) {
    post("setforge-loader: auto-reloading last set: " + lastPath + "\n");
    // Defer to avoid outlet calls during load
    var reloadTask = new Task(function() { loadSet(lastPath); });
    reloadTask.schedule(500);
}

// Start command file poll (deferred — Task may fail at global scope)
try {
    var cmdStartTask = new Task(function() { startCmdPoll(); });
    cmdStartTask.schedule(1000);
} catch (e) {
    post("setforge-loader: deferred cmdPoll failed: " + e + "\n");
}

// Keep the live preset glow asserted against Live's hover-repaint.
try {
    var colorStartTask = new Task(function() { startColorRefresh(); });
    colorStartTask.schedule(1500);
} catch (e) {}

post("setforge-loader.js loaded (surface=" + surface.model + ")\n");
