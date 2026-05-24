// setforge-calibrate — top-level JS controller
// Loaded by [js calibrate.js] in the Max patch.

autowatch = 1;
inlets = 2;   // 0: messages/UI, 1: warp-marker observer
outlets = 3;  // 0: LiveAPI commands, 1: status display, 2: file writes

var current_track = null;
var current_stem = "drums";
var auto_downbeat = 0;
var current_marker = 0;

function init() {
    post("setforge-calibrate: init\n");
    // TODO: Scan for set files, populate track chooser
}

function anything() {
    var msg = messagename;
    var args = arrayfromargs(arguments);

    if (msg === "load-cal") {
        post("setforge-calibrate: load track\n");
        // TODO: Load stem into calibrate-audition track
        // TODO: Place warp marker at manifest downbeat_sec
        // TODO: Set up 4-bar loop
    } else if (msg === "next-cal") {
        post("setforge-calibrate: next track\n");
        // TODO: Advance to next unverified track
    } else if (msg === "audition") {
        post("setforge-calibrate: audition\n");
        // TODO: Start transport with metronome
    } else if (msg === "validated") {
        post("setforge-calibrate: validated\n");
        // TODO: Write .calib_override.json via override-writer
    } else if (msg === "revert") {
        post("setforge-calibrate: revert\n");
        // TODO: Reset warp marker to auto-calibrated value
    } else if (msg === "stem_select") {
        current_stem = ["drums", "bass", "other", "vox"][args[0]] || "drums";
        post("setforge-calibrate: stem = " + current_stem + "\n");
        // TODO: Reload audition clip with selected stem
    }
}

// Warp marker observer callback
function warp_marker_changed(sample_time) {
    current_marker = sample_time;
    // TODO: Update display
    outlet(1, "set", "current marker: " + current_marker.toFixed(3) + " sec");
}

post("setforge-calibrate.js loaded\n");
