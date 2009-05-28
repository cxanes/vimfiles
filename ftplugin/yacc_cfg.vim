" yacc configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
setlocal comments-=:%
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
inoremap <silent> <buffer> {     {<C-R>=<SID>CompleteBrace()<CR>
inoremap <silent> <buffer> <     <lt><C-R>=<SID>CompleteAngleBracket()<CR>
inoremap <silent> <buffer> <Bar> <Bar><C-R>=<SID>IndentDelim()<CR>
inoremap <silent> <buffer> ;     ;<C-R>=<SID>IndentDelim()<CR>

inoremap <silent> <buffer> <Leader>{  {
inoremap <silent> <buffer> <Leader><  <
inoremap <silent> <buffer> <Leader><Bar> <Bar>
inoremap <silent> <buffer> <Leader>;  ;

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

if exists('*myutils#CompleteParen')
  if !exists('*s:CompleteBrace')
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
      
      if line =~ '^%\w\+'
        return myutils#CompleteParen('<')
      else
        return ''
      endif
    endfunction
    "}}}
  endif
endif

if !exists('*s:IndentDelim')
  function! s:IndentDelim() "{{{
    if getline('.') !~ '^\s*[:|;]'
      return ''
    endif

    if synIDattr(synID(line('.'), col('.')-1, 0), 'name') == 'yaccDelim'
      let [lnum, col] = searchpos('^[A-Za-z][A-Za-z0-9_]*\_s*:', 'cbnW')
      if lnum == 0
        return ''
      endif

      let indent = matchend(getline(lnum), '^[A-Za-z][A-Za-z0-9_]*\_s*')
      return "\<Home>0\<C-D>" . repeat(' ', indent) . "\<Right>"
    endif

    return ''
  endfunction
  "}}}
endif

" }}}
"===================================================================
" vim: fdm=marker :
