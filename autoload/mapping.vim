" mapping.vim
" Last Modified: 2009-05-28 23:57:54
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_mapping')
  finish
endif
let loaded_autoload_mapping = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"==============================================================
function! mapping#MoveTo(pat, ...) "{{{
  let default_key = '<C-L>'
  let key = a:0 > 0 && a:1 != '' ? a:1 : default_key

  let modes = a:0 > 1 && a:2 != '' ? a:2 : 'i'
  let q_pat = "'" . substitute(a:pat, "'", "''", 'g') . "'"

  let pat = substitute(a:pat, '<', '<lt>', 'g')
  if stridx(modes, 'i') != -1
    exe 'inoremap <silent> <buffer>' key
          \ "<C-\\><C-N>:call search(" . q_pat . ", 'e')<CR>a"
  endif

  if stridx(modes, 'n') != -1
    exe 'nnoremap <silent> <buffer>' key
          \ ":call search(" . q_pat . ", 'e')<CR>"
  endif

  if stridx(modes, 'v') != -1
    exe 'vnoremap <silent> <buffer>' key
          \ "m':<C-U>exe \"normal! gv\"<Bar>:call search(" . q_pat . ", 'e')<CR>l"
  endif
endfunction
"}}}
" mapping#Enter() {{{
" e.g. call mapping#Enter('{', '}')
"
" In C filetype
"
"     {|} 
"
" press <CR> (| is the position of the cursor)
"
"     {
"       |
"     }
"
function! mapping#Enter(head, tail) "{{{
  exe 'inoremap <silent> <buffer> <CR>'
        \ . ' <C-R>=(col(".") != 1 && strpart(getline("."), col(".")-2, 2) == '''
        \ . a:head . '''.''' . a:tail . ''') ? "\<lt>CR>\<lt>ESC>ko" : "\<lt>CR>"<CR>'
  inoremap <silent> <buffer> <Leader><CR> <CR>
endfunction
"}}}
"}}}
" {{{ Complete parenthesis ([{}])
"
" e.g. ( => ()
function! mapping#CompleteParen(plist, ...) "{{{
  let b:CompleteParenMapEscapePat = a:0 == 0 ? '\w' : a:1
  if !exists('g:AutoPairsLoaded')
    let plist = substitute(a:plist, '[^[:punct:]]\+', '', 'g')
    for ch in split(plist, '\zs')
      exe printf('inoremap <silent> <buffer> <Leader>%s %s', ch, ch)
      exe printf('inoremap <silent> <buffer> %s %s<C-R>=myutils#CompleteParen(''%s'')<CR>'
            \ , ch, ch, substitute(ch, "'", "''", 'g'))
    endfor
  endif
endfunction
"}}}
"}}}
"==============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
