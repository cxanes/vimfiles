" Vim global plugin for appending text synchronously to multiple lines
" Last Modified: 2008-03-13 01:22:27
"        Author: Frank Chang <frank.nevermind AT gmail.com>
" Load Once {{{
if exists('sync_append_plugin')
  finish
endif
let sync_append_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Key mappings {{{
if !hasmapto('<Plug>SyncAppend')
  vmap <silent> <unique> <Leader>A <Plug>SyncAppend
endif

vnoremap <silent> <unique> <script> <Plug>SyncAppend :call <SID>SyncAppendMode()<CR>
"}}}
" Since 'indent' will mess up the comparison of two lines, we must turn it off. {{{
function! s:UnsetIndent()
  let s:indent = {}
  for opt in ['autoindent', 'smartindent', 'cindent', 'indentexpr']
    let val = eval('&'.opt)
    let s:indent[opt] = val
    call setbufvar('', '&'.opt, type(val) == type('') ? '' : 0)
  endfor
endfunction
function! s:RestoreIndent()
  if exists('s:indent')
    for [opt, val] in items(s:indent)
      call setbufvar('', '&'.opt, val)
    endfor
    unlet s:indent
  endif
endfunction
"}}}
function! s:AddAutocmd() "{{{
  call s:UnsetIndent()
  augroup SyncAppend
    au!
    au InsertLeave <buffer> call <SID>SyncAppend()
  augroup END
endfunction
"}}}
function! s:RemoveAutocmd() "{{{
  call s:RestoreIndent()
  au! SyncAppend
endfunction
"}}}
function! s:SyncAppendMode() range "{{{
  let s:line = [line('.'), getline('.')]
  let s:range = [a:firstline+1, a:lastline]
  if s:range[0] > s:range[1]
    return
  endif
  call s:AddAutocmd()
  startinsert!
endfunction
"}}}
" GetDiff() {{{
" 
" return: [si_org, ei_org, diff_str]
"
"   si_org    first index of the change (negative index of line_org)
"   ei_org    last index of the change (negative index of line_org)
"   diff_str  the different between two strings
"
function! s:GetDiff(line_org, line_new)
  let line_org = split(a:line_org, '\zs')
  let line_new = split(a:line_new, '\zs')
  let diff_pos = [0, 0]

  let is_diff = 0

  let len_line_org = len(line_org)
  let len_line_new = len(line_new)

  for i in range(len_line_org)
    if i >= len_line_new
      break
    endif
    if line_org[i] != line_new[i]
      let diff_pos[0] = i
      let is_diff = 1
      break
    endif
  endfor
  if !is_diff
    return [len_line_new - len_line_org, -1, 
          \ len_line_new == len_line_org ? '' : join(line_new[len_line_org : -1], '')]
  endif

  let ei_org = len_line_org - 1
  let ei_new = len_line_new - 1

  let si = diff_pos[0]
  let diff_str = ''
  while ei_org >= si && ei_new >= si && ei_org >= 0 && ei_new >= 0
    if line_org[ei_org] != line_new[ei_new]
      break
    endif
    let ei_org -= 1
    let ei_new -= 1
  endwhile

  let diff_pos[1] = ei_org
  if ei_new >= si
    let diff_str = join(line_new[si : ei_new], '')
  endif

  return [diff_pos[0]-len_line_org, diff_pos[1]-len_line_org, diff_str]
endfunction
"}}}
function! s:SyncAppend() "{{{
  call s:RemoveAutocmd()
  if !exists('s:line') || !exists('s:range') || s:line[0] != line('.')
    return
  endif
  let line_org = s:line[1]
  let line_new = getline('.')
  let diff = s:GetDiff(line_org, line_new)
  call s:Change(diff)
endfunction
"}}}
function! s:Change(diff) "{{{
  if s:range[0] > s:range[1]
    return
  endif
  let [si, ei, sub] = a:diff

  let rm   = si > ei  ? '' : printf('.\{%d}', ei-si+1)
  let tail = ei >= -1 ? '' : printf('.\{%d}', -(ei+1))

  if empty(rm) && empty(tail) && empty(sub)
    return
  endif

  let pat = printf('%s\(%s\)$', rm, tail)
  for lnum in call('range', s:range)
    call setline(lnum, substitute(getline(lnum), pat, (escape(sub, '\&~') . '\1'), ''))
  endfor
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
