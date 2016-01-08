" css configuration file
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
try
  call mapping#CompleteParen('{')
  call mapping#MoveTo('[}]')
  call mapping#Enter('{', '}')
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry
" }}}
"===================================================================
" vim: fdm=marker :
