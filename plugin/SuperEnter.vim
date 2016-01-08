" Trigger different operations when press <C-CR> key in insert mode
" Last Change: 2007-12-20 02:06:24
"      Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('super_enter_plugin')
  finish
endif
let super_enter_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Key Mappings {{{
if !hasmapto('<Plug>SuperEnter')
  nmap <silent> <Leader>o i<Plug>SuperEnter

  imap <silent> <Leader>o <Plug>SuperEnter
  imap <silent> <unique> <C-CR> <Plug>SuperEnter
endif
inoremap <silent> <unique> <expr> <script> <Plug>SuperEnter <SID>SuperEnter()
" }}}
" SuperEnter() {{{
function! <SID>SuperEnter()
  if &ft !~ '^\s*$'
    let [valid, key] = s:Call('s:Super_' . &ft . '_Enter')
    if valid
      return key
    endif
  endif

  let [valid, key] = s:Call('s:Super__Enter')
  if valid
    return key
  endif

  return "\<CR>"
endfunction
" }}}
" Call() {{{
function! s:Call(func)
  if !exists('*' . a:func)
    return [0, '']
  endif
  let ret = call(a:func, [])
  if type(ret) != 3 || len(ret) != 2
    return [0, '']
  endif
  return ret
endfunction
" }}}
" NewLineAndIndent() {{{
function! s:NewLineAndIndent(line)
  return "\<C-O>o" . a:line . "\<C-O>==\<C-O>A"
endfunction
" }}}
" NewLine() {{{
function! s:NewLine(line)
  return "\<C-O>o0\<C-D>" . a:line
endfunction
" }}}
"======================================================
" global {{{
function! s:Super__Enter()
  let lnum = prevnonblank(line('.'))
  while lnum > 0
    let line = getline(lnum)
    " Numbering
    let nr = matchlist(line, '^\(\s*\)\(\D\?\)\(\d\+\)\(\D\?\)\(\s*\)\(.\?\)')
    "              sample:              [       1       ]              a
    "      sub-expression:      \1     \2      \3      \4      \5     \6
    if !empty(nr)
      if (nr[2] == '' && (nr[4] == '.' && (len(nr[5]) > 0 || nr[6] !~ '\d')))
            \ || (nr[2] == '[' && nr[4] == ']')
            \ || (nr[2] == '(' && nr[4] == ')')
        let nr[3] = printf('%0' . strlen(nr[3]) . 'd', nr[3] + 1)
        " return [1, s:NewLineAndIndent(join(nr[2:5], ''))]
        return [1, s:NewLine(join(nr[1:5], ''))]
      endif
    endif

    " Bullet list
    let nr = matchlist(line, '^\(\s*\)\([-+*]\+\)\(.\?\)')
    "              sample:               +        
    "      sub-expression:      \1     \2         \3 
    if !empty(nr) && nr[3] =~ '^\s*$'
      return [1, s:NewLine(join(nr[1:3], ''))]
    endif

    if line =~ '^\S'
      break
    endif

    let lnum = prevnonblank(lnum - 1)
  endwhile
endfunction
"}}}
"==========================================================}}}1
" rst {{{
function! s:Super_rst_Enter()
  " Quoted literal blocks  or Line Blocks
  let char = '[!\"#$%&''()*+,\-./:;<=>?@[\\\]^_`{|}~]'
  let nr = matchlist(getline('.'), '^\(\s*\)\(' . char . '\)\(\s*\)')
  "              sample:                      |        
  "      sub-expression:             \1     \2              \3 
  if !empty(nr)
    return [1, s:NewLine(join(nr[1:3], ''))]
  endif
endfunction
" }}}
" html {{{
function! s:Super_html_Enter()
  let lnum = line('.')

  if searchpair('<', '', '>', 'cnW') > 0
    call search('<', 'cbW')
    if getline('.')[col('.')] != '/'
      call search('>', 'cW')
    endif
  endif

  let tags = {}
  let [type, tag] = s:HtmlNextTag()

  if type == 0
    return
  endif

  for t in ['html', 'body', 'head']
    if tag ==? t
      return
    endif
  endfor

  let tags[tag] = 0

  while type != 0
    if !has_key(tags, tag)
      let tags[tag] = 0
    endif

    if type == 1
      let tags[tag] += 1
    else
      let tags[tag] -= 1
    endif

    if tags[tag] < 0
      break
    endif

    let [type, tag] = s:HtmlNextTag()
  endwhile

  if type == 2 && tags[tag] < 0
    return [1, repeat("\<Down>", line('.') - lnum)
          \    . s:NewLineAndIndent('<' . tag . '></' . tag . '>')
          \    . repeat("\<Left>", strlen(tag) + 3)]
  endif

  return
endfunction

function! s:HtmlNextTag()
  if search('<\w\+[^>]*>\|</\w\+>', 'cW') == 0
    return [0, '']
  endif
  let line = getline('.')[col('.') - 1 : ]
  call search('>', 'W')
  let tag = matchlist(line, '^<\(/\?\)\(\w\+\)')
  if !empty(tag)
    return [(tag[1] != '/' ? 1 : 2), tag[2]]
  endif

  return [0, '']
endfunction
" }}}
" tex {{{
function! s:Super_tex_Enter()
  " Insert Item
  if exists('*Tex_InsertItem')
    let env = Tex_GetCurrentEnv()
    if env =~ '^\%(itemize\|enumerate\|theindex\|thebibliography\|description\)\>'
      let move_down = ''
      let elnum = search('\\end{\V'.escape(env, '\').'}', 'nW')
      if elnum > 0
        let lnum = line('.') + 1
        while lnum < elnum
          if getline(lnum) =~ '^[^%]*\\item'
            break
          endif
          let lnum += 1
        endwhile
        let move_down = repeat("\<Down>", lnum - line('.') - 1)
      endif
      return [1, move_down . "\<C-O>o\<C-R>=Tex_InsertItem()\<CR>"]
    endif
  endif
endfunction
" }}}
"======================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
