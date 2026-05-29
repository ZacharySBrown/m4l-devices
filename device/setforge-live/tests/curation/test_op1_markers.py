"""Op 1 — edit clip markers, save, reload, verify persistence.

This is the first test in the curation suite. It exercises the already-working
path: change a clip's loop_start / loop_end in Live, save the device, reload
the set, and assert the manifest's chop start_sec / length_sec reflect the
change.

Pre-reqs:
  - Live running with setforge-loader + setforge-grid devices loaded
  - AbletonOSC enabled in Live → Preferences → Link / Tempo / MIDI
  - IAC Driver Bus 1 enabled and routed to the grid track's MIDI From
  - ~/Desktop/hiphop_breaks/ contains the production set
"""

import json
import sys
import time
from pathlib import Path

import pytest

# Imports relative to tests/curation/
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from live_bridge import LiveBridge, STEMS
from loader_bridge import LoaderBridge
from osc_client import AbletonOSC
from snapshot import snapshot, sandbox_manifest_path, sandbox_set_path, file_signature


@pytest.fixture(scope="module")
def osc():
    o = AbletonOSC(default_timeout=4.0)
    yield o
    o.close()


@pytest.fixture(scope="module")
def live(osc):
    return LiveBridge(osc)


@pytest.fixture(scope="module")
def loader():
    return LoaderBridge()


@pytest.fixture
def sandbox_set(loader):
    """Per-test: snapshot a fresh copy of the production set into the sandbox
    and tell the loader to load it.
    """
    set_path = snapshot()
    loader.panic()
    loader.eject()
    loader.load_set(sandbox_set_path())
    yield sandbox_set_path()
    loader.panic()


# ─────────────────────────────────────────────────────────────────────
# Op 1: change loop_end on slot 0 of sf-drums → save → reload → verify
# ─────────────────────────────────────────────────────────────────────

def test_loop_end_change_persists(sandbox_set, loader, live):
    # Activate Electric Relaxation (preset A slot 0 = 1835)
    loader.activate_preset(0, settle_secs=5.0)

    sf_drums = live.find_track("sf-drums")
    before = live.get_clip_state(sf_drums, 0)
    assert before.has_clip, "sf-drums slot 0 should hold a clip after activation"
    assert before.warping == 1, "drums clip should be warped"

    original_loop_end = before.loop_end
    # Shorten the loop by 1 beat. 4-beat 1-bar clip → 3-beat half-ish loop.
    new_loop_end = max(1.0, original_loop_end - 1.0)
    live.edit_clip_markers(sf_drums, 0, loop_end=new_loop_end)
    time.sleep(0.5)

    # Verify Live actually applied it
    after_edit = live.get_clip_state(sf_drums, 0)
    assert abs(after_edit.loop_end - new_loop_end) < 0.01, (
        f"Live didn't accept loop_end change: wanted {new_loop_end}, "
        f"got {after_edit.loop_end}"
    )

    # Snapshot the manifest pre-save so we can prove a write happened
    pre_sig = file_signature(sandbox_manifest_path())

    loader.save(settle_secs=3.0)

    post_sig = file_signature(sandbox_manifest_path())
    assert post_sig["mtime"] > pre_sig["mtime"], "manifest mtime should have advanced after save"
    assert post_sig["sha"] != pre_sig["sha"], "manifest content should have changed after save"

    # Reload the set from disk; the change should come back through
    loader.eject()
    loader.load_set(sandbox_set_path())
    loader.activate_preset(0, settle_secs=5.0)

    reloaded = live.get_clip_state(sf_drums, 0)
    # Compare with a generous tolerance — sync may round, warp-marker pass may
    # re-position, etc. We just want to confirm the change persisted in the
    # same ballpark, not the exact float.
    expected_window = (
        original_loop_end * 0.6,   # at least notably shorter than original
        original_loop_end * 0.95,
    )
    assert expected_window[0] <= reloaded.loop_end <= expected_window[1], (
        f"loop_end change didn't persist through reload: "
        f"original={original_loop_end}, edited={new_loop_end}, "
        f"reloaded={reloaded.loop_end}, expected within {expected_window}"
    )


def test_manifest_chop_length_reflects_loop_change(sandbox_set, loader, live):
    """Direct manifest assertion: after editing loop_end and saving, the
    manifest's drums[0].length_sec should reflect the shorter loop.
    """
    loader.activate_preset(0, settle_secs=5.0)
    sf_drums = live.find_track("sf-drums")

    before = live.get_clip_state(sf_drums, 0)
    original_loop_end = before.loop_end

    # Halve the loop
    new_loop_end = original_loop_end / 2.0
    live.edit_clip_markers(sf_drums, 0, loop_end=new_loop_end)
    time.sleep(0.5)

    loader.save(settle_secs=3.0)

    # Now read the manifest off disk and check chop[0]
    with open(sandbox_manifest_path()) as f:
        manifest = json.load(f)

    track_1835 = next(t for t in manifest["tracks"] if str(t.get("id")) == "1835")
    drums_chops = track_1835["stems"]["drums"]["chops"]
    chop0 = drums_chops[0]

    # The chop's length_sec should now be roughly half of the original
    # (original was ~2.4s for a 4-beat clip at ~98 BPM → ~1.2s half).
    assert chop0["length_sec"] < 2.0, (
        f"manifest chop[0].length_sec should reflect shorter loop, got {chop0['length_sec']}"
    )
