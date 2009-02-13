" EmacsModeDetect.vim
" Last Modified: 2008-09-18 17:21:02
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Detect Emacs mode form local variables in files.
"
" Ref: GNU Emacs Manual: 57.3.4 Local Variables in Files
"      emacs/lisp/files.el

" Load Once {{{
if exists('loaded_EmacsModeDetect')
  finish
endif
let loaded_EmacsModeDetect = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

" 0: Stop detecting Emacs mode.
" 1: Detect Emacs mode if 'filetype' is not set.
" 2: Always detect Emacs mode.
if !exists('g:EmacsModeDetect')
  let g:EmacsModeDetect = 1
endif

augroup EmacsModeDetect
  au BufWinEnter * 
        \ if exists('g:EmacsModeDetect') && g:EmacsModeDetect > 0
        \      && (!exists('b:EmacsModeDetect') || b:EmacsModeDetect == 0) |
        \   call <SID>EmacsModeDetect(g:EmacsModeDetect >= 2) |
        \   let b:EmacsModeDetect = 1 |
        \ endif
augroup END

" If 'filetype' is set, we don't detect the mode again,
" unless 'force' is true.
function! s:EmacsModeDetect(force) "{{{
  if ! (empty(&ft) || a:force)
    return
  endif

  if search('\S', 'nw') == 0
    return
  endif

  for type in [1, 2]
    let mode = s:EmacsGetMode{type}(s:EmacsGetFileVariables{type}())
    if mode != ''
      let &ft = s:EmacsMode2Filetype(mode)
      return
    endif
  endfor
endfunction
"}}}
function! s:EmacsMode2Filetype(mode) "{{{
  let mode = tolower(a:mode)
  let ft = ''

  if exists('g:EmacsMode') && type(g:EmacsMode) == type({})
    let ft = get(g:EmacsMode, mode, '')
  endif

  if ft != ''
    return ft
  endif

  if mode == 'c++'
    return 'cpp'
  else
    return mode
  endif
endfunction
"}}}
" Format: 
"    -*- mode: modename; var: value; ... -*-
"
"      or
"
"    -*-modename-*-
"
" Example: 
"    ;; -*- mode: Lisp; fill-column: 75; comment-column: 50; -*-
"
"      or 
"
"    ;; -*-Lisp-*-
"
" Return: 
"    ['mode: Lisp; fill-column: 75; comment-column: 50;']
"
"      or
"
"    ['Lisp']
function! s:EmacsGetFileVariables1() "{{{
  let variables = []

  let lnum = nextnonblank(1)
  if lnum == 0
    return variables
  endif

  let lines = [getline(lnum)]
  if lines[0] =~ '^#!'
    let lnum = nextnonblank(lnum)
    if lnum != 0
      call add(lines, getline(lnum))
    endif
  endif

  for line in lines
    let vbeg = matchend(line, '-\*-')
    if vbeg == -1
      continue
    endif

    let vend = match(line, '-\*-', vbeg)
    if vend == -1
      continue
    endif

    call add(variables, substitute(line[vbeg : (vend-1)], '^\s\+\|\s\+$', '', 'g'))
  endfor

  return variables
endfunction
"}}}
function! s:EmacsGetMode1(variables) "{{{
  for variables in a:variables
    let variables = substitute(variables, '^\s\+\|\s\+$', '', 'g')

    if stridx(variables, ':') == -1
      return tolower(variables)
    endif

    let mode = substitute(matchstr(variables, '^mode:\s*\zs[^;]\+'), '\s\+$', '', '')
    if mode != ''
      return tolower(mode)
    endif

    let mode = substitute(matchstr(variables, '[ \t;]mode:\s*\zs[^;]\+'), '\s\+$', '', '')
    if mode != ''
      return tolower(mode)
    endif
  endfor

  return ''
endfunction
"}}}
" Format:
"    {prefix} Local Variables: {suffix}
"    {prefix} mode: modename {suffix}
"    {prefix} var: value {suffix}
"    {prefix} ... {suffix}
"    {prefix} End: {suffix}
"
" Example: 
"    ;; Local Variables: **
"    ;; mode:lisp **
"    ;; comment-column:0 **
"    ;; comment-start: ";; "  **
"    ;; comment-end:"**" **
"    ;; End: **
"
" Return:
"   ['mode:lisp', 'comment-column:0', 'comment-start: ";; "', comment-end:"**"']
function! s:EmacsGetFileVariables2() "{{{
  let pos = getpos('.')
  call cursor(line('$'), 1)
  call cursor(line('.'), col('$'))
  try
    let min_lnum = max([byte2line(line2byte(line('$')+1)-3000), 1])
    let [lnum, col] = searchpos('\n', 'Wcnbe', min_lnum)
    if lnum == 0
      let lnum = min_lnum
    endif
    call cursor(lnum, 1)
    let [lnum, col] = searchpos('Local Variables:', 'cnW')
    if lnum == 0
      return []
    endif

    let vbeg = lnum
    call cursor(vbeg, 1)
    let [line, prefix, suffix; dummy] = matchlist(getline('.'), '^\(.\{-}\)Local Variables:\s*\(.\{-}\)$')

    let prefix = '^' . (prefix != '' ? ('\V' . escape(prefix, '\') . '\m') : '')
    let suffix = (suffix != '' ? ('\V' . escape(suffix, '\') . '\m') : '') . '$'

    let end_pat = prefix . '\s*End:\s*' . suffix

    let [lnum, col] = searchpos(end_pat, 'cnW')
    if lnum == 0
      return []
    endif

    let vend = lnum

    " if vbeg + 1 > vend - 1
    if vend - vbeg < 2
      return []
    endif

    let variables = []
    for lnum in range(vbeg + 1, vend - 1)
      let m = matchlist(getline(lnum), prefix . '\(.\{-}\)' . suffix)
      if empty(m)
        return []
      endif
      call add(variables, substitute(m[1], '^\s\+\|\s\+$', '', 'g'))
    endfor
    return variables
  finally
    call setpos('.', pos)
  endtry
endfunction
"}}}
function! s:EmacsGetMode2(variables) "{{{
  for variable in a:variables
    let m = matchlist(variable, '^\s*\([^:]\+\):\s*\(.*\)$')
    if !empty(m) && substitute(m[1], '\s\+$', '', 'g') == 'mode'
      return tolower(substitute(m[2], '\s\+$', '', 'g'))
    endif
  endfor
  return ''
endfunction
"}}}

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
