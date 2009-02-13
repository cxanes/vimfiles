" template.vim Insert Template using snippetsEmu.vim
" Last Modified: 2008-03-13 22:37:15
"        Author: Frank Chang <frank.nevermind AT gmail.com>
" Load Once {{{
if exists('loaded_template_plugin')
  finish
endif
let loaded_template_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

command! -nargs=1 -complete=custom,Template#ListTemplates Template call Template#InsertTemplate(<q-args>)

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
