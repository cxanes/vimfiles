" CmdLineCompl.vim 
"
" Last Modified: 2008-04-23 04:02:41
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
"  Complete keywords in command line mode searching current buffer.

" Load Once {{{
if exists('loaded_CmdLineCompl_plugin')
  finish
endif
let loaded_CmdLineCompl_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Mappings {{{
if !hasmapto('<Plug>CmdLineComplForward', 'c')
  cmap <C-T> <Plug>CmdLineComplForward
endif

if !hasmapto('<Plug>CmdLineComplBackward', 'c')
  cmap <C-G> <Plug>CmdLineComplBackward
endif

if !hasmapto('<Plug>CmdLineComplResetAndForward', 'c')
  cmap <Leader><C-T> <Plug>CmdLineComplResetAndForward
endif

if !hasmapto('<Plug>CmdLineComplResetAndBackward', 'c')
  cmap <Leader><C-G> <Plug>CmdLineComplResetAndBackward
endif

cnoremap <unique> <script> <Plug>CmdLineComplForward  <C-\>e<SID>CmdLineCompl(1)<CR>
cnoremap <unique> <script> <Plug>CmdLineComplBackward <C-\>e<SID>CmdLineCompl(0)<CR>
cnoremap <unique> <script> <Plug>CmdLineComplResetAndForward  <C-\>e<SID>CmdLineCompl(1, 1)<CR>
cnoremap <unique> <script> <Plug>CmdLineComplResetAndBackward <C-\>e<SID>CmdLineCompl(0, 1)<CR>
"}}}
function! s:Reset() "{{{
  let s:cmdPat = ''
  let s:cmdLastPos = 1

  let s:curPos = [line('.'), col('.')]
  let s:complList = []
  let s:complIdx = 0
  let s:isCompl = 0
  let s:complWords = {}
  let s:bufnr = bufnr('')
endfunction
"}}}
function! s:GetComplWord(forward) "{{{
  if s:isCompl
    if a:forward
      let s:complIdx = (s:complIdx + 1) % len(s:complList)
    else " backword
      let s:complIdx = (s:complIdx - 1 + len(s:complList)) % len(s:complList)
    endif
    return s:complList[s:complIdx]
  endif

  if a:forward && s:complIdx + 1 < len(s:complList)
    let s:complIdx += 1
    return s:complList[s:complIdx]
  elseif !a:forward && s:complIdx > 0
    let s:complIdx -= 1
    return s:complList[s:complIdx]
  endif

  let curPos = getpos('.')
  call cursor(s:curPos)

  let pat = '\<' . (s:cmdPat == '\V' ? '\k' : s:cmdPat) . '\k\+'
  let flags = a:forward ? 'cnw' : 'bcnw'

  let [lnum, col] = searchpos(pat, flags)

  " No word is found, return the original word.
  if lnum == 0
    let s:isCompl = 1
    call setpos('.', curPos)
    return s:complList[0]
  endif

  " When this position is return again, it means all words are found.
  let pos = [lnum, col]

  while 1
    let word = matchstr(getline(lnum)[col-1 : ], '^'.pat)

    call cursor(lnum, col)
    let [lnum, col] = searchpos(pat, 'e'.flags)
    call cursor(lnum, col)

    " We don't return duplicated keyword.
    if !has_key(s:complWords, word)
      let s:complWords[word] = 1

      if a:forward
        call add(s:complList, word)
        let s:complIdx += 1
      else
        call insert(s:complList, word)
        let s:complIdx = 0
      endif

      " Next time the searching will start from s:curPos
      let s:curPos = [lnum, col]

      call setpos('.', curPos)
      return word
    endif

    let [lnum, col] = searchpos(pat, flags)
    " All words are found.
    " NOTE: It needs to search all buffer to get here.
    if lnum == 0 || [lnum, col] == pos
      let s:isCompl = 1
      call setpos('.', curPos)
      return s:GetComplWord(a:forward)
    endif
  endwhile
endfunction
"}}}
function! s:CmdLineCompl(forward, ...) "{{{
  if a:0 > 0 && a:1 != 0
    call s:Reset()
  endif

  let line = getcmdline()
  let pos = getcmdpos()

  if s:bufnr == bufnr('')
        \ && s:cmdLastPos < pos
        \ && s:complIdx < len(s:complList)
        \ && line[s:cmdLastPos-1 : pos-2] == s:complList[s:complIdx]
    let word = s:GetComplWord(a:forward)
    let newline = (s:cmdLastPos > 1 ? line[0 : s:cmdLastPos-2] : '') . word
    call setcmdpos(strlen(newline)+ 1)
    let newline .= line[pos-1 : ]
  else
    call s:Reset()
    let newline = ''
    if pos > 1
      let newline = line[0 : pos-2]
    endif

    if s:IsSettingOpts()
      let s:complList = s:GetOptVals()
    endif

    if empty(s:complList)
      let word = matchstr(newline, '\k*$')
      let newline = substitute(newline, '\k\+$', '', '')

      let s:cmdPat = '\V' . escape(word, '\')
      let s:complList = [word]
    else
      let newline = substitute(newline, '[a-z]\+$', '', '')
      let s:isCompl = 1
    endif

    let s:cmdLastPos = strlen(newline) + 1
    let newline .= s:GetComplWord(a:forward)
    call setcmdpos(strlen(newline)+ 1)
    let newline .= pos > 1 ? line[pos-1 : ] : ''
  endif

  return newline
endfunction
"}}}
function! s:IsSettingOpts() "{{{
  if getcmdtype() != ':'
    return 0
  endif

  let line = getcmdpos() <= 2 ? '' : getcmdline()[ : getcmdpos() - 2]
  if line == ''
    return 0
  endif
  let val_pat = '\%(\\.\|[^\\| ,"]\)*'
  if line =~ '\%(^\s*\||\s*\)\%(se\%[t]\|setl\%[ocal]\)\>' && line =~ printf('=\%%(%s,\)*%s$', val_pat, val_pat)
    return 1
  endif

  return 0
endfunction
"}}}
function! s:GetOptVals() "{{{
  let line = getcmdpos() <= 2 ? '' : getcmdline()[ : getcmdpos() - 2]
  if line == ''
    return []
  endif

  let val_pat = '\%(\\.\|[^\\| ,"]\)*'
  let m = matchlist(line, printf('\<\(\w\+\)=\%%(%s,\)*\(%s\)$', val_pat, val_pat))

  if empty(m)
    return []
  endif

  let opt = m[1]
  let val = m[2]
  let val_pat = '^\V' . escape(val, '\')

  let vals = []

  try 
    if s:HasGetOptVals == 1
      let vals = myutils#GetOptVals(opt)
      echom string(vals)
      redraw
    endif
  catch
    if s:HasGetOptVals == 1
      echom v:exception
    endif
    let s:HasGetOptVals = 0
    let vals = []
  endtry

  let vals = filter(vals, 'v:val =~ val_pat')
  if !empty(vals)
    call insert(vals, val, 0)
  endif
  return vals
endfunction
"}}}
call s:Reset()
let s:HasGetOptVals = 1
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
