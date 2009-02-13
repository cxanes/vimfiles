" Maintainer:   Lars H. Nielsen (dengmao@gmail.com)
" Last Change:  January 22 2007
"
" Modified by Frank Chang <frank.nevermind AT gmail.com>
"

set background=dark

hi clear

if exists("syntax_on")
  syntax reset
endif

let colors_name = "wombat2"


" Vim >= 7.0 specific colors
if version >= 700
  hi CursorLine         guibg=#2d2d2d
  hi CursorColumn       guibg=#2d2d2d
  " hi MatchParen         guifg=#f6f3e8 guibg=#857b6f gui=bold
  hi MatchParen         guifg=#f6f3e8 guibg=#2B4848 gui=bold
  hi Pmenu              guifg=#f6f3e8 guibg=#444444
  hi PmenuSel           guifg=#000000 guibg=#cae682
endif

" General colors
hi Cursor               guifg=NONE    guibg=#656565 gui=none
hi Normal               guifg=#f6f3e8 guibg=#242424 gui=none
hi NonText              guifg=#808080 guibg=#303030 gui=none
hi LineNr               guifg=#857b6f guibg=#000000 gui=none
hi StatusLine           guifg=#f6f3e8 guibg=#444444 gui=none
hi StatusLineNC         guifg=#857b6f guibg=#444444 gui=none
hi VertSplit            guifg=#444444 guibg=#444444 gui=none
hi Folded               guifg=#a0a8b0 guibg=#384048 gui=none
hi FoldColumn           guifg=#857b6f guibg=#000000 gui=none
hi SignColumn           guifg=#857b6f guibg=#242424 gui=none
hi Title                guifg=#f6f3e8 guibg=NONE    gui=bold
hi Visual               guifg=#f6f3e8 guibg=#444444 gui=none
hi SpecialKey           guifg=#808080 guibg=#343434 gui=none

" Syntax highlighting
hi Comment              guifg=#99968b gui=none
" hi Todo                 guifg=#8f8f8f gui=none
hi Todo                 guifg=#000000 gui=none
hi Constant             guifg=#e5786d gui=none
hi String               guifg=#95e454 gui=none
hi Identifier           guifg=#cae682 gui=none
hi Function             guifg=#cae682 gui=none
hi Type                 guifg=#cae682 gui=none
hi Statement            guifg=#8ac6f2 gui=none
hi Keyword              guifg=#8ac6f2 gui=none
hi PreProc              guifg=#e5786d gui=none
hi Number               guifg=#e5786d gui=none
" hi Special              guifg=#e7f6da gui=none
hi Special              guifg=#ff5755 gui=none

