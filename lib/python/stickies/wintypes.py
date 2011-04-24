#!/usr/bin/python

import ctypes

class COPYDATASTRUCT(ctypes.Structure):
    _fields_ = [
        ("dwData", ctypes.c_int32),
        ("cbData", ctypes.c_int32),
        ("lpData", ctypes.c_char_p),
    ]

PCOPYDATASTRUCT = ctypes.POINTER(COPYDATASTRUCT)
