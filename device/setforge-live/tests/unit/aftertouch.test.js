'use strict';

/**
 * Unit tests for aftertouch (poly 0xA0 + channel 0xD0) parsing in the
 * loader controller's processMidiByte.
 *
 * Runs headless — no hardware needed. Simulates raw MIDI byte streams
 * and verifies the handlers fire with correct values.
 */

const { expect } = require('chai');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const LOADER_JS = path.join(__dirname, '..', '..', 'loader.js');

/**
 * Minimal Max env — just enough for MIDI parsing + aftertouch.
 */
function createMinimalEnv() {
  const log = [];
  const env = {
    autowatch: 0, inlets: 0, outlets: 0, inlet: 0,
    Task: function() { this.schedule = function() {}; this.cancel = function() {}; },
    post: function() { log.push(Array.prototype.slice.call(arguments).join('')); },
    outlet: function() {},
    messagename: '',
    arrayfromargs: function(args) { return Array.prototype.slice.call(args); },
    LiveAPI: function() { this.id = '0'; this.get = function() { return []; }; this.set = function() {}; this.call = function() {}; },
    File: function() { this.isopen = false; this.eof = 0; this.position = 0; this.readstring = function() { return ''; }; this.writestring = function() {}; this.close = function() {}; },
    Dict: function() { this.get = function() { return ''; }; },
    patcher: { getnamed: function() { return { message: function() {} }; } },
    jsarguments: [],
    log: log,
  };
  return env;
}

function loadController() {
  const env = createMinimalEnv();
  const src = fs.readFileSync(LOADER_JS, 'utf-8');
  const ctx = vm.createContext(env);
  vm.runInContext(src, ctx, { filename: 'loader.js' });
  return { ctx, env };
}

/**
 * Feed raw MIDI bytes through msg_int (inlet 0 = grid 1).
 */
function feedBytes(ctx, bytes) {
  for (const b of bytes) {
    ctx.inlet = 0;
    vm.runInContext(`msg_int(${b})`, ctx);
  }
}

/**
 * Feed bytes on inlet 1 = grid 2.
 */
function feedBytesGrid2(ctx, bytes) {
  for (const b of bytes) {
    ctx.inlet = 1;
    vm.runInContext(`msg_int(${b})`, ctx);
  }
}

describe('aftertouch parsing', () => {
  let ctx, env;

  beforeEach(() => {
    ({ ctx, env } = loadController());
  });

  describe('polyphonic key pressure (0xA0)', () => {
    it('fires handlePolyAftertouch with correct note + pressure', () => {
      // 0xA0 = poly AT on ch 0, note 81, pressure 100
      feedBytes(ctx, [0xA0, 81, 100]);
      const pressure = vm.runInContext('getPadPressure(1, 81)', ctx);
      expect(pressure).to.be.closeTo(100 / 127, 0.001);
    });

    it('normalizes pressure to 0–1 range', () => {
      feedBytes(ctx, [0xA0, 61, 0]);
      expect(vm.runInContext('getPadPressure(1, 61)', ctx)).to.equal(0);

      feedBytes(ctx, [0xA0, 61, 127]);
      expect(vm.runInContext('getPadPressure(1, 61)', ctx)).to.equal(1);
    });

    it('tracks per-note pressure independently', () => {
      feedBytes(ctx, [0xA0, 81, 50]);
      feedBytes(ctx, [0xA0, 82, 100]);
      expect(vm.runInContext('getPadPressure(1, 81)', ctx)).to.be.closeTo(50 / 127, 0.001);
      expect(vm.runInContext('getPadPressure(1, 82)', ctx)).to.be.closeTo(100 / 127, 0.001);
    });

    it('works on grid 2 (inlet 1)', () => {
      feedBytesGrid2(ctx, [0xA0, 71, 80]);
      expect(vm.runInContext('getPadPressure(2, 71)', ctx)).to.be.closeTo(80 / 127, 0.001);
      // Grid 1 should not be affected
      expect(vm.runInContext('getPadPressure(1, 71)', ctx)).to.equal(0);
    });

    it('posts a trace message', () => {
      feedBytes(ctx, [0xA0, 81, 64]);
      const atLogs = env.log.filter(l => l.includes('poly-AT'));
      expect(atLogs).to.have.length(1);
      expect(atLogs[0]).to.include('note=81');
    });
  });

  describe('channel pressure (0xD0)', () => {
    it('fires handleChannelPressure with correct pressure', () => {
      // 0xD0 = channel AT on ch 0, pressure 90 (2-byte message!)
      feedBytes(ctx, [0xD0, 90]);
      const pressure = vm.runInContext('getPadPressure(1, 99)', ctx);  // any note falls back to channel
      expect(pressure).to.be.closeTo(90 / 127, 0.001);
    });

    it('completes at 2 bytes (does not consume a third)', () => {
      // Feed 0xD0 + pressure, then immediately a new note-on.
      // If 0xD0 wrongly waits for 3 bytes, the note-on gets eaten.
      feedBytes(ctx, [0xD0, 64, 0x90, 81, 100]);
      // Channel pressure should be set
      expect(vm.runInContext('getPadPressure(1, 0)', ctx)).to.be.closeTo(64 / 127, 0.001);
      // The note-on that followed should NOT be swallowed
      // (we can't directly check handleNoteOn was called without more mocking,
      // but we verify the buffer didn't desync by checking that a subsequent
      // poly-AT still works correctly)
      feedBytes(ctx, [0xA0, 82, 50]);
      expect(vm.runInContext('getPadPressure(1, 82)', ctx)).to.be.closeTo(50 / 127, 0.001);
    });

    it('applies to any note via fallback in getPadPressure', () => {
      feedBytes(ctx, [0xD0, 100]);
      // getPadPressure for any note on grid 1 should return channel pressure
      expect(vm.runInContext('getPadPressure(1, 81)', ctx)).to.be.closeTo(100 / 127, 0.001);
      expect(vm.runInContext('getPadPressure(1, 42)', ctx)).to.be.closeTo(100 / 127, 0.001);
    });

    it('poly AT takes precedence over channel AT', () => {
      feedBytes(ctx, [0xD0, 50]);
      feedBytes(ctx, [0xA0, 81, 120]);
      // Note 81 has poly AT = 120/127; note 82 falls back to channel AT = 50/127
      expect(vm.runInContext('getPadPressure(1, 81)', ctx)).to.be.closeTo(120 / 127, 0.001);
      expect(vm.runInContext('getPadPressure(1, 82)', ctx)).to.be.closeTo(50 / 127, 0.001);
    });
  });

  describe('interleaved with note-on/off and CC', () => {
    it('does not disrupt note-on parsing', () => {
      // note-on, poly-AT, note-off — all should parse cleanly
      feedBytes(ctx, [
        0x90, 81, 100,   // note-on
        0xA0, 81, 64,    // poly AT
        0x80, 81, 0,     // note-off
      ]);
      expect(vm.runInContext('getPadPressure(1, 81)', ctx)).to.be.closeTo(64 / 127, 0.001);
    });

    it('does not disrupt CC parsing', () => {
      feedBytes(ctx, [
        0xA0, 71, 50,    // poly AT
        0xB0, 102, 127,  // CC 102 (inspect command)
        0xA0, 71, 0,     // poly AT release
      ]);
      expect(vm.runInContext('getPadPressure(1, 71)', ctx)).to.equal(0);
    });

    it('handles channel AT between notes without desync', () => {
      feedBytes(ctx, [
        0x90, 81, 100,   // note-on
        0xD0, 80,        // channel AT (2 bytes!)
        0x90, 82, 100,   // another note-on — must not be eaten
      ]);
      // Channel pressure should be set
      expect(vm.runInContext('getPadPressure(1, 99)', ctx)).to.be.closeTo(80 / 127, 0.001);
    });
  });

  describe('getPadPressure defaults', () => {
    it('returns 0 for untouched pads', () => {
      expect(vm.runInContext('getPadPressure(1, 81)', ctx)).to.equal(0);
      expect(vm.runInContext('getPadPressure(2, 71)', ctx)).to.equal(0);
    });
  });
});
