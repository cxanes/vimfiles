" run only auto-pairs.vim exists
if !exists('g:AutoPairsLoaded')
  finish
end

fun! MyAutoPairsInsert(key)
  let c = getline('.')[col('.')-1]
  " If 'c' matches 'pat', don't complete parenthesis.
  if exists('b:CompleteParenMapEscapePat')
    let pat = b:CompleteParenMapEscapePat
  else
    let pat = a:0 > 0 ? a:1 : '\w'
  endif
  if match(c, pat) != -1
    return a:key
  else
    return AutoPairsInsert(a:key)
  endif
endfun

" rewrite version
func! AutoPairsMap(key)
  " | is special key which separate map command from text
  let key = a:key
  if key == '|'
    let key = '<BAR>'
  end
  let escaped_key = substitute(key, "'", "''", 'g')
  execute 'inoremap <buffer> <silent> <Leader>'.key.' '.key
  " use expr will cause search() doesn't work
  execute 'inoremap <buffer> <silent> '.key." <C-R>=MyAutoPairsInsert('".escaped_key."')<CR>"
endf
