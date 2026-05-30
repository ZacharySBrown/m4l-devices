"""Bridge to the setforge-loader device — issues commands and reads its
side-effect files (inspect, manifest, set).

Reuses the existing MIDI/CC paths from tests/uat/setforge_remote.py and adds
load/save round-trip helpers tailored to the curation harness.
"""

import json
import os
import sys
import time
from pathlib import Path
from typing import Optional

import mido

# Bring tests/uat into the path so we can reuse setforge_remote
_UAT_DIR = Path(__file__).resolve().parent.parent / "uat"
sys.path.insert(0, str(_UAT_DIR))
from setforge_remote import send_command, find_iac_port  # noqa: E402


INSPECT_PATH = Path("/tmp/setforge_inspect.json")
CMD_FILE_PATH = Path("/tmp/setforge_cmd.txt")


class LoaderBridge:
    """Talks to setforge-loader via IAC MIDI (CC for commands, file-poll for
    path-bearing commands like `load`). Reads back the device's side-effect
    files when the test needs to check state.
    """

    def __init__(self, port: Optional[mido.ports.BaseOutput] = None):
        if port is None:
            name = find_iac_port()
            if not name:
                raise RuntimeError(
                    "no IAC port; enable IAC Driver in Audio MIDI Setup"
                )
            port = mido.open_output(name)
        self.port = port

    # ── Path-bearing commands go through the file poll. ────────────
    # (CCs only carry 7-bit values, so paths can't ride them; file-poll
    # is still wired and remains the right transport for path args.)

    def load_set(self, path: str | os.PathLike, settle_secs: float = 6.0) -> None:
        """Tell the device to load a set.json. Waits long enough for clip
        creation + warp-marker fix to complete."""
        CMD_FILE_PATH.write_text(f"load {path}\n")
        time.sleep(settle_secs)

    def activate_preset(self, slot_index: int, settle_secs: float = 4.0) -> None:
        """Fire the note for a preset slot. Mapping: row 5/6 cols 1..8 → notes
        41..48 (bank A slot 0-7) and 31..38 (bank B slot 8-15)."""
        if 0 <= slot_index <= 7:
            note = 41 + slot_index
        elif 8 <= slot_index <= 15:
            note = 31 + (slot_index - 8)
        else:
            raise ValueError(f"slot {slot_index} out of range")
        self.port.send(mido.Message("note_on", note=note, velocity=100))
        time.sleep(0.05)
        self.port.send(mido.Message("note_off", note=note, velocity=0))
        time.sleep(settle_secs)

    # ── CC-driven commands (deterministic, instant) ────────────────

    def save(self, settle_secs: float = 3.0) -> None:
        send_command(self.port, "save")
        time.sleep(settle_secs)

    def sync(self, settle_secs: float = 2.0) -> None:
        send_command(self.port, "sync")
        time.sleep(settle_secs)

    def inspect(self, settle_secs: float = 1.5) -> dict:
        """Trigger inspect, then read the resulting /tmp/setforge_inspect.json."""
        if INSPECT_PATH.exists():
            INSPECT_PATH.unlink()
        send_command(self.port, "inspect")
        deadline = time.time() + 8.0
        while time.time() < deadline:
            if INSPECT_PATH.exists() and INSPECT_PATH.stat().st_size > 0:
                time.sleep(settle_secs)
                with open(INSPECT_PATH) as f:
                    return json.load(f)
            time.sleep(0.2)
        raise TimeoutError("inspect file not written within 8s")

    def panic(self, settle_secs: float = 1.0) -> None:
        send_command(self.port, "panic")
        time.sleep(settle_secs)

    def eject(self, settle_secs: float = 1.0) -> None:
        send_command(self.port, "eject")
        time.sleep(settle_secs)
