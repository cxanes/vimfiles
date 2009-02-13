" python configuration file
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

if exists('*AddOptFiles')
  call AddOptFiles('dict', 'keywords/python')
  set complete+=k
endif
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
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
if exists('*CompleteParenMap')
  call CompleteParenMap('([{')
endif

if exists('*MoveToMap')
  call MoveToMap('[}\])]')
endif

if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping(['#'], [30, 45, 60])
endif

inoremap <silent> <buffer> <Leader>> <C-\><C-O>:call <SID>Indent()<CR>
if empty(maparg('<Leader>.', 'i'))
  inoremap <silent> <buffer> <Leader>. <C-\><C-O>:call <SID>Indent()<CR>
endif

inoremap <silent> <buffer> <C-J> <C-R>=<SID>NewLine()<CR>
" }}}
"===================================================================
" vim: fdm=marker :
