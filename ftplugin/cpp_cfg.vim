" c++ configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
if exists('*mylib#AddOptFiles')
  call mylib#AddOptFiles('tags', 'tags/stl.tags')
  call mylib#AddOptFiles('tags', 'tags/lsb32.tags')
  call mylib#AddOptFiles('tags', 'tags/wx.tags')

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
