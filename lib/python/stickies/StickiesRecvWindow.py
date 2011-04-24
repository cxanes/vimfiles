#!/usr/bin/python

from ctypes import *
import threading

from .wintypes import *
from . import win32con

# http://ginstrom.com/scribbles/2008/02/26/python-gui-programming-platforms-for-windows/
# http://stackoverflow.com/questions/5249903/receiving-wm-copydata-in-python

_WNDPROC = WINFUNCTYPE(c_long, c_int, c_uint, c_int, c_int)

_NULL = c_int(win32con.NULL)
_user32 = windll.user32

def _ErrorIfZero(handle):
    if handle == 0:
        raise WinError()
    else:
        return handle

_CreateWindowEx = _user32.CreateWindowExA
_CreateWindowEx.argtypes = [c_int,
                           c_wchar_p,
                           c_wchar_p,
                           c_int,
                           c_int,
                           c_int,
                           c_int,
                           c_int,
                           c_int,
                           c_int,
                           c_int,
                           c_int]
_CreateWindowEx.restype = _ErrorIfZero

class _WNDCLASS(Structure):
    _fields_ = [('style', c_uint),
                ('lpfnWndProc', _WNDPROC),
                ('cbClsExtra', c_int),
                ('cbWndExtra', c_int),
                ('hInstance', c_int),
                ('hIcon', c_int),
                ('hCursor', c_int),
                ('hbrBackground', c_int),
                ('lpszMenuName', c_wchar_p),
                ('lpszClassName', c_wchar_p)]

    def __init__(self,
                 wndProc,
                 style=win32con.CS_HREDRAW | win32con.CS_VREDRAW,
                 clsExtra=0,
                 wndExtra=0,
                 menuName=None,
                 className=u"PythonWin32",
                 instance=None,
                 icon=None,
                 cursor=None,
                 background=None,
                 ):

        if not instance:
            instance = windll.kernel32.GetModuleHandleA(c_int(win32con.NULL))
        if not icon:
            icon = _user32.LoadIconA(c_int(win32con.NULL),
                                     c_int(win32con.IDI_APPLICATION))
        if not cursor:
            cursor = _user32.LoadCursorA(c_int(win32con.NULL),
                                         c_int(win32con.IDC_ARROW))
        if not background:
            background = windll.gdi32.GetStockObject(c_int(win32con.WHITE_BRUSH))

        self.lpfnWndProc=wndProc
        self.style=style
        self.cbClsExtra=clsExtra
        self.cbWndExtra=wndExtra
        self.hInstance=instance
        self.hIcon=icon
        self.hCursor=cursor
        self.hbrBackground=background
        self.lpszMenuName=menuName
        self.lpszClassName=className

class _RECT(Structure):
    _fields_ = [('left', c_long),
                ('top', c_long),
                ('right', c_long),
                ('bottom', c_long)]
    def __init__(self, left=0, top=0, right=0, bottom=0 ):
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom

class _POINT(Structure):
    _fields_ = [('x', c_long),
                ('y', c_long)]
    def __init__( self, x=0, y=0 ):
        self.x = x
        self.y = y

class _MSG(Structure):
    _fields_ = [('hwnd', c_int),
                ('message', c_uint),
                ('wParam', c_int),
                ('lParam', c_int),
                ('time', c_int),
                ('pt', _POINT)]

def _pump_messages():
    """Calls message loop"""
    msg = _MSG()
    pMsg = pointer(msg)

    while _user32.GetMessageA(pMsg, _NULL, 0, 0) > 0:
        _user32.TranslateMessage(pMsg)
        _user32.DispatchMessageA(pMsg)

    return msg.wParam

class _Window(object):
    """Wraps an HWND handle"""

    def __init__(self, hwnd = None):
        self.hwnd = hwnd

        self._event_handlers = {}

        # Register event handlers
        for key in dir(self):
            method = getattr(self, key)
            if hasattr(method, "win32message") and callable(method):
                self._event_handlers[method.win32message] = method

    def Create(self,
            exStyle=0 ,        #  DWORD dwExStyle
            className=u"WndClass",
            windowName=u"Window",
            style=win32con.WS_OVERLAPPEDWINDOW,
            x=win32con.CW_USEDEFAULT,
            y=win32con.CW_USEDEFAULT,
            width=win32con.CW_USEDEFAULT,
            height=win32con.CW_USEDEFAULT,
            parent=_NULL,
            menu=_NULL,
            instance=_NULL,
            lparam=_NULL,
            ):

        self.hwnd = _CreateWindowEx(exStyle,
                              className,
                              windowName,
                              style,
                              x,
                              y,
                              width,
                              height,
                              parent,
                              menu,
                              instance,
                              lparam)
        return self.hwnd

    def WndProc(self, hwnd, message, wParam, lParam):

        event_handler = self._event_handlers.get(message, None)
        if event_handler:
            return event_handler(message, wParam, lParam)
        return _user32.DefWindowProcA(c_int(hwnd),
                                      c_int(message),
                                      c_int(wParam),
                                      c_int(lParam))

## Lifted shamelessly from WCK (effbot)'s wckTkinter.bind
def _EventHandler(message):
    """Decorator for event handlers"""
    def decorator(func):
        func.win32message = message
        return func
    return decorator

class _StickiesRecvWindow(_Window):
    """The application window"""

    def __init__(self, hwnd = None, event_callback = None):
        _Window.__init__(self, hwnd)
        self._reply = None
        self._event_callback = event_callback
        self._cmdref = None

    def set_event_callback(self, event_callback):
        self._event_callback = event_callback

    def get_reply(self):
        return self._reply

    def set_cmdref(self, cmdref):
        self._cmdref = cmdref

    @_EventHandler(win32con.WM_DESTROY)
    def OnDestroy(self, message, wParam, lParam):
        """Quit app when window is destroyed"""
        _user32.PostQuitMessage(0)
        return 0

    @_EventHandler(win32con.WM_COPYDATA)
    def OnCopyData(self, message, wParam, lParam):
        pCDS = cast(lParam, PCOPYDATASTRUCT)
        self._reply = string_at(pCDS.contents.lpData, pCDS.contents.cbData)
        if pCDS.contents.dwData == 0 and self._event_callback is not None:
            self._event_callback(self._reply)
        return 1

class StickiesRecvWindow(threading.Thread):
    def __init__(self, event_callback = None):
        threading.Thread.__init__(self)
        self._window = None 
        self._event_callback = event_callback

    def get_hwnd(self):
        return None if self._window is None else self._window.hwnd

    def destroy(self):
        windll.user32.SendMessageA(self._window.hwnd, win32con.WM_DESTROY, None, None)

    def set_cmdref(self, cmdref):
        return self._window.set_cmdref(cmdref)

    def set_event_callback(self, event_callback):
        self._event_callback = event_callback
        self._window.set_event_callback(event_callback)

    def get_reply(self):
        return self._window.get_reply()

    def run(self):
        """Create window and start message loop"""

        # two-stage creation for Win32 windows
        self._window = _StickiesRecvWindow(event_callback = self._event_callback)

        # register window class...
        wndclass = _WNDCLASS(_WNDPROC(self._window.WndProc))
        wndclass.lpszClassName = u"StickiesRecvWindow"

        if not _user32.RegisterClassA(byref(wndclass)):
            raise WinError()

        self._window.Create( className=wndclass.lpszClassName,
                    instance=wndclass.hInstance,
                    windowName=u"StickiesRecvWindow")

        _pump_messages()
