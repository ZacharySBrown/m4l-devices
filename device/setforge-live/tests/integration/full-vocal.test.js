'use strict';

/**
 * Full-vocal (mode:"full_stem") handling.
 *
 * taste exports the full vocal stem + a per-beat vocals.wav.asd warp grid.
 * The loader must load it as ONE warped clip that trusts the imported .asd —
 * NOT blind-slice it into 8 four-bar clips and NOT re-linearize its markers.
 * Drums/bass/other are unaffected (they keep blind-grid + warp-fix).
 */

const { expect } = require('chai');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const LOADER_JS = path.join(__dirname, '..', '..', 'loader.js');
const FIXTURES_DIR = path.join(__dirname, '..', 'fixtures', 'manifests');

// Recording Max env: captures LiveAPI set() and create_audio_clip() per path.
function createRecordingEnv() {
  const log = [];
  const sets = [];        // { path, prop, val }
  const createClips = []; // { slotPath, wav }
  const tracks = {};
  let trackCounter = 0;

  const env = {
    autowatch: 0, inlets: 0, outlets: 0, inlet: 0,
    Task: function(fn) { this.fn = fn; this.schedule = function() {}; this.cancel = function() {}; },
    post: function() { log.push(Array.prototype.slice.call(arguments).join('')); },
    outlet: function() {},
    messagename: '',
    arrayfromargs: function(a) { return Array.prototype.slice.call(a); },

    LiveAPI: function(p) {
      this.path = p;
      this.id = "1";
      this.get = function(prop) {
        if (prop === 'tracks') {
          var r = []; for (var i = 0; i < trackCounter; i++) r.push(i, "id"); return r;
        }
        if (prop === 'name') {
          var m = this.path.match(/tracks (\d+)/);
          if (m) { var idx = parseInt(m[1]); return tracks[idx] ? tracks[idx].name : ""; }
          return "";
        }
        if (prop === 'has_clip') return "0";
        if (prop === 'tempo') return 120;
        return "";
      };
      this.set = function(prop, val) {
        sets.push({ path: this.path, prop: prop, val: val });
        if (prop === 'name') {
          var m = this.path.match(/tracks (\d+)/);
          if (m) { var idx = parseInt(m[1]); if (!tracks[idx]) tracks[idx] = {}; tracks[idx].name = val; }
        }
      };
      this.call = function(method) {
        if (method === 'create_audio_track') { tracks[trackCounter] = { name: "", clips: {} }; trackCounter++; }
        else if (method === 'create_audio_clip') { createClips.push({ slotPath: this.path, wav: arguments[1] }); }
      };
      this.getcount = function() { return 0; };
    },

    File: function(filePath) {
      this.filePath = filePath; this.isopen = false; this.position = 0;
      try { this._content = fs.readFileSync(filePath, 'utf8'); this.isopen = true; this.eof = this._content.length; }
      catch (e) { this.isopen = false; }
      this.readstring = function(len) { if (!this._content) return ''; var c = this._content.substr(this.position, len); this.position += c.length; return c; };
      this.writestring = function() {};
      this.close = function() { this.isopen = false; };
      this.open = function(p) { try { this._content = fs.readFileSync(p, 'utf8'); this.isopen = true; this.eof = this._content.length; this.position = 0; } catch (e) { this.isopen = false; } };
    },
    Dict: function() { this._data = {}; this.set = function(k, v) { this._data[k] = v; }; this.get = function(k) { return this._data[k]; }; },
    Date: Date, Math: Math, JSON: JSON, String: String, Array: Array,
    parseInt: parseInt, parseFloat: parseFloat, isNaN: isNaN,

    _log: log, _sets: sets, _createClips: createClips,
    _getLog: function() { return log.join(''); },
    messagename: '',
    _sendMessage: function(msg, args) { env.messagename = msg; env.inlet = 2; if (env._anything) env._anything.apply(null, args || []); },
    _sendBang: function() { if (env._bang) env._bang(); },
    _sendNoteOn: function(grid, note, vel) { env.inlet = (grid === 1 ? 0 : 1); if (env._msg_int) { env._msg_int(0x90); env._msg_int(note); env._msg_int(vel || 127); } },
  };
  return env;
}

function loadCtx(env) {
  const ctx = vm.createContext(env);
  vm.runInContext(fs.readFileSync(LOADER_JS, 'utf8'), ctx);
  env._anything = ctx.anything;
  env._bang = ctx.bang;
  env._msg_int = ctx.msg_int;
  env._computeTrackChops = ctx.computeTrackChops;
  env._writeVocalWarpGrid = ctx.writeVocalWarpGrid;
  env._secToBeatGrid = ctx.secToBeatGrid;
  env._Dict = ctx.Dict;
  return ctx;
}

describe('full-vocal: computeTrackChops (pure)', () => {
  let env;
  beforeEach(() => { env = createRecordingEnv(); loadCtx(env); });

  it('emits ONE enabled full-vocal clip (col 1) for a full_stem vox; rest disabled', () => {
    const track = { id: "t1", bpm: 120, downbeat_sec: 0,
      stems: { vox: { path: "/x/vocals.wav", mode: "full_stem", chops: [] } } };
    const chops = env._computeTrackChops(track).vox;
    expect(chops).to.have.length(8);
    const enabled = chops.filter(c => !c.disabled);
    expect(enabled).to.have.length(1);
    expect(enabled[0].fullVocal).to.equal(true);
    expect(enabled[0].column).to.equal(1);
    expect(enabled[0].clipStart).to.equal(0);
    expect(enabled[0].stemPath).to.equal("/x/vocals.wav");
  });

  it('does NOT blind-slice a full_stem vox, but DOES blind-slice a normal stem', () => {
    const track = { id: "t1", bpm: 120, downbeat_sec: 0,
      stems: {
        drums: { path: "/x/drums.wav" },
        vox: { path: "/x/vocals.wav", mode: "full_stem", chops: [] }
      } };
    const chops = env._computeTrackChops(track);
    expect(chops.drums.filter(c => !c.disabled)).to.have.length(8); // blind grid intact
    expect(chops.vox.filter(c => !c.disabled)).to.have.length(1);   // full vocal
    expect(chops.drums.every(c => !c.fullVocal)).to.equal(true);
  });

  it('RESTORES saved vocal regions: full_stem WITH chops -> one clip per region', () => {
    const track = { id: "t1", bpm: 85, downbeat_sec: 0,
      stems: { vox: { path: "/x/vocals.wav", mode: "full_stem",
        warp_grid: [[0, 0.36], [4, 2.81]],
        chops: [
          { start_sec: 28.56, length_sec: 46.41, label: "v1" },
          { start_sec: 74.97, length_sec: 7.34 },
          { start_sec: 103.53, length_sec: 57.12 },
          { start_sec: 171.35, length_sec: 17.85 }
        ] } } };
    const vox = env._computeTrackChops(track).vox;
    const en = vox.filter(c => !c.disabled);
    expect(en).to.have.length(4);                       // 4 regions, not 1 full clip
    expect(en.every(c => c.fullVocal === true)).to.equal(true);
    expect(en.map(c => c.clipStart)).to.deep.equal([28.56, 74.97, 103.53, 171.35]);
    expect(en.map(c => c.clipLength)).to.deep.equal([46.41, 7.34, 57.12, 17.85]);
    expect(en.every(c => c.warpGrid && c.warpGrid.length === 2)).to.equal(true);
    expect(vox).to.have.length(8); // rest disabled
  });

  it('carries EXACT saved region beats (grid-independent restore) onto the chop', () => {
    const track = { id: "t1", bpm: 85, downbeat_sec: 0,
      stems: { vox: { path: "/x/vocals.wav", mode: "full_stem",
        warp_grid: [[0, 44.64], [4, 47.46]],
        chops: [
          { start_sec: 28.56, length_sec: 46.41,
            start_marker_beat: 32.0, end_marker_beat: 88.0,
            loop_start_beat: 32.0, loop_end_beat: 88.0 }
        ] } } };
    const en = env._computeTrackChops(track).vox.filter(c => !c.disabled)[0];
    expect(en.startMarkerBeat).to.equal(32.0);   // exact beats preserved...
    expect(en.endMarkerBeat).to.equal(88.0);
    expect(en.loopStartBeat).to.equal(32.0);
    expect(en.loopEndBeat).to.equal(88.0);
    // ...so the loader restores beats directly instead of reprojecting
    // 28.56s through the deep grid (which would clamp to beat 0 / bar 1).
  });

  it('full_stem with EMPTY chops still loads ONE full clip (regression)', () => {
    const track = { id: "t1", bpm: 85, downbeat_sec: 0,
      stems: { vox: { path: "/x/vocals.wav", mode: "full_stem", chops: [], warp_grid: [[0,0.36]] } } };
    const en = env._computeTrackChops(track).vox.filter(c => !c.disabled);
    expect(en).to.have.length(1);
    expect(en[0].clipLength).to.equal(0);   // full extent
    expect(en[0].fullVocal).to.equal(true);
  });

  it('secToBeatGrid maps region seconds -> beats (anchor / interp / extrapolate)', () => {
    const grid = [[0, 0.36], [4, 2.81], [8, 5.26]];   // 2.45s per 4 beats
    expect(env._secToBeatGrid(grid, 0.36)).to.equal(0);          // on anchor
    expect(env._secToBeatGrid(grid, 2.81)).to.equal(4);          // on anchor
    // midway between anchors 0 and 1
    expect(env._secToBeatGrid(grid, 0.36 + 2.45/2)).to.be.closeTo(2, 1e-9);
    // before first / past last extrapolate monotonically
    expect(env._secToBeatGrid(grid, 0)).to.equal(0);             // clamped to first anchor beat
    expect(env._secToBeatGrid(grid, 7.71)).to.be.closeTo(12, 1e-6); // one bar past last
  });

  it('attaches the manifest warp_grid to the full-vocal chop', () => {
    const grid = [[0, 0.36], [4, 2.81], [8, 5.26]];
    const track = { id: "t1", bpm: 120, downbeat_sec: 0,
      stems: { vox: { path: "/x/vocals.wav", mode: "full_stem", chops: [], warp_grid: grid } } };
    const en = env._computeTrackChops(track).vox.filter(c => !c.disabled)[0];
    expect(en.warpGrid).to.deep.equal(grid);
  });

  it('regression: curated chops path is unchanged', () => {
    const track = { id: "t1", bpm: 120, downbeat_sec: 0,
      stems: { drums: { path: "/x/drums.wav", chops: [
        { start_sec: 0, length_sec: 8, label: "a" },
        { start_sec: 8, length_sec: 8, label: "b" }
      ] } } };
    const en = env._computeTrackChops(track).drums.filter(c => !c.disabled);
    expect(en).to.have.length(2);
    expect(en[0].fullVocal).to.be.undefined;
    expect(en[0].clipLength).to.equal(8);
  });
});

describe('full-vocal: writeVocalWarpGrid (LOM marker writes)', () => {
  let env;
  beforeEach(() => { env = createRecordingEnv(); loadCtx(env); });

  // Records adds + removes in call order. sampleLength=0 disables the tail guard.
  function recordingClip(markers, removes, sampleLength) {
    return {
      id: "1",
      get: function(prop) { if (prop === 'sample_length') return sampleLength || 0; return ""; },
      call: function(method, a) {
        if (method === 'add_warp_marker') markers.push([a.get('beat_time'), a.get('sample_time')]);
        else if (method === 'remove_warp_marker' && removes) removes.push(a);
      }
    };
  }

  it('beat-0 fix: adds beats>=4 first, then removes [0] default and re-adds beat 0 at its sec', () => {
    const grid = [[0, 0.36], [4, 2.81], [8, 5.26], [12, 7.72]];
    const got = [], removed = [];
    const n = env._writeVocalWarpGrid(recordingClip(got, removed, 0), grid);
    expect(n).to.equal(4);
    // beats >=4 added in order FIRST, beat 0 added LAST (after the remove)
    expect(got).to.deep.equal([[4, 2.81], [8, 5.26], [12, 7.72], [0, 0.36]]);
    // the [0,0] default was removed exactly once (beat 0)
    expect(removed).to.deep.equal([0]);
  });

  it('returns 0 and writes nothing for an empty/missing grid', () => {
    const got = [];
    expect(env._writeVocalWarpGrid(recordingClip(got, [], 0), [])).to.equal(0);
    expect(env._writeVocalWarpGrid(recordingClip(got, [], 0), null)).to.equal(0);
    expect(got).to.have.length(0);
  });

  it('tail guard: never writes a marker whose sample_time exceeds clip audio length', () => {
    // sample_length 220500 frames / 44100 = 5.0s. Markers at 5.26 and 7.72 must be dropped.
    const grid = [[0, 0.36], [4, 2.81], [8, 5.26], [12, 7.72]];
    const got = [], removed = [];
    const n = env._writeVocalWarpGrid(recordingClip(got, removed, 220500), grid);
    // beat 4 (2.81 < 5.0) added; beats 8 & 12 dropped; beat 0 (0.36) re-added
    expect(got).to.deep.equal([[4, 2.81], [0, 0.36]]);
    expect(n).to.equal(2);
  });

  it('beat-0 re-add survives even if remove throws (no marker there yet)', () => {
    const grid = [[0, 0.36], [4, 2.81]];
    const got = [];
    const clip = { id: "1",
      get: function() { return 0; },
      call: function(method, a) {
        if (method === 'remove_warp_marker') throw new Error('no marker at 0');
        if (method === 'add_warp_marker') got.push([a.get('beat_time'), a.get('sample_time')]);
      }};
    const n = env._writeVocalWarpGrid(clip, grid);
    expect(got).to.deep.equal([[4, 2.81], [0, 0.36]]);  // remove failure is caught; re-add still happens
    expect(n).to.equal(2);
  });
});

describe('full-vocal: load path (drives loader.js end-to-end)', () => {
  let env;
  beforeEach(() => {
    env = createRecordingEnv();
    loadCtx(env);
    env._sendBang(); // device ready → creates stem tracks
    env._sendMessage('load', [path.join(FIXTURES_DIR, 'full_vocal.set.json')]);
    env._createClips.length = 0; env._sets.length = 0; // clear set-load noise
    env._sendNoteOn(1, 41, 127); // activate preset 0 → loads clips
  });

  function setsForClipWav(wavEndsWith) {
    const created = env._createClips.find(c => c.wav && c.wav.indexOf(wavEndsWith) !== -1);
    expect(created, 'clip created for ' + wavEndsWith).to.not.be.undefined;
    const clipPath = created.slotPath + ' clip';
    return env._sets.filter(s => s.path === clipPath);
  }

  it('creates exactly ONE vocals clip (not 8)', () => {
    const voxClips = env._createClips.filter(c => c.wav && c.wav.indexOf('vocals.wav') !== -1);
    expect(voxClips).to.have.length(1);
  });

  it('vox clip is warped but NOT looped/length-clamped (trusts the .asd)', () => {
    const s = setsForClipWav('vocals.wav');
    const props = s.map(x => x.prop);
    const warping = s.filter(x => x.prop === 'warping');
    expect(warping.length).to.be.greaterThan(0);
    expect(warping[warping.length - 1].val).to.equal(1);     // warping ON
    const startM = s.filter(x => x.prop === 'start_marker');
    expect(startM.length).to.be.greaterThan(0);              // anchored...
    expect(startM[startM.length - 1].val).to.equal(0);       // ...to beat 0 (downbeat)
    expect(props).to.not.include('loop_end');                 // no blind 4-bar loop
    expect(props).to.not.include('end_marker');               // length untouched
    expect(props).to.not.include('warp_bpm');                 // markers own the tempo
  });

  it('drums clips are still looped to a beat grid (regression)', () => {
    const s = setsForClipWav('drums.wav');
    const props = s.map(x => x.prop);
    expect(props).to.include('warping');
    expect(props).to.include('loop_end');     // blind-grid loop preserved
    expect(props).to.include('end_marker');
  });
});
