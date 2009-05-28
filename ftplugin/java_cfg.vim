" java configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
compiler javac

if exists('*mylib#AddOptFiles')
  call mylib#AddOptFiles('dict', 'keywords/java')
  set complete+=k
endif

" For function Run() <in plugin/myutils.vim>
function! RunCommandJava() 
  return ['java', '-classpath', expand('%:p:h'), expand('%:p:t:r')]
endfunction

" Avoid E705: Variable name conflicts with existing function.
unlet! b:run_command_java
let b:run_command_java = function('RunCommandJava')
" }}}
"===================================================================
" Commands {{{
"-------------------------------------------------------------------
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
inoremap <silent> <buffer> <Leader>k <C-X><C-K>

if exists('*mylib#CNewLine')
  inoremap <silent> <buffer> <C-J> <C-R>=mylib#CNewLine()<CR>
endif

if exists('*mapping#CompleteParen')
  call mapping#CompleteParen('([{')
endif

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[{}\])]')
endif

if exists('*mapping#Enter')
  call mapping#Enter('{', '}')
endif

if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping(['//', ['/*', '*/']], [30, 45, 60])
endif
" }}}
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
" }}}
"===================================================================
" vim: fdm=marker :
