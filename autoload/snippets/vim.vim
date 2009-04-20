function! snippets#vim#EndCompl(trigger) "{{{
  if has('syntax_items') 
        \ && synIDattr(synID(line('.'), col('.')-1, 0), 'name') =~? 'comment\|string'
    call feedkeys("\<C-N>")
    return a:trigger
  endif

  let pos = getpos('.')

  let cnt_idx     = 0
  let beg_pat_idx = 1
  let end_pat_idx = 2

  let identifiers = { 
        \   'try'     : [0, '^try$'         , '^endt\%[ry]$'     ],
        \   'while'   : [0, '^wh\%[ile]$'   , '^endw\%[hile]$'   ],
        \   'function': [0, '^fu\%[nction]$', '^endf\%[unction]$'],
        \   'for'     : [0, '^for$'         , '^endfo\%[r]$'     ],
        \   'if'      : [0, '^if$'          , '^en\%[dif]$'      ],
        \ }

  let word = s:PrevWord()
  while !empty(word)
    for [ident, info] in items(identifiers)
      if word =~ info[end_pat_idx]
        let info[cnt_idx] -= 1
        break
      elseif word =~ info[beg_pat_idx]
        let info[cnt_idx] += 1

        if info[cnt_idx] > 0
          call setpos('.', pos)
          return 'end' . ident
        endif

        break
      endif
    endfor

    let word = s:PrevWord()
  endwhile

  call setpos('.', pos)
  call feedkeys("\<C-N>")
  return a:trigger
endfunction
"}}}
function! s:PrevWord() "{{{
  let pat = '\%(^\s*\||\s*\)\@<=\<\%(try\|wh\%[ile]\|fu\%[nction]\|for\|if\|en\%[dif]\|end\%(t\%[ry]\|w\%[hile]\|f\%[unction]\|fo\%[r]\)\)\>'

  while 1
    let [lnum, col] = searchpos(pat, 'bnW')
    if lnum == 0
      return ''
    endif

    call cursor(lnum, col)
    if has('syntax_items') 
      let name = synIDattr(synID(line('.'), col('.'), 0), 'name')
      if name =~? 'comment\|string' || name !~? '^vim'
        continue
      endif
    endif

    break
  endwhile

  let word = matchstr(getline('.')[col('.')-1 : ], '^' . pat)
  return word
endfunction
"}}}
" vim: fdm=marker :