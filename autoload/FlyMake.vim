" flymake.vim
" Last Modified: 2008-04-06 01:43:11
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" {{{ Load Once
if exists('loaded_autoload_flymake_plugin')
  finish
endif
let loaded_autoload_flymake_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
" }}}
"=======================================================
" {{{ Requirement: Vim > 7.0 +signs +autocmd +clientserver
if !(v:version >= 700 && has('signs') && has('autocmd') && has('clientserver'))
  finish
endif
" }}}
"=======================================================
" {{{ Setup
sign define FlyMakeError   text=E> texthl=Error linehl=Error
sign define FlyMakeWarning text=W> texthl=Todo  linehl=Todo

augroup FlyMake
  au!
augroup END

let s:SERVERNAME = 'FLYMAKE'
" }}}
" {{{ +balloon_eval support
if has('balloon_eval')
  function! FlyMake#BalloonExpr()
    let errlist = getbufvar(v:beval_bufnr, 'flymake_errlist')
    if !empty(errlist)
      return errlist.GetError(v:beval_lnum, v:beval_col)
    else
      return ''
    endif
  endfunction
  setlocal balloonexpr=FlyMake#BalloonExpr()
  set beval
endif
"}}}
"=======================================================
function! FlyMake#Mode(on) "{{{
  if a:on
    au! FlyMake CursorHold  <buffer> call FlyMake#ShowErr()
    au! FlyMake CursorHoldI <buffer> call FlyMake#Send()
  else
    au! FlyMake CursorHold  <buffer>
    au! FlyMake CursorHoldI <buffer>
  endif
endfunction
"}}}
function! FlyMake#FlyMake(force) "{{{
  if s:FlyMakeInit(a:force)
    return
  endif

  let loclist = s:LocalMake(b:flymake_errlist['tempname'])
  call b:flymake_errlist.Add(loclist)
  call b:flymake_errlist.HighlightErrors()
endfunction
"}}}
function! FlyMake#ShowErr() "{{{
  if !exists('b:flymake_errlist')
    return
  endif

  let err = b:flymake_errlist.GetError(line('.'), col('.'), 1)
  if empty(err) || empty(err[1])
    return
  else
    if s:IsError(err[0], err[1])
      echohl ErrorMsg | echo err[1] | echohl None
    elseif s:IsWarning(err[0], err[1])
      echohl WarningMsg | echo err[1] | echohl None
    else
      echo err[1]
    endif
  endif
endfunction
"}}}
function! FlyMake#Send() "{{{
  if s:FlyMakeInit(0)
    return
  endif

  if s:SetupServer()
    return
  endif

  if !exists('b:make_count')
    let b:make_count = 0
  endif

  if b:make_count == 0
    au! FlyMake RemoteReply <buffer> call <SID>FlyMakeHighlight(expand('<amatch>'))
  endif
  let b:make_count += 1

  let cmd = printf("\<C-\\>\<C-N>:call FlyMake#RemoteMake('%s')\<CR>", 
        \ fnamemodify(b:flymake_errlist['tempname'], ':p'))
  call writefile(getline(1, '$'), b:flymake_errlist['tempname'])
  call remote_send(s:SERVERNAME, cmd)
	if has('gui_running')
    sleep 100m
    call remote_foreground(v:servername)
  endif
endfunction
"}}}
function! FlyMake#RemoteMake(source) "{{{
  exec 'cd ' . fnamemodify(a:source, ':p:h')
  let source = fnamemodify(a:source, ':p:t')
  exec 'vie ' . source
  call s:Make(source)
  call server2client(expand('<client>'), string([bufnr('.'), getloclist(winnr())]))
  exec 'bd ' . source
endfunction
"}}}
function! FlyMake#MoveToError(next) "{{{
  if !exists('b:flymake_errlist')
    return
  endif

  let lines = sort(map(copy(keys(b:flymake_errlist.position)), 'v:val+0'), 's:NumCompare')

  if empty(lines)
    return
  endif

  let [cur_num, cur_col] = [line('.'), col('.')]

  if a:next
    for lnum in lines
      if lnum > cur_num
        call cursor(lnum, cur_col)
        return
      endif
    endfor
    if !empty(lines)
      call cursor(lines[0], cur_col)
      return
    endif
  else
    for idx in range(len(lines)-1, 0, -1)
      if lines[idx] < cur_num
        call cursor(lines[idx], cur_col)
        return
      endif
    endfor
    if !empty(lines)
      call cursor(lines[-1], cur_col)
      return
    endif
  endif
endfunction

func s:NumCompare(i1, i2)
   return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunc
"}}}
"=======================================================
" {{{ Class: ErrorList
" {{{ Public Method: ctor
function! s:NewErrorList() 
  let self = {
        \   'tempname': s:Tempname(),
        \   'matchIdList': {},
        \   'position': {},
        \   'Add':      function('s:ErrorList_Add'),
        \   'Clear':    function('s:ErrorList_Clear'),
        \   'GetError': function('s:ErrorList_GetError'),
        \   'HighlightErrors': function('s:ErrorList_HighlightErrors'),
        \   'ClearHighlight':  function('s:ErrorList_ClearHighlight'),
        \ }
  return self
endfunction
" }}}
" {{{ Public Method: ClearHighlight
function! s:ErrorList_ClearHighlight(...) dict
  if a:0 != 0
    if has_key(self.matchIdList, a:1)
      call remove(self.matchIdList, a:1)
      exec printf('sign unplace %d buffer=%d', a:1, bufnr(''))
    endif
    return
  endif
    
  for id in keys(self.matchIdList)
    exec printf('sign unplace %d buffer=%d', id, bufnr(''))
  endfor
  let self.matchIdList = {}
endfunction
"}}}
" {{{ Public Method: Clear
function! s:ErrorList_Clear() dict
  let self.position = {}
endfunction
" }}}
" {{{ Public Method: HighlightErrors
function! s:ErrorList_HighlightErrors() dict
  if empty(self.position)
    call self.ClearHighlight()
    return
  endif

  let curbufnr = bufnr('')
  let list = {}
  let m = 1

  for [line, cols] in items(self.position)
    for [col, item] in items(cols)
      let line_pat = '\%' . line . 'l'

      if s:IsError(item.type, item.text)
        let type = 'FlyMakeError'
      elseif s:IsWarning(item.type, item.text)
        let type = 'FlyMakeWarning'
      else
        continue
      endif

      if len(self.matchIdList) == 1 && has_key(self.matchIdList, m)
        let m += 1
      else
        call self.ClearHighlight(m)
      endif

      let list[m] = line
      exec printf('sign place %d line=%d name=%s buffer=%d', m, line, type, curbufnr)
      let m += 1
    endfor
  endfor
  call self.ClearHighlight()
  let self.matchIdList = list
endfunction
" }}}
" {{{ Public Method: Add
function! s:ErrorList_Add(item, ...) dict
  if type(a:item) == type([])
    if a:0 == 0
      for i in a:item
        call self.Add(i)
      endfor
    else
      for i in a:item
        call self.Add(i, a:1)
      endfor
    endif
    return 
  endif

  let tempbufnr = a:0 == 0 ? bufnr(self.tempname) : a:1
  if a:item['bufnr'] != tempbufnr || !a:item.valid
    return
  endif

  let [lnum, col, vcol] = [a:item['lnum'], a:item['col'], a:item['vcol']]
  if !has_key(self.position, lnum)
    let self.position[lnum] = {}
  endif

  let col = vcol ? s:VColToCol(col, getline(lnum)) : col
  let temp_pat = '\V'. escape(self.tempname, '\')
  let file_pat = escape(bufname(''), '\&~')
  if !has_key(self.position[lnum], col)
    let self.position[lnum][col] = { 
          \   'pattern': s:GetPattern(a:item), 
          \   'text':    substitute(a:item['text'], temp_pat, file_pat, 'g'),
          \   'type':    a:item['type'],
          \ }
  endif
endfunction
" }}}
" {{{ Public Method: GetError
function! s:ErrorList_GetError(lnum, col, ...) dict " ... = with_type
  let id = s:GetSignID(a:lnum)
  if a:0 == 0 || a:1 == 0
    let null = ''
  else
    let null = []
  endif

  if id == -1
    return null
  endif

  if !has_key(self.matchIdList, id)
    return null
  endif

  let lnum = self.matchIdList[id] + 0
  if !has_key(self.position, lnum)
    return null
  endif

  let cols = keys(self.position[lnum])

  if empty(cols)
    return null
  endif

  call map(cols, 'str2nr(v:val)')
  let ncols = filter(copy(cols), 'a:col > v:val')

  if !empty(ncols)
    let cols = ncols
  endif

  call sort(cols)

  let line = getline(a:lnum)
  let items = self.position[lnum]

  let item = items[cols[0]]
  if a:0 == 0 || a:1 == 0
    return item['text']
  else
    return [item['type'], item['text']]
  endif

  " for col in cols
  "   let item = items[col]
  "   if col <= a:col && a:col <= strlen(matchstr(line, '^.\{-}'.item['pattern']))
  "     if a:0 == 0 || a:1 == 0
  "       return item['text']
  "     else
  "       return [item['type'], item['text']]
  "     endif
  "   endif
  " endfor

  return null
endfunction
" }}}
" {{{ Utilities
function! s:VColToCol(vcol, line) "{{{
  return a:vcol
endfunction
"}}}
function! s:Tempname() "{{{
  let stamp = '.temp-' . strftime('%Y%m%d%H%M%S') . '.'
  if expand('%:e') == ''
    return stamp . &ft
  else
    return stamp . expand('%:e') 
  endif
endfunction
"}}}
function! s:GetPattern(item) "{{{
  let col_pat = a:item.vcol ? 'v' : 'c'
  let pattern = ''

  if a:item.col + 0 == 0
    let pattern .= empty(a:item.pattern) ?  '\S.*' : a:item['pattern']
  else
    let pattern .= '\%>' . (a:item['col']-1) . col_pat 
    let pattern .= empty(a:item['pattern']) ? '.*' : a:item['pattern']
  endif

  return pattern
endfunction
"}}}
function! s:GetSignID(lnum) "{{{
  if a:lnum < 0 || a:lnum > line('$')
    return -1
  endif

  redir => signs
  exec 'silent! sign place buffer=' . bufnr('')
  redir End

  let lnum = a:lnum + 0
  for line in split(signs, '\n')
    let m = matchlist(line, 'line=\(\d\+\)\s\+id=\(\d\+\)\s\+name=\(\w\+\)')
    if !empty(m) && m[3] =~ '^FlyMake' && str2nr(m[1]) == lnum
      return str2nr(m[2])
    endif
  endfor
  return -1
endfunction
" }}}
function! s:IsError(type, text) "{{{
  return a:type ==? 'e' || a:text =~? 'error'
endfunction
"}}}
function! s:IsWarning(type, text) "{{{
  return !(a:type ==? 'e' || a:text =~? 'error')
  " return a:type ==? 'w' || a:text =~? 'warning'
endfunction
"}}}
" }}}
" }}}
"=======================================================
function! s:SetupServer() "{{{
  if index(split(serverlist(), '\n'), s:SERVERNAME) != -1
    return
  endif

  if has('win32') || has('win64')
    exec 'silent !start vim --servername ' . s:SERVERNAME . ' -c "set co=20 lines=10"'
  else
    echohl ErrorMsg
    echo   'Please start a new VIM to be the server (name it ' . s:SERVERNAME . '),'
    echo   'so we can compile the code in it.'
    call FlyMake#Mode(0)
    return 1
  endif
  sleep 1
endfunction
"}}}
function! s:FlyMakeInit(force) "{{{
  if !exists('b:flymake_errlist')
    let b:flymake_errlist = s:NewErrorList()
  endif

  if !exists('b:flymake_time')
    let b:flymake_time = 0
  endif

  if !a:force && (localtime() - b:flymake_time) < &ut/1000 + 2
    return 1
  endif

  let b:flymake_time = localtime()
  call b:flymake_errlist.Clear()
  return 0
endfunction
"}}}
function! s:LocalMake(tempname) "{{{
  call writefile(getline(1, '$'), a:tempname)
  call s:Make(a:tempname)
  call delete(a:tempname)
  return getloclist(winnr())
endfunction
"}}}
function! s:Make(source) "{{{
  let sp_sav = &sp
  let mp_sav = &mp

  let &sp = '>%s 2>&1'
  if &ft == 'perl'
    let &mp = 'perl -Wc '
    let cmd = printf("silent! lmake! '%s'", a:source)
  elseif &ft == 'python'
    " http://vim.wikia.com/wiki/Python_-_check_syntax_and_run_script
    let &mp = 'python -c "import py_compile,sys; sys.stderr=sys.stdout; py_compile.compile(r''$*'')"'
    let cmd = printf("silent! lmake! %s", a:source)
  else
    let &mp = 'make'
    let cmd = printf("silent! lmake! CHK_SOURCES='%s' check-syntax", a:source)
  endif

  redir => dummy
  exec cmd 
  redir END

  if &ft == 'python' && filereadable(a:source . 'c')
    call delete(a:source . 'c')
  endif

  let &sp = sp_sav
  let &mp = mp_sav
endfunction
"}}}
function! s:FlyMakeHighlight(serverid) "{{{
  let [tempbufnr, loclist] = eval(remote_read(a:serverid))
  call delete(b:flymake_errlist['tempname'])
  let b:make_count -= 1
  if b:make_count <= 0
    au! FlyMake RemoteReply <buffer>
  endi
  call b:flymake_errlist.Add(loclist, tempbufnr)
  call b:flymake_errlist.HighlightErrors()
  redraw
endfunction
"}}}
"=======================================================
" Restore {{{ let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
