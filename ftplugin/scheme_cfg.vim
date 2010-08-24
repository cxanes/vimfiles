" scheme configuration file
"===================================================================
" Key Mappings {{{1
"-------------------------------------------------------------------
try
  call mapping#CompleteParen('(')
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[)]')
endif

try
  call IndentForComment#IndentForCommentMapping([';'], [30, 45, 60])
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry
" }}}1
"===================================================================
" vim: fdm=marker :
