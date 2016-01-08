" FileExplorer.vim
" Last Modified: 2010-09-02 05:45:13
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" A tree view file browser.

" Load Once {{{
if exists('loaded_FileExplorer_plugin')
  finish
endif
let loaded_FileExplorer_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

command! -nargs=? -bar -count=0 -complete=dir -bang FileExplorer call FileExplorer#Open(<q-args>, <count>, <q-bang> == '!')


" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
