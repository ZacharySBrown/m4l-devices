// setforge-arranger — main [js] entry point
// ─────────────────────────────────────────────────────────────────────────────
// Thin wrapper that include()s the original stemforge v0 JS modules:
//   - sf_arrangement_loader.js  (clip creation, loop regions)
//   - sf_arrangement_reader.js  (snapshot export, locator reading)
//   - sf_locator_anchor.js      (re-anchor from locator)
//
// Patcher wiring:
//   inlet 0:  messages from UI (load, export, eject, anchor, debug)
//   outlet 0: status messages → live.comment display
//   outlet 1: shell commands → [shell] object (for stemforge re-anchor)
//   outlet 2: reload manifest path → routes back to loadArrangementFromManifest
//
// The original v0 modules are used UNMODIFIED — all the battle-tested logic
// for warping, fading, stem aliasing, locator snapping, and re-anchor is
// preserved exactly as it was in the working stemforge device.

autowatch = 1;
inlets = 1;
outlets = 3;  // 0: status, 1: shell, 2: reload

// ── State ──

var _lastManifestPath = null;
var _lastBpm = 0;
var _lastClipCount = 0;

// ── Status helper (mirrors v0 _alStatus / _arrStatus pattern) ──

function status(msg) {
    try { post("[setforge-arranger] " + String(msg) + "\n"); } catch (_) {}
    try { outlet(0, "set", String(msg)); } catch (_) {}
}

// ── Include the original v0 modules ──
// Max's include() loads a .js file into this [js]'s scope, making all its
// top-level functions callable. The files are resolved via the Max search
// path (deployed to ~/Documents/Max N/Packages/setforge-live/javascript/).

function _includeModules() {
    try { include("sf_arrangement_loader.js"); } catch (e) {
        status("include sf_arrangement_loader failed: " + e);
    }
    try { include("sf_arrangement_reader.js"); } catch (e) {
        status("include sf_arrangement_reader failed: " + e);
    }
    try { include("sf_locator_anchor.js"); } catch (e) {
        status("include sf_locator_anchor failed: " + e);
    }
}

// ── Message dispatch ──

function anything() {
    var msg = messagename;
    var args = arrayfromargs(arguments);

    if (msg === "init") {
        _includeModules();
        status("init (modules loaded)");

    } else if (msg === "load" || msg === "loadArrangementFromManifest") {
        _includeModules();
        if (!args.length) {
            status("load requires a manifest path");
            return;
        }
        // Handle shift as optional trailing numeric arg
        var shiftBeats = 0;
        var pathArgs = args.slice();
        if (pathArgs.length >= 2) {
            var tail = pathArgs[pathArgs.length - 1];
            var n = Number(tail);
            if (!isNaN(n) && isFinite(n)) {
                shiftBeats = n;
                pathArgs = pathArgs.slice(0, pathArgs.length - 1);
            }
        }
        var manifestPath = pathArgs.join(" ");
        if (!manifestPath) {
            status("load: empty path");
            return;
        }
        status("loading " + manifestPath + (shiftBeats ? " shift=" + shiftBeats : ""));
        if (typeof runArrangementLoad === "function") {
            var ok = runArrangementLoad(manifestPath, shiftBeats);
            _lastManifestPath = manifestPath;
            status(ok ? "load complete" : "load failed — check Max console");
        } else {
            status("runArrangementLoad not available (include failed?)");
        }

    } else if (msg === "export") {
        _includeModules();
        var outPath;
        if (args.length) {
            outPath = args.join(" ");
        } else if (_lastManifestPath) {
            var dir = _lastManifestPath.replace(/\/[^/]+$/, "");
            outPath = dir + "/arrangement_snapshot.json";
        } else {
            status("export requires an output path (no manifest loaded)");
            return;
        }
        if (typeof runArrangementExport === "function") {
            var ok = runArrangementExport(outPath);
            status(ok ? "snapshot written: " + outPath : "export failed");
        } else {
            status("runArrangementExport not available (include failed?)");
        }

    } else if (msg === "anchor" || msg === "reanchor") {
        _includeModules();
        if (typeof anchor === "function") {
            // If a dir is passed, use it; otherwise the anchor module
            // uses its cached TRACK_DIR.
            if (args.length) {
                anchor(args.join(" "));
            } else if (_lastManifestPath) {
                var dir = _lastManifestPath.replace(/\/[^/]+$/, "");
                anchor(dir);
            } else {
                status("anchor: no manifest loaded — load one first");
            }
        } else {
            status("anchor not available (include failed?)");
        }

    } else if (msg === "eject") {
        _lastManifestPath = null;
        _lastBpm = 0;
        _lastClipCount = 0;
        status("ejected");

    } else if (msg === "debug") {
        status("manifest: " + (_lastManifestPath || "(none)"));

    } else if (msg === "anchor_complete") {
        // Routed from [shell] → NDJSON parser → here after stemforge re-anchor
        _includeModules();
        if (typeof onAnchorComplete === "function") {
            onAnchorComplete.apply(null, args);
        }

    } else if (msg === "anchor_started") {
        if (typeof onAnchorStarted === "function") {
            onAnchorStarted();
        }

    } else if (msg === "anchor_error") {
        if (typeof onAnchorError === "function") {
            onAnchorError.apply(null, args);
        }

    } else {
        status("unknown message: " + msg);
    }
}

function bang() {
    _includeModules();
    status("ready");
}

// Load modules on script init
_includeModules();

post("setforge-arranger.js loaded\n");
