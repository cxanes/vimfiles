" Change working directory to the directory of current file
nnoremap <silent> <Leader>cd :<C-U>Cwd<CR>
command! -bang -bar Cwd call <SID>Cwd(<q-bang> == '!')
function! s:Cwd(local)  "{{{
    if &ft == 'netrw' && exists('b:netrw_curdir')
      let path = b:netrw_curdir
    else
      let path = expand('%:p:h')
    endif

    let cd = a:local ? 'lcd' : 'cd'
    exec cd path
endfunction
"}}}

command! -bang Q  q<bang>
command! -bang Qa qa<bang>

command! -nargs=* Set  set  <args>
command! -nargs=1 Setf setf <args>

exe 'command! UpdateDoc helptags ' . $MYVIMRUNTIME . '/doc'

command! -complete=buffer -nargs=? Tbuffer tab sb <args>
command! -nargs=? Tball tab sball <args>
command! CountWords %s/\i\+/&/gn<Bar>let @/=''
command! -bang ShowSyntaxName
      \ echo synIDattr(synID(line('.'), col('.'), (<q-bang> != '!' ? 0 : 1)), 'name')

if exists('*synstack')
  command! ShowSyntaxStack
        \ echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endif

command! -nargs=* -complete=file Tedit tabedit <args>

" http://www.tpope.us/cgi-bin/cvsweb/tpope/.vimrc
command! -bar -nargs=* -bang -complete=file Rename 
      \ let v:errmsg = '' |
      \ saveas<bang> <args> |
      \ if v:errmsg == '' |
      \   call delete(expand('#')) |
      \   bw # |
      \ endif

command! -nargs=1 RFC call s:RFC(<q-args>)
function! s:RFC(number) "{{{
  if a:number !~ '^\d\+$'
    echohl ErrorMsg | echo 'RFC: invalid number' | echohl None
    return
  endif
  exec printf('e http://www.ietf.org/rfc/rfc%04d.txt', a:number)
endfunction
"}}}

if exists("*mkdir")
  command! -nargs=1 -bang Mkdir call mkdir(<q-args>, <q-bang> == '!' ? 'p' : '')
endif

command -nargs=? -complete=file OpenProject call Project#Open(<q-args>)
command -nargs=? -complete=file ProjectOpen call Project#Open(<q-args>)

if g:MSWIN
  command! Cmd silent !start
endif

" Tools
for s:script in [
      \          'Ar30', 'ImageBrowser', 'JpPronunciation',
      \          'AutoCorrect', 'ropevim',
      \          'FlyMake',
      \          'codeintel', 'vstplugin', 'Dict',
      \          'Project', 'imaps', 'SourceNavigator',
      \          'KillRing', 'Stickies'
      \ ]
  if globpath(&rtp, printf('macros/%s.vim', s:script)) != ''
    exec printf('command! Load%s ru macros/%s.vim', substitute(s:script, '^.', '\u&', ''), s:script)
  endif
endfor
unlet! s:script

" Don't close window, when deleting a buffer
" Ref: http://www.amix.dk/vim/vimrc.html
command! -bang Bclose call <SID>BufcloseCloseIt(<q-bang> == '!')
command! -bang Bd call <SID>BufcloseCloseIt(<q-bang> == '!')
function! <SID>BufcloseCloseIt(...) " ... = wipeout {{{
  let currentBufNum = bufnr('%')
  let alternateBufNum = bufnr('#')

  if buflisted(alternateBufNum)
    buffer #
  else
    bnext
  endif

  if bufnr('%') == currentBufNum
    new
  endif

  if buflisted(currentBufNum)
    if a:0 > 0 && !empty(a:1)
      exe 'bwipeout! ' . currentBufNum
    else
      exe 'bdelete!  ' . currentBufNum
    endif
  endif
endfunction
"}}}

" Clean unused buffers
command! CleanUnusedBuffers call <SID>CleanUnusedBuffers()
function! s:CleanUnusedBuffers() "{{{
  let output = ''
  redir => output
  silent buffers!
  redir END
  for buf in split(output, '\n')
    let m = matchlist(buf, '^\s*\(\d\+\)[u ][%# ][h ]')
    if empty(m)
      continue
    endif
    let bufnr = m[1] + 0
    if getbufvar(bufnr, '&bt') ==? 'help'
          \ || match(buf, '\s\s"\[No Name\]"') != -1
      exe bufnr . 'bw!'
    endif
  endfor
endfunction
"}}}

" vim: fdm=marker : ts=2 : sw=2 :
