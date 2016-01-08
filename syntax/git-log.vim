if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syntax match gitLogCommit +^commit \x\{40}+
syntax match gitLogAuthor +^Author:.*+
syntax match gitLogDate   +^Date:.*+

highlight link gitLogCommit Statement
highlight link gitLogAuthor Type
highlight link gitLogDate   Function

let b:current_syntax = 'git-log'
