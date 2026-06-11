'use strict';

/**
 * Arranger dual-deck placement e2e tests.
 * Exercises runArrangementPlacement + buildArrangementManifest
 * with a mocked LiveAPI environment.
 */

const { expect } = require('chai');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const LOADER_JS = path.join(__dirname, '..', '..', 'src', 'arranger', 'sf_arrangement_loader.js');

function createMockLiveEnv() {
  const log = [];
  const tracks = {
    'sf-drums-x': { idx: 0, clips: [] },
    'sf-bass-x': { idx: 1, clips: [] },
    'sf-other-x': { idx: 2, clips: [] },
    'sf-vox-x': { idx: 3, clips: [] },
    'sf-drums-y': { idx: 4, clips: [] },
    'sf-bass-y': { idx: 5, clips: [] },
    'sf-other-y': { idx: 6, clips: [] },
    'sf-vox-y': { idx: 7, clips: [] },
  };

  const env = {
    post: function() { log.push(Array.prototype.slice.call(arguments).join('')); },
    outlet: function() {},
    LiveAPI: function(p) {
      this.path = p || '';
      this.id = '1';
      this.get = function(prop) {
        if (prop === 'tempo') return [120];
        if (prop === 'num_tracks') return [Object.keys(tracks).length];
        if (prop === 'name') {
          for (const name of Object.keys(tracks)) {
            if (this.path.includes('tracks ' + tracks[name].idx)) return [name];
          }
          return [''];
        }
        if (prop === 'has_audio_output') return [1];
        return [];
      };
      this.set = function() {};
      this.call = function() {};
      this.getcount = function() { return 0; };
    },
    File: function() {
      this.isopen = false; this.eof = 0; this.position = 0;
      this.readstring = function() { return ''; };
      this.writestring = function() {};
      this.close = function() {};
    },
    log: log,
  };
  return env;
}

function loadModule() {
  const env = createMockLiveEnv();
  const src = fs.readFileSync(LOADER_JS, 'utf-8');
  const ctx = vm.createContext(env);
  vm.runInContext(src, ctx, { filename: 'sf_arrangement_loader.js' });
  return { ctx, env };
}

describe('arranger dual-deck placement', () => {
  let ctx, env;

  beforeEach(() => {
    ({ ctx, env } = loadModule());
  });

  describe('runArrangementPlacement', () => {
    it('places 2 decks × 4 stems', () => {
      const sinkCalls = [];
      vm.runInContext(`setArrangementSink(function(cmd, args) { _testCalls.push({cmd:cmd, args:args}); })`, ctx);
      ctx._testCalls = sinkCalls;

      const manifest = {
        bpm: 120,
        placements: [
          { deck: 'A', stem: 'drums', clip_id: 'sf:A1:drums:0', start_bar: 0, len_bars: 8 },
          { deck: 'A', stem: 'bass', clip_id: 'sf:A1:bass:0', start_bar: 0, len_bars: 8 },
          { deck: 'A', stem: 'other', clip_id: 'sf:A1:other:0', start_bar: 0, len_bars: 8 },
          { deck: 'A', stem: 'vox', clip_id: 'sf:A1:vox:0', start_bar: 0, len_bars: 4 },
          { deck: 'B', stem: 'drums', clip_id: 'sf:B3:drums:0', start_bar: 8, len_bars: 8 },
          { deck: 'B', stem: 'bass', clip_id: 'sf:B3:bass:0', start_bar: 8, len_bars: 8 },
          { deck: 'B', stem: 'other', clip_id: 'sf:B3:other:0', start_bar: 8, len_bars: 8 },
          { deck: 'B', stem: 'vox', clip_id: 'sf:B1:vox:0', start_bar: 8, len_bars: 8 },
        ],
      };

      const result = vm.runInContext(
        `runArrangementPlacement(${JSON.stringify(manifest)})`,
        ctx
      );
      expect(result.ok).to.be.true;
      expect(result.clips_placed).to.equal(8);
      // Verify deck A → *-x tracks, deck B → *-y tracks
      const aCall = sinkCalls.find(c => c.args.clip_id === 'sf:A1:drums:0');
      expect(aCall.args.track).to.equal('sf-drums-x');
      const bCall = sinkCalls.find(c => c.args.clip_id === 'sf:B3:drums:0');
      expect(bCall.args.track).to.equal('sf-drums-y');
    });

    it('returns error for invalid placement', () => {
      const result = vm.runInContext(
        `runArrangementPlacement({ bpm: 120, placements: [{ deck: 'A' }] })`,
        ctx
      );
      expect(result.errors.length).to.be.greaterThan(0);
    });

    it('handles empty placements', () => {
      const result = vm.runInContext(
        `runArrangementPlacement({ bpm: 120, placements: [] })`,
        ctx
      );
      expect(result.ok).to.be.true;
      expect(result.clips_placed).to.equal(0);
    });
  });

  describe('buildArrangementManifest (round-trip)', () => {
    it('produces a valid manifest from placements', () => {
      const placements = [
        { deck: 'A', stem: 'drums', clip_id: 'sf:A1:drums:0', start_bar: 0, len_bars: 8 },
      ];
      const markers = [
        { scene_id: 'scene-1', name: 'Drop', start_bar: 0 },
      ];
      const manifest = vm.runInContext(
        `buildArrangementManifest(120, ${JSON.stringify(placements)}, ${JSON.stringify(markers)})`,
        ctx
      );
      expect(manifest.schema_version).to.equal(1);
      expect(manifest.bpm).to.equal(120);
      expect(manifest.placements).to.have.length(1);
      expect(manifest.placements[0].deck).to.equal('A');
      expect(manifest.scene_markers).to.have.length(1);
    });

    it('save → load round-trips placements', () => {
      const placements = [
        { deck: 'A', stem: 'drums', clip_id: 'd1', start_bar: 0, len_bars: 4, source: 'A1' },
        { deck: 'B', stem: 'bass', clip_id: 'b1', start_bar: 4, len_bars: 8, source: 'B3' },
      ];
      const saved = vm.runInContext(
        `buildArrangementManifest(121, ${JSON.stringify(placements)}, [])`,
        ctx
      );
      // Load back
      const sinkCalls = [];
      vm.runInContext(`setArrangementSink(function(cmd, args) { _testCalls.push({cmd:cmd, args:args}); })`, ctx);
      ctx._testCalls = sinkCalls;
      const result = vm.runInContext(
        `runArrangementPlacement(${JSON.stringify(saved)})`,
        ctx
      );
      expect(result.ok).to.be.true;
      expect(result.clips_placed).to.equal(2);
      expect(sinkCalls[0].args.track).to.equal('sf-drums-x');
      expect(sinkCalls[1].args.track).to.equal('sf-bass-y');
    });
  });

  describe('_alDualDeckTrackName', () => {
    it('maps deck A → -x suffix', () => {
      const name = vm.runInContext('_alDualDeckTrackName("A", "drums")', ctx);
      expect(name).to.equal('sf-drums-x');
    });

    it('maps deck B → -y suffix', () => {
      const name = vm.runInContext('_alDualDeckTrackName("B", "vox")', ctx);
      expect(name).to.equal('sf-vox-y');
    });
  });
});
