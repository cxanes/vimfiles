" SourceNavigator.vim
" Last Modified: 2009-03-22 23:49:29
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_SourceNavigator')
  finish
endif
let loaded_SourceNavigator = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

" GVIM --servername SN -u NORC --cmd "if v:servername=='SN'|ru _vimrc|el|se lpl|en" --remote-silent "+cal cursor(%l, %c+1)" "%f"

command! -nargs=1 SNStart call SourceNavigator#Start(<args>)
command! -nargs=0 SNStop  call SourceNavigator#Stop()

command! -nargs=1 SNClassBrowser call SourceNavigator#ClassBrowser(<q-args>)
command! -nargs=1 SNClassTree    call SourceNavigator#ClassTree(<q-args>)
command! -nargs=1 SNRetrieve     call SourceNavigator#Retrieve(<q-args>)
command! -nargs=1 SNXref         call SourceNavigator#Xref(<q-args>)

command! -nargs=* SNUpdate       call SourceNavigator#Update(<q-args>)

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
