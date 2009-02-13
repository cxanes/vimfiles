" css configuration file
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
if exists('*CompleteParenMap')
  call CompleteParenMap('{')
endif

if exists('*MoveToMap')
  call MoveToMap('[}]')
endif

if exists('*EnterMap')
  call EnterMap('{', '}')
endif
" }}}
"===================================================================
" vim: fdm=marker :
