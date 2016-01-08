if exists('b:load_ruby_snippets') | finish | endif
let b:load_ruby_snippets = 1
ru syntax/snippet.vim

"=================================================
" Functions {{{
"-------------------------------------------------
function! snippets#ruby#__init__#ArgList(vars, default, ...) "{{{
  let vars = substitute(a:vars, '^\s\+\|\s\+$', '', 'g')
  if vars == '' || vars == a:default
    return ''
  else
    return printf('%s|%s|', (a:0 > 0 ? a:1 : ''), vars)
  endif
endfunction
"}}}
"}}}
"=================================================
" vim: set fdm=marker :
