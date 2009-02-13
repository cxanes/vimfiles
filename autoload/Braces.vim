" Braces.vim
" Last Modified: 2008-09-10 09:27:28
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_Braces')
  finish
endif
let loaded_autoload_Braces = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"================================================
function! Braces#Expand(text) "{{{
  return s:ExpandBrace(a:text)
endfunction
"}}}
"================================================
function! s:ExpandSeq(v1, v2) "{{{
  if a:v1 =~ '-\?\d\+'
    let [v1, v2] = [str2nr(a:v1), str2nr(a:v2)]
    let seq = range(v1, v2, (v1 > v2 ? -1 : 1))
    call map(seq, "v:val . ''")
  else
    let [v1, v2] = [char2nr(a:v1), char2nr(a:v2)]
    let seq = range(v1, v2, (v1 > v2 ? -1 : 1))
    call map(seq, 'nr2char(v:val)')
  endif
  return seq
endfunction
"}}}
function! s:Strlen(str) "{{{
  return strlen(substitute(a:str, '.', '.', 'g'))
endfunction
"}}}
function! s:BraceGobbler(text) "{{{
  let text = a:text
  let level = 1
  let pos = 0

  let span = matchend(text, '^\%(\%(\\.\|[^{}\\]\+\)\+\|[{}]\)')
  while span != -1
    let token = strpart(text, 0, span)
    let text  = strpart(text, span)
    let pos += span

    if token == '{'
      let level += 1
    elseif token == '}'
      let level -= 1
      if level == 0
        return pos
      endif
    endif

    let span = matchend(text, '^\%(\%(\\.\|[^{}\\]\+\)\+\|[{}]\)')
  endwhile

  return -1
endfunction
"}}}
function! s:ExpanseInnerBrace(text) "{{{
  let text = a:text

  " Sequence expression
  let seq = matchlist(text, '^\(-\?\d\+\)\.\.\(-\?\d\+\)$')
  if empty(seq)
    let seq = matchlist(text, '^\([a-zA-Z]\)\.\.\([a-zA-Z]\)$')
  endif

  if !empty(seq)
    return s:ExpandSeq(seq[1], seq[2])
  endif

  let expanses = []
  let item = ''
  let commas = 0

  let span = matchend(text, '^\%(\%(\\.\|[^,{}\\]\+\)\+\|[,{}]\)')
  while span != -1
    let token = strpart(text, 0, span)
    let text  = strpart(text, span)
    if token == '{'
      let item .= token
      let brace_end = s:BraceGobbler(text)
      if brace_end != -1
        let item .= strpart(text, 0, brace_end)
        let text = strpart(text, brace_end)
      endif
    elseif token == ','
      let commas += 1
      call extend(expanses, s:ExpandBrace(item))
      let item = ''
    else
      let item .= token
    endif

    let span = matchend(text, '^\%(\%(\\.\|[^,{}\\]\+\)\+\|[,{}]\)')
  endwhile

  if commas == 0
    return map(s:ExpandBrace(item), "'{' . v:val . '}'")
  else
    call extend(expanses, s:ExpandBrace(item))
    return expanses
  endif
endfunction
"}}}
function! s:ExpandBrace(text) "{{{
  let text = a:text
  let preamble = ''

  let span = matchend(text, '^\%(\\.\|[^{\\]\+\)*{')
  if span == -1
    return [substitute(text, '\\\(.\)', '\1', 'g')]
  endif

  while span != -1
    let brace_end = s:BraceGobbler(strpart(text, span))
    if brace_end == -1
      let preamble .= substitute(strpart(text, 0, span), '\\\(.\)', '\1', 'g')
      let text = strpart(text, span)
      let span = matchend(text, '^\%(\\.\|[^{\\]\+\)*{')
    else
      let preamble .= substitute(strpart(text, 0, span-1), '\\\(.\)', '\1', 'g')
      let postamble = strpart(text, span + brace_end)

      let total_expanses = []
      let expanses = brace_end < 2 ? ['{}'] : s:ExpanseInnerBrace(strpart(text, span, brace_end - 1))
      for i in range(len(expanses))
        for more_expanses in s:ExpandBrace(postamble)
          call add(total_expanses, (preamble . expanses[i] . more_expanses))
        endfor
      endfor
      return total_expanses
    endif
  endwhile

  return [preamble]
endfunction
"}}}
"================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
