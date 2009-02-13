" IndentForComment.vim
" Last Modified: 2008-03-14 11:07:46
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_IndentForComment_plugin')
  finish
endif
let loaded_IndentForComment_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"============================================================
function! IndentForComment#IndentForCommentMapping(comment_list, comment_column, ...) "{{{
  let default_keys      = ['<Leader>ic', '<M-;>']
  let default_kill_keys = ['<Leader>kc', '<M-u><M-;>']

  if a:0 > 0
    if type(a:1) == 1 && !empty(a:1)
      let keys = [a:1]
    elseif type(a:1) == 3
      let keys = a:1
    else
      let keys = default_keys
    endif
  else
    let keys = default_keys
  endif

  if a:0 > 1
    if type(a:2) == 1 && !empty(a:2)
      let kill_keys = [a:2]
    elseif type(a:2) == 3
      let kill_keys = a:2
    else
      let kill_keys = default_kill_keys
    endif
  else
    let kill_keys = default_kill_keys
  endif

  let b:comment_list = a:comment_list
  let b:comment_column = a:comment_column
  let nmap = 'nnoremap <silent> <buffer> %s '
        \ . ':<C-U>call IndentForComment#IndentForComment(''n'', %d, b:comment_list, b:comment_column)<CR>'
  let imap = 'inoremap <silent> <buffer> %s '
        \ . '<C-\><C-O>:call IndentForComment#IndentForComment(''i'', %d, b:comment_list, b:comment_column)<CR>'
  for key in keys
    if empty(key)
      continue
    endif
    exe printf(nmap, key, 0)
    exe printf(imap, key, 0)
  endfor

  for kill_key in kill_keys
    if empty(kill_key)
      continue
    endif
    exe printf(nmap, kill_key, 1)
    exe printf(imap, kill_key, 1)
  endfor
endfunction
" }}}
function! IndentForComment#IndentForComment(mode, kill, comment_list, column) "{{{
  let comment_list = s:GetCommentList(a:comment_list)
  if empty(comment_list)
    return
  endif
  let col = getpos('.')[2]
  let [pos, comment] = s:HasComment(comment_list)
  if empty(comment) && a:kill
    if a:mode == 'i'
      exe 'startinsert' . (col == col('$') ? '!' : '')
    endif
    return
  elseif !empty(comment)
    if a:kill
      call s:KillComment(pos, comment)
      if a:mode == 'i'
        exe 'startinsert' . (col == col('$') ? '!' : '')
      endif
    else
      let pos = s:IndentComment(pos, a:column)
      call s:GoToComment(pos, comment, a:mode)
    endif
    return
  endif
  let [pos, comment] = s:CreateComment(comment_list, a:column)
  call s:GoToComment(pos, comment, a:mode)
endfunction
" }}}
"============================================================
function! s:GetCommentList(comment_list) "{{{
  if type(a:comment_list) == 1
    return [[a:comment_list, '']]
  elseif type(a:comment_list) != 3
    return []
  endif

  let comment_list = []
  for i in range(len(a:comment_list))
    let comment = a:comment_list[i]
    if type(comment) == 1
      call add(comment_list, [comment, ''])
    elseif type(comment) == 3 && len(comment) > 1
          \ && type(comment[0]) == 1 && !empty(comment[0])
          \ && type(comment[1]) == 1
      call add(comment_list, comment[0 : 1])
    endif
    unlet comment
  endfor
  return comment_list
endfunction
" }}}
function! s:HasComment(comment_list) "{{{
  let save_cursor = getpos('.')
  for comment in a:comment_list
    call cursor(line('.'), 1)
    let [lnum, col] = searchpos(LiteralPattern(comment[0]), 'n', line('.'))
    while [lnum, col] != [0, 0]
      if synIDattr(synIDtrans(synID(lnum, col, 1)), 'name') == 'Comment'
        call setpos('.', save_cursor)
        return [[lnum, col], comment]
      else
        call cursor(lnum, col)
        let [lnum, col] = searchpos(LiteralPattern(comment[0]), 'n', line('.'))
      endif
    endwhile
  endfor
  call setpos('.', save_cursor)
  return [[], []]
endfunction
" }}}
function! s:DeleteTrailingWhitespace(...) "{{{
  let range = a:0 > 0 ? a:1 : '.'
  let s_sav = @/
  exe range . 's/\s\+$//e'
  let @/ = s_sav
endfunction
" }}}
function! s:KillComment(pos, comment) "{{{
  let save_cursor = getpos('.')
  call call('cursor', a:pos)
  if empty(a:comment[1])
    silent normal! "_D
  else
    let s_sav = @/
    exe 'silent normal! "_d/' . escape(LiteralPattern(a:comment[1]), '/') . "/e\<CR>"
    let @/ = s_sav
  endif
  call s:DeleteTrailingWhitespace()
  call setpos('.', save_cursor)
endfunction
" }}}
function! s:GetWhitespace(begin_col, end_col) "{{{
  if a:begin_col >= a:end_col
    return ''
  endif

  if &expandtab
    return repeat(' ', a:end_col - a:begin_col - 1)
  else
    let begin_col = a:begin_col / &tabstop * &tabstop
    let length = a:end_col - begin_col - 1
    return repeat("\t", length / &tabstop) . repeat(' ', length % &tabstop)
endfunction
" }}}
function! s:GetCommentColumn(str_col, cmt_col) "{{{
  let comment_list = []
  if type(a:cmt_col) == 0 && a:cmt_col > 0
    let comment_list = [a:cmt_col]
  elseif type(a:cmt_col) == 1 && a:cmt_col + 0 > 0
    let comment_list = [a:cmt_col+0]
  elseif type(a:cmt_col) != 3
    let comment_list = [1]
  endif

  let comment_list = a:cmt_col
  call sort(comment_list)
  for column in comment_list
    if a:str_col <= column
      return column
    endif
  endfor
  redraw
  return a:str_col + 2
endfunction
" }}}
function! s:IndentComment(pos, column) "{{{
  let pos = a:pos
  let save_cursor = getpos('.')
  call call('cursor', a:pos)
  let str_end_col = virtcol(searchpos('\S', 'bn', line('.')))
  let cmt_beg_col = virtcol(a:pos)
  let column = s:GetCommentColumn(str_end_col, a:column)
  if cmt_beg_col != column
    let a_sav = @a 
    silent normal! "aD
    let comment_line = @a
    let @a = a_sav

    call s:DeleteTrailingWhitespace()
    let space = s:GetWhitespace(str_end_col, column)
    call setline(line('.'), getline('.') . space)
    let pos = [line('.'), col('$')]
    call setline(line('.'), getline('.') . comment_line)
  endif
  call setpos('.', save_cursor)
  return pos
endfunction
" }}}
function! s:CreateComment(comments, column) "{{{
  if empty(a:comments)
    return
  endif
  let comment = a:comments[0]
  let comment_line = join(comment, !empty(comment[1]) ? '  ' : ' ')
  call s:DeleteTrailingWhitespace()
  let str_end_col = virtcol('$') - 1
  let column = s:GetCommentColumn(str_end_col, a:column)
  let space = s:GetWhitespace(str_end_col, column)
  call setline(line('.'), getline('.') . space . comment_line)
  return [[line('.'), column], comment]
endfunction
" }}}
function! s:GoToComment(pos, comment, mode) "{{{
  call call('cursor', a:pos)
  let cmt_col = searchpos(LiteralPattern(a:comment[0]), 'ne', line('.'))[1]
  call search(LiteralPattern(a:comment[0]) . '\s*\S\?', 'e', line('.'))
  if !empty(a:comment[1]) 
        \ && getline('.')[col('.')-1 : -1] =~ '^' .LiteralPattern(a:comment[1])
        \ && cmt_col + 1 < col('.')
      exe 'normal! ' . (col('.') - cmt_col)/2 . 'h'
  endif
  if a:mode == 'i'
    if col('.') + 1 == col('$')
      startinsert!
    else
      startinsert
    endif
  endif
endfunction
" }}}
"==========================================================}}}1
"============================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
