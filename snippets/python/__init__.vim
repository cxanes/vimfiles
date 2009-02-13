if exists('b:load_python_snippets')
  finish
endif
let b:load_python_snippets = 1

ru syntax/snippet.vim

let s:st = g:snip_start_tag
let s:et = g:snip_end_tag

"=================================================
" Functions {{{
"-------------------------------------------------
" Given a string containing a list of arguments (e.g. "one, two = 'test'"),
" this function cleans it up by removing useless whitespace and commas.
function! snippets#python#__init__#CleanupArgs(text) "{{{
    if a:text == 'args'
        return ''
    endif
    let text = substitute(a:text, '\(\w\)\s\(\w\)', '\1,\2', 'g')
    return join(split(text, '\s*,\s*'), ', ')
endfunction
"}}}
" Given a string containing a list of arguments (e.g. "one = 'test', *args,
" **kwargs"), this function returns a string containing only the variable
" names, separated by spaces, e.g. "one two".
function! snippets#python#__init__#GetVarnamesFromArgs(text) "{{{
    let text = substitute(a:text, 'self,*\s*', '',  '')
    let text = substitute(text, '\*\*\?\k\+', '',  'g')
    let text = substitute(text,   '=.\{-},',    '',  'g')
    let text = substitute(text,   '=.\{-}$',    '',  'g')
    let text = substitute(text,   '\s*,\s*',    ' ', 'g')
    if text == ' '
        return ''
    endif
    return text
endfunction
"}}}
" Returns the current indent as a string.
function! snippets#python#__init__#GetIndentString() "{{{
    if &expandtab
        let tabs   = indent('.') / &shiftwidth
        let tabstr = repeat(' ', &shiftwidth)
    else
        let tabs   = indent('.') / &tabstop
        let tabstr = '<Tab>'
    endif
    return repeat(tabstr, tabs)
endfunction
"}}}
" Given a string containing a list of arguments (e.g. "one = 'test', *args,
" **kwargs"), this function returns them formatted correctly for the
" docstring.
function! snippets#python#__init__#GetDocstringFromArgs(text) "{{{
    let text = snippets#python#__init__#GetVarnamesFromArgs(a:text)
    if a:text == 'args' || text == ''
        return ''
    endif
    let indent  = snippets#python#__init__#GetIndentString()
    let st      = g:snip_start_tag
    let et      = g:snip_end_tag
    let docvars = map(split(text), 'v:val." -- ".st.et')
    return '<CR>'.indent.join(docvars, '<CR>'.indent).'<CR>'.indent
endfunction
"}}}
" Given a string containing a list of arguments (e.g. "one = 'test', *args,
" **kwargs"), this function returns them formatted as a variable assignment in
" the form "self._ONE = ONE", as used in class constructors.
function! snippets#python#__init__#GetVariableInitializationFromVars(text) "{{{
    let text = snippets#python#__init__#GetVarnamesFromArgs(a:text)
    if a:text == 'args' || text == ''
        return ''
    endif
    let st = g:snip_start_tag
    let et = g:snip_end_tag
    let indent = snippets#python#__init__#GetIndentString()
    " let assert_vars = map(split(text), '"assert ".v:val." ".st.et')
    let assign_vars = map(split(text), '"self._".v:val." = ".v:val')
    " let assertions  = join(assert_vars, '<CR>'.indent)
    let assignments = join(assign_vars, '<CR>'.indent)
    " return assertions.'<CR>'.indent.assignments.'<CR>'.indent
    return assignments.'<CR>'.indent.st.et
endfunction
"}}}
" Given a string containing a list of arguments (e.g. "one = 'test', *args,
" **kwargs"), this function returns them with the default arguments removed.
function! snippets#python#__init__#StripDefaultValue(text) "{{{
    return substitute(a:text, '=.*', '', 'g')
endfunction
"}}}
" Returns the number of occurences of needle in haystack.
function! Count(haystack, needle) "{{{
    let counter = 0
    let index = match(a:haystack, a:needle)
    while index > -1
        let counter = counter + 1
        let index = match(a:haystack, a:needle, index+1)
    endwhile
    return counter
endfunction
"}}}
" Returns replacement if the given subject matches the given match.
" Returns the subject otherwise.
function! snippets#python#__init__#Replace(subject, match, replacement) "{{{
    if a:subject == a:match
        return a:replacement
    endif
    return a:subject
endfunction
"}}}
" Returns the % operator with a tuple containing n elements appended, where n
" is the given number.
function! snippets#python#__init__#HashArgList(count) "{{{
    if a:count == 0
        return ''
    endif
    let st = g:snip_start_tag
    let et = g:snip_end_tag
    return ' % ('.st.et.repeat(', '.st.et, a:count - 1).')'
endfunction
"}}}
"}}}
"=================================================
" Snippets {{{
"
" Note to users: The following method of defininf snippets is to allow for
" changes to the default tags.
" Feel free to define your own as so:
"    Snippet mysnip This is the expansion text.<{}>
" There is no need to use exec if you are happy to hardcode your own start and
" end tags
"-------------------------------------------------

Snippet . self.
exec "Snippet __ __".s:st."init".s:et.'__'.s:st.s:et

" Properties, setters and getters.
exec "Snippet prop ".s:st."attribute".s:et." = property(get_".s:st."attribute".s:et.", set_".s:st."attribute".s:et.s:st.s:et.")<CR>".s:st.s:et
" exec "Snippet get def get_".s:st."name".s:et."(self):<CR><Tab>return self._".s:st."name".s:et."<CR>".s:st.s:et
" exec "Snippet set def set_".s:st."name".s:et."(self, ".s:st."value".s:et."):
" \<CR><Tab>self._".s:st."name".s:et." = ".s:st."value:snippets#python#__init__#StripDefaultValue(@z)".s:et."
" \<CR>".s:st.s:et

" Functions and methods.
exec "Snippet cm ".s:st."class".s:et." = classmethod(".s:st."class".s:et.")<CR>".s:st.s:et

" Keywords
exec "Snippet im import ".s:st."module".s:et."<CR>".s:st.s:et
exec "Snippet from from ".s:st."module".s:et." import ".s:st.'name:D("*")'.s:et."<CR>".s:st.s:et
exec "Snippet % '".s:st."s".s:et."'".s:st."s:snippets#python#__init__#HashArgList(Count(@z, '%[^%]'))".s:et.s:st.s:et
exec "Snippet ass assert ".s:st."expression".s:et.s:st.s:et
" From Kib2
exec "Snippet bc \"\"\"<CR>".s:st.s:et."<CR>\"\"\"<CR>".s:st.s:et

" Try, except, finally.
exec "Snippet trye try:
\<CR><Tab>".s:st.s:et."
\<CR>except Exception, e:
\<CR><Tab>".s:st.s:et."
\<CR>".s:st.s:et

exec "Snippet tryf try:
\<CR><Tab>".s:st.s:et."
\<CR>finally:
\<CR><Tab>".s:st.s:et."
\<CR>".s:st.s:et

exec "Snippet tryef try:
\<CR><Tab>".s:st.s:et."
\<CR>except Exception, e:
\<CR><Tab>".s:st.s:et."
\<CR>finally:
\<CR><Tab>".s:st.s:et."
\<CR>".s:st.s:et

" Other multi statement templates
" From Panos
exec "Snippet ifn if __name__ == '".s:st."main".s:et."':<CR><Tab>".s:st.s:et
exec "Snippet ifmain if __name__ == '__main__':<CR><Tab>".s:st.s:et

" Shebang
exec "Snippet sb #!/usr/bin/env python<CR># -*- coding: ".s:st."encoding".s:et." -*-<CR>".s:st.s:et
exec "Snippet sbu #!/usr/bin/env python<CR># -*- coding: utf-8 -*-<CR>".s:st.s:et
" From Kib2
exec "Snippet sbl1 #!/usr/bin/env python<CR># -*- coding: Latin-1 -*-<CR>".s:st.s:et

" Unit tests.
exec "Snippet unittest if __name__ == '__main__':
\<CR><Tab>import unittest
\<CR>
\<CR><Tab>class ".s:st."ClassName".s:et."Test(unittest.TestCase):
\<CR><Tab>def setUp(self):
\<CR><Tab><Tab>".s:st."pass".s:et."
\<CR>
\<CR><Tab>def runTest(self):
\<CR><Tab>".s:st.s:et
"}}}
"=================================================

unlet s:st s:et
" vim: set fdm=marker :
