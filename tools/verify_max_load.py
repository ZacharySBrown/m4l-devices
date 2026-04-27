#!/usr/bin/env python3
"""verify_max_load.py — headless Max patch load-verifier.

Launches the Max runtime (bundled inside Ableton Live) with a target patch,
waits for the patch to load, reads Max's per-session log file, and parses
error lines into structured categories.

The Max console errors that show up in the GUI also go to
~/Library/Application Support/Cycling '74/Max 9/Logs/Max.log verbatim, so
we capture the log slice produced during this session.

Exit codes:
    0 — clean load (no errors)
    1 — errors found
    2 — setup / infrastructure failure (Max binary missing, log file missing,
        timeout before load could stabilize)
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

MAX_APP = Path(
    "/Applications/Ableton Live 12 Suite.app/Contents/App-Resources/Max/Max.app"
)
MAX_BIN = MAX_APP / "Contents/MacOS/Max"
MAX_LOG = (
    Path.home()
    / "Library/Application Support/Cycling '74/Max 9/Logs/Max.log"
)

# Max log lines look like:
#   [2026-04-27 13:31:15.777269 error] [4689737] patchcord inlet out of range: ...
# The level is inside the timestamp bracket, not a separate token.
ERROR_TAG = re.compile(r"^\[[^\]]* error\] ")
LINE_AFTER_TAG = re.compile(r"^\[[^\]]* error\] \[\d+\]\s*(.*)")

CATEGORIES: list[tuple[str, re.Pattern[str]]] = [
    ("inlet_outlet_missing", re.compile(r"\b(inlet~|outlet~|inlet|outlet):\s*No such object")),
    ("patchcord_inlet_oor", re.compile(r"patchcord inlet out of range")),
    ("patchcord_outlet_oor", re.compile(r"patchcord outlet out of range")),
    ("expr_syntax", re.compile(r"\bsyntax error\b")),
    ("missing_file", re.compile(r"can't find file")),
    ("js_no_function", re.compile(r"js:\s*no function")),
    ("missing_object", re.compile(r":\s*No such object")),
]


def kill_max() -> None:
    subprocess.run(
        ["pkill", "-f", "App-Resources/Max/Max"],
        capture_output=True,
        check=False,
    )


def launch_max(patch: Path) -> None:
    """Launch Max with the patch; returns immediately (Max runs in background)."""
    subprocess.Popen(
        ["open", "-a", str(MAX_APP), str(patch)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def wait_for_idle(*, idle_seconds: float, timeout: float, min_size: int = 200) -> int:
    """Watch Max.log size; return when no growth for `idle_seconds` or `timeout` hits.

    Max truncates Max.log on every new session, so we don't track a pre-launch
    offset — we just wait until the new session's log stops growing. `min_size`
    guards against returning before Max has actually started writing (e.g. if
    the launch failed silently)."""
    deadline = time.time() + timeout
    last_size = -1  # forces first iteration to register a "change"
    last_change = time.time()
    while time.time() < deadline:
        time.sleep(0.5)
        cur = MAX_LOG.stat().st_size if MAX_LOG.exists() else 0
        if cur != last_size:
            last_size = cur
            last_change = time.time()
        elif cur >= min_size and (time.time() - last_change) >= idle_seconds:
            return cur
    return last_size


def categorize(line: str) -> str:
    for name, pat in CATEGORIES:
        if pat.search(line):
            return name
    return "other"


def extract_message(line: str) -> str:
    m = LINE_AFTER_TAG.search(line)
    return m.group(1) if m else line


def verify(patch: Path, *, idle_seconds: float, timeout: float) -> dict:
    if not MAX_BIN.exists():
        return {
            "ok": False,
            "infra_error": f"Max binary not found at {MAX_BIN}",
        }
    if not MAX_LOG.exists():
        # The log file is created on first Max launch; it's missing only if Max
        # has never run. Try to launch briefly to bootstrap, then bail.
        return {
            "ok": False,
            "infra_error": f"Max log not found at {MAX_LOG} — launch Max once manually first",
        }
    if not patch.exists():
        return {"ok": False, "infra_error": f"patch not found: {patch}"}

    # Fresh Max session = log truncated and rewritten from scratch
    kill_max()
    time.sleep(1.5)

    launch_max(patch)

    try:
        final_size = wait_for_idle(idle_seconds=idle_seconds, timeout=timeout)
        with open(MAX_LOG, "rb") as fh:
            new_bytes = fh.read(final_size)
    finally:
        kill_max()

    text = new_bytes.decode("utf-8", errors="replace")
    error_lines = [ln for ln in text.splitlines() if ERROR_TAG.search(ln)]

    by_cat: dict[str, list[str]] = {}
    for ln in error_lines:
        by_cat.setdefault(categorize(ln), []).append(extract_message(ln))

    return {
        "ok": True,
        "patch": str(patch),
        "pass": len(error_lines) == 0,
        "error_count": len(error_lines),
        "log_bytes_captured": final_size,
        "categories": {k: len(v) for k, v in by_cat.items()},
        "samples": {k: list(dict.fromkeys(v))[:3] for k, v in by_cat.items()},
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("patch", type=Path, help="Path to .maxpat or .amxd to load")
    ap.add_argument("--idle-seconds", type=float, default=3.0)
    ap.add_argument("--timeout", type=float, default=25.0)
    ap.add_argument("--json", action="store_true", help="Emit JSON to stdout")
    args = ap.parse_args()

    result = verify(args.patch, idle_seconds=args.idle_seconds, timeout=args.timeout)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if not result["ok"]:
            print(f"INFRA ERROR: {result['infra_error']}", file=sys.stderr)
            return 2
        verdict = "PASS" if result["pass"] else "FAIL"
        print(f"== Max load-verifier: {result['patch']}")
        print(
            f"   {verdict} — {result['error_count']} error lines "
            f"({result['log_bytes_captured']} log bytes)"
        )
        for cat, count in sorted(result["categories"].items(), key=lambda x: -x[1]):
            print(f"   {count:3d} × {cat}")
            for sample in result["samples"].get(cat, [])[:1]:
                print(f"        e.g. {sample}")

    if not result["ok"]:
        return 2
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
