" scheme configuration file
"===================================================================
" Key Mappings {{{1
"-------------------------------------------------------------------
if exists('*mapping#CompleteParen')
  call mapping#CompleteParen('(')
endif

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[)]')
endif

if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping([';'], [30, 45, 60])
endif
" }}}1
"===================================================================
" vim: fdm=marker :
