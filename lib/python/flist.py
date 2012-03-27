#!/usr/bin/python

from __future__ import print_function

import re
import os
import os.path
import posixpath
import sys
import stat
import platform
import gzip
import pickle
import ConfigParser
import fnmatch2
# import fnmatch as fnmatch2

_MUST_BE_DIR = {}


def _strip(line):
    return re.sub(r'^\s+|\s*\r?\n', '', line)

def _get_escaped_str(string):
    return re.sub(r'\\(.)', r'\1', string)

def _has_wildcard(string):
    return re.search(r'\A(?:\\.|[^\\*[?])*\Z', string) == None

def _create_dir_node():
    return { 'exact': {}, 'wildcard': {}, 'recursive': None }

def _get_name_type(name):
    if name == '**'       : return 'recursive'
    if _has_wildcard(name): return 'wildcard'
    return 'exact'

def _add_recursive_dir_node(root, parts, must_be_dir, callback):
    if not parts:
        return

    parts.pop(0)

    if root['recursive'] is None:
        new_node = _create_dir_node()
        root['recursive'] = new_node

    callback(root['recursive'], parts, must_be_dir)

def _add_dir_node_directly(root, parts, must_be_dir):
    if root is None or not parts:
        return

    part = parts[0]
    name_type = _get_name_type(part)

    if name_type == 'recursive':
        _add_recursive_dir_node(root, parts, must_be_dir, _add_dir_node_directly)
        return

    part = parts.pop(0)

    if parts:
        new_node = _create_dir_node()
        root[name_type][_get_escaped_str(part)] = new_node
        _add_dir_node_directly(new_node, parts, must_be_dir)
    else:
        root[name_type][_get_escaped_str(part)] = _MUST_BE_DIR if must_be_dir else None

def _add_dir_node_internal(root, parts, must_be_dir):
    if root is None or not parts:
        return

    part = parts[0]
    name_type = _get_name_type(part)

    if name_type == 'recursive':
        _add_recursive_dir_node(root, parts, must_be_dir, _add_dir_node_internal)
        return

    part = _get_escaped_str(part)

    if part not in root[name_type]:
        _add_dir_node_directly(root, parts, must_be_dir)
        return

    root = root[name_type]

    if not parts:
        root[part] = _MUST_BE_DIR if must_be_dir else None
    else:
        parts.pop(0)
        _add_dir_node_internal(root[part], parts, must_be_dir)

def _add_dir_node(root, parts, must_be_dir):
    if not parts:
        return

    part = parts[0]
    name_type = _get_name_type(part)

    if name_type == 'recursive':
        _add_recursive_dir_node(root, parts, must_be_dir, _add_dir_node)
        return

    if _get_escaped_str(part) not in root[name_type]:
        _add_dir_node_directly(root, parts, must_be_dir)
    else:
        _add_dir_node_internal(root, parts, must_be_dir)

def _add_pattern(_pattern, pattern):
    pat = _pattern['include']

    if pattern.startswith('!'):
        pat = _pattern['exclude']
        pattern = re.sub(r'\A!\s*', '', pattern)

    if '/' in pattern:
        must_be_dir = pattern.endswith('/') 
        pattern = posixpath.normpath(pattern)

        if pattern == '.' or pattern == '/':
            return
        elif pattern == '..' or pattern.startswith('../'):
            print("warning: spec is outside of root dir, ignore", file = sys.stderr)
            return

        if pattern.startswith('/'):
            pattern = pattern[1:]

        parts = pattern.split('/')

        if pat['dir'] is None:
            pat['dir'] = _create_dir_node()

        _add_dir_node(pat['dir'], parts, must_be_dir)
    else:
        if pattern == '**':
            return

        pat[_get_name_type(pattern)].add(_get_escaped_str(pattern))

def _file_match(pattern, name, pattern_type):
    if not pattern[pattern_type]['exact'] and not pattern[pattern_type]['wildcard']:
        return pattern_type == 'include'

    if name in pattern[pattern_type]['exact']:
        return True

    for p in pattern[pattern_type]['wildcard']:
        if fnmatch2.fnmatch(name, p):
            return True

    return False

def _match(name, pattern, is_dir):
    new_pattern = None
    should_copy = True
    matched = False

    if pattern['recursive'] is not None:
        new_pattern = _create_dir_node()
        should_copy = False

        new_pattern['recursive'] = pattern['recursive'].copy()
        matched, next_pattern = _match(name, new_pattern['recursive'], is_dir)
        if matched and next_pattern:
            new_pattern['wildcard'].update(next_pattern['wildcard'])
            new_pattern['exact'].update(next_pattern['exact'])
            if next_pattern['recursive'] is not None:
                new_pattern['recursive'].update(next_pattern['recursive'])

        matched = True

    for p in pattern['wildcard']:
        if not fnmatch2.fnmatch(name, p):
            continue

        matched = True

        next_pattern = pattern['wildcard'][p]

        if not next_pattern:
            if is_dir or next_pattern is not _MUST_BE_DIR:
                return matched, new_pattern
            else:
                continue

        if new_pattern is None:
            new_pattern = next_pattern
        elif should_copy == True:
            new_pattern2 = _create_dir_node()
            new_pattern2['wildcard'].update(next_pattern['wildcard'])
            new_pattern2['exact'].update(next_pattern['exact'])
            if next_pattern['recursive'] is not None:
                if new_pattern2['recursive'] is None:
                    new_pattern2['recursive'] = _create_dir_node()
                new_pattern2['recursive'].update(next_pattern['recursive'])
            new_pattern = new_pattern2
            should_copy = False
        else:
            new_pattern['wildcard'].update(next_pattern['wildcard'])
            new_pattern['exact'].update(next_pattern['exact'])
            if next_pattern['recursive'] is not None:
                if new_pattern['recursive'] is None:
                    new_pattern['recursive'] = _create_dir_node()
                new_pattern['recursive'].update(next_pattern['recursive'])

    if name in pattern['exact']:
        matched = True

        next_pattern = pattern['exact'][name]

        if not next_pattern:
            if is_dir or next_pattern is not _MUST_BE_DIR:
                return matched, new_pattern
        else:
            if new_pattern is None:
                new_pattern = next_pattern
            elif should_copy == True:
                new_pattern2 = _create_dir_node()
                new_pattern2['wildcard'].update(next_pattern['wildcard'])
                new_pattern2['exact'].update(next_pattern['exact'])
                if next_pattern['recursive'] is not None:
                    new_pattern2['recursive'].update(next_pattern['recursive'])
                new_pattern = new_pattern2
                should_copy = False
            else:
                new_pattern['wildcard'].update(next_pattern['wildcard'])
                new_pattern['exact'].update(next_pattern['exact'])
                if next_pattern['recursive'] is not None:
                    if new_pattern['recursive'] is None:
                        new_pattern['recursive'] = _create_dir_node()
                    new_pattern['recursive'].update(next_pattern['recursive'])

    return matched, new_pattern

def _walk(root, include, exclude, pattern, callback = print, onerror = None, level = -1):
    if root == "":
        root = '.'

    try:
        names = os.listdir(root)
    except os.error, err:
        if onerror is not None:
            onerror(err)
        return

    if level > 0:
        level = level - 1

    for name in names:
        path = name if root == '.' else posixpath.join(root, name)

        is_file, is_dir = posixpath.isfile(path), posixpath.isdir(path)

        if not is_file and not is_dir:
            continue

        if _file_match(pattern, name, 'exclude') \
                or (is_file and not _file_match(pattern, name, 'include')):
            continue

        new_exclude, new_include = None, None

        if exclude is not None:
            should_exclude, new_exclude = _match(name, exclude, is_dir)
            if should_exclude:
                continue

        if include is not None:
            should_include, new_include = _match(name, include, is_dir)
            if not should_include:
                continue
        elif posixpath.islink(path):
            continue

        if is_dir:
            if level != 0:
                _walk(path, new_include, new_exclude, pattern, callback, onerror, level)
        else:
            callback(path)


def _path_match(path, include, exclude, pattern):
    if path.startswith('/'):
        path = path[1:]
    elif path.startswith('./'):
        path = path[2:]

    parts = path.split('/')

    while parts:
        name = parts.pop(0)

        is_dir = len(parts) != 0

        if len(parts) == 0 and (_file_match(pattern, name, 'exclude') or not _file_match(pattern, name, 'include')):
            return False

        if exclude is not None:
            should_exclude, exclude = _match(name, exclude, is_dir)
            if should_exclude:
                return False

        if include is not None:
            should_include, include = _match(name, include, is_dir)
            if not should_include:
                return False

    return True

def _get_pattern(pattern_fname):
    if not pattern_fname:
        return None

    pattern = []

    try:
        f = open(pattern_fname, "rb")

        can_skip = lambda line: re.match(r"\s*#|\s*$", line) != None

        pattern = [ _strip(line) for line in f.readlines() if not can_skip(line) ]
    except IOError:
        return None
    else:
        f.close()

    pattern.sort()
    return pattern

def _create_pattern():
    return { 'dir': None, 'wildcard' : set(), 'exact' : set() }

_default_option = {
    'max_depth':        '-1',
    'manual_update':     '0',
    'search_dot_files':  '0',
    'default_pattern':   '',
}

def _parse_default_pattern(pattern):
    pattern = _strip(pattern)
    if len(pattern) == 0:
        return []
    return [ re.sub('^\s+|\s+$', '', pat) for pat in pattern.split(':') ]

def get_fname(name, fname_type):
    suffix = { 'option': '.ini', 'pattern' : '.pat' }

    if not name:
        return None

    if fname_type == 'filelist':
        return name

    if fname_type in suffix:
        name = re.sub('\.out$', '', name)
        return name + suffix[fname_type]

    return None

_dirty_flag = { 'option':   (1<<0),
                'pattern':  (1<<1),
                'filelist': (1<<2),
                'update'  : (1<<3),
              }

class Flist:
    def __init__(self, name = None, option = None):
        self._name = name
        self._default_option = _default_option.copy()
        if option:
            self._default_option.update(option)
        self._root = os.getcwd()
        self._dirty = 0
        self.load()

    def _init_config(self):
        self._dirty = 0
        self._option = ConfigParser.ConfigParser(self._default_option)
        self._file_list = []

    def get_fname(self, fname_type):
        return get_fname(self._name, fname_type)

    def get_pattern(self):
        return self._raw_pattern[:]

    def load(self):
        self._init_config()
        self.import_pattern(self.get_fname('pattern'))
        self._dirty = 0

        if not self._name:
            self._dirty = self._dirty | _dirty_flag['update']
            return

        try:
            f = open(self.get_fname('filelist'), "rb")
        except IOError as e:
            self._dirty = self._dirty | _dirty_flag['filelist'] | _dirty_flag['update']
        else:
            self._file_list = [ _strip(line) for line in f.readlines() ]
            f.close()

        try:
            f = open(self.get_fname('option'), "rb")
        except IOError:
            self._dirty = self._dirty | _dirty_flag['option']
        else:
            self._option.readfp(f)
            f.close()

        if os.path.exists(self.get_fname('filelist')):
            mtime = os.path.getmtime(self.get_fname('filelist'))
            try:
                if os.path.getmtime(self.get_fname('option')) > mtime:
                    self._dirty = self._dirty | _dirty_flag['filelist'] | _dirty_flag['update']
            except os.error:
                pass

            try:
                if os.path.getmtime(self.get_fname('pattern')) > mtime:
                    self._dirty = self._dirty | _dirty_flag['filelist'] | _dirty_flag['update']
            except os.error:
                pass

    def dump(self, name_type = None):
        if not self._name: return

        dump_types = [ 'pattern', 'filelist', 'option' ]
        if name_type:
            if name_type not in dump_types:
                return
            dump_types = [ name_type ]

        if 'filelist' in dump_types:
            self.update()
            if self._dirty & _dirty_flag['filelist']:
                if not self._option.getint('DEFAULT', 'manual_update'):
                    with open(self.get_fname('filelist'), "wb") as f:
                        f.writelines([line + '\n' for line in self._file_list])
                self._dirty = self._dirty & ~_dirty_flag['filelist']

        if 'pattern' in dump_types and self._dirty & _dirty_flag['pattern']:
            with open(self.get_fname('pattern'), "wb") as f:
                f.writelines([line + '\n' for line in self._raw_pattern])
            self._dirty = self._dirty & ~_dirty_flag['pattern']

        if 'option' in dump_types and self._dirty & _dirty_flag['option']:
            with open(self.get_fname('option'), "wb") as f:
                self._option.write(f)
            self._dirty = self._dirty & ~_dirty_flag['option']

    def import_pattern(self, pattern_fname = None, preserve = False):
        self.add_pattern(_get_pattern(pattern_fname), preserve)
        return self

    def add_pattern(self, pattern, preserve = True):
        if not preserve:
            self._dirty = self._dirty | _dirty_flag['pattern'] | _dirty_flag['update'] | _dirty_flag['filelist']
            self._raw_pattern = []
            self._pattern = { 'include': _create_pattern(), 'exclude': _create_pattern() }

            if not self._option.getint('DEFAULT', 'search_dot_files'):
                _add_pattern(self._pattern, '!.*')

            for pat in _parse_default_pattern(self._option.get('DEFAULT', 'default_pattern')):
                _add_pattern(self._pattern, pat)

        if pattern is None:
            self._dirty = self._dirty | _dirty_flag['pattern'] | _dirty_flag['update'] | _dirty_flag['filelist']
            return self

        if pattern in self._raw_pattern:
            return self

        if isinstance(pattern, str):
            self._raw_pattern.append(pattern)
            _add_pattern(self._pattern, pattern)
        else:
            for item in pattern:
                self._raw_pattern.append(item)
                _add_pattern(self._pattern, item)

        self._dirty = self._dirty | _dirty_flag['pattern'] | _dirty_flag['update'] | _dirty_flag['filelist']
        return self

    def match(self, path):
        if not self._option.getint('DEFAULT', 'search_dot_files') and \
                re.search(r'[\\/]\.|^\.', path) != None:
            return False

        if not self._raw_pattern:
            return True

        if path and platform.system() == 'Windows':
            path = re.sub(r'\\', '/', path)

        return _path_match(path, self._pattern['include']['dir'], self._pattern['exclude']['dir'], self._pattern)

    def walk(self, root, callback = print, onerror = None):
        if root and platform.system() == 'Windows':
            root = re.sub(r'\\', '/', root)

        _walk(root, self._pattern['include']['dir'], self._pattern['exclude']['dir'],
              self._pattern, callback, onerror,
              self._option.getint('DEFAULT', 'max_depth'))

    def get(self):
        self.update()
        return self._file_list

    def update(self, force = False):
        if (self._dirty & _dirty_flag['update'] == 0) and not force:
            return False

        if not self._option.getint('DEFAULT', 'manual_update'):
            self._file_list = []
            self.walk('', lambda item: self._file_list.append(item))

        self._dirty = self._dirty & ~_dirty_flag['update']
        return True

    # def pprint_pattern(self):
    #     import pprint
    #     pprint.pprint(self._pattern)


if __name__ == '__main__':
    flist = Flist()
    for f in flist.get():
        print(f)
