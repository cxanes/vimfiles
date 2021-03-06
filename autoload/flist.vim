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

python3 << EOF

import vim
import re
import flist

def FlistUpdate(config, name_type = None):
  f = flist.Flist(config['name'], config['option'])
  f.dump(name_type)

EOF

let s:flist_cwd = ''

function! s:CheckDir(name) abort
  let dir = fnamemodify(a:name, ':h')
  if dir != '.' && empty(glob(dir))
    call mkdir(dir, 'p')
  elseif !isdirectory(dir)
    call s:ShowMesg(dir . ' exists and is not directory')
    throw 'error'
  endif
endfunction

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

function! s:GetConfig(...) abort
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

  let option = {}
  if a:0 > 1
    if type({}) != type(a:2)
      call s:ShowMesg('option must be dict')
    else
      let option = a:2
    endif
  elseif exists('g:flist_option')
    if type({}) != type(g:flist_option)
      call s:ShowMesg('g:flist_option must be dict')
    else
      let option = g:flist_option
    endif
  endif

  call s:CheckDir(name)

  return { 'name': name, 'option': option }
endfunction

function! flist#Update(...) abort
  let config = call('s:GetConfig', a:000)
  py3 FlistUpdate(vim.eval('config'))
endfunction

let s:max_retry = 10

function! s:Open(type, retry, ...) abort
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

  py3 vim.command("let fname = '%s'" % (re.sub(r"'", r"''", flist.get_fname(vim.eval('name'), vim.eval('a:type'))), ))

  if filereadable(fname)
    exec 'e' fnameescape(fname)
    return
  endif

  if a:retry >= s:max_retry
    call s:ShowMesg('cannot open ' . fname)
    return
  endif

  let config = call('s:GetConfig', [name])
  py3 FlistUpdate(vim.eval('config'), vim.eval('a:type'))
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
