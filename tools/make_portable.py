#!/usr/bin/env python3
"""Convert a setforge manifest to use relative paths.

Given a .set.json, rewrites its companion .manifest.json so all stem `path`
and chop `chop_path` entries are relative to the set directory. Files that
don't exist under the set directory are left as absolute (with a warning).

Usage:
    python3 tools/make_portable.py /path/to/my_set.set.json
"""

import json
import os
import sys
from pathlib import Path


def make_portable(set_json_path: str) -> None:
    set_path = Path(set_json_path).resolve()
    set_dir = set_path.parent

    with open(set_path) as f:
        set_data = json.load(f)

    manifest_path = set_dir / f"{set_data['name']}.manifest.json"
    if not manifest_path.exists():
        print(f"ERROR: manifest not found: {manifest_path}")
        sys.exit(1)

    with open(manifest_path) as f:
        manifest = json.load(f)

    tracks = manifest.get("tracks", manifest if isinstance(manifest, list) else [])

    converted = 0
    warnings = 0

    for track in tracks:
        stems = track.get("stems", {})
        for stem_name, stem in stems.items():
            if stem.get("path") and os.path.isabs(stem["path"]):
                abs_path = Path(stem["path"])
                try:
                    rel = abs_path.relative_to(set_dir)
                    stem["path"] = str(rel)
                    converted += 1
                except ValueError:
                    # File not under set_dir — check if it exists there by name
                    local = set_dir / track["id"] / abs_path.name
                    if local.exists():
                        stem["path"] = str(local.relative_to(set_dir))
                        converted += 1
                    else:
                        print(f"  WARN: {stem['path']} not under set dir, left absolute")
                        warnings += 1

            for chop in stem.get("chops", []):
                if chop.get("chop_path") and os.path.isabs(chop["chop_path"]):
                    abs_path = Path(chop["chop_path"])
                    try:
                        rel = abs_path.relative_to(set_dir)
                        chop["chop_path"] = str(rel)
                        converted += 1
                    except ValueError:
                        # Try to find it under set_dir/{track_id}/{stem}/
                        local = set_dir / track["id"] / stem_name / abs_path.name
                        if local.exists():
                            chop["chop_path"] = str(local.relative_to(set_dir))
                            converted += 1
                        else:
                            print(f"  WARN: {chop['chop_path']} not under set dir, left absolute")
                            warnings += 1

    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"Converted {converted} paths to relative ({warnings} warnings)")
    print(f"Wrote: {manifest_path}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path/to/set.json>")
        sys.exit(1)
    make_portable(sys.argv[1])
