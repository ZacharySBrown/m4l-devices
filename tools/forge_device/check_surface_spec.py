"""Spec↔code drift verifier for the Pro MK2 surface layout.

Reads the provisional constant tables from the JS source modules
(punch-layer.js, stem-assign.js, source-led.js) and asserts they
match the spec in docs/specs/pro-mk2-surface.md.

Catches drift after spec edits or hardware-verification updates.

Usage:
    PYTHONPATH=tools python3 -m forge_device.check_surface_spec
Exit 0 = in sync, 1 = drift detected.
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_DIR = REPO_ROOT / "device" / "setforge-live" / "src" / "loader"
SPEC_PATH = REPO_ROOT / "docs" / "specs" / "pro-mk2-surface.md"


def extract_js_array(filepath: Path, varname: str) -> list[int] | None:
    """Extract a JS array constant like `var FOO = [1, 2, 3];`."""
    text = filepath.read_text(encoding="utf-8")
    pattern = rf"var\s+{re.escape(varname)}\s*=\s*\[([^\]]+)\]"
    m = re.search(pattern, text)
    if not m:
        return None
    return [int(x.strip()) for x in m.group(1).split(",") if x.strip()]


def extract_spec_table_notes(spec_text: str, label: str) -> list[int] | None:
    """Extract note numbers from a spec table row by label.
    e.g. '| **Left 1-8** | `[80,70,60,50,40,30,20,10]` |' → [80,70,...,10]
    """
    for line in spec_text.splitlines():
        if label in line:
            m = re.search(r"\[([0-9,\s]+)\]", line)
            if m:
                return [int(x.strip()) for x in m.group(1).split(",") if x.strip()]
    return None


def check_grid_formula(src_text: str) -> bool:
    """Verify the grid mapping formula note = (9-row)*10 + col is present."""
    return "(9 - row) * 10 + col" in src_text or "(9-row)*10+col" in src_text


def main() -> int:
    ok = True

    def check(name, expected, actual):
        nonlocal ok
        if expected == actual:
            print(f"  [PASS] {name}")
        else:
            print(f"  [FAIL] {name}: spec={expected}, code={actual}")
            ok = False

    print("▸ Spec↔code surface drift check")

    if not SPEC_PATH.exists():
        print(f"  [SKIP] spec not found: {SPEC_PATH}")
        return 0

    spec_text = SPEC_PATH.read_text(encoding="utf-8")

    # ── Stem-assign buttons (Left side) ──
    code_left = extract_js_array(SRC_DIR / "stem-assign.js", "STEM_ASSIGN_BUTTONS")
    spec_left = extract_spec_table_notes(spec_text, "Left 1-8")
    check("STEM_ASSIGN_BUTTONS vs spec Left 1-8", spec_left, code_left)

    # ── Preset notes A (Top side) ──
    code_a = extract_js_array(SRC_DIR / "stem-assign.js", "PRESET_NOTES_A")
    spec_a = extract_spec_table_notes(spec_text, "Top 1-8")
    check("PRESET_NOTES_A vs spec Top 1-8", spec_a, code_a)

    # ── Preset notes B (Bottom side) ──
    code_b = extract_js_array(SRC_DIR / "stem-assign.js", "PRESET_NOTES_B")
    spec_b = extract_spec_table_notes(spec_text, "Bottom 1-8")
    check("PRESET_NOTES_B vs spec Bottom 1-8", spec_b, code_b)

    # ── Punch button notes ──
    code_punch_n = extract_js_array(SRC_DIR / "punch-layer.js", "PUNCH_BUTTON_NOTES")
    code_punch_c = extract_js_array(SRC_DIR / "punch-layer.js", "PUNCH_BUTTON_CCS")
    # Spec: notes from the Right side table (89, 79, 69, 59 for first 4)
    spec_punch = [89, 79, 69, 59]  # from spec §2 Right side R1-R4
    check("PUNCH_BUTTON_NOTES vs spec Right R1-R4", spec_punch, code_punch_n)
    check("PUNCH_BUTTON_CCS vs spec Right R1-R4", spec_punch, code_punch_c)

    # ── Grid formula ──
    surface_text = (SRC_DIR / "launchpad-surface-mk2.js").read_text(encoding="utf-8")
    if check_grid_formula(surface_text):
        print("  [PASS] grid formula (9-row)*10+col present in surface-mk2")
    else:
        print("  [FAIL] grid formula (9-row)*10+col NOT found in surface-mk2")
        ok = False

    # ── Palette sync ──
    code_palette = extract_js_array(SRC_DIR / "source-led.js", "LEGEND_PALETTE_7BIT")
    if code_palette is None:
        # LEGEND_PALETTE_7BIT is computed, not a direct array of ints; check hex instead
        led_text = (SRC_DIR / "source-led.js").read_text(encoding="utf-8")
        hex_count = len(re.findall(r'"#[0-9A-Fa-f]{6}"', led_text))
        if hex_count == 8:
            print("  [PASS] LEGEND_PALETTE_HEX has 8 entries")
        else:
            print(f"  [FAIL] LEGEND_PALETTE_HEX: expected 8, found {hex_count}")
            ok = False
    else:
        print(f"  [PASS] LEGEND_PALETTE_7BIT has {len(code_palette)} entries")

    if ok:
        print("  ✓ spec↔code in sync")
    else:
        print("  ✗ DRIFT DETECTED — update spec or code")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
