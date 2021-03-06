" Vim color file
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2001 Jul 23

" This is the default color scheme.  It doesn't define the Normal
" highlighting, it uses whatever the colors used to be.

" Set 'background' back to the default.  The value can't always be estimated
" and is then guessed.
hi clear Normal
set bg&

" Remove all existing highlighting and set the defaults.
hi clear

" Load the syntax highlighting defaults, if it's enabled.
if exists("syntax_on")
  syntax reset
endif

if version >= 700
  hi Pmenu    guibg=LightMagenta gui=NONE ctermfg=White ctermbg=DarkGray   cterm=NONE
  hi PmenuSel guibg=Grey         gui=NONE ctermfg=Black ctermbg=LightGreen cterm=NONE 
endif

let colors_name = "default2"

" vim: sw=2
