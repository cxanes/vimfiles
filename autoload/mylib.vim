" mylib.vim
" Last Modified: 2009-05-28 21:54:06
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_mylib')
  finish
endif
let loaded_autoload_mylib = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"========================================================================
" {{{ mylib#SelectAll <$VIMRUNTIME/menu.vim>
function! mylib#SelectAll()
  exe 'norm gg' . (&slm == '' ? 'VG' : "gH\<C-O>G")
endfunction
" }}}
" {{{ mylib#ShowMesg()
function! mylib#ShowMesg(group, mesg, ...) 
  exec 'echohl' a:group
  if a:0 > 0 && !empty(a:1)
    echom a:mesg
  else
    echo a:mesg
  endif
  echohl None
endfunction
" }}}
" {{{ mylib#GetPos(): Get the position of the cursor on the screen.
"
"   This is a trial-and-error function based on fixed font size.
"   Windows version: set guifont=Consolas:h9:w5

" trial-and-error: set guifont=Consolas:h9:w5
let s:gui_setting = {
      \ 'tabpage_gui_line_height' : 19,
      \ 'tabpage_text_line_height': 15,
      \ 'font_width'              :  7,
      \ 'vert_scrollbar_width'    : 13,
      \ 'font_height'             : 15,
      \ 'menu_height'             : 19,
      \ 'title_height'            : 10,
      \ 'toolbar_height'          : 30,
      \ }
  
function! mylib#GetPos() "{{{
  let nline = winline() + 1
  let ncol  = wincol() - 1

  let orgwin = winnr()
  let curwin = orgwin
  wincmd k
  while curwin != winnr()
    let nline += winheight(0) + 1
    let curwin = winnr()
    wincmd k
  endwhile

  exe orgwin . "wincmd w"
  let curwin = orgwin
  wincmd h
  while curwin != winnr()
    let ncol += winwidth(0) + 1
    let curwin = winnr()
    wincmd h
  endwhile

  exe orgwin . "wincmd w"
  let pos = {'x': getwinposx(), 'y' : getwinposy()}

  let pos.x += ncol * s:gui_setting['font_width'] + 6
        \ + (&columns != winwidth(0) ? s:gui_setting['vert_scrollbar_width'] : 0)

  if &showtabline == 2 || ( tabpagenr('$') > 1 && &showtabline == 1 )
    let pos.y += stridx(&guioptions, 'e') != -1 
          \ ? s:gui_setting['tabpage_gui_line_height']
          \ : s:gui_setting['tabpage_text_line_height']
  endif

  let pos.y += nline * s:gui_setting['font_height'] + s:gui_setting['title_height']

  if stridx(&guioptions, 'm') != -1
    let pos.y += s:gui_setting['menu_height']
  endif

  if stridx(&guioptions, 'T') != -1
    let pos.y += s:gui_setting['toolbar_height']
  endif

  return pos
endfunction
"}}}
" }}}
" {{{ mylib#AddOptFiles()
function! mylib#AddOptFiles(opt, files)
  if type(a:files) == type('') && !empty(a:files)
    let files = [a:files]
  elseif type(a:files) == type([]) && !empty(a:files)
    let files = a:files
  else
    return
  endif

  for file in files
    if file =~ '^[a-zA-Z]:/' || file =~ '^/'
      let path = file
    else
      let path = globpath(&rtp, file)
    endif
    if path != ''
      exe 'setl ' . a:opt . '+=' . substitute(split(path,'\n')[0], '[ ,\\]', '\\\\\\&', 'g')
    endif
  endfor
endfunction
" }}}
" {{{ mylib#LiteralPattern()
function! mylib#LiteralPattern(pat)
  return '\V' . escape(a:pat, '\') . (&magic ? '\m' : '\M')
endfunction
" }}}
" {{{ mylib#SearchApply()
function! mylib#SearchApply(pat, func)
  let total = line('$')
  let lnum = 1
  while lnum <= total
    call substitute(getline(lnum), a:pat, '\=call(a:func, [submatch(0)])', 'g')
    let lnum += 1
  endwhile
endfunction
" }}}
" {{{ mylib#GetSelection()
function! mylib#GetSelection()
  let s_sav = @s
  let @s = ''

  normal gv"sy

  let s = @s
  let @s = s_sav

  return s
endfunction
" }}}
" {{{ mylib#Retab()
function! mylib#Retab(text, ts)
  let text = a:text
  let ts = a:ts + 0
  while match(text, '\t') != -1
    let text = substitute(text, '^\([^\t]*\)\(\t\+\)', 
          \ . '\=submatch(1).repeat(" ", strlen(submatch(2))*'
          \ . ts . '-strlen(submatch(1))%' . ts . ')', '')
  endwhile
  return text
endfunction
" }}}
" mylib#Shellescape() {{{
function! mylib#Shellescape(string, ...) " ... = special
  if &sh =~ '\%(\<command\.com\|\<cmd\.exe\|\<cmd\)$'
        \ && exists('+shellslash') && &ssl
    set nossl
    if a:0
      let string = shellescape(a:string, a:1)
    else
      let string = shellescape(a:string)
    endif
    set ssl
  else
    if a:0
      let string = shellescape(a:string, a:1)
    else
      let string = shellescape(a:string)
    endif
  endif

  if &sh =~ '\%(\<command\.com\|\<cmd\.exe\|\<cmd\)$'
        \ && string !~ '\s'
    let string = substitute(string, '^"\(.*\)"$', '\1', '')
  endif

  return string
endfunction
"}}}
" mylib#ParseCmdArgs() {{{
function! mylib#ParseCmdArgs(line)
  let qstr_pat  = '\%(''\%(\%(''''\)\+\|[^'']\+\)*''\)'
  let qqstr_pat = '\%("\%(\%(\\.\)\+\|[^"\\]\+\)*"\)'
  let cstr_pat  = '\%(\%(\%(\\[\\ \t]\)\+\|[^\\ \t]\+\)\+\)'
  let str_pat = printf('^\%%(%s\|%s\|%s\)', qstr_pat, qqstr_pat, cstr_pat)
  let line = substitute(a:line,  '^\s\+\|\s\+$', '', 'g')
  let args = []
  while !empty(line)
    let idx = matchend(line, str_pat)
    if idx == -1
      break
    endif
    let arg = line[ : (idx-1)]
    if stridx('''"', arg[0]) != -1
      let arg = eval(arg)
    else
      let arg = substitute(arg, '\\\([\\ \t]\)', '\1', 'g')
    endif
    call add(args, arg)
    let line = substitute(line[idx : ], '^\s\+', '', '')
  endwhile
  return args
endfunction
"}}}
" mylib#If2() {{{
function! mylib#If2(x, y)
  return empty(a:x) ? a:y : a:x
endfunction
"}}}
" mylib#Seq() {{{
function! mylib#Seq(...)
  let format = "%d"
  let separator = "\n"
  let [first, increment, last] = [1, 1, 1]

  let argv = copy(a:000)
  while !empty(argv)
    let opt = remove(argv, 0)
    if opt =~ '^-f'
      let val = matchstr(opt, '^-f\zs.*')
      if val == ''
        if empty(argv)
          echohl ErrorMsg | echo 'option requires an argument -- f' | echohl None
          return
        else
          let format = remove(argv, 0)
        endif
      else
        let format = val
      endif
    elseif opt =~ '^-s'
      let val = matchstr(opt, '^-s\zs.*')
      if val == ''
        if empty(argv)
          echohl ErrorMsg | echo 'option requires an argument -- s' | echohl None
          return ''
        else
          let separator = remove(argv, 0)
        endif
      else
        let separator = val
      endif
    elseif opt =~ '^-h'
      echo 'Usage: Seq [OPTION]... LAST'
      echo '  or:  Seq [OPTION]... FIRST LAST'
      echo '  or:  Seq [OPTION]... FIRST INCREMENT LAST'
      echo 'Print numbers from FIRST to LAST, in steps of INCREMENT.'
      echo "\n"
      echo '  -f  use printf style FORMAT'
      echo '  -s  use STRING to separate numbers (default: \n)'
      echo '  -h  print this help'
      echo "\n"
      echo 'If FIRST or INCREMENT is omitted, it defaults to 1.'
      return ''
    elseif opt =~ '^-[^\-]'
      echohl ErrorMsg
      echo 'invalid option -- ' . matchstr(opt, '^-\zs[^\-]\ze')
      echohl None
      return ''
    else
      call insert(argv, opt)
      break
    endif
  endwhile

  if empty(argv)
    echohl ErrorMsg | echo 'missing operand' | echohl None
    return ''
  endif

  let len = len(argv)
  if len > 3
    echohl ErrorMsg | echo "extra operand '" . argv[3] . "'" | echohl None
    return ''
  endif

  for val in argv
    if val !~ '^-\?\d\+$'
      echohl ErrorMsg | echo "invalid number argument: " . val | echohl None
      return ''
    endif
  endfor

  if len == 1
    let last = argv[0]
  elseif len == 2
    let[first, last] = argv[0 : 1]
  elseif len == 3
    let[first, increment, last] = argv[0 : 2]
  endif

  let seq = []
  if last >= first && increment > 0
    for val in range(first, last, increment)
      try
        call add(seq, printf(format, val))
      catch
        echohl ErrorMsg | echo "invalid format string: " . format | echohl None
        return ''
      endtry
    endfor
  endif

  return join(seq, separator)
endfunction
"}}}
" mylib#CNewLine() {{{
function! mylib#CNewLine()
  let newline = "\<C-O>o"

  let ch = getline('.')[col('.')-2]
  if col('.') == 1 || stridx(';`', ch) == -1
    return newline
  endif

  if has('syntax_items')
        \ && synIDattr(synID(line('.'), col('.'), 0), 'name') =~? 'string\|comment'
    return newline
  endif

  if ch == ';' && getline('.') =~ '\<for\s*('
    return newline
  endif

  return "\<BS>\<End>;" . (ch == ';' ? "\<CR>" : '')
endfunction
"}}}
" mylib#Calc() {{{
function! mylib#Calc(expr, ...) " ... = [modules]
  if !has('python')
    call mylib#ShowMesg('ErrorMsg', 'Calc: python not support', 1)
    return
  endif

  if a:0 > 0 && type(a:1) == type([])
    for module in a:1
      silent! exec 'py import ' . module
    endfor
  endif
  let result = ''
  python <<EOF
import vim
from math import *
vim.command("let result = '%s'" % str(eval(vim.eval('a:expr'))).replace("'", "''"))
EOF
  return result
endfunction
"}}}
" mylib#CanSkip() {{{
function! mylib#CanSkip(lnum, col)
  if has('syntax_items')
    return synIDattr(synID(a:lnum, a:col, 0), 'name') =~? 'string\|comment'
  endif
  return 0
endfunction
" }}}
" mylib#StripSurrounding() {{{
function! mylib#StripSurrounding(start, middle, end, ...) " ... = skip {{{
  let skip = a:0 > 0 ? a:1 : 'mylib#CanSkip(line(''.''), col(''.''))'
  let [lnum, col] = searchpairpos(a:start, a:middle, a:end, 'nbW', skip)
  if [lnum, col] == [0, 0]
    return [0, 0]
  endif

  call cursor(lnum, col)
  call searchpair(a:start, a:middle, a:end, 'W', skip)
  let pat = @/
  exe 's/' . '\%#' . substitute(a:end, '/', '\\/', 'g') . '//'
  call cursor(lnum, col)
  exe 's/' . '\%#' . substitute(a:start, '/', '\\/', 'g') . '//'
  call cursor(lnum, col)
  let @/ = pat
  return [lnum, col]
endfunction
"}}}
"}}}
"========================================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
