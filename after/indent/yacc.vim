if exists('*GetYaccIndent') && exists('*synstack')
  setlocal indentexpr=MyGetYaccIndent(v:lnum)
  setlocal indentkeys+=0{,0}

  if !exists('*MyGetYaccIndent')
    function! MyGetYaccIndent(lnum) 
      if a:lnum <= 1
        return 0
      endif

      let lnum = prevnonblank(a:lnum - 1)
      if lnum == 0
        return indent(a:lnum)
      endif

      let synstack = synstack(lnum, strlen(getline(lnum)))
      if empty(synstack)
        return GetYaccIndent()
      endif

      let synstack = map(synstack, 'synIDattr(v:val, "name")')

      " yaccSection2 -> User Subroutines Section
      " yaccUnion    -> %union { ... }
      if index(synstack, 'yaccSection2') != -1
            \ || index(synstack, 'yaccUnion') != -1
        return cindent(a:lnum)
      endif

      if getline(a:lnum) =~ '^\s*{\?' 
        let line = getline(lnum)
        if line =~ '^[A-Za-z][A-Za-z0-9_]*\_s*:\s*\%({\)\@!'
          return matchend(line, '^[A-Za-z][A-Za-z0-9_]*\_s*') + &ts
        elseif line =~ '^\s*[:|;]'
          return matchend(line, '^\s*') + &ts
        endif
      endif

      " yaccAction   -> { ... }
      if index(synstack, 'yaccAction') != -1
        return cindent(a:lnum)
      endif

      " yaccInclude  -> %{ 
      "                 ...
      "                 %}
      if index(synstack, 'yaccInclude') != -1
        let [lnum, col] = searchpos('^%{\|{', 'cnbW')
        if lnum == 0 || getline(lnum)[col-1] == '{'
          return cindent(a:lnum)
        else
          return cindent(a:lnum) - &ts
        endif
      endif

      return GetYaccIndent()
    endfunction
  endif
endif
