#!/usr/bin/python

"""
This script opens sdcv <http://sdcv.sourceforge.net/> in the background,
and queries are sent to it to reduce the startup time.
"""

import os
import re
import time
import sys
from stat import *

def executable(prog):
    pathlist = os.environ['PATH'].split(os.pathsep)
    
    for ext in ['', '.exe']:
        for dir in pathlist:
            filename = os.path.join(dir, prog + ext)
            try:
                st = os.stat(filename)
            except os.error:
                continue
            if S_ISREG(st[ST_MODE]):
                mode = S_IMODE(st[ST_MODE])
                if mode & 0111:
                    return 1

    return 0

try:
    import vim
except ImportError:
    print "This script can only be used in Vim."

try:
    if sys.platform == 'win32':
        import win32file
        import win32pipe
        import msvcrt
    else:
        import popen2
        import select
        import fcntl
    vim.command('let g:sdcv_loaded = 1')
except ImportError:
    if sys.platform == 'win32':
        print "Cannot find module win32file, win32pipe, or msvcrt"
    else:
        print "Cannot find module select, fcntl"
    vim.command('let g:sdcv_loaded = 0')

if executable('pty') == 0:
    print "Cannot find program 'pty'"
    vim.command('let g:sdcv_loaded = 0')

if executable('sdcv') == 0:
    print "Cannot find program 'sdcv'"
    vim.command('let g:sdcv_loaded = 0')

class Sdcv:
    def __init__(self, dict_list = ''):
        self.eof_key = ''

        if dict_list != '':
            dict_arg = ''.join(map(lambda d: ' -u %s ' % d, dict_list.split(',')))
        else:
            dict_arg = ''

        # 'pty' is modified from the sample program in "Advanced Programming in the UNIX Environment"
        # (ch19.5), which executes given program in a session of its own, and connects to a psuedo terminal.
        # The standard I/O library then sets stdin and stdout to line-buffered.
        if sys.platform == 'win32':
            self.ind, self.outd = win32pipe.popen2('pty -e -- sdcv --utf8-output ' + dict_arg, 'b')
        else:
            self.ind, self.outd = os.popen2('pty -e -- sdcv --utf8-output ' + dict_arg, 'b')

        # Give time for program to start up
        time.sleep(2)
        self.pipe_read(self.outd)

    def strip_prompt(self, data):
        return re.compile(r'\n?(?:Enter word or phrase: \n?)+\Z', re.MULTILINE).sub('', data)

    def num_of_items(self, data):
        m = re.match(r'Found (\d+) items,', data)
        if m != None:
            return int(m.group(1))
        return -1

    def input(self, prompt, max_num):
        if max_num <= 0:
            return '-1'

        err_prompt = """Invalid choice.
It must be from 0 to %d or -1.
Your choice[-1 to abort]: """ % (max_num - 1)

        while 1:
            vim.command('call inputsave()')
            vim.command("let choice = input('" + re.sub("'", "''", prompt) + "')")
            vim.command('call inputrestore()')

            try:
                choice = int(vim.eval('choice'))
            except ValueError:
                choice = max_num

            if -2 < choice and choice < max_num:
                return str(choice)

            prompt = err_prompt
    
    def get_choice(self, lines):
        num = self.num_of_items(lines)
        choice = self.input(lines, num)

        self.pipe_write(self.ind, choice + '\n')
        lines = self.pipe_read(self.outd)

        return lines

    def setlines(self, lines):
        vim.command('silent %d _')
        vim.current.buffer.append(lines.split('\n'))
        vim.command('silent 1d _')

    def lookup(self, word):
        word = word + '\n'

        self.pipe_write(self.ind, word)
        lines = self.pipe_read(self.outd)

        # vim.command("let g:lines = '" + re.sub("'", "''", lines) + "'")

        if re.compile(r'^Your choice\[-1 to abort\]:\s*\Z', re.MULTILINE).search(lines):
            lines = self.get_choice(lines)

        lines = self.strip_prompt(lines)

        if lines != '':
            self.setlines(lines)

    def exit_sdcv(self):
        self.pipe_write(self.ind, self.eof_key)

    def pipe_write(self, pipe, data):
        os.write(pipe.fileno(), data)

    # http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/440554
    def pipe_read(self, pipe):
        data = ''
        max_times = 10
        delay = 0.1

        if sys.platform == 'win32':
            handle = msvcrt.get_osfhandle(pipe.fileno())
            size = win32pipe.PeekNamedPipe(handle, 0)[1]
            
            for i in range(max_times):
                if size > 0:
                    while size > 0:
                        data = data + win32file.ReadFile(handle, size, None)[1]
                        time.sleep(0.05)
                        size = win32pipe.PeekNamedPipe(handle, 0)[1]

                    break

                time.sleep(delay)
                size = win32pipe.PeekNamedPipe(handle, 0)[1]
        else:
            flags = fcntl.fcntl(pipe, fcntl.F_GETFL)
            if not pipe.closed:
                fcntl.fcntl(pipe, fcntl.F_SETFL, flags|os.O_NONBLOCK)
            
            try:
                for i in range(max_times):
                    if select.select([pipe], [], [], 0)[0]:
                        tmp = pipe.read(1024)
                        while tmp != '':
                            data = data + tmp
                            time.sleep(0.05)
                            if select.select([pipe], [], [], 0)[0]:
                                tmp = pipe.read(1024)
                            else:
                                tmp = ''

                        break
                    
                    time.sleep(delay)
    
            finally:
                if not pipe.closed:
                    fcntl.fcntl(pipe, fcntl.F_SETFL, flags)

        return data

