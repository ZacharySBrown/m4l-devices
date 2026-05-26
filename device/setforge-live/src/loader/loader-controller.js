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

// Side button function assignments (single-grid mode, left side top-to-bottom)
var SIDE_FUNC = ["MODE_TOGGLE", "TAP", "SYNC", "BPM_DOWN", "BPM_UP", "LOOP_IN", "LOOP_OUT", "PANIC"];

// Grid view mode (single-grid only)
var viewMode = "performance"; // "performance" or "control"
var viewModeLatched = false;
var viewModeLastPress = 0;
var singleGridMode = true; // true until second Launchpad detected

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
                    column: c + 1,
                    clipStart: loopStart,
                    clipLength: loopEnd - loopStart,
                    stemPath: chopPath,
                    disabled: false,
                    label: mc.label || "",
                    kind: mc.kind || "",
                    lengthBars: mc.length_bars || 0
                });
            }
            // Fill remaining columns as disabled
            for (var c = numChops; c < NUM_CHOPS; c++) {
                chops.push({ column: c + 1, clipStart: 0, clipLength: 0, stemPath: stem.path, disabled: true });
            }
        } else {
            // Fallback: fixed 4-bar grid from downbeat + BPM
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
var stemTrackIds = {};
var stemTrackIndices = {};

var WARP_MODES = { drums: 0, bass: 0, other: 4, vox: 4 };

function initLiveApi() {
    try {
        liveApi = new LiveAPI("live_set");
        post("setforge-loader: LiveAPI ready, tracks=" + liveApi.get("tracks").length + "\n");
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
var activeClipSet = "A";
var stagingPresetIndex = -1;
var stagingReady = false;

function activeSetOffset() { return activeClipSet === "A" ? 0 : 8; }
function stagingSetOffset() { return activeClipSet === "A" ? 8 : 0; }

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
                    clipApi.set("name", slot.trackId + "-" + stem + "-" + clipLabel);
                    clipApi.set("warping", 1);
                    clipApi.set("warp_mode", WARP_MODES[stem] || 0);
                    clipApi.set("looping", 1);
                    clipApi.set("launch_quantization", ROW_QUANT[stem]);

                    // Compute beats-per-second slope from known BPM
                    var trackBpm = slot.track.bpm || 95;
                    var secToBeat = trackBpm / 60.0;
                    var beatCount = (chop.lengthBars || 0) * BEATS_PER_BAR;

                    // Place two warp markers to define the tempo grid:
                    // marker 0: file start → beat 0
                    // marker 1: loop end (seconds) → correct beat position
                    if (beatCount > 0) {
                        var loopStartSec = chop.clipStart;
                        var loopEndSec = chop.clipStart + chop.clipLength;
                        var loopStartBeat = loopStartSec * secToBeat;
                        var loopEndBeat = loopStartBeat + beatCount;

                        // Set warp markers (add_warp_marker takes a Dict)
                        try {
                            var wm0 = new Dict();
                            wm0.set("beat_time", loopStartBeat);
                            wm0.set("sample_time", loopStartSec);
                            clipApi.call("add_warp_marker", wm0);

                            var wm1 = new Dict();
                            wm1.set("beat_time", loopEndBeat);
                            wm1.set("sample_time", loopEndSec);
                            clipApi.call("add_warp_marker", wm1);
                        } catch (eWm) {
                            post("  " + stem + " col " + chop.column + ": warp marker error: " + eWm + "\n");
                        }

                        // All positions in beats (warped clip convention)
                        clipApi.set("start_marker", loopStartBeat);
                        clipApi.set("end_marker", loopEndBeat);
                        clipApi.set("loop_start", loopStartBeat);
                        clipApi.set("loop_end", loopEndBeat);
                    } else {
                        // Oneshot: no loop, positions in seconds (unwarped)
                        clipApi.set("warping", 0);
                        clipApi.set("looping", 0);
                        clipApi.set("start_marker", chop.clipStart);
                        clipApi.set("end_marker", chop.clipStart + chop.clipLength);
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

function loadClipsForPreset(presetIdx) {
    loadClipsToSlotSet(presetIdx, activeSetOffset());
}

function stagePreset(presetIdx) {
    stagingPresetIndex = presetIdx;
    stagingReady = false;
    var loaded = loadClipsToSlotSet(presetIdx, stagingSetOffset());
    stagingReady = (loaded > 0);
    post("setforge-loader: staging " + (stagingReady ? "ready" : "failed") +
         " for preset " + presetIdx + "\n");
}

function commitStagedPreset() {
    activeClipSet = (activeClipSet === "A") ? "B" : "A";
    stagingPresetIndex = -1;
    stagingReady = false;
    post("setforge-loader: committed, active set now " + activeClipSet + "\n");
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
var manifestFilePath = null;

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
        post("setforge-loader: manifest read " + mStr.length + " chars\n");
        manifest = JSON.parse(mStr);

        // Always try to init LiveAPI and find/create stem tracks.
        // After autowatch reload, deviceReady is false but LiveAPI still works.
        if (!liveApi) initLiveApi();
        ensureScenes(NUM_CHOPS * 2);
        ensureStemTracks();

        populateBanks();

        updateStatus();
        updateAllPadColors();

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
    var active = getActivePreset();

    for (var c = 1; c <= 8; c++) {
        surface.queueRgb(1, 1, c, presetSlotColor(presetSlots[c - 1]));
    }

    for (var r = 2; r <= 5; r++) {
        var stem = ROW_STEM[r];
        for (var c = 1; c <= 8; c++) {
            surface.queueRgb(1, r, c, chopPadColor(stem, c, active));
        }
    }

    for (var c = 1; c <= 8; c++) {
        var mod = MODIFIERS[c - 1];
        var ms = modState[mod] || "idle";
        surface.queueRgb(1, 6, c, MOD_COLORS[ms] || MOD_COLORS.idle);
    }

    for (var c = 1; c <= 8; c++) {
        surface.queueRgb(1, 7, c, presetSlotColor(presetSlots[c - 1 + SLOTS_PER_BANK]));
    }

    for (var c = 1; c <= 8; c++) {
        var scene = scenes[c - 1];
        surface.queueRgb(1, 8, c, SCENE_COLORS[scene.state] || SCENE_COLORS.empty);
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
    // Check for side buttons via surface
    var sideIdx = surface.sideButtonIndex(note);
    if (sideIdx >= 0) {
        handleSideButtonPress(sideIdx);
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
        sendSurfaceRgb(1);
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
        sendSurfaceRgb(1);
    }
}

function onPresetPress(slotIndex) {
    var slot = presetSlots[slotIndex];
    if (!slot || slot.state === "empty" || slot.state === "loading" || slot.state === "error") return;

    // Auto-save manifest on preset switch (persists any nudged downbeats/bpms)
    if (manifestFilePath && activeSlotIndex >= 0) {
        saveManifest();
    }

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
function saveManifest() {
    if (!manifest || !manifestFilePath) {
        post("setforge-loader: save — no manifest loaded\n");
        return;
    }

    try {
        var jsonStr = JSON.stringify(manifest, null, 2);
        var f = new File(manifestFilePath, "w");
        if (!f.isopen) {
            post("setforge-loader: save — cannot open " + manifestFilePath + "\n");
            return;
        }
        f.writestring(jsonStr);
        f.close();
        post("setforge-loader: saved manifest to " + manifestFilePath + "\n");
    } catch (e) {
        post("setforge-loader: save error: " + e + "\n");
    }
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
        saveManifest();
    } else if (msg === "panic") {
        executePanic();
    } else if (msg === "bar_tick") {
        sendSurfaceRgb(1);
        sendSurfaceRgb(2);
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

function bang() {
    if (deviceReady) return;
    deviceReady = true;
    post("setforge-loader: device ready (model=" + surface.model + ", single-grid=" + singleGridMode + ")\n");
    initLiveApi();

    // Enter programmer mode via surface
    var enterCmd = surface.enterProgrammerMode();
    if (enterCmd) {
        outlet(0, enterCmd);
        post("setforge-loader: sent programmer mode enter\n");
    }

    updateAllPadColors();
    updateStatus();
}

// Init data structures only (no outlet calls at load time)
doInit();
post("setforge-loader.js loaded (surface=" + surface.model + ")\n");
