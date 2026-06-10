// ═══════════════════════════════════════════════════════════
//  setforge-arranger — arrangement-view loader + snapshot exporter
// ═══════════════════════════════════════════════════════════
//
// Loaded by [js arranger.js] in the Max patch (after concat build).
// Implements:
//   - Load prechop_manifest.json into arrangement-view clips
//   - Export arrangement snapshot for re-anchor / EP-133 song-mode
//   - Re-anchor: shift arrangement by N beats without re-cutting audio
//   - Eject: wipe stemforge-owned arrangement clips
//
// Ported from stemforge v0:
//   - sf_arrangement_loader.js (clip creation, loop regions, stem aliasing)
//   - sf_arrangement_reader.js (snapshot builder, locator reader)
//
// Max [js] uses SpiderMonkey (ES5). No require(), no modules.

autowatch = 1;
inlets = 1;   // messages from UI
outlets = 2;  // 0: status, 1: LiveAPI commands

// ═══════════════════════════════════════════════════════════
//  State
// ═══════════════════════════════════════════════════════════

var _arrManifestPath = null;   // last-loaded manifest path (absolute POSIX)
var _arrManifestBpm = 0;       // BPM from last-loaded manifest
var _arrClipCount = 0;         // total clips created by last load
var _arrDebugMode = false;

// ═══════════════════════════════════════════════════════════
//  Logging
// ═══════════════════════════════════════════════════════════

function _arrHomeDir() {
    var h = "";
    try {
        if (typeof max !== "undefined" && max && typeof max.getsystemvariable === "function") {
            h = String(max.getsystemvariable("HOME") || "");
        }
    } catch (_) {}
    if (!h) {
        try {
            if (typeof File !== "undefined" && typeof File.getenv === "function") {
                h = String(File.getenv("HOME") || "");
            }
        } catch (_) {}
    }
    // No hardcoded fallback — if both methods fail, return empty string.
    // Callers must handle the empty case rather than silently writing to
    // another user's home directory.
    if (h && h.charAt(h.length - 1) === "/") h = h.substring(0, h.length - 1);
    return h;
}

function _arrFileLog(msg) {
    try {
        var homePath = _arrHomeDir();
        if (!homePath) return;
        var dir = homePath + "/stemforge/logs";
        var path = dir + "/sf_debug.log";
        var maxPath = "Macintosh HD:" + path;
        try { new Folder("Macintosh HD:" + dir).close(); }
        catch (_) {
            try {
                var ff = new File("Macintosh HD:" + dir + "/.keep", "write", "TEXT", "TEXT");
                if (ff.isopen) { ff.writestring(""); ff.close(); }
            } catch (_) {}
        }
        var ts;
        try { ts = (new Date()).toISOString(); }
        catch (_) { ts = String(new Date().getTime()); }
        var line = "[" + ts + "] [setforge-arranger] " + String(msg) + "\n";
        var f = new File(maxPath, "write", "TEXT", "TEXT");
        if (!f.isopen) return;
        try { f.position = f.eof; } catch (_) {}
        f.writestring(line);
        try { f.eof = f.position; } catch (_) {}
        f.close();
    } catch (_) {}
}

function _arrStatus(msg) {
    try { post("[setforge-arranger] " + String(msg) + "\n"); } catch (_) {}
    _arrFileLog(msg);
}

// ═══════════════════════════════════════════════════════════
//  Path helpers
// ═══════════════════════════════════════════════════════════

function _arrExpandTilde(p) {
    var s = String(p || "");
    if (s === "~") return _arrHomeDir();
    if (s.length >= 2 && s.charAt(0) === "~" && s.charAt(1) === "/") {
        return _arrHomeDir() + s.substring(1);
    }
    return s;
}

function _arrToMaxPath(p) {
    var s = _arrExpandTilde(p);
    if (s.length > 0 && s.charAt(0) === "/") return "Macintosh HD:" + s;
    return s;
}

function _arrStripHfsPrefix(s) {
    if (!s) return "";
    var str = String(s);
    if (str.indexOf("Macintosh HD:") === 0) {
        return str.substring("Macintosh HD:".length);
    }
    return str;
}

function _arrDirname(absPath) {
    var s = String(absPath);
    var i = s.lastIndexOf("/");
    if (i <= 0) return "/";
    return s.substring(0, i);
}

function _arrJoin(dir, rel) {
    var r = String(rel);
    if (r.length > 0 && r.charAt(0) === "/") return r;
    var d = String(dir);
    if (d.length > 0 && d.charAt(d.length - 1) === "/") {
        d = d.substring(0, d.length - 1);
    }
    return d + "/" + r;
}

// ═══════════════════════════════════════════════════════════
//  LOM helpers
// ═══════════════════════════════════════════════════════════

function _arrGetLomNumber(api, prop) {
    try {
        var v = api.get(prop);
        if (v && typeof v === "object") return Number(v[0]);
        return Number(v);
    } catch (_) {
        return NaN;
    }
}

function _arrGetLomString(api, prop) {
    try {
        var v = api.get(prop);
        var s = (v && typeof v === "object") ? v[0] : v;
        if (s === undefined || s === null) return "";
        var str = String(s);
        if (str === "undefined") return "";
        return str;
    } catch (_) {
        return "";
    }
}

// ═══════════════════════════════════════════════════════════
//  File I/O — chunked reads/writes (Max 32767-char cap)
// ═══════════════════════════════════════════════════════════

function _arrReadFile(absPath) {
    try {
        var maxPath = _arrToMaxPath(absPath);
        var f = new File(maxPath, "read");
        if (!f.isopen) {
            _arrStatus("read: could not open " + absPath);
            return null;
        }
        try { f.position = 0; } catch (_) {}
        var MAX_CHUNK = 32767;
        var raw = "";
        var prev = -1;
        while (f.position < f.eof && f.position !== prev) {
            prev = f.position;
            var chunk = f.readstring(MAX_CHUNK) || "";
            if (!chunk.length) break;
            raw += chunk;
        }
        f.close();
        return raw;
    } catch (e) {
        _arrStatus("read error: " + e);
        return null;
    }
}

function _arrWriteJson(outputPath, obj) {
    var contents;
    try { contents = JSON.stringify(obj, null, 2); }
    catch (e) {
        _arrStatus("stringify error: " + e);
        return false;
    }
    try {
        var maxPath = _arrToMaxPath(outputPath);
        var f = new File(maxPath, "write", "TEXT", "TEXT");
        if (!f.isopen) {
            _arrStatus("write: could not open " + outputPath);
            return false;
        }
        try { f.position = 0; } catch (_) {}
        try { f.eof = 0; } catch (_) {}
        var MAX_CHUNK = 32767;
        var written = 0;
        var prev = -1;
        while (written < contents.length && f.position !== prev) {
            prev = f.position;
            var end = written + MAX_CHUNK;
            if (end > contents.length) end = contents.length;
            f.writestring(contents.substring(written, end));
            written = end;
        }
        try { f.eof = f.position; } catch (_) {}
        f.close();
        if (written < contents.length) {
            _arrStatus("write: short write " + written + "/" + contents.length);
            return false;
        }
        return true;
    } catch (e) {
        _arrStatus("write error: " + e);
        return false;
    }
}

// ═══════════════════════════════════════════════════════════
//  Track lookup / creation
// ═══════════════════════════════════════════════════════════

// Stem alias table — handles drum/drums and vocal/vocals naming variance.
// Without this, substring-match fails against singular tracks that LOAD
// FORGE created ("definition | drum") and falls through to creating
// duplicate "drums"/"vocals" tracks.
var _ARR_STEM_ALIASES = {
    drum: ["drum", "drums"],
    drums: ["drums", "drum"],
    vocal: ["vocal", "vocals"],
    vocals: ["vocals", "vocal"],
    bass: ["bass"],
    other: ["other"]
};

function _arrTrackCount() {
    return new LiveAPI("live_set").getcount("tracks");
}

function _arrTrackName(i) {
    var raw = new LiveAPI("live_set tracks " + i).get("name");
    return (raw && typeof raw === "object") ? String(raw[0]) : String(raw);
}

function _arrIsAudioTrack(i) {
    var api = new LiveAPI("live_set tracks " + i);
    var v = api.get("has_audio_input");
    if (v && typeof v === "object") return Number(v[0]) === 1;
    return Number(v) === 1;
}

function _arrFindTrackForStem(stemName) {
    var n = _arrTrackCount();
    var lc = String(stemName).toLowerCase();
    var aliases = _ARR_STEM_ALIASES[lc] || [lc];
    var firstContains = -1;
    for (var i = 0; i < n; i++) {
        if (!_arrIsAudioTrack(i)) continue;
        var name = _arrTrackName(i).toLowerCase();
        for (var ai = 0; ai < aliases.length; ai++) {
            var alias = aliases[ai];
            if (name === alias) return i;
            if (firstContains < 0 && name.indexOf(alias) >= 0) firstContains = i;
        }
    }
    return firstContains;
}

function _arrCreateAudioTrack(stemName) {
    var liveSet = new LiveAPI("live_set");
    var before = _arrTrackCount();
    try {
        liveSet.call("create_audio_track", -1);
    } catch (e) {
        _arrStatus("create_audio_track failed: " + e);
        return -1;
    }
    var after = _arrTrackCount();
    if (after <= before) {
        _arrStatus("create_audio_track: track count did not increase");
        return -1;
    }
    var newIdx = after - 1;
    try {
        new LiveAPI("live_set tracks " + newIdx).set("name", stemName);
    } catch (_) {}
    return newIdx;
}

function _arrResolveTrack(stemName) {
    var idx = _arrFindTrackForStem(stemName);
    if (idx >= 0) {
        _arrStatus("stem " + stemName + " -> track " + idx + " (" + _arrTrackName(idx) + ")");
        return idx;
    }
    idx = _arrCreateAudioTrack(stemName);
    if (idx >= 0) {
        _arrStatus("stem " + stemName + " -> created track " + idx);
    }
    return idx;
}

// ═══════════════════════════════════════════════════════════
//  Clip creation on arrangement view
// ═══════════════════════════════════════════════════════════

function _arrFindClipAtBeat(trackIdx, beat) {
    // Reverse walk: create_audio_clip appends, so the new clip is at the end.
    // O(1) in the common case vs O(N) forward walk.
    var trackApi = new LiveAPI("live_set tracks " + trackIdx);
    var n = 0;
    try { n = trackApi.getcount("arrangement_clips") | 0; }
    catch (_) { return -1; }
    if (n === 0) return -1;

    for (var i = n - 1; i >= 0; i--) {
        var clip = new LiveAPI(
            "live_set tracks " + trackIdx + " arrangement_clips " + i
        );
        if (!clip || clip.id === "0") continue;
        var st = _arrGetLomNumber(clip, "start_time");
        if (isFinite(st) && Math.abs(st - beat) < 1e-3) return i;
    }
    return -1;
}

function _arrCreateAndConfigureClip(trackIdx, absWavPath, startBeat, lengthBeats,
                                    loopStartSec, loopEndSec, bpm) {
    // Creates an audio clip on trackIdx's arrangement view at startBeat,
    // sources from absWavPath, sets the playback span (start_marker /
    // end_marker) and loop region to [loopStartSec, loopEndSec] in SECONDS
    // (warping is OFF — markers are in seconds, not beats).
    //
    // Returns the clip's arrangement_clips index (>= 0) on success, -1 on fail.
    var trackPath = "live_set tracks " + trackIdx;
    var trackApi = new LiveAPI(trackPath);

    try {
        trackApi.call("create_audio_clip", absWavPath, startBeat);
    } catch (e) {
        _arrStatus("create_audio_clip failed: " + e + " path=" + absWavPath);
        return -1;
    }

    var idx = _arrFindClipAtBeat(trackIdx, startBeat);
    if (idx < 0) {
        _arrStatus("created clip not found at beat " + startBeat
            + " (track " + trackIdx + ")");
        return -1;
    }

    var clipPath = trackPath + " arrangement_clips " + idx;
    var clip = new LiveAPI(clipPath);

    // Warping OFF — clips are pre-rendered at manifest BPM, unwarped playback
    // at native rate stays in sync with the arrangement timeline.
    // Warping OFF: chunks are pre-rendered at manifest BPM and the project
    // tempo is set to match. With warping off, start_marker/end_marker/
    // loop_start/loop_end are in SECONDS (not beats). This avoids Live's
    // auto-warp BPM guessing which gets wildly wrong on short (~15s) chunks.
    try { clip.set("warping", 0); } catch (_) {}

    // Disable default arrangement fades — they cause discontinuities
    // at chunk boundaries.
    try { clip.set("fades_are_enabled", 0); } catch (_) {}

    // Loop / markers: all in SECONDS.
    // Order matters in some Live versions — set looping=1 LAST.
    try { clip.set("start_marker", loopStartSec); } catch (e) {
        _arrStatus("set start_marker fail: " + e);
    }
    try { clip.set("end_marker", loopEndSec); } catch (e) {
        _arrStatus("set end_marker fail: " + e);
    }
    try { clip.set("loop_start", loopStartSec); } catch (e) {
        _arrStatus("set loop_start fail: " + e);
    }
    try { clip.set("loop_end", loopEndSec); } catch (e) {
        _arrStatus("set loop_end fail: " + e);
    }
    try { clip.set("looping", 1); } catch (e) {
        _arrStatus("set looping fail: " + e);
    }

    // lengthBeats is not settable via LOM (Clip.length is read-only)
    void lengthBeats;

    return idx;
}

// ═══════════════════════════════════════════════════════════
//  Manifest -> arrangement view
// ═══════════════════════════════════════════════════════════

function _arrSecToBeats(sec, bpm) {
    var b = Number(sec) * Number(bpm) / 60.0;
    if (!isFinite(b) || b < 0) return 0;
    return b;
}

function _arrClearStemfgClips(trackIdx, manifestDir) {
    // Delete every arrangement_clip on this track whose file_path sits inside
    // manifestDir. Scoping preserves user-placed clips while wiping prior
    // stemforge-owned chunks (necessary for re-anchor / reload).
    // Walk in REVERSE so deletion doesn't shift unvisited indices.
    var trackApi = new LiveAPI("live_set tracks " + trackIdx);
    var n = 0;
    try { n = trackApi.getcount("arrangement_clips") | 0; }
    catch (_) { return 0; }
    var deleted = 0;
    var prefix = String(manifestDir || "");
    for (var i = n - 1; i >= 0; i--) {
        var clipPath = "live_set tracks " + trackIdx + " arrangement_clips " + i;
        var clip = new LiveAPI(clipPath);
        if (!clip || clip.id === "0") continue;
        var fp = "";
        try { fp = String(clip.get("file_path") || ""); } catch (_) {}
        if (!fp) continue;
        if (fp.indexOf(prefix) !== 0) continue;
        try {
            trackApi.call("delete_clip", "id", clip.id);
            deleted++;
        } catch (e) {
            _arrStatus("delete_clip failed for " + fp + ": " + e);
        }
    }
    return deleted;
}

function _arrLoadStem(stemName, stemBlock, manifestDir, bpm, beatsPerBar, shiftBeats) {
    var trackIdx = _arrResolveTrack(stemName);
    if (trackIdx < 0) {
        _arrStatus("could not resolve track for stem " + stemName);
        return { ok: false, clips_created: 0 };
    }

    // Wipe prior stemforge-owned clips before placing new ones
    var wiped = _arrClearStemfgClips(trackIdx, manifestDir);
    if (wiped > 0) {
        _arrStatus("stem " + stemName + " -> wiped " + wiped + " prior clip(s)");
    }

    var chunks = (stemBlock && stemBlock.chunks) ? stemBlock.chunks : [];
    var created = 0;
    var shift = Number(shiftBeats) || 0;

    for (var i = 0; i < chunks.length; i++) {
        var ch = chunks[i];
        if (!ch || !ch.file) continue;

        var absWav = _arrJoin(manifestDir, ch.file);
        var bars = (ch.bars != null) ? Number(ch.bars) : 4;
        // Prefer explicit start_bar (set by chunks[] adapter from bar_position).
        // Sequential i * bars fallback only works when all chunks are same length.
        var startBar = (ch.start_bar != null && isFinite(Number(ch.start_bar)))
            ? Number(ch.start_bar) : (i * bars);
        var startBeat = startBar * beatsPerBar + shift;
        // Clamp negative start_time (Ableton refuses it)
        if (startBeat < 0) startBeat = 0;
        // Markers in SECONDS (warping is off)
        var loopStartSec = Number(ch.loop_start_sec) || 0;
        var loopEndSec = Number(ch.loop_end_sec) || 0;
        var lengthBeats = bars * beatsPerBar;

        // Sanity: loop_end must be > loop_start
        if (loopEndSec <= loopStartSec) {
            _arrStatus("malformed loop region for " + stemName + " chunk "
                + (i + 1) + "; falling back to full clip");
            loopStartSec = 0;
            loopEndSec = Number(ch.total_sec) || (60 * lengthBeats / bpm);
        }

        var clipIdx = _arrCreateAndConfigureClip(
            trackIdx, absWav, startBeat, lengthBeats,
            loopStartSec, loopEndSec, bpm
        );
        if (clipIdx >= 0) created++;
    }

    return { ok: created > 0, clips_created: created };
}

// Adapt flat chunks[] (arrangement-manifest shape) into nested stems{}
// shape the loader expects. Field mapping:
//   audio_path    -> file
//   duration_bars -> bars
//   duration_sec  -> total_sec
//   bar_position  -> start_bar
function _arrAdaptChunksToStems(chunks) {
    var adapted = {};
    if (!Array.isArray(chunks)) return adapted;
    for (var ci = 0; ci < chunks.length; ci++) {
        var c = chunks[ci];
        if (!c || !c.stem || !c.audio_path) continue;
        var stemKey = String(c.stem);
        if (!adapted[stemKey]) adapted[stemKey] = { chunks: [] };
        adapted[stemKey].chunks.push({
            file: String(c.audio_path),
            bars: (c.duration_bars != null) ? Number(c.duration_bars) : 4,
            total_sec: Number(c.duration_sec) || 0,
            start_bar: (c.bar_position != null && isFinite(Number(c.bar_position)))
                ? Number(c.bar_position) : null,
            loop_start_sec: (c.loop_start_sec != null) ? Number(c.loop_start_sec) : undefined,
            loop_end_sec: (c.loop_end_sec != null) ? Number(c.loop_end_sec) : undefined
        });
    }
    return adapted;
}

// Resolve relative paths in a manifest's stems{} against the manifest dir.
// Mirrors the resolveManifestPaths pattern from loader-controller.js but
// adapted for the prechop manifest shape.
function _arrResolveManifestPaths(stems, manifestDir) {
    var resolved = 0;
    for (var stemName in stems) {
        if (!stems.hasOwnProperty(stemName)) continue;
        var chunks = stems[stemName].chunks || [];
        for (var i = 0; i < chunks.length; i++) {
            if (chunks[i].file && chunks[i].file.charAt(0) !== "/") {
                // Relative path — resolve against manifest directory
                // (but don't double-resolve; _arrJoin handles this in _arrLoadStem)
                resolved++;
            }
        }
    }
    if (resolved > 0 && _arrDebugMode) {
        _arrStatus("manifest has " + resolved + " relative path(s) (resolved at load time)");
    }
}

// ═══════════════════════════════════════════════════════════
//  Main load entry point
// ═══════════════════════════════════════════════════════════

function runArrangementLoad(manifestPath, shiftBeats) {
    if (!manifestPath || String(manifestPath).length === 0) {
        _arrStatus("runArrangementLoad: missing manifestPath");
        return false;
    }
    var path = _arrExpandTilde(String(manifestPath));
    var shift = Number(shiftBeats) || 0;

    var raw = _arrReadFile(path);
    if (raw == null) return false;
    var manifest;
    try { manifest = JSON.parse(raw); }
    catch (e) {
        _arrStatus("manifest parse error: " + e);
        return false;
    }

    var bpm = Number(manifest.bpm) || 120.0;
    var beatsPerBar = Number(manifest.beats_per_bar) || 4;
    var stems = manifest.stems || {};
    var manifestDir = _arrDirname(path);

    // Adapt flat chunks[] shape (auto-curation forge + sample-forge fixture)
    // into nested stems{} if no stems{} present.
    if ((!stems || Object.keys(stems).length === 0)
            && Array.isArray(manifest.chunks)) {
        stems = _arrAdaptChunksToStems(manifest.chunks);
        _arrStatus("arrangement: adapted " + manifest.chunks.length
            + " chunks -> " + Object.keys(stems).length + " stems (chunks[] shape)");
    }

    _arrResolveManifestPaths(stems, manifestDir);

    // Set Live project tempo to manifest BPM — chunks are pre-rendered at
    // this tempo and warping is off, so mismatched tempo = drift.
    if (bpm > 0 && isFinite(bpm)) {
        try { new LiveAPI("live_set").set("tempo", bpm); } catch (_) {}
        _arrStatus("project tempo -> " + bpm + " BPM");
    }

    var totalCreated = 0;
    var anyOk = false;
    for (var stemName in stems) {
        if (!Object.prototype.hasOwnProperty.call(stems, stemName)) continue;
        var res = _arrLoadStem(stemName, stems[stemName], manifestDir, bpm,
            beatsPerBar, shift);
        if (res.ok) anyOk = true;
        totalCreated += res.clips_created;
    }

    // Update state
    _arrManifestPath = path;
    _arrManifestBpm = bpm;
    _arrClipCount = totalCreated;

    _arrStatus("loaded " + totalCreated + " clips from " + path
        + " (bpm=" + bpm + ", beats_per_bar=" + beatsPerBar
        + (shift !== 0 ? ", shift=" + shift.toFixed(2) + " beats" : "") + ")");

    _arrUpdateStatusDisplay();
    return anyOk;
}

// ═══════════════════════════════════════════════════════════
//  Snapshot builder (arrangement reader)
// ═══════════════════════════════════════════════════════════

function _arrFindTrackByName(name) {
    var n = _arrTrackCount();
    for (var i = 0; i < n; i++) {
        if (_arrTrackName(i) === name) return i;
    }
    return -1;
}

function _arrReadLocators(beatToSec) {
    var liveSet = new LiveAPI("live_set");
    var count = 0;
    try { count = liveSet.getcount("cue_points") | 0; }
    catch (_) { count = 0; }
    var out = [];
    for (var i = 0; i < count; i++) {
        var cp;
        try { cp = new LiveAPI("live_set cue_points " + i); }
        catch (_) { continue; }
        if (!cp || cp.id === "0") continue;
        var name = _arrGetLomString(cp, "name");
        var beats = _arrGetLomNumber(cp, "time");
        if (!isFinite(beats)) continue;
        out.push({
            time_sec: beats * beatToSec,
            name: String(name || "")
        });
    }
    out.sort(function (a, b) { return a.time_sec - b.time_sec; });
    return out;
}

function _arrReadTrackClips(letter, beatToSec) {
    var trackIdx = _arrFindTrackByName(letter);
    if (trackIdx < 0) return [];

    var trackApi = new LiveAPI("live_set tracks " + trackIdx);
    var count = 0;
    try { count = trackApi.getcount("arrangement_clips") | 0; }
    catch (_) { count = 0; }

    var clips = [];
    for (var i = 0; i < count; i++) {
        var clip;
        try {
            clip = new LiveAPI(
                "live_set tracks " + trackIdx + " arrangement_clips " + i
            );
        } catch (_) { continue; }
        if (!clip || clip.id === "0") continue;

        var fp = _arrGetLomString(clip, "file_path");
        var startBeats = _arrGetLomNumber(clip, "start_time");
        var lengthBeats = _arrGetLomNumber(clip, "length");
        var warping = _arrGetLomNumber(clip, "warping");

        if (!fp) continue;

        clips.push({
            file_path: _arrStripHfsPrefix(fp),
            start_time_sec: isFinite(startBeats) ? startBeats * beatToSec : 0.0,
            length_sec: isFinite(lengthBeats) ? lengthBeats * beatToSec : 0.0,
            warping: (isFinite(warping) ? warping : 0) | 0
        });
    }
    clips.sort(function (a, b) {
        if (a.start_time_sec !== b.start_time_sec) {
            return a.start_time_sec - b.start_time_sec;
        }
        if (a.file_path < b.file_path) return -1;
        if (a.file_path > b.file_path) return 1;
        return 0;
    });
    return clips;
}

function _arrComputeArrangementLengthSec(snapshot) {
    var maxEnd = 0.0;
    var letters = ["A", "B", "C", "D"];
    for (var li = 0; li < letters.length; li++) {
        var clips = snapshot.tracks[letters[li]];
        for (var ci = 0; ci < clips.length; ci++) {
            var end = clips[ci].start_time_sec + clips[ci].length_sec;
            if (end > maxEnd) maxEnd = end;
        }
    }
    for (var li2 = 0; li2 < snapshot.locators.length; li2++) {
        if (snapshot.locators[li2].time_sec > maxEnd) {
            maxEnd = snapshot.locators[li2].time_sec;
        }
    }
    return maxEnd;
}

function buildArrangementSnapshot() {
    var liveSet = new LiveAPI("live_set");
    var tempoRaw = _arrGetLomNumber(liveSet, "tempo");
    var tempo = isFinite(tempoRaw) && tempoRaw > 0 ? tempoRaw : 120.0;

    var sigNumRaw = _arrGetLomNumber(liveSet, "signature_numerator");
    var sigDenRaw = _arrGetLomNumber(liveSet, "signature_denominator");
    var sigNum = isFinite(sigNumRaw) && sigNumRaw > 0 ? (sigNumRaw | 0) : 4;
    var sigDen = isFinite(sigDenRaw) && sigDenRaw > 0 ? (sigDenRaw | 0) : 4;

    var beatToSec = 60.0 / tempo;

    var locators = _arrReadLocators(beatToSec);
    var tracks = {
        A: _arrReadTrackClips("A", beatToSec),
        B: _arrReadTrackClips("B", beatToSec),
        C: _arrReadTrackClips("C", beatToSec),
        D: _arrReadTrackClips("D", beatToSec)
    };

    var song = {
        tempo: tempo,
        time_sig: [sigNum, sigDen],
        arrangement_length_sec: 0.0,
        locators: locators,
        tracks: tracks
    };
    song.arrangement_length_sec = _arrComputeArrangementLengthSec(song);
    return {
        schema_version: 2,
        songs: [song]
    };
}

function runArrangementExport(outputPath) {
    if (!outputPath || String(outputPath).length === 0) {
        _arrStatus("runArrangementExport: missing outputPath");
        return false;
    }
    var path = _arrExpandTilde(String(outputPath));
    var snapshot;
    try { snapshot = buildArrangementSnapshot(); }
    catch (e) {
        _arrStatus("buildArrangementSnapshot threw: " + e);
        return false;
    }
    var ok = _arrWriteJson(path, snapshot);
    if (ok) {
        var song = (snapshot.songs && snapshot.songs.length) ? snapshot.songs[0] : snapshot;
        var letters = ["A", "B", "C", "D"];
        var summary = [];
        for (var li = 0; li < letters.length; li++) {
            summary.push(letters[li] + "=" + song.tracks[letters[li]].length);
        }
        _arrStatus("snapshot written: " + path + " | locators="
            + song.locators.length + " | clips: " + summary.join(" "));
    }
    return ok;
}

// ═══════════════════════════════════════════════════════════
//  Status display
// ═══════════════════════════════════════════════════════════

function _arrUpdateStatusDisplay() {
    try {
        var patcher = this.patcher;
        if (!patcher) return;

        // Update status comments by scripting_name
        var statusManifest = patcher.getnamed("status-manifest");
        if (statusManifest) {
            var label = _arrManifestPath
                ? _arrManifestPath.substring(_arrManifestPath.lastIndexOf("/") + 1)
                : "(none)";
            statusManifest.set("text", "manifest: " + label);
        }
        var statusBpm = patcher.getnamed("status-bpm");
        if (statusBpm) {
            statusBpm.set("text", "bpm: " + (_arrManifestBpm || "--"));
        }
        var statusClips = patcher.getnamed("status-clips");
        if (statusClips) {
            statusClips.set("text", "clips: " + _arrClipCount);
        }
    } catch (_) {}
}

// ═══════════════════════════════════════════════════════════
//  Eject — clear all loaded state
// ═══════════════════════════════════════════════════════════

function doEject() {
    if (_arrManifestPath) {
        // Clear clips from tracks that were loaded from this manifest
        var manifestDir = _arrDirname(_arrManifestPath);
        var n = _arrTrackCount();
        var totalDeleted = 0;
        for (var i = 0; i < n; i++) {
            if (!_arrIsAudioTrack(i)) continue;
            totalDeleted += _arrClearStemfgClips(i, manifestDir);
        }
        _arrStatus("eject: deleted " + totalDeleted + " clip(s)");
    }
    _arrManifestPath = null;
    _arrManifestBpm = 0;
    _arrClipCount = 0;
    _arrUpdateStatusDisplay();
    _arrStatus("ejected");
}

// ═══════════════════════════════════════════════════════════
//  Debug dump
// ═══════════════════════════════════════════════════════════

function doDumpState() {
    _arrStatus("=== arranger state ===");
    _arrStatus("  manifestPath: " + (_arrManifestPath || "(none)"));
    _arrStatus("  manifestBpm: " + _arrManifestBpm);
    _arrStatus("  clipCount: " + _arrClipCount);
    _arrStatus("  debugMode: " + _arrDebugMode);
    _arrStatus("=== end state ===");
}

// ═══════════════════════════════════════════════════════════
//  Init
// ═══════════════════════════════════════════════════════════

function doInit() {
    _arrStatus("init");
    _arrUpdateStatusDisplay();
}

// ═══════════════════════════════════════════════════════════
//  Message dispatch — Max [js] anything() handler
// ═══════════════════════════════════════════════════════════

function handleMessage(msg, args) {
    if (msg === "init") {
        doInit();
    } else if (msg === "load") {
        if (args.length > 0) {
            var shift = (args.length > 1) ? parseFloat(args[1]) : 0;
            runArrangementLoad(args[0], shift);
        } else {
            _arrStatus("load requires a manifest path");
        }
    } else if (msg === "export") {
        if (args.length > 0) {
            runArrangementExport(args[0]);
        } else {
            // Default: export next to manifest
            if (_arrManifestPath) {
                var dir = _arrDirname(_arrManifestPath);
                runArrangementExport(dir + "/arrangement_snapshot.json");
            } else {
                _arrStatus("export requires an output path (no manifest loaded)");
            }
        }
    } else if (msg === "reanchor") {
        // Re-load the current manifest with a beat offset
        if (!_arrManifestPath) {
            _arrStatus("reanchor: no manifest loaded");
            return;
        }
        var shiftBeats = (args.length > 0) ? parseFloat(args[0]) : 0;
        if (!isFinite(shiftBeats)) shiftBeats = 0;
        _arrStatus("reanchor: shift=" + shiftBeats + " beats");
        runArrangementLoad(_arrManifestPath, shiftBeats);
    } else if (msg === "eject") {
        doEject();
    } else if (msg === "debug") {
        _arrDebugMode = !_arrDebugMode;
        doDumpState();
    } else {
        _arrStatus("unknown message: " + msg);
    }
}

function anything() {
    var msg = messagename;
    var args = arrayfromargs(arguments);
    handleMessage(msg, args);
}

function bang() {
    doInit();
}

// ═══════════════════════════════════════════════════════════
//  CommonJS shim — for Node test sandbox
// ═══════════════════════════════════════════════════════════

if (typeof module !== "undefined" && module.exports) {
    module.exports.__test__ = {
        runArrangementLoad: runArrangementLoad,
        runArrangementExport: runArrangementExport,
        buildArrangementSnapshot: buildArrangementSnapshot,
        _arrJoin: _arrJoin,
        _arrDirname: _arrDirname,
        _arrSecToBeats: _arrSecToBeats,
        _arrExpandTilde: _arrExpandTilde,
        _arrAdaptChunksToStems: _arrAdaptChunksToStems,
        _arrFindTrackForStem: _arrFindTrackForStem,
        _ARR_STEM_ALIASES: _ARR_STEM_ALIASES,
        _arrStripHfsPrefix: _arrStripHfsPrefix,
        handleMessage: handleMessage
    };
}
