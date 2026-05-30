"""Minimal AbletonOSC client wrapper for the curation test harness.

Wraps the request/response pattern: send an OSC message to Live, wait for the
reply on the listener port. AbletonOSC defaults to listening on 11000 (Live
side) and replying on 11001 (our side).
"""

import queue
import threading
import time
from typing import Any

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import ThreadingOSCUDPServer
from pythonosc.udp_client import SimpleUDPClient

LIVE_HOST = "127.0.0.1"
LIVE_PORT = 11000   # Live listens here (AbletonOSC default)
LOCAL_PORT = 11001  # we listen here (AbletonOSC default reply target)


class AbletonOSC:
    """Send requests to Live and collect their replies."""

    def __init__(self, host: str = LIVE_HOST, send_port: int = LIVE_PORT,
                 listen_port: int = LOCAL_PORT, default_timeout: float = 2.0):
        self.client = SimpleUDPClient(host, send_port)
        self.default_timeout = default_timeout

        self._replies: "queue.Queue[tuple[str, tuple[Any, ...]]]" = queue.Queue()

        dispatcher = Dispatcher()
        dispatcher.set_default_handler(self._on_reply)
        self._server = ThreadingOSCUDPServer((host, listen_port), dispatcher)
        self._thread = threading.Thread(target=self._server.serve_forever, daemon=True)
        self._thread.start()

    def _on_reply(self, address: str, *args):
        self._replies.put((address, args))

    def send(self, address: str, *args):
        """Fire a message at Live and don't wait for a reply."""
        if args:
            self.client.send_message(address, list(args))
        else:
            self.client.send_message(address, [])

    def ask(self, address: str, *args, timeout: float = None) -> tuple[Any, ...]:
        """Send a /live/clip/get/foo style request and wait for the matching reply.

        AbletonOSC replies on the same address that was sent. The first reply
        on that address (within timeout) is returned as the args tuple.
        """
        if timeout is None:
            timeout = self.default_timeout
        # Drain any stale replies so we don't return a stale value
        while not self._replies.empty():
            try: self._replies.get_nowait()
            except queue.Empty: break
        self.send(address, *args)
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                reply_addr, reply_args = self._replies.get(timeout=0.1)
            except queue.Empty:
                continue
            if reply_addr == address:
                return reply_args
        raise TimeoutError(f"no OSC reply on {address} within {timeout}s")

    def close(self):
        self._server.shutdown()
        self._server.server_close()


def smoke_test() -> bool:
    """Round-trip ping to confirm AbletonOSC is responding."""
    osc = AbletonOSC(default_timeout=3.0)
    try:
        # /live/test is AbletonOSC's built-in echo endpoint
        reply = osc.ask("/live/test")
        print(f"  /live/test reply: {reply}")

        # Pull Live's version as proof we're actually talking to it
        reply = osc.ask("/live/application/get/version")
        print(f"  Live version: {reply}")

        # Pull the open set's track count for sanity
        reply = osc.ask("/live/song/get/num_tracks")
        print(f"  num_tracks in current set: {reply}")
        return True
    finally:
        osc.close()


if __name__ == "__main__":
    import sys
    try:
        ok = smoke_test()
        sys.exit(0 if ok else 1)
    except TimeoutError as e:
        print(f"FAILED: {e}")
        print("Check: AbletonOSC is enabled in Live → Preferences → Link / Tempo / MIDI → Control Surface")
        sys.exit(2)
