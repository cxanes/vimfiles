" c++ configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
try
  call mylib#AddOptFiles('tags', 'tags/uclibc.tags')
  call mylib#AddOptFiles('tags', 'tags/stl.tags')
  call mylib#AddOptFiles('tags', 'tags/lsb.tags')
  call mylib#AddOptFiles('tags', 'tags/wx.tags')

  if !exists('g:opengl_headers')
    " possible headers: opengl-1.1, opengles-1.1, opengles2, glew 
    let g:opengl_headers = ['opengl-1.1']
  endif

  for header in g:opengl_headers
    call mylib#AddOptFiles('tags', printf('tags/%s.tags', header))
  endfor

  call mylib#AddOptFiles('dict', 'keywords/cpp')
  set complete+=k
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
try
  call IndentForComment#IndentForCommentMapping(['//', ['/*', '*/']], [30, 45, 60])
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

function! s:StlRefVimKeyMapping()
  vmap <silent> <buffer> <Leader>tr <Plug>StlRefVimVisual
  nmap <silent> <buffer> <Leader>tr <Plug>StlRefVimNormal
  map  <silent> <buffer> <Leader>taa <Plug>StlRefVimAsk
  map  <silent> <buffer> <Leader>ti <Plug>StlRefVimInvoke
  map  <silent> <buffer> <Leader>te <Plug>StlRefVimExample
endfunction

if !exists("loaded_stlrefvim")
  if empty(globpath(&rtp, "autoload/stlrefvim.vim"))
    let loaded_stlrefvim = 0
  else
    call s:StlRefVimKeyMapping()
    ru autoload/stlrefvim.vim
  endif
elseif loaded_stlrefvim == 1
  call s:StlRefVimKeyMapping()
endif
" }}}
"===================================================================
" vim: fdm=marker :
