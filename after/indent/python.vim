
if exists('*GetPythonIndent')
  setlocal indentexpr=MyGetPythonIndent(v:lnum)

  if !exists('*MyGetPythonIndent')
    function! MyGetPythonIndent(lnum) 
      let i = GetPythonIndent(a:lnum)
      if i != -1
        return i
      endif

      let plnum = prevnonblank(v:lnum - 1)
      let nlnum = nextnonblank(v:lnum + 1)

      if plnum != 0 && nlnum != 0 && indent(plnum) == indent(nlnum)
        return indent(plnum)
      endif

      " if plnum == 0 && v:lnum + 1 <= line('$')
      "   return indent(nlnum)
      " endif

      " if nlnum == 0 && v:lnum - 1 >= 1
      "   return indent(plnum)
      " endif

      return -1
    endfunction
  endif
endif
