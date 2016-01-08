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

" Command:
"
"   :StartNoteManager [db]   Start NoteManager using database 'db'
"                            Default is defined by 'g:NoteManager_DbFile'
"                            All databases are in the directory 'g:NoteManager_Dir',
"                            unless 'g:NoteManager_DbFile' is a absolute path.
"
"   :StopNoteManager         Stop NoteManager
"
"
"   In NoteManager mode:
"
"     :NMGetNote [id|query]    {id} is the ID of note. {query} will show all notes that
"                            meet the search criteria. No argument will get a new note.
"     :NMShowPanel             Show the panel
"
"   In Note panel:
"
"     :NMExportNote[!] {file}  Export saved note to {file}
"                            Add ! to overwrite an existing file.
"
" Global Settings:
"
"   1. g:NoteManager_MaxNumQuery (default: 10)
"      The maximum number of queries stored in the history
"
"   2. g:NoteManager_DbFile (default: "notes.db")
"      The database used to store notes
"
"   3. g:NoteManager_Dir (default: "$HOME/notes")
"      The directory containing all files used by NoteManager
"      The directory must exist when using NoteManager. 
"
"   4. g:NoteManager_FileType (default: "rst")
"      The filetype of note (used for highlighting)
"
"   5. g:NoteManager_Query (default: "Today")
"      The default query of note list
"
" After starting NoteManager, press <F1> for help.
" NoteManager stores text in UTF-8.
"
" *NOTE* Each Vim can start only one NoteManager.
"
" {{{1 This script requires Vim 7.0 (or later) and SQLite 3.0 (or later)
if v:version < 700
  echohl ErrorMsg
  echom 'NoteManager plugin requires Vim 7.0 or later'
  echohl None
  finish
endif
" }}}1
" {{{1 Load Once
if exists('loaded_note_manager')
  finish
endif
let loaded_note_manager = 1
let s:save_cpo = &cpo
set cpo&vim
" }}}1

let s:default_setting = {
      \ 'MaxNumQuery': 10,
      \ 'DbFile'     : 'notes.db',
      \ 'Dir'        : $HOME . '/notes',
      \ 'FileType'   : 'rst',
      \ 'Query'      : 'Today',
      \ 'NoteRead'   : '',
      \ 'NoteWrite'  : '',
      \ 'NoteLeave'  : '',
      \ 'NoteExport' : '',
      \ 'PanelCreate': '',
      \ 'PanelDelete': '',
      \ 'NoteManagerEnter' : '',
      \ 'NoteManagerLeave' : '',
      \ }

" {{{ NewSetting()
function! s:NewSetting(...) 
  let setting = {}
  for var in keys(s:default_setting)
    let setting[var] = exists('g:NoteManager_' . var) ? eval('g:NoteManager_' . var) : s:default_setting[var]
  endfor
  if a:0 > 0 && type(a:1) == type({})
    for var in keys(a:1)
      let setting[var] = a:1[var]
    endfor
  endif
  return setting
endfunction
" }}}
" {{{ ShowMesg()
function! s:ShowMesg(mesg, ...)
  let hl = a:0 == 0 ? 'WarningMsg' : a:1
  exe 'echohl ' . hl
  echom 'NoteManager: ' . a:mesg
  echohl None
endfunction
" }}}
" {{{ ShowSetting()
function! s:ShowSetting(config, setting)
  if type(a:setting) == type({})
    echo '[' . a:config . ']'
    for var in sort(copy(keys(a:setting)))
      echo var . '=' . string(a:setting[var])
    endfor
  endif
endfunction
" }}}
" {{{ CheckSetting()
function! s:CheckSetting(setting) 
  if type(a:setting) != type({})
    call s:ShowMesg('Invalid configuration: Dictionary required', 'ErrorMsg')
    return 1
  endif

  if ! (has_key(a:setting, 'DbFile') && has_key(a:setting, 'Dir'))
    call s:ShowMesg('The configuration must contain settings "DbFile" and "Dir"', 'ErrorMsg')
    return 1
  endif

  return 0
endfunction
" }}}
" {{{ StartNoteManager()
function! s:StartNoteManager(config) 
  if s:SetupConfig() == 1
    return
  endif

  let show_setting = 0
  let config = a:config
  if config =~ '?$'
    let show_setting = 1
    let config = substitute(config, '?$', '', '')
  endif

  if empty(config)
    let config = 'default'
  endif
    
  if !has_key(g:NoteManager_Config, config)
    call s:ShowMesg('The configuration "' . config . '" doesn''t exist', 'ErrorMsg')
    return
  elseif type(g:NoteManager_Config[config]) != type({})
    call s:ShowMesg('The configuration "' . config . '" is not a valid type: Dictionary required', 'ErrorMsg')
    return
  endif

  if s:CheckSetting(g:NoteManager_Config[config]) == 1
    return
  endif

  if show_setting
    call s:ShowSetting(config, g:NoteManager_Config[config])
  else
    call NoteManager#StartNoteManager(s:NewSetting(g:NoteManager_Config[config]))
  endif
endfunction
" }}}
" {{{ ListConfigs()
function! s:ListConfigs(A,L,P)
  if !exists('g:NoteManager_Config') || type(g:NoteManager_Config) != type({})
    return ''
  endif

  return join(keys(g:NoteManager_Config), "\n")
endfun
" }}}
" {{{ SetupConfig()
function! s:SetupConfig()
  if exists('g:NoteManager_Config') && type(g:NoteManager_Config) != type({})
    call s:ShowMesg('The type of g:NoteManager_Config is invalid: Dictionary required', 'ErrorMsg')
    return 1
  endif

  if !exists('g:NoteManager_Config')
    let g:NoteManager_Config = {}
  endif
  if !has_key(g:NoteManager_Config, 'default')
    let g:NoteManager_Config['default'] = s:NewSetting()
  endif

  return 0
endfunction
" }}}
call s:SetupConfig()
" {{{1 Command Definitions 
" command! -narg=? -complete=file StartNoteManager call NoteManager#StartNoteManager(<q-args>)
command! -narg=? -complete=custom,s:ListConfigs StartNoteManager call s:StartNoteManager(<q-args>)
command! -narg=0 StopNoteManager  call NoteManager#StopNoteManager()
" }}}1
" {{{1 Restore
let &cpo= s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
