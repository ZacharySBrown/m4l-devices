'use strict';

const { expect } = require('chai');
const {
  overridePath, buildOverride, writeOverride, readOverride,
} = require('../../src/calibrator/override-writer');
const { createMockFs } = require('../harness/fixture-loader');

describe('override-writer', () => {
  describe('overridePath', () => {
    it('returns .calib_override.json in stem directory', () => {
      const p = overridePath('/data/stems/track_a/drums.wav');
      expect(p).to.equal('/data/stems/track_a/.calib_override.json');
    });
  });

  describe('buildOverride', () => {
    it('builds correct override object', () => {
      const override = buildOverride('track_a', 2.27, 'warp_marker_drag', 2.31);
      expect(override.track_id).to.equal('track_a');
      expect(override.downbeat_sec).to.equal(2.27);
      expect(override.method).to.equal('warp_marker_drag');
      expect(override.delta_from_auto_sec).to.be.closeTo(-0.04, 0.001);
      expect(override.validated_at).to.be.a('string');
    });

    it('defaults method to warp_marker_drag', () => {
      const override = buildOverride('x', 1.0, null, 1.0);
      expect(override.method).to.equal('warp_marker_drag');
    });
  });

  describe('writeOverride + readOverride (atomic)', () => {
    let mockFs;

    beforeEach(() => {
      mockFs = createMockFs();
    });

    it('writes via tmp + rename', () => {
      const filePath = '/data/.calib_override.json';
      const override = buildOverride('track_a', 2.27, 'warp_marker_drag', 2.31);

      writeOverride(filePath, override, mockFs);

      // tmp file should NOT exist (it was renamed)
      expect(mockFs.existsSync(filePath + '.tmp')).to.be.false;
      // final file should exist
      expect(mockFs.existsSync(filePath)).to.be.true;
    });

    it('round-trips through write + read', () => {
      const filePath = '/data/.calib_override.json';
      const override = buildOverride('track_a', 2.27, 'warp_marker_drag', 2.31);

      writeOverride(filePath, override, mockFs);
      const read = readOverride(filePath, mockFs);

      expect(read.track_id).to.equal('track_a');
      expect(read.downbeat_sec).to.equal(2.27);
    });

    it('readOverride returns null for missing file', () => {
      expect(readOverride('/nonexistent', mockFs)).to.be.null;
    });
  });
});
