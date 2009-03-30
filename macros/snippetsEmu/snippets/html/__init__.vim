if exists('b:load_html_snippets')
  finish
endif
let b:load_html_snippets = 1

ru syntax/snippet.vim

"=================================================
" Snippets {{{
"-------------------------------------------------
Snippet a <a href="<{}>"><{}></a>
Snippet attr <{}>=<{}>
Snippet < <{p:snippets#html#__init__#CreateTag(@z)}>
Snippet li <li><{}></li>
"}}}
"=================================================
" Functions {{{
"-------------------------------------------------
function! snippets#html#__init__#WrapInTag(text) "{{{
  return '<<{p}>>'.substitute(a:text, '^\s\+\|\s\+$', '', 'g').'</<{p:matchstr(@z, ''\S\+'')}>>'
endfunction
"}}}
function! snippets#html#__init__#CreateTag(text) "{{{
  let tag = a:text
  if tag == ''
    let tag = 'p'
    return '<<{'.tag.'}>><{}></<{'.tag.':matchstr(@z, ''\S\+'')}>>'
  endif

  let isXhtml = &filetype == 'xhtml'
  if match(tag, '^\c\%(br\|hr\)$') != -1
    return '<'.tag.(isXhtml ? ' />' : '>').'<{}>'
  elseif match(tag, '^\c\%(a\)$') != -1
    return '<'.tag.' href="<{}>"<{}>><{}></'.matchstr(tag, '\S\+').'>'
  elseif match(tag, '^\c\%(img\|meta\|link\|input\|base\|area\|col\|frame\|param\)$') != -1
    return '<'.tag.(isXhtml ? ' <{}>/>' : '<{}>>').'<{}>'
  else
    return '<'.tag.'<{}>><{}></'.matchstr(tag, '\S\+').'>'
  endif
endfunction
"}}}
function! snippets#html#__init__#Doctype() "{{{
  let choices = [
        \ ['HTML Strict DTD',
        \   "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\"\n\t\t\"http://www.w3.org/TR/html4/strict.dtd\">"],
        \ ['HTML Transitional DTD',
        \  "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n\t\t\"http://www.w3.org/TR/html4/loose.dtd\">"],
        \ ['Frameset DTD',
        \  "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Frameset//EN\"\n\t\t\"http://www.w3.org/TR/html4/frameset.dtd\">"],
        \ ['XHTML Strict DTD',
        \  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"\n\t\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"],
        \ ['XHTML Transitional DTD',
        \  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n\t\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"],
        \ ['XHTML Frameset DTD',
        \  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Frameset//EN\"\n\t\t\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd\">"]
        \ ]
  return SnippetSelect("Select DOCTYPE: ", choices)
endfunction
"}}}
function! snippets#html#__init__#Attr(attr, value) "{{{
  if a:value == ' '
    return ''
	elseif a:attr == a:value
		if a:attr == 'id' || a:attr == 'class'
			return ''
		endif
  endif
	return printf(' %s="%s"', a:attr, a:value)
endfunction
"}}}
"}}}
"=================================================
" Commands {{{
"-------------------------------------------------
call SnippetSetCommand('<C-T>', 'snippets#html#__init__#WrapInTag', 's')
call SnippetSetCommand('<C-L>', 'snippets#html#__init__#WrapInTag', 'l')
call SnippetSetCommand('<Leader>t', 'snippets#html#__init__#CreateTag', 'ws')
"}}}
"=================================================
" vim: set fdm=marker :
