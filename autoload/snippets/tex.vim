function! snippets#tex#Font(attr, ...) "{{{
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
    return '\math' . a:attr . (a:0 ? a:1 : "{<{}>\<C-Q>}")
  else
    return '\text' . a:attr . (a:0 ? a:1 : "{<{}>\<C-Q>}")
  endif
endfunction
"}}}
" vim: fdm=marker :
