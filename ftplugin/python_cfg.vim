" python configuration file
"===================================================================
" Coc setting {{{
"-------------------------------------------------------------------
if exists('*CocSettingInit')
  call CocSettingInit()
endif
"}}}
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
if !exists('*s:Indent')
  function! s:Indent() "{{{
    let lnum = prevnonblank(line('.') - 1)
    let indent = (lnum == 0 ? '' : repeat(' ', indent(lnum)))
    let curindent = matchstr(getline('.'), '^\s*')
    let pos = getpos('.')
    call setline('.', substitute(getline('.'), '^\s*', indent, ''))
    call cursor(pos[1], pos[2] + (strlen(indent) - strlen(curindent)))
  endfunction
  " }}}
endif
if !exists('*s:NewLine')
  function! s:NewLine() "{{{
    let newline = "\<C-O>o"

    let ch = getline('.')[col('.')-2]
    if col('.') == 1 || ch != ':'
      return newline
    endif

    if has('syntax_items')
          \ && synIDattr(synID(line('.'), col('.'), 0), 'name') =~? 'string\|comment'
      return newline
    endif

    return "\<BS>\<C-O>A:\<CR>"
  endfunction
  "}}}
endif

try
  call mylib#AddOptFiles('dict', 'keywords/python')
  set complete+=k
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry
" }}}
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
function! RunCommandPython() 
  return ['python', expand('%:p')]
endfunction

" Avoid E705: Variable name conflicts with existing function.
unlet! b:run_command_python
let b:run_command_python = function('RunCommandPython')

silent! compiler python
setlocal ts=4 sts=4 sw=4 et

if exists('g:use_codeintel') && g:use_codeintel
  setlocal completefunc=codeintel#Complete
endif
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
try
  call mapping#CompleteParen('([{')
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[}\])]')
endif

try
  call IndentForComment#IndentForCommentMapping(['#'], [30, 45, 60])
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

inoremap <silent> <buffer> <Leader>> <C-\><C-O>:call <SID>Indent()<CR>
if empty(maparg('<Leader>.', 'i'))
  inoremap <silent> <buffer> <Leader>. <C-\><C-O>:call <SID>Indent()<CR>
endif

inoremap <silent> <buffer> <C-J> <C-R>=<SID>NewLine()<CR>
" }}}
"===================================================================
" vim: fdm=marker :
