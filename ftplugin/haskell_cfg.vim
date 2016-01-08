" haskell configuration file
" Reference: http://projects.haskell.org/haskellmode-vim/
"===================================================================
" Setting 
"-------------------------------------------------------------------
let b:filter_cmd = 'runghc'

setlocal include=^import\\s*\\%(qualified\\)\\?\\s*
setlocal includeexpr=substitute(v:fname,'\\.','/','g').'.'
setlocal suffixesadd=hs,lhs,hsc

setlocal ai

"===================================================================
" Key Mappings 
"-------------------------------------------------------------------
try
  call mapping#CompleteParen('([{')
  call mapping#MoveTo('[{}\])]')
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry
"===================================================================
" vim: fdm=marker :
