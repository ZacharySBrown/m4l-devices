"""
UAT fixtures for setforge-live integration testing.

Provides:
- Virtual MIDI port fixtures (inject pads, capture LED feedback)
- Inspect file reader (reads /tmp/setforge_inspect.json written by the device)
- Manifest loader (loads expected values from the set manifest)
- UDP command sender (sends messages to the device)
"""

import json
import os
import socket
import time
from pathlib import Path

import pytest

INSPECT_PATH = Path("/tmp/setforge_inspect.json")
MANIFEST_DIR = Path("/Users/zak/zacharysbrown/taste/setlist_out/manifests")
SET_PATH = Path("/Users/zak/Desktop/sets/hiphop_breaks.set.json")
COMBINED_MANIFEST_PATH = Path("/Users/zak/Desktop/sets/hiphop_breaks.manifest.json")

# UDP port for sending commands to the device (if wired)
UDP_CMD_PORT = 7422


@pytest.fixture(scope="session")
def set_data():
    """Load the set.json."""
    with open(SET_PATH) as f:
        return json.load(f)


@pytest.fixture(scope="session")
def manifest_data():
    """Load the combined manifest."""
    with open(COMBINED_MANIFEST_PATH) as f:
        return json.load(f)


@pytest.fixture(scope="session")
def track_manifests():
    """Load individual track manifests keyed by track ID."""
    manifests = {}
    for p in MANIFEST_DIR.glob("*.json"):
        if p.stem.isdigit():
            with open(p) as f:
                m = json.load(f)
            manifests[m["id"]] = m
    return manifests


@pytest.fixture
def inspect_data():
    """Read the latest inspect output from the device.

    The device writes /tmp/setforge_inspect.json when it receives
    the 'inspect' message. This fixture reads it.
    """
    if not INSPECT_PATH.exists():
        pytest.skip("No inspect data — run 'inspect' on the device first")
    with open(INSPECT_PATH) as f:
        return json.load(f)


def send_udp_command(msg: str, port: int = UDP_CMD_PORT):
    """Send a text command to the device via UDP."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(msg.encode(), ("127.0.0.1", port))
    sock.close()


def wait_for_inspect(timeout: float = 10.0) -> dict | None:
    """Send 'inspect' and wait for the JSON file to be updated."""
    before_mtime = INSPECT_PATH.stat().st_mtime if INSPECT_PATH.exists() else 0

    send_udp_command("inspect")

    deadline = time.time() + timeout
    while time.time() < deadline:
        if INSPECT_PATH.exists() and INSPECT_PATH.stat().st_mtime > before_mtime:
            time.sleep(0.1)  # let the write finish
            with open(INSPECT_PATH) as f:
                return json.load(f)
        time.sleep(0.2)
    return None
