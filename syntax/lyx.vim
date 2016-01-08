" Vim syntax file
" Language:     Lyx  <http://www.lyx.org>
" Maintainer:   Frank Chang <frank.nevermind AT gmail.com>
" Last Change:  2009-01-15
" Filenames:    *.lyx
"
" Quit when a syntax file was already loaded
if version < 600
  syn clear
elseif exists("b:current_syntax")
  finish
endif

syn include @texGroup syntax/tex.vim

syn cluster texMatchGroup add=@lyxEnvGroup
syn cluster lyxEnvGroup contains=lyxBody,lyxPreamble,lyxHeader,lyxDocument,lyxBranch,lyxLayout,lyxInset,lyxDeeper

syn match lyxShebang '\%^#LyX\s.\+$'

function! s:SynEvn(group, env_begin, ...)
  let env_begin = a:0 == 0 ? ('begin_' . a:env_begin) : a:env_begin
  let env_end   = a:0 == 0 ? ('end_'   . a:env_begin) : a:1

  exec printf('syn region %s matchgroup=lyxEnvBegin start=''\\%s\>'' matchgroup=lyxEnvEnd end=''\\%s\>'' contains=@texGroup,@lyxEnvGroup,lyxOption', a:group, env_begin, env_end)
endfunction

syn clear texMatcher texParen texError

call s:SynEvn('lyxBody'    , 'body')
call s:SynEvn('lyxPreamble', 'preamble')
call s:SynEvn('lyxHeader'  , 'header')
call s:SynEvn('lyxDocument', 'document')
call s:SynEvn('lyxBranch'  , 'branch', 'end_branch')
call s:SynEvn('lyxLayout'  , 'layout')
call s:SynEvn('lyxInset'   , 'inset')
call s:SynEvn('lyxDeeper'  , 'deeper')

syn match lyxOption '\\\%(lyxformat\|textclass\|begin_local_layout\|begin_modules\|begin_removed_modules\|options\|use_default_options\|master\|language\|inputencoding\|graphics\|font_roman\|font_sans\|font_typewriter\|font_default_family\|font_sc\|font_osf\|font_sf_scale\|font_tt_scale\|font_cjk\|paragraph_separation\|defskip\|quotes_language\|papersize\|use_geometry\|use_amsmath\|use_esint\|cite_engine\|use_bibtopic\|tracking_changes\|output_changes\|end_bran\|selected\|color\|author\|paperorientation\|paperwidth\|paperheight\|leftmargin\|topmargin\|rightmargin\|bottommargin\|headheight\|headsep\|footskip\|columnsep\|paperfontsize\|papercolumns\|listings_params\|papersides\|paperpagestyle\|bullet\|bulletLaTeX\|secnumdepth\|tocdepth\|spacing\|float_placement\|pdf_\w\+\|use_hyperref\)\>' nextgroup=lyxParam skipwhite

syn match lyxParam   '.\+$' contained
syn match lyxEnvName '\%(\\begin_\S\+\s\)\@<=\w\+\%(\s\+\w\+\)*' containedin=@lyxEnvGroup contained

syn match lyxUrl  contains=@NoSpell containedin=@lyxEnvGroup
      \ "\<\%(\%(\%(https\=\|file\|ftp\|gopher\)://\|\%(mailto\|news\):\)[^[:space:]'\"<>]\+\|www[[:alnum:]_-]*\.[[:alnum:]_-]\+\.[^[:space:]'\"<>]\+\)[[:alnum:]/]"

syn match lyxFilenameLabel '\<filename\>' contained containedin=lyxInset nextgroup=lyxFilename skipwhite
syn match lyxFilename '.\+$' contained


hi default link lyxShebang   Comment
hi default link lyxOption    Define
hi default link lyxParam     Type
hi default link lyxEnvBegin  Function
hi default link lyxEnvName   Label
hi default link lyxEnvEnd    Function
hi default link lyxUrl       Underlined
hi default link lyxFilename  Underlined

let b:current_syntax = 'lyx'
