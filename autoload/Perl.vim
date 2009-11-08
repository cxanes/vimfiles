" Perl.vim
" Last Modified: 2009-11-06 22:18:44
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_Perl')
  finish
endif
let loaded_autoload_Perl = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
let s:MSWIN =  has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')

let s:CYGWIN_PERL_ROOT     = 'C:\cygwin'
let s:STRAWBERRY_PERL_ROOT = 'C:\strawberry'

function! s:CatDir(...) "{{{
  let full_dir = ''
  for dir in a:000
    if !empty(full_dir)
      let full_dir .= '\'
    end
    let full_dir .= substitute(dir, '\\\+$', '', '')
  endfor
  return full_dir
endfunction
"}}}

let s:BIN_DIR = { 'cygwin'    :   s:CatDir(s:CYGWIN_PERL_ROOT, 'bin'),
      \           'strawberry': [ s:CatDir(s:STRAWBERRY_PERL_ROOT, 'perl', 'bin'),
      \                           s:CatDir(s:STRAWBERRY_PERL_ROOT, 'c'   , 'bin') ] }

function! Perl#SetEnv(dist) "{{{
  if !s:MSWIN
    echohl ErrorMsg
    echo "Only for Win32 versions."
    echohl None
    return
  elseif a:dist ==? 'cygwin'
    let $PERL5LIB = Cygwin#ChangePath($PERL5LIB, 1)
    call s:AddPATH(a:dist)
  elseif a:dist ==? 'strawberry'
    let $PERL5LIB = Cygwin#ChangePath($PERL5LIB, 0)
    call s:AddPATH(a:dist)
  else
    echohl ErrorMsg
    echo "Unsupported distribution: only 'cygwin' and 'strawberry' are supported."
    echohl None
    return
  endif
endfunction
"}}}
" ref: $VIMRUNTIME/ftplugin/perl.vim
function! Perl#SetOptPath(dist, ...) " ... = [local, force] {{{
  let local = a:0 > 0 && !empty(a:1)
  let force = a:0 > 1 && !empty(a:2)

  if a:dist == 'cygwin'
    if !exists('s:perlpath_cyg') || force
      if executable('perl') && executable('cygpath')
        try
          " I don't use $_ directly because of the different interpretations in 
          " different shells (e.g. cmd.exe or bash.exe)
          if &shellxquote != '"'
            let cmd = 'perl -MShell=cygpath -e "print map { cygpath(q{-m}, join q{}, split /(.+)/) } @INC"'
          else
            let cmd = "perl -MShell=cygpath -e 'print map { cygpath(q{-m}, join q{}, split /(.+)/) } @INC'"
          end

          let s:perlpath_cyg = system(cmd)
          let map_expr = 'substitute(v:val, ''\([ ,]\)'', ''\\\1'', ''g'')'
          let s:perlpath_cyg = join(map(split(s:perlpath_cyg, '\n'), map_expr), ',')
          let s:perlpath_cyg = substitute(s:perlpath_cyg,',.$',',,','')
        catch /E145:/
          let s:perlpath_cyg = '.,,'
        endtry
      else
          let s:perlpath_cyg = '.,,'
      endif
    endif

    let &l:path=s:perlpath_cyg
  else
    " copied from $VIMRUNTIME/ftplugin/perl.vim
    if !exists('s:perlpath') || force
      if executable("perl")
        try
          if &shellxquote != '"'
            let s:perlpath = system('perl -e "print join(q/,/,@INC)"')
          else
            let s:perlpath = system("perl -e 'print join(q/,/,@INC)'")
          endif
          let s:perlpath = substitute(s:perlpath,',.$',',,','')
        catch /E145:/
          let s:perlpath = '.,,'
        endtry
      else
        let s:perlpath = '.,,'
      endif
    endif

    let &l:path=s:perlpath
  endif

  if !local
    let g:perlpath = &l:path
  endif

  return &l:path
endfunction
"}}}
function! s:DirPat(dir)"{{{
  return '\V\c\%(\^' . escape(a:dir, '\') . '\\\?\%(\$\|;\)\)\|\%(;' . escape(a:dir, '\') . '\\\?\%(\$\|;\)\@=\)\m'
endfunction
"}}}
function! s:RemoveStrawberryPerlFromPATH() "{{{
    for dir in s:BIN_DIR.strawberry
      let $PATH = substitute($PATH, s:DirPat(dir), '', 'g')
    endfor
endfunction
"}}}
function! s:AddPATH(dist) "{{{
  if !s:MSWIN
    echohl ErrorMsg
    echo "Only for Win32 versions."
    echohl None
    return
  end

  if a:dist ==? 'cygwin'
    call s:RemoveStrawberryPerlFromPATH()
    let bin_idx_cygwin = match($PATH, s:DirPat(s:BIN_DIR.cygwin))
    if bin_idx_cygwin < 0
      let $PATH .= ($PATH =~ ';$' ? '' : ';') . s:BIN_DIR.cygwin
    endif
  elseif a:dist ==? 'strawberry'
    call s:RemoveStrawberryPerlFromPATH()
    let bin_idx_cygwin = match($PATH, s:DirPat(s:BIN_DIR.cygwin))
    if bin_idx_cygwin == 0
      let $PATH = join(s:BIN_DIR.strawberry, ';') . ';' . $PATH
    elseif bin_idx_cygwin < 0
      let $PATH .= ($PATH =~ ';$' ? '' : ';') . join(s:BIN_DIR.strawberry, ';')
    else
      let $PATH = $PATH[0 : bin_idx_cygwin-1] . ';' . join(s:BIN_DIR.strawberry, ';') . $PATH[bin_idx_cygwin : ]
    endif
  endif
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
