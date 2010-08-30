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
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn match OrgMode_Property /^#+\w\+:/
syn match OrgMode_Property /:\w\+:/

syn cluster OrgMode_Outline_Group contains=OrgMode_Tag,OrgMode_Todo,OrgMode_Timestamp,OrgMode_Priority

syn match OrgMode_Tag /:\%(\w\+:\)\+\%(\s*$\)\@=/ contained 

syn match OrgMode_Outline /\%(^\*\{4,}\)\@<=\*[^*].*$/ contains=@OrgMode_Outline_Group

syn match OrgMode_Outline1 /^\*[^*].*$/ contains=@OrgMode_Outline_Group
syn match OrgMode_Outline2 /\%(^\*\)\@<=\*[^*].*$/ contains=@OrgMode_Outline_Group
syn match OrgMode_Outline3 /\%(^\*\*\)\@<=\*[^*].*$/ contains=@OrgMode_Outline_Group
syn match OrgMode_Outline4 /\%(^\*\*\*\)\@<=\*[^*].*$/ contains=@OrgMode_Outline_Group

syn match OrgMode_Todo /\%(^\*\+\s\+\)\@<=\%(TODO\|DONE\)\+\>/ contained
syn match OrgMode_HiddenStar /^\*\{-1,}\%(\*[^*]\)\@=/
syn match OrgMode_TimestampKW /\<DEADLINE:/
syn match OrgMode_TimestampKW /\<SCHEDULED:/

syn region OrgMode_Timestamp start="<" end=">" oneline contains=OrgMode_Timestamp
syn region OrgMode_Timestamp start="\[" end="\]" oneline contains=OrgMode_Timestamp
syn region OrgMode_Priority  start="\[#" end="\]" oneline contains=OrgMode_Priority

hi! default link OrgMode_Outline1    Comment
hi! default link OrgMode_Outline2    Identifier
hi! default link OrgMode_Outline3    PreProc
hi! default link OrgMode_Outline4    Type
hi! default link OrgMode_HiddenStar  Ignore
hi! default link OrgMode_Property    Label
hi! default link OrgMode_Tag         Tag
hi! default link OrgMode_Todo        Todo
hi! default link OrgMode_TimestampKW Keyword
hi! default link OrgMode_Timestamp   Underlined
hi! default link OrgMode_Property    String
hi! default link OrgMode_Priority    Keyword

let b:current_syntax = 'org'
