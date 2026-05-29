"""Snapshot helper — copy the production set into a sandbox the test suite
can corrupt freely without touching the user's real set.

Standard layout assumed:
    ~/Desktop/hiphop_breaks/
        hiphop_breaks.manifest.json
        hiphop_breaks.set.json
        chops/...
        loader.js (a stale copy from the old workflow; we ignore it)

The snapshot lands at:
    ~/Desktop/hiphop_breaks_test/
"""

import hashlib
import os
import shutil
import time
from pathlib import Path


PRODUCTION_DIR = Path.home() / "Desktop" / "hiphop_breaks"
SANDBOX_DIR = Path.home() / "Desktop" / "hiphop_breaks_test"


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:12]


def snapshot(*, force: bool = False) -> Path:
    """Copy production set → sandbox dir. Idempotent: re-runs blow away the
    sandbox and re-copy. Returns the sandbox path.
    """
    if not PRODUCTION_DIR.exists():
        raise FileNotFoundError(f"production set not found: {PRODUCTION_DIR}")

    if SANDBOX_DIR.exists():
        shutil.rmtree(SANDBOX_DIR)
    shutil.copytree(PRODUCTION_DIR, SANDBOX_DIR)

    # Rename the set + manifest to match the sandbox directory's name so the
    # device's "save" produces files in the sandbox, not files that try to
    # overwrite the production names.
    for ext in ("manifest.json", "set.json"):
        prod = SANDBOX_DIR / f"hiphop_breaks.{ext}"
        sandbox = SANDBOX_DIR / f"hiphop_breaks_test.{ext}"
        if prod.exists():
            shutil.move(prod, sandbox)

    # Patch the set.json's "name" field so save_set writes back to the
    # sandbox name. Otherwise save_set computes setPath from setData.name
    # and we'd dirty the production set name.
    set_path = SANDBOX_DIR / "hiphop_breaks_test.set.json"
    if set_path.exists():
        import json
        with open(set_path) as f: s = json.load(f)
        s["name"] = "hiphop_breaks_test"
        with open(set_path, "w") as f: json.dump(s, f, indent=2)

    return SANDBOX_DIR


def sandbox_set_path() -> Path:
    return SANDBOX_DIR / "hiphop_breaks_test.set.json"


def sandbox_manifest_path() -> Path:
    return SANDBOX_DIR / "hiphop_breaks_test.manifest.json"


def file_signature(path: Path) -> dict:
    """Returns mtime/size/sha so tests can detect whether a save happened."""
    if not path.exists():
        return {"exists": False}
    s = path.stat()
    return {
        "exists": True,
        "mtime": s.st_mtime,
        "size": s.st_size,
        "sha": _sha(path),
        "mtime_str": time.strftime("%H:%M:%S", time.localtime(s.st_mtime)),
    }


if __name__ == "__main__":
    p = snapshot()
    print(f"sandbox: {p}")
    print(f"  set:      {sandbox_set_path()}")
    print(f"  manifest: {sandbox_manifest_path()}")
    print(f"  sig: {file_signature(sandbox_set_path())}")
