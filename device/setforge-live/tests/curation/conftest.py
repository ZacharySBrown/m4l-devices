"""Shared fixtures for curation ops 1-5.

Pulls the OSC + LoaderBridge + sandbox-snapshot setup out of individual
test files so each op test stays focused on its own assertions.
"""

import sys
from pathlib import Path

import pytest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from live_bridge import LiveBridge
from loader_bridge import LoaderBridge
from osc_client import AbletonOSC
from snapshot import snapshot, sandbox_set_path


@pytest.fixture(scope="session")
def osc():
    o = AbletonOSC(default_timeout=4.0)
    yield o
    o.close()


@pytest.fixture(scope="session")
def live(osc):
    return LiveBridge(osc)


@pytest.fixture(scope="session")
def loader():
    return LoaderBridge()


@pytest.fixture
def sandbox_set(loader):
    """Per-test: snapshot a fresh copy of the production set into the sandbox
    and load it into the device. Tests get an isolated, known-good state.
    """
    snapshot()
    loader.panic()
    loader.eject()
    loader.load_set(sandbox_set_path())
    yield sandbox_set_path()
    loader.panic()
