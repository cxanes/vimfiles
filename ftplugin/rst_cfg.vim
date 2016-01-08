" rst configuration file
"===================================================================
" Wiki-related settings
"-------------------------------------------------------------------
if exists('g:rst_wiki') && g:rst_wiki 
      \ && exists('g:WikiHomeDir') && isdirectory(g:WikiHomeDir)
  setlocal includeexpr=RstIncludeExpr(v:fname)

  nnoremap <buffer> gf         :<C-U>e    `=RstIncludeExpr(expand('<lt>cfile>'))`<CR>
  nnoremap <buffer> <C-W>f     :<C-U>new  `=RstIncludeExpr(expand('<lt>cfile>'))`<CR>
  nnoremap <buffer> <C-W><C-F> :<C-U>new  `=RstIncludeExpr(expand('<lt>cfile>'))`<CR>
  nnoremap <buffer> <C-W>gf    :<C-U>tabe `=RstIncludeExpr(expand('<lt>cfile>'))`<CR>

  function! RstIncludeExpr(fname) "{{{
    let wikiLink = s:GetWikiLink(line('.'), col('.'))
    if empty(wikiLink)
      if exists('*IncludeExpr')
        return IncludeExpr(a:fname)
      else
        return a:fname
      endif
    endif

    if exists('g:WikiHomeDir')
      let wikiLink = simplify(g:WikiHomeDir . '/' . wikiLink)
    endif

    let wikiLink .= '.rst'
    return wikiLink
  endfunction
  "}}}
  function! s:GetWikiLink(lnum, col) "{{{
    let sav_pos = getpos('.')

    try
      let [lnum, col] = searchpos('\%(\%([^\\]\|^\)\\\%(\\\\\)*\)\@<!\[\[\+', 'bc', a:lnum)
      if lnum == 0
        return ''
      endif

      let line = getline('.')
      let pos = matchend(line, '\[\[\([^\]\\]\+\|\%(\\.\)\+\|\]\%(\]\)\@!\)*\]\]', col-1)
      if pos < 0 || a:col > pos
        return ''
      endif

      let link = line[col+1 : pos-3]
      let link = substitute(link, '\\\(.\)', 
        \ '\= stridx(''\[]'', submatch(1)) < 0 ? (''\'' . submatch(1)) : submatch(1)', 'g')
      return link
    finally
      call setpos('.', sav_pos)
    endtry

    return ''
  endfunction
  "}}}
endif
"===================================================================
" vim: fdm=marker :
