// setforge-loader — top-level JS controller
// Loaded by [js loader.js] in the Max patch.
//
// This file bridges Max messages to the setforge-live JS modules.
// It delegates to: chop-router, preset-banks, scene-memory,
// modifier-layer, fx-bus, launchpad-surface.

autowatch = 1;
inlets = 3;   // 0: Grid 1 MIDI, 1: Grid 2 MIDI, 2: messages/UI
outlets = 4;  // 0: Grid 1 MIDI out, 1: Grid 2 MIDI out, 2: LiveAPI, 3: status

function init() {
    post("setforge-loader: init\n");
    // TODO: Wire to module instances
    // TODO: Initialize Launchpad surfaces
    // TODO: Discover connected Launchpads
}

function msg_int(v) {
    // MIDI byte routing
    var inlet_idx = inlet;
    if (inlet_idx === 0) {
        // Grid 1 MIDI input
        // TODO: Parse note on/off, route to chop-router / preset-banks
    } else if (inlet_idx === 1) {
        // Grid 2 MIDI input
        // TODO: Parse note on/off, route to fx-bus / transport
    }
}

function anything() {
    // Message routing from UI elements
    var msg = messagename;
    var args = arrayfromargs(arguments);

    if (msg === "load") {
        post("setforge-loader: load set\n");
        // TODO: Parse manifest + set.json, populate preset banks
    } else if (msg === "reload") {
        post("setforge-loader: reload set\n");
        // TODO: Re-parse, preserve held chops
    } else if (msg === "eject") {
        post("setforge-loader: eject\n");
        // TODO: Stop all, clear all, reset Launchpads
    } else if (msg === "panic") {
        post("setforge-loader: PANIC\n");
        // TODO: router.stopAll(), mods.clearAll(), fx.bypass(), liveApi.stopAllClips()
    }
}

// Bar-boundary callback for RGB coalescing
function bar_tick() {
    // TODO: Flush pending RGB writes to both Launchpads
}

post("setforge-loader.js loaded\n");
