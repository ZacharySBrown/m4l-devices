'use strict';

const { expect } = require('chai');
const {
  secondsPerBar, clipStart, clipLength, computeChops, computeTrackChops,
  BARS_PER_CHOP, NUM_CHOPS,
} = require('../../src/shared/chop-math');
const { loadManifest, loadExpectedChops } = require('../harness/fixture-loader');

describe('chop-math', () => {
  describe('secondsPerBar', () => {
    it('computes correctly at 120 BPM', () => {
      expect(secondsPerBar(120)).to.equal(2.0);
    });

    it('computes correctly at 94.7 BPM', () => {
      expect(secondsPerBar(94.7)).to.be.closeTo(2.5343189017951424, 0.0000001);
    });

    it('throws on zero BPM', () => {
      expect(() => secondsPerBar(0)).to.throw('Invalid BPM');
    });

    it('throws on negative BPM', () => {
      expect(() => secondsPerBar(-10)).to.throw('Invalid BPM');
    });
  });

  describe('clipStart', () => {
    it('column 1 returns downbeat_sec', () => {
      expect(clipStart(1, 120, 0)).to.equal(0);
      expect(clipStart(1, 120, 2.31)).to.equal(2.31);
    });

    it('column 2 returns downbeat + 4 bars', () => {
      // 4 bars at 120 BPM = 4 * 2.0 = 8.0 sec
      expect(clipStart(2, 120, 0)).to.equal(8.0);
    });

    it('column 8 returns downbeat + 28 bars', () => {
      // 28 bars at 120 BPM = 28 * 2.0 = 56.0
      expect(clipStart(8, 120, 0)).to.equal(56.0);
    });

    it('throws on column 0', () => {
      expect(() => clipStart(0, 120, 0)).to.throw('Column out of range');
    });

    it('throws on column 9', () => {
      expect(() => clipStart(9, 120, 0)).to.throw('Column out of range');
    });

    it('throws on negative downbeat', () => {
      expect(() => clipStart(1, 120, -1)).to.throw('Invalid downbeat_sec');
    });
  });

  describe('clipLength', () => {
    it('returns 4 bars at 120 BPM = 8 sec', () => {
      expect(clipLength(120)).to.equal(8.0);
    });

    it('returns 4 bars at 94.7 BPM', () => {
      expect(clipLength(94.7)).to.be.closeTo(10.13727560718057, 0.00000001);
    });
  });

  describe('computeChops', () => {
    it('returns 8 chops for a normal stem', () => {
      const chops = computeChops(120, 0, '/test/drums.wav', false);
      expect(chops).to.have.lengthOf(NUM_CHOPS);
      expect(chops[0].column).to.equal(1);
      expect(chops[0].clipStart).to.equal(0);
      expect(chops[0].disabled).to.be.false;
      expect(chops[7].column).to.equal(8);
    });

    it('returns all disabled for varying track', () => {
      const chops = computeChops(120, 0, '/test/drums.wav', true);
      expect(chops).to.have.lengthOf(NUM_CHOPS);
      for (const chop of chops) {
        expect(chop.disabled).to.be.true;
        expect(chop.clipStart).to.equal(0);
        expect(chop.clipLength).to.equal(0);
      }
    });

    it('includes stem path in every chop', () => {
      const chops = computeChops(120, 0, '/my/stem.wav', false);
      for (const chop of chops) {
        expect(chop.stemPath).to.equal('/my/stem.wav');
      }
    });
  });

  describe('computeTrackChops', () => {
    it('computes chops for all 4 stems', () => {
      const manifest = loadManifest('hiphop_v3');
      const track = manifest.tracks[0]; // the_next_episode
      const result = computeTrackChops(track);

      expect(result).to.have.keys('drums', 'bass', 'other', 'vox');
      expect(result.drums).to.have.lengthOf(8);
      expect(result.bass).to.have.lengthOf(8);
    });

    it('returns null for missing stems', () => {
      const manifest = loadManifest('missing_stem');
      const track = manifest.tracks[0];
      const result = computeTrackChops(track);

      expect(result.drums).to.be.null;
      expect(result.bass).to.not.be.null;
    });

    it('returns disabled chops for varying tracks', () => {
      const manifest = loadManifest('varying_track');
      const track = manifest.tracks[0];
      const result = computeTrackChops(track);

      expect(result.drums[0].disabled).to.be.true;
    });

    it('throws on missing bpm', () => {
      expect(() => computeTrackChops({})).to.throw('missing required bpm');
    });
  });

  describe('regression: fixture expectations', () => {
    it('matches expected chop values for the_next_episode', () => {
      const manifest = loadManifest('hiphop_v3');
      const track = manifest.tracks[0];
      const expected = loadExpectedChops('the_next_episode');
      const result = computeTrackChops(track);

      expect(clipLength(track.bpm)).to.be.closeTo(expected.clip_length, 0.001);

      for (const exp of expected.chops.drums) {
        const actual = result.drums.find(c => c.column === exp.column);
        expect(actual.clipStart).to.be.closeTo(exp.clipStart, 0.001);
      }
    });
  });
});
