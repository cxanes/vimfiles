" Man.vim
" Last Modified: 2008-08-03 14:00:37
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Some code comes from manpageview.vim
" <http://www.vim.org/scripts/script.php?script_id=489>

" Load Once {{{
if exists('loaded_autoload_Man')
  finish
endif
let loaded_autoload_Man = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"==================================================
" Utilities
"==================================================
" +python {{{
let s:has_python = 0
if has('python') && (has('win32') || has('win32unix') || has('win64') || has('win95') || has('win16'))
  let s:has_python = 1
python <<EOF
import vim, os
def ManSystem(cmd):
  try:
    f = os.popen(cmd, "r")
    lines = f.readlines()
    if len(lines) != 0:
      vim.current.buffer.append(lines)
    retcode = f.close()
    if retcode is not None:
      vim.command('let error = ' + str(retcode))
  except IOError:
    vim.command('let error = 1')
EOF
endif
"}}}
function! s:ShowMesg(mesg, ...) "{{{
  let hl = a:0 == 0 ? 'WarningMsg' : a:1
  exe 'echohl ' . hl
  echom a:mesg
  echohl None
endfunction
" }}}
function! s:SID() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
"}}}
function! s:Function(func) "{{{
  return '<SNR>' . s:SID() . '_' . a:func
endfunction
"}}}
function! s:System(cmd, opt, args) "{{{
  if type(a:args) == type([])
    let args = a:args
  else
    let args = [a:args]
  endif

  let srr_sav = &srr
  let tmpfile = tempname()
  let error = 0
  silent %d _
  if s:has_python
    let cmd = printf('%s %s %s 2>%s', a:cmd, a:opt, join(args, ' '), tmpfile)
    python ManSystem(vim.eval('cmd'))
  else
    let &srr= '>%s 2>' . tmpfile
    let cmd = printf('1r !%s %s %s', a:cmd, a:opt, escape(join(args, ' '), '%#!'))
    silent exe cmd
    let error = v:shell_error
    let &srr = srr_sav
  endif
  if error
    silent %d _
    call append(1, readfile(tmpfile))
  endif
  call delete(tmpfile)
  silent 1d _
  return error
endfunction
"}}}
"==================================================
" Settings
"==================================================
function! s:GetSetting(type, bang) "{{{
  let type = tolower(a:type)
  let setting = s:GetSettingTemplate()
  if type == ''
    if exists('g:man_setting') && type(g:man_setting) == type({})
      for [key, value] in items(g:man_setting)
        let setting[key] = value
      endfor
    else
      return s:GetSetting('man', 0)
    endif
  elseif exists('g:man_setting_{type}') && type(g:man_setting_{type}) == type({})
    for key in keys(g:man_setting_{type})
      let setting[key] = g:man_setting_{type}[key]
    endfor
  endif

  if exists('b:man_setting_{type}') && type(b:man_setting_{type}) == type({})
    for [key, value] in items(b:man_setting_{type})
      let setting[key] = value
    endfor
  endif

  if a:bang && !empty(setting['bang'])
    call call(setting['bang'], [setting])
  endif

  if setting['cmd'] == ''
    let setting = s:GetSettingTemplate()
    let setting['cmd'] = 'man'
    return setting
  endif

  return setting
endfunction
"}}}
function! s:GetSettingTemplate() "{{{
    return {
          \   'cmd'    : '',
          \   'opt'    : '',
          \   'bufname': '__man__',
          \   'init'   : s:Function('ManBufInit'),
          \   'input'  : '',
          \   'bang'   : '',
          \   'args_parser': 'Man#SimpleArgsParser',
          \ }
endfunction
"}}}
function! s:InitSetting() "{{{
  if !exists('g:man_setting_perl')
    let g:man_setting_perl = { 
          \   'cmd': 'perldoc',
          \   'opt': ['-f', '', '-q'],
          \   'bufname': '__perldoc__', 
          \   'K': s:Function('K_Map_perl'),
          \ }
  endif

  if !exists('g:man_setting_python')
    let g:man_setting_python = { 
          \ 'cmd': 'pydoc', 'bufname': '__pydoc__', 'init': s:Function('PyManBufInit') }
  endif

  if !exists('g:man_setting_ruby')
    let g:man_setting_ruby = { 
          \ 'cmd': 'ri', 'bufname': '__ri__', 'opt': '-f plain', 'init': s:Function('RiManBufInit') }
  endif

  if !exists('g:man_setting_info')
    let g:man_setting_info = { 
          \ 'cmd': 'info', 'bufname': '__info__', 'opt': '-o-', 
          \ 'input': s:Function('InfoInput'),
          \ 'init': s:Function('InfoManBufInit') }
  endif
endfunction
"}}}
call s:InitSetting()
"==================================================
" Global Function
"==================================================
function! Man#Main(type, bang, line) "{{{
  if a:type ==? 'vim' || a:type ==? 'help'
    if type(a:line) == type([])
      exec 'help' join(a:line, ' ')
    else
      exec 'help' a:line
    end
    return
  endif

  let setting = s:GetSetting(a:type, a:bang)
  if type(a:line) == type([])
    let args = a:line
  else
    let line = a:line

    if line == ''
      let input = setting['input']
      if input == ''
        call s:ShowMesg('E471: Argument required', 'ErrorMsg')
        return
      endif

      let line = call(input, [])

      if line == ''
        call s:ShowMesg('E471: Argument required', 'ErrorMsg')
        return
      end
    endif

    let args_parser = setting['args_parser']
    if args_parser == ''
      let args = [line]
    else
      let args = call(args_parser, [line])
    endif
  endif

  let curwinnum = winnr()

  " CreateSharedTempBuffer(): Defined in TempBuffer.vim
  let winnum = CreateSharedTempBuffer(setting['bufname'])

  exe winnum . 'wincmd w'
  silent %d _

  let opts = setting['opt']
  let error_mesg = ''

  let q_args = copy(args)
  if exists('*mylib#Shellescape')
    call map(q_args, 'mylib#Shellescape(v:val)')
  else
    call map(q_args, 'shellescape(v:val)')
  endif


  let has_error = 0
  if type(opts) == type([]) && !empty(opts)
    for opt in opts
      if s:System(setting['cmd'], opt, q_args)
        if !empty(error_mesg)
          let error_mesg .= "\n"
        endif
        let error_mesg .= join(getline(1, '$'), "\n")
        let has_error = 1
      else
        let has_error = 0
        break
      endif
    endfor
    if has_error
      silent %d _
      1put =error_mesg
      silent 1d _
    endif
  elseif type(opts) == type('')
    call s:System(setting['cmd'], opts, q_args)
  else
    call s:System(setting['cmd'], '', q_args)
  endif

  let b:man_buf_type_last = exists('b:man_buf_type') ? b:man_buf_type : ''
  let b:man_buf_type = tolower(a:type)
  let b:man_buf_bang = a:bang

  " clean up (ie. remove) any ansi escape sequences
  silent! %s/\e\[[0-9;]\{-}m//ge
  silent! %s/\%xe2\%x80\%x90/-/ge
  silent! %s/\%xe2\%x88\%x92/-/ge
  silent! %s/\%xe2\%x80\%x99/'/ge
  silent! %s/\%xe2\%x94\%x82/ /ge

  if &keywordprg =~ '^man\>'
    nnoremap <buffer> <silent> <2-LeftMouse> :call Man#K_Map(&ft, v:count, expand('<cWORD>'))<CR>
  endif

  if !empty(setting['init'])
    call call(setting['init'], args)
  endif

  call cursor(1, 1)
  redraw
  if line('$') <= winheight(0)
    exe curwinnum . 'wincmd w'
  endif
endfunction
"}}}
function! Man#SimpleArgsParser(line) "{{{
  " ParseCmdArgs(): Defined in myutils.vim
  return ParseCmdArgs(a:line)
endfunction
"}}}
function! Man#K_Map(ft, cnt, word) range "{{{
  if exists('g:man_setting_{a:ft}') && has_key(g:man_setting_{a:ft}, 'K')
        \ && !empty(g:man_setting_{a:ft}['K'])
    call call(g:man_setting_{a:ft}['K'], [a:cnt, a:word])
  else
    call s:K_Map_man(a:cnt, a:word)
  endif
endfunction
"}}}
"==================================================
" K mapping
"==================================================
function! s:K_Map_man(cnt, word) "{{{
  let word = substitute(a:word, '^\s\+\|\s\+$', '', 'g')
  let word = substitute(word, '^[`"]\+', '', 'g')
  let tokens = matchlist(word, '^\(\w\+\)\%((\(\d\+\))\)\?')
  if empty(tokens)
    call s:ShowMesg('No manual entry for ' . a:word)
    return
  endif
  let section = ''

  let name = tokens[1]
  if tokens[2] != ''
    let section = tokens[2]
  endif
  if a:cnt > 0
    let section = a:cnt
  endif
  if section == ''
    call Man#Main('man', 0, [name])
  else
    call Man#Main('man', 0, [section, name])
  endif
endfunction
"}}}
function! s:K_Map_perl(cnt, word) "{{{
  call Man#Main('perl', 0, [a:word])
endfunction
"}}}
"==================================================
" man & apropos
"==================================================
function! s:ManBufInit(...) "{{{
  silent! %s/’/'/ge
  silent! %s/−/-/ge
  silent! %s/‐$/-/e
  silent! %s/‘/`/ge
  silent! %s/‐/-/ge
  silent! %s/.\b//ge

  setlocal ts=8
  if a:0 > 0 && a:1 == '-k'
    call s:AproposSyntax()
  else
    call s:ManSyntax()
  endif

  let b:man_buf_info = matchstr(getline(1), '^\w\+(\d\+)')
endfunction
"}}}
function! s:ManSyntax() "{{{
  syntax clear
  ru! syntax/ctrlh.vim

  syn case ignore
  " following four lines taken from Vim's <man.vim>:
  syn match manReference       "\f\+([1-9]\l\=)"
  syn match manSectionTitle    '^\u\{2,}\(\s\+\u\{2,}\)*'
  syn match manSubSectionTitle '^\s+\zs\u\{2,}\(\s\+\u\{2,}\)*'
  syn match manTitle           "^\f\+([0-9]\+\l\=).*"
  syn match manSectionHeading  "^\l[a-z ]*\l$"
  syn match manOptionDesc      "^\s*\zs[+-]\{1,2}\w\S*"

  syn match manSectionHeading  "^\s\+\d\+\.[0-9.]*\s\+\u.*$" contains=manSectionNumber
  syn match manSectionNumber   "^\s\+\d\+\.\d*" contained
  syn region manDQString       start='[^a-zA-Z"]"[^", )]'lc=1 end='"' end='^$' contains=manSQString
  syn region manSQString       start="[ \t]'[^', )]"lc=1 end="'" end='^$'
  syn region manSQString       start="^'[^', )]"lc=1 end="'" end='^$'
  syn region manBQString       start="[^a-zA-Z`]`[^`, )]"lc=1 end="[`']" end='^$'
  syn region manBQString       start="^`[^`, )]" end="[`']"	end='^$'
  syn region manBQSQString     start="``[^),']" end="''"	end='^$'
  syn match  manBulletZone     "^\s\+o\s" transparent contains=manBullet
  syn case match

  syn keyword manBullet o contained
  syn match manBullet "\[+*]" contained
  syn match manSubSectionStart "^\*" skipwhite nextgroup=manSubSection
  syn match manSubSection	".*$" contained
  syn match manOptionWord	"\s[+-]\a\+\>"

  if getline(1) =~ '^[a-zA-Z_]\+([23])'
    syntax include @cCode syntax/c.vim
    syn match manCFuncDefinition  display "\<\h\w*\>\s*("me=e-1 contained
    syn region manSynopsis matchgroup=manSectionTitle start="^SYNOPSIS" end="^\u\+\s*$"me=e-12 keepend contains=manSectionHeading,@cCode,manCFuncDefinition
  endif

  hi def link manTitle          Title
  hi def link manUnderline      Type
  hi def link manSectionHeading	Statement
  hi def link manOptionDesc     Constant

  hi def link manReference      PreProc
  hi def link manSectionTitle	  Function
  hi def link manSectionNumber  Number
  hi def link manDQString       String
  hi def link manSQString       String
  hi def link manBQString       String
  hi def link manBQSQString     String
  hi def link manBullet         Special
  if has('win32') || has('win95') || has('win64') || has('win16')
    if &shell == 'bash'
      hi manSubSectionStart	term=NONE cterm=NONE gui=NONE ctermfg=black ctermbg=black guifg=navyblue guibg=navyblue
      hi manSubSection term=underline cterm=underline gui=underline ctermfg=green guifg=green
      hi manSubTitle term=NONE cterm=NONE gui=NONE ctermfg=cyan ctermbg=blue guifg=cyan guibg=blue
    else
      hi manSubSectionStart	term=NONE cterm=NONE gui=NONE ctermfg=black ctermbg=black guifg=black guibg=black
      hi manSubSection term=underline cterm=underline gui=underline ctermfg=green guifg=green
      hi manSubTitle term=NONE cterm=NONE gui=NONE ctermfg=cyan ctermbg=blue guifg=cyan guibg=blue
    endif
  else
   hi manSubSectionStart term=NONE cterm=NONE gui=NONE ctermfg=black ctermbg=black guifg=navyblue guibg=navyblue
   hi manSubSection term=underline cterm=underline gui=underline ctermfg=green guifg=green
   hi manSubTitle term=NONE cterm=NONE gui=NONE ctermfg=cyan ctermbg=blue guifg=cyan guibg=blue
  endif
endfunction
"}}}
function! s:AproposSyntax() "{{{
  syn match  aproposTopic	'^\S\+' skipwhite nextgroup=aproposType,aproposBook
  syn match  aproposType '\[\S\+\]' contained skipwhite nextgroup=aproposSep,aproposBook contains=aproposTypeDelim
  syn match  aproposTypeDelim	'[[\]]'	contained
  syn region aproposBook	matchgroup=Delimiter start='(' end=')' contained skipwhite nextgroup=aproposSep
  syn match  aproposSep	'\s\+-\s\+'	

  hi def link aproposTopic Statement
  hi def link aproposType  Type
  hi def link aproposBook  Special
  hi def link aproposTypeDelim	Delimiter
  hi def link aproposSep   Delimiter
endfunction
"}}}
"==================================================
" Ruby (ri)
"==================================================
function! s:RiManBufInit(...) "{{{
  call s:RiSyntax()
  if a:0 == 0
    let b:man_buf_info = ''
  else
    let b:man_buf_info = a:000[-1]
  endif
endfunction
"}}}
"==========================================================}}}1
function! s:RiSyntax() "{{{
  syn clear
  syn match riErrorMsg       /\%^Nothing known about .\+$/
  syn match riTopic          /\%(^-\{20,}\)\@<=.\+$/
  syn match riConstant       /\%(^\s\+\)\@<=[A-Z]\w*\%(:\s\)\@=/
  syn match riTitle          /^\S.*\n\%(-\{2,}$\)\@=/
  syn match riTitleLine      /\%(^\S.*\n\)\@<=-\{2,}$/
  syn match riTitleLine      /^-\{20,}/
  syn match riItText         /\<_\S.\{-}\S_\>/hs=s+1,he=e-1
  syn match riItText         /\<_\S_\>/hs=s+1,he=e-1
  syn match riBfText         /\%(^\|\W\|[+_]\)\@<=\*[^0-9 \t].\{-}\S\*\%(\W\|[+_]\|$\)\@=/hs=s+1,he=e-1
  syn match riBfText         /\%(^\|\W\|[+_]\)\@<=\*[^0-9 \t]\*\%(\W\|[+_]\|$\)\@=/hs=s+1,he=e-1
  syn match riTTText         /\%(^\|\W\|[\*_]\)\@<=+[^0-9 \t].\{-}\S+\%(\W\|[\*_]\|$\)\@=/hs=s+1,he=e-1
  syn match riTTText         /\%(^\|\W\|[\*_]\)\@<=+[^0-9 \t]+\%(\W\|[\*_]\|$\)\@=/hs=s+1,he=e-1
  syn match riBulletedList   /\%(^\s*\)\@<=[-*]\s\@=/
  syn match riEnumeratedList /\%(^\s*\)\@<=\%(\d\{1,3}\|[a-zA-Z]\)\.\s\@=/

  hi def  riItText  ctermfg=Green gui=italic
  hi def  riBfText  cterm=bold   gui=bold

  hi def link riErrorMsg         Error
  hi def link riBulletedList     Operator
  hi def link riEnumeratedList   Operator
  hi def link riTopic            Keyword
  hi def link riTTText           Label
  hi def link riTitle            Todo
  hi def link riTitleLine        Repeat
  hi def link riConstant         Constant
endfunction
"}}}
"==================================================
" Python (pydoc)
"==================================================
function! s:PyManBufInit(...) "{{{
  call s:PySyntax()
  if a:0 == 0
    let b:man_buf_info = ''
  else
    let b:man_buf_info = a:000[-1]
  endif
endfunction
"}}}
function! s:PySyntax() "{{{
  syn clear
  syn match Function '\%(\w\+\.\)*\w\+\%((\)\@='
  syn match Keyword  '\%(^\|\%([^-]\)\@<=\)->\%($\|\%([^>]\)\@=\)'
endfunction
"}}}
"==================================================
" info
"==================================================
function! s:InfoSetNodeInfo(info, key, value) "{{{
  let a:info[a:key] = a:value
  return ''
endfunction
"}}}
function! s:InfoGetNodeInfo(line) "{{{
  let info = {}
  let line = substitute(a:line, 
        \ '\<\(File\|Node\|Next\|Distrib\|Prev\|Up\):\s*\([^,\t]\+\)',
        \ '\= s:InfoSetNodeInfo(info, submatch(1), submatch(2))', 'g')
  return info
endfunction
"}}}
function! s:InfoManBufInit(...) "{{{
  call s:InfoSyntax()
  call s:InfoMap()

  setlocal ts=8

  let b:man_buf_info = ''
  let b:man_info_node = s:InfoGetNodeInfo(getline(1))
  let b:man_info_node['File'] = substitute(get(b:man_info_node, 'File', ''), '\.info$', '', '')

  if !exists('b:man_info_history') || b:man_buf_type != b:man_buf_type_last
    let b:man_info_history = []
    let b:man_info_history_idx = -1
  endif

  if !exists('b:man_info_history_add')
    let b:man_info_history_add = 1
  endif

  if b:man_info_history_add
    if b:man_info_history_idx + 1 < len(b:man_info_history)
      call remove(b:man_info_history, b:man_info_history_idx+1, len(b:man_info_history)-1)
    endif
    if has_key(b:man_info_node, 'Node')
      call add(b:man_info_history, ['(' . b:man_info_node['File'] . ')' . b:man_info_node['Node']])
    else
      call add(b:man_info_history, copy(a:000))
    endif
    let b:man_info_history_idx += 1
  endif
  let b:man_info_history_add = 1

  let b:man_buf_info = get(b:man_info_node, 'Node', '')
endfunction
"}}}
function! s:InfoInput() "{{{
  return '(dir)'
endfunction
"}}}
function! s:InfoMap() "{{{
  nnoremap <silent> <buffer> <CR>  :call <SID>InfoFollowLink()<CR>
  nnoremap <silent> <buffer> <2-LeftMouse> :call <SID>InfoFollowLink()<CR>
  nnoremap <silent> <buffer> n     :call <SID>InfoManPage('Next')<CR>
  nnoremap <silent> <buffer> <C-N> n
  nnoremap <silent> <buffer> p     :call <SID>InfoManPage('Prev')<CR>
  nnoremap <silent> <buffer> u     :call <SID>InfoManPage('Up')<CR>
  nnoremap <silent> <buffer> t     :call <SID>InfoManPage('Top')<CR>
  nnoremap <silent> <buffer> d     :call <SID>InfoManPage('(dir)')<CR>
  nnoremap <silent> <buffer> b     :call <SID>InfoBackwardLink()<CR>
  nnoremap <silent> <buffer> f     :call <SID>InfoForwardLink()<CR>
  nnoremap <silent> <buffer> <Tab> :call <SID>InfoNextLink()<CR>
  nnoremap <silent> <buffer> ?     :call <SID>InfoUsage()<CR>
endfunction
"}}}
function! s:InfoUsage() "{{{
  echo 'Key    Description'
  echo '====== ========================================='
  echo '<CR>   Follow a reference or menu item'
  echo 'n      Move to the "next" node of this node'
  echo '       (use <C-N> to repeat searching)'
  echo 'p      Move to the "previous" node of this node'
  echo 'u      Move "up" from this node'
  echo 't      Move to the Top node'
  echo 'd      Move to the `directory'' node'
  echo 'b      Move backward'
  echo 'f      Move forward'
  echo '<Tab>  Skip to next hypertext link'
  echo '?      Print this help'
endfunction
"}}}
function! s:InfoSyntax() "{{{
  syn clear
  syn case match
  syn match  infoMenuTitle /^\* Menu:/hs=s+2
  syn match  infoTitle     /^[A-Z][0-9A-Za-z `',/&]\{,43}\([a-z']\|[A-Z]\{2}\)$/
  syn match  infoTitle     /^[-=*]\{,45}$/
  syn match  infoString    /`[^`]*'/
  for i in range(1, 5)
    exec 'syn match infoLink /' . s:linkpat{i} . '/'
  endfor
  syn region infoHeader    start=/^File:/ end="$" contains=infoHeaderLabel
  syn match  infoHeaderLabel /\<\%(File\|Node\|Next\|Prev\|Up\):\s/ contained

  hi def link infoMenuTitle Title
  hi def link infoTitle     Comment
  hi def link infoLink      Directory
  hi def link infoString    String
  hi def link infoHeader    infoLink
  hi def link infoHeaderLabel	Statement
endfunction
"}}}
function! s:InfoNodeName(file, node) "{{{
  if a:node == '(dir)'
    return a:node
  elseif a:node == 'Top'
    return '(' . a:file . ')'
  else
    return '(' . a:file . ')' . a:node
  endif
endfunction
"}}}
" Link patterns {{{
let s:linkpat1 = '\*[Nn]ote\%(\s\|\n\)\+\(\_[^():]*\)\%(::\|$\)' " note1
let s:linkpat2 = '\*[Nn]ote\%(\s\|\n\)\+\_[^():]*:\s\+\(\%\(([^)]*\)\?\_[^.,]\+\)' " note2
let s:linkpat3 = '^\*\s\+\([^:]*\)::'               " menu
let s:linkpat4 = '^\*\s\+[^:]*:\s\+\(([^)]*)\)'      " filename
let s:linkpat5 = '^\*\s\+[^:]*:\s\+\([^.]*\)'      " index
"}}}
function! s:InfoFollowLink() "{{{
  if line('.') == 1
    call s:InfoHeaderLink() 
    return
  endif

  let curline = join(getline('.', min([line('.')+3, line('$')])), "\n")
  for i in range(1, 5)
    let link = matchstr(curline, s:linkpat{i})
    if !empty(link)
      let link = matchlist(curline, s:linkpat{i})[1]
      if (i == 2 && link =~ '^(') || i == 4
        call Man#Main('info', b:man_buf_bang, [link])
      else
        call Man#Main('info', b:man_buf_bang, ['(' . b:man_info_node['File'] . ')' . link])
      endif
      return
    endif
  endfor
  call s:ShowMesg('Not reference nor menu item')
endfunction
"}}}
function! s:InfoHeaderLink() "{{{
  let col = col('.') - 1
  let line = getline('.')
  let pat = '\<\(File\|Node\|Next\|Distrib\|Prev\|Up\):\s*\([^,\t]\+\)'
  let idx_prev = 0
  let idx = matchend(line, pat, idx_prev)
  let file = b:man_info_node['File'] 
  while idx != -1
    if col < idx
      let [label, node] = matchlist(line, pat, idx_prev)[1 : 2]
      if label == 'File'
        let file = node
        call Man#Main('info', b:man_buf_bang, ['(' . node . ')'])
        return
      elseif label == 'Next' || label == 'Prev' || label == 'Up'
        call Man#Main('info', b:man_buf_bang, [s:InfoNodeName(file, node)])
      endif
      return
    endif
    let idx_prev = idx
    let idx = matchend(line, pat, idx_prev)
  endwhile
endfunction
"}}}
function! s:InfoManPage(type)"{{{
  if !exists('b:man_info_node')
    call s:ShowMesg('Invalid Info node')
    return
  endif

  let error_mesg = {
        \   'Next': 'Node has no Next',
        \   'Prev': 'Node has no Prev',
        \   'Up'  : 'Node has no Up',
        \ }

  if a:type == 'Next' || a:type == 'Prev' || a:type == 'Up'
    if !has_key(b:man_info_node, a:type)
      call s:ShowMesg(error_mesg[a:type])
      return
    endif
    call Man#Main('info', b:man_buf_bang, [s:InfoNodeName(b:man_info_node['File'], b:man_info_node[a:type])])
    return
  elseif a:type == 'Top'
    call Man#Main('info', b:man_buf_bang, ['(' . b:man_info_node['File'] . ')'])
    return
  elseif a:type == '(dir)'
    call Man#Main('info', b:man_buf_bang, ['(dir)'])
    return
  endif
endfunction
"}}}
function! s:InfoBackwardLink() "{{{
  if !exists('b:man_info_history') || b:man_info_history_idx <= 0
    call s:ShowMesg('This is the first Info node you looked at')
    return
  endif
  let b:man_info_history_idx -= 1
  let node_args = b:man_info_history[b:man_info_history_idx]
  let b:man_info_history_add = 0
  call Man#Main('info', b:man_buf_bang, node_args)
endfunction
"}}}
function! s:InfoForwardLink() "{{{
  if !exists('b:man_info_history') || b:man_info_history_idx >= len(b:man_info_history) - 1
    call s:ShowMesg('This is the last Info node you looked at')
    return
  endif
  let b:man_info_history_idx += 1
  let node_args = b:man_info_history[b:man_info_history_idx]
  let b:man_info_history_add = 0
  call Man#Main('info', b:man_buf_bang, node_args)
endfunction
"}}}
function! s:InfoNextLink() "{{{
  let ln = search('\('.s:linkpat1.'\|'.s:linkpat2.'\|'.s:linkpat3.'\|'.s:linkpat4.'\)', 'w')
  if ln == 0
    call s:ShowMesg('No reference nor menu item found')
  endif
endfunction
"}}}
"==================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
