if exists('b:load_tex_snippets')
  finish
endif
let b:load_tex_snippets = 1

ru syntax/snippet.vim

if exists('*SnipMapKeys')
  call SnipMapKeys()
endif

"=================================================
" Snippets {{{
"-------------------------------------------------
Snippet \ <{command:snippets#tex#__init__#CreateCommand(D('textnormal'))}>
if exists('*Tex_FastEnvironmentInsert')
  Snippet env <{:snippets#tex#__init__#Tex_FastEnvironmentInsert()}>
endif
Snippet rm <{:snippets#tex#__init__#Font('rm')}>
Snippet tt <{:snippets#tex#__init__#Font('tt')}>
Snippet bf <{:snippets#tex#__init__#Font('bf')}>
Snippet sf <{:snippets#tex#__init__#Font('sf')}>
Snippet it <{:snippets#tex#__init__#Font('it')}>
Snippet sl \textsl{<{}>}
"}}}
"=================================================
" Functions {{{
"-------------------------------------------------
function! snippets#tex#__init__#Tex_FastEnvironmentInsert() "{{{
  return substitute(Tex_FastEnvironmentInsert('no'), '<'.'+\(.\{-}\)+>', '<{\1}>', 'g')
endfunction
"}}}
function! snippets#tex#__init__#WrapInCommand(text) "{{{
  return '\<{command}>{'.substitute(a:text, '^\s\+\|\s\+$', '', 'g').'}<{}>'
endfunction
"}}}
function! snippets#tex#__init__#CreateCommand(text) "{{{
  let command = a:text
  if command == ''
    let command = '<{command}>'
  endif
  return '\'.command.'{<{}>}'
endfunction
"}}}
function! snippets#tex#__init__#Font(attr) "{{{
  let in_math = 0

  " For '$...$' and '$$...$$', since searchpairpos() cannot handle these two tokens.
  if has('syntax_items')
    if exists('*synstack')
      let syn = synstack(line('.'), col('.')-1)
      if !empty(syn)
        call reverse(syn)
        for id in syn
           if synIDattr(id, 'name') =~? 'math'
             let in_math = 1
             break
           endif
        endfor
      endif
    elseif synIDattr(synID(line('.'), col('.')-1, 1), 'name') =~? 'math'
      let in_math = 1
    endif
  endif

  let [lnum , col] = [0, 0]
  if in_math == 0
    for [s, m, e] in [
          \  ['\\begin{math}',        '', '\\end{math}'],
          \  ['\\begin{displaymath}', '', '\\end{displaymath}'],
          \  ['\\begin{equation}',    '', '\\end{equation}'],
          \  ['\\begin{eqnarray}',    '', '\\end{eqnarray}'],
          \  ['\\begin{eqnarray\*}',  '', '\\end{eqnarray\*}'],
          \  ['\\\[',                 '', '\\\]'],
          \ ]
      let [lnum , col] = searchpairpos(s, m, e, 'bnW')
      if [lnum, col] != [0, 0]
        let in_math = 1
        break
      endif
    endfor
  endif

  if in_math
    let [tlnum , tcol] = searchpairpos('\\mbox{', '', '}', 'bnW')
    if [tlnum, tcol] != [0, 0]
          \ && ([lnum, col] == [0, 0] 
          \     || tlnum < lnum 
          \     || (tlnum == lnum && tcol < col))
      let in_math = 0
    endif
  endif

  if in_math
    return '\math' . a:attr . "{<{}>\<C-Q>}"
  else
    return '\text' . a:attr . "{<{}>\<C-Q>}"
  endif
endfunction
"}}}
"}}}
"=================================================
" Commands {{{
"-------------------------------------------------
call SnippetSetCommand('<C-T>', 'snippets#tex#__init__#WrapInCommand', 's')
call SnippetSetCommand('<Leader>cc', 'snippets#tex#__init__#CreateCommand', 'ws')
"}}}
"=================================================
" vim: set fdm=marker :
