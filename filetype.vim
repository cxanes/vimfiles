if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  " cwTeX: *.ctx
  au BufRead,BufNewFile *.ctx setf tex
  au BufRead,BufNewFile *.aspx,*.asmx,*.ascx setf aspnet 

  " The original filetype detection of *.m defined in $VIMRUNTIME/filetype.vim
  " first guesses filetype based on the first ten lines of the buffer (See
  " s:FTm() in filetype.vim). Since both MATLAB and Octave both use '%' for
  " commenting, the above filetype detection will set filetype of Octave script
  " to MATLAB.
  au BufRead,BufNewFile *.m if exists('g:filetype_m') | exe 'setf ' . g:filetype_m | endif

  " Yacc
  au BufRead,BufNewFile *.ypp,*.y++ let g:yacc_uses_cpp = 1 | setf yacc
  au BufRead,BufNewFile *.y         unlet! g:yacc_uses_cpp  | call s:FTy()

  " Lex
  au BufNewFile,BufRead *.lpp,*.l++ let g:lex_uses_cpp = 1 | setf lex
  au BufNewFile,BufRead *.l         unlet! g:lex_uses_cpp  | setf lex

  " WikidPad <http://wikidpad.python-hosting.com>
  au BufNewFile,BufRead *.wiki      setf wikidpad

  " LyX <http://www.lyx.org>
  au BufNewFile,BufRead *.lyx       setf lyx

  " (Perl) Parse::Eyapp <http://search.cpan.org/dist/Parse-Eyapp/>
  au BufNewFile,BufRead *.yp        setf eyapp
  au BufNewFile,BufRead *.eyp       setf eyapp 

  " GLSL: http://www.opengl.org/documentation/glsl/
  au BufNewFile,BufRead *.frag,*.vert,*.fp,*.fs,*.vp,*.vs,*.glsl setf glsl | setl cin
augroup END

" copy from filetype.vim
if !exists('s:FTy')
  func! s:FTy()
    let n = 1
    while n < 100 && n < line("$")
      let line = getline(n)
      if line =~ '^\s*%'
        setf yacc
        return
      endif
      if getline(n) =~ '^\s*\(#\|class\>\)' && getline(n) !~ '^\s*#\s*include'
        setf racc
        return
      endif
      let n = n + 1
    endwhile
    setf yacc
  endfunc
endif

