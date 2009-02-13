if exists('b:load_rst_snippets')
  finish
endif
let b:load_rst_snippets = 1

ru syntax/snippet.vim

"=================================================
" Variables {{{
"-------------------------------------------------
let s:SecLevStr = '==-`''.~*+^'
let b:SecLev = 0
"}}}
"=================================================
" Snippets {{{
"-------------------------------------------------
Snippet sec <{title:snippets#rst#__init__#Sec(@z)}>
Snippet secn <{title:snippets#rst#__init__#Sec(@z, SnippetQuery("Section Level? ", b:SecLev))}>
Snippet hr ``'<CR>' . repeat('=', 50) . '<CR><CR><CR>'``
Snippet e *<{}>* <{}>
Snippet b **<{}>** <{}>
Snippet f :<{}>: <{}>
Snippet l ``snippets#rst#__init__#Literal()``
"}}}
"=================================================
" Functions {{{
"-------------------------------------------------
function! snippets#rst#__init__#Literal() "{{{
  return '\`\`<{}>\`\` <{}>'
endfunction
"}}}
function! snippets#rst#__init__#Sec(str, ...) "{{{
  if a:0 > 0
    if type(a:1) == type(0)
      let SecLev = a:1
    elseif type(a:1) == type('') && a:1 =~ '^\d\+$'
      let SecLev = a:1 + 0
    else
      let SecLev = -1
    endif
  else
    let SecLev = -1
  endif
  
  if SecLev >= 0 && SecLev < strlen(s:SecLevStr)
    let b:SecLev = SecLev
  endif

  let strlen = strlen(substitute(a:str, '.', 'x', 'g'))
  let line = repeat(s:SecLevStr[b:SecLev], strlen)
  if b:SecLev == 0
    return line . '<CR>' . a:str . '<CR>' . line . '<CR><CR><{}>'
  else
    return a:str . '<CR>' . line . '<CR><CR><{}>'
  endif
endfunction
"}}}
function! snippets#rst#__init__#WrapEmp(str) "{{{
  return '*' . a:str . '*'
endfunction
"}}}
function! snippets#rst#__init__#WrapBold(str) "{{{
  return '**' . a:str . '**'
endfunction
"}}}
function! snippets#rst#__init__#WrapField(str) "{{{
  return ':' . a:str . ':'
endfunction
"}}}
function! snippets#rst#__init__#WrapLiteral(str) "{{{
  return '\`\`' . a:str . '\`\`'
endfunction
"}}}
"}}}
"=================================================
" Commands {{{
"-------------------------------------------------
call SnippetSetCommand('<Leader>e', 'snippets#rst#__init__#WrapEmp', 's')
call SnippetSetCommand('<Leader>b', 'snippets#rst#__init__#WrapBold', 's')
call SnippetSetCommand('<Leader>f', 'snippets#rst#__init__#WrapField', 's')
call SnippetSetCommand('<Leader>l', 'snippets#rst#__init__#WrapLiteral', 's')
"}}}
"=================================================
" vim: set fdm=marker :
