" java configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
compiler javac

try
  call mylib#AddOptFiles('dict', 'keywords/java')
  set complete+=k
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

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

try
  call mapping#CompleteParen('([{')
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[{}\])]')
endif

if exists('*mapping#Enter')
  call mapping#Enter('{', '}')
endif

try
  call IndentForComment#IndentForCommentMapping(['//', ['/*', '*/']], [30, 45, 60])
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry
" }}}
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
" }}}
"===================================================================
" vim: fdm=marker :
