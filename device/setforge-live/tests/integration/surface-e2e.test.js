'use strict';

/**
 * End-to-end headless test for the Phase-1 surface gesture chain.
 * Drives synthetic MIDI through the built loader.js (like loader-e2e)
 * and asserts state at each step: stem-assign, punch-FX, aftertouch,
 * LED feedback.
 */

const { expect } = require('chai');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const LOADER_JS = path.join(__dirname, '..', '..', 'loader.js');
const FIXTURES_DIR = path.join(__dirname, '..', 'fixtures', 'manifests');

function createMaxEnv() {
  const log = [];
  const outlets = [];
  let currentInlet = 0;
  let trackCounter = 0;
  const tracks = {};
  const clipSlots = {};

  const env = {
    autowatch: 0, inlets: 0, outlets: 0, inlet: 0,
    Task: function(fn) { this.fn = fn; this.schedule = function() {}; this.cancel = function() {}; },
    SF_VERBOSE: true,
    post: function() { log.push(Array.prototype.slice.call(arguments).join('')); },
    outlet: function() { outlets.push(Array.prototype.slice.call(arguments)); },
    messagename: '', arrayfromargs: function(a) { return Array.prototype.slice.call(a); },
    jsarguments: [],
    LiveAPI: function(p) {
      this.path = p || '';
      this.id = '1';
      this.get = function(prop) {
        if (prop === 'tempo') return [120];
        if (prop === 'has_clip') return [0];
        return [];
      };
      this.set = function() {};
      this.call = function() {};
      this.getcount = function() { return 0; };
    },
    File: function(p, m) {
      this.isopen = false; this.eof = 0; this.position = 0;
      this.readstring = function() { return ''; };
      this.writestring = function() {};
      this.close = function() {};
    },
    Dict: function() { this.get = function() { return ''; }; },
    patcher: { getnamed: function() { return { message: function() {} }; } },
    log: log, outlets: outlets,
  };
  return env;
}

function loadController() {
  const env = createMaxEnv();
  const src = fs.readFileSync(LOADER_JS, 'utf-8');
  const ctx = vm.createContext(env);
  vm.runInContext(src, ctx, { filename: 'loader.js' });
  return { ctx, env };
}

function feedBytes(ctx, bytes) {
  for (const b of bytes) {
    ctx.inlet = 0;
    vm.runInContext(`msg_int(${b})`, ctx);
  }
}

describe('Phase-1 surface gesture chain (e2e)', () => {
  let ctx, env;

  beforeEach(() => {
    ({ ctx, env } = loadController());
  });

  describe('stem-assign gesture (direct function calls)', () => {
    // Controller MIDI routing is not yet wired to the Phase-1 modules;
    // test the module functions directly (they're in the concat scope).

    it('enters WAITING on stemAssignButtonDown(80)', () => {
      vm.runInContext('stemAssignButtonDown(80)', ctx);
      const assigning = vm.runInContext('isStemAssigning()', ctx);
      expect(assigning).to.be.true;
    });

    it('cancels on stemAssignButtonUp without preset', () => {
      vm.runInContext('stemAssignButtonDown(80)', ctx);
      vm.runInContext('stemAssignButtonUp(80)', ctx);
      expect(vm.runInContext('isStemAssigning()', ctx)).to.be.false;
    });

    it('completes assignment on stemAssignPresetTap(93)', () => {
      vm.runInContext('stemAssignButtonDown(80)', ctx);
      vm.runInContext('stemAssignPresetTap(93)', ctx);
      const assignment = vm.runInContext('getRowAssignment(0)', ctx);
      expect(assignment).to.equal(2);  // A3 = slot 2
    });

    it('getRowStem maps row 0 → drums-x', () => {
      const stem = vm.runInContext('JSON.stringify(getRowStem(0))', ctx);
      expect(JSON.parse(stem)).to.deep.equal({ stem: 'drums', deck: 'x' });
    });
  });

  describe('punch-FX gesture via note (direct calls)', () => {
    it('enters FX_APPLY on punchButtonDown(89)', () => {
      vm.runInContext('punchButtonDown(89)', ctx);
      expect(vm.runInContext('isPunchFxActive()', ctx)).to.be.true;
      const state = vm.runInContext('JSON.stringify(getPunchState())', ctx);
      expect(JSON.parse(state).effect).to.equal('REPEAT');
    });

    it('exits FX_APPLY on punchButtonUp(89)', () => {
      vm.runInContext('punchButtonDown(89)', ctx);
      vm.runInContext('punchButtonUp(89)', ctx);
      expect(vm.runInContext('isPunchFxActive()', ctx)).to.be.false;
    });
  });

  describe('punch-FX gesture via CC (direct calls)', () => {
    it('enters FX_APPLY on punchCCDown(89, 127)', () => {
      vm.runInContext('punchCCDown(89, 127)', ctx);
      expect(vm.runInContext('isPunchFxActive()', ctx)).to.be.true;
    });

    it('exits on punchCCDown(89, 0) (value=0 release)', () => {
      vm.runInContext('punchCCDown(89, 127)', ctx);
      vm.runInContext('punchCCDown(89, 0)', ctx);
      expect(vm.runInContext('isPunchFxActive()', ctx)).to.be.false;
    });
  });

  describe('aftertouch during FX_APPLY', () => {
    it('poly aftertouch updates pad pressure', () => {
      feedBytes(ctx, [0x90, 89, 100]);  // punch button
      feedBytes(ctx, [0xA0, 81, 100]);  // poly AT on pad
      const p = vm.runInContext('getPadPressure(1, 81)', ctx);
      expect(p).to.be.closeTo(100 / 127, 0.001);
    });
  });

  describe('per-source LED (color lookup)', () => {
    it('sourceColor7bit returns 7-bit RGB for slot 0', () => {
      const rgb = vm.runInContext('JSON.stringify(sourceColor7bit(0))', ctx);
      const parsed = JSON.parse(rgb);
      expect(parsed).to.have.length(3);
      expect(parsed[0]).to.be.at.least(100);  // warm amber → high R
    });

    it('LEGEND_PALETTE_HEX has 8 entries', () => {
      const len = vm.runInContext('LEGEND_PALETTE_HEX.length', ctx);
      expect(len).to.equal(8);
    });
  });
});
