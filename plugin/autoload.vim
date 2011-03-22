" autoload.vim
" Last Modified: 2011-03-16 20:34:38
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Add autoload support for some plugins which doesn't support autoload.
" And you don't want to modify the source code of the plugin directly.

" Load Once {{{
if exists('loaded_autoload')
  finish
endif
let loaded_autoload = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

function! s:FnameEscape(fname)
  if exists('*fnameescape')
    return fnameescape(a:fname)
  endif
  return escape(a:fname, " \t\n*?[{`$\\%#'\"|!<")
endfunction

" Gundo : Visualize your undo tree
" http://www.vim.org/scripts/script.php?script_id=3304 {{{
if globpath(&rtp, 'autoload/gundo.vim') != ''
  function! s:GundoLoadAndRun()
    delcommand GundoToggle
    ru autoload/gundo.vim
    GundoToggle
  endfunction

  command! -nargs=0 GundoToggle call s:GundoLoadAndRun()
endif
"}}}
" CCTree : C Call-Tree Explorer
" http://www.vim.org/scripts/script.php?script_id=2368 {{{
if globpath(&rtp, 'autoload/cctree.vim') != ''
  function! s:CCTreeLoadAndRun(cmd, args)
    delcommand CCTreeLoadDB
    ru autoload/cctree.vim
    exec a:cmd s:FnameEscape(a:args)
  endfunction

  command! -nargs=? -complete=file CCTreeLoadDB  call s:CCTreeLoadAndRun('CCTreeLoadDB', <q-args>)
  command! -nargs=? -complete=file CCTreeLoadXRefDB  call s:CCTreeLoadAndRun('CCTreeLoadXRefDB', <q-args>)

  function! s:CCTreeLoadOnce() 
    ru autoload/cctree.vim
    au! CCTreeLoadOnce
    augroup! CCTreeLoadOnce
  endfunction

  augroup CCTreeLoadOnce
    au!
    au FileType c call s:CCTreeLoadOnce()|do CCTreeMaps FileType
    au FileType cpp call s:CCTreeLoadOnce()|do CCTreeMaps FileType
  augroup END
endif
"}}}
" DirDiff.vim : A plugin to diff and merge two directories recursively.
" http://www.vim.org/scripts/script.php?script_id=102 {{{
if globpath(&rtp, 'autoload/DirDiff.vim') != ''
  function! s:DirDiffLoadAndRun(srcA, srcB)
    delcommand DirDiff
    ru autoload/DirDiff.vim
    exec 'DirDiff' s:FnameEscape(a:srcA) s:FnameEscape(a:srcB)
  endfunction

  command! -nargs=* -complete=dir DirDiff call s:DirDiffLoadAndRun(<f-args>)
endif
"}}}

" calendar.vim : Calendar
" http://www.vim.org/scripts/script.php?script_id=52 {{{
if globpath(&rtp, 'autoload/calendar.vim') != ''
  function! s:CalendarLoadAndRun(...)
    delcommand Calendar
    delcommand CalendarH
    ru autoload/calendar.vim
    call call('Calendar', a:000)
  endfunction

  command! -nargs=* Calendar  call s:CalendarLoadAndRun(0,<f-args>)
  command! -nargs=* CalendarH call s:CalendarLoadAndRun(1,<f-args>)
endif
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :