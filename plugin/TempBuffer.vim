" TempBuffer.vim
" Last Modified: 2008-08-03 11:35:57
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Create (shared) temporary buffer in new window and return the window
" number of temporary buffer.

" Load Once {{{
if exists('loaded_TempBuffer')
  finish
endif
let loaded_TempBuffer = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"=====================================================
function! CreateTempBuffer(bufname, ...) " bufInitFunc -> call a:1(a:2) {{{
  call s:ClearUnusedTempBuf(a:bufname, 0)
  let cur_bufnum = bufnr('%')
  let cur_winnum = winnr()

  if s:IsTempBufName(bufname(cur_bufnum), a:bufname, 0)
    return cur_winnum
  endif

  let args = a:000
  if !empty(args) && s:IsSplitCmd(args[0])
    let args = copy(a:000)
    let split = remove(args, 0)
  else
    let split = 'bel'
  endif

  let temp_winnum = s:TempBufwinnr(a:bufname, cur_bufnum)
  if temp_winnum != -1
    if cur_winnum == temp_winnum
      return temp_winnum
    endif

    let creator_bufnum = getbufvar(winbufnr(temp_winnum), 'TempCreatorBufnr')
    if creator_bufnum == cur_bufnum
      return temp_winnum
    endif

    if bufexists(creator_bufnum) == 0
      call setbufvar(winbufnr(temp_winnum), 'TempCreatorBufnr', cur_bufnum)
      return temp_winnum
    endif

    exe temp_winnum . 'wincmd w'
    let temp_bufloaded = 0
    let temp_bufnum = s:TempBufnr(a:bufname, cur_bufnum) 
    if temp_bufnum == -1
      silent enew
      call s:SetTempBufName(a:bufname, 0)
    else
      let temp_bufloaded = bufloaded(temp_bufnum)
      silent exec temp_bufnum . 'b'
    endif
    if temp_bufnum == -1 || !temp_bufloaded
      call s:TempBufInit(cur_bufnum)
      call call('s:TempBufInitFunc', args)
    endif
    wincmd p
    return temp_winnum
  else
    let temp_bufloaded = 0
    let temp_bufnum = s:TempBufnr(a:bufname, cur_bufnum) 
    if temp_bufnum != -1
      let temp_bufloaded = bufloaded(temp_bufnum)
      exe 'silent' split 'sb' temp_bufnum
    else
      exe 'silent' split 'new'
      call s:SetTempBufName(a:bufname, 0)
    endif
    if temp_bufnum == -1 || !temp_bufloaded
      call s:TempBufInit(cur_bufnum)
      call call('s:TempBufInitFunc', args)
    endif
    let temp_winnum = winnr()
    wincmd p
    return temp_winnum
  endif
endfunction
" }}}
function! CreateSharedTempBuffer(bufname, ...) " bufInitFunc -> call a:1(a:2) {{{
  let temp_winnum = s:TempBufwinnr(a:bufname, 0)
  let cur_winnum = winnr()
  if temp_winnum != -1
    return temp_winnum
  else
    let args = a:000
    if !empty(args) && s:IsSplitCmd(args[0])
      let args = copy(a:000)
      let split = remove(args, 0)
    else
      let split = 'bel'
    endif

    let temp_bufloaded = 0
    let temp_bufnum = s:TempBufnr(a:bufname, 0) 
    if temp_bufnum != -1
      let temp_bufloaded = bufloaded(temp_bufnum)
      exe 'silent' split 'sb' temp_bufnum
    else
      exe 'silent' split 'new'
      call s:SetTempBufName(a:bufname, 1)
    endif
    if temp_bufnum == -1 || !temp_bufloaded
      call s:TempBufInit(0)
      call call('s:TempBufInitFunc', args)
    endif
    let temp_winnum = winnr()
    wincmd p
  endif
  return temp_winnum
endfunction
" }}}
"=====================================================
function! s:IsSplitCmd(cmd) "{{{
  return a:cmd =~ '^\s*\%(vert\%[ical]\s\+\)\?\%(lefta\%[bove]\|abo\%[veleft]\|rightb\%[elow]\|bel\%[owright]\|to\%[pleft]\|bo\%[tright]\)\?\s*\%(\d\+\)\?\s*$' && a:cmd !~ '^\s*$'
endfunction
"}}}
function! s:IsTempBufName(bufname, temp_bufname, shared) "{{{
  return a:bufname =~ printf('^\V%s%s\$', 
        \ escape(a:temp_bufname, '\'), (a:shared ? '' : '\[\d\+\]'))
endfunction
"}}}
function! s:ClearUnusedTempBuf(bufname, shared) "{{{
  let last_buffer = bufnr('$')
  let bufnum = 1
  while bufnum <= last_buffer
    if bufexists(bufnum) && s:IsTempBufName(bufname(bufnum), a:bufname, a:shared)
      if a:shared
        exec bufname . 'bd'
      else
        let creator_bufnr = getbufvar(bufnum, 'TempCreatorBufnr') + 0
        if creator_bufnr > 0 && !bufexists(creator_bufnr)
          exec bufnum . 'bd'
        endif
      endif
    endif
    let bufnum += 1
  endwhile
endfunction
"}}}
function! s:TempBufnr(temp_bufname, creator_bufnr) "{{{
  let shared = a:creator_bufnr <= 0
  let last_buffer = bufnr('$')
  let bufnum = 1
  let unused_bufnum = -1
  while bufnum <= last_buffer
    if bufexists(bufnum) && s:IsTempBufName(bufname(bufnum), a:temp_bufname, shared)
      if shared
        return bufnum
      endif

      let creator_bufnr = getbufvar(bufnum, 'TempCreatorBufnr') + 0
      if creator_bufnr == a:creator_bufnr
        return bufnum
      elseif unused_bufnum == -1 
            \ && (creator_bufnr == 0 || !bufexists(creator_bufnr))
        let unused_bufnum = bufnum
      endif
    endif
    let bufnum += 1
  endwhile
  if unused_bufnum != -1
    call setbufvar(unused_bufnum, 'TempCreatorBufnr', a:creator_bufnr)
    return unused_bufnum
  endif
  return -1
endfunction
"}}}
function! s:TempBufInit(creator_bufnr) "{{{
  silent setlocal bt=nofile noswf nobl
  if a:creator_bufnr > 0
    let b:TempCreatorBufnr = a:creator_bufnr
  else " shared
    silent setlocal bh=delete
  endif
endfunction
"}}}
function! s:TempBufInitFunc(...) "{{{
  if a:0 == 0
    return
  endif

  let arglist = []
  if a:0 > 1
    if type(a:2) != type([])
      let arglist = [ a:2 ]
    else
      let arglist = a:2
    endif
  endif
  call call(a:1, arglist)
endfunction
"}}}
function! s:SetTempBufName(bufname, shared) "{{{
  if !exists('s:new_temp_buf_id')
    let s:new_temp_buf_id = 1
  endif

  setlocal bt=nofile noswf
  if a:shared
    silent exec printf('f %s', escape(a:bufname, ' '))
  else
    silent exec printf('f %s\[%d\]', escape(a:bufname, ' '), s:new_temp_buf_id)
    let s:new_temp_buf_id += 1
  endif
endfunction
"}}}
function! s:TempBufwinnr(temp_bufname, creator_bufnr) "{{{
  let shared = a:creator_bufnr <= 0
  let last_buffer = bufnr('$')
  let bufnum = 1
  let unused_bufwinnum = -1
  while bufnum <= last_buffer
    if bufloaded(bufnum) && s:IsTempBufName(bufname(bufnum), a:temp_bufname, shared)
      let winnum = bufwinnr(bufnum)
      if winnum != -1
        if shared
          return winnum
        else
          let creator_bufnr = getbufvar(bufnum, 'TempCreatorBufnr') + 0
          if creator_bufnr == a:creator_bufnr
            return winnum
          elseif unused_bufwinnum == -1 && bufwinnr(creator_bufnr) == -1
            let unused_bufwinnum = winnum
          endif
        endif
      endif
    endif
    let bufnum += 1
  endwhile
  if unused_bufwinnum != -1
    retur unused_bufwinnum
  endif
  return -1
endfunction
"}}}
"=====================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
