" Vim global plugin for kill ring simulation
" Last Change: 2008-01-10 09:05:12
"      Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('kill_ring_plugin')
  finish
endif
let kill_ring_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Global Settings {{{

if !exists('g:KillRingMax')
  let g:KillRingMax = 30
endif
"}}}
" Key mappings {{{
if !hasmapto('<Plug>KillRingNext', 'n')
  nmap <silent> <unique> <C-N> <Plug>KillRingNext
endif

if !hasmapto('<Plug>KillRingBefore', 'n')
  nmap <silent> <unique> <C-P> <Plug>KillRingBefore
endif

if !hasmapto('<Plug>KillRingAccept', 'n')
  nmap <silent> <unique> <C-Y> <Plug>KillRingAccept
endif

if !hasmapto('<Plug>KillRingEnd', 'n')
  nmap <silent> <unique> <C-E> <Plug>KillRingEnd
endif

nnoremap <silent> <unique> <script> <Plug>KillRingNext   :<C-U>call <SID>Put(1, v:count1)<CR>
nnoremap <silent> <unique> <script> <Plug>KillRingBefore :<C-U>call <SID>Put(0, v:count1)<CR>
nnoremap <silent> <unique> <script> <Plug>KillRingAccept :<C-U>call <SID>Accept()<CR>
nnoremap <silent> <unique> <script> <Plug>KillRingEnd    :<C-U>call <SID>End()<CR>
"}}}
" Commands {{{
command -bang Put call <SID>KillRingPut(expand('<bang>'))
"}}}
" Autocommands {{{
augroup KillRing
  " au BufEnter    * call s:Init()
  au CursorMoved * call s:Add()
augroup END
"}}}
function! s:Accept() "{{{
  if !&ma
    exec "normal! \<C-Y>"
    return
  endif
  if g:KillRing.Put
    let g:KillRing.Put = 0
  else
    exec "normal! \<C-Y>"
  endif
endfunction
"}}}
function! s:End() "{{{
  if !&ma
    exec "normal! \<C-E>"
    return
  endif
  if g:KillRing.Put
    silent undo
    let g:KillRing.Put = 0
  else
    exec "normal! \<C-E>"
  endif
endfunction
"}}}
function! s:Put(next, count) "{{{
  if !&ma
    exec 'normal! '.(a:next ? "\<C-N>" : "\<C-P>")
    return
  endif

  let l:count = a:count <= 0 ? 1 : a:count
  if g:KillRing.Put == 0
    let g:KillRing.Put = 1
    let g:KillRing.Index = 0
    let g:KillRing.After = !empty(a:next)
    let l:count -= 1
  elseif len(g:KillRing.Text) > 0
    silent undo
    let g:KillRing.Put = 1
  endif

  if len(g:KillRing.Text) > 0
    let ring_len = len(g:KillRing.Text)
    if empty(a:next)
      let g:KillRing.Index = g:KillRing.Index - (l:count % ring_len) + ring_len
    else
      let g:KillRing.Index = g:KillRing.Index + (l:count % ring_len)
    endif
    let g:KillRing.Index = g:KillRing.Index % ring_len

    let save_reg = [@z, getregtype('z')]
    call setreg('z', g:KillRing.Text[g:KillRing.Index][0], g:KillRing.Text[g:KillRing.Index][1])
    if g:KillRing.After
      normal! "zp
    else
      normal! "zP
    endif
    call setreg('z', save_reg[0], save_reg[1])
  endif
endfunction
"}}}
function! s:Init() "{{{
  if !&ma
    return
  endif

  if !exists('g:KillRing')
    let g:KillRing = {}
    let g:KillRing.Text = []
    let g:KillRing.Put = 0
    let g:KillRing.After = 0
    let g:KillRing.Curwinnr = 0
    let g:KillRing.LastReg = [@", getregtype('"')]
    let g:KillRing.LastPos = getpos('.')
    let g:KillRing.LastBufnr = 0
    let g:KillRing.Index = 0
  endif
endfunction
"}}}
function! s:Add() "{{{
  if !&ma
    return
  endif

  let reg = [@", getregtype('"')]
  if !exists('g:KillRing')
    call s:Init()
  endif

  if g:KillRing.LastBufnr != bufnr('%')
    let g:KillRing.LastPos = [0, 0, 0, 0]
    let g:KillRing.LastBufnr = bufnr('%')
  endif

  if reg != g:KillRing.LastReg
    let g:KillRing.Put = 0
    if empty(g:KillRing.Text)
      call insert(g:KillRing.Text, reg)
    elseif getpos('.') == g:KillRing.LastPos
          \ && reg[1] == g:KillRing.LastReg[1]
      let g:KillRing.Text[0][0] = g:KillRing.Text[0][0].@"
    elseif len(g:KillRing.Text) >= g:KillRingMax
      call remove(g:KillRing.Text, -(len(g:KillRing.Text)-g:KillRingMax+1), -1)
      call insert(g:KillRing.Text, reg)
    else
      call insert(g:KillRing.Text, reg)
    endif

    let g:KillRing.LastPos = getpos('.')
    let g:KillRing.LastReg = reg
  else
    let g:KillRing.LastPos = getpos('.')
    if g:KillRing.Put > 0
      if g:KillRing.Put > 1
        let g:KillRing.Put = 0
      else
        let g:KillRing.Put += 1
      endif
    endif
  endif
endfunction
"}}}
function! s:CreateTempBuffer(bufname) "{{{
  let winnum = bufwinnr(a:bufname)
  let curwinnum = winnr()
  if winnum != -1
    if curwinnum == winnum
      return winnum
    endif
  else
    exe 'silent! bo sp '. a:bufname
    silent! setlocal bt=nofile bh=delete noswf nobl
    let winnum = bufwinnr('%')
    exe curwinnum . 'wincmd w'
  endif
  return winnum
endfunction
"}}}
function! s:GetTypeName(type) "{{{
  if type(a:type) == 0 && a:type == 0
    return 'unknown'
  elseif a:type == 'v'
    return 'characterwise'
  elseif a:type == 'V'
    return 'linewise'
  else
    return 'blockwise-visual' . (a:type[1:] != 0 ? ' ('.a:type[1:].')' : '')
  endif
endfunction
"}}}
function! s:KillRingPut(before) "{{{
  if empty(g:KillRing.Text)
    return
  endif

  let g:KillRing.After = empty(a:before)
  let g:KillRing.Curwinnr = winnr()
  let winnum = s:CreateTempBuffer('-KillRing-')

  let width = winwidth(bufwinnr(winnum)) - 30
  if width < 0
    let width = width/2
  endif
  let kill_ring = ''
  for text in g:KillRing.Text
    let typename = s:GetTypeName(text[1])
    let kill_ring = kill_ring.'---{ '.typename.' }-'.repeat('-', width-len(typename)-1)."\n"
    let kill_ring = kill_ring.text[0]."\n"
  endfor

  " Get a copy of the selected lines
  let keepz = @z
  let @z = kill_ring
  exe winnum . 'wincmd w'
  %d _
  silent! put z
  1d_

  let pat = '^---{ \%(characterwise\|linewise\|blockwise-visual\%( (\d\+)\)\?\|unknown\) }-\+$'
  redir @z>
  exec 'silent! g/'.pat.'/num'
  redir END

  syn clear
  exec 'match Special /'.pat.'/'
  setl noma nowrap

  let b:KillRingLineIndex = map(split(@z, "\n"), 'str2nr(matchstr(v:val, ''^\s*\zs\d\+''))')
  nmap <buffer> <silent> <C-N> :call <SID>Browse(0)<CR>
  nmap <buffer> <silent> <C-P> :call <SID>Browse(1)<CR>
  nmap <buffer> <silent> <CR>  :call <SID>PutText()<CR>

  normal! gg
  let @z = keepz
endfunction
"}}}
function! s:Browse(next) "{{{
  let index = s:GetIndex()
  if index < 0
    return
  endif
  if empty(a:next)
    let index = (index+1) % len(b:KillRingLineIndex)
  else
    let index = (index-1+len(b:KillRingLineIndex)) % len(b:KillRingLineIndex)
  endif
  call cursor(b:KillRingLineIndex[index], col('.'))
endfunction
"}}}
function! s:PutText() "{{{
  let index = s:GetIndex()
  close
  let text = g:KillRing.Text[index]
  exe g:KillRing.Curwinnr . 'wincmd w'
  let save_reg = [@z, getregtype('z')]
  call setreg('z', text[0], text[1])
  if g:KillRing.After
    normal! "zp
  else
    normal! "zP
  endif
  call setreg('z', save_reg[0], save_reg[1])
endfunction
"}}}
function! s:GetIndex() "{{{
  let cline = line('.')
  for index in range(len(b:KillRingLineIndex))
    if cline < b:KillRingLineIndex[index]
      return index-1
    endif
  endfor
  return len(b:KillRingLineIndex)-1 
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
