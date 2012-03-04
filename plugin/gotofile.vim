" gotofile.vim
" Last Modified: 2012-01-30 03:08:15
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_gotofile')
  finish
endif
let loaded_gotofile = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

if !hasmapto('<Plug>GoToFileWindow')
 nmap <F9> <Plug>GoToFileWindow
 imap <F9> <ESC><Plug>GoToFileWindow
endif
nmap <script> <silent> <unique> <Plug>GoToFileWindow :<C-U>GoToFileWindow<CR>

command! GoToFileWindow call gotofile#CreateGoToFileWindow()

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
