#!/usr/bin/python

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

def print_func(s):
    print s

class Node(object):
    __slots__ = [ 'exact', 'wildcard', 'recursive', 'terminal' ]

    _MUST_BE_DIR = {}

    def __init__(self, terminal = None):
        self.exact     = None
        self.wildcard  = None
        self.recursive = None
        self.terminal  = terminal

    def __setitem__(self, key, value):
        self.__setattr__(key, value)

    def __getitem__(self, key):
        return self.__getattribute__(key)

    def __repr__(self):
        return "{'exact': %s, 'wildcard': %s, 'recursive': %s, 'terminal': %s}" % (
                str(self.exact), str(self.wildcard), str(self.recursive),
                ('MUST_BE_DIR' if self.must_be_dir() else str(self.terminal)))

    def must_be_dir(self):
        return self.terminal is Node._MUST_BE_DIR

    def is_terminal(self):
        return self.terminal is not None

    def has_child(self):
        return self.exact     is not None \
            or self.wildcard  is not None \
            or self.recursive is not None

    def copy(self):
        return Node().update(self)

    def update(self, node):
        if node is None:
            return self

        for t in ('wildcard', 'exact', 'recursive'):
            if node[t] is None:
                continue

            if self[t] is None:
                self[t] = Node() if t == 'recursive' else {}

            self[t].update(node[t])

        if node.is_terminal():
            if not self.is_terminal() or (node.must_be_dir() and not self.must_be_dir()):
                self.terminal = node.terminal

        return self

    @staticmethod
    def get_escaped_str(string):
        return re.sub(r'\\(.)', r'\1', string)

    @staticmethod
    def has_wildcard(string):
        return re.search(r'\A(?:\\.|[^\\*[?])*\Z', string) == None

    @staticmethod
    def get_name_type(name):
        if name == '**'           : return 'recursive'
        if Node.has_wildcard(name): return 'wildcard'
        return 'exact'

    @staticmethod
    def add(root, parts, must_be_dir):
        while parts:
            name_type = Node.get_name_type(parts[0])

            if name_type == 'recursive':
                return Node._add_recursive(root, parts, must_be_dir)

            part = Node.get_escaped_str(parts.pop(0))

            if root[name_type] is None:
                root[name_type] = { part: Node() }
            elif part not in root[name_type]:
                root[name_type][part] = Node()

            root = root[name_type][part]

        root.terminal = Node._MUST_BE_DIR if must_be_dir else True

    @staticmethod
    def _add_recursive(root, parts, must_be_dir):
        if len(parts) < 2:
            return

        parts.pop(0)

        if root['recursive'] is None:
            root['recursive'] = Node()

        return Node.add(root['recursive'], parts, must_be_dir)

class Pattern(object):
    @staticmethod
    def _create():
        return { 'dir': None, 'wildcard' : set(), 'exact' : set() }

    def __init__(self):
        self.include = Pattern._create()
        self.exclude = Pattern._create()

    def __repr__(self):
        return "{'include': %s, 'exclude': %s}" % (
                str(self.include), str(self.exclude))

    def add(self, pattern):
        select = self.include

        if pattern == '.' or pattern == '/':
            return
        elif pattern == '..' or pattern.startswith('../'):
            print >> sys.stderr, "warning: spec is outside of root dir, ignore"
            return

        if pattern.startswith('!'):
            select = self.exclude
            pattern = re.sub(r'\A!\s*', '', pattern)

        if '/' in pattern:
            must_be_dir = pattern.endswith('/') 
            pattern = posixpath.normpath(pattern)

            if pattern.startswith('/'):
                pattern = pattern[1:]

            parts = pattern.split('/')

            if select['dir'] is None:
                select['dir'] = Node()

            Node.add(select['dir'], parts, must_be_dir)
        else:
            name_type = Node.get_name_type(pattern)

            if name_type == 'recursive':
                return

            select[name_type].add(Node.get_escaped_str(pattern))

    def _match_name(self, name, include):
        select = self.include if include else self.exclude

        if not select['exact'] and not select['wildcard']:
            return bool(include)

        if name in select['exact']:
            return True

        for pat in select['wildcard']:
            if fnmatch2.fnmatch(name, pat):
                # the name which matches exactly has higher priority
                select = self.exclude if include else self.include
                if select['exact'] and name in select['exact']:
                    return False

                return True

        return False

    def walk(self, root, callback = print_func, onerror = None, level = -1):
        matched = self.include['dir'] is None
        self._walk(root, self.include['dir'], self.exclude['dir'], matched, callback, onerror, level)

    @staticmethod
    def _match(name, pattern, is_dir):
        if pattern is None:
            return None

        new_pattern = None

        if pattern['recursive'] is not None:
            new_pattern = Node()
            new_pattern['recursive'] = pattern['recursive'].copy()
            new_pattern.update(Pattern._match(name, new_pattern['recursive'], is_dir))

        if pattern['wildcard'] is not None:
            for pat in pattern['wildcard']:
                if not fnmatch2.fnmatch(name, pat):
                    continue

                next_pattern = pattern['wildcard'][pat]

                if next_pattern.is_terminal():
                    if not is_dir and next_pattern.must_be_dir():
                        continue

                if new_pattern is None:
                    new_pattern = next_pattern.copy()
                else:
                    new_pattern.update(next_pattern)

        if pattern['exact'] is not None:
            if name in pattern['exact']:
                next_pattern = pattern['exact'][name]

                if next_pattern.is_terminal():
                    if not is_dir and next_pattern.must_be_dir():
                        return new_pattern

                if new_pattern is None:
                    new_pattern = next_pattern.copy()
                else:
                    new_pattern.update(next_pattern)

        return new_pattern

    def _walk(self, root, include, exclude, matched, callback, onerror, level):
        if level == 0:
            return
        if level > 0:
            level = level - 1

        if root == "":
            root = '.'

        try:
            names = os.listdir(root)
        except os.error as err:
            if onerror is not None:
                onerror(err)
            return

        for name in names:
            path = name if root == '.' else posixpath.join(root, name)

            is_file, is_dir = posixpath.isfile(path), posixpath.isdir(path)

            if not (is_file or is_dir):
                continue

            if self._match_name(name, include = False):
                continue

            if is_file:
                if not self._match_name(name, include = True):
                    continue

                if not matched or posixpath.islink(path):
                    if include is None:
                        continue
                    new_include = Pattern._match(name, include, is_dir)
                    if new_include is None or (not new_include.is_terminal() or new_include.must_be_dir()):
                        continue
                elif matched and exclude is not None:
                    new_exclude = Pattern._match(name, exclude, is_dir)
                    if new_exclude is not None and (new_exclude.is_terminal() and not new_exclude.must_be_dir()):
                        continue

                callback(path)
                continue

            new_exclude, new_include, new_matched = None, None, matched

            if include is not None:
                if include.has_child():
                    new_include = Pattern._match(name, include, is_dir)
                    if new_include is None:
                        continue
            elif posixpath.islink(path):
                continue

            if exclude is not None and exclude.has_child():
                new_exclude = Pattern._match(name, exclude, is_dir)

            if new_include is not None and new_include.is_terminal():
                new_matched = True

            if new_exclude is not None and new_exclude.is_terminal():
                if new_include is not None and new_include.has_child():
                    new_matched = False
                else:
                    continue

            if not new_matched and (new_include is None or not new_include.has_child()):
                continue

            self._walk(path, new_include, new_exclude, new_matched, callback, onerror, level)

    def match_path(self, path):
        include = self.include['dir']
        exclude = self.exclude['dir']
        matched = include is None

        if path.startswith('/'):
            path = path[1:]
        elif path.startswith('./'):
            path = path[2:]

        parts = path.split('/')

        while parts:
            name = parts.pop(0)

            if self._match_name(name, include = False):
                return False

            if len(parts) == 0:
                if not self._match_name(name, include = True):
                    return False

                if not matched:
                    if include is None:
                        return False
                    include = Pattern._match(name, include, False)
                    if include is None or (not include.is_terminal() or include.must_be_dir()):
                        return False
                elif matched and exclude is not None:
                    exclude = Pattern._match(name, exclude, False)
                    if exclude is not None and (exclude.is_terminal() and not exclude.must_be_dir()):
                        return False

                return True

            if include is not None:
                if include.has_child():
                    include = Pattern._match(name, include, True)
                    if include is None:
                        return False

            if exclude is not None and exclude.has_child():
                exclude = Pattern._match(name, exclude, True)

            if include is not None and include.is_terminal():
                matched = True

            if exclude is not None and exclude.is_terminal():
                if include is not None and include.has_child():
                    matched = False
                else:
                    return False

            if not matched and (include is None or not include.has_child()):
                return False

        return True

def _strip(line):
    return re.sub(r'^\s+|\s*\r?\n', '', line)

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
        pattern = _get_pattern(pattern_fname)
        self.add_pattern(pattern, preserve)
        if not preserve and pattern is not None:
            self._dirty = self._dirty & ~_dirty_flag['pattern']
        return self

    def add_pattern(self, pattern, preserve = True):
        if not preserve:
            self._dirty = self._dirty | _dirty_flag['pattern'] | _dirty_flag['update'] | _dirty_flag['filelist']
            self._raw_pattern = []
            self._pattern = Pattern()

            if not self._option.getint('DEFAULT', 'search_dot_files'):
                self._pattern.add('!.*')

            for pat in _parse_default_pattern(self._option.get('DEFAULT', 'default_pattern')):
                self._pattern.add(pat)

        if pattern is None:
            self._dirty = self._dirty | _dirty_flag['pattern'] | _dirty_flag['update'] | _dirty_flag['filelist']
            return self

        if pattern in self._raw_pattern:
            return self

        if isinstance(pattern, str):
            self._raw_pattern.append(pattern)
            self._pattern.add(pattern)
        else:
            for item in pattern:
                self._raw_pattern.append(item)
                self._pattern.add(item)

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

        return self._pattern.match_path(path)

    def walk(self, root, callback = print_func, onerror = None):
        if root and platform.system() == 'Windows':
            root = re.sub(r'\\', '/', root)

        self._pattern.walk(root, callback, onerror, self._option.getint('DEFAULT', 'max_depth'))

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
