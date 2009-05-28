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

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[{}\])>]')
endif

if exists('*mylib#CNewLine')
  inoremap <silent> <buffer> <C-J> <C-R>=mylib#CNewLine()<CR>
endif
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

if !exists('*s:CompleteBrace') && exists('*myutils#CompleteParen')
  function! s:CompleteBrace() "{{{
    let line = getline('.')[ : (col('.')-(col('$') == col('.') ? 1 : 2)) ]
    
    if line =~ '^%{$'
      return "\<CR>0\<C-D>\<CR>0\<C-D>%}\<Up>\<Home>"
    else
      return myutils#CompleteParen('{')
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
