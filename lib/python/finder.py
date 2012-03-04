#!/usr/bin/python

import re

class Item:
    __slots__  = ['name', 'score', 'pos', 'private']

    def __init__(self, name, private = None, score = 0.0, pos = None):
        self.name = name
        self.score = score
        self.pos = pos
        self.private = name

class Finder(object):
    def __init__(self, items = None, option = None):
        if items is None:
            items = []
        self.set_items(items)
        self.set_option(option)

    def set_option(self, option):
        self.option = { 'always_show_dot_files': 0,
                        'never_show_dot_files': 0  }
        if option is not None:
            self.option.update(dict(option))

    def set_items(self, items):
        self.items = [item if isinstance(item, Item) else Item(item) for item in items]

    def get_items(self):
        for item in self.items:
            item.pos = None

        if not self.option['always_show_dot_files']:
            return [item for item in self.items if not re.search(r'^\.|/\.', item.name)]
        else:
            return self.items[:]

    def search(self, pattern):
        if len(pattern) == 0:
            return self.get_items()

        try:
            pattern = re.compile(pattern)
        except re.error, err:
            return []

        for item in self.items:
            match = pattern.search(item.name)
            if match is None:
                item.score = 0
                item.pos = None if item.score == 0 else list(pos)
            else:
                item.score = 1
                item.pos = range(match.start(), match.end())

        return [item for item in self.items if item.score != 0]

