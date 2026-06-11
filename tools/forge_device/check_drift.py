"""L0 drift-guard — verify the shipped monolith loader.js matches a fresh
concat of src/loader/*.js.

The device ships device/setforge-live/loader.js, concatenated from
src/loader/*.js (LOADER_CONCAT_ORDER) by build_setforge.py. If someone edits a
src/loader file and commits without rebuilding, the shipped monolith silently
drifts from source — the exact class of bug that hid the HFS-path issue. This
guard catches it. The build always regenerates loader.js, so run this as a
pre-commit / CI gate on the committed tree.

Usage:
    python3 -m forge_device.check_drift [DEVICE_DIR]
Exit 0 = in sync, 1 = drift (or error).
"""
from __future__ import annotations
import difflib
import importlib.util
import sys
from pathlib import Path


def _default_device_dir() -> Path:
    # tools/forge_device/check_drift.py -> repo root -> device/setforge-live
    return Path(__file__).resolve().parents[2] / "device" / "setforge-live"


def _load_build_module(device_dir: Path):
    build_py = device_dir / "build" / "build_setforge.py"
    spec = importlib.util.spec_from_file_location("setforge_build_setforge", build_py)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load build module at {build_py}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def check_loader_drift(device_dir: Path | str | None = None) -> tuple[bool, str]:
    """Return (ok, message). ok=True when the shipped loader.js byte-matches a
    fresh concat of src/loader/*."""
    device_dir = Path(device_dir) if device_dir else _default_device_dir()
    shipped_path = device_dir / "loader.js"
    if not shipped_path.exists():
        return False, f"shipped loader.js not found at {shipped_path}"

    mod = _load_build_module(device_dir)
    fresh = mod.build_loader_js_text()
    shipped = shipped_path.read_text(encoding="utf-8")

    if fresh == shipped:
        return True, f"loader.js in sync with src/loader/* ({len(shipped)} bytes)"

    diff = list(difflib.unified_diff(
        shipped.splitlines(), fresh.splitlines(),
        fromfile="shipped loader.js", tofile="fresh concat(src)", lineterm="", n=1))
    hint = "\n".join(diff[:24])
    return False, (
        "loader.js is STALE — it differs from a fresh concat of src/loader/*.\n"
        "Rebuild: cd device/setforge-live && PYTHONPATH=../../tools python3 build/build_setforge.py\n"
        "--- drift (first lines) ---\n" + hint)


def main(argv=None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    device_dir = argv[0] if argv else None
    ok, msg = check_loader_drift(device_dir)
    print(("[PASS] " if ok else "[FAIL] ") + "loader_monolith_in_sync: " + msg)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
