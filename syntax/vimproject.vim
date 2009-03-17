" Vim syntax file
" Language:	WikidPad (v1.8rc14)
" Maintainer:	Frank Chang <frank.nevermind AT gmail.com>
" Reference: http://wikidpad.python-hosting.com/

if version < 600
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syn match  vimProjEntryDelimit  '[{}]'
syn match  vimProjEntryComment  '#.*'
syn match  vimProjEntryHeader '^.*\%({\s*\)\@='
syn match  vimProjEntryAssign '=' contained containedin=vimProjEntryHeader
syn match  vimProjEntryDescription  '\%(^\s\+\)\@<=[^=]\+' contained containedin=vimProjEntryHeader
syn match  vimProjEntryDescription  '[^=[:blank:]][^=]*' contained containedin=vimProjEntryHeader
syn match  vimProjEntryOption '\%(CD\|in\|out\|filter\|flags\)\%(=\)\@=' contained containedin=vimProjEntryHeader
syn match  vimProjEntryValue  '\%(=\)\@<=\%(\%(\\.\)\+\|[^\\[:blank:]]\+\)\+' contained containedin=vimProjEntryHeader
syn region vimProjEntryValue  start=+"+  skip=+\\"+  end=+"+ contained containedin=vimProjEntryHeader

hi link vimProjEntryDescription Label
hi link vimProjEntryOption      Tag
hi link vimProjEntryValue       String
hi link vimProjEntryComment     Comment
hi link vimProjEntryDelimit     Label
hi link vimProjEntryAssign      Type

let b:current_syntax = 'vimproject'
