'use strict';

const { expect } = require('chai');
const { createMockLiveApi } = require('../harness/mock-live-api');
const { createMockFs } = require('../harness/fixture-loader');
const { overridePath, buildOverride, writeOverride, readOverride } = require('../../src/calibrator/override-writer');

describe('integration: calibrate-flow', () => {
  let liveApi, mockFs;

  beforeEach(() => {
    liveApi = createMockLiveApi();
    mockFs = createMockFs();
  });

  it('full calibration flow: load track, move marker, validate, write override', () => {
    const trackId = 'the_next_episode';
    const stemPath = '/data/stems/the_next_episode/drums.wav';
    const autoDownbeat = 2.31;

    // 1. Load stem into audition track
    const track = liveApi.getTrack('calibrate-audition');
    liveApi.setClip('calibrate-audition', 0, {
      path: stemPath,
      warpEnabled: true,
      warpMode: 'complex-pro',
      startMarker: autoDownbeat,
      warpMarkers: [{ sample_time: autoDownbeat }],
    });

    expect(liveApi.getCallsFor('setClip')).to.have.lengthOf(1);

    // 2. Simulate user dragging warp marker (LiveAPI emits change)
    const newDownbeat = 2.27;
    liveApi.setClipWarpMarker('calibrate-audition', 0, newDownbeat);

    // 3. Read back marker position (device observes this)
    const markers = liveApi.getClipWarpMarkers('calibrate-audition', 0);
    expect(markers[0].sample_time).to.equal(newDownbeat);

    // 4. User taps "validated" → write override
    const override = buildOverride(trackId, newDownbeat, 'warp_marker_drag', autoDownbeat);
    const filePath = overridePath(stemPath);
    writeOverride(filePath, override, mockFs);

    // 5. Verify override was written correctly
    const written = readOverride(filePath, mockFs);
    expect(written.track_id).to.equal(trackId);
    expect(written.downbeat_sec).to.equal(newDownbeat);
    expect(written.delta_from_auto_sec).to.be.closeTo(-0.04, 0.001);
    expect(written.method).to.equal('warp_marker_drag');
  });

  it('validates without moving marker (auto-cal accepted)', () => {
    const trackId = 'big_poppa';
    const stemPath = '/data/stems/big_poppa/drums.wav';
    const autoDownbeat = 0.85;

    liveApi.setClip('calibrate-audition', 0, {
      path: stemPath,
      warpMarkers: [{ sample_time: autoDownbeat }],
    });

    // User validates immediately without drag
    const override = buildOverride(trackId, autoDownbeat, 'warp_marker_drag', autoDownbeat);
    const filePath = overridePath(stemPath);
    writeOverride(filePath, override, mockFs);

    const written = readOverride(filePath, mockFs);
    expect(written.delta_from_auto_sec).to.equal(0);
  });

  it('preserves previous override when re-calibrating', () => {
    const stemPath = '/data/stems/track_a/drums.wav';
    const filePath = overridePath(stemPath);

    // First calibration
    writeOverride(filePath, buildOverride('track_a', 2.0, 'warp_marker_drag', 2.1), mockFs);

    // Second calibration overwrites
    writeOverride(filePath, buildOverride('track_a', 1.95, 'warp_marker_drag', 2.1), mockFs);

    const written = readOverride(filePath, mockFs);
    expect(written.downbeat_sec).to.equal(1.95);
  });
});
