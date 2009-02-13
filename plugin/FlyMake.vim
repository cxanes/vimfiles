" FlyMake.vim
" Last Modified: 2008-03-16 01:00:14
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_FlyMake_plugin')
  finish
endif
let loaded_FlyMake_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Requirement: Vim > 7.0 +signs +autocmd +clientserver {{{
if !(v:version >= 700 && has('signs') && has('autocmd') && has('clientserver'))
  finish
endif
"}}}
" Commands {{{
command! FlyMake        call FlyMake#FlyMake(1)
command! FlyMakeRemote  call FlyMake#Send()
command! FlyMakeShowErr call FlyMake#ShowErr()
command! DoFlyMake      call FlyMake#Mode(1)
command! NoFlyMake      call FlyMake#Mode(0)
command! Fnext          call FlyMake#MoveToError(1)
command! FNext          call FlyMake#MoveToError(0)
command! Fprevious      call FlyMake#MoveToError(0)
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
