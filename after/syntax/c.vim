try
  syn clear cPreConditMatch
  syn match	cPreConditMatch	display "^\s*\(%:\|#\)\s*\(else\|endif\)\>"
catch /^Vim\%((\a\+)\)\=:E28/
endtry

ru syntax/opengl.vim
ru syntax/ctags_highlighting.vim
