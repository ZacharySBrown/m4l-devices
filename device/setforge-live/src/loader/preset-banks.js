'use strict';

/**
 * Preset banks — 16-slot state machine for loaded songs.
 *
 * Bank A = slots 0-7 (Grid 1, row 1)
 * Bank B = slots 8-15 (Grid 1, row 7)
 */

const SLOTS_PER_BANK = 8;
const TOTAL_SLOTS = 16;

const SLOT_STATE = {
  EMPTY: 'empty',
  LOADING: 'loading',
  LOADED_IDLE: 'loaded_idle',
  LOADED_ACTIVE: 'loaded_active',
  ERROR: 'error',
};

function createSlot(index) {
  return {
    index,
    state: SLOT_STATE.EMPTY,
    trackId: null,
    track: null,      // full track object from manifest
    chops: null,      // computed chops from chop-math
    bank: index < SLOTS_PER_BANK ? 'A' : 'B',
  };
}

function createPresetBanks() {
  const slots = Array.from({ length: TOTAL_SLOTS }, (_, i) => createSlot(i));
  let activeSlotIndex = null;

  return {
    /**
     * Get all slots.
     */
    getSlots() {
      return slots;
    },

    /**
     * Get a slot by index.
     */
    getSlot(index) {
      if (index < 0 || index >= TOTAL_SLOTS) return null;
      return slots[index];
    },

    /**
     * Get the currently active slot.
     */
    getActive() {
      return activeSlotIndex !== null ? slots[activeSlotIndex] : null;
    },

    /**
     * Get the active slot index.
     */
    getActiveIndex() {
      return activeSlotIndex;
    },

    /**
     * Load a track into a slot.
     */
    loadSlot(index, trackId, track, chops) {
      if (index < 0 || index >= TOTAL_SLOTS) {
        throw new Error(`Slot index out of range: ${index}`);
      }
      const slot = slots[index];
      slot.state = SLOT_STATE.LOADED_IDLE;
      slot.trackId = trackId;
      slot.track = track;
      slot.chops = chops;
    },

    /**
     * Mark a slot as loading.
     */
    setLoading(index) {
      if (index >= 0 && index < TOTAL_SLOTS) {
        slots[index].state = SLOT_STATE.LOADING;
      }
    },

    /**
     * Mark a slot as error.
     */
    setError(index) {
      if (index >= 0 && index < TOTAL_SLOTS) {
        slots[index].state = SLOT_STATE.ERROR;
      }
    },

    /**
     * Activate a slot (make it the source for rows 2-5).
     * Returns { previous, current } slot indices.
     */
    activate(index) {
      if (index < 0 || index >= TOTAL_SLOTS) return null;
      const slot = slots[index];
      if (slot.state !== SLOT_STATE.LOADED_IDLE && slot.state !== SLOT_STATE.LOADED_ACTIVE) {
        return null; // can't activate empty/loading/error slots
      }

      const previous = activeSlotIndex;

      // Deactivate previous
      if (previous !== null && previous !== index) {
        slots[previous].state = SLOT_STATE.LOADED_IDLE;
      }

      // Activate new
      slot.state = SLOT_STATE.LOADED_ACTIVE;
      activeSlotIndex = index;

      return { previous, current: index };
    },

    /**
     * Clear a slot (eject).
     */
    clearSlot(index) {
      if (index < 0 || index >= TOTAL_SLOTS) return;
      const slot = slots[index];
      slot.state = SLOT_STATE.EMPTY;
      slot.trackId = null;
      slot.track = null;
      slot.chops = null;
      if (activeSlotIndex === index) {
        activeSlotIndex = null;
      }
    },

    /**
     * Clear all slots (full eject).
     */
    clearAll() {
      for (let i = 0; i < TOTAL_SLOTS; i++) {
        this.clearSlot(i);
      }
      activeSlotIndex = null;
    },

    /**
     * Find a slot by track ID.
     */
    findByTrackId(trackId) {
      return slots.find(s => s.trackId === trackId) || null;
    },

    /**
     * Find the next empty slot, optionally within a specific bank.
     * @param {'A'|'B'} [bank]
     */
    findNextEmpty(bank) {
      const start = bank === 'B' ? SLOTS_PER_BANK : 0;
      const end = bank === 'A' ? SLOTS_PER_BANK : TOTAL_SLOTS;
      for (let i = start; i < end; i++) {
        if (slots[i].state === SLOT_STATE.EMPTY) return slots[i];
      }
      return null;
    },

    /**
     * Get bank A slots (indices 0-7).
     */
    getBankA() {
      return slots.slice(0, SLOTS_PER_BANK);
    },

    /**
     * Get bank B slots (indices 8-15).
     */
    getBankB() {
      return slots.slice(SLOTS_PER_BANK);
    },
  };
}

module.exports = {
  SLOTS_PER_BANK,
  TOTAL_SLOTS,
  SLOT_STATE,
  createPresetBanks,
};
