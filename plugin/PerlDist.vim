" Perl.vim
" Last Modified: 2009-11-07 13:08:38
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_Perl')
  finish
endif
let loaded_Perl = 1

let s:MSWIN =  has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')
if !s:MSWIN
  unlet s:MSWIN
  finish
end

let s:save_cpo = &cpo
set cpo&vim
"}}}

let g:perlpath = ''
au FileType perl call Perl#SetOptPath(GetPerlDist())

command -nargs=1 -bang -complete=custom,<SID>ListPerlDists SetPerlDist call SetPerlDist(<q-args>, <q-bang> == '!')
command -nargs=0 -bang                                     GetPerlDist echo GetPerlDist(<q-bang> == '!')

" g:PERL_DIST {{{
" {only for Win32 versions}
" possible distribution:
"   - cygwin
"   - strawberry
"   - all other distributions are not supported
let g:PERL_DIST = 'cygwin'
"}}}

function! s:ListPerlDists(A,L,P) "{{{
  return "cygwin\nstrawberry"
endfunction
"}}}
function! SetPerlDist(dist, ...) " ... = local {{{
  let scope = a:0 > 0 && !empty(a:1) ? 'b' : 'g'

  if a:dist ==? 'cygwin'
    let {scope}:PERL_DIST = 'cygwin'
  elseif a:dist ==? 'strawberry'
    let {scope}:PERL_DIST = 'strawberry'
  else
    echohl ErrorMsg
    echo "Unsupported distribution: only 'cygwin' and 'strawberry' are supported."
    echohl None
    return
  endif

  call Perl#SetEnv({scope}:PERL_DIST)
  
  if &ft =~ '\<perl\>'
    call Perl#SetOptPath({scope}:PERL_DIST, scope == 'b')
  end
endfunction
"}}}
function! GetPerlDist(...) " ... = local {{{
  let local = a:0 > 0 && !empty(a:1) 
  if local && exists('b:PERL_DIST')
    return b:PERL_DIST
  else
    return g:PERL_DIST
  end
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
