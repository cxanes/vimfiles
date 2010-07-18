" Emacs Org-Mode configuration file
"===================================================================
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
set si
set fdm=expr
set foldexpr=Org_FoldExpr(v:lnum)

function! Org_FoldExpr(lnum) 
  let line = getline(a:lnum)
  let level = strlen(matchstr(line, '^\*\{1,4}\%([^\*]\)\@='))
  if level == 0
    return '='
  else
    return '>' . level
  endif
endfunction
" }}}
"===================================================================
" vim: fdm=marker :
