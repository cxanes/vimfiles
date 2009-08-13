#!python

import os
import sys

# argv = [$0 filename line col servername]

path = r'C:\Program Files\Vim\vim72\gvim.exe'
args = ['gvim']
if len(sys.argv) <= 1:
    print 'usage: %s filename[.tex] line col [vim_servername]' % sys.argv[0]
    sys.exit()

filename = sys.argv[1]

line = 1
col  = 1
servername = None

if len(sys.argv) > 2:
    try: 
        line = max(int(sys.argv[2]), 1)
    except ValueError:
        line = 1
    
if len(sys.argv) > 3:
    try: 
        col = max(int(sys.argv[3]), 1)
    except ValueError:
        col = 1

if len(sys.argv) > 4:
    servername = sys.argv[4]

if servername is not None:
    args += ['--servername', servername, '--remote-silent']

if not filename.lower().endswith('.tex'):
    filename += '.tex'

args += ['"+call cursor(%d,%d)"' % (line, col), '"%s"' % (filename, )]
os.execv(path, args)
