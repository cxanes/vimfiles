" .vimrc
"
" Author:        Frank Chang <frank.nevermind AT gmail.com>
" Last Modified: 2016-01-07 01:55:54
"
" Prerequisite:  Vim >= 7.0
"
" Some definitions of the functions and key mappings are modified from
" others' scripts. Many thanks to them!
"
" Reference:
"   - $VIMRUNTIME/vimrc_example.vim
"   - $VIMRUNTIME/gvimrc_example.vim
"   - $VIMRUNTIME/mswin.vim
"   - http://macromates.com/svn/Bundles/trunk/Bundles/
"   - http://mysite.verizon.net/astronaut/vim/index.html
"   - http://www.tpope.us/cgi-bin/cvsweb/tpope/.vimrc
"
"   - $VIMRUNTIME/mswin.vim
"   - $VIMRUNTIME/gvimrc_example.vim
"
set nocompatible
if version < 700
  echohl ErrorMsg | echo 'Config requires at least VIM 7.0' | echohl None
  set noloadplugins
  finish
end

" Remove ALL autocommands in group Vimrc.
augroup Vimrc
  au!
augroup END

" g:USER_INFO
ru init/user_info.vim

let g:MSWIN =  has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')

let s:RUNTIME_DIRS = [($HOME . '/.vim'), ($VIM  . '/vimfiles')]
if !isdirectory(s:RUNTIME_DIRS[g:MSWIN])
      \ && isdirectory(s:RUNTIME_DIRS[!g:MSWIN])
  let $MYVIMRUNTIME = s:RUNTIME_DIRS[!g:MSWIN]
else
  let $MYVIMRUNTIME = s:RUNTIME_DIRS[g:MSWIN]
end
unlet s:RUNTIME_DIRS

let $V = $MYVIMRUNTIME

ru init/env.vim
ru init/setting.vim
ru init/mapping.vim
ru init/command.vim
ru init/filetype.vim
ru init/plugin.vim
ru init/misc.vim
ru init/gvim.vim

" vim: ts=2 : sw=2 :
