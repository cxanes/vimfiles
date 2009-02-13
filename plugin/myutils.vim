" File: myutils.vim
" Author: Frank Chang (frank.nevermind AT gmail.com)
" Version: 1.0
" Last Modified: 2008-07-28 20:08:04
"
" My own defined functions and mappings.
"
" {{{ Load Once
if exists('loaded_myutils_plugin')
  finish
endif
let loaded_myutils_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
" }}}
"==============================================================
" Common functions
"--------------------------------------------------------------
" {{{ SelectAll <$VIMRUNTIME/menu.vim>
function! SelectAll()
  exe 'norm gg' . (&slm == '' ? 'VG' : "gH\<C-O>G")
endfunction
" }}}
" {{{ GetPos(): Get the position of the cursor on the screen.
"
"   This is a trial-and-error function based on fixed font size.
"   Windows version: set guifont=Consolas:h9:w5

" trial-and-error: set guifont=Consolas:h9:w5
let s:gui_setting = {
      \ 'tabpage_gui_line_height' : 19,
      \ 'tabpage_text_line_height': 15,
      \ 'font_width'              :  7,
      \ 'vert_scrollbar_width'    : 13,
      \ 'font_height'             : 15,
      \ 'menu_height'             : 19,
      \ 'title_height'            : 10,
      \ 'toolbar_height'          : 30,
      \ }
  
function! GetPos() "{{{
  let nline = winline() + 1
  let ncol  = wincol() - 1

  let orgwin = winnr()
  let curwin = orgwin
  wincmd k
  while curwin != winnr()
    let nline += winheight(0) + 1
    let curwin = winnr()
    wincmd k
  endwhile

  exe orgwin . "wincmd w"
  let curwin = orgwin
  wincmd h
  while curwin != winnr()
    let ncol += winwidth(0) + 1
    let curwin = winnr()
    wincmd h
  endwhile

  exe orgwin . "wincmd w"
  let pos = {'x': getwinposx(), 'y' : getwinposy()}

  let pos.x += ncol * s:gui_setting['font_width'] + 6
        \ + (&columns != winwidth(0) ? s:gui_setting['vert_scrollbar_width'] : 0)

  if &showtabline == 2 || ( tabpagenr('$') > 1 && &showtabline == 1 )
    let pos.y += stridx(&guioptions, 'e') != -1 
          \ ? s:gui_setting['tabpage_gui_line_height']
          \ : s:gui_setting['tabpage_text_line_height']
  endif

  let pos.y += nline * s:gui_setting['font_height'] + s:gui_setting['title_height']

  if stridx(&guioptions, 'm') != -1
    let pos.y += s:gui_setting['menu_height']
  endif

  if stridx(&guioptions, 'T') != -1
    let pos.y += s:gui_setting['toolbar_height']
  endif

  return pos
endfunction
"}}}
" }}}
" {{{ AddOptFiles()
function! AddOptFiles(opt, files)
  if type(a:files) == type('') && !empty(a:files)
    let files = [a:files]
  elseif type(a:files) == type([]) && !empty(a:files)
    let files = a:files
  else
    return
  endif

  for file in files
    if file =~ '^[a-zA-Z]:/' || file =~ '^/'
      let path = file
    else
      let path = globpath(&rtp, file)
    endif
    if path != ''
      exe 'setl ' . a:opt . '+=' . substitute(split(path,'\n')[0], '[ ,\\]', '\\\\\\&', 'g')
    endif
  endfor
endfunction
" }}}
" {{{ LiteralPattern()
function! LiteralPattern(pat)
  return '\V' . escape(a:pat, '\') . (&magic ? '\m' : '\M')
endfunction
" }}}
" {{{ SearchApply()
function! SearchApply(pat, func)
  let total = line('$')
  let lnum = 1
  while lnum <= total
    call substitute(getline(lnum), a:pat, '\=call(a:func, [submatch(0)])', 'g')
    let lnum += 1
  endwhile
endfunction
" }}}
" {{{ GetSelection()
function! GetSelection()
  let s_sav = @s
  let @s = ''

  normal gv"sy

  let s = @s
  let @s = s_sav

  return s
endfunction
" }}}
" {{{ Retab()
function! Retab(text, ts)
  let text = a:text
  let ts = a:ts + 0
  while match(text, '\t') != -1
    let text = substitute(text, '^\([^\t]*\)\(\t\+\)', 
          \ . '\=submatch(1).repeat(" ", strlen(submatch(2))*'
          \ . ts . '-strlen(submatch(1))%' . ts . ')', '')
  endwhile
  return text
endfunction
" }}}
" Shellescape() {{{
function! Shellescape(string)
  if s:MSWIN && a:string !~ '[" \t]'
    return a:string
  endif

  if &sh =~ '\%(\<command\.com\|\<cmd\.exe\|\<cmd\)$'
        \ && exists('+shellslash') && &ssl
    set nossl
    let string = shellescape(a:string)
    set ssl
  else
    let string = shellescape(a:string)
  endif
  return string
endfunction
"}}}
" ParseCmdArgs() {{{
function! ParseCmdArgs(line)
  let qstr_pat  = '\%(''\%(\%(''''\)\+\|[^'']\+\)*''\)'
  let qqstr_pat = '\%("\%(\%(\\.\)\+\|[^"\\]\+\)*"\)'
  let cstr_pat  = '\%(\%(\%(\\[\\ \t]\)\+\|[^\\ \t]\+\)\+\)'
  let str_pat = printf('^\%%(%s\|%s\|%s\)', qstr_pat, qqstr_pat, cstr_pat)
  let line = substitute(a:line,  '^\s\+\|\s\+$', '', 'g')
  let args = []
  while !empty(line)
    let idx = matchend(line, str_pat)
    if idx == -1
      break
    endif
    let arg = line[ : (idx-1)]
    if stridx('''"', arg[0]) != -1
      let arg = eval(arg)
    else
      let arg = substitute(arg, '\\\([\\ \t]\)', '\1', 'g')
    endif
    call add(args, arg)
    let line = substitute(line[idx : ], '^\s\+', '', '')
  endwhile
  return args
endfunction
"}}}
"==============================================================
" {{{1 Global Variable
"--------------------------------------------------------------
let s:MSWIN = has('win32') || has('win32unix') || has('win64') || 
          \   has('win95') || has('win16')
"==========================================================}}}1
"==============================================================
" {{{1 Move current line N lines up/down (default is 1).
"--------------------------------------------------------------
nnoremap <script> <Plug>MoveLineDown :<C-U>call <SID>MoveLine('d', v:count1)<CR>
nnoremap <script> <Plug>MoveLineUp   :<C-U>call <SID>MoveLine('u', v:count1)<CR>

nmap <silent> <M-Down> <Plug>MoveLineDown
nmap <silent> <M-Up>   <Plug>MoveLineUp
nmap <silent> <M-j>    <Plug>MoveLineDown
nmap <silent> <M-k>    <Plug>MoveLineUp

function! s:MoveLine(dir, count) "{{{
  if line('$') == 1
    return
  endif
  let l:count = a:count

  let keepx = @x
  let col = col('.')
  while l:count > 0
    let foldclosed = foldclosed(line('.'))
    if a:dir == 'u' && line('.') != 1 
      exe 'normal! "xdd'.(line('.') == line('$') ? '' : 'k').'"xP'
    elseif a:dir == 'd' && line('.') != line('$')
      normal! "xdd"xp
    endif
    let l:count = l:count - 1
    if foldclosed != -1
      normal! zc
    endif
  endwhile
  call cursor(line('.'), col)
  let @x = keepx
endfunction
" }}}
"==========================================================}}}1
" {{{1 Format: par <http://www.nicemice.net/par/>
"--------------------------------------------------------------
function! Format(...) range " ... = option {{{
  let formatprg = 'par'
  if !executable(formatprg)
    echohl ErrorMsg
    echo formatprg . ': command not find'
    echohl None
  endif

  exe printf('%d,%d!%s %s', 
        \ a:firstline, a:lastline, formatprg, (a:0 > 0 ? a:1 : ''))
endfunction
" }}}
function! FormatAll(...) " ... = option {{{
  let save_cursor = getpos('.')
  %call Format(a:0 > 0 ? a:1 : '')
  call setpos('.', save_cursor)
endfunction
" }}}
"==========================================================}}}1
" {{{1 Run
"--------------------------------------------------------------
command! -bang -nargs=* Run call <SID>Run(<q-bang> != '!', <q-args>)
nnoremap <silent> <Leader><F7> :Run<CR>

function! s:Executable(file) 
  if !executable(a:file)
    echohl ErrorMsg
    echo "The executable file '" . a:file . "' doesn't exist"
    echohl None
    return 0
  endif
  return 1
endfunction

function! s:Run(contain_command, args) "{{{
  let args = ParseCmdArgs(a:args)

  if empty(args) || !a:contain_command
    let run_command = ''
    if !empty(&ft) && exists('b:run_command_' . &ft)
      unlet run_command
      if type(b:run_command_{&ft}) == type(function("tr"))
        let run_command = b:run_command_{&ft}()
      else
        let run_command = b:run_command_{&ft}
      endif
    elseif exists('b:run_command')
      unlet run_command
      if type(b:run_command) == type(function("tr"))
        let run_command = b:run_command()
      else
        let run_command = b:run_command
      endif
    endif

    if !(type(run_command) == type('') || type(run_command) == type([]))
      echohl ErrorMsg
      echo 'b:run_command: Invalid type: ' . type(run_command)
      echohl None
      return
    endif

    if !empty(run_command)
      let command = run_command
      if type(command) == type('')
        if !s:Executable(command)
          return
        endif
        let command = Shellescape(command)
      elseif type(command) == type([])
        let temp = []
        let i = 0
        for val in command
          if type(val) != type('')
            echohl ErrorMsg
            echo 'b:run_command[' . i . ']: invalid type: ' . type(val)
            echohl None
            return
          elseif empty(val)
            echohl ErrorMsg
            echo 'b:run_command[' . i . ']: empty string'
            echohl None
            return
          endif

          if i == 0
            if !s:Executable(val)
              return
            endif
          endif
          call add(temp, Shellescape(val))

          let i += 1
        endfor

        unlet! command
        let command = escape(join(temp), '%#!')
      else
        echohl ErrorMsg
        echo 'b:run_command: Invalid type: ' . type(command)
        echohl None
        return
      endif
    elseif executable(expand('%:p:r'))
      let command = Shellescape(expand('%:p:r'))
    elseif executable(expand('%:p'))
      let command = Shellescape(expand('%:p'))
    else
      echohl ErrorMsg
      echo 'No executable file is found'
      echohl None
      return
    endif
  endif

  if !empty(args) && a:contain_command
    let command = remove(args, 0)
    if !s:Executable(command)
      return
    endif
    let command = Shellescape(command)
  endif

  let curwinnum = winnr()
  let winnum = CreateTempBuffer('-OutputPreview-')
  exe winnum . 'wincmd w'
  silent %d _

  call map(args, 'Shellescape(v:val)')
  silent exe printf('1r !%s %s', command, escape(join(args), '%#!'))
  silent 1d _
  call cursor(1, 1)
  redraw
  exe curwinnum . 'wincmd w'
endfunction
"}}}
"==========================================================}}}1
" {{{1 Inject
"--------------------------------------------------------------
command! -bang -range -complete=buffer -nargs=1 Inject 
      \ call s:Inject(<q-args>, GetSelection(), <q-bang> == '!')

function! s:Inject(bufnr, text, newline) "{{{
  let bufnr = a:bufnr =~ '^\d\+' ? a:bufnr+0 : a:bufnr
  let nr = bufwinnr(bufnr)
  if nr != -1
    let curwin = winnr()
    if curwin == nr
      echohl ErrorMsg
      echo 'Cannot inject text into the same buffer'
      echohl None
      return
    endif
    exe nr . 'wincmd w'
    silent exec 'normal! i' . a:text . (a:newline ? "\<CR>" : '')
    exe curwin . 'wincmd w'
  else
    let nr = bufnr(bufnr)
    if nr == -1
      echohl ErrorMsg
      echo 'Buffer '
        \ . (a:bufnr =~ '^\d\+' ? a:bufnr : "'" . a:bufnr . "'")
        \ . " does not exist"
      echohl None
      return
    endif

    let curbuf = bufnr('')
    if curbuf == nr
      echohl ErrorMsg
      echo 'Cannot inject text into the same buffer'
      echohl None
      return
    endif

    let hid_sav = &hid
    set hidden
    silent exec 'b' . bufnr
    silent exec 'normal! i' . a:text . (a:newline ? "\<CR>" : '')
    silent exec 'b' . curbuf
    let &hid = hid_sav
  endif

  let snippet = matchstr(a:text, '^\s*[^[:space:]]\{,10}')
  echo "The text '" . snippet . (snippet == a:text ? '' : '...') 
        \ . "' has been injected into buffer "
        \ . (a:bufnr =~ '^\d\+' ? a:bufnr : "'" . a:bufnr . "'")
endfunction
"}}}
if !s:MSWIN && executable('screen')
  command! -range -nargs=1 ScreenInject 
        \ call s:ScreenInject(<q-args>, GetSelection())

  function! s:ScreenInject(winID, text) "{{{
    let tmpfile = tempname()
    let lines = split(a:text, '\n')
    call writefile(lines, tmpfile)
    exec printf("silent !screen -X eval 'readreg x \"%s\"' 'select %d' 'paste x' 'other'", tmpfile, a:winID)
    call delete(tmpfile)
  endfunction
  "}}}
endif
"==========================================================}}}1
" {{{1 Filter
"--------------------------------------------------------------
au FileType * 
      \ if !exists('b:filter_cmd') | 
      \   let b:filter_cmd = expand('<amatch>') | 
      \ endif

vnoremap <silent> <F7> :call Filter()<CR>
nnoremap <silent> <F7> :<C-U>call FilterAll()<CR>
inoremap <silent> <F7> <C-O>:call FilterAll()<CR>

command! -range=% -nargs=+ Filter <line1>,<line2>call Filter(<q-args>)

" Filter {range} lines through the external program {filtcmd} to other
" window.
"
" Ref: 1. Re: Filter to preview window 
"         <http://groups.yahoo.com/group/vim/message/62934>
"      2. The idea of specific preview window comes from 'taglist.vim'.
"      3. :h special-buffers
function! Filter(...) range " ... = filtcmd {{{
  let filtcmd = a:0 > 0 ? a:1 : exists('b:filter_cmd') ? b:filter_cmd : ''

  if filtcmd == ''
    let filtcmd = &filetype
  endif

  let curwinnum = winnr()
  let winnum = CreateTempBuffer('-OutputPreview-')

  " Get a copy of the selected lines
  let keepa = @a
  if a:0 > 1
    let @a = a:2
  else
    exe 'silent!' . a:firstline . ',' . a:lastline . 'y a'
  endif
  exe winnum . 'wincmd w'
  silent %d _
  silent! put a
  silent 1d _
  exe 'silent! %!'. filtcmd
  exe curwinnum . 'wincmd w'
  " Restore register 'a'
  let @a= keepa
endfunction
" }}}
" Filter all text through the external program {filtcmd} to other window.
function! FilterAll(...) " ... = filtcmd {{{
  let filtcmd = a:0 > 0 ? a:1 : (exists('b:filter_cmd') ? b:filter_cmd : '')

  if filtcmd == ''
    let filtcmd = &filetype
  endif
  let firstline = getline(1)
  " If the beginning of the first line is '#!' (shebang), use the 
  " argument after '#!' as the external command for filtering.
  if firstline =~ '^#!' && executable(matchstr(firstline[2:], '^\s*\zs\S\+'))
    let filtcmd = firstline[2:]
  endif
  call Filter(filtcmd, join(getline(1, '$'), "\n"))
endfunction
" }}}
"==========================================================}}}1
" {{{1 Capitalize the selecting words
"--------------------------------------------------------------
nmap     <silent> gc <Plug>CapitalizeN0
vnoremap <silent> gc :<C-U>call <SID>Capitalize('v')<CR>
nmap     <silent> gC <Plug>CapitalizeN1
vnoremap <silent> gC :<C-U>call <SID>Capitalize('v', 1)<CR>

nnoremap <silent> gc :<C-U>call <SID>Capitalize('n')<CR>

nnoremap <silent> <Plug>CapitalizeN0 :<C-U>call <SID>Capitalize('n')<CR>
nnoremap <silent> <Plug>CapitalizeN1 :<C-U>call <SID>Capitalize('n', 1)<CR>

" Capitalize the selecting words. (e.g. capitalize => Capitalize)
" The function is modified from ``cream-capitalization.vim'', which is part of
" Cream.
function! <SID>Capitalize(mode, ...) " ... = preserve cases {{{
  if a:mode == 'v'
    normal! gv
  else
    let mypos = getpos('.')
    " select current word
    normal! vaw
  endif
  let keepx = @x
  " yank
  normal! "xy

  " lower case entire string
  if a:0 == 0 || a:1 == 0
    let @x = tolower(@x)
  endif
  " capitalize first in series of word chars
  let @x = substitute(@x, '\w\+', '\u&', 'g')

  " '_' is treated as space 
  let @x = substitute(@x, '\(_\+\)\(\w\)', '\1\u\2', 'g')

  " reselect
  normal! gv
  " paste over selection (replacing it)
  normal! "xP
  let @x = keepx

  " return state
  if a:mode == 'v'
    normal! gv
    if &selection == 'exclusive'
      normal! l
    endif
  else
    call setpos('.', mypos)
    if a:0 == 0 || a:1 == 0
      silent! call repeat#set("\<Plug>CapitalizeN0")
    else
      silent! call repeat#set("\<Plug>CapitalizeN1")
    endif
  endif
endfunction
" }}}
"==========================================================}}}1
" {{{1  Swapping characters, words...
"
" - Swap characters: ab => ba
" - Swap words:      a = b => b = a
"
" See http://vim.wikia.com/wiki/Swapping_characters,_words_and_lines
"--------------------------------------------------------------
nmap <silent> gw <Plug>FSwapWords
nmap <silent> gW <Plug>BSwapWords

" nmap <silent> gc <Plug>FSwapChars
" nmap <silent> gC <Plug>BSwapChars

nnoremap <silent> <Plug>FSwapWords :<C-U>call <SID>SwapWords(1)<CR>
nnoremap <silent> <Plug>BSwapWords :<C-U>call <SID>SwapWords(0)<CR>

nnoremap <silent> <Plug>FSwapChars :<C-U>call <SID>SwapChars(1)<CR>
nnoremap <silent> <Plug>BSwapChars :<C-U>call <SID>SwapChars(0)<CR>

function! s:SwapWords(forward) "{{{
  keepjumps normal! "_yiw
  let keepv = @/
  let pos = getpos('.')
  try
    if a:forward == 1
      keepjumps s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/
      call setpos('.', pos)
      call search('\<\w', 'W')
      silent! call repeat#set("\<Plug>FSwapWords")
    else
      let [lnum, col] = searchpos('\<\w', 'bW')
      if lnum != 0
        call cursor(lnum, col)
        keepjumps s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/
        silent! call repeat#set("\<Plug>BSwapWords")
        call cursor(lnum, col)
      endif
    endif
  catch /^Vim\%((\a\+)\)\=:E486/
  endtry
  let @/ = keepv
endfunction
" }}}
function! s:SwapChars(forward) "{{{
  let a_sav = @a
  if a:forward == 1
    if col('.') + 1 != col('$')
      keepjumps normal! "ax"ap
      silent! call repeat#set("\<Plug>FSwapChars")
    endif
  else
    if col('.') != 1
      keepjumps normal! "axh"aP
      silent! call repeat#set("\<Plug>BSwapChars")
    endif
  endif
  let @a = a_sav
endfunction
"}}}
"==========================================================}}}1
" {{{1 Hungry Delete
"
" e.g. ( _ is the position of the cursor) 
"
"       1. foo  _    bar => foo_bar 
"
"       2. foo  _        => foo_
"           bar              bar
"
"       3. foo           => foo
"                           _
"          _                 bar
"           bar
"
"       4. foo           => foo
"           _ bar           _bar
"
"--------------------------------------------------------------
nmap <silent> <Leader>d<Space> <Plug>HungryDeleteN
imap <silent> <Leader>d<Space> <C-O><Plug>HungryDeleteN

nnoremap <silent> <Plug>HungryDeleteN :<C-U>call <SID>HungryDelete()<CR>

function! <SID>HungryDelete() "{{{
  let lnum = line('.')
  let line = getline('.')
  let [blnum, bcol] = searchpos('\%(\S\)\@<=\s*\%#\s\+\%(\S\)\@=', 'cnbW', lnum)
  if [blnum, bcol] != [0, 0]
    let [elnum, ecol] = searchpos('\%(\S\)\@<=\s*\%#\s\+\%(\S\)\@=', 'cneW', lnum)
    if [elnum, ecol] == [0, 0] || blnum != elnum
      return
    endif
    call setline(blnum, line[0 : bcol-2] . ' ' . line[ecol : ])
    call cursor(blnum, bcol)
    silent! call repeat#set("\<Plug>HungryDeleteN")
    return
  endif

  let [blnum, bcol] = searchpos('\%(\S\)\@<=\s*\%#\s\+$', 'cnbW', lnum)
  if [blnum, bcol] != [0, 0]
    call setline(blnum, line[0 : bcol-2] . ' ')
    call cursor(blnum, bcol)
    silent! call repeat#set("\<Plug>HungryDeleteN")
    return
  endif
  
  let [blnum, bcol] = searchpos('^\s*\%#\s*$', 'cnbW', lnum)
  if [blnum, bcol] != [0, 0]
    let elnum = nextnonblank(blnum)
    if elnum == 0
      let elnum = line('$') + 1
    endif
    let blnum = prevnonblank(blnum)
    if blnum >= elnum
      return
    endif
    exec printf('silent %d,%dd _', blnum+1, elnum-1)
    if line('$') > 1 || !empty(getline(1))
      call append(blnum, '')
    endif
    call cursor(blnum+1, 1)
    silent! call repeat#set("\<Plug>HungryDeleteN")
    return
  endif

  let [elnum, ecol] = searchpos('^\s*\%#\s\+\%(\S\)\@=', 'cneW', lnum)
  if [elnum, ecol] != [0, 0]
    call setline(elnum, ' ' . line[ecol : ])
    call cursor(elnum, 1)
    silent! call repeat#set("\<Plug>HungryDeleteN")
    return
  endif
endfunction
" }}}
"==========================================================}}}1
" {{{1 ShowMatch: Show all lines which the pattern matches
"      NOTE: :vimgrep /pattern/ %|copen 
"            may do the same job (except using file).
"--------------------------------------------------------------
command! -nargs=? ShowMatch call myutils#ShowMatch(<q-args>)
"==========================================================}}}1
" {{{1 Seq: Insert a list of number (the same options as seq)
"--------------------------------------------------------------
command! -nargs=+ -bang -range Seq call s:InsertSeq(<q-bang> == '!', <q-args>)

function! s:InsertSeq(visual_mode, args) "{{{
  let seq = call('myutils#Seq', ParseCmdArgs(a:args))
  if seq == ''
    return
  endif

  if !a:visual_mode
    exec 'normal! i' . seq
    normal '[
    startinsert!
  else
    let [var_a, var_amode] = [getreg('a'), getregtype('a')]
    call setreg('a', seq, 'b')
    normal! "aP
    let seq_len = matchstr(getregtype('a'), '\d\+$') - 1
    if seq_len > 0
      let len = col('$') - col('.') - 1
      if seq_len > len
        let seq_len = len
      endif
      exec 'normal! ' . seq_len . 'l'
    endif
    call setreg('a', var_a, var_amode)
    if col('.') >= col('$') - 1
      startinsert!
    else
      normal! l
      startinsert
    endif
  endif
endfunction
"}}}
"==========================================================}}}1
" {{{1 CNewLine()
"--------------------------------------------------------------
function! CNewLine()
  let newline = "\<C-O>o"

  let ch = getline('.')[col('.')-2]
  if col('.') == 1 || stridx(';`', ch) == -1
    return newline
  endif

  if has('syntax_items')
        \ && synIDattr(synID(line('.'), col('.'), 0), 'name') =~? 'string\|comment'
    return newline
  endif

  if ch == ';' && getline('.') =~ '\<for\s*('
    return newline
  endif

  return "\<BS>\<End>;" . (ch == ';' ? "\<CR>" : '')
endfunction
"==========================================================}}}1
" {{{1 MultipleEdit()
"--------------------------------------------------------------
command! -nargs=+ -complete=custom,s:ListFiles MultipleEdit call s:MultipleEdit(<f-args>)

function! s:ListFiles(A, L, P) "{{{
  " let line = substitute(a:L[ : a:P], '^\S\+\s*', '', '')
  let list = split(glob(a:A . '*'), '\n')
  call map(list, "v:val . (isdirectory(v:val) ? '/' : '')")
  return join(list, "\n")
endfunction
"}}}
function! s:MultipleEdit(...) "{{{
  if a:0 == 0
    return
  endif

  let opts = ''
  let files = []

  for arg in a:000
    if arg =~ '^+'
      let opts .= escape(arg, '\ ') . ' '
      continue
    endif

    let fs = split(glob(arg), "\n")

    if len(fs) == 0
      echohl ErrorMsg | echom 'E480: No match: ' . arg | echohl None
    else
      call extend(files, fs)
    endif
  endfor

  if empty(files)
    return
  endif

  for file in files
    exec 'edit ' opts . file
  endfor
endfunction
"}}}
"==========================================================}}}1
" {{{1 Calc(): require +python
"--------------------------------------------------------------
function! Calc(expr, ...) " ... = [modules]
  if !has('python')
    echohl ErrorMsg
    echom 'Calc: python not support'
    echohl None

    return
  endif

  if a:0 > 0 && type(a:1) == type([])
    for module in a:1
      silent! exec 'py import ' . module
    endfor
  endif
  let result = ''
  python <<EOF
import vim
from math import *
vim.command("let result = '%s'" % str(eval(vim.eval('a:expr'))).replace("'", "''"))
EOF
  return result
endfunction

" Tip 1235: http://vim.wikia.com/wiki/VimTip1235
command! -nargs=+ Calc call s:ImportPyModule(<q-args>)
function! s:ImportPyModule(expr)
  if !has('python')
    echohl ErrorMsg
    echom 'Calc: python not support'
    echohl None

    return
  endif

  py from math import *
  command! -nargs=+ Calc py print <args>

  exec 'py print' a:expr
endfunction

"==========================================================}}}1
" {{{1 StripSurrounding()
"--------------------------------------------------------------
function! s:CanSkip(lnum, col) "{{{
  if has('syntax_items')
    return synIDattr(synID(a:lnum, a:col, 0), 'name') =~? 'string\|comment'
  endif
  return 0
endfunction
" }}}
function! StripSurrounding(start, middle, end, ...) " ... = skip {{{
  let skip = a:0 > 0 ? a:1 : 's:CanSkip(line(''.''), col(''.''))'
  let [lnum, col] = searchpairpos(a:start, a:middle, a:end, 'nbW', skip)
  if [lnum, col] == [0, 0]
    return [0, 0]
  endif

  call cursor(lnum, col)
  call searchpair(a:start, a:middle, a:end, 'W', skip)
  let pat = @/
  exe 's/' . '\%#' . substitute(a:end, '/', '\\/', 'g') . '//'
  call cursor(lnum, col)
  exe 's/' . '\%#' . substitute(a:start, '/', '\\/', 'g') . '//'
  call cursor(lnum, col)
  let @/ = pat
  return [lnum, col]
endfunction
"}}}

nnoremap <silent> <Leader>sf :call StripFunc()<CR>

function! StripFunc() 
  call StripSurrounding('\<\h\w*\s*(', '', ')')
endfunction
"==========================================================}}}1
" {{{1 PutNewLine()
"--------------------------------------------------------------
inoremap <silent> <S-CR> <C-\><C-O>:call <SID>PutNewLine()<CR>

function! <SID>PutNewLine() "{{{
  let save_cursor = getpos('.')
  if col('.') == col('$')
    normal! a
  else
    normal! i
  endif
  call setpos('.', save_cursor)
endfunction
" }}}
"==========================================================}}}1
" {{{1 Parenthesis-related Functions (use surround.vim instead)
"--------------------------------------------------------------
" {{{ Complete parenthesis ([{}])
"
" e.g. ( => ()
function! CompleteParenMap(plist, ...) "{{{
  let plist = substitute(a:plist, '[^[:punct:]]\+', '', 'g')
  let b:CompleteParenMapEscapePat = a:0 == 0 ? '\w' : a:1
  for ch in split(plist, '\zs')
    exe printf('inoremap <silent> <buffer> <Leader>%s %s', ch, ch)
    exe printf('inoremap <silent> <buffer> %s %s<C-R>=CompleteParen(''%s'')<CR>'
          \ , ch, ch, substitute(ch, "'", "''", 'g'))
  endfor
endfunction
"}}}
function! CompleteParen(paren,...) "{{{
  let c = getline('.')[col('.')-1]
  " If 'c' matches 'pat', don't complete parenthesis.
  if exists('b:CompleteParenMapEscapePat')
    let pat = b:CompleteParenMapEscapePat
  else
    let pat = a:0 > 0 ? a:1 : '\w'
  endif
  if match(c, pat) != -1
    return ''
  endif
  let plist = split(&matchpairs, ':\|,')
  let i = index(plist, a:paren)
  " If 'a:paren' is not listed in &matchpairs, return itself
  if i < 0
    return a:paren . "\<Left>"
  endif
  if i % 2 == 0
    let paren2 = plist[i + 1]
    return paren2 . "\<Left>"
  else
    return ''
  endif
endfunction "}}}
" }}}3
" }}}
"==========================================================}}}1
" {{{1 Mapping-related Functions
"--------------------------------------------------------------
" MoveToMap() {{{2
function! MoveToMap(pat, ...) "{{{
  let default_key = '<C-L>'
  let key = a:0 > 0 && a:1 != '' ? a:1 : default_key

  let modes = a:0 > 1 && a:2 != '' ? a:2 : 'i'
  let q_pat = "'" . substitute(a:pat, "'", "''", 'g') . "'"

  let pat = substitute(a:pat, '<', '<lt>', 'g')
  if stridx(modes, 'i') != -1
    exe 'inoremap <silent> <buffer>' key
          \ "<C-\\><C-N>:call search(" . q_pat . ", 'e')<CR>a"
  endif

  if stridx(modes, 'n') != -1
    exe 'nnoremap <silent> <buffer>' key
          \ ":call search(" . q_pat . ", 'e')<CR>"
  endif

  if stridx(modes, 'v') != -1
    exe 'vnoremap <silent> <buffer>' key
          \ "m':<C-U>exe \"normal! gv\"<Bar>:call search(" . q_pat . ", 'e')<CR>l"
  endif
endfunction
"}}}
"}}}2
" e.g. call EnterMap('{', '}')
"
" In C filetype
"
"     {|} 
"
" press <CR> (| is the position of the cursor)
"
"     {
"       |
"     }
"
function! EnterMap(head, tail) "{{{
  exe 'inoremap <silent> <buffer> <CR>'
        \ . ' <C-R>=(col(".") != 1 && strpart(getline("."), col(".")-2, 2) == '''
        \ . a:head . '''.''' . a:tail . ''') ? "\<lt>CR>\<lt>ESC>ko" : "\<lt>CR>"<CR>'
  inoremap <silent> <buffer> <Leader><CR> <CR>
endfunction
"}}}
"==========================================================}}}1
" {{{1 Build Tags
"--------------------------------------------------------------
if has('cscope')
  command! -nargs=? -bang Cscope call <SID>Cscope(<q-args>, expand('<bang>') != '!')

  function! s:Cscope(output, isCurrentFile) "{{{
    if !executable('cscope')
      echohl ErrorMsg
      echom 'cscope: command not find'
      echohl None
    endif

    let cmd = 'silent !cscope -Rb %s %s'
    exe printf(cmd, empty(a:output) ? '' : ('-f '.shellescape(a:output)),
          \ a:isCurrentFile && !empty(expand('%')) ? shellescape(expand('%')) : '')
    redraw!
    return v:shell_error 
          \    ? '' 
          \    : !empty(a:output) 
          \        ? a:output 
          \        : !empty($CSCOPE_DB) 
          \            ? $CSCOPE_DB 
          \            : 'cscope.out'
  endfunction
  "}}}
endif

if (s:MSWIN && executable('ctags.exe')) || executable('ctags')
  command! -nargs=? -bang Ctags call <SID>Ctags(<q-args>, expand('<bang>') != '!')

  function! s:Ctags(output, isCurrentFile) "{{{
    let cmd = 'silent !ctags -R --c++-kinds=+p --fields=+iaS --extra=+q %s %s'
    exe printf(cmd, empty(a:output) ? '' : ('-f '.shellescape(a:output)),
          \ a:isCurrentFile && !empty(expand('%')) ? shellescape(expand('%')) : '.')
    redraw!
    return v:shell_error ? '' : !empty(a:output) ? a:output : 'tags'
  endfunction
  "}}}
endif
"==========================================================}}}1
" {{{1 Text objects selection
"--------------------------------------------------------------
" {{{2 Function

nnoremap <silent> yaf :<C-U>call FuncTextObject('y')<CR>
nnoremap <silent> daf :<C-U>call FuncTextObject('d')<CR>
nnoremap <silent> caf :<C-U>call FuncTextObject('d')<CR>i
vnoremap <silent> af  :<C-U>call FuncTextObject('v')<CR>

function! FuncTextObject(mode) " mode = [d|y|v]
  let skip = 's:CanSkip(line(''.''), col(''.''))'
  " let [l:start, l:middle, l:end]  = ['\<\w\+\s*(', '', ')']
  let pos = getpos('.')

  if getline('.')[col('.')-1] == ')'
    normal! h
  endif

  let [l:start, l:middle, l:end]  = ['\%(\.\)\@<!\<\w\+\%(\.\w\+\)*\s*(', '', ')']
  let [slnum, scol] = searchpairpos(l:start, l:middle, l:end, 'cbnW', skip)
  if [slnum, scol] == [0, 0]
    call setpos('.', pos)
    return
  endif

  let [elnum, ecol] = searchpairpos(l:start, l:middle, l:end, 'nW', skip)
  if [elnum, ecol] == [0, 0]
    call setpos('.', pos)
    return
  endif

  let move_down  = elnum - slnum
  let move_right = ecol - (&sel == 'inclusive' ? 1 : 0)
  call cursor(slnum, scol)
  let cmd = 'silent normal! v0' . (move_down <= 0 ? '' : (move_down.'j')) 
        \ . (move_right <= 0 ? '' : (move_right.'l'))

  if a:mode == 'v'
    exec cmd
  elseif a:mode == 'd'
    exec cmd . '"' . v:register . 'd'
  elseif a:mode == 'y'
    exec cmd . '"' . v:register . 'y'
  endif
endfunction
" }}}2
"==========================================================}}}1
" {{{1 WebSearch
"--------------------------------------------------------------
if has('unix') && !exists('*LaunchBrowser')
  " http://www.infynity.spodzone.com/vim/HTML/
  ru! browser_launcher.vim
endif

if s:MSWIN || exists('*LaunchBrowser')
  command! -nargs=+ WebSearch call WebSearch(<q-args>)

  function! WebSearch(query) "{{{
    " default: Google search
    let url_default = 'http://www.google.com/search?q=%s&ie=utf-8&oe=utf-8&aq=t'
    let enc_default = 'utf-8'

    let url = exists('g:WebSearchUrl')      ? g:WebSearchUrl      : url_default
    let enc = exists('g:WebSearchEncoding') ? g:WebSearchEncoding : enc_default

    try
      let query = printf(url, s:WebQueryEncode(iconv(a:query, &enc, enc)))
		catch /^Vim\%((\a\+)\)\=:E767/
      let query = printf(url_default, s:WebQueryEncode(iconv(a:query, &enc, enc)))
    endtry
    if s:MSWIN
      let query = substitute(query, '%', '\\%', 'g')
      silent exe '!start RunDll32.exe shell32.dll,ShellExec_RunDLL "' . query . '"'
    elseif exists('*LaunchBrowser')
      " Launch Firefox
      call LaunchBrowser('f', 2, query)
    endif
  endfunction
  " }}}
  function! s:WebQueryEncode(query) "{{{
    let output = ''
    for i in range(strlen(a:query))
      let ch = a:query[i]
      if ch =~ '\w' || ch == '-'
        let output .= ch
      elseif ch =~ '[[:space:]]'
        let output .= '+'
      else
        let output .= printf('%%%X', char2nr(ch))
      endif
    endfor
    return output
  endfunction
  " }}}
endif
"==========================================================}}}1
" {{{1 ShowImage()
"--------------------------------------------------------------
if globpath(&rtp, 'bin/image-viewer') != ''
  vnoremap <silent> <Leader>vi :<C-U>call ShowImage(<SID>GetFiles())<CR>
  command! -nargs=+ -complete=file ShowImage call ShowImage([<f-args>])

  function! s:GetFiles() "{{{
    let path = GetSelection()
    if path =~ '^\s*$'
      return
    endif
    let files = split(path, '\n')
    for i in range(0, len(files)-1)
      let file = files[i]
      let file = substitute(file, '^\s\+', '', 'g')
      let file = substitute(file, '\s\+$', '', 'g')

      if !filereadable(file)
        if filereadable(expand('%:p:h').'/'.file)
          let file = expand('%:p:h').'/'.file
        else
          let file = ''
        endif
      endif

      if s:MSWIN
        let file = iconv(file, &enc, 'big5')
      endif

      let files[i] = file
    endfor
    call filter(files, 'v:val != ""')
    return files
  endfunction
  " }}}
  function! ShowImage(files, ...) " ... = NotWithCursor {{{
    let python = s:MSWIN ? 'C:\Python26\pythonw.exe' : 'python'
    if !executable(python)
      return 1
    endif

    let image_viewer = globpath(&rtp, 'bin/image-viewer')
    if image_viewer == ''
      return 1
    else
      let image_viewer = split(image_viewer, '\n')[0]
    endif

    if type(a:files) == type('')
      let files = [a:files]
    elseif type(a:files) == type([])
      let files = a:files
    else
      return
    endif

    call filter(files, 'v:val != ""')

    if !empty(files)
      if exists('*GetPos') && (a:0 == 0 || a:1 == 0)
        let pos = GetPos()
      else
        let pos = { 'x': getwinposy(), 'y': getwinposy() }
      endif

      let cmd = s:MSWIN ? 'silent !start %s %s -p "%d+%d" %s'
            \ : 'silent !%s %s -p "%d+%d" %s 2>/dev/null&'

      let q = s:MSWIN ? '"' : "'"
      if len(files) == 1
        if globpath(&rtp, 'bin/preview') != ''
          let image_viewer = split(globpath(&rtp, 'bin/preview'), '\n')[0]
        endif
        let farg = printf('-s "%s"', files[0])
      else
        let farg = q . join(files, q . ' ' . q) . q
      endif

      exe printf(cmd, python, q . image_viewer . q, pos.x, pos.y, farg)
      " redraw!
    endif
  endfunction
  " }}}
endif
"==========================================================}}}1
" {{{1 OpenFile(): open file according to the file association
"--------------------------------------------------------------
command! -nargs=1 -complete=file OpenFile call OpenFile(<q-args>)

function! OpenFile(file) "{{{
	if exists('*Shellescape')
		let file = Shellescape(a:file)
	else
		let file = shellescape(a:file)
	endif

	let cmd = s:MSWIN 
				\ ? 'start RunDll32.exe shell32.dll,ShellExec_RunDLL'
				\ : executable('gnome-open') 
				\   ? 'gnome-open'
				\   : executable('xdg-open')
				\     ? 'xdg-open'
				\     : ''

	if cmd != ''
		silent exe '!' . cmd . ' ' . file
		return 0
	endif

	return 1
endfunction
"}}}
"==========================================================}}}1
" {{{1 ColorSelector()
"--------------------------------------------------------------
if (s:MSWIN && executable('color-selector.bat')) || executable('color-selector')
  inoremap <silent> <Leader>cs     <C-R>=<SID>ColorSelector('i')<CR>
  nnoremap <silent> <Leader>cs    a<C-R>=<SID>ColorSelector('i')<CR>
  vnoremap <silent> <Leader>cs "_yi<C-R>=<SID>ColorSelector('v')<CR>

  function! s:ColorSelector(mode) "{{{
    let prev_color = ''
    if a:mode == 'v'
      let prev_color = GetSelection()
    endif

    let len = strlen(substitute(prev_color, '.', 'x', 'g'))
    let prev_color = substitute(prev_color, '[\r\n \t]\+', '', 'g')
    if empty(prev_color)
      let color = system('color-selector')
    else
      let color = system('color-selector "' . prev_color . '"')
    endif

    let color = substitute(color, '[\f\r\n \t]\+', '', 'g')
    if !empty(color)
      let format = '#%02X%02X%02X'
      try 
        if exists('g:color_selector_format') && !empty(g:color_selector_format)
          try
            let output = call('printf', [g:color_selector_format] + eval(color))
          catch
            let output = call('printf', [format] + eval(color))
          endtry
        else
          let output = call('printf', [format] + eval(color))
        endif
      catch 
        let output = color
      endtry
      return repeat("\<Del>", len) . output
    endif
    return ''
  endfunction
  "}}}
endif
"==========================================================}}}1
" {{{1 Enclose(): Enclose text with braces.
"--------------------------------------------------------------
command! -nargs=? -range Enclose call s:Enclose(<q-args>, <line1>, <line2>)

function! s:Enclose(paren, line1, line2) "{{{
  let paren = a:paren == '' ? '{' : a:paren
  let plist = split(&matchpairs, ':\|,')
  let i = index(plist, paren)
  let paren2 = (i >= 0 && i % 2 == 0) ? plist[i + 1] : paren

  call append(a:line2, paren2)
  call append(a:line1 - 1, paren)
  let lnum1 = a:line1
  let lnum2 = a:line2  == line('$') ? line('$') : (a:line2 + 2)
  call cursor(a:line1, 0)
  exec 'normal! V' . (lnum1 == lnum2 ? '' : ((lnum2-lnum1) . 'j')) . '='
  call cursor(a:line1, 0)
  call setline(line('.'), matchstr(getline('.'),  '^\s*') . ' ' . paren)
  call search(' '.paren, '', line('.'))
  startinsert
endfunction
"}}}
"==========================================================}}}1
"==============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
