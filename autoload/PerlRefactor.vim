" PerlRefactor.vim
" Last Modified: 2009-03-19 22:14:23
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_PerlRefactor')
  finish
endif
let loaded_autoload_PerlRefactor = 1

let s:refactorprg = 'pl-refactor'
if !executable(s:refactorprg)
  finish
endif
let s:save_cpo = &cpo
set cpo&vim
"}}}
function! PerlRefactor#ExtractSubroutine(subName, codeSnippet) 
  let delimter = '<CODE_CALL>'  " from EPIC
  let cmd = printf('%s "%s" "%s"', s:refactorprg, a:subName, delimter)
  let result = split(system(cmd, a:codeSnippet), delimter)
  if len(result) < 2
    return ['', '']
  endif

  return [result[0], join(result[1:], delimter)] 
endfunction
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
