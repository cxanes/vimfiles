" Log.vim
" Last Modified: 2008-03-20 23:53:12
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Syntax:
"
" *2008/08/27 23:00-24:00 [tag1,tag2] ... *bold* _italic_ +monospace+
" *2008/08/27 23:00-2008/08/28 22:00 [tag1,tag2] ...
"    *2008/08/27 23:00-24:00 [tag1,tag2] ...
"
" Load Once {{{
if exists('loaded_PIM_Log_plugin')
  finish
endif
let loaded_PIM_Log_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
function! PIM#Log#Open(file, ...) "... = new_tab, category_file {{{
  exec (a:0 > 0 && a:1 ? 'tabe' : 'e') a:file
  call s:LogInit(a:0 > 1 ? a:2 : '')
endfunction
"}}}
function! s:LogInit(category_file) "{{{
  call s:LogSyntaxInit()
  if exists('*AddOptFiles')
    call AddOptFiles('dict', a:category_file)
  endi

  imap <F5> <Plug>InsertDate
  imap <F6> <Plug>InsertTime
  imap <Leader>id <Plug>InsertDate
  imap <Leader>it <Plug>InsertTime

  inoremap <unique> <script> <silent> <Plug>InsertDate <C-G>u<C-R>=<SID>InsertDate(<SID>Input('Date: '))<CR>
  inoremap <unique> <script> <silent> <Plug>InsertTime <C-G>u<C-R>=<SID>InsertTime(<SID>Input('Time: '))<CR>


  if exists('*CompleteParenMap')
    call CompleteParenMap('[')
  endif
  set nowrap
  setl ai
  exec 'lcd ' . expand('%:p:h')
endfunction
"}}}
function! s:Input(prompt, ...) "{{{
  call inputsave()
  let res = call('input', [a:prompt] + a:000)
  call inputrestore()
  return res
endfunction
"}}}
function! s:InsertDate(num) "{{{
  let num = type(a:num) == type('') ? a:num : string(a:num)
  if num == '0' || num == ''
    return strftime('%Y/%m/%d')
  endif

  let elem = matchlist(num, '^\(\d\d\d\d\)/\(\d\d\?\)/\(\d\d\?\)$')
  if !empty(elem)
    return printf('%s/%s/%s', elem[1], printf('%02d', elem[2]), printf('%02d', elem[3]))
  endif

  let elem = matchlist(num, '^\(\d\d\d\d\)\(\d\d\)\(\d\d\)$')
  if !empty(elem)
    return printf('%s/%s/%s', elem[1], elem[2], elem[3])
  endif

  let elem = matchlist(num, '^\(\d\d\)\(\d\d\)$')
  if !empty(elem)
    return printf('%s/%s/%s', strftime('%Y'), elem[1], elem[2])
  endif

  return ''
endfunction
"}}}
function! s:InsertTime(num) "{{{
  let num = type(a:num) == type('') ? a:num : string(a:num)
  if num == '0' || num == ''
    return strftime('%H:%M')
  endif

  let elem = matchlist(num, '^\(\d\d\?\):\(\d\d\?\)$')
  if !empty(elem)
    return printf('%s:%s', printf('%02d', elem[1]), printf('%02d', elem[2]))
  endif

  let elem = matchlist(num, '^\(\d\d\)\(\d\d\)$')
  if !empty(elem)
    return printf('%s:%s', elem[1], elem[2])
  endif

  let elem = matchlist(num, '^\(\d\d\?\)$')
  if !empty(elem)
    return printf('%s:%s', printf('%02d', elem[1]), '00')
  endif

  return ''
endfunction
"}}}
function! s:LogSyntaxInit() "{{{
  syntax clear

  syn match  logBullet '^\s*\*'
  syn match  logDate   '\<\d\d\d\d\/\d\d\/\d\d\>'
  syn match  logTime   '\<\d\d:\d\d\>'
  syn region logTags   matchgroup=logTagsDelimiter start='\[' end='\]' contains=logTag oneline
  syn match  logTag    '[^,\[\]]\+' contained 

  syn match  logItText         /\<_\S.\{-}\S_\>/hs=s+1,he=e-1
  syn match  logItText         /\<_\S_\>/hs=s+1,he=e-1
  syn match  logBfText         /\%(^\|\W\|[+_]\)\@<=\*[^0-9 \t].\{-}\S\*\%(\W\|[+_]\|$\)\@=/hs=s+1,he=e-1
  syn match  logBfText         /\%(^\|\W\|[+_]\)\@<=\*[^0-9 \t]\*\%(\W\|[+_]\|$\)\@=/hs=s+1,he=e-1
  syn match  logTTText         /\%(^\|\W\|[\*_]\)\@<=+[^0-9 \t].\{-}\S+\%(\W\|[\*_]\|$\)\@=/hs=s+1,he=e-1
  syn match  logTTText         /\%(^\|\W\|[\*_]\)\@<=+[^0-9 \t]+\%(\W\|[\*_]\|$\)\@=/hs=s+1,he=e-1

  hi def  logItText  ctermfg=Green gui=italic
  hi def  logBfText  cterm=bold   gui=bold

  hi def link logTTText         Label
  hi def link logBullet         Operator
  hi def link logDate           Boolean
  hi def link logTime           Keyword
  hi def link logTagsDelimiter  Include
  hi def link logTag            Tag

  let b:current_syntax = "log"
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
