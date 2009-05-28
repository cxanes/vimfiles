" Man.vim
" Last Modified: 2008-08-03 22:33:35
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_Man')
  finish
endif
let loaded_Man = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
command! -bang -nargs=* Man       call Man#Main(&ft,      <q-bang> == '!', <q-args>)
command! -bang -nargs=* Info      call Man#Main('info',   <q-bang> == '!', <q-args>)
command! -bang -nargs=* Perldoc   call Man#Main('perl',   <q-bang> == '!', <q-args>)
command! -bang -nargs=* Pydoc     call Man#Main('python', <q-bang> == '!', <q-args>)
command! -bang -nargs=* Ri        call Man#Main('ruby',   <q-bang> == '!', <q-args>)

command! -bang -nargs=* ManMan    call Man#Main('man',    <q-bang> == '!', <q-args>)
command! -bang -nargs=* ManInfo   call Man#Main('info',   <q-bang> == '!', <q-args>)
command! -bang -nargs=* ManPerl   call Man#Main('perl',   <q-bang> == '!', <q-args>)
command! -bang -nargs=* ManPython call Man#Main('python', <q-bang> == '!', <q-args>)
command! -bang -nargs=* ManRuby   call Man#Main('ruby',   <q-bang> == '!', <q-args>)

if &keywordprg =~ '^man\>'
  nnoremap <silent> K :call Man#K_Map(&ft, v:count, expand('<cWORD>'))<CR>
  vnoremap <silent> K :call Man#K_Map(&ft, v:count, mylib#GetSelection())<CR>
endif

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
