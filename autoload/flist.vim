" flist.vim
" Last Modified: 2012-02-28 02:49:13
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_flist')
  finish
endif
let loaded_autoload_flist = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

python << EOF

import vim
import re
import flist

def FlistUpdate(config, name_type = None):
  f = flist.Flist(config['name'], config['option'])
  f.add_pattern(config['pattern'])
  f.dump(name_type)

EOF

let s:flist_cwd = ''

function! s:ShowMesg(mesg, ...)
  let hl = a:0 == 0 ? 'WarningMsg' : a:1
  exe 'echohl ' . hl
  echom a:mesg
  echohl None
endfunction

let s:default_name = 'filelist.out'
if exists('g:flist_name')
  let s:default_name = g:flist_name
endif

function! s:GetConfig(...)
  let name = s:default_name
  if a:0 > 0
    if type('') != type(a:1)
      call s:ShowMesg('name must be string')
    else
      let name = a:1
    endif
  elseif exists('g:flist_name')
    if type('') != type(g:flist_name)
      call s:ShowMesg('g:flist_name must be string')
    else
      let name = g:flist_name
    endif
  endif

  let pattern = []
  if a:0 > 1
    if type([]) != type(a:2)
      call s:ShowMesg('pattern must be list')
    else
      let pattern = a:2
    endif
  elseif exists('g:flist_pattern')
    if type([]) != type(g:flist_pattern)
      call s:ShowMesg('g:flist_pattern must be list')
    else
      let pattern = g:flist_pattern
    endif
  endif

  let option = {}
  if a:0 > 2
    if type({}) != type(a:3)
      call s:ShowMesg('option must be dict')
    else
      let option = a:3
    endif
  elseif exists('g:flist_option')
    if type({}) != type(g:flist_option)
      call s:ShowMesg('g:flist_option must be dict')
    else
      let option = g:flist_option
    endif
  endif

  return { 'name': name, 'pattern': pattern, 'option': option }
endfunction

function! flist#Update(...)
  let config = call('s:GetConfig', a:000)
  py FlistUpdate(vim.eval('config'))
endfunction

let s:max_retry = 10

function! s:Open(type, retry, ...)
  if index(['pattern', 'option', 'filelist'], a:type) == -1
    call s:ShowMesg('invalid type: ' . string(a:type))
    return
  endif

  let name = s:default_name
  if a:0 > 0
    let name = a:1
  elseif exists('g:flist_name')
    let name = g:flist_name
  endif

  py vim.command("let fname = '%s'" % (re.sub(r"'", r"''", flist.get_fname(vim.eval('name'), vim.eval('a:type'))), ))

  if filereadable(fname)
    exec 'e' fnameescape(fname)
    return
  endif

  if a:retry >= 10
    call s:ShowMesg('cannot open ' + fname)
    return
  endif

  let config = call('s:GetConfig', [name])
  py FlistUpdate(vim.eval('config'), vim.eval('a:type'))
  call call('s:Open', [a:type, a:retry + 1] + a:000)
endfunction

function! flist#Open(type, ...)
  call call('s:Open', [a:type, 1] + a:000)
endfunction

let s:file_type = [ 'option', 'pattern', 'filelist' ]

function! flist#ListType(A, L, P)
  return join(s:file_type, "\n")
endfunction

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
