" lex configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
setlocal comments-=:%
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
inoremap <silent> <buffer> { {<C-R>=<SID>CompleteBrace()<CR>
inoremap <silent> <buffer> < <lt><C-R>=<SID>CompleteAngleBracket()<CR>

inoremap <silent> <buffer> <Leader>{  {
inoremap <silent> <buffer> <Leader><  <

try
  call mapping#MoveTo('[{}\])>]')
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

try
  inoremap <silent> <buffer> <C-J> <C-R>=mylib#CNewLine()<CR>
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry
" }}}
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
if exists('*mapping#CompleteParen')
  call mapping#CompleteParen('([')
endif

if exists('*mapping#Enter')
  call mapping#Enter('{', '}')
endif

if !exists('*s:CompleteBrace')
  function! s:CompleteBrace() "{{{
    let line = getline('.')[ : (col('.')-(col('$') == col('.') ? 1 : 2)) ]
    
    if line =~ '^%{$'
      return "\<CR>0\<C-D>\<CR>0\<C-D>%}\<Up>\<Home>"
    else
      try
        return myutils#CompleteParen('{')
      catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
        return ''
      endtry
    endif
  endfunction
  "}}}
endif

if !exists('*s:CompleteAngleBracket')
  function! s:CompleteAngleBracket() "{{{
    let line = getline('.')[ : (col('.')-(col('$') == col('.') ? 1 : 2)) ]
    
    if line =~ '^<$'
      return myutils#CompleteParen('<')
    else
      return ''
    endif
  endfunction
  "}}}
endif
" }}}
"===================================================================
" vim: fdm=marker :
