#!/usr/bin/python

# Modified from 
#  http://macromates.com/svn/Bundles/trunk/Bundles/Latex.tmbundle/Commands/Show%20Outline.tmCommand

import re

try:
    import vim
    in_vim = True
except ImportError:
    in_vim = False

_REGEX = re.compile(r'\\(part|chapter|section|subsection|subsubsection|paragraph|subparagraph)\*?(?:%.*\n[ \t]*)?(?:(?=(\[(.*?)\]))\2|\{([^{}]*(?:\{[^}]*\}[^}]*?)*)\})');
_INCLUDE_REGEX = re.compile(r'\\(?:input|include)(?:%.*\n[ \t]*)?(?=(\{(.*?)\}))\1');
_NON_COMMENT_REGEX = re.compile(r'^((?:[^%]|\\%)*)(?=%|$)');

def _adjust_end(path, filename):
    path = re.sub(r'[^\\/]*$', filename, path)
    if not re.search(r'\.tex$', path):
        path += '.tex'
    return path

def outline_points(filename):
    points = []

    lines = []
    name = ''

    if isinstance(filename, file):
        lines = filename.readlines()
        if re.search('^<', file.name):
            import os
            import os.path
            filename = os.path.join(os.getcwd(), 'dummy')
        else:
            filename = file.name
            name = filename
    elif not in_vim:
        try:
            f = open(filename)
            try:
                lines = f.readlines()
            finally:
                f.close()
        except IOError:
            return points

        name = filename
    elif isinstance(filename, type(vim.current.buffer)):
        lines = filename[:]
        filename = filename.name
        name = filename
    else:
        for b in vim.buffers:
            if b.name == filename:
                lines = b[:]
                filename = b.name
                name = filename
                break
        else:
            try:
                f = open(filename)
                try:
                    lines = f.readlines()
                finally:
                    f.close()

            except IOError:
                return points

            name = filename

    i = 1
    for line in lines:
        m = _NON_COMMENT_REGEX.search(line)
        if m:
            line = m.group(1)
        else:
            line = ''
        m = _REGEX.search(line)
        if m:
            item = [name, i, m.group(1), m.group(3) or m.group(4)]
            if item[3].strip() != '':
                points.append(item)
        m = _INCLUDE_REGEX.search(line)
        if m:
            if m.group(2).strip() != '':
                points += outline_points(_adjust_end(filename, m.group(2)))

        i += 1

    return points

if __name__ == '__main__':
    import sys
    import os.path
    if len(sys.argv) > 1:
        points = outline_points(os.path.abspath(sys.argv[1]))
        for point in points:
            print "%s\t%d\t%s\t%s" % tuple(point)

