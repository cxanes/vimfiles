" MetaPost configuration file
"===================================================================
" Settings {{{
"------------------------------------------------------------
set foldmethod=expr
set foldexpr=getline(v:lnum)=~'^\\s*beginfig(\\d\\+)\\s*;\\?'?'a1':getline(v:lnum)=~'^\\s*endfig\\s*;\\?'?'s1':'='
" }}}
"===================================================================
" Keymappings and Commands {{{
"------------------------------------------------------------
if executable('mpost') && executable('tex2img')
  command! -buffer MpPreviewFig call s:PreviewFig()
endif
" }}}
"===================================================================
" Functions {{{
"------------------------------------------------------------
if (!exists('s:PreviewFig')) && executable('mpost') && executable('tex2img')
function! s:PreviewFig() "{{{2
  let [l:start, l:middle, l:end]  = ['\<beginfig(\s*\d\+\s*)\s*;\?', '', '\<endfig\>\s*;\?']
  let [slnum, scol] = searchpairpos(l:start, l:middle, l:end, 'bnW')
  if [slnum, scol] == [0, 0]
    echohl ErrorMsg | echo 'Cannot find Figure' | echohl None
    return
  endif

  let [elnum, ecol] = searchpairpos(l:start, l:middle, l:end, 'nW')
  if [elnum, ecol] == [0, 0]
    echohl ErrorMsg | echo 'Cannot find Figure' | echohl None
    return
  endif

  call cursor(elnum, ecol)
  let [elnum, ecol] = searchpos(l:end, 'neW')

  let move_down  = elnum - slnum
  let move_right = ecol - (&sel == 'inclusive' ? 1 : 0)
  call cursor(slnum, scol)
  let cmd = 'silent normal! v0' . (move_down <= 0 ? '' : (move_down.'j')) 
        \ . (move_right <= 0 ? '' : (move_right.'l'))

  let s_sav = @s
  exec cmd . '"sy'
  let code = @s
  let @s = s_sav

  let lines = join(getline(1, '$'), "\n")
  let lines = substitute(lines, '\<filenametemplate\s\+"[^"]\+"\s*;', '', 'g')
  let lines = substitute(lines, (l:start . '\_.\{-}' . l:end), '', 'g')

  let code  = substitute(code, l:start, 'beginfig(1);', '')
  let code  = lines . code

  let mp_file = tempname()
  exec 'redir! > ' . mp_file
  silent! echo code
  redir END

  if exists('*GetPos')
    let pos = GetPos()
  else
    let pos = { 'x': getwinposy(), 'y': getwinposy() }
  endif

  let wd = getcwd()
  let mp_dir = substitute(mp_file, '[\\/][^\\/]\+$', '', '')
  exec 'cd! ' . mp_dir
  let mp_file = matchstr(mp_file, '[^\\/]\+$')
  let ssl_set = 0
  if &ssl && (has('win16') || has('win32') || has('win64') || has('win95'))
    let ssl_set = 1
    set nossl
  endif
  let err_msg = system('mpost -interaction=batchmode ' . shellescape(mp_file))
  let tmp_file = substitute(mp_file, '\.[^.]\+$', '', '')
  let mp_file =  tmp_file . '.1'
  for ext in ['tmp', 'mpx', 'log']
    call delete(tmp_file . '.' . ext)
  endfor
  if !filereadable(mp_file)
    cd! -
    echohl ErrorMsg
    " echom 'Error: mpost'
    echom err_msg
    echohl None
    return
  endif
  let err_msg = system(printf('tex2img -c2 -l "%d+%d" -t %s -m "%s"', 
        \ pos.x, pos.y, shellescape('\includegraphics{' . mp_file . '}'),
        \ '+adjoin +antialias -density 100x100 -background white -flatten'))
  if ssl_set == 1
    set ssl
  endif
  if v:shell_error
    echohl ErrorMsg
    " echom 'Error: tex2img'
    echom err_msg
    echohl None
  endif
  for ext in ['1']
    call delete(tmp_file . '.' . ext)
  endfor
  cd! -
endfunction
endif
" }}}2
" }}}
"===================================================================
" vim: fdm=marker :
