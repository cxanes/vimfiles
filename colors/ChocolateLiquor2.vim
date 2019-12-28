" Vim color file
" Maintainer:   Gerald S. Williams
" Last Change:  2007 Jun 13

" This started as a dark version (perhaps opposite is a better term) of
" PapayaWhip, but took on a life of its own. Easy on the eyes, but still has
" good contrast. Not bad on a color terminal, either (especially if yours
" default to PapayaWhip text on a ChocolateLiquor/#3f1f1f background).
"
" Only values that differ from defaults are specified.

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "ChocolateLiquor2"

hi Normal guibg=#3f1f1f guifg=PapayaWhip ctermfg=White
if !has('gui_running') && &t_Co == 256
hi NonText guibg=#1f0f0f guifg=Brown2 ctermfg=3 ctermbg=Black
else
hi NonText guibg=#1f0f0f guifg=Brown2 ctermfg=Brown ctermbg=Black
endif
hi LineNr guibg=#1f0f0f guifg=Brown2 ctermfg=DarkGray
hi DiffDelete guibg=DarkRed guifg=White ctermbg=DarkRed ctermfg=White
hi DiffAdd guibg=DarkGreen guifg=White ctermbg=DarkGreen ctermfg=White
hi DiffText gui=NONE guibg=DarkCyan guifg=Yellow ctermbg=DarkCyan ctermfg=Yellow
hi DiffChange guibg=DarkCyan guifg=White ctermbg=DarkCyan ctermfg=White
hi Constant ctermfg=Red
hi Comment guifg=Gray ctermfg=Gray
hi Function guifg=Cyan ctermfg=Cyan
hi Identifier guifg=Cyan ctermfg=Cyan
hi PreProc guifg=Plum ctermfg=Magenta
if !has('gui_running') && &t_Co == 256
hi StatusLine guibg=White guifg=Sienna4 cterm=NONE ctermfg=Black ctermbg=3
else
hi StatusLine guibg=White guifg=Sienna4 cterm=NONE ctermfg=Black ctermbg=Brown
endif
hi StatusLineNC gui=NONE guifg=Black guibg=Gray ctermbg=Black ctermfg=Gray
hi VertSplit guifg=Gray
if !has('gui_running') && &t_Co == 256
hi Search guibg=Gold3 ctermfg=Blue ctermbg=226
else
hi Search guibg=Gold3 ctermfg=Blue
endif
hi Type gui=NONE guifg=DarkSeaGreen2
hi Statement gui=NONE guifg=Gold3
hi FoldColumn guibg=#1f0f0f ctermfg=Cyan ctermbg=Black
hi Folded guibg=grey20 ctermfg=Cyan ctermbg=Black

if !has('gui_running') && &t_Co == 256
hi Visual cterm=NONE ctermbg=66
endif

if !has('gui_running') && &t_Co == 256
hi SpecialKey term=bold ctermfg=DarkBlue
hi Special ctermfg=Red
hi Type ctermfg=Green
hi Underlined term=underline ctermfg=DarkBlue
hi Todo ctermbg=226
endif

if version >= 700
if !has('gui_running') && &t_Co == 256
  hi Pmenu    guibg=LightMagenta gui=NONE ctermfg=White ctermbg=66   cterm=NONE
else
  hi Pmenu    guibg=LightMagenta gui=NONE ctermfg=White ctermbg=DarkGray   cterm=NONE
endif
  hi PmenuSel guibg=Grey         gui=NONE ctermfg=Black ctermbg=LightGreen cterm=NONE 
endif

hi spellBad      term=reverse      cterm=underline ctermbg=darkred
