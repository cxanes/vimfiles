" Vim syntax file
" Languages:	Eyapp and Yapp
" Maintainer:	Frank Chang <frank.nevermind AT gmail.com>
" Last Change:	Nov 13, 2009
" Version:	1
" Note:        Modified from yacc.vim and Casiano's eyapp.vim
"              <http://www.vim.org/scripts/script.php?script_id=2453>

" ---------------------------------------------------------------------
" this version of syntax/eyapp.vim requires 6.0 or later
if version < 600
 finish
endif
if exists("b:current_syntax")
 syntax clear
endif

" ---------------------------------------------------------------------
"  Folding Support {{{1
if has("folding")
 com! -nargs=+ HiFold	<args> fold
else
 com! -nargs=+ HiFold	<args>
endif

" ---------------------------------------------------------------------
syn	cluster eyappCode contains=eyappCodeBlock,eyappCodeDelim

" Set variable eyapp_only if you only want to emphasize grammar vs actions {{{1
if !exists("g:eyapp_only")
 syn include @eyappCode	<sfile>:p:h/perl.vim

 " I use official perl.vim provided by Vim itself, since the version I use has
 " some problem <http://www.vim.org/scripts/script.php?script_id=2300>.
 " syn	include @eyappCode	$VIMRUNTIME/syntax/perl.vim
endif

syn	clear perlFunctionName
if exists("perl_want_scope_in_variables")
  syn match  perlFunctionName	"\\\=&\$*\(\I\i*\)\=\(\(::\|'\)\I\i*\)*\>" contains=perlPackageRef nextgroup=perlVarMember,perlVarSimpleMember contained
else
  syn match  perlFunctionName	"\\\=&\$*\(\I\i*\)\=\(\(::\|'\)\I\i*\)*\>" nextgroup=perlVarMember,perlVarSimpleMember contained
endif

" ---------------------------------------------------------------------
"  Eyapp Clusters: {{{1
syn cluster eyappInitCluster	contains=eyappKey,eyappKeyActn,eyappBrkt,eyappType,eyappString,eyappUnionStart,eyappHeader2,eyappComment
syn cluster eyappRulesCluster	contains=eyappNonterminal,eyappString,eyappComment

" ---------------------------------------------------------------------
"  Eyapp Sections: {{{1
HiFold syn	region	eyappInit	start='.'ms=s-1,rs=s-1	matchgroup=eyappSectionSep	end='^%%$'me=e-2,re=e-2	contains=@eyappInitCluster	nextgroup=eyappRules	skipwhite skipempty contained
HiFold syn	region	eyappInit2	start='\%^\_.'ms=s-1,rs=s-1	matchgroup=eyappSectionSep	end='^%%$'me=e-2,re=e-2	contains=@eyappInitCluster	nextgroup=eyappRules	skipwhite skipempty
HiFold syn	region	eyappHeader2	matchgroup=eyappSep	start="^\s*\zs%{"	end="^\s*%}"		contains=@eyappCode	nextgroup=eyappInit	skipwhite skipempty contained
HiFold syn	region	eyappHeader	matchgroup=eyappSep	start="^\s*\zs%{"	end="^\s*%}"		contains=@eyappCode	nextgroup=eyappInit	skipwhite skipempty
HiFold syn	region	eyappRules	matchgroup=eyappSectionSep	start='^%%$'		end='^%%$'me=e-2,re=e-2	contains=@eyappRulesCluster	nextgroup=eyappEndCode	skipwhite skipempty contained
HiFold syn	region	eyappEndCode	matchgroup=eyappSectionSep	start='^%%$'		end='\%$'		contains=@eyappCode	contained

syn	match	eyappSectionSep '\%^%%$'me=e-2	nextgroup=eyappRules	skipwhite skipempty

" ---------------------------------------------------------------------
" Eyapp Commands: {{{1
syn	match	eyappDelim	"[:|]"	contained
syn	match	eyappOper	"@\d\+"	contained

syn	match	eyappKey	"^\s*%\(token\|semantic\|syntactic\|type\|left\|right\|start\|ident\|nonassoc\|tree\|metatree\|strict\)\>"	contained
syn	match	eyappKey	"\s%\(prec\|expect|name|tree|metatree|begin\)\>"	contained
syn	match	eyappKey	"\$\(<[a-zA-Z_][a-zA-Z_0-9]*>\)\=[\$0-9]\+"	contained
syn	keyword	eyappKeyActn	YYErrok yyclearin YYAbort error YYParse YYData YYNberr YYRecovering YYAbort YYAccept YYError YYSemval YYLhs	contained
syn	keyword	eyappKeyActn	YYRuleindex YYRightside YYIsterm YYIssemantic YYName YYPrefix YYAccessors YYFilename YYBypass YYBypassrule Y	contained
syn	keyword	eyappKeyActn	YFirstline YYBuildingTree YYBuildAST YYBuildTS YYCurtok YYCurval YYExpect YYLexer	contained

syn	match	eyappKey        "%defaultaction"	skipwhite skipnl nextgroup=eyappAction	contained
syn	match	eyappUnionStart	"^%union"	skipwhite skipnl nextgroup=eyappUnion	contained
HiFold syn	region	eyappUnion	matchgroup=eyappCurly start="{" matchgroup=eyappCurly end="}" contains=@eyappCode	contained
syn	match	eyappBrkt	"[<>]"	contained
syn	match	eyappType	"<[a-zA-Z_][a-zA-Z0-9_]*>"	contains=eyappBrkt	contained

HiFold syn	region	eyappNonterminal	start="^\s*\a\w*\ze\_s*\(/\*\_.\{-}\*/\)\=\_s*:"	matchgroup=eyappDelim end=";"	matchgroup=eyappSectionSep end='^%%$'me=e-2,re=e-2 contains=eyappAction,eyappDelim,eyappString,eyappComment,eyappAttribute,eyappModifier	contained
syn	region	eyappComment	start="/\*"	end="\*/"
syn	match	eyappComment	"#.*"	contained
syn	match	eyappString	"'\([^\\']\|\\.\)*'"	contained

syn match	eyappModifier   "[+*?()<>%]"	contained 
syn match	eyappAttribute  "\.\s*[a-zA-Z_][a-zA-Z0-9_]*"	contained

" ---------------------------------------------------------------------
" I'd really like to highlight just the outer {}.  Any suggestions??? {{{1
syn	match	eyappCurlyError	"[{}]"
HiFold syn	region	eyappAction	matchgroup=eyappCurly start="{" end="}" contains=@eyappCode	contained

" ---------------------------------------------------------------------
" Extra syntax for Perl
syn	region	eyappCodeBlock	matchgroup=eyappCodeCurly start="{" end="}" contains=@eyappCode	contained
syn	match	eyappCodeDelim	";"	contained

" ---------------------------------------------------------------------
" Eyapp synchronization: {{{1
syn sync fromstart

" ---------------------------------------------------------------------
" Define the default highlighting. {{{1
if !exists("did_eyapp_syn_inits")
  command -nargs=+ HiLink hi def link <args>

  " Internal eyapp highlighting links {{{2
  HiLink eyappBrkt	eyappStmt
  HiLink eyappKey	eyappStmt
  HiLink eyappOper	eyappStmt
  HiLink eyappUnionStart	eyappKey

  " External eyapp highlighting links {{{2
  HiLink eyappComment	Comment
  HiLink eyappCurly	Delimiter
  HiLink eyappCurlyError	Error
  HiLink eyappNonterminal	Function
  HiLink eyappDelim	Delimiter
  HiLink eyappKeyActn	Special
  HiLink eyappSectionSep	Todo
  HiLink eyappSep	Delimiter
  HiLink eyappString	String
  HiLink eyappStmt	Statement
  HiLink eyappType	Type
  HiLink eyappModifier	Special

  " since Bram doesn't like my Delimiter :| {{{2
  HiLink Delimiter	Type

  delcommand HiLink
endif

" ---------------------------------------------------------------------
"  Cleanup: {{{1
delcommand HiFold
let b:current_syntax = "eyapp"

" ---------------------------------------------------------------------
"  Modelines: {{{1
" vim: ts=15 fdm=marker
