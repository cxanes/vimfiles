" c++ configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
if exists('*mylib#AddOptFiles')
  call mylib#AddOptFiles('tags', 'tags/stl.tags')
  call mylib#AddOptFiles('tags', 'tags/lsb32.tags')
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
endif
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping(['//', ['/*', '*/']], [30, 45, 60])
endif
" }}}
"===================================================================
" vim: fdm=marker :
