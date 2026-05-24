'use strict';

/**
 * Modifier layer — row 6 momentary/latch logic.
 *
 * 8 modifiers: HOLD, MUTE, SOLO, REV, STUT, HALF, DBL, KILL.
 * All are momentary by default; double-tap latches.
 */

const MODIFIERS = ['HOLD', 'MUTE', 'SOLO', 'REV', 'STUT', 'HALF', 'DBL', 'KILL'];

const MOD_STATE = {
  IDLE: 'idle',
  HELD: 'held',
  LATCHED: 'latched',
};

const DOUBLE_TAP_WINDOW_MS = 400;

function createModifierLayer() {
  const state = {};
  const lastPressTime = {};

  for (const mod of MODIFIERS) {
    state[mod] = MOD_STATE.IDLE;
    lastPressTime[mod] = 0;
  }

  return {
    /**
     * Get current state of a modifier.
     */
    getState(mod) {
      return state[mod] || MOD_STATE.IDLE;
    },

    /**
     * Get all active modifiers (held or latched).
     */
    getActive() {
      return MODIFIERS.filter(m => state[m] !== MOD_STATE.IDLE);
    },

    /**
     * Is the given modifier active (held or latched)?
     */
    isActive(mod) {
      return state[mod] === MOD_STATE.HELD || state[mod] === MOD_STATE.LATCHED;
    },

    /**
     * Handle pad press (note-on).
     * @param {string} mod - modifier name
     * @param {number} [timestamp] - current time in ms
     * @returns {string} new state
     */
    press(mod, timestamp) {
      if (!MODIFIERS.includes(mod)) return MOD_STATE.IDLE;
      const now = timestamp || Date.now();

      if (state[mod] === MOD_STATE.LATCHED) {
        // Tapping a latched modifier releases it
        state[mod] = MOD_STATE.IDLE;
        return MOD_STATE.IDLE;
      }

      // Check for double-tap
      const delta = now - (lastPressTime[mod] || 0);
      if (delta < DOUBLE_TAP_WINDOW_MS && delta > 0) {
        state[mod] = MOD_STATE.LATCHED;
        lastPressTime[mod] = now;
        return MOD_STATE.LATCHED;
      }

      state[mod] = MOD_STATE.HELD;
      lastPressTime[mod] = now;
      return MOD_STATE.HELD;
    },

    /**
     * Handle pad release (note-off).
     * @param {string} mod
     * @returns {string} new state
     */
    release(mod) {
      if (!MODIFIERS.includes(mod)) return MOD_STATE.IDLE;
      // Only release if held (not latched)
      if (state[mod] === MOD_STATE.HELD) {
        state[mod] = MOD_STATE.IDLE;
      }
      return state[mod];
    },

    /**
     * Clear all modifier state (panic).
     */
    clearAll() {
      for (const mod of MODIFIERS) {
        state[mod] = MOD_STATE.IDLE;
        lastPressTime[mod] = 0;
      }
    },

    /**
     * Get the full state snapshot (for scene memory).
     */
    snapshot() {
      const snap = {};
      for (const mod of MODIFIERS) {
        snap[mod] = state[mod];
      }
      return snap;
    },

    /**
     * Restore from a snapshot (for scene recall).
     */
    restore(snap) {
      if (!snap) return;
      for (const mod of MODIFIERS) {
        if (snap[mod]) {
          state[mod] = snap[mod];
        }
      }
    },
  };
}

module.exports = {
  MODIFIERS,
  MOD_STATE,
  DOUBLE_TAP_WINDOW_MS,
  createModifierLayer,
};
