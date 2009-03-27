if !exists('g:loaded_snips') || exists('s:did_vim_snips')
	fini
en
let s:did_vim_snips = 1
let snippet_filetype = 'vim'

function s:SID() "{{{
  if !exists('s:SID')
    let s:SID = matchstr(expand('<sfile>'), '<SNR>\d\+\ze_SID$')
  endif
  return s:SID
endfunction
"}}}
function! s:EndCompl(trigger) "{{{
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

" snippets for making snippets :)
exe 'Snipp snip exe "Snipp ${1:trigger}"${2}'
exe "Snipp snipp exe 'Snipp ${1:trigger}'${2}"
exe 'Snipp bsnip exe "BufferSnip ${1:trigger}"${2}'
exe "Snipp bsnipp exe 'BufferSnip ${1:trigger}'${2}"
exe 'Snipp gsnip exe "GlobalSnip ${1:trigger}"${2}'
exe "Snipp gsnipp exe 'GlobalSnip ${1:trigger}'${2}"
exe "Snipp guard if !exists('g:loaded_snips') || exists('s:did_".
	\ "${1:`substitute(expand(\"%:t:r\"), \"_snips\", \"\", \"\")`}_snips')\n\t"
	\ "finish\nendif\nlet s:did_$1_snips = 1\nlet snippet_filetype = '$1'${2}"

exe "Snipp func function! ${1:function_name}(${2}) \n\t${3}\nendfunction"
exe "Snipp for for ${1:i} in ${2:list}\n\t${3}\nendfor"
exe "Snipp wh while ${1:condition}\n\t${2}\nendwhile"
exe "Snipp if if ${1:condition}\n\t${2}\nendif"
exe "Snipp el else\n\t${1}"
exe "Snipp elif elseif ${1:condition}\n\t${2}"
exe "Snipp let let ${1} = ${2}"

exe "Snipp end `" . s:SID() . "_EndCompl('end')`"

" vim: set fdm=marker :
