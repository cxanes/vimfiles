setlocal indentexpr=MyGetLexIndent(v:lnum)

if !exists('*MyGetLexIndent')
  function! MyGetLexIndent(lnum) 
    if a:lnum == 1
      return cindent(a:lnum)
    endif

    let lnum = prevnonblank(a:lnum - 1)
    if lnum == 0
      return cindent(a:lnum)
    endif

    let synstack = synstack(a:lnum-1, strlen(getline(lnum)))
    if empty(synstack)
      return cindent(a:lnum)
    endif

    let synstack = map(synstack, 'synIDattr(v:val, "name")')

    " lexInclude  -> %{ 
    "                ...
    "                %}
    if index(synstack, 'lexInclude') != -1
      let [lnum, col] = searchpos('^%{\|{', 'cnbW')
      if lnum == 0 || getline(lnum)[col-1] == '{'
        return cindent(a:lnum)
      else
        return cindent(a:lnum) - &ts
      endif
    endif

    return cindent(a:lnum)
  endfunction
endif
