" Script: syntax/org.vim
"
" Version: 0.1
"
" Description:
"
"       The subset of Emacs Org-Mode Syntax <http://orgmode.org/>
"
" Maintainer: Frank Chang
"

syn match OrgMode_Property /^#+\w\+:/
syn match OrgMode_Property /:\w\+:/

syn match OrgMode_Tag /:\%(\w\+:\)\+\%(\s*$\)\@=/ contained 

syn match OrgMode_Outline /\%(^\*\{4,}\)\@<=\*[^*].*$/ contains=OrgMode_Tag

syn match OrgMode_Outline1 /^\*[^*].*$/ contains=OrgMode_Tag
syn match OrgMode_Outline2 /\%(^\*\)\@<=\*[^*].*$/ contains=OrgMode_Tag
syn match OrgMode_Outline3 /\%(^\*\*\)\@<=\*[^*].*$/ contains=OrgMode_Tag
syn match OrgMode_Outline4 /\%(^\*\*\*\)\@<=\*[^*].*$/ contains=OrgMode_Tag

syn match OrgMode_Hiddenstar /^\*\{-1,}\%(\*[^*]\)\@=/

hi! default link OrgMode_Outline1    Comment
hi! default link OrgMode_Outline2    Identifier
hi! default link OrgMode_Outline3    PreProc
hi! default link OrgMode_Outline4    Type
hi! default link OrgMode_Hiddenstar  Ignore
hi! default link OrgMode_Property    Label
hi! default link OrgMode_Tag         Tag
