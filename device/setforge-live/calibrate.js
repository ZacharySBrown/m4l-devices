// setforge-calibrate — fully wired Max JS controller
// Loaded by [js calibrate.js] in the Max patch.
//
// Implements: track loading, warp-marker observation,
// downbeat validation, .calib_override.json writing.
//
// Max [js] uses SpiderMonkey (ES5). No require(), no modules.

autowatch = 1;
inlets = 2;   // 0: messages/UI, 1: warp-marker observer
outlets = 3;  // 0: LiveAPI commands, 1: status display, 2: file writes

// ═══════════════════════════════════════════════════════════
//  State
// ═══════════════════════════════════════════════════════════

var manifest = null;
var setData = null;
var tracks = [];         // validated tracks from manifest
var currentTrackIdx = -1;
var currentStem = "drums";
var autoDownbeat = 0;
var currentMarker = 0;
var validationState = {};  // trackId -> "green_auto" | "yellow_pending" | "red" | "validated_by_ear" | "varying"

var STEM_NAMES = ["drums", "bass", "other", "vox"];

// ═══════════════════════════════════════════════════════════
//  Manifest Loading
// ═══════════════════════════════════════════════════════════

function loadManifest(path) {
    post("setforge-calibrate: loading manifest from " + path + "\n");
    try {
        var f = new File(path, "r");
        if (!f.isopen) {
            post("setforge-calibrate: cannot open: " + path + "\n");
            return;
        }
        var str = f.readstring(f.eof);
        f.close();
        manifest = JSON.parse(str);

        tracks = [];
        validationState = {};

        if (manifest.tracks) {
            for (var i = 0; i < manifest.tracks.length; i++) {
                var t = manifest.tracks[i];
                if (!t || !t.id || !t.bpm) continue;
                tracks.push(t);

                if (t.varying) {
                    validationState[t.id] = "varying";
                } else if (t.validated) {
                    validationState[t.id] = "green_auto";
                } else if (!t.stems || !t.stems.drums) {
                    validationState[t.id] = "red";
                } else {
                    validationState[t.id] = "yellow_pending";
                }
            }
        }

        currentTrackIdx = -1;
        updateTrackChooser();
        updateSetState();

        post("setforge-calibrate: loaded " + tracks.length + " tracks\n");
    } catch (e) {
        post("setforge-calibrate: load error: " + e + "\n");
    }
}

// ═══════════════════════════════════════════════════════════
//  Track Loading & Audition
// ═══════════════════════════════════════════════════════════

function loadTrack(idx) {
    if (idx < 0 || idx >= tracks.length) return;
    currentTrackIdx = idx;
    var track = tracks[idx];

    var stem = track.stems ? track.stems[currentStem] : null;
    if (!stem || !stem.path) {
        post("setforge-calibrate: stem '" + currentStem + "' missing for " + track.id + "\n");
        return;
    }

    autoDownbeat = track.downbeat_sec || 0;
    currentMarker = autoDownbeat;

    // Tell Max to load the stem into the audition track
    outlet(0, "load_stem", stem.path, autoDownbeat, track.bpm);

    updateDisplay();
    post("setforge-calibrate: loaded " + track.id + " (" + currentStem + ")\n");
}

function nextUnverified() {
    if (tracks.length === 0) return;

    var startIdx = (currentTrackIdx >= 0) ? currentTrackIdx + 1 : 0;
    for (var i = 0; i < tracks.length; i++) {
        var idx = (startIdx + i) % tracks.length;
        var state = validationState[tracks[idx].id];
        if (state === "yellow_pending" || state === "red") {
            loadTrack(idx);
            return;
        }
    }
    post("setforge-calibrate: all tracks validated or varying\n");
}

function switchStem(stemIdx) {
    if (stemIdx < 0 || stemIdx >= STEM_NAMES.length) return;
    currentStem = STEM_NAMES[stemIdx];
    if (currentTrackIdx >= 0) {
        loadTrack(currentTrackIdx);
    }
}

// ═══════════════════════════════════════════════════════════
//  Warp Marker Observer
// ═══════════════════════════════════════════════════════════

function warpMarkerChanged(sampleTime) {
    currentMarker = sampleTime;
    updateDisplay();
}

// ═══════════════════════════════════════════════════════════
//  Validation & Override Writing
// ═══════════════════════════════════════════════════════════

function validateCurrent() {
    if (currentTrackIdx < 0 || currentTrackIdx >= tracks.length) return;
    var track = tracks[currentTrackIdx];

    var override = {
        track_id: track.id,
        downbeat_sec: currentMarker,
        validated_at: new Date().toISOString(),
        method: "warp_marker_drag",
        delta_from_auto_sec: Math.round((currentMarker - autoDownbeat) * 1000) / 1000
    };

    // Determine override file path
    var stem = track.stems ? track.stems[currentStem] : null;
    if (!stem || !stem.path) {
        post("setforge-calibrate: no stem path for override write\n");
        return;
    }
    var stemDir = stem.path.replace(/[^\/\\]*$/, "");
    var overridePath = stemDir + ".calib_override.json";

    // Write via outlet (Max will handle file I/O)
    var overrideStr = JSON.stringify(override, null, 2);
    outlet(2, "write_override", overridePath, overrideStr);

    // Update state
    validationState[track.id] = "validated_by_ear";
    updateDisplay();
    updateSetState();

    post("setforge-calibrate: validated " + track.id +
         " (delta=" + override.delta_from_auto_sec + "s)\n");
}

function revertMarker() {
    if (currentTrackIdx < 0) return;
    currentMarker = autoDownbeat;
    outlet(0, "set_marker", autoDownbeat);
    updateDisplay();
}

// ═══════════════════════════════════════════════════════════
//  Audition Control
// ═══════════════════════════════════════════════════════════

function startAudition() {
    outlet(0, "audition_start");
}

function toggleClick() {
    outlet(0, "click_toggle");
}

// ═══════════════════════════════════════════════════════════
//  Display Updates
// ═══════════════════════════════════════════════════════════

function updateDisplay() {
    var track = (currentTrackIdx >= 0 && currentTrackIdx < tracks.length) ?
        tracks[currentTrackIdx] : null;

    // Downbeat display
    outlet(1, "set", "cal-downbeat",
        "calibrated downbeat: " + autoDownbeat.toFixed(3) + " sec (auto)");

    // Current marker
    var delta = currentMarker - autoDownbeat;
    var deltaStr = (delta >= 0 ? "+" : "") + delta.toFixed(3);
    outlet(1, "set", "cal-marker",
        "current marker: " + currentMarker.toFixed(3) + " sec (delta " + deltaStr + " sec)");
}

function updateTrackChooser() {
    // Send track list to umenu
    outlet(1, "clear", "track_chooser");
    for (var i = 0; i < tracks.length; i++) {
        var t = tracks[i];
        var state = validationState[t.id] || "?";
        var prefix = "";
        if (state === "green_auto") prefix = "\u25CF ";        // green dot
        else if (state === "yellow_pending") prefix = "\u25CB "; // yellow
        else if (state === "red") prefix = "\u2716 ";            // red x
        else if (state === "validated_by_ear") prefix = "\u2714 "; // checkmark
        else if (state === "varying") prefix = "\u2500 ";        // dash
        outlet(1, "append", "track_chooser", prefix + t.display_name + " (" + t.artist + ")");
    }
}

function updateSetState() {
    var validated = 0;
    var unverified = 0;
    var red = 0;
    var varying = 0;

    for (var i = 0; i < tracks.length; i++) {
        var state = validationState[tracks[i].id];
        if (state === "green_auto" || state === "validated_by_ear") validated++;
        else if (state === "yellow_pending") unverified++;
        else if (state === "red") red++;
        else if (state === "varying") varying++;
    }

    outlet(1, "set", "cal-setstate",
        "set state: " + validated + " validated \u00b7 " +
        unverified + " unverified \u00b7 " + red + " red" +
        (varying > 0 ? " \u00b7 " + varying + " varying" : ""));
}

// ═══════════════════════════════════════════════════════════
//  Message Handling
// ═══════════════════════════════════════════════════════════

function msg_int(v) {
    if (inlet === 1) {
        // Warp marker observer sends float/int sample time
        warpMarkerChanged(v);
    }
}

function msg_float(v) {
    if (inlet === 1) {
        warpMarkerChanged(v);
    }
}

function anything() {
    var msg = messagename;
    var args = arrayfromargs(arguments);

    if (msg === "init") {
        doInit();
    } else if (msg === "load-cal") {
        if (currentTrackIdx >= 0) {
            loadTrack(currentTrackIdx);
        } else if (tracks.length > 0) {
            loadTrack(0);
        }
    } else if (msg === "next-cal") {
        nextUnverified();
    } else if (msg === "audition") {
        startAudition();
    } else if (msg === "click") {
        toggleClick();
    } else if (msg === "validated") {
        validateCurrent();
    } else if (msg === "revert") {
        revertMarker();
    } else if (msg === "stem_select") {
        if (args.length > 0) switchStem(args[0]);
    } else if (msg === "track_chooser") {
        if (args.length > 0) loadTrack(args[0]);
    } else if (msg === "load_manifest") {
        if (args.length > 0) loadManifest(args[0]);
    }
}

// ═══════════════════════════════════════════════════════════
//  Init
// ═══════════════════════════════════════════════════════════

function doInit() {
    post("setforge-calibrate: init\n");
    tracks = [];
    currentTrackIdx = -1;
    currentStem = "drums";
    autoDownbeat = 0;
    currentMarker = 0;
    validationState = {};
}

doInit();
post("setforge-calibrate.js loaded\n");
