" Stickies.vim
"
" Send commands to Stickies < http://www.zhornsoftware.co.uk/stickies >
" Last Modified: 2011-04-24 00:48:25
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_Stickies')
  finish
endif
let loaded_autoload_Stickies = 1

if !has('python')
  finish
endif

let s:MSWIN =  has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')

if !s:MSWIN
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}

let s:has_error = ''
let s:stickies_started = 0

" cannot use s:current_sticky_id:
" event callback function may be called out of script scope.
let g:current_sticky_id = ''
let s:latest_reply = ''

python3 <<EOF
try:
  from stickies.Stickies import Stickies
  import vim
  import re

  # http://www.zhornsoftware.co.uk/stickies/api/events.html
  def _stickies_event_callback(message):
    event_id = re.search(r'^\d+', message)
    if event_id is not None:
      event_id = int(event_id.group(0))

    if event_id in (500, 506):
      sticky_id = re.search(r'\S+$', message)
      if sticky_id is not None:
        vim.command("let g:current_sticky_id = '%s'" % sticky_id.group(0).replace("'", "''"))
    elif event_id in (501, 502):
      sticky_id = re.search(r'\S+$', message)
      if sticky_id is not None:
        sticky_id = sticky_id.group(0)
        current_sticky_id = vim.eval('g:current_sticky_id')
        if sticky_id == current_sticky_id:
          vim.command("let g:current_sticky_id = ''")

  _stickies = Stickies(event_callback = _stickies_event_callback)

except ImportError as error:
  vim.command("let s:has_error = '%s'" % str(error).replace("'", "''"))
EOF

au VimLeave * call Stickies#Stop()

if exists('g:stickies_encoding')
  let s:stickies_encoding = g:stickies_encoding
else
  let s:stickies_encoding = s:MSWIN ? 'big5' : 'utf-8'
endif

function! s:HasError() "{{{
  if empty(s:has_error) | return 0 | endif
  echohl ErrorMsg | echom 'Stickies:' s:has_error | echohl None
  return 1
endfunction
"}}}
function! Stickies#Start() "{{{
  if s:HasError() != 0 | return | endif
  py _stickies.start()
  let s:stickies_started = 1
  call Stickies#Send('do register', 0)
endfunction
"}}}
function! Stickies#Stop()"{{{
  if s:stickies_started == 0 | return | endif
  call Stickies#Send('do deregister', 0)
  py _stickies.stop()
endfunction
"}}}
function! Stickies#CreateNewSticky(content)"{{{
  call Stickies#Send('do new sticky ' . a:content)
endfunction
"}}}
function! Stickies#GetCurrentStickyID()"{{{
  return g:current_sticky_id
endfunction
"}}}
function! Stickies#GetLatestReply()"{{{
  return s:latest_reply
endfunction
"}}}
" http://www.zhornsoftware.co.uk/stickies/api/commands.html
function! Stickies#Send(cmd, ...)"{{{
  if s:HasError() != 0 | return '' | endif
  if s:stickies_started == 0
    call Stickies#Start()
  endif
  let show_message = (a:0 == 0 || (a:0 > 0 && !empty(a:1)))
  let cmd = (&enc == s:stickies_encoding ? a:cmd : iconv(a:cmd, &enc, s:stickies_encoding))
  py vim.command("let reply = '%s'" % _stickies.send(vim.eval('cmd')).replace("'", "''"))
  let reply = (&enc == s:stickies_encoding ? a:cmd : iconv(reply, s:stickies_encoding, &enc)) 
  let latest_reply = substitute(reply, '^\d\+\s*', '', '')
  if show_message
    echohl MoreMsg | echom 'Stickies:' reply | echohl None
  endif
  return reply
endfunction
"}}}
function! s:GetStickyID(sticky_id) "{{{
  if a:sticky_id == 0
    if g:current_sticky_id == ''
      echohl ErrorMsg | echom 'Stickies: Current Sticky ID invalid' | echohl None
      return ''
    endif
    return g:current_sticky_id
  endif
  return a:sticky_id
endfunction
"}}}
function! Stickies#VimCmdSend(cmd)"{{{
  if a:cmd =~ '^\w\+\s\+\w\+\s\+%\%(\s\|$\)'
    let current_sticky_id = s:GetStickyID(0)
    if empty(current_sticky_id)
      return ''
    endif
    let cmd = substitute(a:cmd, '\%(^\w\+\s\+\w\+\s\+\)\@<=%', current_sticky_id, '')
  else
    let cmd = a:cmd
  endif
  return Stickies#Send(cmd)
endfunction
"}}}
function! Stickies#GetSticky(sticky_id, type) "{{{
  let sticky_id = s:GetStickyID(a:sticky_id)
  if sticky_id == ''
    return ''
  endif
  let reply = Stickies#Send(printf('get desktop %s %s', sticky_id, a:type), 0)
  let reply_id = matchstr(reply, '^\d\+',) + 0
  let reply = substitute(reply, '^\d\+\s*', '', '')
  if reply_id != 1
    echohl ErrorMsg | echom 'Stickies:' reply | echohl None
    return ''
  endif
  return reply
endfunction
"}}}
function! Stickies#SetSticky(sticky_id, type, value) "{{{
  let sticky_id = s:GetStickyID(a:sticky_id)
  if sticky_id == 0
    return
  endif
  let reply = Stickies#Send(printf('set desktop %s %s %s', sticky_id, a:type, a:value), 0)
  let reply_id = matchstr(reply, '^\d\+',) + 0
  let reply = substitute(reply, '^\d\+\s*', '', '')
  if reply_id != 0
    echohl ErrorMsg | echom 'Stickies:' reply | echohl None
    return
  endif
endfunction
"}}}
function! Stickies#GetCurrentStickyText() "{{{
  return Stickies#GetSticky(0, 'text')
endfunction
"}}}
function! Stickies#SetCurrentStickyText(text) "{{{
  return Stickies#SetSticky(0, 'text', a:text)
endfunction
"}}}

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
