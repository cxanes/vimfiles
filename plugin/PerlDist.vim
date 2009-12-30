" Perl.vim
" Last Modified: 2009-11-07 13:08:38
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_Perl')
  finish
endif
let loaded_Perl = 1

let s:MSWIN =  has('win32') || has('win32unix') || has('win64') || has('win95') || has('win16')
if !s:MSWIN
  unlet s:MSWIN
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}

let g:perlpath = ''
au FileType perl call Perl#SetOptPath(GetPerlDist())

command -nargs=? -bang -complete=custom,<SID>ListPerlDists SetPerlDist call SetPerlDist(<q-args>, <q-bang> == '!')
command -nargs=0 -bang                                     GetPerlDist echo GetPerlDist(<q-bang> == '!')

let s:PerlDistCandidates = ['cygwin', 'strawberry', '']

function! s:CheckDist(dist) "{{{
  if type(a:dist) != type('')
    echohl ErrorMsg
    echo 'Invalid format.'
    echohl None
    return 0
  endif

  if empty(a:dist) || index(s:PerlDistCandidates, a:dist) >= 0
    return 1
  else
    echohl ErrorMsg
    echo "Unsupported distribution: only 'cygwin' and 'strawberry' are supported."
    echohl None
    return 0
  endif
endfunction
"}}}

" g:PERL_DIST {{{
" {only for Win32 versions}
" possible distribution:
"   - (empty)
"   - cygwin
"   - strawberry
"   - all other distributions are not supported
let s:PERL_DIST_DEFAULT = 'strawberry'

if !exists('g:PERL_DIST')
  let g:PERL_DIST = s:PERL_DIST_DEFAULT
elseif !s:CheckDist(g:PERL_DIST)
  let g:PERL_DIST = ''
endif
"}}}

function! s:ListPerlDists(A,L,P) "{{{
  return join(s:PerlDistCandidates, "\n")
endfunction
"}}}
function! SetPerlDist(dist, ...) " ... = local {{{
  let scope = a:0 > 0 && !empty(a:1) ? 'b' : 'g'

  if !s:CheckDist(a:dist)
    return
  endif

  let {scope}:PERL_DIST = a:dist

  call Perl#SetEnv({scope}:PERL_DIST)
  
  if &ft =~ '\<perl\>'
    call Perl#SetOptPath({scope}:PERL_DIST, scope == 'b')
  endif
endfunction
"}}}
function! GetPerlDist(...) " ... = local {{{
  let local = a:0 > 0 && !empty(a:1) 
  if local && exists('b:PERL_DIST')
    return b:PERL_DIST
  else
    return g:PERL_DIST
  endif
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
