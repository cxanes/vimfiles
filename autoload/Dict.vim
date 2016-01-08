" Dict.vim  
" Last Modified: 2008-03-14 09:41:57
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Prerequisite: myutils.vim
"
" Look up the word using 'sdcv' (The command line version of 'stardict')
" Ref: http://sdcv.sourceforge.net/

" Load Once {{{
if exists('loaded_Dict_autoload_plugin')
  finish
endif
let loaded_Dict_autoload_plugin = 1

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
" {{{ Options
if !exists('g:dict_try_speedup')
  let g:dict_try_speedup = 1
endif
" }}}
"==============================================================
" {{{ Variables
let s:MSWIN = has('win32') || has('win16') || has('win64')
      \   || has('win95') || has('win32unix')
" }}}
"===============================================================
function! s:IsPureEnglish(word) "{{{
  " Modeified from sdcv (src/lib/lib.cpp - bIsPureEnglish())
  for i in range(strlen(a:word))
    if char2nr(a:word[i]) > 0177 
      return 0
    endif
  endfor
  return 1
endfunction
" }}}
"==============================================================
" {{{ Look up the word <sdcv>
function! Dict#Dict(word, ...) " ... = StayInDictBuffer {{{
  if s:dict_running == 1
    return
  endif

  let s:dict_running = 1
  let bufname = '-Dictionary-'
  let winnum = bufwinnr(bufname)

  let lz_sav = &lz
  let &lz = 1

  try
    if a:word == ''
      if winnum != -1
        exe winnum . 'wincmd w'
        wincmd c
      else
        echohl ErrorMsg | echo 'E471: Argument required' | echohl None
        return
      endif
      return
    endif

    let word = iconv(a:word, &enc, (s:MSWIN ? 'big5' : 'utf-8'))
    let curwinnum = winnr()

    " CreateSharedTempBuffer() is defined in myutils.vim
    let winnum = CreateSharedTempBuffer(bufname, '<SNR>'.s:SID().'_DictionaryBufInit')

    exe winnum . 'wincmd w'
    if exists('g:sdcv_loaded') && g:sdcv_loaded == 1 && s:IsPureEnglish(a:word)
      call s:PySdcv_Lookup(word)
    else
      silent %d _
      if exists('g:dict_list')
        let dicts = substitute(g:dict_list, '^\|,', ' -u ', 'g')
        silent exe '0r !sdcv -n ' . dicts . ' ' . word
      else
        silent exe '0r !sdcv -n ' . word
      endif
    endif

    call cursor(1, 1)

    if a:0 == 0 || a:1 == 0
      redraw
      exe curwinnum . 'wincmd w'
    endif
  finally
    let &lz = lz_sav
    let s:dict_running = 0
  endtry
endfunction
" }}}
function! s:Dict_Setup() "{{{
  let s:dict_running = 0

  if exists('g:dict_list')
    let s:dict_list = type(g:dict_list) == type([]) 
          \ ? join(map(g:dict_list, 'printf(''"%s"'')'), ',')
          \ : g:dict_list 
  else
    let s:dict_list = '"Collins Cobuild English Dictionary","Oxford Advanced Learner''s Dictionary","Merrian Webster 10th dictionary","LANGDAO-CE","XDICT-CE","CDICT"'
  endif
endfunction
  "}}}
function! s:SID() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
"}}}
function! s:DictionaryBufInit() " {{{
  let b:Dictionary_Buf_Init = 1
  syn clear
  syn match Identifier '^-->.\+'

  nmap <silent> <buffer> <CR> <Plug>NDict
  vmap <silent> <buffer> <CR> <Plug>VDict

  if exists('*s:PySdcv_Setup') && exists('*s:PySdcv_Cleanup')
    call s:PySdcv_Setup()
    au BufUnload <buffer> call s:PySdcv_Cleanup()
  endif
endfunction 
" }}}
call s:Dict_Setup()
" }}}
" {{{ Pronounce English Words <WyabdcRealPeopleTTS>
function! Dict#Pronounce(word) "{{{
  if empty(a:word) || !s:IsPureEnglish(a:word) || s:pronounce_running
    return
  endif

  let s:pronounce_running = 1
  if !empty(s:eng_word['file'])
    let word = s:GetSimilarWord(a:word)
    if !empty(word)
      call system(printf(s:eng_word['cmd'], printf(s:eng_word['file'], word[0], word)))
      if !v:shell_error
        let s:pronounce_running = 0
        return
      endif
    endif
  endif

  if !empty(s:eng_word['pronounce'])
    call system(printf("pronounce '%s'", a:word))
    if !v:shell_error
      let s:pronounce_running = 0
      return
    endif
  endif

  echohl ErrorMsg | echo 'Cannot pronounce the word: ' . a:word | echohl None
  let s:pronounce_running = 0
endfunction
" }}}
function! s:Pronounce_Setup() "{{{
  let s:pronounce_running = 0
  let s:eng_word = {}
  let s:eng_word['pronounce'] = executable('pronounce') > 0

  if exists('g:pronounce_dirs')
    let dirs = type(g:pronounce_dirs) == type([])
          \ ? g:pronounce_dirs
          \ : split(g:pronounce_dirs, ',')
  else
    let dirs = s:MSWIN
          \ ? ['C:/Program Files/WyabdcRealPeopleTTS', 
          \    'C:/Program Files/StarDict/WyabdcRealPeopleTTS']
          \ : ['/usr/share/WyabdcRealPeopleTTS']
  endif

  let s:eng_word['file'] = ''
  for dir in dirs
    if isdirectory(dir)
      let s:eng_word['file'] = dir . '/%s/%s.wav'
      break
    endif
  endfor

  if !empty(s:eng_word['file'])
    if s:MSWIN
      if executable('bash') && executable('cat')
        " http://cygwin.com/ml/cygwin/2003-05/msg00894.html
        let s:eng_word['cmd'] = "bash -c \"cat '%s' > /dev/dsp\""
      else
        let s:eng_word['file'] = ''
      endif
    else
      if executable('mplayer')
        let s:eng_word['cmd'] = "mplayer -quiet '%s' >/dev/null 2>&1"
      else
        let s:eng_word['file'] = ''
      endif
    endif
  endif
endfunction
" }}}
function! s:ExistWav(word) "{{{
  return filereadable(printf(s:eng_word['file'], a:word[0], a:word))
endfunction
" }}}
function! s:GetSimilarWord(word) "{{{
  " Modified from sdcv (src/lib/lib.cpp - Libs::LookupSimilarWord())
  if empty(a:word)
    return ''
  endif

  let orig_word = tolower(a:word)

  if s:ExistWav(orig_word)
    return orig_word
  endif

  " cut one char "s" or "d"
  if strlen(orig_word) > 1 && match(orig_word, '\%(s\|d\)$') != -1
    let word = substitute(orig_word, '\%(s\|d\)$', '', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut "ly"
  if strlen(orig_word) > 2 && match(orig_word, 'ly$') != -1
    let word = substitute(orig_word, 'ly$', '', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut "ing"
  if strlen(orig_word) > 3 && match(orig_word, 'ing$') != -1
    let word = substitute(orig_word, 'ing$', '', '')
    if s:ExistWav(word)
      return word
    endif
    let word = substitute(orig_word, 'ing$', 'e', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut two char "es"
  if strlen(orig_word) > 2 && match(orig_word, 'es$') != -1
    let word = substitute(orig_word, 'es$', '', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut "ed"
  if strlen(orig_word) > 2 && match(orig_word, 'ed$') != -1
    let word = substitute(orig_word, 'ed$', '', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut "ied" , add "y".
  if strlen(orig_word) > 3 && match(orig_word, 'ied$') != -1
    let word = substitute(orig_word, 'ied$', 'y', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut "ies" , add "y".
  if strlen(orig_word) > 3 && match(orig_word, 'ies$') != -1
    let word = substitute(orig_word, 'ies$', 'y', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut "er".
  if strlen(orig_word) > 2 && match(orig_word, 'er$') != -1
    let word = substitute(orig_word, 'er$', '', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  " cut "est".
  if strlen(orig_word) > 3 && match(orig_word, 'est$') != -1
    let word = substitute(orig_word, 'est$', '', '')
    if s:ExistWav(word)
      return word
    endif
  endif

  return ''
endfunction
" }}}
call s:Pronounce_Setup()
" }}}
"==============================================================
" +python support "{{{
if executable('pty') && g:dict_try_speedup == 1 
      \ && has('python') && globpath(&rtp, 'tools/SdcvServer.py') != ''
  function! s:PySdcv_Setup() "{{{
    if !exists('g:sdcv_loaded')
      let sdcv = split(globpath(&rtp, 'tools/SdcvServer.py'), '\n')[0]
      if sdcv == ''
        return
      endif
      exec 'pyf  ' . sdcv
    endif

    if exists('g:sdcv_loaded') && g:sdcv_loaded == 1 
      py << EOF
if 'sdcv_server' not in locals():
  sdcv_server = Sdcv(vim.eval('s:dict_list'))
EOF
    endif
  endfunction
  "}}}
  function! s:PySdcv_Lookup(word) "{{{
    if a:word == ''
      return
    endif

    let word = a:word
    py << EOF
if 'sdcv_server' in locals():
  sdcv_server.lookup(vim.eval('word'))
EOF
  endfunction
  "}}}
  function! s:PySdcv_Cleanup() "{{{
    py << EOF
if 'sdcv_server' in locals():
  sdcv_server.exit_sdcv()
  del sdcv_server
EOF
  endfunction
  "}}}
endif
"}}}
"==============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
