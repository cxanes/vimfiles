if exists('b:load_demo_snippets')
  finish
endif
let b:load_demo_snippets = 1

ru syntax/snippet.vim

" DEMO 1
function! snippets#demo#__init__#WrapInTag(text)
  return '<<{p}>>'.substitute(a:text, '^\s\+\|\s\+$', '', 'g').'</<{p:matchstr(@z, ''\S\+'')}>>'
endfunction

call SnippetSetCommand('<C-T>', 'snippets#demo#__init__#WrapInTag', 's')

