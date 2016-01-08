#!/usr/bin/python

"""
Send command to Stickies < http://www.zhornsoftware.co.uk/stickies >
"""

import time

from .send_to_stickies import send_to_stickies
from .StickiesRecvWindow import StickiesRecvWindow

class Stickies:
    def __init__(self, event_callback = None):
        self._recv_window = None
        self._event_callback = event_callback


    def start(self):
        if self._recv_window is not None:
            return

        self._recv_window = StickiesRecvWindow(event_callback = self._event_callback)
        self._recv_window.start()

        while self._recv_window.get_hwnd() is None:
            time.sleep(0.1);


    def stop(self):
        if self._recv_window is None:
            return ''

        self._recv_window.destroy()
        self._recv_window.join()
        self._recv_window = None


    def send(self, cmd):
        if self._recv_window is None:
            return ''

        return send_to_stickies(cmd, self._recv_window)

