// setforge-loader — fully wired Max JS controller
// Loaded by [js loader.js] in the Max patch.
//
// Implements: chop routing, preset banks, scene memory,
// modifier layer, FX bus, launchpad surface, manifest parsing.
//
// Max [js] uses SpiderMonkey (ES5). No require(), no modules.

autowatch = 1;
inlets = 3;   // 0: Grid 1 MIDI, 1: Grid 2 MIDI, 2: messages/UI
outlets = 4;  // 0: Grid 1 MIDI out, 1: Grid 2 MIDI out, 2: LiveAPI, 3: status

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
var STEM_ROW = { drums: 2, bass: 3, other: 4, vox: 5 };
var ROW_STEM = { 2: "drums", 3: "bass", 4: "other", 5: "vox" };

var MODIFIERS = ["HOLD", "MUTE", "SOLO", "REV", "STUT", "HALF", "DBL", "KILL"];

// Launch quantization (Live enum values)
var LAUNCH_QUANT = { "1/16": 4, "1/8": 5, "1/4": 6, "1/2": 7, "1bar": 8 };
var ROW_QUANT = {
    drums: LAUNCH_QUANT["1/16"],
    bass:  LAUNCH_QUANT["1bar"],
    other: LAUNCH_QUANT["1/4"],
    vox:   LAUNCH_QUANT["1/2"]
};

// Launchpad Pro SysEx headers
// MK2: F0 00 20 29 02 10 0B ... F7 (RGB direct mode)
// MK3: F0 00 20 29 02 0E 03 ... F7 (RGB LED lighting)
var LP_MODEL = "mk2"; // "mk2" or "mk3"
var LP_SYSEX_RGB = {
    mk2: [240, 0, 32, 41, 2, 16, 11],   // 02 10 0B
    mk3: [240, 0, 32, 41, 2, 14, 3],    // 02 0E 03
};
var LP_SYSEX_PROGRAMMER_MODE = {
    mk2_enter: [240, 0, 32, 41, 2, 16, 44, 3, 247],   // 02 10 2C 03
    mk2_leave: [240, 0, 32, 41, 2, 16, 44, 0, 247],   // 02 10 2C 00
    mk3_enter: [240, 0, 32, 41, 2, 14, 14, 1, 247],    // 02 0E 0E 01
    mk3_leave: [240, 0, 32, 41, 2, 14, 14, 0, 247],    // 02 0E 0E 00
};

// Side button note numbers (MK2 programmer mode, left column top-to-bottom)
var SIDE_BUTTONS_LEFT = [80, 70, 60, 50, 40, 30, 20, 10];
// Single-grid mode: side button assignments (left, top-to-bottom)
// [0] MODE_TOGGLE, [1] TAP, [2] SYNC, [3] BPM-, [4] BPM+, [5] LOOP_IN, [6] LOOP_OUT, [7] PANIC
var SIDE_FUNC = ["MODE_TOGGLE", "TAP", "SYNC", "BPM_DOWN", "BPM_UP", "LOOP_IN", "LOOP_OUT", "PANIC"];

// Grid view mode (single-grid only)
var viewMode = "performance"; // "performance" or "control"
var viewModeLatched = false;
var viewModeLastPress = 0;
var singleGridMode = true; // true until second Launchpad detected

// Stem colors [R, G, B] in 0-127 (Launchpad 7-bit)
// Saturated and punchy — need to pop on stage, not look like a spreadsheet
var STEM_COLORS = {
    drums: { soft: [64, 20, 0],   bright: [127, 40, 0] },     // warm orange-red
    bass:  { soft: [0, 20, 64],   bright: [0, 40, 127] },     // deep blue
    other: { soft: [50, 50, 0],   bright: [100, 100, 0] },    // yellow-gold
    vox:   { soft: [0, 50, 20],   bright: [0, 127, 40] }      // bright green
};

// Genre colors — vivid, distinguishable at a glance
var GENRE_COLORS = {
    hiphop:  [127, 50, 0],     // hot orange
    idm:     [0, 60, 127],     // electric blue
    ambient: [0, 127, 50],     // neon green
    rock:    [100, 100, 100],  // bright grey
    funk:    [127, 100, 0]     // golden yellow
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

function computeTrackChops(track) {
    var result = {};
    var length = track.varying ? 0 : chopClipLength(track.bpm);
    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stemName = STEM_NAMES[s];
        var stem = track.stems ? track.stems[stemName] : null;
        if (!stem || !stem.path) {
            result[stemName] = null;
            continue;
        }
        var chops = [];
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
        result[stemName] = chops;
    }
    return result;
}

// ═══════════════════════════════════════════════════════════
//  Launchpad Surface
// ═══════════════════════════════════════════════════════════

function noteToRowCol(note) {
    if (note < 11 || note > 88) return null;
    var lpRow = Math.floor(note / 10);
    var lpCol = note % 10;
    if (lpCol < 1 || lpCol > 8 || lpRow < 1 || lpRow > 8) return null;
    return { row: 9 - lpRow, col: lpCol };
}

function rowColToNote(row, col) {
    return (9 - row) * 10 + col;
}

var pendingRgb = { 1: [], 2: [] };

function queueRgb(grid, row, col, rgb) {
    var note = rowColToNote(row, col);
    pendingRgb[grid].push({ note: note, rgb: rgb });
}

function flushRgb(grid) {
    var writes = pendingRgb[grid];
    if (!writes || writes.length === 0) return;

    var header = LP_SYSEX_RGB[LP_MODEL] || LP_SYSEX_RGB.mk2;

    // MK2 max ~78 pads per SysEx; chunk if needed
    var chunkSize = 70;
    for (var start = 0; start < writes.length; start += chunkSize) {
        var end = Math.min(start + chunkSize, writes.length);
        var msg = header.slice();
        for (var i = start; i < end; i++) {
            // MK2 format: <pad_note> <r7> <g7> <b7> (no leading 0x03)
            // MK3 format: 03 <pad_note> <r7> <g7> <b7>
            if (LP_MODEL === "mk3") msg.push(3);
            msg.push(writes[i].note, writes[i].rgb[0], writes[i].rgb[1], writes[i].rgb[2]);
        }
        msg.push(247);

        // In single-grid mode, all output goes to outlet 0
        var outletIdx = (singleGridMode || grid === 1) ? 0 : 1;
        outlet(outletIdx, msg);
    }
    pendingRgb[grid] = [];
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

    var active = getActivePreset();
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
    scenes[index] = {
        state: "built",
        snapshot: {
            activePresetIndex: activeSlotIndex,
            heldChops: getHeldChops(),
            modifiers: modifierSnapshot()
        }
    };
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
var stemTrackIds = {};   // stemName -> Live track id path
var stemTrackIndices = {}; // stemName -> track index in live_set

// Warp modes per stem (matches stemforge convention)
var WARP_MODES = { drums: 0, bass: 0, other: 4, vox: 4 }; // 0=Beats, 4=Complex

function initLiveApi() {
    try {
        liveApi = new LiveAPI("live_set");
        post("setforge-loader: LiveAPI ready, tracks=" + liveApi.get("tracks").length + "\n");
    } catch (e) {
        post("setforge-loader: LiveAPI init failed: " + e + "\n");
    }
}

/**
 * Ensure at least N scenes exist in the Live set.
 * Clip slots only exist if there's a corresponding scene.
 */
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

/**
 * Find or create audio tracks for the 4 stems.
 * Track names: "sf-drums", "sf-bass", "sf-other", "sf-vox"
 */
function ensureStemTracks() {
    if (!liveApi) { post("setforge-loader: no LiveAPI\n"); return false; }

    for (var s = 0; s < STEM_NAMES.length; s++) {
        var stem = STEM_NAMES[s];
        var trackName = "sf-" + stem;
        var trackIdx = findTrackByName(trackName);

        if (trackIdx < 0) {
            post("setforge-loader: creating track '" + trackName + "'\n");
            try {
                // Get current track count, insert at end (before return/master)
                var trackCount = liveApi.get("tracks").length / 2;
                // create_audio_track inserts at the given index
                // Use trackCount - 1 to insert before master (last track is master)
                var insertIdx = Math.max(0, trackCount - 1);
                liveApi.call("create_audio_track", insertIdx);

                // The new track is now at insertIdx
                // But track indices may shift — re-count and find it
                var newCount = liveApi.get("tracks").length / 2;
                // The new track should be at insertIdx
                trackIdx = insertIdx;

                var tApi = new LiveAPI("live_set tracks " + trackIdx);
                tApi.set("name", trackName);

                // Verify it stuck
                var verifyName = tApi.get("name").toString();
                post("setforge-loader: created '" + trackName + "' at index " + trackIdx + " (verify: " + verifyName + ")\n");
            } catch (e) {
                post("setforge-loader: error creating track '" + trackName + "': " + e + "\n");
                continue;
            }
        } else {
            post("setforge-loader: found track '" + trackName + "' at index " + trackIdx + "\n");
        }

        stemTrackIndices[stem] = trackIdx;
        stemTrackIds[stem] = "live_set tracks " + trackIdx;
    }
    return true;
}

function findTrackByName(name) {
    if (!liveApi) return -1;
    try {
        var trackIds = liveApi.get("tracks");
        // trackIds is flat array of [id, "id", id, "id", ...]
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

// ── Dual slot-set A/B architecture ──
// Each stem track has 16 clip slots: set A (0-7) and set B (8-15).
// One set is "active" (playing), the other is "staging" (pre-loading).
// On preset swap, the incoming preset loads into staging, then we
// fire staging clips at the boundary and swap labels.
var activeClipSet = "A";  // "A" uses slots 0-7, "B" uses slots 8-15
var stagingPresetIndex = -1; // preset currently being staged
var stagingReady = false;

function activeSetOffset() { return activeClipSet === "A" ? 0 : 8; }
function stagingSetOffset() { return activeClipSet === "A" ? 8 : 0; }

/**
 * Load clips for a preset into a specific slot-set offset (0 or 8).
 * Returns number of clips loaded.
 */
function loadClipsToSlotSet(presetIdx, offset) {
    var slot = presetSlots[presetIdx];
    if (!slot || !slot.chops) return 0;

    var totalLoaded = 0;
    post("setforge-loader: loading clips for " + slot.trackId + " into set " +
         (offset === 0 ? "A" : "B") + " (slots " + offset + "-" + (offset + 7) + ")\n");

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

                // Delete existing clip
                try {
                    var hasClip = csApi.get("has_clip");
                    if (hasClip && hasClip.toString() === "1") {
                        csApi.call("delete_clip");
                    }
                } catch (_) {}

                // Load audio (POSIX path)
                csApi.call("create_audio_clip", String(chop.stemPath));

                // Configure
                var clipApi = new LiveAPI(csPath + " clip");
                if (clipApi && clipApi.id !== "0") {
                    clipApi.set("name", slot.trackId + "-" + stem + "-" + chop.column);
                    clipApi.set("warping", 1);
                    clipApi.set("warp_mode", WARP_MODES[stem] || 0);
                    clipApi.set("looping", 1);
                    clipApi.set("launch_quantization", ROW_QUANT[stem]);
                    clipApi.set("loop_start", chop.clipStart);
                    clipApi.set("loop_end", chop.clipStart + chop.clipLength);
                    clipApi.set("start_marker", chop.clipStart);
                    clipApi.set("end_marker", chop.clipStart + chop.clipLength);
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

/**
 * Load clips for the initial/active preset into the active set.
 */
function loadClipsForPreset(presetIdx) {
    loadClipsToSlotSet(presetIdx, activeSetOffset());
}

/**
 * Pre-load clips for an incoming preset into the staging set.
 */
function stagePreset(presetIdx) {
    stagingPresetIndex = presetIdx;
    stagingReady = false;
    var loaded = loadClipsToSlotSet(presetIdx, stagingSetOffset());
    stagingReady = (loaded > 0);
    post("setforge-loader: staging " + (stagingReady ? "ready" : "failed") +
         " for preset " + presetIdx + "\n");
}

/**
 * Commit the staged preset: swap A/B labels so staging becomes active.
 */
function commitStagedPreset() {
    activeClipSet = (activeClipSet === "A") ? "B" : "A";
    stagingPresetIndex = -1;
    stagingReady = false;
    post("setforge-loader: committed, active set now " + activeClipSet + "\n");
}

/**
 * Launch a clip in a stem track.
 */
function launchClipInTrack(stemName, slotIndex, chop) {
    if (!deviceReady) return;

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

/**
 * Launch a clip from the STAGING set (used during hot-swap transition).
 */
function launchStagingClip(stemName, chop) {
    if (!deviceReady) return;

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

/**
 * Stop a clip in a stem track (active set).
 */
function stopClipInTrack(stemName, slotIndex) {
    if (!deviceReady) return;

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

/**
 * Stop all clips in all stem tracks.
 */
function stopAllClips() {
    if (!deviceReady) return;

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
}

// ═══════════════════════════════════════════════════════════
//  Manifest / Set Loading
// ═══════════════════════════════════════════════════════════

var manifest = null;
var setData = null;

function loadSet(path) {
    post("setforge-loader: loading set from " + path + "\n");

    try {
        var setFile = new File(path, "r");
        if (!setFile.isopen) {
            post("setforge-loader: cannot open set file: " + path + "\n");
            return;
        }
        var setStr = setFile.readstring(setFile.eof);
        setFile.close();
        setData = JSON.parse(setStr);

        var setDir = path.replace(/[^\/\\]*$/, "");
        var manifestPath = setDir + setData.name + ".manifest.json";

        var mFile = new File(manifestPath, "r");
        if (!mFile.isopen) {
            post("setforge-loader: cannot open manifest: " + manifestPath + "\n");
            return;
        }
        var mStr = mFile.readstring(mFile.eof);
        mFile.close();
        manifest = JSON.parse(mStr);

        // Ensure 16 scenes (8 per slot-set A/B) + stem tracks
        if (deviceReady) {
            ensureScenes(NUM_CHOPS * 2);
            ensureStemTracks();
        }

        populateBanks();

        updateStatus();
        updateAllPadColors();

        // Debug: dump state
        post("setforge-loader: set loaded (" + (manifest.tracks ? manifest.tracks.length : 0) + " tracks)\n");
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
            // Control view: rows 1-7 show Grid 2 content, row 8 stays scenes
            updateControlViewColors();
        }
        flushRgb(1);
    } else {
        updateGrid1Colors();
        updateGrid2Colors();
        flushRgb(1);
        flushRgb(2);
    }
}

function updateControlViewColors() {
    // Rows 1-7: Grid 2 content rendered on Grid 1's physical pads
    // (reuse Grid 2 color logic but write to grid 1 pending buffer)
    // Rows 1-4: Setlist
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
                queueRgb(1, r, c, color);
            } else {
                queueRgb(1, r, c, STATE_COLORS.empty);
            }
        } else {
            queueRgb(1, r, c, STATE_COLORS.off);
        }
    }

    // Row 5: FX target
    var targetColors = [
        STEM_COLORS.drums.bright, STEM_COLORS.bass.bright,
        STEM_COLORS.other.bright, STEM_COLORS.vox.bright,
        [127, 127, 127], [127, 127, 0], [127, 127, 0], [127, 0, 0]
    ];
    var targetIdx = FX_TARGETS.indexOf(fxTarget);
    for (var c = 1; c <= 8; c++) {
        var isBright = (c - 1 === targetIdx);
        var tc = targetColors[c - 1];
        queueRgb(1, 5, c, isBright ? tc : scaleBrightness(tc, 0.3));
    }

    // Row 6: Filter
    for (var c = 1; c <= 8; c++) {
        var isActive = (c === fxFilterCol);
        if (isActive && fxFilterLatched) queueRgb(1, 6, c, [127, 127, 127]);
        else if (isActive) queueRgb(1, 6, c, [64, 64, 64]);
        else queueRgb(1, 6, c, [16, 16, 16]);
    }

    // Row 7: Throws
    for (var c = 1; c <= 8; c++) {
        queueRgb(1, 7, c, (c === fxThrowCol) ? [127, 80, 0] : [16, 16, 16]);
    }

    // Row 8: Scenes (always scenes in both views)
    for (var c = 1; c <= 8; c++) {
        var scene = scenes[c - 1];
        queueRgb(1, 8, c, SCENE_COLORS[scene.state] || SCENE_COLORS.empty);
    }
}

function updateGrid1Colors() {
    var active = getActivePreset();

    // Row 1: Bank A presets
    for (var c = 1; c <= 8; c++) {
        queueRgb(1, 1, c, presetSlotColor(presetSlots[c - 1]));
    }

    // Rows 2-5: Stem chops
    for (var r = 2; r <= 5; r++) {
        var stem = ROW_STEM[r];
        for (var c = 1; c <= 8; c++) {
            queueRgb(1, r, c, chopPadColor(stem, c, active));
        }
    }

    // Row 6: Modifiers
    for (var c = 1; c <= 8; c++) {
        var mod = MODIFIERS[c - 1];
        var ms = modState[mod] || "idle";
        queueRgb(1, 6, c, MOD_COLORS[ms] || MOD_COLORS.idle);
    }

    // Row 7: Bank B presets
    for (var c = 1; c <= 8; c++) {
        queueRgb(1, 7, c, presetSlotColor(presetSlots[c - 1 + SLOTS_PER_BANK]));
    }

    // Row 8: Scenes
    for (var c = 1; c <= 8; c++) {
        var scene = scenes[c - 1];
        queueRgb(1, 8, c, SCENE_COLORS[scene.state] || SCENE_COLORS.empty);
    }
}

function updateGrid2Colors() {
    // Rows 1-4: Setlist tracks
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
                queueRgb(2, r, c, color);
            } else {
                queueRgb(2, r, c, STATE_COLORS.empty);
            }
        } else {
            queueRgb(2, r, c, STATE_COLORS.off);
        }
    }

    // Row 5: FX target select
    var targetColors = [
        STEM_COLORS.drums.bright, STEM_COLORS.bass.bright,
        STEM_COLORS.other.bright, STEM_COLORS.vox.bright,
        [127, 127, 127], [127, 127, 0], [127, 127, 0], [127, 0, 0]
    ];
    var targetIdx = FX_TARGETS.indexOf(fxTarget);
    for (var c = 1; c <= 8; c++) {
        var isBright = (c - 1 === targetIdx);
        var tc = targetColors[c - 1];
        queueRgb(2, 5, c, isBright ? tc : scaleBrightness(tc, 0.3));
    }

    // Row 6: Filter
    for (var c = 1; c <= 8; c++) {
        var isActive = (c === fxFilterCol);
        if (isActive && fxFilterLatched) {
            queueRgb(2, 6, c, [127, 127, 127]);
        } else if (isActive) {
            queueRgb(2, 6, c, [64, 64, 64]);
        } else {
            queueRgb(2, 6, c, [16, 16, 16]);
        }
    }

    // Row 7: Throws
    for (var c = 1; c <= 8; c++) {
        queueRgb(2, 7, c, (c === fxThrowCol) ? [127, 80, 0] : [16, 16, 16]);
    }

    // Row 8: Transport
    var transportColors = [
        [64, 64, 64], [64, 64, 64], [40, 40, 64], [40, 40, 64],
        [64, 64, 40], [64, 64, 40], [127, 0, 0], [127, 0, 0]
    ];
    for (var c = 1; c <= 8; c++) {
        queueRgb(2, 8, c, transportColors[c - 1]);
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
    if (!activeSlot || !activeSlot.chops || !activeSlot.chops[stem]) return STATE_COLORS.off;
    var chopList = activeSlot.chops[stem];
    var chop = null;
    for (var i = 0; i < chopList.length; i++) {
        if (chopList[i].column === col) { chop = chopList[i]; break; }
    }
    if (!chop) return STATE_COLORS.off;
    if (chop.disabled) return STATE_COLORS.disabled;
    if (playingChops[stem] === col) return STEM_COLORS[stem].bright;
    return STEM_COLORS[stem].soft;
}

// Preset colors cycle through a fixed palette so each slot is visually distinct
var PRESET_PALETTE = [
    [127, 40, 0],    // orange
    [0, 40, 127],    // blue
    [0, 127, 40],    // green
    [127, 0, 80],    // magenta
    [127, 100, 0],   // gold
    [0, 100, 127],   // cyan
    [80, 0, 127],    // purple
    [127, 80, 80],   // salmon
];

function presetColor(slotIndex) {
    return PRESET_PALETTE[slotIndex % PRESET_PALETTE.length];
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
}

// ═══════════════════════════════════════════════════════════
//  MIDI Input Handling
// ═══════════════════════════════════════════════════════════

var midiBytes1 = [];
var midiBytes2 = [];

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
    }
}

function handleNoteOn(grid, note, velocity) {
    // Check for side buttons (MK2: notes ending in 0 on left side)
    var sideIdx = SIDE_BUTTONS_LEFT.indexOf(note);
    if (sideIdx >= 0) {
        handleSideButtonPress(sideIdx);
        return;
    }

    var pos = noteToRowCol(note);
    if (!pos) return;

    if (singleGridMode && viewMode === "control") {
        // In control view, pad presses route to Grid 2 handlers
        // But row 8 always stays scenes
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
    var sideIdx = SIDE_BUTTONS_LEFT.indexOf(note);
    if (sideIdx >= 0) {
        handleSideButtonRelease(sideIdx);
        return;
    }

    var pos = noteToRowCol(note);
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
            // Double-tap: latch toggle
            viewModeLatched = !viewModeLatched;
            post("setforge-loader: view mode " + (viewModeLatched ? "latched" : "unlatched") + " to " + viewMode + "\n");
        } else {
            // Single press: momentary toggle
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
        // Momentary: return to performance view on release
        viewMode = "performance";
        post("setforge-loader: view mode -> performance (released)\n");
        updateAllPadColors();
    }
}

// ═══════════════════════════════════════════════════════════
//  Grid 1 Event Handlers
// ═══════════════════════════════════════════════════════════

function handleGrid1Press(row, col) {
    if (row === 1) {
        onPresetPress(col - 1);
    } else if (row >= 2 && row <= 5) {
        onChopPress(row, col);
    } else if (row === 6) {
        pressModifier(col - 1, Date.now());
        updateGrid1Colors();
        flushRgb(1);
    } else if (row === 7) {
        onPresetPress(col - 1 + SLOTS_PER_BANK);
    } else if (row === 8) {
        onScenePress(col - 1);
    }
}

function handleGrid1Release(row, col) {
    if (row === 6) {
        releaseModifier(col - 1);
        updateGrid1Colors();
        flushRgb(1);
    }
}

function onPresetPress(slotIndex) {
    var slot = presetSlots[slotIndex];
    if (!slot || slot.state === "empty" || slot.state === "loading" || slot.state === "error") return;

    var isFirstActivation = (activeSlotIndex < 0);
    var shiftMode = (modState.HOLD === "held" || modState.HOLD === "latched");
    var result = activatePreset(slotIndex);
    if (!result) return;

    if (isFirstActivation) {
        // First preset activation: load directly into active set
        loadClipsForPreset(slotIndex);
    } else if (!shiftMode) {
        // Hot-swap: pre-load into staging, fire staging clips for held chops,
        // then commit (swap A/B labels)
        stagePreset(slotIndex);

        if (stagingReady) {
            var migrations = hotSwapChops(presetSlots[slotIndex].chops);
            for (var i = 0; i < migrations.length; i++) {
                var m = migrations[i];
                if (m.newChop) {
                    // Fire from staging set (already loaded, zero latency)
                    launchStagingClip(m.stem, m.newChop);
                } else {
                    stopClipInTrack(m.stem, m.column - 1);
                }
            }
            // Commit: staging becomes active
            commitStagedPreset();
        }
    } else {
        // Shift mode: hard switch, stop everything, load fresh
        var held = getHeldChops();
        for (var i = 0; i < held.length; i++) {
            stopClipInTrack(held[i].stem, held[i].col - 1);
        }
        stopAllChops();
        stagePreset(slotIndex);
        if (stagingReady) commitStagedPreset();
    }

    updateAllPadColors();
    updateStatus();
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
    flushRgb(1);
}

function onScenePress(sceneIndex) {
    if (modState.HOLD === "held" || modState.HOLD === "latched") {
        saveScene(sceneIndex);
        post("setforge-loader: saved scene " + String.fromCharCode(65 + sceneIndex) + "\n");
    } else {
        var snapshot = recallScene(sceneIndex);
        if (!snapshot) return;

        if (snapshot.activePresetIndex >= 0 && snapshot.activePresetIndex !== activeSlotIndex) {
            activatePreset(snapshot.activePresetIndex);
        }

        stopAllChops();
        if (snapshot.heldChops) {
            var activePreset = getActivePreset();
            for (var i = 0; i < snapshot.heldChops.length; i++) {
                var hc = snapshot.heldChops[i];
                playingChops[hc.stem] = hc.col;
                if (activePreset && activePreset.chops && activePreset.chops[hc.stem]) {
                    var chopList = activePreset.chops[hc.stem];
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
        flushRgb(2);
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
        flushRgb(2);
    } else if (row === 7) {
        fxThrowCol = col;
        updateGrid2Colors();
        flushRgb(2);
    } else if (row === 8) {
        onTransportPress(col);
    }
}

function handleGrid2Release(row, col) {
    if (row === 6 && !fxFilterLatched) {
        fxFilterCol = 4;
        updateGrid2Colors();
        flushRgb(2);
    } else if (row === 7) {
        fxThrowCol = -1;
        updateGrid2Colors();
        flushRgb(2);
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
    updateAllPadColors();
    updateStatus();
}

// ═══════════════════════════════════════════════════════════
//  Message Handling (from UI / Max)
// ═══════════════════════════════════════════════════════════

function anything() {
    var msg = messagename;
    var args = arrayfromargs(arguments);

    if (msg === "init") {
        doInit();
    } else if (msg === "load") {
        if (args.length > 0) loadSet(args[0]);
        else post("setforge-loader: load requires a path\n");
    } else if (msg === "reload") {
        if (setData) {
            populateBanks();
            updateAllPadColors();
            updateStatus();
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
    } else if (msg === "panic") {
        executePanic();
    } else if (msg === "bar_tick") {
        flushRgb(1);
        flushRgb(2);
    } else if (msg === "debug") {
        dumpState();
    }
}

// ═══════════════════════════════════════════════════════════
//  Debug
// ═══════════════════════════════════════════════════════════

function dumpState() {
    post("\n=== setforge-loader state ===\n");
    post("deviceReady: " + deviceReady + "\n");
    post("manifest: " + (manifest ? manifest.tracks.length + " tracks" : "null") + "\n");
    post("setData: " + (setData ? setData.name : "null") + "\n");
    post("activeSlot: " + activeSlotIndex + "\n");

    // Preset slots
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

    // Playing chops
    var held = getHeldChops();
    post("playing: " + (held.length > 0 ? held.map(function(h) { return h.stem + ":" + h.col; }).join(", ") : "none") + "\n");

    // Modifiers
    var activeMods = [];
    for (var i = 0; i < MODIFIERS.length; i++) {
        if (modState[MODIFIERS[i]] !== "idle") {
            activeMods.push(MODIFIERS[i] + "=" + modState[MODIFIERS[i]]);
        }
    }
    post("modifiers: " + (activeMods.length > 0 ? activeMods.join(", ") : "none") + "\n");

    // Scenes
    var builtScenes = [];
    for (var i = 0; i < NUM_SCENES; i++) {
        if (scenes[i].state !== "empty") {
            builtScenes.push(String.fromCharCode(65 + i) + "=" + scenes[i].state);
        }
    }
    post("scenes: " + (builtScenes.length > 0 ? builtScenes.join(", ") : "none") + "\n");

    // FX
    post("fx: target=" + fxTarget + " filter=" + fxFilterCol + (fxFilterLatched ? "(latched)" : "") + " throw=" + fxThrowCol + "\n");

    // Stem tracks
    for (var i = 0; i < STEM_NAMES.length; i++) {
        var stem = STEM_NAMES[i];
        post("  track[" + stem + "]: " + (stemTrackIds[stem] || "not created") + "\n");
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
}

// Called by [live.thisdevice] bang — device is fully wired
function bang() {
    if (deviceReady) return; // only init once
    deviceReady = true;
    post("setforge-loader: device ready (model=" + LP_MODEL + ", single-grid=" + singleGridMode + ")\n");
    initLiveApi();

    // Enter programmer mode on Launchpad (via send/receive bridge to grid device)
    var enterCmd = LP_SYSEX_PROGRAMMER_MODE[LP_MODEL + "_enter"];
    if (enterCmd) {
        outlet(0, enterCmd);
        post("setforge-loader: sent programmer mode enter\n");
    }

    updateAllPadColors();
    updateStatus();
}

// Init data structures only (no outlet calls at load time)
doInit();
post("setforge-loader.js loaded\n");
