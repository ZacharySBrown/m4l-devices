'use strict';

/**
 * Mock Launchpad — simulates Launchpad MIDI in/out for testing.
 *
 * Records all RGB writes and emits scripted MIDI input.
 * Tests assert on the recorded RGB sequence.
 */

function createMockLaunchpad(gridId) {
  const rgbWrites = [];
  const noteOnHandlers = [];
  const noteOffHandlers = [];

  return {
    gridId,

    /**
     * Register handler for note-on events.
     */
    onNoteOn(handler) {
      noteOnHandlers.push(handler);
    },

    /**
     * Register handler for note-off events.
     */
    onNoteOff(handler) {
      noteOffHandlers.push(handler);
    },

    /**
     * Simulate a pad press (note-on).
     * @param {number} note - MIDI note number
     * @param {number} [velocity=127]
     */
    simulateNoteOn(note, velocity) {
      const event = { note, velocity: velocity || 127, timestamp: Date.now() };
      for (const handler of noteOnHandlers) {
        handler(event);
      }
    },

    /**
     * Simulate a pad release (note-off).
     * @param {number} note
     */
    simulateNoteOff(note) {
      const event = { note, velocity: 0, timestamp: Date.now() };
      for (const handler of noteOffHandlers) {
        handler(event);
      }
    },

    /**
     * Simulate a pad tap (on + off with delay).
     */
    simulateTap(note, velocity) {
      this.simulateNoteOn(note, velocity);
      this.simulateNoteOff(note);
    },

    /**
     * Record an RGB write (called by the surface code).
     */
    writeRgb(note, rgb) {
      rgbWrites.push({ note, rgb: [...rgb], timestamp: Date.now() });
    },

    /**
     * Send a SysEx message (record it).
     */
    sendSysex(bytes) {
      // Parse LED updates from SysEx
      // Skip header (7 bytes) and footer (1 byte)
      for (let i = 7; i < bytes.length - 1; i += 5) {
        if (bytes[i] === 0x03) {
          const note = bytes[i + 1];
          const r = bytes[i + 2];
          const g = bytes[i + 3];
          const b = bytes[i + 4];
          rgbWrites.push({ note, rgb: [r, g, b], timestamp: Date.now() });
        }
      }
    },

    /**
     * Get all RGB writes.
     */
    getRgbWrites() {
      return rgbWrites;
    },

    /**
     * Get the last RGB write for a specific note.
     */
    getLastColorForNote(note) {
      for (let i = rgbWrites.length - 1; i >= 0; i--) {
        if (rgbWrites[i].note === note) return rgbWrites[i].rgb;
      }
      return null;
    },

    /**
     * Clear recorded writes.
     */
    clearWrites() {
      rgbWrites.length = 0;
    },

    /**
     * Reset everything.
     */
    reset() {
      rgbWrites.length = 0;
      noteOnHandlers.length = 0;
      noteOffHandlers.length = 0;
    },
  };
}

module.exports = { createMockLaunchpad };
