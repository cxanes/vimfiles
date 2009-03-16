if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case match
syn sync minlines=50

if has("spell")
    syn spell toplevel
endif

syn include @gitStatusDiff syntax/diff.vim
syn region gitStatusDiff start=/\%(^diff --git \)\@=/ end=/^$\|^#\@=/ contains=@gitStatusDiff

syn match   gitStatusFirstLine  "\%^[^#].*"  nextgroup=gitStatusBlank skipnl
syn match   gitStatusSummary    "^.\{0,50\}" contained containedin=gitStatusFirstLine nextgroup=gitStatusOverflow contains=@Spell
syn match   gitStatusOverflow ".*" contained contains=@Spell
syn match   gitStatusBlank  "^[^#].*" contained contains=@Spell
syn match   gitStatusComment  "^#.*"
syn region  gitStatusHead start=/^#   / end=/^#$/ contained transparent
syn match   gitStatusOnBranch "\%(^# \)\@<=On branch" contained containedin=gitStatusComment nextgroup=gitStatusBranch skipwhite
syn match   gitStatusBranch "\S\+" contained
syn match   gitStatusHeader "\%(^# \)\@<=.*:$"  contained containedin=gitStatusComment

syn region  gitStatusUntracked  start=/^# Untracked files:/ end=/^#$\|^#\@!/ contains=gitStatusHeader,gitStatusHead,gitStatusUntrackedFile fold
syn match   gitStatusUntrackedFile  "\t\@<=.*"  contained

syn region  gitStatusDiscarded  start=/^# Changed but not updated:/ end=/^#$\|^#\@!/ contains=gitStatusHeader,gitStatusHead,gitStatusDiscardedType fold
syn region  gitStatusSelected start=/^# Changes to be committed:/ end=/^#$\|^#\@!/ contains=gitStatusHeader,gitStatusHead,gitStatusSelectedType fold

syn match   gitStatusDiscardedType  "\t\@<=[a-z][a-z ]*[a-z]: "he=e-2 contained containedin=gitStatusComment nextgroup=gitStatusDiscardedFile skipwhite
syn match   gitStatusSelectedType "\t\@<=[a-z][a-z ]*[a-z]: "he=e-2 contained containedin=gitStatusComment nextgroup=gitStatusSelectedFile skipwhite
syn match   gitStatusDiscardedFile  ".\{-\}\%($\| -> \)\@=" contained nextgroup=gitStatusDiscardedArrow
syn match   gitStatusSelectedFile ".\{-\}\%($\| -> \)\@=" contained nextgroup=gitStatusSelectedArrow
syn match   gitStatusDiscardedArrow " -> " contained nextgroup=gitStatusDiscardedFile
syn match   gitStatusSelectedArrow  " -> " contained nextgroup=gitStatusSelectedFile

hi def link gitStatusSummary        Keyword
hi def link gitStatusComment        Comment
hi def link gitStatusUntracked      gitStatusComment
hi def link gitStatusDiscarded      gitStatusComment
hi def link gitStatusSelected       gitStatusComment
hi def link gitStatusOnBranch       Comment
hi def link gitStatusBranch         Special
hi def link gitStatusDiscardedType  gitStatusType
hi def link gitStatusSelectedType   gitStatusType
hi def link gitStatusType           Type
hi def link gitStatusHeader         PreProc
hi def link gitStatusUntrackedFile  gitStatusFile
hi def link gitStatusDiscardedFile  gitStatusFile
hi def link gitStatusSelectedFile   gitStatusFile
hi def link gitStatusFile           Constant
hi def link gitStatusDiscardedArrow gitStatusArrow
hi def link gitStatusSelectedArrow  gitStatusArrow
hi def link gitStatusArrow          gitStatusComment
" hi def link gitStatusOverflow       Error
hi def link gitStatusBlank          Error

let b:current_syntax = 'git-status'
