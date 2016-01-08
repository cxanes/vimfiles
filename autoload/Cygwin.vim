" Cygwin.vim
" Last Modified: 2009-11-08 12:44:38
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_Cygwin')
  finish
endif
let loaded_autoload_Cygwin = 1

" Only for Win32
let s:MSWIN =  has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')
if !s:MSWIN
  unlet s:MSWIN
  finish
end

let s:save_cpo = &cpo
set cpo&vim
"}}}
function! Cygwin#PrependEnv(env, path, is_cyg) "{{{
  let env  = Cygwin#ChangePath(a:env,  a:is_cyg)
  let path = Cygwin#ChangePath(a:path, a:is_cyg)

  let path_sep = a:is_cyg ? ':' : ';'
  if empty(path)
    return env
  endif
  return join(path, path_sep) . (empty(env) ? '' : (path_sep . env))
endfunction
"}}}
function! Cygwin#ChangePath(path, is_cyg) "{{{
  if type(a:path) == type([])
    let path = a:path
    return map(path, 'Cygwin#ChangePath(v:val, a:is_cyg)')
  elseif type(a:path) == type('')
    if a:is_cyg
      if s:IsCygpath(a:path)
        return a:path
      else
        let old_sep = ';'
        let new_sep = ':'
        let Change_func = function('s:Cygpath')
      endif
    else
      if !s:IsCygpath(a:path)
        return a:path
      else
        let old_sep = ':'
        let new_sep = ';'
        let Change_func = function('s:Winpath')
      endif
    endif

    return join(map(split(a:path, old_sep, 1), 'Change_func(v:val)'), new_sep)
  else
    return ''
  endif
endfunction
"}}}
function! s:IsCygpath(path) "{{{
  return a:path !~ '\%(^\|;\)[a-zA-Z]:[\\/]'
endfunction
"}}}
function! s:Cygpath(path) "{{{
  let path = tr(a:path, '\', '/')
  let path = substitute(path, '^\([a-zA-Z]\):', '/cygdrive/\u\1', '')
  return path
endfunction
"}}}
function! s:Winpath(path) "{{{
  let path = substitute(a:path, '^/cygdrive/\([^/]\)/', '\u\1:/', '')
  return path
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
