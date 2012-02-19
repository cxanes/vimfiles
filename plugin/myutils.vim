" File: myutils.vim
" Author: Frank Chang (frank.nevermind AT gmail.com)
" Version: 1.0
" Last Modified: 2008-07-28 20:08:04
"
" My own defined functions and mappings.
"
" {{{ Load Once
if exists('loaded_myutils_plugin')
  finish
endif
let loaded_myutils_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
" }}}
"==============================================================
" {{{1 Global Variable
"--------------------------------------------------------------
let s:MSWIN = has('win32') || has('win32unix') || has('win64') || 
          \   has('win95') || has('win16')
"==========================================================}}}1
"==============================================================
" {{{1 Move current line N lines up/down (default is 1).
"--------------------------------------------------------------
nnoremap <script> <Plug>MoveLineDown :<C-U>call myutils#MoveLine('d', v:count1)<CR>
nnoremap <script> <Plug>MoveLineUp   :<C-U>call myutils#MoveLine('u', v:count1)<CR>

nmap <silent> <M-Down> <Plug>MoveLineDown
nmap <silent> <M-Up>   <Plug>MoveLineUp
nmap <silent> <M-j>    <Plug>MoveLineDown
nmap <silent> <M-k>    <Plug>MoveLineUp
"==========================================================}}}1
" {{{1 Run
"--------------------------------------------------------------
command! -bang -nargs=* Run call myutils#Run(<q-bang> != '!', <q-args>)
nnoremap <silent> <Leader><F7> :Run<CR>
"==========================================================}}}1
" {{{1 Inject
"--------------------------------------------------------------
command! -bang -range -complete=buffer -nargs=1 Inject 
      \ call myutils#Inject(<q-args>, mylib#GetSelection(), <q-bang> == '!')

command! -range -nargs=1 -bang ScreenInject 
      \ call myutils#ScreenInject(<q-bang> != '!', <q-args>, mylib#GetSelection())
"==========================================================}}}1
" {{{1 Filter
"--------------------------------------------------------------
au FileType * 
      \ if !exists('b:filter_cmd') | 
      \   let b:filter_cmd = expand('<amatch>') | 
      \ endif

vnoremap <silent> <F7> :call myutils#Filter()<CR>
nnoremap <silent> <F7> :<C-U>call myutils#FilterAll()<CR>
inoremap <silent> <F7> <C-O>:call myutils#FilterAll()<CR>

command! -range=% -nargs=+ Filter <line1>,<line2>call myutils#Filter(<q-args>)
"==========================================================}}}1
" {{{1 Capitalize the selecting words (e.g. capitalize => Capitalize)
"--------------------------------------------------------------
nmap     <silent> gc <Plug>CapitalizeN0
vnoremap <silent> gc :<C-U>call myutils#Capitalize('v')<CR>
nmap     <silent> gC <Plug>CapitalizeN1
vnoremap <silent> gC :<C-U>call myutils#Capitalize('v', 1)<CR>

nnoremap <silent> gc :<C-U>call myutils#Capitalize('n')<CR>

nnoremap <silent> <Plug>CapitalizeN0 :<C-U>call myutils#Capitalize('n')<CR>
nnoremap <silent> <Plug>CapitalizeN1 :<C-U>call myutils#Capitalize('n', 1)<CR>
"==========================================================}}}1
" {{{1  Swapping characters, words...
"
" - Swap characters: ab => ba
" - Swap words:      a = b => b = a
"
" See http://vim.wikia.com/wiki/Swapping_characters,_words_and_lines
"--------------------------------------------------------------
nmap <silent> gw <Plug>FSwapWords
nmap <silent> gW <Plug>BSwapWords

" nmap <silent> gc <Plug>FSwapChars
" nmap <silent> gC <Plug>BSwapChars

nnoremap <silent> <Plug>FSwapWords :<C-U>call myutils#SwapWords(1)<CR>
nnoremap <silent> <Plug>BSwapWords :<C-U>call myutils#SwapWords(0)<CR>

nnoremap <silent> <Plug>FSwapChars :<C-U>call myutils#SwapChars(1)<CR>
nnoremap <silent> <Plug>BSwapChars :<C-U>call myutils#SwapChars(0)<CR>
"==========================================================}}}1
" {{{1 Hungry Delete
"
" e.g. ( _ is the position of the cursor) 
"
"       1. foo  _    bar => foo_bar 
"
"       2. foo  _        => foo_
"           bar              bar
"
"       3. foo           => foo
"                           _
"          _                 bar
"           bar
"
"       4. foo           => foo
"           _ bar           _bar
"
"--------------------------------------------------------------
nmap <silent> <Leader>d<Space> <Plug>HungryDeleteN
imap <silent> <Leader>d<Space> <C-O><Plug>HungryDeleteN

nnoremap <silent> <Plug>HungryDeleteN :<C-U>call myutils#HungryDelete()<CR>
"==========================================================}}}1
" {{{1 ShowMatch: Show all lines which the pattern matches
"      NOTE: :vimgrep /pattern/ %|copen 
"            may do the same job (except using file).
"--------------------------------------------------------------
command! -nargs=? -bang ShowMatch call myutils#ShowMatch(<q-bang> == '!', <q-args>)
"==========================================================}}}1
" {{{1 Seq: Insert a list of number (the same options as seq)
"--------------------------------------------------------------
command! -nargs=+ -bang -range Seq call myutils#InsertSeq(<q-bang> == '!', <q-args>)
"==========================================================}}}1
" {{{1 MultipleEdit()
"--------------------------------------------------------------
command! -nargs=+ -complete=custom,myutils#CmdListFiles MultipleEdit call myutils#MultipleEdit(<f-args>)
"==========================================================}}}1
" {{{1 Calc(): require +python
"--------------------------------------------------------------
" Tip 1235: http://vim.wikia.com/wiki/VimTip1235
command! -nargs=+ Calc call s:ImportPyModule(<q-args>)
function! s:ImportPyModule(expr)
  if !has('python')
    call mylib#ShowMesg('ErrorMsg', 'Calc: python not support', 1)
    return
  endif

  py from math import *
  command! -nargs=+ Calc py print <args>

  exec 'py print' a:expr
endfunction
"==========================================================}}}1
" {{{1 StripSurrounding()
"--------------------------------------------------------------
nnoremap <silent> <Leader>sf :call myutils#StripFunc()<CR>
"==========================================================}}}1
" {{{1 PutNewLine()
"--------------------------------------------------------------
inoremap <silent> <S-CR> <C-\><C-O>:call myutils#PutNewLine()<CR>
"==========================================================}}}1
" {{{1 CloseAllOtherWindows()
"--------------------------------------------------------------
nnoremap <silent> <C-W>o :<C-U>call myutils#CloseAllOtherWindows()<CR>
"==========================================================}}}1
" {{{1 Build Tags
"--------------------------------------------------------------
command! -nargs=* -bang         Cscope       call myutils#Cscope(<q-args>, expand('<bang>') == '!')
command! -nargs=* -bang         Ctags        call myutils#Ctags(<q-args>, expand('<bang>') == '!')
command! -nargs=? -complete=dir SimpleRetag  call myutils#SimpleRetag(<q-args>)
"==========================================================}}}1
" {{{1 Text objects selection
"--------------------------------------------------------------
" {{{2 Function
nnoremap <silent> yaf :<C-U>call myutils#FuncTextObject('y')<CR>
nnoremap <silent> daf :<C-U>call myutils#FuncTextObject('d')<CR>
nnoremap <silent> caf :<C-U>call myutils#FuncTextObject('d')<CR>i
vnoremap <silent> af  :<C-U>call myutils#FuncTextObject('v')<CR>
" }}}2
"==========================================================}}}1
" {{{1 WebSearch
"--------------------------------------------------------------
command! -nargs=+ WebSearch call myutils#WebSearch(<q-args>)
"==========================================================}}}1
" {{{1 ShowImage()
"--------------------------------------------------------------
vnoremap <silent> <Leader>vi :<C-U>call myutils#ShowImage(<SID>GetFiles())<CR>
command! -nargs=+ -complete=file ShowImage call myutils#ShowImage([<f-args>])
function! s:GetFiles() "{{{
  let path = mylib#GetSelection()
  if path =~ '^\s*$'
    return
  endif
  let files = split(path, '\n')
  for i in range(0, len(files)-1)
    let file = files[i]
    let file = substitute(file, '^\s\+', '', 'g')
    let file = substitute(file, '\s\+$', '', 'g')

    if !filereadable(file)
      if filereadable(expand('%:p:h').'/'.file)
        let file = expand('%:p:h').'/'.file
      else
        let file = ''
      endif
    endif

    if s:MSWIN
      let file = iconv(file, &enc, 'big5')
    endif

    let files[i] = file
  endfor
  call filter(files, 'v:val != ""')
  return files
endfunction
" }}}
"==========================================================}}}1
" {{{1 OpenFile(): open file according to the file association
"--------------------------------------------------------------
command! -nargs=1 -complete=file OpenFile call myutils#OpenFile(<q-args>)
"==========================================================}}}1
" {{{1 ColorSelector()
"--------------------------------------------------------------
inoremap <silent> <Leader>cs     <C-R>=myutils#ColorSelector('i')<CR>
nnoremap <silent> <Leader>cs    a<C-R>=myutils#ColorSelector('i')<CR>
vnoremap <silent> <Leader>cs "_yi<C-R>=myutils#ColorSelector('v')<CR>
"==========================================================}}}1
" {{{1 Enclose(): Enclose text with braces.
"--------------------------------------------------------------
command! -nargs=? -range Enclose call myutils#Enclose(<q-args>, <line1>, <line2>)
"==========================================================}}}1
" {{{1 VimEval(): Evaluate given expression and return the result
"                 (when error occurs returns 0)
"--------------------------------------------------------------
inoremap <silent> <Leader>ee <C-R>=myutils#IEvalVim('e')<CR>
inoremap <silent> <Leader>ej <C-R>=myutils#IEvalVim('j')<CR>

nnoremap <silent> <Leader>ee :<C-U>call myutils#NEvalVim('e')<CR>
nnoremap <silent> <Leader>ej :<C-U>call myutils#NEvalVim('j')<CR>

vnoremap <silent> <Leader>ee :<C-U>call myutils#VEvalVim('e')<CR>
vnoremap <silent> <Leader>ej :<C-U>call myutils#VEvalVim('j')<CR>
vnoremap <silent> <Leader>er :<C-U>call myutils#VEvalVim('r')<CR>
"}}}
"==========================================================}}}1
" {{{1 OpenMRUList(): Open a window to show the MRU list (use bufexplorer).
"--------------------------------------------------------------
command! OpenMRUList call myutils#OpenMRUList()
"==========================================================}}}1
"==============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
