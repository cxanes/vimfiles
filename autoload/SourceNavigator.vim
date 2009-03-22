" SourceNavigator.vim
" Last Modified: 2009-03-22 22:36:03
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Modified from etc/sn.el

" Load Once {{{
if exists('loaded_autoload_SourceNavigator')
  finish
endif
let loaded_autoload_SourceNavigator = 1

if !has('python')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}
"========================================================
python << PY_EOF
import vim
import socket
_SN_Socket = None
PY_EOF

function! s:Send(string) "{{{
python << PY_EOF
if _SN_Socket is not None:
  _SN_Socket.send(vim.eval('a:string') + "\n")
PY_EOF
endfunction
"}}}
function! s:TclQuote(string) "{{{
  return '"' . escape(a:string, '[]{}\"$ ;') . '"'
endfunction
"}}}

function! SourceNavigator#Start(port) "{{{
  if type(a:port) != type(0)
    echohl ErrorMsg
    echo 'port must be number'
    echohl None
    return
  endif

python << PY_EOF
if _SN_Socket is None:
  try:
    _SN_Socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    _SN_Socket.connect(('127.0.0.1', int(vim.eval('a:port'))))
    vim.command('au VimLeavePre * call SourceNavigator#Stop()')
  except socket.error, mesg:
    _SN_Socket = None
    import sys
    if sys.platform == 'win32':
      print unicode(str(mesg), "big5").encode(vim.eval('&enc'))
    else:
      print mesg
PY_EOF
endfunction
"}}}
function! SourceNavigator#Stop() "{{{
python << PY_EOF
if _SN_Socket is not None:
  _SN_Socket.close()
  _SN_Socket = None
PY_EOF
endfunction
"}}}

" Browse the contents of a class in the Source Navigator.
function! SourceNavigator#ClassBrowser(class) "{{{
  call s:Send('sn_classbrowser ' . s:TclQuote(a:class))
endfunction
"}}}
" Browse a class in the Source Navigator hierarchy browser.
function! SourceNavigator#ClassTree(class) "{{{
  call s:Send('sn_classtree ' . s:TclQuote(a:class))
endfunction
"}}}
" Tell Source Navigator to retrieve all symbols matching pattern.
function! SourceNavigator#Retrieve(pattern) "{{{
  call s:Send('sn_retrieve_symbol ' . s:TclQuote(a:pattern) . ' all')
endfunction
"}}}
" Look up a symbol in the Source Navigator cross-referencer.
function! SourceNavigator#Xref(symbol) "{{{
  call s:Send('sn_xref both ' . s:TclQuote(a:symbol))
endfunction
"}}}

function! SourceNavigator#Update(filename) "{{{
  if empty(a:filename)
    let filename = expand('%:p')
  endif
  if filereadable(filename)
    call s:Send('sn_parse_uptodate ' . s:TclQuote(filename) . " 0")
  endif
endfunction
"}}}
"========================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
