"""stemforge_bridge — vendored M4L build + telemetry tooling.

See NOTICE.md for provenance. Public API:

    from tools.stemforge_bridge import amxd_pack, patcher

    patch_dict = patcher.build_minimal_audio_effect("MyDevice", width=600, height=220)
    amxd_pack.pack_amxd(patch_dict, "out/MyDevice.amxd", device_class="audio")
"""

from . import amxd_pack, patcher  # noqa: F401

__all__ = ["amxd_pack", "patcher"]
