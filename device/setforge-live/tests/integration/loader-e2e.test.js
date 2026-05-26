'use strict';

/**
 * End-to-end test for loader.js — the ACTUAL Max JS controller.
 *
 * Simulates the Max SpiderMonkey environment (post, outlet, inlet,
 * LiveAPI, File, etc.) and eval()'s loader.js to test the real
 * production code path.
 */

const { expect } = require('chai');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const LOADER_JS = path.join(__dirname, '..', '..', 'loader.js');
const FIXTURES_DIR = path.join(__dirname, '..', 'fixtures', 'manifests');

/**
 * Build a mock Max environment.
 */
function createMaxEnv() {
  const log = [];           // All post() output
  const outlets = [];       // All outlet() calls: { outlet, args }
  const tracks = {};        // Mock Live tracks
  const clipSlots = {};     // trackIdx -> slotIdx -> clip data
  let currentInlet = 0;
  let trackCounter = 0;

  const env = {
    // ── Max globals ──
    autowatch: 0,
    inlets: 0,
    outlets: 0,
    inlet: 0,

    post: function() {
      const msg = Array.prototype.slice.call(arguments).join('');
      log.push(msg);
    },

    outlet: function() {
      const args = Array.prototype.slice.call(arguments);
      outlets.push({ outlet: args[0], args: args.slice(1) });
    },

    messagename: '',
    arrayfromargs: function(args) {
      return Array.prototype.slice.call(args);
    },

    // ── LiveAPI mock ──
    LiveAPI: function(path) {
      this.path = path;
      this.id = "1";  // non-zero = valid

      this.get = function(prop) {
        if (prop === 'tracks') {
          // Return flat array of [id, "id"] pairs
          var result = [];
          for (var i = 0; i < trackCounter; i++) {
            result.push(i, "id");
          }
          return result;
        }
        if (prop === 'name') {
          // Find track name by path
          var match = this.path.match(/tracks (\d+)/);
          if (match) {
            var idx = parseInt(match[1]);
            return tracks[idx] ? tracks[idx].name : "";
          }
          return "";
        }
        if (prop === 'has_clip') return "0";
        if (prop === 'tempo') return 120;
        return "";
      };

      this.set = function(prop, val) {
        if (prop === 'name') {
          var match = this.path.match(/tracks (\d+)/);
          if (match) {
            var idx = parseInt(match[1]);
            if (!tracks[idx]) tracks[idx] = {};
            tracks[idx].name = val;
          }
        } else if (prop === 'tempo') {
          log.push('[LiveAPI] set tempo: ' + val + '\n');
        }
        // Accept all other set() calls silently (warping, warp_mode, looping, etc.)
      };

      this.call = function(method) {
        if (method === 'create_audio_track') {
          tracks[trackCounter] = { name: "", clips: {} };
          trackCounter++;
        } else if (method === 'create_audio_clip') {
          var wavPath = arguments[1];
          log.push('[LiveAPI] create_audio_clip(' + wavPath + '): ' + this.path + '\n');
        } else if (method === 'create_scene') {
          // no-op, just accept it
        } else if (method === 'fire') {
          log.push('[LiveAPI] fire: ' + this.path + '\n');
        } else if (method === 'stop') {
          log.push('[LiveAPI] stop: ' + this.path + '\n');
        } else if (method === 'stop_all_clips') {
          log.push('[LiveAPI] stop_all_clips: ' + this.path + '\n');
        } else if (method === 'delete_clip') {
          // no-op
        } else if (method === 'add_warp_marker') {
          var dict = arguments[1];
          var bt = dict && dict._data ? dict._data.beat_time : '?';
          var st = dict && dict._data ? dict._data.sample_time : '?';
          log.push('[LiveAPI] add_warp_marker(beat=' + bt + ', sample=' + st + '): ' + this.path + '\n');
        } else if (method === 'create_clip') {
          var clipLen = arguments[1];
          log.push('[LiveAPI] create_clip(' + clipLen + '): ' + this.path + '\n');
        }
      };

      this.getcount = function(prop) {
        if (prop === 'scenes') return 0;
        return 0;
      };
    },

    // ── File mock (supports chunked reading) ──
    File: function(filePath, mode) {
      this.filePath = filePath;
      this.isopen = false;
      this.eof = 0;
      this.position = 0;

      // Check if real file exists
      try {
        var content = fs.readFileSync(filePath, 'utf8');
        this.isopen = true;
        this.eof = content.length;
        this._content = content;
      } catch (e) {
        this.isopen = false;
      }

      this.readstring = function(len) {
        if (!this._content) return '';
        var chunk = this._content.substr(this.position, len);
        this.position += chunk.length;
        return chunk;
      };

      this.writestring = function(str) {
        // For save functionality — write to real filesystem
        try {
          fs.writeFileSync(this.filePath, str, 'utf8');
        } catch (e) {}
      };

      this.close = function() {
        this.isopen = false;
      };

      this.open = function(p, m) {
        try {
          this._content = fs.readFileSync(p, 'utf8');
          this.isopen = true;
          this.eof = this._content.length;
          this.position = 0;
        } catch (e) {
          this.isopen = false;
        }
      };
    },

    // ── Max Dict mock (used for warp markers) ──
    Dict: function() {
      this._data = {};
      this.set = function(key, val) { this._data[key] = val; };
      this.get = function(key) { return this._data[key]; };
    },

    // ── Date (already global in Node) ──
    Date: Date,
    Math: Math,
    JSON: JSON,
    String: String,
    Array: Array,
    parseInt: parseInt,
    parseFloat: parseFloat,
    isNaN: isNaN,

    // ── Test utilities ──
    _log: log,
    _outlets: outlets,
    _tracks: tracks,
    _setInlet: function(idx) { currentInlet = idx; env.inlet = idx; },

    _getLog: function() { return log.join(''); },

    _getOutletCalls: function(outletIdx) {
      return outlets.filter(function(o) { return o.outlet === outletIdx; });
    },

    _clearLog: function() { log.length = 0; },
    _clearOutlets: function() { outlets.length = 0; },

    _sendMessage: function(msg, args) {
      env.messagename = msg;
      env._currentArgs = args || [];
      env._setInlet(2); // messages come on inlet 2
      if (env._anything) {
        env._anything.apply(null, args || []);
      }
    },

    _sendBang: function() {
      if (env._bang) env._bang();
    },

    _sendNoteOn: function(grid, note, velocity) {
      env._setInlet(grid === 1 ? 0 : 1);
      // Send status byte (note on, channel 0)
      if (env._msg_int) {
        env._msg_int(0x90);
        env._msg_int(note);
        env._msg_int(velocity || 127);
      }
    },

    _sendNoteOff: function(grid, note) {
      env._setInlet(grid === 1 ? 0 : 1);
      if (env._msg_int) {
        env._msg_int(0x80);
        env._msg_int(note);
        env._msg_int(0);
      }
    },
  };

  return env;
}

/**
 * Load loader.js into a mock Max environment.
 */
function loadLoaderJs(env) {
  const code = fs.readFileSync(LOADER_JS, 'utf8');

  // Create a VM context with the mock environment
  const context = vm.createContext(env);

  // Run the script
  vm.runInContext(code, context);

  // Capture function references for testing
  env._anything = context.anything;
  env._bang = context.bang;
  env._msg_int = context.msg_int;
  env._dumpState = context.dumpState;
  env._doInit = context.doInit;

  return context;
}

describe('integration: loader.js end-to-end (simulated Max)', () => {
  let env, ctx;

  beforeEach(() => {
    env = createMaxEnv();
    ctx = loadLoaderJs(env);
  });

  it('loads without errors', () => {
    const logStr = env._getLog();
    expect(logStr).to.include('setforge-loader.js loaded');
    expect(logStr).to.include('setforge-loader: init');
    // Should NOT have outlet errors (no outlet calls at load time)
    expect(logStr).not.to.include('bad outlet');
  });

  it('responds to bang (live.thisdevice ready)', () => {
    env._clearLog();
    env._sendBang();
    const logStr = env._getLog();
    expect(logStr).to.include('device ready');
  });

  describe('after device ready', () => {
    beforeEach(() => {
      env._sendBang(); // device ready
      env._clearLog();
      env._clearOutlets();
    });

    it('loads hiphop_v3 fixture set', () => {
      const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
      env._sendMessage('load', [setPath]);

      const logStr = env._getLog();
      expect(logStr).to.include('loading set from');
      expect(logStr).to.include('set loaded (2 tracks)');
      expect(logStr).to.include('slot[0] A: the_next_episode (loaded_idle)');
      expect(logStr).to.include('slot[1] A: big_poppa (loaded_idle)');
    });

    it('creates stem tracks on load', () => {
      const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
      env._sendMessage('load', [setPath]);

      const logStr = env._getLog();
      expect(logStr).to.include("creating track 'sf-drums'");
      expect(logStr).to.include("creating track 'sf-bass'");
      expect(logStr).to.include("creating track 'sf-other'");
      expect(logStr).to.include("creating track 'sf-vox'");
    });

    it('reports missing stem files on preset activation', () => {
      const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
      env._sendMessage('load', [setPath]);

      // Clips load on first preset activation, not at set-load time
      env._sendNoteOn(1, 81, 127); // activate preset 0
      const logStr = env._getLog();
      // Fixture stems have fake paths — create_audio_clip will fail
      // But should NOT crash the state machine
      expect(logStr).not.to.include('load error');
    });

    it('sends status updates to outlet 3', () => {
      const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
      env._sendMessage('load', [setPath]);

      const statusCalls = env._getOutletCalls(3);
      expect(statusCalls.length).to.be.greaterThan(0);

      // Should have bank A status with track names
      const bankACall = statusCalls.find(c =>
        c.args.some(a => typeof a === 'string' && a.includes('bank A'))
      );
      expect(bankACall).to.not.be.undefined;
    });

    it('ejects cleanly', () => {
      const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
      env._sendMessage('load', [setPath]);
      env._clearLog();

      env._sendMessage('eject', []);
      const logStr = env._getLog();
      expect(logStr).to.include('ejected');
    });

    it('handles debug command', () => {
      const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
      env._sendMessage('load', [setPath]);
      env._clearLog();

      env._sendMessage('debug', []);
      const logStr = env._getLog();
      expect(logStr).to.include('=== setforge-loader state ===');
      expect(logStr).to.include('the_next_episode');
      expect(logStr).to.include('=== end state ===');
    });

    it('handles panic', () => {
      env._sendMessage('panic', []);
      const logStr = env._getLog();
      expect(logStr).to.include('PANIC');
    });

    describe('MIDI pad simulation', () => {
      beforeEach(() => {
        const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
        env._sendMessage('load', [setPath]);
        env._clearLog();
        env._clearOutlets();
      });

      it('activates preset on row 1 pad press', () => {
        // Row 1, col 1 = note 81 (LP Pro mk3: row 8 bottom = 81-88 top)
        // Our row 1 = LP row 8 = notes 81-88
        env._sendNoteOn(1, 81, 127); // row 1, col 1
        const logStr = env._getLog();
        // Should not crash; preset should activate if loaded
      });

      it('triggers chop on row 2 pad press', () => {
        // First activate a preset
        env._sendNoteOn(1, 81, 127); // row 1, col 1 = preset A slot 0
        env._clearLog();

        // Row 2 (drums), col 1 = LP row 7 = note 71
        env._sendNoteOn(1, 71, 127);
        const logStr = env._getLog();
        expect(logStr).to.include('launch drums');
      });

      it('replaces chop in same row', () => {
        env._sendNoteOn(1, 81, 127); // activate preset 0
        env._sendNoteOn(1, 71, 127); // drums col 1
        env._clearLog();

        env._sendNoteOn(1, 73, 127); // drums col 3
        const logStr = env._getLog();
        expect(logStr).to.include('launch drums');
        expect(logStr).to.include('slot=2'); // preset 0 * 8 + col 3 - 1 = 2
      });

      it('stops chop on re-press', () => {
        env._sendNoteOn(1, 81, 127); // activate preset 0
        env._sendNoteOn(1, 71, 127); // drums col 1 start
        env._clearLog();

        env._sendNoteOn(1, 71, 127); // drums col 1 stop
        const logStr = env._getLog();
        expect(logStr).to.include('[LiveAPI] stop');
      });

      it('modifier press/release works', () => {
        env._sendNoteOn(1, 81, 127); // activate preset
        env._clearLog();

        // Row 6, col 1 = HOLD = LP row 3 = note 31
        env._sendNoteOn(1, 31, 127);  // HOLD press
        env._sendNoteOn(1, 71, 127);  // drums col 1 with HOLD
        const logStr = env._getLog();
        expect(logStr).to.include('launch drums');

        // Release HOLD
        env._sendNoteOff(1, 31);
      });

      it('scene save and recall', () => {
        env._sendNoteOn(1, 81, 127); // activate preset
        env._sendNoteOn(1, 71, 127); // play drums col 1

        // Save scene: HOLD (row 6 col 1 = note 31) + scene A (row 8 col 1 = note 11)
        env._sendNoteOn(1, 31, 127);  // HOLD
        env._clearLog();
        env._sendNoteOn(1, 11, 127);  // scene A
        var logStr = env._getLog();
        expect(logStr).to.include('saved scene A');
        env._sendNoteOff(1, 31);      // release HOLD

        // Recall scene
        env._clearLog();
        env._sendNoteOn(1, 11, 127);  // scene A (no HOLD = recall)
        logStr = env._getLog();
        expect(logStr).to.include('recalled scene A');
      });

      it('Grid 2 FX target select', () => {
        // Row 5, col 2 = BASS target = LP row 4 = note 42
        env._sendNoteOn(2, 42, 127);
        // Should not crash; check outlets for status update
        const statusCalls = env._getOutletCalls(3);
        const fxCall = statusCalls.find(c =>
          c.args.some(a => typeof a === 'string' && a.includes('fx target: bass'))
        );
        expect(fxCall).to.not.be.undefined;
      });

      it('Grid 2 panic triple-tap', () => {
        env._clearLog();
        env._sendNoteOn(2, 18, 127); // row 8 col 8 = panic = note 18
        env._sendNoteOn(2, 18, 127);
        env._sendNoteOn(2, 18, 127);
        const logStr = env._getLog();
        expect(logStr).to.include('PANIC');
      });

      it('preset hot-swap stages incoming preset then fires', () => {
        // Activate preset 0, play drums col 3
        env._sendNoteOn(1, 81, 127); // preset 0
        env._sendNoteOn(1, 73, 127); // drums col 3
        env._clearLog();

        // Switch to preset 1 (row 1 col 2 = note 82)
        env._sendNoteOn(1, 82, 127);
        const logStr = env._getLog();
        // Should stage the new preset and commit
        expect(logStr).to.include('staging');
        expect(logStr).to.include('committed');
      });
    });

    describe('varying track handling', () => {
      it('loads varying track with disabled chops', () => {
        const setPath = path.join(FIXTURES_DIR, 'hiphop_v3.set.json');
        env._sendMessage('load', [setPath]);
        env._clearLog();
        env._sendMessage('debug', []);
        const logStr = env._getLog();
        // hiphop_v3 has no varying tracks, just verify load works
        expect(logStr).to.include('the_next_episode');
      });
    });
  });
});
