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

if globpath(&rtp, 'autoload/gundo.vim') != ''
  function! s:GundoLoadAndRun()
    delcommand GundoToggle
    ru autoload/gundo.vim
    GundoToggle
  endfunction

  command! -nargs=0 GundoToggle call s:GundoLoadAndRun()
endif

if globpath(&rtp, 'autoload/cctree.vim') != ''
  function! s:FnameEscape(fname)
    if exists('*fnameescape')
      return fnameescape(a:fname)
    endif
    return escape(a:fname, " \t\n*?[{`$\\%#'\"|!<")
  endfunction

  function! s:CCTreeLoadAndRun(args)
    delcommand CCTreeLoadDB
    ru autoload/cctree.vim
    exec 'CCTreeLoadDB' s:FnameEscape(a:args)
  endfunction

  command! -nargs=? -complete=file CCTreeLoadDB  call s:CCTreeLoadAndRun(<q-args>)

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

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
