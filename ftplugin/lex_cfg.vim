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

if exists('*MoveToMap')
  call MoveToMap('[{}\])>]')
endif

if exists('*CNewLine')
  inoremap <silent> <buffer> <C-J> <C-R>=CNewLine()<CR>
endif
" }}}
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
if exists('*CompleteParenMap')
  call CompleteParenMap('([')
endif

if exists('*EnterMap')
  call EnterMap('{', '}')
endif

if !exists('*s:CompleteBrace')
  function! s:CompleteBrace() "{{{
    let line = getline('.')[ : (col('.')-(col('$') == col('.') ? 1 : 2)) ]
    
    if line =~ '^%{$'
      return "\<CR>0\<C-D>\<CR>0\<C-D>%}\<Up>\<Home>"
    else
      return CompleteParen('{')
    endif
  endfunction
  "}}}
endif

if !exists('*s:CompleteAngleBracket')
  function! s:CompleteAngleBracket() "{{{
    let line = getline('.')[ : (col('.')-(col('$') == col('.') ? 1 : 2)) ]
    
    if line =~ '^<$'
      return CompleteParen('<')
    else
      return ''
    endif
  endfunction
  "}}}
endif
" }}}
"===================================================================
" vim: fdm=marker :
