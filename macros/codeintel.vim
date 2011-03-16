" codeintel.vim
" Last Modified: 2009-03-06 13:13:05
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_codeintel')
  finish
endif
let loaded_codeintel = 1
"}}}
" Required vim compiled with +python {{{
if !has('python')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Commands {{{
command! CodeIntelScanAllBuffers    call codeintel#ScanAllBuffers()
command! CodeIntelScanCurrentBuffer call codeintel#ScanCurrentBuffer()
command! CodeIntelShowCalltips      call codeintel#ShowCalltips()
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
