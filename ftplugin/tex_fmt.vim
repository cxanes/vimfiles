" TeX formatting file
"===================================================================
setl formatexpr=TeXFormatExpr()
"===================================================================
" Load Once "{{{
if exists('*TeXFormat')
  finish
endif
"}}}
"-------------------------------------------------------------------
function! s:EnvPairPat(...) "{{{
  let pair = []
  for env in a:000
    call add(pair, [printf('^\s*\\begin{%s}', env), printf('^\s*\\end{%s}', env)])
  endfor
  return pair
endfunction
"}}}
function! s:LeadCmdPat(...) "{{{
  let pat = []
  for word in a:000
    call add(pat, printf('^\s*\\%s\>', word))
  endfor
  return pat
endfunction
"}}}

function! s:CanSkip(str) "{{{
  for pat in s:fmt_skip
    if a:str =~ pat
      return 1
    endif
  endfor
  return 0
endfunction
"}}}

let s:fmt_skip      = ['\\\\\%(\[[^\]*\]\)\?$', 'centering', 'include\S*', 
      \ 'caption', 'label', 'vspace']
let s:fmt_delimit   = s:LeadCmdPat('item', 'bibitem') + s:fmt_skip

let s:fmt_verbatim  = [['\\\[', '\\\]']]
let s:fmt_verbatim += s:EnvPairPat('equation', 'align', '[Vv]erbatim', 'table', 'tabular')

let s:fmt_block     = [['^\s*\\begin\>', '^\s*\\end\>']]

function! s:PairCanSkip(...) "{{{
  let pos = a:0 ? a:1 : [line('.'), col('.')]
  return synIDattr(synID(pos[0], pos[1], 0), 'name') =~? 'comment'
endfunction
"}}}
let s:fmt_pair_skip = 's:PairCanSkip()'

function! s:SkipVerbatim(lnum, range) "{{{
  let [start, stop] = a:range
  if a:lnum < start || a:lnum > stop
    return 0
  endif

  try 
    for [beg_pat, end_pat] in s:fmt_verbatim
      call cursor(a:lnum, 1)
      let pos = searchpos(e, 'cnW', a:lnum)
      if pos[0] != 0 && !s:PairCanSkip(pos)
        return a:lnum + 1
      endif

      let end_lnum = searchpair(beg_pat, '', end_pat, 'nW', s:fmt_pair_skip)
      if end_lnum > 0
        call cursor(end_lnum, 1)
        let beg_lnum = searchpair(beg_pat, '', end_pat, 'bnW', s:fmt_pair_skip)
        if beg_lnum && !(beg_lnum < start && stop < end_lnum)
          return min([end_lnum, stop]) + 1
        endif
      endif
    endfor
    return 0
  finally
    call cursor(a:lnum, 1)
  endtry
endfunction
"}}}
function! s:BlockPos(lnum, range) "{{{
  let [start, stop] = a:range
  if a:lnum < start || a:lnum > stop
    return [-1, -1]
  endif

  try
    call cursor(a:lnum, 1)
    let lnums = []
    for [beg_pat, end_pat] in s:fmt_block
      let pos = searchpos(e, 'cnW', a:lnum)
      if pos[0] != 0 && !s:PairCanSkip(pos)
        return [a:lnum, a:lnum]
      endif

      let end_lnum = searchpair(beg_pat, '', end_pat, 'nW', s:fmt_pair_skip)
      if end_lnum > 0
        call add(lnums, end_lnum)
      endif
    endfor

    if !empty(lnums)
      let end_lnum = min(lnums)
      call cursor(end_lnum, 1)
      let beg_lnum = searchpair(beg_pat, '', end_pat, 'bnW')
      if beg_lnum && !(beg_lnum < start && stop < end_lnum)
        return [beg_lnum && beg_lnum < start ? (start-1) : beg_lnum, end_lnum > stop ? (stop+1) : end_lnum]
      endif
    endif

    return [-1, -1]
  finally
    call cursor(a:lnum, 1)
  endtry
endfunction
"}}}
function! s:FindDelimit(lnum, stop) "{{{
  if a:lnum > a:stop
    return 0
  endif

  try
    call cursor(a:lnum, 1)
    let lnums = []
    for [beg_pat, end_pat] in (s:fmt_verbatim + s:fmt_block)
      let pos = searchpos(beg_pat, 'cnW', a:stop)
      if pos[0] != 0 && !s:PairCanSkip(pos)
        call add(lnums, pos[0])
        continue
      endif
    endfor

    if !empty(lnums)
      return min(lnums)
    endif

    let lnums = []
    for pat in s:fmt_delimit
      call cursor(a:lnum, 1)
      let pos = searchpos(pat, 'cnW', a:stop)
      if pos[0] != 0 && !s:PairCanSkip(pos)
        if a:lnum + 1 > a:stop
          continue
        endif
        call cursor(a:lnum + 1, 1)
      endif

      let pos = searchpos(pat, 'cnW', a:stop)
      if pos[0] != 0 && !s:PairCanSkip(pos)
        call add(lnums, pos[0])
        continue
      endif
    endfor

    return min(lnums)
  finally
    call cursor(a:lnum, 1)
  endtry
endfunction
"}}}
function! s:FormatRegion(start, delimit_lnum, stop_lnum) "{{{
  let stop = a:delimit_lnum == 0 
        \ ? a:stop_lnum : 
        \   a:delimit_lnum > a:stop_lnum 
        \   ? a:stop_lnum : (a:delimit_lnum-1)

  if a:start > stop
    return [a:start+1, a:stop_lnum]
  endif

  echom string(a:start, stop)

  call cursor(a:start, 1)
  silent normal! ==

  if a:start == stop
    call append(a:start, '')
    exec printf('silent normal! V%dGgq', stop+1)
    if line('.') == line('$')
      silent d _
    else
      silent d _
      silent normal k
    endif
  else
    exec printf('silent normal! V%dGgq', stop)
  endif
  return [line('.')+1, a:stop_lnum-(stop-line('.'))]
endfunction
"}}}
function! TeXFormat(start, stop) "{{{
  let lnum = a:start
  let stop = a:stop

  while lnum <= stop
    let next_lnum = nextnonblank(lnum)
    if next_lnum != lnum
      if next_lnum > stop
        break
      endif
      let lnum = next_lnum
    endif

    if s:CanSkip(getline(lnum))
      call cursor(lnum, 1)
      silent normal! ==
      let lnum += 1
      continue
    endif

    let next_lnum = s:SkipVerbatim(lnum, [a:start, stop])
    if next_lnum
      let lnum = next_lnum
      continue
    endif

    let [beg_lnum, end_lnum] = s:BlockPos(lnum, [a:start, stop])

    if beg_lnum != -1
      let stop -= end_lnum - 1 - TeXFormat(beg_lnum + 1, end_lnum - 1)
      let lnum  = end_lnum + 1
    else
      let [lnum, stop] = s:FormatRegion(lnum, s:FindDelimit(lnum, stop), stop) 
    endif
  endwhile

  call cursor(stop, 1)
  return stop
endfunction
"}}}
function! TeXFormatExpr() "{{{
  if mode() == 'i'
    return 1
  endif

  setl formatexpr=
  call TeXFormat(v:lnum, v:lnum+v:count-1)
  setl formatexpr=TeXFormatExpr()
endfunction
"}}}
"===================================================================
" vim: fdm=marker :
