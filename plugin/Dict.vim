" Dict.vim  
" Last Modified: 2008-03-14 09:41:57
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Prerequisite: myutils.vim
"
" Look up the word using 'sdcv' (The command line version of 'stardict')
" Ref: http://sdcv.sourceforge.net/

" Load Once {{{
if exists('loaded_Dict_plugin')
  finish
endif
let loaded_Dict_plugin = 1

if !executable('sdcv')
  echohl ErrorMsg
  echom 'Dict plugin requires sdcv <http://sdcv.sourceforge.net/>.'
  echohl None
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}
"==============================================================
if !hasmapto('<Plug>VDict')
  vmap <silent> <F9> <Plug>VDict
endif

if !hasmapto('<Plug>NDict')
  nmap <silent> <F9> <Plug>NDict
endif

vnoremap <silent> <script> <Plug>VDict <ESC>:<C-U>call Dict#Dict(GetSelection())<CR>
nnoremap <silent> <script> <Plug>NDict :<C-U>call Dict#Dict(expand('<cword>'))<CR>

command! -nargs=? -bang Dict      call Dict#Dict(<q-args>, <q-bang> != '!')
command! -nargs=1       Pronounce call Dict#Pronounce(<q-args>)

if !hasmapto('<Plug>VPronounce')
  vmap <silent> <F6> <Plug>VPronounce
endif

if !hasmapto('<Plug>NPronounce')
  nmap <silent> <F6> <Plug>NPronounce
endif

vnoremap <silent> <script> <Plug>VPronounce <ESC>:<C-U>call Dict#Pronounce(GetSelection())<CR>
nnoremap <silent> <script> <Plug>NPronounce :<C-U>call Dict#Pronounce(expand('<cword>'))<CR>
"==============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
