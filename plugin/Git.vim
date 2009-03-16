" Git.vim
" Last Modified: 2009-03-15 07:39:48
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Most source codes are copied from git-vim <http://github.com/motemen/git-vim>

" Load Once {{{
if exists('loaded_Git')
  finish
endif
let loaded_Git = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

command! -nargs=1 -complete=customlist,Git#ListCommits GitCheckout call Git#Checkout(<q-args>)
command! -nargs=* -complete=customlist,Git#ListCommits GitDiff     call Git#Diff(<q-args>)
command!          GitStatus           call Git#Status()
command! -nargs=? GitAdd              call Git#Add(<q-args>)
command! -nargs=* -bang GitLog        call Git#Log(<q-args>, <q-bang> == '!')
command! -nargs=* GitCommit           call Git#Commit(<q-args>)
command! -nargs=1 GitCatFile          call Git#CatFile(<q-args>)
command! -nargs=+ -complete=custom,Git#ListArgs        Git         call Git#DoCommand(<q-args>)
command!          GitVimDiffMerge     call Git#VimDiffMerge()
command!          GitVimDiffMergeDone call Git#VimDiffMergeDone()

command! -nargs=1 -complete=custom,Git#ListArgs        GitHelp     call Git#ShowHelp(<q-args>)

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
