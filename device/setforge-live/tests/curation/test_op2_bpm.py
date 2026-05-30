"""Op 2 — per-clip BPM persistence.

XFAIL: M4L's LiveAPI doesn't expose `Clip.warp_bpm`. The clip-class property
list visible to JS-LiveAPI is {warping, warp_mode, warp_markers,
available_warp_modes} — no warp_bpm. Reading returns 0; writing is a silent
no-op. AbletonOSC routes through the same LOM bridge and gets the same
restriction (reads time out).

The existing op-2 wiring (loader-controller.js set("warp_bpm") on load,
sync read of warp_bpm) is dead code. Real per-clip BPM persistence requires
manipulating warp markers to retarget the effective tempo — a separate
design pass, not a property write.

Pitfall #28 (M4L LiveAPI omits Clip.warp_bpm) is documented in the handoff;
this test is left in place as a regression marker for if/when Live exposes
the property or we implement the marker-based fallback.
"""

import time

import pytest


@pytest.mark.xfail(
    strict=True,
    reason="M4L LiveAPI doesn't expose Clip.warp_bpm — pitfall #28. "
           "Per-clip BPM persistence needs warp-marker manipulation, "
           "not a property write. Tracked for a follow-up design pass.",
)
def test_warp_bpm_change_persists(sandbox_set, loader, live):
    loader.activate_preset(0, settle_secs=5.0)
    sf_drums = live.find_track("sf-drums")
    before = live.get_clip_state(sf_drums, 0)
    track_bpm = before.warp_bpm
    new_bpm = round(track_bpm + 10.0, 2)
    live.set_clip_bpm(sf_drums, 0, new_bpm)
    time.sleep(0.5)
    after_edit = live.get_clip_state(sf_drums, 0)
    assert abs(after_edit.warp_bpm - new_bpm) < 0.01, "Live didn't accept warp_bpm change"
    loader.save(settle_secs=3.0)
    loader.eject()
    loader.load_set(sandbox_set)
    loader.activate_preset(0, settle_secs=5.0)
    reloaded = live.get_clip_state(sf_drums, 0)
    assert abs(reloaded.warp_bpm - new_bpm) < 0.5, "warp_bpm didn't persist"
