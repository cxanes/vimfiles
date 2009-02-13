" wikidpad.vim
" Last Modified: 2008-12-09 08:13:31
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_wikidpad')
  finish
endif
let loaded_wikidpad = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
if !(has('clientserver') && has('python'))
  finish
endif

let s:wikidpad_servername = 'WIKIDPAD'

function! wikidpad#StartVim(wikidpad_addr) 
  if v:servername ==? s:wikidpad_servername
    call wikidpad#CreateBuffer(a:wikidpad_addr)
    return 0
  endif

  let wikidpad_addr = substitute(a:wikidpad_addr, "'", "''", 'g')
  for servername in split(serverlist(), "\n")
    if servername ==? s:wikidpad_servername
      call remote_foreground(servername)
      call remote_send(servername, 
            \ printf("\<C-\\>\<C-N>:call wikidpad#CreateBuffer('%s')\<CR>", wikidpad_addr))
      return 1
    endif
  endfor

  if has('win32') || has('win32unix') || has('win64')
            \ || has('win95') || has('win16')
    exec '!start gvim --servername ' . s:wikidpad_servername 
          \ . printf(' -c "call wikidpad#CreateBuffer(''%s'')"', wikidpad_addr)
  else
    exec '!gvim --servername ' . s:wikidpad_servername
          \ . printf(' -c "call wikidpad#CreateBuffer(''%s'')" &', wikidpad_addr)
  endif
  return 1
endfunction

function! s:GetUri() 
  if !exists('g:wikidpad_addr')
    echoerr "Variable 'g:wikidpad_addr' doesn't exist"
  endif
  return printf('http://%s', g:wikidpad_addr)
endfunction

if exists('*fnameescape')
  let s:Fnameescape = function('fnameescape')
else
  function! s:Fnameescape(string) 
    let fname = escape(a:string, " \t\n*?[{`$\\%#'\"|!<")
    if fname =~ '^[\-+]\|^-$'
      let fname = '\' . fname
    endif
    return fname
  endfunction
endif

python <<EOF
import xmlrpclib
import vim

def check_server(f):
  def new_f(cls, *args, **kwds):
    if not cls.wikidpad_exists:
      return
    return f(cls, *args, **kwds)
  new_f.func_name = f.func_name
  return new_f

class WikidPad(object):
  wikidpad_exists = False
  
  @classmethod
  @check_server
  def SetContent(cls, wikiword, content):
    vim.command('silent %d_')
    vim.command("let b:wikiword = '%s'" % wikiword.replace("'", "''"))
    vim.command("silent exec 'file ' . s:Fnameescape('%s')" % (wikiword.replace("'", "''"), ))
    vim.current.buffer.append(content.split("\n"))
    del vim.current.buffer[0]

  @classmethod
  @check_server
  def GetServer(cls):
    uri = vim.eval('s:GetUri()')
    return xmlrpclib.ServerProxy(uri)

  @classmethod
  @check_server
  def GetCurrentPage(cls, s = None):
    if s is None:
      s = WikidPad.GetServer()
    [wikiword, content] = s.GetCurrentPage()
    wikiword = wikiword.data
    content = content.data
    WikidPad.SetContent(wikiword, content)
    vim.command('setl nomod')

  @classmethod
  @check_server
  def UpdateCurrentPage(cls, s = None):
    text = "\n".join(vim.current.buffer[:])
    if s is None:
      s = WikidPad.GetServer()
    s.UpdateCurrentPage(xmlrpclib.Binary(text))

  @classmethod
  @check_server
  def OpenWikiPage(cls, word, anchor = '', s = None):
    if s is None:
      s = WikidPad.GetServer()
    [wikiword, content] = s.OpenWikiPage(xmlrpclib.Binary(word), xmlrpclib.Binary(anchor))
    wikiword = wikiword.data
    content = content.data
    WikidPad.SetContent(wikiword, content)

  @classmethod
  @check_server
  def VimClosed(cls, s = None):
    if s is None:
      s = WikidPad.GetServer()
    s.VimClosed()
 
  @classmethod
  @check_server
  def GetCompleteWords(cls, line, s = None):
    if s is None:
      s = WikidPad.GetServer()
    [tofind, words] = s.GetCompleteWords(xmlrpclib.Binary(line))
    tofind = tofind.data
    words = map(lambda v: v.data, words)
    return [tofind, words]

  @classmethod
  def ExitWikidPad(cls):
    cls.wikidpad_exists = False

EOF

function! s:GetMatch(pat, lnum, col) 
  let pos = getpos('.')
  try
    let pat = printf('\%%%dl%s', a:lnum, a:pat)

    call cursor(a:lnum, a:col)
    if search(pat, 'bcW', a:lnum) != 0
      let m_beg = col('.')
      if search(pat, 'ecW', a:lnum) != 0
        let m_end = col('.')
        if a:lnum == line('.') && m_end < a:col
          return ''
        endif
      end
      if line('.') != a:lnum
        call cursor(a:lnum, 1)
        let m_end = col('$')
      endif
      return getline(a:lnum)[m_beg-1 : m_end-1]
    endif

    return ''
  finally
    call setpos('.', pos)
  endtry
endfunction

function! s:GetCursorWikiWord() 
  return s:GetWikiWord(line('.'), col('.'))
endfunction

function! s:GetWikiWord(lnum, col) 
  let editor_pat = '\%(#\%(\%(\%(#.\)\|[^ \t\n#]\)\+\)\|!\%\([A-Za-z0-9_]\+\)\)\?'
  let wikiword_pat = '\[[a-zA-Z0-9_ \t-]\{-1,}\%(\%(\s*|\)\%(\%([^\\]\|\\.\)\{-1,}\)\)\?\]' . editor_pat
  let m = s:GetMatch(wikiword_pat, a:lnum, a:col)
  if m != ''
    return m
  endif

  let wikiword_pat = '\<\%(\~\)\@<!\%([A-Z\xc0-\xde\x8a-\x8f]\+[a-z\xdf-\xff\x9a-\x9f]\+[A-Z\xc0-\xde\x8a-\x8f]\+[a-zA-Z0-9\xc0-\xde\x8a-\x8f\xdf-\xff\x9a-\x9f]*\|[A-Z\xc0-\xde\x8a-\x8f]\{2,}[a-z\xdf-\xff\x9a-\x9f]\+\)\>' . editor_pat
  let m = s:GetMatch(wikiword_pat, a:lnum, a:col)
  if m != ''
    return m
  endif

  return ''
endfunction

function! wikidpad#VimClosed() 
  py WikidPad.VimClosed()
endfunction

function! wikidpad#OpenWikiPage(word, ...) 
  let anchor = a:0 > 0 ? a:1 : ''
  if exists('b:wikiword') && b:wikiword == a:word
    py WikidPad.OpenWikiPage(vim.eval('a:word'), vim.eval('anchor'))
  else
    try
      let ul = &ul

      " remove all undos
      setl ul=-1
      py WikidPad.OpenWikiPage(vim.eval('a:word'), vim.eval('anchor'))
    finally
      let &l:ul = ul
    endtry
  endif
  setl nomod
endfunction

function! wikidpad#UpdateCurrentPage() 
  py WikidPad.UpdateCurrentPage()
  setl nomod
endfunction

function! wikidpad#RemoteExitWikidPad() 
  if v:servername == s:wikidpad_servername
    call wikidpad#ExitWikidPad()
  else
    call remote_send(s:wikidpad_servername, "\<C-\\>\<C-N>:call wikidpad#ExitWikidPad()\<CR>")
  endif
endfunction

function! wikidpad#ExitWikidPad() 
  py WikidPad.ExitWikidPad()
endfunction

function! wikidpad#RemoteGetCurrentPage() 
  if v:servername == s:wikidpad_servername
    call wikidpad#GetCurrentPage(1) 
  else
    call remote_send(s:wikidpad_servername, "\<C-\\>\<C-N>:call wikidpad#GetCurrentPage(1)\<CR>")
  endif
endfunction

function! wikidpad#GetCurrentPage(...) 
  if a:0 > 0 && a:1 != 0
    call s:PushWikiWordHistory()
  endif
    
  try
    let ul = &ul

    " remove all undos
    setl ul=-1
    py WikidPad.GetCurrentPage()
  finally
    let &l:ul = ul
  endtry
endfunction

function! s:GetCompleteWords() 
  let line = col('.') == 1 ? '' : getline('.')[ : (col('.')-2)]
  let [tofind, words] = ['', []]
python << EOF
[tofind, words] = WikidPad.GetCompleteWords(vim.eval('line'))
if tofind != '':
  vim.command("let tofind = '%s'" % tofind.replace("'", "''"))
  vim.command("let words = [%s]" % ",".join(map(lambda v: ("'%s'" % v.replace("'", "''")), words)))
EOF
  return [tofind, words]
endfunction

function! s:CompleteWords(findstart, base) 
  if a:findstart
    let [s:wikidpad_tofind, s:wikidpad_words] = s:GetCompleteWords()
    if s:wikidpad_tofind == ''
      return -1
    else
      return col('.') - strlen(substitute(s:wikidpad_tofind, ".", "x", "g")) - 1
    endif
  else
    return s:wikidpad_words
  endif
endfunction

function! s:PushWikiWordHistory() 
  if !exists('b:wikiword_history')
    let b:wikiword_history = []
  endif
  
  if exists('b:wikiword')
    call add(b:wikiword_history, [b:wikiword, getpos('.')])
  endif
endfunction

function! s:PopWikiWordHistory() 
  if !exists('b:wikiword_history') || empty(b:wikiword_history)
		echohl ErrorMsg | echo "WikidPad: at bottom of wikiword stack" | echohl None
    return []
  endif
  
  return remove(b:wikiword_history, -1)
endfunction

function! s:ParseWikiWord(word) 
  let word = a:word
  let anchor = ''
  let editor_pat = '\(#\%(\%(#.\)\|[^ \t\n#]\)\+\)\|\(![A-Za-z0-9_]\+\)$'
  let list = matchlist(word, editor_pat)
  if !empty(list)
    if list[1] != ''
      let anchor = list[1]
    elseif list[2] != ''
      let anchor = list[2]
    endif
    let word = substitute(word, editor_pat, '', '')
  endif
  if word != '' && word[0] != '['
    return [word, anchor]
  else
    let word = substitute(word, 
          \ '\[\([a-zA-Z0-9_ \t-]\{-1,}\)\%(\%(\s*|\)\%(\%([^\\]\|\\.\)\{-1,}\)\)\?\]', '\1', 'g')
    return [word, anchor]
  endif
endfunction

function! s:JumpToWikiword() 
  let word = s:GetCursorWikiWord()
  if word == ''
		echohl ErrorMsg | echo "WikidPad: not wikiword" | echohl None
    return
  endif

  call s:PushWikiWordHistory()
  let [word, anchor] = s:ParseWikiWord(word)
  call wikidpad#OpenWikiPage(word, anchor)
  if anchor != ''
    let pos = getpos('.')
    call cursor(1, 1)
    if anchor[0] == '!'
      if search(printf('\V\^\s\*anchor:\s\*%s\$', escape(anchor[1:], '\')), 'w') == 0
        call setpos('.', pos)
      endif
    else
      let anchor = substitute(anchor[1:], '#\(.\)', '\1', 'g')
      if search(printf('\V%s', escape(anchor, '\')), 'w') == 0
        call setpos('.', pos)
      endif
    endif
  endif
endfunction

function! s:JumpToOlderWikiword() 
  let history = s:PopWikiWordHistory()
  if empty(history)
    return
  endif
  let [word, pos] = history
  call wikidpad#OpenWikiPage(word)
  call setpos('.', pos)
endfunction

function! s:SID()
  if !exists('s:SID')
    let s:SID = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
  endif
  return s:SID
endfun

function! s:SetupBuffer() 
    setl bt=acwrite noswf
    setf wikidpad

    command! -buffer GetCurrentPage    call wikidpad#GetCurrentPage()
    command! -buffer UpdateCurrentPage call wikidpad#UpdateCurrentPage()

    noremap <buffer> <silent> <C-]> :<C-U>call <SID>JumpToWikiword()<CR>
    noremap <buffer> <silent> <C-T> :<C-U>call <SID>JumpToOlderWikiword()<CR>

    exec 'setlocal completefunc='.'<SNR>'.s:SID().'_CompleteWords'

    augroup WikidPad
      au!
      au BufWriteCmd <buffer> call wikidpad#UpdateCurrentPage()
      au VimLeave    <buffer> call wikidpad#VimClosed()
    augroup END
endfunction

function! wikidpad#CreateBuffer(wikidpad_addr) 
  let g:wikidpad_addr = a:wikidpad_addr
  if !exists('s:wikidpad_bufnr') || !bufloaded(s:wikidpad_bufnr) 
    new
    let s:wikidpad_bufnr = bufnr('%')
    wincmd p
    wincmd c

    call s:SetupBuffer()
  endif

  if bufnr('%') != s:wikidpad_bufnr
    exec printf('%db!', s:wikidpad_bufnr)
  endif

  py WikidPad.wikidpad_exists = True
  call wikidpad#GetCurrentPage() 

  setl lbr
endfunction


" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
