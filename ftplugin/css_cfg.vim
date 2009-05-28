" css configuration file
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
if exists('*mapping#CompleteParen')
  call mapping#CompleteParen('{')
endif

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[}]')
endif

if exists('*mapping#Enter')
  call mapping#Enter('{', '}')
endif
" }}}
"===================================================================
" vim: fdm=marker :
