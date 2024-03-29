" File: autoload/myutils.vim
" Author: Frank Chang (frank.nevermind AT gmail.com)
" Version: 1.0
" Last Modified: 2013-05-30 19:30:29
"
" My own defined functions and mappings (autoload)
"
" {{{ Load Once
if exists('myutils_autoload_plugin')
  finish
endif
let myutils_autoload_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
" }}}
"==============================================================
" {{{1 Utilities
"--------------------------------------------------------------
function! s:SID() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
"}}}
"==========================================================}}}1
" {{{1 Global Variable
"--------------------------------------------------------------
let s:MSWIN = has('win16') || has('win32') || has('win64') || 
          \   has('win95') || has('win32unix')
"==========================================================}}}1
"==============================================================
" {{{1 CppComplete-related Functions
"--------------------------------------------------------------
function! myutils#CppCompleteInit() "{{{
  call omni#cpp#complete#Init()
  inoremap <expr> . myutils#CppMayCompleteDot()
  inoremap <expr> > myutils#CppMayCompleteArrow()
  inoremap <expr> : myutils#CppMayCompleteScope()
endfunction
"}}}
function! myutils#CppMayCompleteDot() "{{{
  if has('syntax_items') 
        \ && synIDattr(synID(line('.'), col('.'), 1), "name") =~? '\(Comment\|String\)$'
    return '.'
  endif
  return omni#cpp#maycomplete#Dot()
endfunction
"}}}
function! myutils#CppMayCompleteArrow() "{{{
  if has('syntax_items') 
        \ && synIDattr(synID(line('.'), col('.'), 1), "name") =~? '\(Comment\|String\)$'
    return '>'
  endif
  return omni#cpp#maycomplete#Arrow()
endfunction
"}}}
function! myutils#CppMayCompleteScope() "{{{
  if has('syntax_items') 
        \ && synIDattr(synID(line('.'), col('.'), 1), "name") =~? '\(Comment\|String\)$'
    return ':'
  endif
  return omni#cpp#maycomplete#Scope()
endfunction
" }}}
"==========================================================}}}1
"==============================================================
" {{{1 Move current line N lines up/down (default is 1).
"--------------------------------------------------------------
function! myutils#MoveLine(dir, count) "{{{
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
function! myutils#Format(...) range " ... = option {{{
  let formatprg = 'par'
  if !executable(formatprg)
    call mylib#ShowMesg('ErrorMsg', formatprg . ': command not find')
    return
  endif

  exe printf('%d,%d!%s %s', 
        \ a:firstline, a:lastline, formatprg, (a:0 > 0 ? a:1 : ''))
endfunction
" }}}
function! myutils#FormatAll(...) " ... = option {{{
  let save_cursor = getpos('.')
  %call myutils#Format(a:0 > 0 ? a:1 : '')
  call setpos('.', save_cursor)
endfunction
" }}}
"==========================================================}}}1
" {{{1 Run
"--------------------------------------------------------------
function! s:Executable(file) 
  if !executable(a:file)
    call mylib#ShowMesg('ErrorMsg', "The executable file '" . a:file . "' doesn't exist")
    return 0
  endif
  return 1
endfunction

function! myutils#Run(contain_command, args) "{{{
  let args = mylib#ParseCmdArgs(a:args)

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
      call mylib#ShowMesg('ErrorMsg', 'b:run_command: Invalid type: ' . type(run_command))
      return
    endif

    if !empty(run_command)
      let command = run_command
      if type(command) == type('')
        if !s:Executable(command)
          return
        endif
        let command = mylib#Shellescape(command)
      elseif type(command) == type([])
        let temp = []
        let i = 0
        for val in command
          if type(val) != type('')
            call mylib#ShowMesg('ErrorMsg', 'b:run_command[' . i . ']: invalid type: ' . type(val))
            return
          elseif empty(val)
            call mylib#ShowMesg('ErrorMsg', 'b:run_command[' . i . ']: empty string')
            return
          endif

          if i == 0
            if !s:Executable(val)
              return
            endif
          endif
          call add(temp, mylib#Shellescape(val))

          let i += 1
        endfor

        unlet! command
        let command = escape(join(temp), '%#!')
      else
        call mylib#ShowMesg('ErrorMsg', 'b:run_command: Invalid type: ' . type(command))
        return
      endif
    elseif executable(expand('%:p:r'))
      let command = mylib#Shellescape(expand('%:p:r'))
    elseif executable(expand('%:p'))
      let command = mylib#Shellescape(expand('%:p'))
    else
      call mylib#ShowMesg('ErrorMsg', 'No executable file is found')
      return
    endif
  endif

  if !empty(args) && a:contain_command
    let command = remove(args, 0)
    if !s:Executable(command)
      return
    endif
    let command = mylib#Shellescape(command)
  endif

  let curwinnum = winnr()
  let winnum = CreateTempBuffer('_OutputPreview_')
  exe winnum . 'wincmd w'
  silent %d _

  call map(args, 'mylib#Shellescape(v:val)')
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
function! myutils#Inject(bufnr, text, newline) "{{{
  let bufnr = a:bufnr =~ '^\d\+' ? a:bufnr+0 : a:bufnr
  let nr = bufwinnr(bufnr)
  if nr != -1
    let curwin = winnr()
    if curwin == nr
      call mylib#ShowMesg('ErrorMsg', 'Inject: Cannot inject text into the same buffer')
      return
    endif
    exe nr . 'wincmd w'
    silent exec 'normal! i' . a:text . (a:newline ? "\<CR>" : '')
    exe curwin . 'wincmd w'
  else
    let nr = bufnr(bufnr)
    if nr == -1
      call mylib#ShowMesg('ErrorMsg', 'Inject: Buffer ' . string(a:bufnr) . ' does not exist')
      return
    endif

    let curbuf = bufnr('')
    if curbuf == nr
      call mylib#ShowMesg('ErrorMsg', 'Inject: Cannot inject text into the same buffer')
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
function! myutils#ScreenInject(other, winID, text) "{{{
  if !executable('screen')
    call mylib#ShowMesg('ErrorMsg', 'screen: command not find')
    return
  endif

  let tmpfile = tempname()
  let lines = split(a:text, '\n')
  call writefile(lines, tmpfile)
  let cmd = "silent !screen -X eval 'readreg x \"%s\"' 'select %d' 'paste x'"
  if a:other
    let cmd .= " 'other'"
  end
  exec printf(cmd, tmpfile, a:winID)
  call delete(tmpfile)
endfunction
"}}}
function! myutils#TmuxInject(other, targetPane, text) "{{{
  if !executable('tmux')
    call mylib#ShowMesg('ErrorMsg', 'tmux command not find')
    return
  endif

  let tmpfile = tempname()
  let lines = split(a:text, '\n')
  call writefile(lines, tmpfile)
  let cmd = "silent !tmux loadb \"%s\" \\; pasteb -t \"%s\" \\; deleteb"
  if a:other
    exec printf(cmd, tmpfile, a:targetPane)
  else
    let targetWindow = substitute(a:targetPane, '\.[^.]\+$', '', '')
    let cmd .= " \\; selectw -t \"%s\" \\; selectp -t \"%s\""
    exec printf(cmd, tmpfile, a:targetPane, targetWindow, a:targetPane)
  end
  call delete(tmpfile)
  redraw!
endfunction

"}}}
"==========================================================}}}1
" {{{1 Filter
"--------------------------------------------------------------
" Filter {range} lines through the external program {filtcmd} to other
" window.
"
" Ref: 1. Re: Filter to preview window 
"         <http://groups.yahoo.com/group/vim/message/62934>
"      2. The idea of specific preview window comes from 'taglist.vim'.
"      3. :h special-buffers
function! myutils#Filter(...) range " ... = filtcmd {{{
  let filtcmd = a:0 > 0 ? a:1 : exists('b:filter_cmd') ? b:filter_cmd : ''

  if filtcmd == ''
    let filtcmd = &filetype
  endif

  let curwinnum = winnr()
  let winnum = CreateTempBuffer('_OutputPreview_')

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
function! myutils#FilterAll(...) " ... = filtcmd {{{
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
  call myutils#Filter(filtcmd, join(getline(1, '$'), "\n"))
endfunction
" }}}
"==========================================================}}}1
" {{{1 Capitalize the selecting words (e.g. capitalize => Capitalize)
"--------------------------------------------------------------
" The function is modified from ``cream-capitalization.vim'', which is part of
" Cream.
function! myutils#Capitalize(mode, ...) " ... = preserve cases {{{
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
function! myutils#SwapWords(forward) "{{{
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
function! myutils#SwapChars(forward) "{{{
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
function! myutils#HungryDelete() "{{{
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
" {{{1 Seq: Insert a list of number (the same options as seq)
"--------------------------------------------------------------
function! myutils#InsertSeq(visual_mode, args) "{{{
  let seq = call('mylib#Seq', mylib#ParseCmdArgs(a:args))
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
" {{{1 MultipleEdit()
"--------------------------------------------------------------
function! myutils#CmdListFiles(A, L, P) "{{{
  " let line = substitute(a:L[ : a:P], '^\S\+\s*', '', '')
  let list = split(glob(a:A . '*'), '\n')
  call map(list, "v:val . (isdirectory(v:val) ? '/' : '')")
  return join(list, "\n")
endfunction
"}}}
function! myutils#MultipleEdit(...) "{{{
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
      call mylib#ShowMesg('ErrorMsg', 'E480: No match: ' . arg, 1)
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
" {{{1 GetOptVals(opt): Get possible values of given option (opt)
"--------------------------------------------------------------
function! myutils#GetOptVals(opt) 
  let opt = substitute(tolower(a:opt), '^\s\+\|\s\+$', '', 'g')
  if opt == ''
    return []
  endif

  let c = opt[0]

  if     c == 'a' " {{{
    if     opt == 'ambiwidth'  || opt == 'ambw'
      return ['single', 'double']
    endif
    " }}}
  elseif c == 'b' " {{{
    if     opt == 'backspace'  || opt == 'bs'
      return ['indent', 'eol', 'start']
    elseif opt == 'backupcopy' || opt == 'bkc'
      return ['yes', 'no', 'auto']
    elseif opt == 'bufhidden'  || opt == 'bh'
      return ['hide', 'unload', 'delete', 'wipe']
    elseif opt == 'browsedir'  || opt == 'bsdir'
      return ['last', 'buffer', 'current']
    elseif opt == 'buftype'    || opt == 'bt'
      return ['nofile', 'nowrite', 'acwrite', 'quickfix', 'help']
    elseif opt == 'background' || opt == 'bg'
      return ['dark', 'light']
    endif
    " }}}
  elseif c == 'c' " {{{
    if     opt == 'casemap'     || opt == 'cmp'
      return ['internal', 'keepascii']
    elseif opt == 'clipboard'   || opt == 'cb'
      return ['unnamed', 'autoselect', 'autoselectml', 'exclude']
    endif
    " }}}
  elseif c == 'd' " {{{
    if     opt == 'diffopt'      || opt == 'dip'
      return ['filler', 'context', 'icase', 'iwhite', 'horizontal', 'vertical', 'foldcolumn']
    elseif opt == 'display'      || opt == 'dy'
      return ['lastline', 'uhex']
    endif
    " }}}
  elseif c == 'e' " {{{
    if     opt == 'eadirection'  || opt == 'ead'
      return ['ver', 'hor', 'both']
    endif
    " }}}
  elseif c == 'f' " {{{
    if     opt == 'foldmethod' || opt == 'fdm'
      return ['marker', 'manual', 'indent', 'expr', 'syntax', 'diff']
    elseif opt == 'foldopen'   || opt == 'fdo'
      return ['all', 'block', 'hor', 'insert', 'jump', 'mark', 'percent', 'quickfix', 'search', 'tag', 'undo']
    elseif opt == 'fileformat' || opt == 'ff'
      return ['dos', 'unix', 'mac']
    elseif opt == 'fillchars'  || opt == 'fcs'
      return ['stl', 'stlnc', 'vert', 'fold', 'diff']
    endif
    " }}}
  elseif c == 'l' " {{{
    if    opt == 'listchars'  || opt == 'lcs'
      return ['eol', 'tab', 'trail', 'extend', 'precedes', 'nbsp']
    endif
    " }}}
  elseif c == 'm' " {{{
    if    opt == 'mousemodel' || opt == 'mousem'
      return ['extend', 'popup', 'popup_setpos']
    endif
    " }}}
  elseif c == 'n' " {{{
    if    opt == 'nrformats'  || opt == 'nf'
      return ['alpha', 'octal', 'hex']
    endif
    " }}}
  elseif c == 's' " {{{
    if     opt == 'selection'  || opt == 'sel'
      return ['inclusive', 'exclusive', 'old']
    elseif opt == 'scrollopt'  || opt == 'sbo'
      return ['ver', 'hor', 'jump']
    elseif opt == 'selectmode' || opt == 'slm'
      return ['mouse', 'key', 'cmd']
    elseif opt == 'sessionoptions' || opt == 'ssop'
      return ['blank', 'buffers', 'curdir', 'folds', 'globals', 'help', 'localoptions', 'options', 'resize', 'sesdir', 'slash', 'tabpages', 'unix', 'winpos', 'winsize']
    elseif opt == 'spellsuggest' || opt == 'sps'
      return ['best', 'double', 'fast', 'file', 'expr']
    elseif opt == 'switchbuf'  || opt == 'swb'
      return ['useopen', 'usetab', 'split', 'newtab']
    endif
    " }}}
  elseif c == 't' " {{{
    if     opt == 'toolbar' || opt == 'tb'
      return ['icons', 'text', 'horiz', 'tooltips']
    elseif opt == 'toolbariconsize' || opt == 'tbis'
      return ['tiny', 'small', 'medium', 'large']
    elseif opt == 'ttymouse' || opt == 'ttym'
      return ['xterm', 'xterm2', 'netterm', 'dec', 'jsbterm', 'pterm']
    endif
    " }}}
  elseif c == 'v' " {{{
    if     opt == 'viewoptions' || opt == 'vop'
      return ['cursor', 'folds', 'options', 'slash', 'unix']
    elseif opt == 'virtualedit' || opt == 've'
      return ['block', 'insert', 'all', 'onemore']
    endif
    " }}}
  elseif c == 'w' " {{{
    if     opt == 'wildmode'    || opt == 'wim'
      return ['full', 'longest', 'longest:full', 'list', 'list:full', 'list:longest']
    elseif opt == 'winaltkeys'  || opt == 'wak'
      retur ['no', 'yes', 'menu']
    endif
    " }}}
  endif

  return []
endfunction
"==========================================================}}}1
" {{{1 ShowMatch: Show all lines which the pattern matches
"      NOTE: :vimgrep /pattern/ %|copen 
"            may do the same job (except using file).
"--------------------------------------------------------------
function! myutils#ShowMatch(all_buffers, ...) "{{{
  let pattern = a:0 > 0 ? a:1 : ('\<' . expand('<cword>') . '\>')
  if pattern == ''
    return
  endif

  let curlnum = line('.')

  let bufout = {}

  let bufnum = bufnr('$')
  let curbuf = bufnr('%')

  let errormsg = ''
  let errorcnt = 0

  let i = 0
  while i < bufnum
    let output = ''
    redir => output
    exe printf('silent! g/%s/num', escape(pattern, '/'))
    redir END

    if output =~ '^\_s*E486:'
      let errormsg = output
      let errorcnt += 1
    else
      let bufout[bufnr('%')] = output
    endif

    if a:all_buffers
      bnext
      let i += 1
    else
      break
    endif
  endwhile

  if a:all_buffers
    exe 'b' curbuf
  endif

  if (a:all_buffers && errorcnt == bufnum) || !(a:all_buffers || empty(errormsg))
    call mylib#ShowMesg('ErrorMsg', errormsg)
    return
  endif

  let bufnrs = keys(bufout)
  if a:all_buffers
    call sort(bufnrs, '<SID>NumCompare')
  endif

  let curwinnum = winnr()
  let winnum = CreateTempBuffer('[MatchPreview]')

  exe winnum . 'wincmd w'

  silent %d _
  for nr in bufnrs
    let lines = split(bufout[nr], '\r\?\n')
    call map(lines, 'substitute(v:val,''^\s*\(\d\+\)'', printf(''%s|%d|\1|'',bufname(nr+0),nr),''g'')')
    call append(line('$'), lines)
  endfor
  silent 1d _

  let b:tempbuffer_title = 'Pattern: ' . pattern

  setl cursorline
  setl nowrap

  syn clear
  exe "syn match showMatchPattern " . "'" . escape(pattern, "'") . "'"
  syn match showMatchBufName '^[^|]*|'he=e-1 nextgroup=showMatchBufNr
  syn match showMatchBufNr   '\d\+|'he=e-1 nextgroup=showMatchLineNr contained
  syn match showMatchLineNr  '\d\+|'he=e-1 contained
  syn match showMatchSeparator  '|' contained containedin=showMatchBufNr,showMatchBufName,showMatchLineNr
  hi link showMatchBufNr LineNr
  hi link showMatchBufName Identifier
  hi link showMatchLineNr LineNr
  hi link showMatchPattern Special

  call cursor(1, 1)
  call search('^[^|]*|' . curbuf . '|')
  call search('^[^|]*|' . curbuf . '|' . curlnum . '|')

  let pattern = "'" . substitute(pattern, "'", "''", 'g') . "'"
  let pattern = substitute(pattern, '<', '<lt>', 'g')
  let cmd = ":call <SID>ShowMatchGoToLine(" . pattern . "," . curwinnum . ")<CR>"
  exe "nnoremap <buffer> <silent> <CR> " . cmd
  exe "nnoremap <buffer> <silent> <Leader><CR> " . cmd . '<Bar>:winc w<CR>'
  exe "nnoremap <buffer> <silent> <2-LeftMouse> " . cmd
endfunction
" }}}
function! s:NumCompare(v1, v2) "{{{
  let v1 = a:v1 + 0
  let v2 = a:v2 + 0
  return v1 == v2 ? 0 : v1 > v2 ? 1 : -1
endfunction
" }}}
function! s:ShowMatchGoToLine(pattern, winnum) "{{{
  let bufnr = str2nr(matchstr(getline('.'), '^[^|]*|\zs\d\+|'))
  if bufnr > 0
    let lnum = str2nr(matchstr(getline('.'), '^[^|]*|\d\+|\zs\d\+|'))

    if lnum > 0
      exe a:winnum . 'wincmd w'
      exe bufnr 'b'
      call cursor(lnum, 1)
      call search(a:pattern, 'c', lnum)
    endif
  endif
endfunction
" }}}
"==========================================================}}}1
" {{{1 StripSurrounding()
"--------------------------------------------------------------
function! myutils#StripFunc() 
  call mylib#StripSurrounding('\<\h\w*\s*(', '', ')')
endfunction
"==========================================================}}}1
" {{{1 PutNewLine()
"--------------------------------------------------------------
function! myutils#PutNewLine() "{{{
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
function! myutils#CompleteParen(paren,...) "{{{
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
" {{{1 CloseAllOtherWindows(): Close all windows except current and reserved windows
"--------------------------------------------------------------
function! myutils#MatchPattern(str, patterns) "{{{
  for pattern in a:patterns
    if a:str =~ pattern
      return 1
    endif
  endfor
  return 0
endfunction
"}}}
function! s:NumWinBuf(buf) "{{{
  let bufnr = bufnr(a:buf)
  let num = 0
  for winnr in range(1, winnr('$'))
    if winbufnr(winnr) == bufnr
      let num += 1
    endif
  endfor
  return num
endfunction
"}}}
function! s:CloseBuffer(buf, left) "{{{
  let num_win = s:NumWinBuf(a:buf)

  if num_win == 0
    return
  endif

  let left = a:left + 0
  if left < 0
    let left = 0
  endif

  while num_win > a:left
    let winnr = bufwinnr(a:buf)
    exe winnr . "wincmd w"
    silent! close!
    let num_win -= 1
  endwhile
endfunction
"}}}
let s:default_reserved_window_patterns = [ '^__Tag_List__$', '^\[FileExplorer\]\%(\[\d\+\]\)\?$']
function! s:WindowShouldReserved() "{{{
  if exists('g:CloseAllOtherWindowsReserveHandler')
    let result = call(g:CloseAllOtherWindowsReserveHandler, [])
    return result == -1 ? myutils#MatchPattern(bufname('%'), s:default_reserved_window_patterns) : result
endfunction
"}}}
function! myutils#CloseAllOtherWindows() "{{{
  if s:WindowShouldReserved()
    return
  endif

  let curbuf = bufnr('%')
  let curpos = getpos('.')

  for i in range(1, bufnr('$'))
    let winnr = bufwinnr(i)
    if (winnr == -1)
      continue
    endif

    exe winnr . "wincmd w"
    let buf = bufnr('%')

    if buf == curbuf
      call s:CloseBuffer(buf, 1)
    elseif !s:WindowShouldReserved()
      call s:CloseBuffer(buf, 0)
    endif
  endfor

  let winnr = bufwinnr(curbuf)
  if (winnr != -1)
    exe winnr . "wincmd w"
    call setpos('.', curpos)
  endif
endfunction
"}}}
" }}}
" {{{1 Build Tags
"--------------------------------------------------------------
function! myutils#Cscope(args, default, try_flist_name) "{{{
  if !executable('cscope')
    call mylib#ShowMesg('ErrorMsg', 'cscope: command not find', 1)
    return
  endif

  let cmd = 'silent !cscope -b '

  if a:default
    let cmd .= '-Rq '
  endif

  if a:try_flist_name && exists('g:flist_name') && filereadable(g:flist_name)
    let cmd .= '-i ' . mylib#Shellescape(g:flist_name) . ' '
  endif

  if exists('g:cscope_default_args')
    let cmd .= g:cscope_default_args
  endif

  exe cmd . a:args

  if exists('g:vim_resources_dir') && !empty(g:vim_resources_dir)
    if empty(glob(g:vim_resources_dir))
      call mkdir(g:vim_resources_dir, 'p')
    endif

    if isdirectory(g:vim_resources_dir)
      let files = glob('cscope.*', 0, 1)
      if (!empty(files))
        let move = g:MSWIN ? "move" : "mv"
        exe 'silent !'.move join(files) mylib#Shellescape(g:vim_resources_dir)
      endif
    endif
  endif

  redraw!
endfunction
"}}}
function! myutils#Ctags(args, default, try_flist_name) "{{{
  if !executable('ctags')
    call mylib#ShowMesg('ErrorMsg', 'ctags: command not find', 1)
    return
  endif

  let cmd =  'silent !ctags --c++-kinds=+p --fields=+iaS --extras=+q '

  if a:default
    let cmd .= '-R '
  endif

  if a:try_flist_name && exists('g:flist_name') && filereadable(g:flist_name)
    let cmd .= '-L ' . mylib#Shellescape(g:flist_name) . ' '
  endif

  if exists('g:vim_resources_dir') && !empty(g:vim_resources_dir)
    if empty(glob(g:vim_resources_dir))
      call mkdir(g:vim_resources_dir, 'p')
    endif

    let cmd .= '--tag-relative=yes -f ' . mylib#Shellescape(g:vim_resources_dir . '/tags')
  endif

  if exists('g:ctags_default_args')
    let cmd .= g:ctags_default_args
  endif

  exe cmd . a:args

  redraw!
endfunction
"}}}
function! myutils#SimpleRetag(...) "{{{
  let try_flist_name = a:0 ? a:1 : 0
  if has('cscope')
    try
      cs kill 0
    catch /^Vim\%((\a\+)\)\=:E261/
    endtry
  endif

  echohl MoreMsg
  echo "Rebuild cscope database..."
  echohl None
  call myutils#Cscope('', 1, try_flist_name)

  echohl MoreMsg
  echo "Rebuild ctags..."
  echohl None
  call myutils#Ctags('', 1, try_flist_name)

  let cscope_out = ''
  if exists('g:vim_resources_dir') && isdirectory(g:vim_resources_dir) && filereadable(g:vim_resources_dir . '/cscope.out')
    let cscope_out = g:vim_resources_dir . '/cscope.out'
  elseif filereadable('cscope.out')
    let cscope_out = 'cscope.out'
  endif
  if !empty(cscope_out)
    if has('cscope')
      exe 'cs add' g:vim_resources_dir . '/cscope.out'
    elseif has('nvim-0.9') && v:lua.has_cscope_maps()
      let g:cscope_maps_db_file = cscope_out
    endif
  endif

  redraw
  echohl MoreMsg
  echo "Done"
  echohl None
endfunction
"}}}
"==========================================================}}}1
" {{{1 Text objects selection
"--------------------------------------------------------------
" {{{2 Function
function! myutils#FuncTextObject(mode) " mode = [d|y|v]
  let skip = 'mylib#CanSkip(line(''.''), col(''.''))'
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
function! myutils#WebSearch(query) "{{{
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
  call myutils#OpenFile(query)
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
"==========================================================}}}1
" {{{1 ShowImage()
"--------------------------------------------------------------
function! myutils#ShowImage(files, ...) " ... = NotWithCursor {{{
  let python = s:MSWIN ? 'C:\Python26\pythonw.exe' : 'python'
  if !executable(python)
    call mylib#ShowMesg('ErrorMsg', python . ': command not find')
    return 1
  endif

  let image_viewer = globpath(&rtp, 'bin/image-viewer')
  if image_viewer == ''
    call mylib#ShowMesg('ErrorMsg', 'image-viewer: command not find')
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
    try
      if a:0 == 0 || a:1 == 0
        let pos = mylib#GetPos()
      else
        let pos = { 'x': getwinposy(), 'y': getwinposy() }
      endif
    catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
      let pos = { 'x': getwinposy(), 'y': getwinposy() }
    endtry

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
"==========================================================}}}1
" {{{1 OpenFile(): open file according to the file association
"--------------------------------------------------------------
function! myutils#OpenFile(file) "{{{
  try
		let file = mylib#Shellescape(a:file, 1)
  catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
		let file = shellescape(a:file, 1)
	endtry

	let cmd = s:MSWIN 
				\ ? 'start RunDll32.exe shell32.dll,ShellExec_RunDLL'
				\ : executable('gnome-open') 
				\   ? 'gnome-open'
				\   : executable('xdg-open')
				\     ? 'xdg-open'
				\     : ''

	if cmd != ''
		silent exe '!' . cmd . ' ' . file
    return v:shell_error == 0 ? 0 : 1
	endif

	return 1
endfunction
"}}}
"==========================================================}}}1
" {{{1 ColorSelector()
"--------------------------------------------------------------
function! myutils#ColorSelector(mode) "{{{
  if !executable('color-selector')
    call mylib#ShowMesg('ErrorMsg', 'color-selector: command not find')
    return 1
  endif

  let prev_color = ''
  if a:mode == 'v'
    let prev_color = mylib#GetSelection()
  endif

  let len = strlen(substitute(prev_color, '.', 'x', 'g'))
  let prev_color = substitute(prev_color, '[\r\n \t]\+', '', 'g')
  if empty(prev_color)
    let color = system('color-selector')
  else
    let color = system('color-selector "' . prev_color . '"')
  endif

  let color = substitute(color, '[\f\r\n \t]\+', '', 'g')
  let color = matchstr(color, '\[\d\+,\d\+,\d\+\]')
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
"==========================================================}}}1
" {{{1 Enclose(): Enclose text with braces.
"--------------------------------------------------------------
function! myutils#Enclose(paren, line1, line2) "{{{
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
" {{{1 VimEval(): Evaluate given expression and return the result
"                 (when error occurs returns 0)
"--------------------------------------------------------------
function! myutils#EvalVim(expr) "{{{
  try
    let res = eval(tr(a:expr, "\n", ' '))
    return type(res) == type('') ? res : string(res)
  catch /^Vim\%((\a\+)\)\=:/
    call mylib#ShowMesg('ErrorMsg', substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', ''), 1)
    throw 'Error'
  catch
    call mylib#ShowMesg('ErrorMsg', v:exception, 1)
    throw 'Error'
  endtry
endfunction
"}}}
function! myutils#IEvalVim(mode) "{{{
  try
    let res = myutils#EvalVim(getline('.'))
  catch 
    return ''
  endtry

  if a:mode == 'e'
    return "\<C-G>u" . res
  elseif a:mode == 'j'
    return "\<C-G>u\<End>\<CR> \<C-U>" . res
  endif
endfunction
"}}}
function! myutils#NEvalVim(mode) "{{{
  try
    let res = myutils#EvalVim(getline('.'))
  catch 
    return
  endtry

  if a:mode == 'e'
    exec 'norm! A'. res
  elseif a:mode == 'j'
    exec "norm! o \<C-U>" . res
  endif
endfunction
"}}}
function! myutils#VEvalVim(mode) "{{{
  try
    let res = myutils#EvalVim(mylib#GetSelection())
  catch 
    return
  endtry

  if a:mode == 'e'
    exec 'norm! `>' . (visualmode()=='V' ? 'A' : col("'>") == strlen(getline("'>"))+1 ? 'a' : 'i') . res
  elseif a:mode == 'j'
    exec "norm! `>o\<C-O>\"_S" . res
  elseif a:mode == 'r'
    let del = 'gv"_d' 
    if visualmode() == 'V'
      exec 'norm!' del . (line("'>") == line('$') ? 'o' : 'O') .  " \<C-U>" . res
    else
      exec 'norm!' del
      redraw
      let insert = col("'<") == strlen(getline("'<"))+1 ? 'a' : 'i'
      exec 'norm!' insert . res
    endif
  endif
endfunction
"}}}
"}}}
"==========================================================}}}1
" {{{1 OpenMRUList()
"--------------------------------------------------------------
let s:bufexplorer_SID = -1
function! s:OpenMRUList_OpenFile() "{{{
  let idx = line('.')-1
  if idx >= len(b:mru_list)
    echom "buffer not found"
    return
  endif

  let bufnr = b:mru_list[idx]

  wincmd p
  exec 'b' bufnr
endfunction
"}}}
function! s:OpenMRUList_Init() "{{{
  exec 'resize' max([&lines/4, 10])
  setl cursorline nowrap wfh noma
  nnoremap <buffer> <silent> <CR> :<C-U>call <SID>OpenMRUList_OpenFile()<CR>
endfunction
"}}}
function! s:OpenMRUList_Update(mru_list) "{{{
  setl ma
  let b:mru_list = filter(copy(a:mru_list), '!empty(bufname(v:val)) && buflisted(v:val)')
  call setline(1, map(copy(b:mru_list), 'bufname(v:val)'))
  setl noma
endfunction
"}}}
function! myutils#GetMRUList() "{{{
  if s:bufexplorer_SID == -1
    redir => l:scriptnames
    silent scriptnames
    redir END

    for name in split(l:scriptnames, "\n")
      let m = matchstr(name, '^\s*\zs\d\+\ze:.\{-}[\\/]bufexplorer\.vim')
      if !empty(m)
        let s:bufexplorer_SID = m
        break
      endif
    endfor
  endif

  if s:bufexplorer_SID == -1
    echom "plugin bufexplorer not found"
    return []
  endif

  redir => l:mru_list
  silent call call(printf("<SNR>%d_BEMRUListShow", s:bufexplorer_SID), [])
  redir END

  for item in split(l:mru_list, "\n")
    let m = matchstr(item, '\[[^]]*\]')
    if !empty(m)
      unlet l:mru_list
      let l:mru_list = eval(m)
    endif
  endfor

  if type(l:mru_list) != type([])
    echom "MRUList not found"
    return []
  endif

  return l:mru_list
endfunction
"}}}
function! myutils#OpenMRUList() "{{{
  let mru_list = myutils#GetMRUList()
  if empty(mru_list)
    echom "MRUList not found"
    return
  endif
  let winnum = CreateSharedTempBuffer('_MRU_Files_', '<SNR>'.s:SID().'_OpenMRUList_Init')
  exe winnum . 'wincmd w'
  call s:OpenMRUList_Update(mru_list)
endfunction
"}}}
"==========================================================}}}1
" {{{1 CheckExpandTab()
"--------------------------------------------------------------
function! myutils#CheckExpandTab()
  let has_syn_items = has('syntax_items')
  let cur_pos = getpos('.')
  call cursor(1, 1)

  " It's just a heuristic guess: Once we find a line beginning with a tab,
  " we consider the buffer is in 'noexpandtab' mode
  " (the default is 'expandtab' mode)
  let lnum = search('^\t', 'cW')
  while lnum != 0
    if !has_syn_items || synIDattr(synID(lnum, 1, 0), 'name') !~? 'string\|comment'
      setl noet
      call setpos('.', cur_pos)
      return
    endif

    let lnum = search('^\t', 'W')
  endwhile
  call setpos('.', cur_pos)
endfunction
"==========================================================}}}1
"==============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
