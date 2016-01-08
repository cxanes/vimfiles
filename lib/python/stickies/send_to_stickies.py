#!/usr/bin/python

# http://skype4py.sourceforge.net/doc/html/Skype4Py.api.windows-pysrc.html
# http://initiative.yo2.cn/archives/category/python/page/2

import ctypes

from .wintypes import *
from . import win32con

_FindWindowEx = ctypes.windll.user32.FindWindowExA
_SendMessage  = ctypes.windll.user32.SendMessageA

_MAX_CMDREF = (1<<(ctypes.sizeof(ctypes.c_int)*8)) - 1

def send_to_stickies(cmd, recv_window = None):
    global _cmdref

    hWnd = _FindWindowEx(None, None, None, "ZhornSoftwareStickiesMain")
    if hWnd == 0:
        return ''

    cmd8 = 'api ' + cmd + '\0' 
    copydata = COPYDATASTRUCT(send_to_stickies.cmdref, len(cmd8), ctypes.c_char_p(cmd8)) 

    recv_window.set_cmdref(send_to_stickies.cmdref)
    if send_to_stickies.cmdref == _MAX_CMDREF:
        send_to_stickies.cmdref = 1
    else:
        send_to_stickies.cmdref += 1

    # http://msdn.microsoft.com/en-us/library/ms644950%28v=vs.85%29.aspx
    # SendMessage function does not return until the window procedure has processed the message.
    if _SendMessage(hWnd, win32con.WM_COPYDATA, recv_window.get_hwnd(), 
                    ctypes.byref(copydata)) != 0:
        return ''

    return recv_window.get_reply()

send_to_stickies.cmdref = 1

if __name__ == "__main__":
    print send_to_stickies('do new sticky')
