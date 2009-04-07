" Author:  Eric Van Dewoestine
"
" Description: {{{
"   see http://eclim.sourceforge.net/vim/php/complete.html
"
" License:
"
" Copyright (C) 2005 - 2009  Eric Van Dewoestine
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" }}}

" Script Varables {{{
  let s:complete_command =
    \ '-command php_complete -p "<project>" -f "<file>" -o <offset> -e <encoding>'
" }}}

" CodeComplete(findstart, base) {{{
" Handles php code completion.
function! eclim#php#complete#CodeComplete(findstart, base)
  let line = line('.')
  let phpstart = search('<?php', 'bcnW')
  let phpend = search('?>', 'bcnW', line('w0'))
  if phpstart == 0 || (phpend != 0 && line > phpend)
    return eclim#html#complete#CodeComplete(a:findstart, a:base)
  endif

  if a:findstart
    if !eclim#project#util#IsCurrentFileInProject(0) || !filereadable(expand('%'))
      return -1
    endif

    " update the file before vim makes any changes.
    call eclim#util#ExecWithoutAutocmds('silent update')

    " locate the start of the word
    let line = getline('.')

    let start = col('.') - 1

    "exceptions that break the rule
    if line[start] =~ '\.'
      let start -= 1
    endif

    while start > 0 && line[start - 1] =~ '\w'
      let start -= 1
    endwhile

    return start
  else
    if !eclim#project#util#IsCurrentFileInProject(0) || !filereadable(expand('%'))
      return []
    endif

    let offset = eclim#util#GetOffset() + len(a:base)
    let project = eclim#project#util#GetCurrentProjectName()
    let filename = eclim#project#util#GetProjectRelativeFilePath(expand('%:p'))

    let command = s:complete_command
    let command = substitute(command, '<project>', project, '')
    let command = substitute(command, '<file>', filename, '')
    let command = substitute(command, '<offset>', offset, '')
    let command = substitute(command, '<encoding>', eclim#util#GetEncoding(), '')

    let completions = []
    let results = split(eclim#ExecuteEclim(command), '\n')
    if len(results) == 1 && results[0] == '0'
      return
    endif

    " as of eclipse 3.2 it will include the parens on a completion result even
    " if the file already has them.
    let open_paren = getline('.') =~ '\%' . col('.') . 'c\s*('
    let close_paren = getline('.') =~ '\%' . col('.') . 'c\s*(\s*)'

    for result in results
      let word = substitute(result, '\(.\{-}\)|.*', '\1', '')
      let menu = substitute(result, '.\{-}|\(.\{-}\)|.*', '\1', '')
      let info = substitute(result, '.\{-}|.\{-}|\(.\{-}\)', '\1', '')
      let info = eclim#html#util#HtmlToText(info)

      " strip off close paren if necessary.
      if word =~ ')$' && close_paren
        let word = strpart(word, 0, strlen(word) - 1)
      endif

      " strip off open paren if necessary.
      if word =~ '($' && open_paren
        let word = strpart(word, 0, strlen(word) - 1)
      endif

      let dict = {
          \ 'word': word,
          \ 'menu': menu,
          \ 'info': info,
        \ }

      call add(completions, dict)
    endfor

    return completions
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
