#!/usr/bin/python

import os
import re
import ctypes;
import os.path
import platform

import finder

if platform.architecture()[0] == '64bit':
    libfzmatch_default = 'libfzmatch64.so'
else:
    libfzmatch_default = 'libfzmatch.so'
fzmatch_path = { 'Windows': 'fzmatch.dll' }
fzmatch = ctypes.CDLL(os.path.join(os.path.dirname(os.path.realpath( __file__ )),
                         fzmatch_path.get(platform.system(), libfzmatch_default)))
fzmatch.get_score.restype = ctypes.c_double

class _Option(ctypes.Structure):
    _fields_ = [("always_show_dot_files", ctypes.c_int),
                ("never_show_dot_files", ctypes.c_int)]

class FzFinder(finder.Finder):
    def __init__(self, items = None, option = None):
        super(FzFinder, self).__init__(items, option)

    def set_option(self, option):
        super(FzFinder, self).set_option(option)
        self.coption = _Option(self.option['always_show_dot_files'],
                               self.option['never_show_dot_files'])

    def search(self, abbrev):
        if len(abbrev) == 0:
            return self.get_items()

        pos = (ctypes.c_long * len(abbrev))()

        for item in self.items:
            item.score = fzmatch.get_score(item.name, abbrev, ctypes.byref(self.coption), ctypes.byref(pos))
            if item.score == 0:
                item.pos = None
            else:
                item.pos = list(pos)

        matched_items = [item for item in self.items if item.score != 0]
        matched_items.sort(key = lambda item: item.score, reverse = True)

        return matched_items

if __name__ == '__main__':
    def _highlight(name, pos):
        if not pos:
            return name
        return "\0".join(name[start : end] for start, end in zip([0] + pos, pos + [len(name)]))

    os.chdir('.')

    file_list = []

    for root, dirs, files in os.walk('.'):
        file_list.extend(os.path.join(root, f) for f in files)

    file_list = [re.sub(r'\\', '/', re.sub(r'^\.\\', '', f)) for f in file_list]

    finder = FzFinder(file_list)

    for item in finder.search("foobar"):
        print _highlight(item.name, item.pos), item.name, item.pos, item.score

