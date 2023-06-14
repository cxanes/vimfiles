"--------------------------------------------------------------
" *
"--------------------------------------------------------------
if (g:MSWIN && executable('makeprg.bat')) || executable('makeprg')
  augroup Vimrc
    au FileType * call <SID>SetMakeprgFT(expand('<amatch>'))
  augroup END
  command! -nargs=? SetMakeprg call SetMakeprg(<q-args>)

  function! s:SetMakeprgFT(ft) "{{{
    if empty(a:ft)
      return
    endif

    let func = 'b:set_makeprg_' . a:ft
    if exists(func)
      call call(eval(func), [])
    else
      call SetMakeprg()
    endif
  endfunction
  "}}}
  function! SetMakeprg(...) "{{{
    if &makeprg != 'make'
      return
    endif
    let args = a:0 > 0 ? a:1 : ''
    if args !~ '^\s*$'
      let args = escape(' ' . args, ' \|"')
    endif
    exec 'setlocal makeprg=makeprg\ -t\ '''.&ft.'''\ ''%:p''' . args
  endfunction
  "}}}
endif

if has('autocmd') && exists('+omnifunc')
  augroup Vimrc
    au Filetype *
          \	if &omnifunc == '' |
          \		setlocal omnifunc=syntaxcomplete#Complete |
          \	endif
  augroup END
endif

" Modified from a.vim <http://www.vim.org/scripts/script.php?script_id=31>
" function ExpandAlternatePath()
function! s:ExpandAlternatePath(pathSpec, sfPath) "{{{
  let prfx = strpart(a:pathSpec, 0, 4)
  if prfx == 'wdr:' || prfx == 'abs:'
    let path = strpart(a:pathSpec, 4)
  elseif prfx == 'reg:'
    let re     = strpart(a:pathSpec, 4)
    let sep    = strpart(re, 0, 1)
    let patend = match(re, sep, 1)
    let pat    = strpart(re, 1, patend - 1)
    let subend = match(re, sep, patend + 1)
    let sub    = strpart(re, patend + 1, subend - patend - 1)
    let flag   = strpart(re, strlen(re) - 2)
    if (flag == sep)
      let flag = ''
    endif
    let path = substitute(a:sfPath, pat, sub, flag)
    "call confirm('PAT: [' . pat . '] SUB: [' . sub . ']')
    "call confirm(a:sfPath . ' => ' . path)
  else
    let path = a:pathSpec
    if (prfx == 'sfr:')
      let path = strpart(path, 4)
    endif
    let path = a:sfPath . '/' . path
  endif
  return path
endfunction
"}}}

" Modified from a.vim <http://www.vim.org/scripts/script.php?script_id=31>
" function FindFileInSearchPathEx()
function! s:FindFileInSearchPathEx(fileName, pathList, relPathBase, count) "{{{
  let spath = ''

  if !empty(a:pathList)
    if type(a:pathList) == type("")
      let items = split(a:pathList, ',')
    else
      let items = a:pathList
    endif

    if !empty(items)
      let spath = join(map(items, 'escape(s:ExpandAlternatePath(v:val, a:relPathBase), '' \,'')'), ',')
    endif
  endif

  if !empty(&path)
    if !empty(spath)
      let spath .= ','
    endif
    let spath .= &path
  endif

  return findfile(a:fileName, spath, a:count)
endfunction
"}}}

function! IncludeExpr(fname) "{{{
  if !exists('g:alternateSearchPath')
    return a:fname
  endif

  let currentPath = expand('%:p:h')
  let openCount = 1

  let fileName = s:FindFileInSearchPathEx(a:fname, g:alternateSearchPath, currentPath, openCount)
  return empty(fileName) ? a:fname : fileName
endfunction
"}}}
function! SetIncludeExpr() "{{{
  if empty(&includeexpr)
    setlocal includeexpr=IncludeExpr(v:fname)
  endif
endfunction
"}}}
function! s:IncludeExprInit() "{{{
  if !exists('g:loaded_alternateFile')
    delfunction SetIncludeExpr
    return
  endif

  augroup Vimrc
    au FileType * call SetIncludeExpr()
  augroup END
  call SetIncludeExpr()
endfunction
"}}}
augroup Vimrc
  au VimEnter * call <SID>IncludeExprInit()|delfunction <SID>IncludeExprInit
augroup END

" Map special section motion (:h section)
if !exists('g:opt_map_special_section_motion')
  let g:opt_map_special_section_motion = 0
endif

function! s:MapSpecialSectionMotion() "{{{
  map <buffer> [[ ?{<CR>w99[{
  map <buffer> ][ /}<CR>b99]}
  map <buffer> ]] j0[[%/{<CR>
  map <buffer> [] k$][%?}<CR>
endfunction
"}}}
function! s:UnmapSpecialSectionMotion() "{{{
  unmap <buffer> [[
  unmap <buffer> ][
  unmap <buffer> ]]
  unmap <buffer> []
endfunction
"}}}
function! s:SetupSpecialSectionMotion() "{{{
  if !exists('g:opt_map_special_section_motion')
    let g:opt_map_special_section_motion = 0
  endif

  if g:opt_map_special_section_motion == 0
    return
  endif

  if !empty(maparg('[['))
    return
  endif

  call s:MapSpecialSectionMotion()
endfunction
"}}}

command! MapSpecialSectionMotion   call <SID>MapSpecialSectionMotion()
command! UnmapSpecialSectionMotion call <SID>UnmapSpecialSectionMotion()

augroup Vimrc
  au Filetype * call <SID>SetupSpecialSectionMotion()
augroup END
"--------------------------------------------------------------
" *.m
"--------------------------------------------------------------
let filetype_m = 'matlab'
augroup Vimrc
  au BufRead,BufNewFile *.m setl suffixesadd+=.m
augroup END
"--------------------------------------------------------------
" .vimrc, .gvimrc
"--------------------------------------------------------------
command! -bang Vimrc  if <q-bang> == '!'|exe "tabe" g:MYVIMRUNTIME . "/_vimrc"|else|exe 'e' g:MYVIMRUNTIME . '/_vimrc' |exe 'lcd' g:MYVIMRUNTIME |endif

augroup Vimrc
  au BufRead,BufNewFile .vimrc,_vimrc,.gvimrc,_gvimrc let b:UpdateModifiedTime = 1
  au BufRead,BufNewFile .vimrc,_vimrc setlocal foldmethod=marker foldtext=VimrcTOCFoldLine()
augroup END
function! VimrcTOCFoldLine() "{{{
  let isHeadline = match(getline(v:foldstart), '^\s*"\s*[^{]\+{\{3}\d\+\s*$')
  if isHeadline == -1
    return foldtext()
  endif
  let line = getline(v:foldstart+1)
  return v:folddashes.substitute(line,'^\s*"\s*','> ', 'g')
endfunction
"}}}
"--------------------------------------------------------------
" c, cpp
"--------------------------------------------------------------
" let g:c_comment_strings	= 1
augroup Vimrc
  au FileType c,cpp call myutils#CheckExpandTab()
augroup END
"--------------------------------------------------------------
" changelog
"--------------------------------------------------------------
augroup Vimrc
  au FileType changelog nnoremap <buffer> <F6> :<C-U>NewChangelogEntry<CR>
augroup END
"--------------------------------------------------------------
" help
"--------------------------------------------------------------
augroup Vimrc
  au FileType help nnoremap <buffer> <CR> <C-]>
  au FileType help nnoremap <buffer> <BS> <C-T>
  au FileType help set nolist
augroup END
"--------------------------------------------------------------
" quickfix
"--------------------------------------------------------------
let g:qf_disable_statusline = 1
"--------------------------------------------------------------
" shell
"--------------------------------------------------------------
" Set for the cygwin version of bash.
" New version of bash seems only accept the unix newline format.
augroup Vimrc
  au FileType sh set fileformat=unix
augroup END
let g:is_bash = 1
"--------------------------------------------------------------
" tex
"--------------------------------------------------------------
let g:tex_flavor = 'latex'
"--------------------------------------------------------------
" perl
"--------------------------------------------------------------
let g:perl_want_scope_in_variables = 1
let g:perl_extended_vars = 1
"--------------------------------------------------------------
" ruby
"--------------------------------------------------------------
let g:rct_completion_use_fri = 0
let g:rct_completion_info_max_len = 20
let g:rct_use_python = 1
"--------------------------------------------------------------
" python
"--------------------------------------------------------------
let python_highlight_numbers           = 1
let python_highlight_builtins          = 1
let python_highlight_exceptions        = 1
let python_highlight_string_formatting = 1

let g:pyindent_open_paren   = 'match(getline(plnum),''[({\[][^({\[]*$'')-indent(plnum)+1'
let g:pyindent_nested_paren = g:pyindent_open_paren
"--------------------------------------------------------------
" Binary (:h hex-editing)
"--------------------------------------------------------------
function! s:BinaryMode(pattern) "{{{
  augroup Binary
    exec 'au BufReadPre   ' . a:pattern . ' let &bin=1'
    exec 'au BufReadPost  ' . a:pattern . ' if &bin | silent %!xxd'
    exec 'au BufReadPost  ' . a:pattern . ' set ft=xxd | endif'
    exec 'au BufWritePre  ' . a:pattern . ' if &bin | silent %!xxd -r'
    exec 'au BufWritePre  ' . a:pattern . ' endif'
    exec 'au BufWritePost ' . a:pattern . ' if &bin | silent %!xxd'
    exec 'au BufWritePost ' . a:pattern . ' set nomod | endif'
  augroup END
endfunction
"}}}
command! BinaryMode call <SID>BinaryMode('<lt>buffer>')|e
"--------------------------------------------------------------
" markdown
"--------------------------------------------------------------
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0

" vim: fdm=marker : ts=2 : sw=2 :
