" scheme configuration file
"===================================================================
" Key Mappings {{{1
"-------------------------------------------------------------------
if exists('*CompleteParenMap')
  call CompleteParenMap('(')
endif

if exists('*MoveToMap')
  call MoveToMap('[)]')
endif

if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping([';'], [30, 45, 60])
endif
" }}}1
"===================================================================
" vim: fdm=marker :
