" Vim syntax file
" Language:	WikidPad (v2.0)
" Maintainer:	Frank Chang <frank.nevermind AT gmail.com>
" Reference: http://wikidpad.python-hosting.com/

if version < 600
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syn spell toplevel

syn match wikiBold   '\*\%(\S\)\@=\%(\%([^\\]\|\\.\)\{-1,}\)\*'
syn match wikiItalic '\<_\%(\%([^\\]\|\\.\)\{-1,}\)_\>'

syn region wikiHeading4 matchgroup=wikiHeadingPrefix start='^++++\%(+\)\@!\s\+' end='$' keepend
syn region wikiHeading3 matchgroup=wikiHeadingPrefix start='^+++\%(+\)\@!\s\+'  end='$' keepend
syn region wikiHeading2 matchgroup=wikiHeadingPrefix start='^++\%(+\)\@!\s\+'   end='$' keepend
syn region wikiHeading1 matchgroup=wikiHeadingPrefix start='^+\%(+\)\@!\s\+'    end='$' keepend

syn match wikiBullet        '^\s*\*\s\+'
syn match wikiNumericBullet '^\s*\%(\d\+\.\)*\%(\d\+\)\.\s\+'

syn match wikiWikiWord      '\<\%(\~\)\@<!\%([A-Z\xc0-\xde\x8a-\x8f]\+[a-z\xdf-\xff\x9a-\x9f]\+[A-Z\xc0-\xde\x8a-\x8f]\+[a-zA-Z0-9\xc0-\xde\x8a-\x8f\xdf-\xff\x9a-\x9f]*\|[A-Z\xc0-\xde\x8a-\x8f]\{2,}[a-z\xdf-\xff\x9a-\x9f]\+\)\>' nextgroup=wikiWikiWordEditor
syn match wikiWikiWord      '\[[a-zA-Z0-9_ \t-]\{-1,}\%(\%(\s*|\)\%(\%([^\\]\|\\.\)\{-1,}\)\)\?\]' nextgroup=wikiWikiWordEditor

syn match wikiWikiWordEditor '#\%(\%(\%(#.\)\|[^ \t\n#]\)\+\)\|!\%\([A-Za-z0-9_]\+\)' contained

syn match wikiFootnote '\[[0-9]\{-1,}\]'
syn match wikiProperty '\[\s*\%([a-zA-Z0-9_.-]\{-1,}\)\s*[=:]\s*\%([a-zA-Z0-9_ \t:;,.!?#/|-]\{-1,}\)\]'

syn match wikiUrl '\%(\%(wiki\|file\|https\?\|ftp\|rel\)://\|mailto:\)\%(\%([.,;:!?)]\+[" \t]\)\@![^" \t<>]\)*\%(>\S\+\)\?'

syn match wikiTitledUrl '\[\%(\%(wiki\|file\|https\?\|ftp\|rel\)://\|mailto:\)\%(\%([.,;:!?)]\+[" \t]\)\@![^" \t<>]\)*\%(>\S\+\)\?\%(\s*|\)\%(\%([^\\]\|\\.\)\{-1,}\)\?\]'

syn match wikiTitledUrlTitle '\%(\s*|\)\@<=\%(\%([^\\]\|\\.\)\{-1,}\)\?\%(\]\)\@=' contained containedin=wikiTitledUrl

syn region wikiInsertionError matchgroup=wikiDelimiter start='\[:\s*\%(\w[a-zA-Z0-9_.-]*\)\s*:\s*' end='\]' contains=wikiInsertionValue

syn match wikiDelimiter $\[:\s*\%(\w[a-zA-Z0-9_.-]*\)\s*:\s*\%(\%(""\)\+\|\%(''\)\+\|\%(//\)\+\|\%(\\\\\)\+\)\]$

syn match wikiInsertionValue '\w[a-zA-Z0-9_ \t;,.!?#/|-]*' contained nextgroup=wikiInsertionAppendix
syn region wikiInsertionValue matchgroup=wikiDelimiter start=$\z("\+\|'\+\|/\+\|\\\+\)$ end='\z1' contained nextgroup=wikiInsertionDelimiter,wikiInsertionAppendix2

syn match wikiInsertionDelimiter ';' contained nextgroup=wikiInsertionAppendix

syn match wikiInsertionAppendix '\s*\w[A-Za-z0-9_ \t;,.!?#/|-]*' contained nextgroup=wikiInsertionDelimiter,wikiInsertionAppendix2
syn region wikiInsertionAppendix2 matchgroup=wikiInsertionDelimiter start=$;\s*\z("\+\|'\+\|/\+\|\\\+\)$ end='\z1' contained nextgroup=wikiInsertionDelimiter,wikiInsertionAppendix2

syn match wikiHtmlTag '<[A-Za-z][A-Za-z0-9]*\%(/\| [^>]*\)\?>'
syn match wikiHtmlTag '</\?[A-Za-z][A-Za-z0-9]*>'

syn include @Python syntax/python.vim
syn region wikiScript matchgroup=wikiScriptDelimiter start='<%' end='%>' contains=@Python

syn match wikiToDoKeyword '\<\%(todo\|done\|wait\|action\|track\|issue\|question\|project\)\%(\.[^: \t]\+\)\?\%(:\)\@=' nextgroup=wikiToDo

syn match wikiToDo '\%([^|]\+\|\\|\)\+' contained contains=wikiToDoSetting,wikiToDoDate1,wikiToDoDate2

syn match wikiToDoSetting '\%(^\|\%(\s\)\@<=\)[!#@]\w\+\%($\|\s\+\)' contained
syn match wikiToDoDate1 '\%(^\|\%(\s\)\@<=\)\d\+/\d\+/\d\+\%(T\d\+:\d\+\)\?\%(-\d\+/\d\+/\d\+\%(T\d\+:\d\+\)\?\)\?\%($\|\s\+\)' contained
syn match wikiToDoDate2 '\%(^\|\%(\s\)\@<=\)\%(-\d\+/\d\+/\d\+\%(T\d\+:\d\+\)\?\)\%($\|\s\+\)' contained

syn match wikiHorizLine  '----\+'
syn match wikiAnchor  '^\s*anchor:\s*\w\+$'

syn cluster wikiHighlighting contains=wikiBold,wikiItalic,wikiWikiWord,wikiEscape,wikiUrl,wikiTitledUrl

syn region wikiSuppressHighlighting matchgroup=wikiDelimiter start='^\s*<<\s*$' end='^\s*>>\s*$'
syn region wikiTable matchgroup=wikiDelimiter start='^\s*<<|t\?\s*$' end='^\s*>>\s*$' contains=@wikiHighlighting,wikiTableCellDelimiter
syn region wikiPreBloc matchgroup=wikiDelimiter start='^\s*<<pre\s*$' end='^\s*>>\s*$'
syn match wikiTableCellDelimiter '|' contained
syn match wikiEscape '\\.'


hi def wikiBold    cterm=bold    gui=bold
hi def wikiItalic  ctermfg=Green gui=italic
hi def link wikiHeading1           Todo
hi def link wikiHeading2           wikiHeading1
hi def link wikiHeading3           wikiHeading2
hi def link wikiHeading4           wikiHeading3
hi def link wikiHeadingPrefix      Label
hi def link wikiUrl                Underlined
hi def link wikiTitledUrl          Comment
hi def link wikiTitledUrlTitle     Underlined
hi def link wikiBullet             Operator
hi def link wikiNumericBullet      Operator
hi def link wikiWikiWord           Function
hi def link wikiWikiWordEditor     Statement
hi def link wikiFootnote           Tag   
hi def link wikiProperty           Tag
hi def link wikiInsertionError     Error
hi def link wikiInsertionValue     String
hi def link wikiInsertionAppendix  String
hi def link wikiInsertionAppendix2 wikiInsertionAppendix
hi def link wikiHtmlTag            Identifier
hi def link wikiDelimiter          Delimiter
hi def link wikiInsertionDelimiter wikiDelimiter
hi def link wikiScriptDelimiter    wikiDelimiter
hi def link wikiToDoKeyword        Keyword
hi def link wikiToDoSetting        Tag
hi def link wikiToDoDate1          Identifier
hi def link wikiToDoDate2          Identifier
hi def link wikiHorizLine          Constant
hi def link wikiAnchor             Define
hi def link wikiPreBloc            Comment
hi def link wikiTableCellDelimiter Structure

let b:current_syntax = 'wikidpad'
