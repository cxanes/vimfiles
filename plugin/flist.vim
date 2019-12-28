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
  if exists('g:vim_resources_dir')
    let g:flist_name = g:vim_resources_dir . '/' . g:flist_name
  endif
endif

if !exists('g:flist_option') || exists("g:flist_option['default_pattern']")
  let g:flist_option = { 'default_pattern': '!cscope.*:!tags' }
endif

if exists('g:vim_resources_dir') && !empty(g:vim_resources_dir)
  let g:flist_option['default_pattern'] .= ':!' . g:vim_resources_dir
endif

command! -narg=1 -complete=custom,flist#ListType FlistOpen call flist#Open(<q-args>)
command! FlistUpdate call flist#Update()

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
