if !exists('*SetLocalTagVars')
  finish
endif

let [s:snip_start_tag, s:snip_elem_delim, s:snip_end_tag] = SetLocalTagVars()

" let s:search_str = s:snip_start_tag
"       \ . '\%([^'.s:snip_start_tag.s:snip_end_tag
"       \ . '[:punct:] \t]\{-}\|".\{-}"\|\[.\{-}\]\|{.\{-}\}\)\%('
"       \ . s:snip_elem_delim
"       \ . '\_.\{-}\)\?'.s:snip_end_tag

" exec printf('syntax match SnipWholeTag /%s/ containedin=TOP', escape(s:search_str, '/'))

exec printf('syntax region SnipWholeTag matchgroup=SnipTag start=/%s/ end=/%s/ containedin=ALLBUT,SnipWholeTag keepend',
      \ escape(s:snip_start_tag 
      \         . '\%([^'.s:snip_start_tag .'[:punct:] \t]\|"\|\[\|{\|' 
      \         . s:snip_end_tag . '\|' . s:snip_elem_delim . '\)\@=', '/'), 
      \ escape(s:snip_end_tag, '/'))

" exec printf('syntax match SnipTag /%s/ contained containedin=SnipWholeTag', 
"       \ escape('\%('.s:snip_start_tag.'\)\|\%('.s:snip_end_tag.'\)', '/'))

exec printf('syntax match SnipEmptyTag /%s/ contained containedin=SnipWholeTag', 
      \ escape('\%('.s:snip_start_tag.'\)\@<=\[\d\+\]\%('.s:snip_end_tag.'\)\@=', '/'))

exec printf('syntax match SnipDefaultVal /%s/ contained containedin=SnipWholeTag', 
      \ escape('\%('.s:snip_start_tag.'\)\@<={.\{-}}\%(['. snip_elem_delim . snip_end_tag .']\)\@=', '/'))

exec printf('syntax match SnipTagName /%s/ contained containedin=SnipWholeTag', 
      \ escape('\%('.s:snip_start_tag.'\)\@<=[^' 
      \         . snip_start_tag . snip_end_tag . '[:punct:] \t]\{-}\%(['. snip_elem_delim . snip_end_tag .']\)\@=', '/'))

exec printf('syntax match SnipTagNameQ /%s/ contained containedin=SnipWholeTag', 
      \ escape('\%('.s:snip_start_tag.'\)\@<=".\{-}"\%(['. snip_elem_delim . snip_end_tag .']\)\@=', '/'))


hi link SnipTag           Comment
hi link SnipDefaultVal    Type
hi link SnipEmptyTag      Ignore
hi link SnipTagName       Tag
hi link SnipTagNameQ      String

unlet s:snip_start_tag s:snip_end_tag s:snip_elem_delim
" unlet s:search_str
