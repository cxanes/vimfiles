" dot configuration file
"===================================================================
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
function! SetMakePrgDot() 
  compiler dot
endfunction

let b:set_makeprg_dot = 'SetMakePrgDot'
" }}}
"===================================================================
" vim: fdm=marker :
