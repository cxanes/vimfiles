" SwapParams.vim
" Last Modified: 2008-05-05 14:46:56
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Inspired by swap_parameters.vim without need for +python support
" <http://www.vim.org/scripts/script.php?script_id=2032>

" Load Once {{{
if exists('loaded_SwapParams')
  finish
endif
let loaded_SwapParams = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Mappings {{{
if !hasmapto('<Plug>SwapForwardParam', 'n')
  nmap <silent> gs <Plug>SwapDelimitForwardParam
endif

if !hasmapto('<Plug>SwapBackwardParam', 'n')
  nmap <silent> gS <Plug>SwapDelimitBackwardParam
endif

nnoremap <silent> <Plug>SwapDelimitForwardParam  :<C-U>call <SID>SwapDelimitParams(1, v:count1)<CR>
nnoremap <silent> <Plug>SwapDelimitBackwardParam :<C-U>call <SID>SwapDelimitParams(0, v:count1)<CR>

nnoremap <silent> <Plug>SwapForwardParam  :<C-U>call <SID>SwapParams(1, v:count1)<CR>
nnoremap <silent> <Plug>SwapBackwardParam :<C-U>call <SID>SwapParams(0, v:count1)<CR>
"}}}
" Global variables {{{
let s:delimit_default = ',=+-/|\~%^'
let [s:delimit, s:leftBrackets, s:rightBrackets] = [s:delimit_default, '{([', ')]}']
"}}}
function! s:CanIgnore(lnum, col) "{{{
  return has('syntax_items') && synIDattr(synID(a:lnum, a:col, 0), 'name') =~? 'string\|comment'
endfunction
"}}}
function! s:FindFirst(forward, lnum, col, delimit) "{{{
  let bracketCnt = 0
  let [openBracket, closeBracket] = a:forward
        \ ? [s:leftBrackets, s:rightBrackets] 
        \ : [s:rightBrackets, s:leftBrackets]

  let line   = getline(a:lnum)
  let strlen = strlen(line)

  let i = a:col - 1

  if 0 <= i && i < strlen 
        \ && stridx(a:delimit,    line[i]) != -1
        \ && stridx(closeBracket, line[i]) != -1
    let i += a:forward ? 1 : -1
  endif

  while 0 <= i && i < strlen 
    let ch = line[i]
    if stridx(a:delimit, ch) != -1 && bracketCnt <= 0 && !s:CanIgnore(a:lnum, i + 1)
      return i + 1
    elseif stridx(openBracket,  ch) != -1 && !s:CanIgnore(a:lnum, i + 1)
      let bracketCnt += 1
    elseif stridx(closeBracket, ch) != -1 && !s:CanIgnore(a:lnum, i + 1)
      let bracketCnt -= 1
      if stridx(a:delimit, ch) != -1 && bracketCnt < 0
        return i + 1
      endif
    endif
    let i += a:forward ? 1 : -1
  endwhile

  return -1
endfunction
"}}}
function! s:InBrackets(lnum, col) "{{{
  return s:FindFirst(1, a:lnum, a:col, s:rightBrackets) != -1
endfunction
"}}}
function! s:SkipBlank(forward, lnum, col) "{{{
  let line = getline(a:lnum)
  let strlen = strlen(line)
  let i = a:col - 1
  while 0 <= i && i < strlen 
    let ch = line[i]
    if ch =~ '\S'
      return i + 1
    endif
    let i += a:forward ? 1 : -1
  endwhile
  return -1
endfunction
"}}}
function! s:SwapParamsPos(forward, lnum, col) "{{{
  if a:lnum < 1 || a:lnum > line('$')
    return -1
  endif

  if 0 < a:col && a:col <= strlen(getline(a:lnum))
        \ && stridx(s:delimit, getline(a:lnum)[a:col-1]) != -1
    return -1
  endif

" echom printf('%s_', repeat(' ', a:col-1))
" echom getline(a:lnum)
" echom repeat('1234567890', 5)
" echom join(map(range(1, 5), "'         '.v:val"), '')

  let col = a:col
  if !a:forward
    let col = s:FindFirst(0, a:lnum, col, (s:leftBrackets . s:delimit))
    if col == -1 || stridx(s:leftBrackets, getline(a:lnum)[col-1]) != -1
      return -1
    endif
    let col = s:SkipBlank(0, a:lnum, col-1)
  endif

  let inBrackets = s:InBrackets(a:lnum, col)
" echom 'inBrackets:' inBrackets

  let param1end = s:FindFirst(1, a:lnum, col, (s:rightBrackets . s:delimit))
" echom 'param1end:' param1end
  if param1end == -1 || stridx(s:rightBrackets, getline(a:lnum)[param1end-1]) != -1
    return -1
  endif

  let param1start = s:FindFirst(0, a:lnum, col, 
        \ (inBrackets ? (s:leftBrackets . s:delimit) : (s:leftBrackets . ' ' . s:delimit))) 
" echom 'param1start:' param1start
  if param1start == -1
    let param1start = 0
  endif

  let param1start = s:SkipBlank(1, a:lnum, param1start+1)
" echom 'param1start:' param1start

  if param1start == -1
    return -1
  endif
" echom 'param1start:' param1start

  let delimit_pos = param1end

  let param1end = s:SkipBlank(0, a:lnum, delimit_pos-1)
" echom 'param1end:' param1end
  if param1end == -1
    return -1
  endif

  let param2start = s:SkipBlank(1, a:lnum, delimit_pos+1)
" echom 'param2start:' param2start
  if param2start == -1
    return -1
  endif

  let param2end = s:FindFirst(1, a:lnum, param2start, 
        \ (inBrackets ? (s:rightBrackets . s:delimit) : (' ' . s:delimit)))
" echom 'param2end:' param2end
  if param2end == -1
    let param2end = strlen(getline(a:lnum)) + 1
  endif

  let param2end = s:SkipBlank(0, a:lnum, param2end-1)
" echom 'param2end:' param2end

  if param2end == -1
    return -1
  endif
" echom 'param2end:' param2end

  let line = getline(a:lnum)
  call setline(a:lnum, 
        \    (param1start < 2 ? '' : line[ : param1start-2])
        \  . line[param2start-1 : param2end-1  ]
        \  . line[param1end     : param2start-2]
        \  . line[param1start-1 : param1end-1  ]
        \  . line[param2end     :              ]
        \ )
  return a:forward ? param2end : param1start
endfunction
"}}}
function! s:GetDelimit() "{{{
  let c = getchar()

  if c =~ '^\d\+$'
    let c = nr2char(c)
    if c =~ "\<Esc>" || c =~ "\<C-C>"
      let c = ''
    endif
    return c
  endif

  return ''
endfunction
"}}}
function! s:SwapDelimitParams(forward, cnt) "{{{
  let delimit = s:GetDelimit()
  if empty(delimit)
    return
  endif

  let s:delimit = delimit
  call s:SwapParams(a:forward, a:cnt)
endfunction
"}}}
function! s:SwapParams(forward, cnt) "{{{
  let cnt = a:cnt <= 0 ? 1 : a:cnt
  let changedtick = b:changedtick

  while cnt > 0
    let [lnum, col] = [line('.'), col('.')]
    let col = s:SwapParamsPos(a:forward, lnum, col)
    if col <= 0
      break
    endif
    call cursor(lnum, col)
    let cnt -= 1
  endwhile

  if changedtick == b:changedtick
    return
  endif

  if a:forward
    silent! call repeat#set("\<Plug>SwapForwardParam")
  else
    silent! call repeat#set("\<Plug>SwapBackwardParam")
  endif
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
