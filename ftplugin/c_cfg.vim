" c configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
compiler gcc
if exists('*mylib#AddOptFiles') && isdirectory($HOME . '/local/include')
  call mylib#AddOptFiles('path', $HOME . '/local/include')
endif
" }}}
"===================================================================
" Commands {{{
"-------------------------------------------------------------------
if executable('cfunc')
  command! -nargs=+ -complete=file CFuncSkel  r !cfunc -m s <args>
  command! -nargs=+ -complete=file CFuncProto r !cfunc -m p <args>
endif
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
inoremap <silent> <buffer> <Leader>k <C-X><C-K>
inoremap <silent> <buffer> <Leader>p <C-R>=<SID>CFuncType()<CR><C-R>=<SID>Imap()<CR>

if exists('*mylib#CNewLine')
  inoremap <silent> <buffer> <C-J> <C-R>=mylib#CNewLine()<CR>
endif

if exists('*mapping#CompleteParen')
  call mapping#CompleteParen('([{')
endif

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[{}\])]')
endif

if exists('*mapping#Enter')
  call mapping#Enter('{', '}')
endif
" }}}
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
if !exists('*s:Imap')
  function! s:Imap() "{{{
    if !exists('*IMAP_Jumpfunc')
      return ''
    endif
    return IMAP_Jumpfunc('', 0)
  endfunction
  "}}}
endif
if !exists('*s:PlaceHolder')
  function! s:PlaceHolder(args) "{{{
    if a:args =~ '^\s*$' || !exists('*IMAP_GetPlaceHolderStart')
      return args
    endif

    let args = a:args
    let phs = escape(IMAP_GetPlaceHolderStart(), '\&~')
    let phe = escape(IMAP_GetPlaceHolderEnd(), '\&~')

    let args = substitute(args, '\c\s*\[\(,\s\+\)\?ARG,\s\+\.\.\.\]', '\1...', 'g')
    let args = substitute(args, '\([^,\. ][^,\.]\{-}\)\%(\s*\%(,\|$\)\)\@=', phs.'\1'.phe, 'g')
    let args = substitute(args, '\(\s*\)\(,\s*\.\.\.\)', '\1'.phs.'\2'.phe, 'g')

    return args
  endfunction
  "}}}
endif
if !exists('*s:GetArgs')
  function! s:GetArgs(func, proto) "{{{
    let idx = matchend(a:proto, '\V'.escape(a:func, '\'))
    if idx == -1
      return ''
    endif
    let idx = stridx(a:proto, '(', idx)
    if idx == -1
      return ''
    endif
    let lp = 1
    let idx += 1
    for i in range(idx, strlen(a:proto)-1)
      let ch = a:proto[i]
      if ch == '('
        let lp += 1
      elseif ch == ')'
        let lp -= 1
      endif
      if lp == 0
        return a:proto[idx : i-1]
      endif
    endfor
    return ''
  endfunction
  "}}}
endif
if !exists('*s:GetPrototypesFromPreviewWindow')
  function! s:GetPrototypesFromPreviewWindow(func) "{{{
    for nr in range(1, winnr('$'))
      if getwinvar(nr, '&pvw')
        let info = {}
        let lines = getbufline(winbufnr(nr), 1, '$')
        for line in lines
          let m = matchlist(line, '^\(\w\+\):\s*\(.\{-}\)\s*$')
          if empty(m)
            continue
          endif
          let info[m[1]] = m[2]
        endfor
        if has_key(info, 'name') && info['name'] == a:func
              \ && has_key(info, 'signature')
          return [ a:func . info['signature'] ]
        endif
        break
      endif
    endfor
    return []
  endfunction
  "}}}
endif
if !exists('*s:CFuncType')
  function! s:CFuncType() "{{{
    let func = matchstr(getline('.')[:col('.')-2], '\w\+\ze\s*($')
    if func =~ '^\%(if\|while\|for\|switch\|\s*\)$'
      return ''
    endif
    let prototypes = s:GetPrototypesFromPreviewWindow(func)
    if empty(prototypes) && executable('cfuncproto') 
      let prototypes = split(system('cfuncproto '.func), '\n')
    endif
    if empty(prototypes)
      return ''
    endif
    let prototypes = map(prototypes, 's:PlaceHolder(s:GetArgs(func, v:val))')
    call complete(col('.'), prototypes)
    return getline('.')[col('.')-1] == ')' ? '' : ')'
  endfunction
  "}}}
endif
" CExpandTagCallback "{{{
if !exists('*CExpandTagCallback')
  function! CExpandTagCallback(col) "{{{
    let line = a:col > 1 ? getline('.')[0 : a:col-1] : ''
    if line =~ '^\s*#inc\c$'
      return 0
    endif

    if line =~ '^.*\Wdo$'
      return 0
    endif

    return -1
  endfunction
  "}}}
endif
let g:ExpandTagCallback_{split(&ft, '\.')[0]} = 'CExpandTagCallback'
"}}}
" }}}
"===================================================================
" C Only {{{
"-------------------------------------------------------------------
if &ft != 'c'
  finish
endif

if exists('*mylib#AddOptFiles')
  call mylib#AddOptFiles('tags', 'tags/cstd.tags')
  call mylib#AddOptFiles('tags', 'tags/lsb32.tags')

  call mylib#AddOptFiles('dict', 'keywords/c')
  set complete+=k
endif

" <http://mysite.wanadoo-members.co.uk/indent/beautify.html>
if executable('indent') 
  vnoremap <silent> <buffer> + :call <SID>CIndent()<CR>
  nnoremap <silent> <buffer> + :call <SID>CIndentAll()<CR>
endif

if !exists('s:CIndent')
  function! s:CIndent() range "{{{
    let ts = &ts
    let tw = &tw == 0 ? 80 : &tw
    let et = &et == 1 ? '' : ' -nut '
    let iopt = printf(' -cli%d -i%d -ci%d -ts%d -ip%d ', ts, ts, ts, ts, ts)
    let cmd = printf('indent -st -npro -bad -bap -nsob -fc1 -fca -c33 -cd33 '
          \ . '-cp33 -ncdb -sc -br -nce -ncdw -cbi0 -nss -nprs -npcs -ss '
          \ . '-saf -sai -saw -di%d -nlps -bls -lp -l%d -bbo -hnl %s %s', 
          \   ts*2, tw, et, iopt)
    exec printf('%d,%d!'.cmd, a:firstline, a:lastline)
  endfunction
  "}}}
  function! s:CIndentAll() "{{{
    let save_cursor = getpos('.')
    %call s:CIndent()
    call setpos('.', save_cursor)
  endfunction "}}}
endif

if executable('insert_missing_includes') && !exists(':CInsMissInc')
	command -nargs=0 CInsMissInc call <SID>CInsMissInc()
  function! s:CInsMissInc() "{{{
    %!insert_missing_includes
    %s///ge
  endfunction
  "}}}
endif

if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping([['/*', '*/'], '//'], [30, 45, 60])
endif
" }}}
"===================================================================
" vim: fdm=marker :
