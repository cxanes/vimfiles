"--------------------------------------------------------------
" Handle some cygwin filepath (/cygdrive/*,/home/*) in WIN32 version of vim
"
" ATTENTION: Vim sometimes treats WIN32 filepath as '/home/...' 
" (without disk numbers) and it matches the autocmd pattern in 
" autocmd group 'Cygpath'. If you happened to have directory named 
" 'C:/home' or 'C:/cygdrive' (or with other disk number), the 
" following code may open files in that directory using cygpath.
"--------------------------------------------------------------
if g:MSWIN && !has('win32unix') && executable('cygpath.exe')
  function! s:Cygpath(path) "{{{
    if a:path == ''
      return ''
    endif

    if !exists('b:prev_cygpath')
      let b:prev_cygpath = ['', '']
    endif

    if b:prev_cygpath[0] == a:path
      return b:prev_cygpath[1]
    endif
    let l:path = substitute(system('cygpath -m ' . shellescape(a:path)), '\n', '', 'g')
    if v:shell_error == 0
      let b:prev_cygpath = [a:path, l:path]
    else
      let l:path = ''
    endif

    return l:path
  endfunction
  "}}}
  function! s:Getpath() "{{{
    let path = expand('<amatch>')
    if filereadable(path)
      return path
    endif

    return s:Cygpath(expand('<amatch>:s?^[a-zA-Z]:??'))
  endfunction
  "}}}
  function! s:EditFile(path) "{{{
    if isdirectory(a:path)
      silent! call netrw#LocalBrowseCheck(a:path)
    else
      set noswf
      exe 'silent doau BufReadPre ' . a:path
      if filereadable(a:path)
        try
          let ul = &ul
          setl ul=-1
          silent %d _ | exe '1r '. a:path | silent 1d _
        finally
          let &l:ul = ul
        endtry
      endif
      exe 'silent doau BufReadPost ' . a:path
    endif
  endfunction
  "}}}
  augroup Cygpath
    au!
    au BufReadCmd   /cygdrive/*,/home/* call s:EditFile(s:Getpath())

    au FileReadCmd  /cygdrive/*,/home/* 
          \ exe 'silent doau FileReadPre '.s:Getpath() |
          \ exe 'r '.s:Getpath() |
          \ exe 'silent doau FileReadPost '.s:Getpath()

    au BufWriteCmd  /cygdrive/*,/home/* 
          \ exe 'silent doau BufWritePre '.s:Getpath() |
          \ exe 'w! '.s:Getpath() |
          \ set nomod |
          \ exe 'silent doau BufWritePost '.s:Getpath()

    au FileWriteCmd /cygdrive/*,/home/* 
          \ exe 'silent doau FileWritePre '.s:Getpath() |
          \ exe "'[,']w! ".s:Getpath() |
          \ exe 'silent doau FileWritePost '.s:Getpath()

  augroup END
endif
"--------------------------------------------------------------
" Use :Man in Vim (use ManPageView <http://www.vim.org/scripts/script.php?script_id=489> instead)
"--------------------------------------------------------------
" ru ftplugin/man.vim
"--------------------------------------------------------------
" Highlight complete items in preview window
"--------------------------------------------------------------
function! s:HighlightCompleteItems() "{{{
  if &previewwindow && &bt == 'nofile' && pumvisible()
    syn match Label '^\w\+:'he=e-1
  endif
endfunction
"}}}
augroup Vimrc
  autocmd BufWinEnter * call s:HighlightCompleteItems()
augroup END

" vim: fdm=marker : ts=2 : sw=2 :
