" flist.vim
" Last Modified: 2012-02-28 06:51:45
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_flist')
  finish
endif
let loaded_flist = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

if !exists('g:flist_name')
  let g:flist_name = 'filelist.out'
endif

if !exists('g:flist_option')
  let g:flist_option = { 'default_pattern': '!cscope.*:!tags' }
endif

command! -narg=1 -complete=custom,flist#ListType FlistOpen call flist#Open(<q-args>)
command! FlistUpdate call flist#Update()

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
