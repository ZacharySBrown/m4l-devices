"""forge_device — autonomous M4L device build orchestrator.

Public modules:

    audit          Audit-trail emitter (NDJSON, hashable, replayable)
    verifiers      Pitfall verifier suite (the 20 hard-won checks)
    load_verifier  Headless-Max load verifier (pitfall #24, opt-in)
    analyzer       Spec → structured plan + design doc + exec plan
    builder        Spec → patcher dict → .amxd via stemforge_bridge
    cli            /forge-device skill backend
"""

from . import audit, load_verifier, verifiers  # noqa: F401

__all__ = ["audit", "load_verifier", "verifiers"]
