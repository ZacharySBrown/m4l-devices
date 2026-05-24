'use strict';

/**
 * Mock LiveAPI — simulates the Ableton Live API surface for testing.
 *
 * Records all LiveAPI calls (clip creation, marker placement, transport)
 * and lets tests pre-script return values and assert on call sequences.
 */

function createMockLiveApi() {
  const calls = [];
  const tracks = {};
  let globalTempo = 120;
  let transportPlaying = false;

  function recordCall(method, args) {
    calls.push({ method, args, timestamp: Date.now() });
  }

  return {
    /**
     * Get a track by name, creating it if needed.
     */
    getTrack(name) {
      if (!tracks[name]) {
        tracks[name] = {
          name,
          clipSlots: Array.from({ length: 128 }, () => ({
            clip: null,
            hasClip: false,
          })),
          muted: false,
          soloed: false,
        };
      }
      recordCall('getTrack', { name });
      return tracks[name];
    },

    /**
     * Set a clip in a track's slot.
     */
    setClip(trackName, slotIndex, clipData) {
      const track = this.getTrack(trackName);
      track.clipSlots[slotIndex] = {
        clip: { ...clipData, playing: false, launched: false },
        hasClip: true,
      };
      recordCall('setClip', { trackName, slotIndex, clipData });
    },

    /**
     * Launch a clip.
     */
    launchClip(trackName, slotIndex) {
      const track = this.getTrack(trackName);
      const slot = track.clipSlots[slotIndex];
      if (slot && slot.clip) {
        // Stop any other playing clips in this track
        for (const s of track.clipSlots) {
          if (s.clip) s.clip.playing = false;
        }
        slot.clip.playing = true;
        slot.clip.launched = true;
      }
      recordCall('launchClip', { trackName, slotIndex });
    },

    /**
     * Stop a clip.
     */
    stopClip(trackName, slotIndex) {
      const track = this.getTrack(trackName);
      const slot = track.clipSlots[slotIndex];
      if (slot && slot.clip) {
        slot.clip.playing = false;
      }
      recordCall('stopClip', { trackName, slotIndex });
    },

    /**
     * Stop all clips across all tracks.
     */
    stopAllClips() {
      for (const track of Object.values(tracks)) {
        for (const slot of track.clipSlots) {
          if (slot.clip) slot.clip.playing = false;
        }
      }
      recordCall('stopAllClips', {});
    },

    /**
     * Get/set global tempo.
     */
    getGlobalTempo() {
      recordCall('getGlobalTempo', {});
      return globalTempo;
    },

    setGlobalTempo(bpm) {
      globalTempo = bpm;
      recordCall('setGlobalTempo', { bpm });
    },

    /**
     * Transport controls.
     */
    startTransport() {
      transportPlaying = true;
      recordCall('startTransport', {});
    },

    stopTransport() {
      transportPlaying = false;
      recordCall('stopTransport', {});
    },

    isTransportPlaying() {
      return transportPlaying;
    },

    /**
     * Warp marker operations.
     */
    setClipWarpMarker(trackName, slotIndex, sampleTime) {
      const track = this.getTrack(trackName);
      const slot = track.clipSlots[slotIndex];
      if (slot && slot.clip) {
        if (!slot.clip.warpMarkers) slot.clip.warpMarkers = [];
        slot.clip.warpMarkers[0] = { sample_time: sampleTime };
      }
      recordCall('setClipWarpMarker', { trackName, slotIndex, sampleTime });
    },

    getClipWarpMarkers(trackName, slotIndex) {
      const track = this.getTrack(trackName);
      const slot = track.clipSlots[slotIndex];
      recordCall('getClipWarpMarkers', { trackName, slotIndex });
      return (slot && slot.clip && slot.clip.warpMarkers) || [];
    },

    // --- Test utilities ---

    /**
     * Get the full call log.
     */
    getCalls() {
      return calls;
    },

    /**
     * Get calls filtered by method name.
     */
    getCallsFor(method) {
      return calls.filter(c => c.method === method);
    },

    /**
     * Clear the call log.
     */
    clearCalls() {
      calls.length = 0;
    },

    /**
     * Reset everything.
     */
    reset() {
      calls.length = 0;
      for (const key of Object.keys(tracks)) delete tracks[key];
      globalTempo = 120;
      transportPlaying = false;
    },
  };
}

module.exports = { createMockLiveApi };
