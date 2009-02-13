" File: autoload/myutils.vim
" Author: Frank Chang (frank.nevermind AT gmail.com)
" Version: 1.0
" Last Modified: 2008-07-16 22:21:30
"
" My own defined functions and mappings (autoload)
"
" {{{ Load Once
if exists('myutils_autoload_plugin')
  finish
endif
let myutils_autoload_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
" }}}
"==============================================================
" {{{1 Utilities
"--------------------------------------------------------------
function! s:SID() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
"}}}
"==========================================================}}}1
" {{{1 Global Variable
"--------------------------------------------------------------
let s:MSWIN = has('win16') || has('win32') || has('win64') || 
          \   has('win95') || has('win32unix')
"==========================================================}}}1
"==============================================================
" {{{1 CppComplete-related Functions
"--------------------------------------------------------------
function! myutils#CppCompleteInit() "{{{
  call omni#cpp#complete#Init()
  inoremap <expr> . myutils#CppMayCompleteDot()
  inoremap <expr> > myutils#CppMayCompleteArrow()
  inoremap <expr> : myutils#CppMayCompleteScope()
endfunction
"}}}
function! myutils#CppMayCompleteDot() "{{{
  if has('syntax_items') 
        \ && synIDattr(synID(line('.'), col('.'), 1), "name") =~? '\(Comment\|String\)$'
    return '.'
  endif
  return omni#cpp#maycomplete#Dot()
endfunction
"}}}
function! myutils#CppMayCompleteArrow() "{{{
  if has('syntax_items') 
        \ && synIDattr(synID(line('.'), col('.'), 1), "name") =~? '\(Comment\|String\)$'
    return '>'
  endif
  return omni#cpp#maycomplete#Arrow()
endfunction
"}}}
function! myutils#CppMayCompleteScope() "{{{
  if has('syntax_items') 
        \ && synIDattr(synID(line('.'), col('.'), 1), "name") =~? '\(Comment\|String\)$'
    return ':'
  endif
  return omni#cpp#maycomplete#Scope()
endfunction
" }}}
"==========================================================}}}1
" {{{1 Seq: Insert a list of number (the same options as seq)
"--------------------------------------------------------------
function! myutils#Seq(...) "{{{
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
"==========================================================}}}1
" {{{1 GetOptVals(opt): Get possible values of given option (opt)
"--------------------------------------------------------------
function! myutils#GetOptVals(opt) 
  let opt = substitute(tolower(a:opt), '^\s\+\|\s\+$', '', 'g')
  if opt == ''
    return []
  endif

  let c = opt[0]

  if     c == 'a' " {{{
    if     opt == 'ambiwidth'  || opt == 'ambw'
      return ['single', 'double']
    endif
    " }}}
  elseif c == 'b' " {{{
    if     opt == 'backspace'  || opt == 'bs'
      return ['indent', 'eol', 'start']
    elseif opt == 'backupcopy' || opt == 'bkc'
      return ['yes', 'no', 'auto']
    elseif opt == 'bufhidden'  || opt == 'bh'
      return ['hide', 'unload', 'delete', 'wipe']
    elseif opt == 'browsedir'  || opt == 'bsdir'
      return ['last', 'buffer', 'current']
    elseif opt == 'buftype'    || opt == 'bt'
      return ['nofile', 'nowrite', 'acwrite', 'quickfix', 'help']
    elseif opt == 'background' || opt == 'bg'
      return ['dark', 'light']
    endif
    " }}}
  elseif c == 'c' " {{{
    if     opt == 'casemap'     || opt == 'cmp'
      return ['internal', 'keepascii']
    elseif opt == 'clipboard'   || opt == 'cb'
      return ['unnamed', 'autoselect', 'autoselectml', 'exclude']
    endif
    " }}}
  elseif c == 'd' " {{{
    if     opt == 'diffopt'      || opt == 'dip'
      return ['filler', 'context', 'icase', 'iwhite', 'horizontal', 'vertical', 'foldcolumn']
    elseif opt == 'display'      || opt == 'dy'
      return ['lastline', 'uhex']
    endif
    " }}}
  elseif c == 'e' " {{{
    if     opt == 'eadirection'  || opt == 'ead'
      return ['ver', 'hor', 'both']
    endif
    " }}}
  elseif c == 'f' " {{{
    if     opt == 'foldmethod' || opt == 'fdm'
      return ['marker', 'manual', 'indent', 'expr', 'syntax', 'diff']
    elseif opt == 'foldopen'   || opt == 'fdo'
      return ['all', 'block', 'hor', 'insert', 'jump', 'mark', 'percent', 'quickfix', 'search', 'tag', 'undo']
    elseif opt == 'fileformat' || opt == 'ff'
      return ['dos', 'unix', 'mac']
    elseif opt == 'fillchars'  || opt == 'fcs'
      return ['stl', 'stlnc', 'vert', 'fold', 'diff']
    endif
    " }}}
  elseif c == 'l' " {{{
    if    opt == 'listchars'  || opt == 'lcs'
      return ['eol', 'tab', 'trail', 'extend', 'precedes', 'nbsp']
    endif
    " }}}
  elseif c == 'm' " {{{
    if    opt == 'mousemodel' || opt == 'mousem'
      return ['extend', 'popup', 'popup_setpos']
    endif
    " }}}
  elseif c == 'n' " {{{
    if    opt == 'nrformats'  || opt == 'nf'
      return ['alpha', 'octal', 'hex']
    endif
    " }}}
  elseif c == 's' " {{{
    if     opt == 'selection'  || opt == 'sel'
      return ['inclusive', 'exclusive', 'old']
    elseif opt == 'scrollopt'  || opt == 'sbo'
      return ['ver', 'hor', 'jump']
    elseif opt == 'selectmode' || opt == 'slm'
      return ['mouse', 'key', 'cmd']
    elseif opt == 'sessionoptions' || opt == 'ssop'
      return ['blank', 'buffers', 'curdir', 'folds', 'globals', 'help', 'localoptions', 'options', 'resize', 'sesdir', 'slash', 'tabpages', 'unix', 'winpos', 'winsize']
    elseif opt == 'spellsuggest' || opt == 'sps'
      return ['best', 'double', 'fast', 'file', 'expr']
    elseif opt == 'switchbuf'  || opt == 'swb'
      return ['useopen', 'usetab', 'split', 'newtab']
    endif
    " }}}
  elseif c == 't' " {{{
    if     opt == 'toolbar' || opt == 'tb'
      return ['icons', 'text', 'horiz', 'tooltips']
    elseif opt == 'toolbariconsize' || opt == 'tbis'
      return ['tiny', 'small', 'medium', 'large']
    elseif opt == 'ttymouse' || opt == 'ttym'
      return ['xterm', 'xterm2', 'netterm', 'dec', 'jsbterm', 'pterm']
    endif
    " }}}
  elseif c == 'v' " {{{
    if     opt == 'viewoptions' || opt == 'vop'
      return ['cursor', 'folds', 'options', 'slash', 'unix']
    elseif opt == 'virtualedit' || opt == 've'
      return ['block', 'insert', 'all', 'onemore']
    endif
    " }}}
  elseif c == 'w' " {{{
    if     opt == 'wildmode'    || opt == 'wim'
      return ['full', 'longest', 'longest:full', 'list', 'list:full', 'list:longest']
    elseif opt == 'winaltkeys'  || opt == 'wak'
      retur ['no', 'yes', 'menu']
    endif
    " }}}
  endif

  return []
endfunction
"==========================================================}}}1
" {{{1 ShowMatch: Show all lines which the pattern matches
"      NOTE: :vimgrep /pattern/ %|copen 
"            may do the same job (except using file).
"--------------------------------------------------------------
function! myutils#ShowMatch(...) "{{{
  let pattern = a:0 > 0 ? a:1 : ('\<' . expand('<cword>') . '\>')
  if pattern == ''
    return
  endif

  let output = ''
  redir => output
  exe printf('silent! g/%s/num', escape(pattern, '/'))
  redir END

  if output =~ '^\_s*E486:'
    echohl ErrorMsg | echo output | echohl None
    return
  endif

  let curwinnum = winnr()
  let winnum = CreateTempBuffer('-MatchPreview-')

  exe winnum . 'wincmd w'
  silent %d _
  silent! put =output
  g/^\s*$/d

  syn clear
  syn match Number '^\s*\d\+'
  let pattern = "'" . escape(pattern, "'") . "'"
  exe "syn match Special " . pattern
  exe "nmap <buffer> <silent> <CR> :call <SID>ShowMatchGoToLine(" . substitute(pattern, '<', '<lt>', 'g') . "," . curwinnum ")<CR>"
endfunction
" }}}
function! s:ShowMatchGoToLine(pattern, winnum) "{{{
  let lnum = str2nr(matchstr(getline('.'), '^\s*\zs\d\+'))
  if lnum > 0
    exe a:winnum . 'wincmd w'
    call cursor(lnum, 1)
    call search(a:pattern, 'c', lnum)
  endif
endfunction
" }}}
"==========================================================}}}1
"==============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
