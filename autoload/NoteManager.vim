"         File: NoteManager.vim
"       Author: Frank Chang
"              ( frank.nevermind <AT> gmail.com )
"  Description: A simple note-taking system using SQLite.
"      Version: 1.0
"     
" Prerequisite: Vim    >= 7.0   <http://www.vim.org/>
"
"               SQLite >= 3.0   <http://www.sqlite.org/> (sqlite3 program)
"
"                   or
"
"               Python >= 2.5   <http://www.python.org/> (sqlite3 module)
"               Vim    +python
"
" See plugin/NoteManager.vim for documentation
"
" Implementation: {{{
"
" Class Diagram:                       +-----------------------+
"                                      |                       |
"               +----------------------+----------+            |
"               |                      |          |            |
"               |                      |          v            v
"  +---------+  |      +---------+     |     +----------+  +------+   +------+
"  |  Query  |  |      |  Panel  |     |     | NoteList |  | Note |   | Tags |
"  +---------+  |      +---------+     |     +----------+  +------+   +------+
"  |         |  |      |         |     |     |          |  |      |o->|      |
"  +---------+  |      +---------+     |     +----------+  +------+   +------+
"       ^       |           ^    +-----+                                  ^
"       |       |           |    |                                        |
"   +---+  +----|-----------+----|----------+                             |
"   |      |    |           |    |          |                             |
"   o      |    o           |    o          |                +------------+  
"  +---------------+  +-----------+   +----------+           |               
"  | NoteListPanel |  | NotePanel |   | TagPanel |           |               
"  +---------------+  +-----------+   +----------+           |               
"  |               |  |           |   |          |           |               
"  +---------------+  +-----------+   +----------+           |               
"          ^                ^               ^                |   
"          |                |               |                |   
"          |                |   +-----------+                |   +----------+
"          |                |   |                            |   | Database |
"          |                |   |     +-------------+        |   +----------+
"          |                |   |     | NoteManager |        |   |Execute() |
"          |                |   |     +-------------+        |   +----------+
"          |                |   +----o|GetNoteList()|o-------+         ^
"          |                +--------o|GetNote()    |                  |            
"          +-------------------------o|             |o-----------------+            
"                                     +-------------+
" }}}
" {{{1 This script requires Vim 7.0 (or later)
if v:version < 700
  echohl ErrorMsg
  echom 'NoteManager plugin requires Vim 7.0 or later'
  echohl None
  finish
endif
" }}}1
" {{{1 Load Once
if exists('loaded_autoload_note_manager')
  finish
endif
let loaded_autoload_note_manager = 1
let s:save_cpo = &cpo
set cpo&vim
" }}}1
" {{{1 sqlite3 detection
"
" If Vim is compiled with python interface, and the version of python is higher than 2.5,
" we can use the built-in module 'sqlite3' to manumplate data.
let s:has_python = 0
if has('python') && exists('g:NoteManager_PySqlite') && g:NoteManager_PySqlite != 0
  python << EOF
import sys
if sys.version_info[0] >= 2 and sys.version_info[1] >= 5:
  import sqlite3
  import vim
  import re
  vim.command('let s:has_python = 1')
EOF
endif

if !executable('sqlite3') && s:has_python == 0
  echohl ErrorMsg
  echom 'NoteManager plugin requires SQLite 3.0 or later'
  echohl None
  finish
endif
" }}}
" }}}1
" {{{1 Global Variables
let NoteManager#QUERY_LIST_ID = -2
" {{{ NoteManager Database Schema
let s:NoteDBCmd= join([
  \ "BEGIN TRANSACTION;",
  \ "CREATE TABLE Notes (ID INTEGER PRIMARY KEY, PostDate DATE, Summary TEXT, Description TEXT, Info TEXT);",
  \ "CREATE TABLE NoteTags (NoteID INTEGER, TagID INTEGER);",
  \ "CREATE TABLE TagDef (ID INTEGER PRIMARY KEY, Name TEXT NOT NULL UNIQUE ON CONFLICT IGNORE, Parent INTEGER);",
  \ "COMMIT;"], "\n")
let s:NoteListColWitdh = [5, 19, -25, -1]
" }}}
" }}}1
" {{{1 Global Utilities
" {{{ CurPanelName()
function! NoteManager#CurPanelName() 
  if !exists('g:NoteManager')
    return ''
  endif

  return g:NoteManager.CurPanel.Class
endfunction
" }}}
" {{{ Note()
function! NoteManager#Note() 
  if !exists('g:NoteManager') || g:NoteManager.CurPanel.Class != 'NotePanel'
    return {}
  endif

  return g:NoteManager.CurPanel.Note.Content
endfunction
" }}}
" {{{ ShowMesg()
function! NoteManager#ShowMesg(mesg, ...)
  let hl = a:0 == 0 ? 'WarningMsg' : a:1
  exe 'echohl ' . hl
  echom 'NoteManager: ' . a:mesg
  echohl None
endfunction
" }}}
" {{{ FormatNote()
" a:1 = fieldNames
function! NoteManager#FormatNote(note, ...)
  let note = {}
  let type = 0
  if type(a:note) == type({})
    let note = a:note
  elseif type(a:note) == type([]) && a:0 > 0
    let type = 1
    if type(a:1) == type({}) " a:1 = { 'ID': 0, 'Summary': 1, ... }
      for field in keys(a:1)
        let note[field] = a:note[a:1[field]]
      endfor
    elseif type(a:1) == type([]) " a:1 = ['ID', 'Summary', ... ]
      for i in range(len(a:1))
        let note[a:1[i]] = a:note[i]
      endfor
    endif
  endif

  let summary = get(note, 'Summary',  '')
  let sep = repeat('=', strlen(summary))
  let id = get(note, 'ID', '') + 0
  if id == g:NoteManager#QUERY_LIST_ID
    let text = [ ':Summary: ' . get(note, 'Summary', '')]
  else
    let text = [sep, summary, sep, '']
  endif

  call extend(text, [
        \   ':ID: '       . get(note, 'ID',       ''),
        \   ':PostDate: ' . get(note, 'PostDate', ''),
        \   ':Tags: '     . get(note, 'Tags',     ''),
        \   '',
        \ ])

  if id == g:NoteManager#QUERY_LIST_ID && &ft == 'rst' 
    call extend(text, [
          \ '.. contents:: Note Summaries',
          \ '    :depth: 1',
          \ '    :backlinks: entry',
          \ ''])
  endif
  call add(text, get(note, 'Description', ''))
  return join(text, "\n")
endfunction
" }}}
" }}}1
" {{{1 Start or Stop NoteManager
" {{{ StartNoteManager()
function! NoteManager#StartNoteManager(setting)
  " The format of message comes from DrawIt.vim
  if exists('g:NoteManager')
    echo '[NoteManager] (already on, use :StopNoteManager to stop, or :NMShowPanel to show the missing panel)'
    return
  endif

  let s:g_setting = s:NewSetting(a:setting)

  try
    let db = s:g_setting.Get('DbFile')
    if db =~ '^[a-zA-Z]:[\\/]' || db =~ '^\~\?/'
      " db is a absolute path
      if isdirectory(db)
        call NoteManager#ShowMesg("'".db."' is a directory", 'ErrorMsg')
        return
      elseif filewritable(fnamemodify(db, ':p:h')) != 2
        call NoteManager#ShowMesg("'".fnamemodify(db, ':p:h')."' is not writable", 'ErrorMsg')
        return
      endif
    elseif !isdirectory(s:g_setting.Get('Dir'))
      call NoteManager#ShowMesg("The directory '".s:g_setting.Get('Dir')."' doesn't exist", 'ErrorMsg')
      return
    else
      let db = fnamemodify(s:g_setting.Get('Dir'), ':p') . s:g_setting.Get('DbFile')
    endif
  catch /^NoteManager:/
    call NoteManager#ShowMesg(substitute(v:exception, '^NoteManager:\s*', '', ''), 'ErrorMsg')
    return
  endtry

  try
    let g:NoteManager = s:NewNoteManager(db)
  catch /^NoteManager:/
    unlet! g:NoteManager
    redraw
    call NoteManager#ShowMesg('Cannot start NoteManager', 'ErrorMsg')
    call NoteManager#ShowMesg(substitute(v:exception, '^NoteManager:\s*', '', ''), 'ErrorMsg')
    return
  endtry

  command! -narg=* NMGetNote call s:GetNote(<q-args>)
  command! -bang -narg=1 NMExportNote call s:ExportNote(<q-args>, <q-bang> == '!')
  command! -narg=0 NMShowPanel call s:ShowPanel()
  command! -narg=1 NMSetf call s:Setf(<q-args>)
  redraw
  echo '[NoteManager]'
endfunction
" }}}
" {{{ StopNoteManager()
function! NoteManager#StopNoteManager()
  if !exists('g:NoteManager')
    return
  endif

  call g:NoteManager.Delete()
  unlet g:NoteManager
  let commands = ['NMGetNote', 'NMExportNote', 'NMShowPanel', 'NMSetf']
  for cmd in commands
    if exists(':' . cmd)
      exe 'delc '.cmd
    endif
  endfor
  unlet! s:g_setting
  call garbagecollect()
  redraw
  echo '[NoteManager off]'
endfunction
" }}}
" {{{ GetNote()
function! s:GetNote(type)
  if !exists('g:NoteManager') | return | endif
  try
    call g:NoteManager.SetPanel('NotePanel').Show(a:type)
  catch /^NoteManager(OpenNote):/
    call g:NoteManager.SetPanel('NoteListPanel')
    call g:NoteManager.CurPanel.Show()
    call NoteManager#ShowMesg(substitute(v:exception, '^NoteManager(OpenNote):\s*', '', ''), 'ErrorMsg')
  endtry
endfunction
" }}}
" {{{ ExportNote()
function! s:ExportNote(file, override)
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NotePanel'
    call NoteManager#ShowMesg("Only works in Note Panel", 'ErrorMsg')
    return
  endif
  if a:override
    if isdirectory(a:file)
      call NoteManager#ShowMesg('"' . a:file . '" is a directory', 'ErrorMsg')
      return
    endif
  elseif filereadable(a:file) || isdirectory(a:file)
    call NoteManager#ShowMesg("File Exists (add ! to override)", 'ErrorMsg')
    return
  endif
  let is_new = !filereadable(a:file)
  if !writefile(split(g:NoteManager.CurPanel.Note.Export(), '\n'), a:file)
    echo printf('"%s" %swritten', a:file, is_new ? '[New] ' : '')
  endif
endfunction
" }}}
" {{{ ShowPanel()
function! s:ShowPanel()
  if !exists('g:NoteManager') | return | endif
  call g:NoteManager.CurPanel.Create()
endfunction
" }}}
" {{{ Setf()
function! s:Setf(ft)
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NotePanel'
    call NoteManager#ShowMesg("Only works in Note Panel", 'ErrorMsg')
    return
  endif
  call g:NoteManager.CurPanel.SetFileType(a:ft)
endfunction
" }}}
" }}}1
" {{{1 Class: Setting
" Public  Method: Ctor {{{2
function! s:NewSetting(setting) 
  let self = {
        \ 'content': a:setting,
        \ 'Get'    : function('s:Setting_Get')
        \ }
  return self
endfunction
" }}}2
" Public  Method: Get {{{2
" a:1 - default. If omitted, throw an exception
function! s:Setting_Get(opt, ...) dict
  if has_key(self.content, a:opt)
    return self.content[a:opt]
  else
    if a:0 == 0
      throw "NoteManager: The option '" . a:opt . "' doesn't exist"
    else
      return a:1
    endif
  endif
endfunction
" }}}2
" }}}1
" {{{1 Class: Database
" Public  Method: Ctor {{{2
function! s:NewDatabase(db_file)
  let self = {
        \ 'Class'        : 'Database',
        \ 'Db'           : a:db_file,
        \ 'Execute'      : function('s:Database_Execute'),
        \ 'ExecuteMany'  : function('s:Database_ExecuteMany'),
        \ 'ExecuteScript': function('s:Database_ExecuteScript'),
        \ 'ExecuteAndReturnID': function('s:Database_ExecuteAndReturnID'),
        \ 'Delete'       : function('s:Database_Delete'),
        \ }
  call s:CreateNewNoteDb(self.Db)
  return self
endfunction
" }}}2
" Public  Method: Delete {{{2
function! s:Database_Delete() dict
  if s:has_python == 1
    python << EOF
if 'NoteDbCursor' in globals():
  NoteDbCursor.close()
  del NoteDbCursor
if 'NoteDbConn' in globals():
  NoteDbConn.close()
  del NoteDbConn
EOF
  endif
endfunction
" }}}2
if s:has_python == 1 
"{{{2 python + sqlite3
  " Public  Method: Execute {{{3
  function! s:Database_Execute(cmd, ...) dict
    let fmt  = s:GetCmdFmtPy(a:cmd, a:0)
    let args = s:GetArgsPy(a:000)
    silent python SQLGetData(vim.eval('fmt'), vim.eval('args'))

    if !empty(SQLExecuteError)
      call s:ThrowExecuteSQLError(call('printf', ['%s' . s:GetCmdFmt(a:cmd), ''] + s:GetArgs(a:000))
            \ ,SQLExecuteError)
    endif

    if exists('data') && a:cmd =~? '^\s*SELECT\>' 
      return data
    else
      return ''
    endif
  endfunction
  " }}}3
  " Public  Method: ExecuteAndReturnID {{{3
  function! s:Database_ExecuteAndReturnID(cmd, ...) dict
    call call(self.Execute, [a:cmd] + a:000, self)
    let lastrowid = -1
    python << EOF
if NoteDbCursor.lastrowid is None:
  pass
elif isinstance(NoteDbCursor.lastrowid, int):
  vim.command('let lastrowid = ' + str(NoteDbCursor.lastrowid))
else:
  vim.command("let lastrowid = '%s'" % re.sub(r"'", r"''", NoteDbCursor.lastrowid))
EOF
    return lastrowid
  endfunction
  " }}}3
  " Public  Method: ExecuteMany {{{3
  function! s:Database_ExecuteMany(cmd, args) dict
    if empty(a:args)
      return
    endif
    let fmt  = s:GetCmdFmtPy(a:cmd, len(a:args[0]))
    let args = s:GetArgsPy(a:args)

    let SQLExecuteError = ''
    python << EOF
try:
  NoteDbCursor.executemany(vim.eval('fmt'), vim.eval('args'))
  NoteDbConn.commit()
except sqlite3.DatabaseError, e:
  PyStrToVim(e.args[0])
  vim.command('let SQLExecuteError = output')
EOF
    if !empty(SQLExecuteError)
      call s:ThrowExecuteSQLError(call('printf', ['%s' . s:GetCmdFmt(a:cmd), ''] 
            \ + !empty(a:args) ? s:GetArgs(a:args[0]) : []), SQLExecuteError)
    endif
  endfunction
  " }}}3
  " Public  Method: ExecuteScript {{{3
  function! s:Database_ExecuteScript(cmd) dict
    let cmd = iconv(a:cmd, &enc, 'utf-8')
    let SQLExecuteError = ''
    python << EOF
try:
  NoteDbCursor.executescript(vim.eval('cmd'))
  NoteDbConn.commit()
except sqlite3.DatabaseError, e:
  PyStrToVim(e.args[0])
  vim.command('let SQLExecuteError = output')
EOF
    if !empty(SQLExecuteError)
      call s:ThrowExecuteSQLError(a:cmd, SQLExecuteError)
    endif
  endfunction
  " }}}3
  " Utilities (python + sqlite3 only) {{{3
  " {{{ GetArgsPy()
  function! s:GetArgsPy(args)
    let args = []
    for arg in a:args
      if type(arg) == type([])
        call add(args, s:GetArgsPy(arg))
      else
        call add(args, iconv(arg, &enc, 'utf-8'))
      endif
    endfor
    return args
  endfunction
  " }}}
  " {{{ GetCmdFmtPy()
  function! s:GetCmdFmtPy(cmd, num)
    let cmd = iconv(a:cmd, &enc, 'utf-8')
    return call('printf', ['%s' . cmd, ''] + repeat(['?'], a:num))
  endfunction
  " }}}
  " {{{ Python: PyStrToVim()
  python << EOF
def PyStrToVim(str):
  if isinstance(str, int):
    vim.command("let output = '%s'" % str)
  else:
    vim.command("let output = '%s'" % str.replace("'", "''"))

  ## old method
  # vim.command('let output = ""')
  # vim.command('redir => output')
  # if isinstance(str, int):
  #   print str
  # else:
  #   print str.replace("\\", "\\\\").replace("\t", "\\t").replace('"', '\\"')
  # vim.command('redir END')
  # vim.command(r"""let output = eval('"' . substitute(output, '^\n', '', 'g') . '"')""")
  vim.command(r"let output = iconv(output, 'utf-8', &enc)")
EOF
  " }}}
  " {{{ Python: SQLGetData()
  python << EOF
def SQLGetData(cmd, args):
  vim.command('let SQLExecuteError = ""')
  if 'NoteDbCursor' in globals():
    try:
      NoteDbCursor.execute(cmd, args)
      vim.command('let data = []')
      for row in NoteDbCursor:
          vim.command('let single = []')
          for col in row:
              if col is None:
                col = ''
              PyStrToVim(col)
              vim.command(r"call add(single, output)")
          vim.command('call add(data, single)')
      NoteDbConn.commit()
    except sqlite3.DatabaseError, e:
      PyStrToVim(e.args[0])
      vim.command('let SQLExecuteError = output')
EOF
  " }}}
  " {{{ Python: CheckNoteDb()
  python << EOF
def CheckNoteDb(db):
  if 'NoteDbCursor' not in globals():
    try:
      global NoteDbConn, NoteDbCursor
      NoteDbConn = sqlite3.connect(db)
      NoteDbConn.text_factory = str
      NoteDbCursor = NoteDbConn.cursor()
      NoteDbCursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
      tables = ['NoteTags', 'Notes', 'TagDef']
      for row in NoteDbCursor:
        if row[0] in tables:
          tables.remove(row[0])
      if len(tables) != 0:
        vim.command('throw \'NoteManager: "%s" is not a valid database\'' % re.sub(r"'", r"''", db))
    except sqlite3.DatabaseError:
        vim.command('throw \'NoteManager: "%s" is not a database\'' % re.sub(r"'", r"''", db))
EOF
  " }}}
  " {{{ Python: CreateNewNoteDb()
    python << EOF
def CreateNewNoteDb(db):
  try:
    if 'NoteDbCursor' not in globals():
      global NoteDbConn, NoteDbCursor
      NoteDbConn = sqlite3.connect(db)
      NoteDbConn.text_factory = str
      NoteDbCursor = NoteDbConn.cursor()
    NoteDbCursor.executescript(vim.eval('s:NoteDBCmd'))
  except sqlite3.DatabaseError:
      vim.command('throw \'NoteManager: Cannot create database "%s"\'' % re.sub(r"'", r"''", db))
EOF
  " }}}
  " {{{ CreateNewNoteDb()
  " The database used to store all notes
  " return 0 if successfully creating new database
  "
  " Ref: http://souptonuts.sourceforge.net/readme_sqlite_tutorial.html
  function! s:CreateNewNoteDb(db)
    if filereadable(a:db)
      python CheckNoteDb(vim.eval('a:db'))
      return
    endif
    python CreateNewNoteDb(vim.eval('a:db'))
  endfunction
  " }}}
  " }}}3
" }}}2
else
"{{{2 sqlite3 program
  " Public  Method: Execute {{{3
  function! s:Database_Execute(cmd, ...) dict
    let fmt = s:GetCmdFmt(a:cmd)

    let res = s:DbExecute(self.Db, call('printf', ['%s' . fmt, ''] + s:GetArgs(a:000)))
    if a:cmd =~? '^\s*SELECT\>'
      return s:ExtractCSV(res)
    else
      return ''
    endif
  endfunction
  " }}}3
  " Public  Method: ExecuteAndReturnID {{{3
  function! s:Database_ExecuteAndReturnID(cmd, ...) dict
    let fmt = s:GetCmdFmt(a:cmd)
    let fmt .= 'SELECT last_insert_rowid();'
    let res = s:DbExecute(self.Db, call('printf', ['%s' . fmt, ''] + s:GetArgs(a:000)))
    return s:ExtractCSV(res)[0][0]
  endfunction
  " }}}3
  " Public  Method: ExecuteMany {{{3
  function! s:Database_ExecuteMany(cmd, args) dict
    let cmd = ''
    let fmt = s:GetCmdFmt(a:cmd)
    for arg in a:args
      let cmd .= call('printf', ['%s' . fmt, ''] + s:GetArgs(arg))
    endfor
    call s:DbExecute(self.Db, cmd)
  endfunction
  " }}}3
  " Public  Method: ExecuteScript {{{3
  function! s:Database_ExecuteScript(cmd) dict
    call s:DbExecute(self.Db, a:cmd)
  endfunction
  " }}}3
  " Utilities (sqlite3 program only) {{{3
  " {{{ CreateNewNoteDb()
  function! s:CreateNewNoteDb(db)
    if filereadable(a:db)
      let output = system('sqlite3 -batch ' . shellescape(a:db), '.tables')
      if v:shell_error || output =~? '^Error: '
        throw "NoteManager: '" . a:db . "' is not a database"
      elseif output !~? '\<NoteTags\>' || output !~? '\<Notes\>' || output !~? '\<TagDef\>'
        throw "NoteManager: '" . a:db . "' is not a valid database"
      endif
      return
    endif
    call system('sqlite3 -batch ' . shellescape(a:db), s:NoteDBCmd)
    if v:shell_error
      throw "NoteManager: Cannot create database '" . a:db . "'"
    endif
  endfunction
  " }}}
  " }}}3
"}}}2
endif
" Utilities {{{2
" {{{3 ThrowExecuteSQLError()
function! s:ThrowExecuteSQLError(cmd, ...) 
  throw printf('NoteManager(ExecuteSQL): %s: %s'
        \ ,a:0 > 0 ? a:1 : 'The syntax of the SQL command is invalid'
        \ ,substitute(a:cmd, '[\r\n]\+', ' ', 'g'))
endfunction
" }}}3
" {{{3 DbExecute()
function! s:DbExecute(db, cmd)
  let cmd = iconv(a:cmd, &enc, 'utf-8')
  let res = system('sqlite3 -csv -batch '. shellescape(a:db), a:cmd)
  if v:shell_error
    call s:ThrowExecuteSQLError(cmd)
  endif
  return iconv(res, 'utf-8', &enc)
endfunction
" }}}3
" {{{3 GetCmdFmt()
function! s:GetCmdFmt(cmd)
  let fmt = a:cmd
  if fmt !~ ';\s*$'
    let fmt .= ';'
  endif
  return fmt
endfunction
" }}}3
" {{{3 GetArgs()
function! s:GetArgs(args)
  let args = copy(a:args)
  for idx in range(len(args))
    if type(args[idx]) == type('')
      let args[idx] = s:Quote(args[idx])
    endif
  endfor
  return args
endfunction
" }}}3
" {{{ ExtractCSV() - Extract data from csv file format
" a:1 = the number of data we want to extract (-1 means all)
"
" Ref: http://tools.ietf.org/html/rfc4180
function! s:ExtractCSV(csv, ...)
  let ct = a:0 > 0 ? a:1 : -1
  if ct == 0
    return []
  endif

  let data = []
  let single = []

  let csv = a:csv
  while !empty(csv)
    let strlen = strlen(csv)
    if csv[0] != '"' " non-escaped
      let i = match(csv, '[\r\n,]')
      if i == -1
        let i = strlen
      endif
      call add(single, (i == 0 ? '' : csv[0 : (i-1)]))
    else " escaped
      let quote1 = 0
      let quote = stridx(csv, '"', 1)
      let i = quote == -1 ? strlen : quote
      while 1
        if i < strlen && csv[i] == '"'
          let quote1 = !quote1
        elseif quote1
          call add(single, (i <= 2 ? '' : substitute(csv[1 : (i-2)], '""', '"', 'g')))
          break
        endif
        if quote1
          let i += 1
        else
          let quote = stridx(csv, '"', i + 1)
          let i = quote == -1 ? strlen : quote
        endif
      endwhile
    endif

    if i < strlen
      let ch = csv[i]
    endif
    let csv = csv[i+1 : ]

    if i == strlen || ch == "\n" || (ch == "\r" && csv[0] == "\n")
      if ch == "\r" && csv[0] == "\n"
        let csv = csv[1 : ]
      endif
      call add(data, single)
      let single = []
      if ct > 0 && len(data) >= ct
        return data
      endif
    endif
  endwhile

  if !empty(single)
    call add(single, '')
    call add(data, single)
  endif

  return data
endfunction
" }}}
" }}}2
" }}}1
" {{{1 Class: NoteManager
" Public  Method: Ctor {{{2
function! s:NewNoteManager(db_file)
  let db = s:NewDatabase(a:db_file)
  if empty(db)
    return {}
  endif

  let self =  { 
        \ 'Class'      : 'NoteManager',
        \ 'Db'         : db,
        \ 'Tags'       : s:NewTags(db),
        \ 'CurPanel'   : {},
        \ 'SetPanel'   : function('s:NoteManager_SetPanel'),
        \ 'GetNoteList': function('s:NoteManager_GetNoteList'),
        \ 'GetNote'    : function('s:NoteManager_GetNote'),
        \ 'Modified'   : function('s:NoteManager_Modified'),
        \ 'Delete'     : function('s:NoteManager_Delete'),
        \ }

  let self['Panel'] = { 
        \ 'NotePanel'    : s:NewPanel(self, 'NotePanel'),
        \ 'NoteListPanel': s:NewPanel(self, 'NoteListPanel'),
        \ 'TagPanel'     : s:NewPanel(self, 'TagPanel'),
        \ }

  " Always start NoteManager in new tab.
  tabnew

  call s:ApplyAutoCmd('NoteManagerEnter', [])
  call self.SetPanel('NoteListPanel').Show()
  return self
endfunction
" }}}2
" Public  Method: SetPanel {{{2
function! s:NoteManager_SetPanel(panel) dict
  if !has_key(self.Panel, a:panel)
    call NoteManager#ShowMesg("Panel '".a:panel."' doesn't exist")
    return self.CurPanel
  endif

  if !empty(self.CurPanel)
    if self.CurPanel.Class == a:panel
      return self.CurPanel
    endif
    call self.CurPanel.Clear()
  endif

  let self.CurPanel = self.Panel[a:panel]
  return self.CurPanel
endfunction
" }}}2
" }}}2
" Public  Method: GetNoteList {{{2
function! s:NoteManager_GetNoteList(...) dict
  return call('s:NewNoteList', [self.Db] + a:000)
endfunction
" }}}2
" Public  Method: GetNote {{{2
function! s:NoteManager_GetNote(...) dict
  return call('s:NewNote', [self.Db, self.Tags] + a:000)
endfunction
" }}}2
" Public  Method: Modified {{{2
"
" Some notes or tags have been modified, so the note-list panel needs to be refreshed.
function! s:NoteManager_Modified() dict
  call self.Panel.NoteListPanel.Modified()
endfunction
" }}}2
" Public  Method: Delete {{{2
function! s:NoteManager_Delete() dict
  for panel in values(self.Panel)
    call panel.Delete()
  endfor
  call self.Db.Delete()
  call s:ApplyAutoCmd('NoteManagerLeave', [])
endfunction
" }}}2
" }}}1
" {{{1 Class: Tags
" Public  Method: Ctor {{{2
function! s:NewTags(db)
  let self = {
        \ 'Class'  : 'Tags',
        \ 'Content': {},
        \ 'Db'     : a:db,
        \ 'Delete' : function('s:Tags_Delete'),
        \ 'Add'    : function('s:Tags_Add'),
        \ 'Rename' : function('s:Tags_Rename'),
        \ 'Update' : function('s:Tags_Update'),
        \ 'UpdateFromDb_': function('s:Tags_UpdateFromDb'),
        \ }
  call self.UpdateFromDb_()
  return self
endfunction
" }}}2
" Private Method: UpdateFromDb {{{2
function! s:Tags_UpdateFromDb() dict
  let data = self.Db.Execute('SELECT ID, Name FROM TagDef ORDER BY ID;')
  let tags = {}
  for item in data
    let tags[item[1]] = item[0]
  endfor
  let self.Content = tags
endfunction
" }}}2
" Public  Method: Add {{{2
function! s:Tags_Add(tags) dict
  if !(type(a:tags) == type("") || type(a:tags) == type([]))
    return -1
  endif
  if type(a:tags) == type([])
    if empty(a:tags)
      return -1
    else
      let tags = a:tags
    endif
  elseif a:tags =~ '^\s*$'
    return -1
  elseif has_key(self.Content, a:tags)
    call NoteManager#ShowMesg("The tag '" . a:tags . "' already exists")
    return -1
  else
    let tags = [a:tags]
  endif
  let new_tags = []
  for tag in tags
    if tag =~ '^\s*$'
      continue
    endif
    if !has_key(self.Content, tag)
      call add(new_tags, [tag])
    else
      call NoteManager#ShowMesg("The tag '" . tag . "' already exists")
    endif
  endfor
  call self.Db.ExecuteMany('INSERT INTO TagDef (Name) VALUES (%s);', new_tags)
  call self.UpdateFromDb_()
  return 0
endfunction
" }}}2
" Public  Method: Delete {{{2
function! s:Tags_Delete(tag) dict
  if type(a:tag) == type("") " Name
    if a:tag =~ '^\s*$' || !has_key(self.Content, a:tag)
      return -1
    endif
    let id = self.Content[a:tag]
  elseif type(a:tag) == type(0) " ID 
    let has_tag = 0
    for id in values(self.Content)
      if id == a:tag
        let has_tag = 1
        break
      endif
    endfor
    if !has_tag
      return -1
    endif
    let id = a:tag
  else
    return -1
  endif
  let cmd  = printf('DELETE FROM TagDef WHERE ID = %d;', id)
  let cmd .= printf('DELETE FROM NoteTags WHERE TagID = %d;', id)
  call self.Db.ExecuteScript(cmd)
  call self.UpdateFromDb_()
  return 0
endfunction
" }}}2
" Public  Method: Update {{{2
"
" Update the tags of the note with give ID.
function! s:Tags_Update(id, tags) dict
  if empty(a:tags)
    return -1
  endif

  let new_tags = []
  for tag in a:tags
    if tag =~ '^\s*$'
      continue
    endif
    if !has_key(self.Content, tag)
      call add(new_tags, tag)
    endif
  endfor
  if !empty(new_tags)
    call self.Add(new_tags)
  endif

  let cmd = printf('BEGIN TRANSACTION; DELETE FROM NoteTags WHERE NoteID = %d;', a:id)
  for tag in a:tags
    if tag =~ '^\s*$'
      continue
    endif
    let cmd .= printf('INSERT INTO NoteTags (NoteID, TagID) VALUES (%d, %d);',
          \ a:id, self.Content[tag])
  endfor
  let cmd .= 'COMMIT;'
  call self.Db.ExecuteScript(cmd)
  return 0
endfunction
" }}}2
" Public  Method: Rename {{{2
function! s:Tags_Rename(id, tag) dict
  if a:tag =~ '^\s*$'
    call NoteManager#ShowMesg("The tag cannot be empty")
    return -1
  elseif has_key(self.Content, a:tag)
    call NoteManager#ShowMesg("The tag '" . a:tag . "' already exists")
    return -1
  endif
  let cmd = printf("UPDATE TagDef SET Name = %s WHERE ID = %d;", s:Quote(a:tag), a:id)
  call self.Db.ExecuteScript(cmd)
  call self.UpdateFromDb_()
  return 0
endfunction
" }}}2
" }}}1
" {{{1 Class: Query"{{{
"
" Store the history of query.
" Public  Method: Ctor {{{2
function! s:NewQuery(...)
  let maxNum = a:0 == 0 ? 0 : a:1
  let self = {
        \ 'Class'   : 'Query',
        \ 'MaxNum'  : maxNum,
        \ 'History_': [],
        \ 'Index_'  : -1,
        \ 'Last_'   : '',
        \ 'Add'     : function('s:Query_Add'),
        \ 'Get'     : function('s:Query_Get'),
        \ }
  return self
endfunction
" }}}2
" Public  Method: Add {{{2
function! s:Query_Add(query) dict
  if a:query =~ '^\s*$' 
    if empty(self.History_)
      call add(self.History_, s:g_setting.Get('Query'))
    endif
  else
    call add(self.History_, a:query)
  endif
  let self.Last_ = self.History_[-1]

  if len(self.History_) > self.MaxNum
    if self.MaxNum != 0
      let self.History_ = self.History_[ -self:MaxNum : -1 ]
    else
      let self.History_ = []
    endif
  endif
  let self.Index_ = -1
  return self.Last_
endfunction
" }}}2
" Public  Method: Get {{{2
function! s:Query_Get(back) dict
  let query = ''
  if self.Index_ < 0
    let self.Index_ = a:back ? len(self.History_) - 1 : 0
    let query = self.History_[self.Index_]
  else
    if a:back
      let self.Index_ -= 1
      if self.Index_ >= 0
        let self.Index_ = self.Index_ % len(self.History_)
        let query = self.History_[self.Index_]
      endif
    else
      let self.Index_ += 1
      if self.Index_ >= len(self.History_)
        let self.Index_ = -1
      else
        let self.Index_ = self.Index_ % len(self.History_)
        let query = self.History_[self.Index_]
      endif
    endif
  endif
  return query
endfunction
" }}}2
" }}}1"}}}
" {{{1 Class: Panel
" Public  Method: Ctor {{{2
function! s:NewPanel(NoteManager, Child)
  let self = {
        \ 'Class'      : 'Panel',
        \ 'NoteManager': a:NoteManager,
        \ }
  let child = s:New{a:Child}(self)
  let child.Show     = function('s:Panel_Show')
  let child.Create   = function('s:Panel_Create')
  let child.Delete   = function('s:Panel_Delete')
  let child.Clear    = function('s:Panel_Clear')
  let child.HasPanel = function('s:Panel_HasPanel')
  return child
endfunction
" }}}2
" Public  Method: Show {{{2
function! s:Panel_Show(...) dict
  call self.Create()
  if !s:Call(self, 'Before', ['show'] + a:000)
    return
  endif
  for [bufname, height] in self.SubPanels
    call s:GoToWinnr(bufname)
    try
      let ul = &ul

      " remove all undos
      setl ul=-1

      call s:Call(self, 'Proc', [bufname, 'show'] + a:000)
    finally
      let &l:ul = ul
    endtry
  endfor
  redraw
  call s:Call(self, 'After', ['show'] + a:000)
endfunction
" }}}2
" Public  Method: Delete {{{2
function! s:Panel_Delete(...) dict
  for [bufname; dummy] in self.SubPanels
    let bufnr = s:FindBufferForName(bufname)
    if bufnr != -1
      exe 'bw '.bufnr
      call s:ApplyAutoCmd('PanelDelete', [self.Class, self.Name, bufname])
    endif
  endfor
endfunction
" }}}2
" Public  Method: Clear {{{2
function! s:Panel_Clear(...) dict
  call s:Call(self, 'Clear', a:000)
endfunction
" }}}2
" Public  Method: HasPanel {{{2
function! s:Panel_HasPanel() dict
  for [bufname; dummy] in self.SubPanels
    if s:Bufwinnr(bufname) == -1
      return 0
    endif
  endfor
  return 1
endfunction
" }}}2
" Private Method: Create {{{2
function! s:Panel_Create() dict
  if self.HasPanel()
    return
  endif
  call s:Call(self, 'Before', ['create'] + a:000)
  silent wincmd o
  let first = 1
  let func = 's:'.self.Class.'_Proc'
  for [bufname; dummy] in self.SubPanels
    let new_panel = 0
    if first
      let first = 0
      setlocal hid 
      if s:FindBufferForName(bufname) == -1
        enew
        exe 'silent f' escape(bufname, ' ')
        let new_panel = 1
      else
        exe 'silent e' escape(bufname, ' ')
      endif
    else
      if s:FindBufferForName(bufname) == -1
        bo new
        exe 'silent f' escape(bufname, ' ')
        let new_panel = 1
      else
        exe 'silent bo sp' escape(bufname, ' ')
      endif
    endif
    setlocal bt=nofile bh=hide nobl noswf
    exe 'lcd ' . substitute(fnamemodify(s:g_setting.Get('Dir'), ':p'), '\s', '\\&', 'g')
    call s:Call(self, 'Proc', [bufname, 'create'] + a:000)
    if new_panel
      call s:ApplyAutoCmd('PanelCreate', [self.Class, self.Name, bufname])
    endif
  endfor
  for [bufname, height] in self.SubPanels
    if height > 0
      call s:GoToWinnr(bufname)
      exe 'resize '.height
      setlocal wfh
    endif
  endfor
  call s:Call(self, 'After', ['create'] + a:000)
endfunction
" }}}2
" Utilities {{{2
" {{{ Call()
function! s:Call(self, func, va_list)
  let class = a:self.Class
  if exists('*s:'.class.'_'.a:func)
    return call('s:'.class.'_'.a:func, a:va_list, a:self)
  endif
  return -1
endfunction
" }}}
" }}}2
" }}}1
" {{{1 Class: NoteListPanel
" Public  Method: Ctor {{{2
function! s:NewNoteListPanel(parent)
  let self = {
        \ 'Class'       : 'NoteListPanel',
        \ 'NoteManager' : a:parent.NoteManager,
        \ 'Cursor'      : [1, 1],
        \ 'Query'       : s:NewQuery(s:g_setting.Get('MaxNumQuery', 10)),
        \ 'Name'        : {
        \                   'Query'   : '_Query_', 
        \                   'NoteList': '_NoteList_'
        \                 },
        \ 'Modified_'   : 1,
        \ 'DeleteNote'  : function('s:NoteListPanel_DeleteNote'),
        \ 'QueryHistory': function('s:NoteListPanel_QueryHistory'),
        \ 'Modified'    : function('s:NoteListPanel_Modified'),
        \ 'ListNote_'   : function('s:NoteListPanel_ListNote'),
        \ }
  let self['NoteList'] = self.NoteManager.GetNoteList()
  let self['SubPanels'] = [
        \ [self.Name.Query,     1],
        \ [self.Name.NoteList, -1],
        \ ]
  return self
endfunction
" }}}2
" Public  Method: Proc {{{2
function! s:NoteListPanel_Proc(bufname, type, ...) dict
  if a:bufname == self.Name['Query']
    if a:type ==? 'show'
      call s:Clear()
      call setline(1, ': ')
      normal! gg
    elseif a:type ==? 'create'
      exec 'setlocal completefunc='.'<SNR>'.s:SID().'_CompleteTagsQuote'

      nnoremap <silent> <buffer> <CR>   :call <SID>Query()<CR>
      inoremap <silent> <buffer> <CR>   <C-O>:call <SID>Query()<CR><ESC>
      nnoremap <silent> <buffer> <Up>   :call <SID>QueryHistory(1)<CR>$
      inoremap <silent> <buffer> <Up>   <C-O>:call <SID>QueryHistory(1)<CR><C-O>$
      nnoremap <silent> <buffer> k      :call <SID>QueryHistory(1)<CR>$
      nnoremap <silent> <buffer> <Down> :call <SID>QueryHistory(0)<CR>$
      inoremap <silent> <buffer> <Down> <C-O>:call <SID>QueryHistory(0)<CR><C-O>$
      nnoremap <silent> <buffer> j      :call <SID>QueryHistory(0)<CR>$
      nnoremap <silent> <buffer> <F1>   :call <SID>NoteListPanel_Help('Query')<CR>
      inoremap <silent> <buffer> <F1>   <C-O>:call <SID>NoteListPanel_Help('Query')<CR>
      inoremap <silent> <buffer> <F4>   <C-O>:StopNoteManager<CR>
      nnoremap <silent> <buffer> <F4>   :StopNoteManager<CR>
      setlocal nonu
    endif
  elseif a:bufname == self.Name['NoteList']
    if a:type ==? 'show'
      let self.Cursor = getpos('.')[1 : 2]
      call call(self.ListNote_, a:000, self)
    elseif a:type ==? 'create'
      au VimResized <buffer> call g:NoteManager.CurPanel.Show()
      nnoremap <silent> <buffer> <CR> :call <SID>OpenNote()<CR>
      nnoremap <silent> <buffer> <2-LeftMouse> :call <SID>OpenNote()<CR>
      nnoremap <silent> <buffer> <F4> :StopNoteManager<CR>
      nnoremap <silent> <buffer> <expr> k    line('.') <= 5 ? '' : 'k'
      nnoremap <silent> <buffer> <expr> <Up> line('.') <= 5 ? '' : 'k'
      nnoremap <silent> <buffer> o    :NMGetNote<CR>
      nnoremap <silent> <buffer> dd   :call <SID>DeleteNote()<CR>
      nnoremap <silent> <buffer> q    :call <SID>MoveToQuery()<CR>A
      nnoremap <silent> <buffer> t    :call <SID>OpenTagPanel()<CR>
      nnoremap <silent> <buffer> <F1> :call <SID>NoteListPanel_Help('NoteList')<CR>
      setlocal nonu cul

      syn match notelistQuery '\%1l.*'
      syn match notelistSep   '\%2l.*'
      syn match notelistField '\%3l.*'
      syn match notelistSep   '\%4l.*'
      syn match noteID        '^\s*\d\+'
      syn match noteDate      '\%(\d\)\@<!\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\%(\d\)\@!'

      " Highlight for Tag column
      let notelist_col_witch = s:g_setting.Get('NoteListColWitdh', s:NoteListColWitdh)
      let bc = s:Abs(get(notelist_col_witch, 0)) + 2 + s:Abs(get(notelist_col_witch, 1))
      let ec = bc + 2 + s:Abs(get(notelist_col_witch, 2))
      exec printf('syn match noteTag ''\%%>4l\%%>%dc[^,[:space:]]\+\%%<%dc''', bc, ec)

      hi link notelistQuery Define
      hi link notelistSep   Label
      hi link notelistField Title
      hi link noteID        Number
      hi link noteDate      String
      hi link noteTag       Tag

      set nowrap
    endif
  endif
endfunction
" }}}2
" Public  Method: After {{{2
function! s:NoteListPanel_After(type, ...) dict
  if a:type ==? 'show'
    call s:GoToWinnr(self.Name['NoteList'])
    if self.Cursor[0] > line('$')
      let self.Cursor[0] = line('$')
    endif
    call cursor(self.Cursor)
    normal! 0
    call search('^\s*\d\+\D\|^\s*$', 'cw')
    call cursor(line('.'), self.Cursor[1])
  endif
endfunction
" }}}2
" Public  Method: DeleteNote {{{2
function! s:NoteListPanel_DeleteNote(id) dict
  call self.NoteList.DeleteNote(a:id)
  call self.Show()
endfunction
" }}}2
" Public  Method: Modified {{{2
function! s:NoteListPanel_Modified() dict
  let self.Modified_ = 1
endfunction
" }}}2
" Public  Method: QueryHistory {{{2
function! s:NoteListPanel_QueryHistory(back) dict
  if !self.HasPanel() || empty(self.Query)
    return
  endif
  call s:GoToWinnr(self.Name.Query)
  call s:Clear()
  call setline(1, ': '.self.Query.Get(a:back))
endfunction
" }}}2
" Public  Method: Help {{{2
function! s:NoteListPanel_Help(subpanel)
  if a:subpanel ==? 'NoteList'
    let help = [
          \ '" <F4> : Stop NoteManager',
          \ '" <CR> : Open the note under the cursor',
          \ '" o  : Create new note',
          \ '" :NMGetNote [id|query]: Create new note or note list',
          \ '" dd : Delete the note under the cursor',
          \ '" q  : Query',
          \ '" t  : Tag list',
          \ ]
  elseif a:subpanel ==? 'Query'
    let help = [
          \ 'SQL expression syntax <http://www.sqlite.org/lang_expr.html>:',
          \ ' SQL syntax [Tag: ''A'', ''B'']',
          \ '',
          \ 'Columns:',
          \ "  Tag      : The tag of note",
          \ "  PostDate : The post date of note",
          \ "  ID       : The id of note",
          \ '',
          \ 'Special command:',
          \ '  All   : List all notes',
          \ "  Today : List today's note",
          \ ]
  else
    let help = []
  endif
  if !empty(help)
    echohl Comment | echo join(help, "\n") | echohl None
  endif
endfunction
" }}}2
" Private Method: ListNote {{{2
"  a:1 - query
function! s:NoteListPanel_ListNote(...) dict
  if !self.HasPanel()
    return
  endif

  call s:GoToWinnr(self.Name.NoteList)
  let query = self.Query.Add(a:0 > 0 ? a:1 : '')

  " When a:1 (query) exists, update anyway
  if self.Modified_ || a:0 > 0
    call self.NoteList.Update(query)
    let self.Modified_ = 0
  endif

  setlocal ma
  call s:Clear()
  call setline(1, ': '.query)
  if !empty(self.NoteList)
    let notelist_col_witch = s:g_setting.Get('NoteListColWitdh', s:NoteListColWitdh)
    let table = s:FormatTable(self.NoteList.FieldName, notelist_col_witch, self.NoteList.Content)
    call append(1, table)
  endif
  setlocal noma
endfunction
" }}}2
" Utilities {{{2
" {{{ MoveToQuery()
function! s:MoveToQuery()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NoteListPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  call s:GoToWinnr(g:NoteManager.CurPanel.Name.Query)
endfunction
" }}}
" {{{ Query()
function! s:Query()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NoteListPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  let query = join(getline(1, '$'), '')
  let query = substitute(query, '^:\s*', '', '')
  call g:NoteManager.CurPanel.Show(query)
endfunction
" }}}
" {{{ QueryHistory()
function! s:QueryHistory(back)
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NoteListPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  call g:NoteManager.CurPanel.QueryHistory(a:back)
endfunction
" }}}
" {{{ OpenNote()
function! s:OpenNote()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NoteListPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  let id = matchstr(getline('.'), '^\s*\zs\d\+\ze\s\+')
  if id == '' | return | endif
  call g:NoteManager.SetPanel('NotePanel').Show(id)
endfunction
" }}}
" {{{ DeleteNote()
function! s:DeleteNote()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NoteListPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  let id = matchstr(getline('.'), '^\s*\zs\d\+\ze\s\+')
  if id == '' | return | endif
  let ans =  confirm('Delete this note?', "&Yes\n&No", 1, 'Question')
  if ans == 1
    call g:NoteManager.CurPanel.DeleteNote(id)
  endif
endfunction
" }}}
" {{{ OpenTagPanel()
function! s:OpenTagPanel()
  if exists('g:NoteManager')
    call g:NoteManager.SetPanel('TagPanel').Show()
  endif
endfunction
" }}}
" {{{ CompleteTagsQuote() - For Query panel
function! s:CompleteTagsQuote(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '[^[:space:]]'
      let start -= 1
    endwhile
    return start
  else
    let res = []
    if exists('g:NoteManager') && match(getline('.')[: col('.')-1], '\c\<Tag\>') != -1
      let tags = map(copy(keys(g:NoteManager.Tags.Content)), '"''" . substitute(v:val, "''", "''''", "g") . "''"') 
      for m in tags
        if m =~ '^' . a:base
          call add(res, m)
        endif
      endfor
    endif
    return res
  endif
endfunction
" }}}
" }}}2
" }}}1
" {{{1 Class: NotePanel
" Public  Method: Ctor {{{2
function! s:NewNotePanel(parent)
  let self = {
        \ 'Class'      : 'NotePanel',
        \ 'NoteManager': a:parent.NoteManager,
        \ 'Note'       : {},
        \ 'Cursor'     : [],
        \ 'Name'       : {
        \                  'Info'       : '_Info_', 
        \                  'Description': '_Description_', 
        \                },
        \ 'NoteStack'  : [],
        \ 'UpdateNote' : function('s:NotePanel_UpdateNote'),
        \ 'GoToNote'   : function('s:NotePanel_GoToNote'),
        \ 'BackNote'   : function('s:NotePanel_BackNote'),
        \ 'CloseNote'  : function('s:NotePanel_CloseNote'),
        \ 'OpenNote'   : function('s:NotePanel_OpenNote'),
        \ 'GetPos'     : function('s:NotePanel_GetPos'),
        \ 'SetPos'     : function('s:NotePanel_SetPos'),
        \ 'SetFileType': function('s:NotePanel_SetFileType'),
        \ 'SetBufFileType_': function('s:NotePanel_SetBufFileType'),
        \ }
  let self['SubPanels'] = [
        \ [self.Name.Info,         4],
        \ [self.Name.Description, -1],
        \ ]
  return self
endfunction
" }}}2
" Public  Method: SetFileType {{{2
function! s:NotePanel_SetFileType(ft) dict
  let cur_winnr = winnr()
  let go_back = 0

  call s:GoToWinnr(self.Name.Info)
  if winnr() == cur_winnr
    let go_back = 1
  endif

  call self.SetBufFileType_(a:ft, self.Name.Info, 1)
  call s:GoToWinnr(self.Name.Description)
  call self.SetBufFileType_(a:ft, self.Name.Description, 1)

  if go_back
    call s:GoToWinnr(self.Name.Info)
  endif
endfunction
" }}}2
" Private Method: SetBufFileType {{{2
function! s:NotePanel_SetBufFileType(ft, bufname, force) dict
  if &ft == '' || a:force == 1
    exe 'silent setf' a:ft
  endif

  if a:bufname == self.Name.Info
    silent! syn clear noteDate noteTag noteFieldList noteTagField

    syn match noteDate  '\%(\d\)\@<!\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\%(\d\)\@!'
    syn match noteTag '[^,[:space:]]\+' contained
    syn match noteFieldList '\%(^\s*\)\@<=:\%([^:]\|\\:\)\+:\s\@='
    syn region noteTagField matchgroup=noteFieldList start='\c^\s*:\s*Tags\s*:' end="$" contains=noteTag keepend

    hi link noteDate String
    hi link noteFieldList Label
    hi link noteTag Tag
  else
    silent! syn clear noteTag
  endif

  silent! syn clear noteLink noteLinkQuote noteTagNum noteTagColon

  syn match noteLink '\c<NOTE:\(\d\+\)\%(:[^>]*\)\?>' containedin=ALL
  syn match noteLinkQuote '<\|>' containedin=noteLink contained
  syn match noteTag '\c\%(<\)\@<=NOTE:\d\+:\?' containedin=noteLink contained
  syn match noteTagNum '\d\+' containedin=noteTag contained
  syn match noteTagColon ':'  containedin=noteTag contained

  hi link noteLink String
  hi link noteLinkQuote Tag
  hi link noteTag Identifier
  hi link noteTagNum Number
  hi link noteTagColon Delimiter
endfunction
" }}}2
" Public  Method: Before {{{2
function! s:NotePanel_Before(type, ...) dict
  if a:type ==? 'show'
    if !call(self.OpenNote, a:000, self)
      return -1
    endif
  endif
  return 0
endfunction
" Public  Method: Proc {{{2
function! s:NotePanel_Proc(bufname, type, ...) dict
  if a:type ==? 'create'
    nnoremap <silent> <buffer> <F2> :call <SID>UpdateNote()<CR>
    inoremap <silent> <buffer> <F2> <C-O>:call <SID>UpdateNote()<CR>
    nnoremap <silent> <buffer> <F4> :call <SID>ShowNoteList()<CR>
    inoremap <silent> <buffer> <F4> <C-O>:call <SID>ShowNoteList()<CR><ESC>
    nnoremap <silent> <buffer> <F1> :call <SID>NotePanel_Help()<CR>
    inoremap <silent> <buffer> <F1> <C-O>:call <SID>NotePanel_Help()<CR>
    nnoremap <silent> <buffer> <C-]> :call <SID>GoToNote()<CR>
    nnoremap <silent> <buffer> <C-T> :call <SID>BackNote()<CR>

    setlocal bt=acwrite
    au BufWriteCmd <buffer> call s:UpdateNote()

    command! -narg=0 -buffer NMUpdatePostDate call s:UpdatePostDate()

    if a:bufname == self.Name.Info
      exec 'setlocal completefunc='.'<SNR>'.s:SID().'_CompleteTags'
      setlocal nonu
    endif
  elseif a:type ==? 'show'
    call s:Clear()
    if a:bufname == self.Name.Info
      call setline(        1, ':Summary : '.self.Note.Content['Summary'])
      call append (line('$'), ':PostDate: '.self.Note.Content['PostDate'])
      call append (line('$'), ':Tags    : '.self.Note.Content['Tags'])
      call append (line('$'), ':Info    : '.self.Note.Content['Info'])
    elseif a:bufname == self.Name.Description
      call setline(1, split(self.Note.Content['Description'], '\n'))
    endif

    syn clear

    if a:bufname == self.Name.Description
      normal! gg
    endif

    call s:ApplyAutoCmd('NoteRead', [self.Note.Content, self.Name, a:bufname])
    call self.SetBufFileType_(s:g_setting.Get('FileType', ''), a:bufname, 0)

    if a:bufname == self.Name.Description
      if self.Note.IsList()
        call s:SetNoteListFolding(self.Note.Content.List)
      endif
    endif

    set nomod
  endif
endfunction
" }}}2
" Public  Method: After {{{2
function! s:NotePanel_After(type, ...) dict
  if a:type ==? 'show'
    if !empty(self.Cursor)
      call self.SetPos(self.Cursor)
    elseif self.Note.IsNew() && !self.Note.IsList()
      call s:GoToWinnr(self.Name.Info)
      startinsert!
    else
      call s:GoToWinnr(self.Name.Description)
      normal! gg
    endif
  endif
endfunction
" }}}2
" Public  Method: Clear {{{2
function! s:NotePanel_Clear(...) dict
  call s:GoToWinnr(self.Name.Info)
  silent set ft=
  call s:GoToWinnr(self.Name.Description)
  silent set ft=

  let self.Note = {}
  let self.NoteStack = []
  let self.Cursor = []
endfunction
" Public  Method: GetPos {{{2
function! s:NotePanel_GetPos() dict
  return [bufname(''), getpos('.')]
endfunction
" Public  Method: SetPos {{{2
function! s:NotePanel_SetPos(pos) dict
  call s:GoToWinnr(a:pos[0])
  call setpos('.', a:pos[1])
endfunction
" Public  Method: UpdateNote {{{2
function! s:NotePanel_UpdateNote() dict
  let mod = 0
  for bufname in values(self.Name)
    if getbufvar(s:FindBufferForName(bufname), '&mod')
      let mod = 1
      break
    endif
  endfor

  if mod == 0
    return
  endif

  let note = self.Note.Content
  let note['Description'] = 
        \ join(getbufline(s:FindBufferForName(self.Name.Description), 1, '$'), "\n")
  let info = getbufline(s:FindBufferForName(self.Name.Info), 1, '$')
  let field = ''
  for line in info
    let m = matchlist(line, '^\s*:\s*\([^:]\{-1,}\)\s*:\s*\(.*\)')
    if !empty(m)
      let field = m[1]
      if has_key(note, field)
        let note[field]  = substitute(m[2], '[\r\n]\+', '', 'g')
      endif
    else
      if has_key(note, field)
        let note[field] .= substitute(line, '[\r\n]\+', '', 'g')
      endif
    endif
  endfor
  call self.Note.Commit()
  call s:ApplyAutoCmd('NoteWrite', [self.Note.Content])
  for bufname in values(self.Name)
    call setbufvar(s:FindBufferForName(bufname), '&mod', 0)
  endfor
  call self.NoteManager.Modified()
  redraw
  " redraw the tabline
  let &tabline = &tabline
endfunction
" }}}2
" Public  Method: OpenNote {{{2
" a:1 = id
" a:2 = note history
"       -1: pop one note (ignore a:1)
"        0: clean history first (default)
"        1: push_back original note
function! s:NotePanel_OpenNote(...) dict
  if self.CloseNote()
    return -1
  endif

  let self.Cursor = []
  if a:0 > 1 && a:2 < 0
    if !empty(self.NoteStack)
      let [self.Cursor, self.Note] = remove(self.NoteStack, -1)
    else
      throw 'NoteManager(OpenNote): note stack empty'
    endif
    return 0
  endif

  if a:0 < 2 || a:2 == 0
    let self.NoteStack = []
  endif

  if a:0 > 0
    try
      let note = self.NoteManager.GetNote(a:1)
    catch /^NoteManager(GetNote):/
      let self.Note = self.NoteManager.GetNote()
      throw 'NoteManager(OpenNote): note not found: ID = ' . a:1
    endtry
  else
    let note = self.NoteManager.GetNote()
  endif
  if !empty(self.Note)
    call add(self.NoteStack, [self.GetPos(), self.Note])
  endif
  let self.Note = note
  return 0
endfunction
" Public  Method: Help {{{2
function! s:NotePanel_Help()
  let help = [
        \ '" <F2>|:w : Save this note',
        \ '" <F4> : Back to note list without saving the note',
        \ '" <C-X><C-U> : Tag completion |compl-function|',
        \ '" <C-]> : Jump to the note of the link under the cursor',
        \ '"        Link format: <NOTE:{ID}[:{Description}]>',
        \ '"                       {ID}: The ID of the note',
        \ '"                       {Description}: Description (optional)',
        \ '" <C-T> : Jump to older note in note stack',
        \ '" :NMExportNote[!] {file}: Export note to {file} (add ! to override)',
        \ ]
  echohl Comment | echo join(help, "\n") | echohl None
endfunction
" }}}2
" {{{ Public  Method: GoToNote
function! s:NotePanel_GoToNote(id) dict
  try
    call self.Show(a:id, 1)
  catch /^NoteManager(OpenNote):/
    call NoteManager#ShowMesg(substitute(v:exception, '^NoteManager(OpenNote):\s*', '', ''), 'ErrorMsg')
    return
  endtry
endfunction
" }}}
" {{{ Public  Method: BackNote
function! s:NotePanel_BackNote() dict
  try
    call self.Show(0, -1)
  catch /^NoteManager(OpenNote):/
    call NoteManager#ShowMesg(substitute(v:exception, '^NoteManager(OpenNote):\s*', '', ''), 'ErrorMsg')
    return
  endtry
endfunction
" }}}
" {{{ Public  Method: CloseNote
function! s:NotePanel_CloseNote() dict
  let bufnr = map(values(self.Name), 's:FindBufferForName(v:val)')
  let close = 1
  for nr in bufnr
    if getbufvar(nr, '&mod') == 1
      let ans = confirm('The note is modified. Save changes?'
            \ , "&Yes\n&No\n&Cancel", 1, 'Question')
      if ans == 1
        call self.UpdateNote()
      elseif ans == 2
        for nr2 in bufnr
          call setbufvar(nr2, '&mod', 0)
        endfor
      else
        let close = 0
      endif
      break
    endif
  endfor

  if close == 0
    return -1
  endif

  if has_key(self.Note, 'Content')
    call s:UnsetNoteListFolding()
    call s:ApplyAutoCmd('NoteLeave', [self.Note.Content])
  endif
  return 0
endfunction
" }}}
" Utilities {{{2
" {{{ SetNoteListFolding()
function! s:SetNoteListFolding(list)
  set foldtext=g:NoteManagerFoldText()
  let s:NoteManagerFoldList = {}
  let blnum = 1
  for [elnum, text] in a:list
    let s:NoteManagerFoldList[elnum] = text
    exec printf('%d,%dfold', blnum, elnum)
    let blnum = elnum + 1
  endfor
endfunction
" }}}
" {{{ NoteManagerFoldText()
function! g:NoteManagerFoldText()
  if !exists('s:NoteManagerFoldList')
    return foldtext()
  endif

  if has_key(s:NoteManagerFoldList, v:foldend)
    return s:NoteManagerFoldList[v:foldend]
  endif

  return foldtext()
endfunction
" }}}
" {{{ UnsetNoteListFolding()
function! s:UnsetNoteListFolding()
  " For LaTeX-Suite
  unlet! b:doneFolding b:doneSetFoldOptions
  set foldtext< fdm<
  silent! normal! zE
  if exists('s:NoteManagerFoldList')
    unlet s:NoteManagerFoldList
  endif
endfunction
" }}}
" {{{ UpdateNote()
function! s:UpdateNote()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NotePanel' | return | endif
  call g:NoteManager.CurPanel.UpdateNote()
endfunction
" }}}
" {{{ ShowNoteList()
function! s:ShowNoteList()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class == 'NotePanel'
    if g:NoteManager.CurPanel.CloseNote()
      return
    endif
  endif
  call g:NoteManager.SetPanel('NoteListPanel').Show()
endfunction
" }}}
" {{{ CompleteTags() - For Info panel
function! s:CompleteTags(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '[^[:space:],]'
      let start -= 1
    endwhile
    return start
  else
    let res = []
    if exists('g:NoteManager') && match(getline('.'), '\c^\s*:\s*Tags\s*:') != -1
      for m in keys(g:NoteManager.Tags.Content)
        if m =~ '^' . a:base
          call add(res, m)
        endif
      endfor
    endif
    return res
  endif
endfunction
" }}}
" {{{ GoToNote()
function! s:GoToNote()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NotePanel' | return | endif
	let [dummy, bcol] = searchpos('<', 'bnc', line('.'))
	let [dummy, ecol] = searchpos('>', 'nc',  line('.'))
  if bcol == 0 || ecol == 0 || bcol >= ecol
    call NoteManager#ShowMesg('No identifier under cursor', 'ErrorMsg')
    return
  endif
  let link = matchlist(getline('.')[bcol-1 : ecol-1], '^\c<NOTE:\(\d\+\)\%(:[^>]*\)\?>$')
  if empty(link)
    call NoteManager#ShowMesg('No identifier under cursor', 'ErrorMsg')
    return
  endif
  let id = link[1] + 0
  call g:NoteManager.CurPanel.GoToNote(id)
endfunction
" }}}
" {{{ BackNote()
function! s:BackNote()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NotePanel' | return | endif
  call g:NoteManager.CurPanel.BackNote()
endfunction
" }}}
" {{{ UpdatePostDate()
function! s:UpdatePostDate() 
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'NotePanel' | return | endif
  let cur_winnr = winnr()
  call s:GoToWinnr(g:NoteManager.CurPanel.Name.Info)
  let pos = getpos('.')
  call cursor(1, 1)
	let [lnum, col] = searchpos('^\s*:\s*PostDate\s*:', 'nW')
  if lnum == 0
    call setpos('.', pos)
    exec cur_winnr . 'wincmd w'
    return 0
  endif

  let line = getline(lnum)
  let field = matchstr(line, '^\s*:\s*PostDate\s*:\s*')
  call setline(lnum, field . s:GetDate())
  
  call setpos('.', pos)
  exec cur_winnr . 'wincmd w'
endfunction
" }}}
" }}}2
" }}}1
" {{{1 Class: TagPanel
" Public  Method: Ctor {{{2
function! s:NewTagPanel(parent)
  let self = {
        \ 'Class'      : 'TagPanel',
        \ 'Cursor'     : [1, 1],
        \ 'NoteManager': a:parent.NoteManager,
        \ 'Name'       : {
        \                  'TagList': '_Tag List_'
        \                },
        \ 'ListTag_'   : function('s:TagPanel_ListTag'),
        \ }
  let self['SubPanels'] = [
        \ [self.Name.TagList, -1],
        \ ]
  return self
endfunction
" }}}2
" Public  Method: Proc {{{2
function! s:TagPanel_Proc(bufname, type, ...) dict
  if a:bufname == self.Name['TagList']
    if a:type ==? 'show'
      let self.Cursor = getpos('.')[1 : 2]
      call call(self.ListTag_, a:000, self)
    elseif a:type ==? 'create'
      au VimResized <buffer> call g:NoteManager.CurPanel.Show()

      nnoremap <silent> <buffer> <F4> :call <SID>ShowNoteList()<CR>
      nnoremap <silent> <buffer> b    :call <SID>ShowNoteList()<CR>
      nnoremap <silent> <buffer> <CR> :call <SID>QueryNote()<CR>
      nnoremap <silent> <buffer> s    :call <SID>QueryNote()<CR>
      nnoremap <silent> <buffer> o    :call <SID>AddTag()<CR>
      nnoremap <silent> <buffer> r    :call <SID>RenameTag()<CR>
      nnoremap <silent> <buffer> dd   :call <SID>DeleteTag()<CR>
      nnoremap <silent> <buffer> <expr> k    line('.') <= 4 ? '' : 'k'
      nnoremap <silent> <buffer> <expr> <Up> line('.') <= 4 ? '' : 'k'
      nnoremap <silent> <buffer> <F1> :call <SID>TagPanel_Help()<CR>
      setlocal noma nonu cul

      syn match Label  '\%1l.*'
      syn match Title  '\%2l.*'
      syn match Label  '\%3l.*'
      syn match Number '^\s*\d\+'
    endif
  endif
endfunction
" }}}2
" Public  Method: After {{{2
function! s:TagPanel_After(type) dict
  if a:type ==? 'show'
    call s:GoToWinnr(self.Name['TagList'])
    if self.Cursor[0] > line('$')
      let self.Cursor[0] = line('$')
    endif
    call cursor(self.Cursor)
    normal! 0
    call search('^\s*\d\+\D\|^\s*$', 'cw')
    call cursor(line('.'), self.Cursor[1])
  endif
endfunction
" }}}2
" Public  Method: Help {{{2
function! s:TagPanel_Help()
  let help = [
        \ '" <F4>|b : Back to note list',
        \ '" <CR>|s : Show notes with the tag under the cursor',
        \ '" o  : Add new tag',
        \ '" r  : Rename the tag under the cursor',
        \ '" dd : Delete the tag under the cursor',
        \ ]
  echohl Comment | echo join(help, "\n") | echohl None
endfunction
" }}}2
" Private Method: ListTag {{{2
function! s:TagPanel_ListTag() dict
  setlocal ma
  let tags = []
  for tag in items(self.NoteManager.Tags.Content)
    call add(tags, [tag[1]+0, tag[0]])
  endfor
  call sort(tags, function('s:SortTags'))
  call s:Clear()
  call setline(1, s:FormatTable(['ID', 'Tag'], [6, -1], tags))
  setlocal noma
endfunction
function! s:SortTags(i1, i2)
  return a:i1[0] == a:i2[0] ? 0 : a:i1[0] > a:i2[0] ? 1 : -1
endfunction
" }}}2
" Utilities {{{2
" {{{ AddTag()
function! s:AddTag()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'TagPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  call inputsave()
  let tag = input("Enter new tag name: ")
  let tag = substitute(tag, '^\s\+\|\s\+$', '', 'g')
  call inputrestore()
  if tag =~ ','
    call NoteManager#ShowMesg('Tag name cannot contain comma (,)')
    return
  elseif tag =~ '^\s*$'
    return
  endif
  call g:NoteManager.Tags.Add(tag)
  call g:NoteManager.CurPanel.Show()
endfunction
" }}}
" {{{ RenameTag()
function! s:RenameTag()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'TagPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  let id = matchstr(getline('.'), '^\s*\zs\d\+\ze\s\+')
  if id == '' | return | endif
  let tag = matchstr(getline('.'), '^\s*\d\+\s\+\zs.*$')
  let tag = substitute(tag, '\s\+$', '', 'g')
  call inputsave()
  let new_tag = input("Change the tag '" . tag . "' to: ")
  let new_tag = substitute(new_tag, '^\s\+\|\s\+$', '', 'g')
  call inputrestore()
  if new_tag =~ ','
    call NoteManager#ShowMesg('Tag name cannot contain comma (,)')
    return
  elseif new_tag =~ '^\s*$' || new_tag == tag
    return
  endif
  if !g:NoteManager.Tags.Rename(id, new_tag)
    call g:NoteManager.Modified()
  endif
  call g:NoteManager.CurPanel.Show()
endfunction
" }}}
" {{{ DeleteTag()
function! s:DeleteTag()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'TagPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  let id = matchstr(getline('.'), '^\s*\zs\d\+\ze\s\+')
  if id == '' | return | endif
  let ans =  confirm('Delete this Tag?', "&Yes\n&No", 1, 'Question')
  if ans == 1
    if !g:NoteManager.Tags.Delete(id+0)
      call g:NoteManager.Modified()
    endif
    call g:NoteManager.CurPanel.Show()
  endif
endfunction
" }}}
" {{{ QueryNote()
function! s:QueryNote()
  if !exists('g:NoteManager') | return | endif
  if g:NoteManager.CurPanel.Class != 'TagPanel' | return | endif
  if !g:NoteManager.CurPanel.HasPanel() | return | endif
  let tag = matchstr(getline('.'), '^\s*\d\+\s\+\zs.*$')
  let tag = substitute(tag, '\s\+$', '', 'g')
  if tag == ''
      return
  endif
  call g:NoteManager.SetPanel('NoteListPanel').Show("Tag = '" . tag . "'")
endfunction
" }}}
" }}}1
" {{{1 Class: Note
" Public  Method: Ctor {{{2
" a:1 - id
" a:2 - raise exception when the note with given id doesn't exit
function! s:NewNote(db, tags, ...)
  let self = {
        \ 'Db'          : a:db,
        \ 'Tags'        : a:tags,
        \ 'Type'        : 0,
        \ 'Content'     : s:CreateEmptyNote(),
        \ 'IsNew'       : function('s:Note_IsNew'),
        \ 'IsList'      : function('s:Note_IsList'),
        \ 'Commit'      : function('s:Note_Commit'),
        \ 'GetTags'     : function('s:Note_GetTags'),
        \ 'Export'      : function('s:Note_Export'),
        \ 'Insert_'     : function('s:Note_Insert'),
        \ 'Update_'     : function('s:Note_Update'),
        \ 'GetNoteByID_': function('s:Note_GetNoteByID'),
        \ 'GetNoteList_': function('s:Note_GetNoteList'),
        \ }

  let self.FieldID = {
        \ 'ID'          : 0,
        \ 'PostDate'    : 1,
        \ 'Summary'     : 2,
        \ 'Description' : 3,
        \ 'Info'        : 4,
        \}

  if a:0 > 0 
    if (type(a:1) == type(0) 
          \ || (type(a:1) == type('') && match(a:1, '^\d\+$') != -1)) " id
      call self.GetNoteByID_(a:1+0)
    elseif type(a:1) == type('') && match(a:1, '^\s*$') == -1 " query
      call self.GetNoteList_(a:1)
    endif
  endif

  return self
endfunction
" }}}2
" Public  Method: IsNew {{{2
function! s:Note_IsNew() dict
  return self.Content.ID <= 0
endfunction
" }}}2
" Public  Method: IsList {{{2
function! s:Note_IsList() dict
  return self.Type == 1
endfunction
" }}}2
" Public  Method: Commit {{{2
function! s:Note_Commit() dict
  if self.IsNew()
    call self.Insert_()
  else
    call self.Update_()
  endif
endfunction
" }}}2
" Public  Method: GetTags {{{2
function! s:Note_GetTags() dict
  let tags = []
  if self.IsNew()
    return tags
  endif

  let data = self.Db.Execute('SELECT TagDef.Name FROM NoteTags INNER JOIN TagDef ON TagDef.ID = NoteTags.TagID WHERE NoteTags.NoteID = %s;', self.Content.ID+0)
  for tag in data
    call add(tags, tag[0])
  endfor
  return tags
endfunction
" }}}2
" Private Method: Export {{{2
function! s:Note_Export() dict
  return s:ApplyAutoCmd('NoteExport', [self.Content], 'NoteManager#FormatNote')
endfunction
" }}}2
" Private Method: Insert {{{2
function! s:Note_Insert() dict
  let note = self.Content
  let note['ID'] = self.Db.ExecuteAndReturnID('INSERT INTO Notes (PostDate, Summary, Description, Info) VALUES (%s, %s, %s, %s);', note['PostDate'], note['Summary'], note['Description'], note['Info'])
  call self.Tags.Update(note['ID'], s:SplitTags(note['Tags']))
endfunction
" }}}2
" Private Method: Update {{{2
function! s:Note_Update() dict
  let note = self.Content
  call self.Db.Execute('UPDATE Notes SET PostDate = %s, Summary = %s, Description = %s, Info = %s WHERE ID = %s;', note['PostDate'], note['Summary'], note['Description'], note['Info'], note['ID'])
  call self.Tags.Update(note['ID'], s:SplitTags(note['Tags']))
endfunction
" }}}2
" Private Method: GetNoteByID {{{2 
function! s:Note_GetNoteByID(id) dict
  let note = self.Content
  if !(type(a:id) == 0 || type(a:id) == 1)
    return
  endif
  let id = a:id + 0
  let data = self.Db.Execute('SELECT * FROM Notes WHERE ID = %s;', id)
  if !empty(data)
    let data = data[0]
    for field in keys(note)
      if has_key(self.FieldID, field)
        let note[field] = data[self.FieldID[field]]
      endif
    endfor
    let note['Tags'] = join(self.GetTags(), ',')
  else
    throw 'NoteManager(GetNote): note not found : ID = ' . a:id
  endif
endfunction
" }}}2
" Private Method: GetNoteList {{{2 
function! s:Note_GetNoteList(query) dict
  let self.Type = 1
  let content = self.Content
  let notelist = s:NewNoteList(self.Db, a:query, 1)
  let content.ID = g:NoteManager#QUERY_LIST_ID
  let content.Summary = 'Query: ' . a:query
  let field_name = notelist.FieldName
  let note_list = notelist.Content

  let content['List'] = []
  let id_idx      = index(field_name, 'ID')
  let date_idx    = index(field_name, 'PostDate')
  let summary_idx = index(field_name, 'Summary')
  let list = []
  let lnum = 1
  let desc = ''
  let first = 1
  for note in note_list
    if id_idx >= 0
      let note[id_idx] = printf('<Note:%d>', note[id_idx])
    endif

    let lines = NoteManager#FormatNote(note, field_name) 
          \  . "\n\n" . (note is note_list[-1] ? '' : (repeat('=', &columns * 4/5) . "\n\n"))
    let desc .= lines
    if first
      let lnum += s:Lines(lines) - 1
      let first = 0
    else
      let lnum += s:Lines(lines)
    endif
    call add(list, [lnum, 
          \ printf('|%s| %s', (date_idx    < 0 ? '' : note[date_idx]), 
          \                   (summary_idx < 0 ? '' : note[summary_idx]))])
  endfor

  let content['Description'] = desc
  let content['List'] = list
endfunction
" }}}2
" Utilities {{{2
" {{{ Lines()
function! s:Lines(text)
  let lines = 0
  let start = stridx(a:text, "\n")
  while start != -1
    let lines += 1
    let start = stridx(a:text, "\n", start+1)
  endwhile
  return lines
endfunction

" }}}
" {{{ SplitTags()
function! s:SplitTags(tags)
  let tags = split(a:tags, ',')
  call map(tags, 'substitute(v:val, ''^\s\+\|\s\+$'', '''', ''g'')')
  call filter(tags, 'v:val !~ ''^\s*$''')
  let set = {}
  for tag in tags
    let set[tag] = 1
  endfor
  return keys(set)
endfunction
" }}}
" {{{ CreateEmptyNote()
function! s:CreateEmptyNote()
  return {
        \ 'ID'          : -1,
        \ 'PostDate'    : s:GetDate(),
        \ 'Summary'     : '',
        \ 'Description' : '',
        \ 'Tags'        : '',
        \ 'Info'        : '',
        \ }
endfunction
" }}}
" }}}2
" }}}1
" {{{1 Class: NoteList
" Public  Method: Ctor {{{2
" a:1 = query
" a:2 = withContent
function! s:NewNoteList(db, ...)
  let self = {
        \ 'Db'        : a:db,
        \ 'FieldName' : ['ID', 'PostDate', 'Tags', 'Summary'],
        \ 'Content'   : [],
        \ 'Update'    : function('s:NoteList_Update'),
        \ 'DeleteNote': function('s:NoteList_DeleteNote'),
        \ 'Parse_'    : function('s:NoteList_Parse'),
        \ }
  if a:0 > 0
    if a:0 > 1 && !empty(a:2)
      let self.FieldName += ['Description']
      call self.Update(a:1, a:2)
    else
      call self.Update(a:1)
    endif
  endif
  return self
endfunction
" }}}2
" Public  Method: Update {{{2
" a:1 = withContent
function! s:NoteList_Update(query, ...) dict
  let withContent = (a:0 > 0 && !empty(a:1))
  let note_list = []
  let tag_list  = []
  try
    let note_list = self.Db.Execute(printf("SELECT DISTINCT Notes.ID, PostDate, Summary%s FROM Notes LEFT OUTER JOIN NoteTags ON NoteTags.NoteID = Notes.ID LEFT OUTER JOIN TagDef ON TagDef.ID = NoteTags.TagID %s;", (withContent ? ', Description, Info' : ''), self.Parse_(a:query)))

    let id_list = []
    for note in note_list
      call add(id_list, note[0])
    endfor

    let tag_list = []
    if !empty(id_list)
      let tag_list = self.Db.Execute(printf("SELECT DISTINCT NoteTags.NoteID, TagDef.Name FROM NoteTags INNER JOIN TagDef ON TagDef.ID = NoteTags.TagID WHERE NoteTags.NoteID IN (%s);", join(id_list, ', ')))
    endif
  catch /^NoteManager(ExecuteSQL):/
    call NoteManager#ShowMesg('The query is invalid: ' . a:query, 'ErrorMsg')
    call NoteManager#ShowMesg(substitute(v:exception, '^NoteManager(ExecuteSQL):\s*', '', ''), 'ErrorMsg')
  catch /^NoteManager(ParseSQL):/
    call NoteManager#ShowMesg('The query is invalid: ' . a:query, 'ErrorMsg')
    call NoteManager#ShowMesg(substitute(v:exception, '^NoteManager(ParseSQL):\s*', '', ''), 'ErrorMsg')
  endtry

  let tag = {}
  for id_tag in tag_list
    if has_key(tag, id_tag[0])
      let tag[id_tag[0]] .= ',' . id_tag[1]
    else
      let tag[id_tag[0]] = id_tag[1]
    endif
  endfor

  for note in note_list
    call insert(note, (has_key(tag, note[0]) ? tag[note[0]] : ''), 2)
  endfor
  
  let self.Content = note_list
endfunction
" }}}2
" Public  Method: DeleteNote {{{2
function! s:NoteList_DeleteNote(id) dict
  let cmd  = printf('DELETE FROM Notes WHERE ID = %d;', a:id)
  let cmd .= printf('DELETE FROM NoteTags WHERE NoteID = %d;', a:id)
  call self.Db.ExecuteScript(cmd)
  call filter(self.Content, printf('v:val[0] != %d', a:id))
endfunction
" }}}2
" Private Method: Parse {{{2
function! s:NoteList_Parse(query)
  let query = a:query
  let key_fmt   = '\c\%%(''\|\w\)\@<!%s\%%(''\|\w\|\s*(\)\@!'

  if     match(query, printf(key_fmt, 'INSERT')) != -1 
    \ || match(query, printf(key_fmt, 'DELETE')) != -1
    \ || match(query, printf(key_fmt, 'UPDATE')) != -1 
    \ || match(query, printf(key_fmt, 'DROP'  )) != -1
    \ || match(query, printf(key_fmt, 'WHERE' )) != -1
    \ || match(query, printf(key_fmt, ';'     )) != -1
    throw 'NoteManager(ParseSQL): The query contains invalid command: '
          \ . substitute(query, '[\r\n]\+', '', 'g')
  endif

  " FIXME: Since "Tag = 'A' AND Tag = 'B'" 
  " (find the notes whose tag containing both 'A' and 'B') doesn't work,
  " we need to invent new syntax: Tag: 'A', 'B'
  " ref: http://darwinweb.net/articles/66-optimizing_and_simplifying_limited_eager_loading_in_activerecord
  let query_join = ''
  let b = match(query, '\c\<Tag:\s*')
  if b != -1
    let e = matchend(query, '\c\<Tag:\s*')
    let tags = split(query[e : ], ',')
    let i = 1
    for tag in tags
      let tag = substitute(tag, '^\s\+\|\s\+$', '', 'g')
      if empty(tag)
        continue
      endif
      let query_join .= printf("INNER JOIN NoteTags AS NoteTags%d ON NoteTags%d.NoteID = Notes.ID INNER JOIN TagDef AS TagDef%d ON TagDef%d.ID = NoteTags%d.TagID AND TagDef%d.Name %s", i, i, i, i, i, i, (tag =~ '^''\([^'']\|''''\)*''$' ? ('= '.tag) : tag))
      let i += 1
    endfor
    let query = b == 0 ? '' : query[ : b-1]
  endif

  let query = substitute(query, printf(key_fmt, 'All' ), '1'          , 'g')
  " let query = substitute(query, printf(key_fmt, 'Date'), 'PostDate'   , 'g')
  let query = substitute(query, printf(key_fmt, 'Tag' ), 'TagDef.Name', 'g')
  let query = substitute(query, printf(key_fmt, 'ID'  ), 'Notes.ID'   , 'g')

  let query = substitute(query, printf(key_fmt, 'Today\s*\(([^)]*)\)\?'), 
        \ '\=s:GetTimeRange("day", submatch(1))' , 'g')
  let query = substitute(query, printf(key_fmt, 'ThisMonth\s*\(([^)]*)\)\?'), 
        \ '\=s:GetTimeRange("month", submatch(1))' , 'g')

  return query_join . (query !~ '^\s*$' ? ('WHERE '.query) : '')
endfunction
" }}}2
" Utilities {{{2
" {{{ GetTimeRange()
function! s:GetTimeRange(type, args)
  " http://www.sqlite.org/cvstrac/wiki?p=DateAndTimeFunctions
  if a:type == 'day'
    let format = "(date('now', 'localtime', 'start of day', '%+d day') <= PostDate AND PostDate < date('now', 'localtime', 'start of day', '%+d day'))"
  elseif a:type == 'month'
    let format = "(date('now', 'localtime', 'start of month', '%+d months') <= PostDate AND PostDate < date('now', 'localtime', 'start of month', '%+d months'))"
  else
    return ''
  endif

  let args = substitute(a:args, '\s\+', '', 'g')
  if args == ''
    return printf(format, 0, 1)
  endif

  let range = matchlist(args, '^(\([-+]\?\d\+\)\%(,\([-+]\?\d\+\)\)\?)$')
  if !empty(range)
    return printf(format, range[1] + 0, (range[2] == '' ? range[1] : range[2]) + 1)
  endif

  return printf(format, 0, 1)
endfunction
" }}}
" }}}1
" {{{1 Utilities
" {{{ GetDate()
function! s:GetDate() 
  return strftime('%Y-%m-%d %H:%M:%S')
endfunction
" }}}
" {{{ Abs()
function! s:Abs(num) 
  let num = a:num + 0
  return num < 0 ? -num : num
endfunction
" }}}
" {{{ Quote() - Quote the string
" Since string in SQLite doesn't contain escaped characters,
" we only need to deal with "'" .
function! s:Quote(str)
  return "'".substitute(a:str, "'", "''", 'g')."'"
endfunction
" }}}
" {{{ Bufwinnr()
function! s:Bufwinnr(expr)
  if type(a:expr) == 0
    return bufwinnr(a:expr)
  elseif type(a:expr) == 1
    if a:expr == '' || a:expr == '%' || a:expr == '#'
      return bufwinnr(a:expr)
    else
      return bufwinnr(s:FindBufferForName(a:expr))
    endif
  endif
  retur -1
endfunction
" }}}
" {{{ GoToWinnr()
function! s:GoToWinnr(expr)
  exe s:Bufwinnr(a:expr).'wincmd w'
endfunction
" }}}
" {{{ FindBufferForName()
" Return the number of the buffer whose name matches exactly on given argument.
" http://tech.groups.yahoo.com/group/vim/message/73315
function! s:FindBufferForName(fileName)
  let fileName = escape(a:fileName, '[?,{')
  let _isf = &isfname
  try
    set isfname-=\
    set isfname-=[
    let i = bufnr('^' . fileName . '$')
  finally
    let &isfname = _isf
  endtry

  " Somtimes the above function doesn't work, the fallback is the 
  " original function 'bufnr()'
  if i == -1
    let i = bufnr(a:fileName)
  endif
  return i
endfunction
" }}}
" {{{ FormatTable()
function! s:FormatTable(fieldName, fieldWidth, list)
  if empty(a:fieldName)
    return ''
  endif

  let fieldWidth = a:fieldWidth
  let end = empty(a:fieldWidth) ? 0 : len(a:fieldWidth) - 1
  let fend = end
  for i in reverse(range(len(a:fieldWidth)))
    if !(a:fieldWidth[i] == -1 || a:fieldWidth[i] == 0)
      let fend = i
      let fieldWidth = a:fieldWidth[ 0 : i ]
      break
    endif
  endfor

  let winwidth = &columns - (&l:nu ? &nuw : 0)
  if len(fieldWidth) < len(a:fieldName)
    let w = 0
    for fw in fieldWidth | let w += (fw < 0 ? -fw : fw) + 1 | endfor
    if w > 0 | let w -= 1 | endif
    let c = len(a:fieldName) - len(fieldWidth)
    if w < winwidth
      let fd = (winwidth - w) / c
      if empty(fieldWidth)
        call add(fieldWidth, fd)
        let c -= 1
      endif
      call extend(fieldWidth, repeat([fd-1], c))
    else
      call extend(fieldWidth, repeat([0], c))
    endif
  endif

  let sep = join(map(copy(fieldWidth), 'repeat("=", v:val < 0 ? -v:val : v:val)'), ' ')
  let fieldName = join(map(range(len(a:fieldName)), 's:Center(a:fieldName[v:val], fieldWidth[v:val] < 0 ? -fieldWidth[v:val] : fieldWidth[v:val])'), ' ')

  let table = [sep, fieldName, sep]

  if empty(a:list)
    return table + ['']
  endif

  for i in range(fend, end)
    if a:fieldWidth[i] == -1
      let fieldWidth[i] = -fieldWidth[i]
    elseif a:fieldWidth[i] == 0
      let fieldWidth[i] = 0
    endif
  endfor

  let fmt = join(map(copy(fieldWidth), 
        \ "'%' . (v:val == 0  ? '' :  v:val < 0 ? ('-' . (-v:val) . '.' . (-v:val)) : (v:val . '.' . v:val)) . 's'"), ' ')
  if !empty(fieldWidth) && fieldWidth[-1] < 0
    let fmt = substitute(fmt, '%[-1-9\.]\+s$', '%s', '')
  endif

  for row in a:list
    call add(table, call('printf', [fmt] + row))
  endfor
  return table
endfunction
" }}}
" {{{ Clear()
function! s:Clear()
  silent %d _
endfunction
" }}}
" {{{ Center()
function! s:Center(str, width)
  let width = a:width < 0 ? -a:width : a:width
  let len = strlen(a:str)
  if width <= len
    return a:str
  endif
  let sw = width - len
  let sp = repeat(' ', sw/2)
  return sp . a:str . sp . (sw % 2 == 0 ? '' : ' ')
endfunction
" }}}
" {{{ SID() - Get the SID for the current script
function! s:SID()
  if !exists('s:SID')
    let s:SID = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
  endif
  return s:SID
endfunction
" }}}
" {{{ ApplyAutoCmd() - Execute the command for specific event
" a:1 - default command
function! s:ApplyAutoCmd(event, args, ...) 
  let func = s:g_setting.Get(a:event, '')
  if !empty(func) && exists('*' . func)
    return call(func, a:args)
  elseif a:0 > 0
    return call(a:1, a:args)
  endif
endfunction
" }}}
" }}}1
" {{{1 Restore
let &cpo= s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
