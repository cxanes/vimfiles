if !exists('*SetLocalTagVars')
  finish
endif

let [s:snip_start_tag, s:snip_elem_delim, s:snip_end_tag] = SetLocalTagVars()

if exists("b:current_syntax") && b:current_syntax != 'vim'
  let s:current_syntax = b:current_syntax
  unlet b:current_syntax
endif

syntax include @VimSyn syntax/vim.vim

if exists("s:current_syntax")
  let b:current_syntax = s:current_syntax
  unlet s:current_syntax
endif

syntax region SnipCommandTag start=/``/ end=/``/ contains=SnipCommand keepend containedin=ALLBUT,SnipCommand,@VimSyn
syntax match SnipCommand /\%(``\)\@<=\_.\{-}\%(``\)\@=/ contains=@VimSyn contained

exec printf ('syntax match SnipSep /\%(``\|%s\)\@<=[{]\|[}]\%(``\|%s\)\@=/ containedin=SnipCommand,SnipFilterCommand contained',
      \ escape(s:snip_elem_delim, '/'), escape(s:snip_end_tag, '/'))

exec printf('syntax region SnipFilterCommand matchgroup=SnipTag start=/%s/ end=/%s/ contains=@VimSyn containedin=SnipWholeTag,SnipTag contained', escape(s:snip_elem_delim, '/'), escape(s:snip_end_tag, '/'))

hi link SnipCommandTag    Comment
hi link SnipCommand       Comment
hi link SnipFilterCommand Comment
hi link SnipSep           PreProc

unlet s:snip_start_tag s:snip_end_tag s:snip_elem_delim
