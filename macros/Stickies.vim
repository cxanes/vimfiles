" Stickies.vim
" Last Modified: 2011-04-24 02:50:06
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_Stickies')
  finish
endif
let loaded_Stickies = 1

if !has('python')
  finish
endif

let s:MSWIN =  has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')

if !s:MSWIN
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}

command! -range StickiesCreateNewStickyFromSelection call Stickies#CreateNewSticky(mylib#GetSelection())
command! -nargs=* StickiesCreateNewSticky call Stickies#CreateNewSticky(<q-args>)
command! -nargs=* StickiesSendCommand call Stickies#VimCmdSend(<q-args>)
command! -nargs=* StickiesStart call Stickies#Start()
command! -nargs=* StickiesStop call Stickies#Stop()

command! -range StickiesSetCurrentStickyTextFromSelection call Stickies#SetCurrentStickyText(mylib#GetSelection())
command! -nargs=* StickiesSetCurrentStickyText call Stickies#SetCurrentStickyText(<q-args>)

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
