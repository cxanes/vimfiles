" c++ configuration file
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
if exists('*AddOptFiles')
  call AddOptFiles('tags', 'tags/stl.tags')
  call AddOptFiles('tags', 'tags/lsb32.tags')
  call AddOptFiles('tags', 'tags/wx.tags')

  call AddOptFiles('dict', 'keywords/cpp')
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
