" Rst after syntax file

" ref: http://fp-etc.progiciels-bpi.ca/showfile.html?name=vim/syntax/rest.vim

syn match rstTitle /^\S.*\n\%(\([!\"#$%&'()*+,\-.\/:;<=>?@[\\\]^_`{|}~]\)\1\+$\)\@=/
      \ contains=@rstInline

syn region rstTitle oneline matchgroup=rstTitleLine keepend 
      \ start=/^\%1c\z(\([!\"#$%&'()*+,\-.\/:;<=>?@[\\\]^_`{|}~]\)\1\+\)\s*\n/ end=/\n\z1\s*$/
      \ contains=@rstInline

syn match rstTitleLine /\%(^\S.*\n\)\@<=\([!\"#$%&'()*+,\-.\/:;<=>?@[\\\]^_`{|}~]\)\1\+$/
syn match rstFieldList /\%(^\s*\)\@<=:\%([^:]\|\\:\)\+:\s\@=/
syn match rstBulletedList /\%(^\s*\)\@<=[-+*]\s\@=/
syn match rstEnumeratedList /\%(^\s*\)\@<=\d\{1,3}\.\s\@=/

syn match rstTransition /\%(^\s*\n\)\@<=\([!\"#$%&'()*+,\-.\/:;<=>?@[\\\]^_`{|}~]\)\1\{3,}\s*\n\%(\s*\)\@=$/

syntax cluster rstInline contains=@NoSpell

syntax cluster rstInline add=rstEmphasis
syntax cluster rstInline add=rstStrongEmphasis
syntax cluster rstInline add=rstInterpretedTextOrHyperlinkReference
syntax cluster rstInline add=rstInlineLiteral
syntax cluster rstInline add=rstSubstitutionReference
syntax cluster rstInline add=InlineInternalTargets

hi link rstTitle                  Todo
hi link rstTitleLine              Constant
hi link rstTransition             Constant
hi link rstFieldList              Label
hi link rstBulletedList           Operator
hi link rstEnumeratedList         Operator
hi link rstLiteralBlock           Comment
hi link rstEmphasis               Exception
hi link rstInlineLiteral          Function
hi link rstStrongEmphasis         Exception
hi link rstSubstitutionReference  Macro
hi link rstStandaloneHyperlink    Underlined	
hi link rstHyperlinkTarget        Underlined	
hi link rstExDirective            Character

syn sync minlines=100 linebreaks=5
