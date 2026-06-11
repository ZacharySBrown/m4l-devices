"""Setforge contract validator (L1).

Validates a JSON artifact against the matching Setforge schema. Auto-detects
which contract a file is (set.json vs manifest.json) from its shape.

CLI:
    python3 schemas/validate.py <file> [<file> ...]
Exit 0 = all valid, 1 = any invalid/undetected.

Library:
    from schemas.validate import validate_file   # -> (ok, schema_name, errors)
"""
from __future__ import annotations
import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
except ImportError:  # pragma: no cover
    sys.exit("jsonschema not installed — `pip install jsonschema`")

SCHEMA_DIR = Path(__file__).resolve().parent
SCHEMAS = {
    "set": SCHEMA_DIR / "set.schema.json",
    "manifest": SCHEMA_DIR / "manifest.schema.json",
}


def detect_schema(data) -> str | None:
    if not isinstance(data, dict):
        return None
    sv = str(data.get("schema_version", ""))
    if "preset_bank_A" in data or sv == "1.0":
        return "set"
    if "tracks" in data or sv.startswith("2."):
        return "manifest"
    return None


def validate_file(path: str | Path):
    """Return (ok: bool, schema_name: str|None, errors: list[str])."""
    path = Path(path)
    data = json.loads(path.read_text(encoding="utf-8"))
    name = detect_schema(data)
    if name is None:
        return False, None, ["could not detect contract type (not a set or manifest)"]
    schema = json.loads(SCHEMAS[name].read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)
    errors = [
        f"{'/'.join(str(p) for p in e.absolute_path) or '<root>'}: {e.message}"
        for e in sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path))
    ]
    return (not errors), name, errors


def main(argv=None) -> int:
    argv = argv if argv is not None else sys.argv[1:]
    if not argv:
        print("usage: validate.py <file> [<file> ...]")
        return 1
    rc = 0
    for f in argv:
        ok, name, errors = validate_file(f)
        if ok:
            print(f"[PASS] {f}  ({name})")
        else:
            rc = 1
            print(f"[FAIL] {f}  ({name or 'unknown'})")
            for e in errors[:15]:
                print(f"       - {e}")
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
