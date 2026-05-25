// ═══════════════════════════════════════════════════════════
//  Launchpad Surface — interface dispatcher
// ═══════════════════════════════════════════════════════════
//
// Factory that creates the right surface implementation based on model.
// The rest of the device talks to `surface.*` — never raw SysEx.
//
// Interface contract (all concrete implementations satisfy this):
//
//   surface.model              → "mk2" | "mk3"
//   surface.noteToRowCol(note) → { row, col } | null
//   surface.rowColToNote(row, col) → note number
//   surface.sideButtonIndex(note)  → 0-7 or -1
//   surface.queueRgb(grid, row, col, [r,g,b])  → void (buffered)
//   surface.queueRgbNote(grid, note, [r,g,b])   → void (buffered)
//   surface.flushRgb(grid)     → array of SysEx byte arrays
//   surface.enterProgrammerMode() → SysEx byte array
//   surface.leaveProgrammerMode() → SysEx byte array
//   surface.buildPulseSysex(note, paletteIndex)    → SysEx byte array | null
//   surface.buildFlashSysex(note, colorA, colorB)  → SysEx byte array | null
//
// Colors are 0-127 (7-bit) at the interface boundary.
// MK2 passes through; MK3 could scale up internally if needed.
//
// This file is concatenated into loader.js by the build script.
// Depends on: launchpad-surface-mk2.js, launchpad-surface-mk3.js

function createSurface(model) {
    if (model === "mk3") return createMk3Surface();
    return createMk2Surface();
}
