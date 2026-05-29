"""Remote command interface to setforge-loader via MIDI CC.

Replaces the legacy /tmp/setforge_cmd.txt file-poll mechanism, whose timing
was unreliable. The CC map MUST stay in sync with REMOTE_CC_MAP in
src/loader/loader-controller.js.
"""

import time

import mido


# Keep in sync with REMOTE_CC_MAP in loader-controller.js
REMOTE_CC = {
    "save":          100,
    "sync":          101,
    "inspect":       102,
    "panic":         103,
    "eject":         104,
    "reload":        105,
    "debug":         106,
    "save_manifest": 107,
    "save_set":      108,
}


def send_command(port, cmd, settle=0.05):
    """Fire a remote command at the loader via MIDI CC.

    Returns immediately after the CC pair is sent. Callers that need to read
    a side-effect file (e.g. /tmp/setforge_inspect.json after `inspect`) should
    use their own polling loop on that file's mtime — the device is async.
    """
    cc = REMOTE_CC.get(cmd)
    if cc is None:
        raise ValueError("unknown setforge-loader remote command: " + cmd)
    port.send(mido.Message("control_change", control=cc, value=127))
    time.sleep(settle)
    port.send(mido.Message("control_change", control=cc, value=0))


def find_iac_port():
    for name in mido.get_output_names():
        if "IAC" in name:
            return name
    return None
