"""Regression: edited chops must not desync from un-edited chops in the
same song.

Pre-fix bug: an edited sub-bar chop kept lengthBars=1 (= 4 beats) while its
length_sec shrank to ~1.22s. On reload, beatCount was derived from lengthBars,
giving secToBeat = 4/1.22 = 3.28 — making the edited chop play at ~197 BPM
while an untouched chop in the same song played at ~98 BPM.

We can't read warp_bpm directly (M4L LiveAPI doesn't expose it — pitfall #28),
so the test asserts the observable proxies: both clips warped, both with
integer-beat loop_end values, and loop_end ratios that imply the same
underlying secPerBeat (≈ trackBpm/60).
"""

import json
import time

from snapshot import sandbox_manifest_path


def test_edited_and_unedited_chops_stay_in_sync(sandbox_set, loader, live):
    loader.activate_preset(0, settle_secs=5.0)
    sf_drums = live.find_track("sf-drums")

    before0 = live.get_clip_state(sf_drums, 0)
    before1 = live.get_clip_state(sf_drums, 1)
    assert before0.has_clip and before1.has_clip
    assert before0.warping == 1 and before1.warping == 1

    # Shrink drums[0] to half-bar (2 beats), leave drums[1] alone
    live.edit_clip_markers(sf_drums, 0, loop_end=2.0)
    time.sleep(0.5)
    loader.save(settle_secs=3.0)

    loader.eject()
    loader.load_set(sandbox_set)
    loader.activate_preset(0, settle_secs=5.0)

    after0 = live.get_clip_state(sf_drums, 0)
    after1 = live.get_clip_state(sf_drums, 1)
    assert after0.warping == 1 and after1.warping == 1

    # Both must round cleanly to integer beats — the fix's whole point.
    for slot, st in ((0, after0), (1, after1)):
        rounded = round(st.loop_end)
        assert abs(st.loop_end - rounded) < 0.05, (
            f"slot {slot} loop_end={st.loop_end} should be integer-beat (clean grid lock)"
        )
        assert rounded > 0

    # The edited chop must have shrunk; the untouched one must not have.
    assert after0.loop_end < after1.loop_end, (
        f"edited chop[0] should be shorter than untouched chop[1], "
        f"got chop[0]={after0.loop_end}, chop[1]={after1.loop_end}"
    )

    # Manifest invariant: both chops' length_sec / track_bpm should yield the
    # *same* secPerBeat (the pre-fix bug had them diverge by 2×).
    with open(sandbox_manifest_path()) as f:
        manifest = json.load(f)
    t = next(t for t in manifest["tracks"] if str(t.get("id")) == "1835")
    track_bpm = t["bpm"]
    sec_per_beat = 60.0 / track_bpm
    chops = t["stems"]["drums"]["chops"]
    # The first two chops post-edit should be drums[0] (col=1, ~2 beats) and
    # drums[1] (col=2, ~4 beats); their length_sec / sec_per_beat should both
    # round to integer beats.
    for ch in chops[:2]:
        beats_continuous = ch["length_sec"] / sec_per_beat
        assert abs(beats_continuous - round(beats_continuous)) < 0.05, (
            f"chop {ch.get('label')} length_sec={ch['length_sec']} doesn't "
            f"map cleanly to integer beats at track BPM ({beats_continuous:.4f})"
        )
