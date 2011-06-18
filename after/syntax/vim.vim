" Vim after syntax file

" Operators: {{{1
" =========
syn cluster vimOperGroup	remove=vimOperParen add=vimFuncVar,vimFunc,vimEnvvar,vimRegvar,vimOptvar
syn match vimOper "\<isnot\>\|\<is\>" skipwhite nextgroup=vimString,vimSpecFile

" http://tech.groups.yahoo.com/group/vimdev/message/49735
" Highlight the balanced parentheses in different line.
syn clear  vimOperParen

syn region vimOperParen matchgroup=vimOper start="("  end=")" matchgroup=vimParenSep end="\%(^\s*\%([^[:blank:]\\]\|$\)\)\@=" contains=@vimOperGroup containedin=vimOperParen
syn region vimOperParen matchgroup=vimOper start="\[" end='\]' matchgroup=NONE end="\%(^\s*\%([^[:blank:]\\]\|$\)\)\@=" contains=@vimOperGroup containedin=vimOperParen
syn region vimOperParen	matchgroup=vimSep  start="\%({\)\@<!{\%({\)\@!"  end='}' matchgroup=vimSep end="\%(^\s*\%([^[:blank:]\\]\|$\)\)\@=" contains=@vimOperGroup containedin=vimOperParen nextgroup=vimVar,vimFuncVar

if !exists("g:vimsyn_noerror")
  syn clear  vimOperError
  syn match  vimOperError ")"
  syn match  vimOperError "]"
  syn match  vimOperError "\%(}\)\@<!}\%(}\)\@!"
endif

" Echo and Execute {{{1
" ================
syn clear  vimEcho
syn region vimEcho oneline excludenl matchgroup=vimCommand start="\<ec\%[ho]\>" skip="\(\\\\\)*\\|" end="$\||" contains=vimFunc,vimFuncVar,vimString,vimVar,vimOperParen,vimOperError

syn clear vimExecute
syn region vimExecute	oneline excludenl matchgroup=vimCommand start="\<exe\%[cute]\>" skip="\(\\\\\)*\\|" end="$\||\|<[cC][rR]>" contains=vimFunc,vimFuncVar,vimIsCommand,vimString,vimOper,vimVar,vimNotation,vimOperParen,vimNumber,vimOperError

" Embedded Syntax {{{1
" ===============
" The original vim syntax script has some problems for embedded script highlighting
if !hlexists('vimPythonRegion')
  let s:pythonpath= split(globpath(&rtp,"syntax/python.vim"), "\n")
  if (g:vimsyn_embed =~ 'P' && has("python")) && !empty(s:pythonpath) && filereadable(s:pythonpath[0])
    unlet! b:current_syntax
    exe "syn include @vimPythonScript ".fnameescape(s:pythonpath[0])
    let b:current_syntax = 'vim'
    if exists("g:vimsyn_folding") && g:vimsyn_folding =~ 'P'
      syn region vimPythonRegion fold matchgroup=vimScriptDelim start=+py\%[thon]3\=\s*<<\s*\z(.*\)$+ end=+^\z1$+	contains=@vimPythonScript
      syn region vimPythonRegion fold matchgroup=vimScriptDelim start=+py\%[thon]3\=\s*<<\s*$+ end=+\.$+		contains=@vimPythonScript
    else
      syn region vimPythonRegion matchgroup=vimScriptDelim start=+py\%[thon]3\=\s*<<\s*\z(.*\)$+ end=+^\z1$+		contains=@vimPythonScript
      syn region vimPythonRegion matchgroup=vimScriptDelim start=+py\%[thon]3\=\s*<<\s*$+ end=+\.$+		contains=@vimPythonScript
    endif
    syn cluster vimFuncBodyList	add=vimPythonRegion
  else
    syn region vimEmbedError start=+py\%[thon]3\=\s*<<\s*\z(.*\)$+ end=+^\z1$+
    syn region vimEmbedError start=+py\%[thon]3\=\s*<<\s*$+ end=+\.$+
  endif
  unlet s:pythonpath
endif

if hlexists('vimPythonRegion')
  syn region vimPythonRegion matchgroup=vimScriptDelim start=+py\%[thon]3\=\s\%(\s*<<\)\@!+ end=+\n+ contains=@vimPythonScript oneline
endif

" Functions {{{1
" =========
syn cluster vimFuncBodyList remove=vimFuncName add=vimPythonRegion,vimRubyRegion,vimPerlRegion,vimUserCmd,vimSyntax,vimHighlight,vimEnvvar,vimRegvar,vimOptvar,vimOperError,vimMenuCommand,vimAugroupKey

syn match vimFunction "\<fu\%[nction]!\=\s\+\%(\%(<[sS][iI][dD]>\|[Ss]:\|\u\|\%(\i\+#\)\+\i\)\i*\|g:\(\I\i*\.\)\+\I\i*\)\ze\s*("	contains=@vimFuncList nextgroup=vimFuncBody

" User Function Highlighting {{{1
" ==========================
syn clear vimFunc
syn match vimFunc	"\%(\%([gGsS]:\|<[sS][iI][dD]>\)\=\%([a-zA-Z0-9_.]\+\.\)*\I[a-zA-Z0-9_.]*\)\ze\s*("	contains=vimFuncName,vimUserFunc
syn match vimFunc "\C\<[a-z]\+\ze\s*(" contains=vimFuncName,vimExecute,vimCommand

" Norm {{{1
" ====
syn clear vimNorm
syn match vimNorm	"\<norm\%[al]!\=\>" skipwhite nextgroup=vimNormCmds

" Substitutions: {{{1
" =============
syn clear vimSubstFlags
syn match vimSubstFlags contained	"[&cegiInp#lr]\+"

" In-String Specials: {{{1
syn region vimString	oneline keepend	start=+[^a-zA-Z>!\\@]"+lc=1 skip=+\\\\\|\\"+ end=+"+	contains=@vimStringGroup
syn region vimString	oneline keepend	start=+[^a-zA-Z>!\\@]'+lc=1 end=+'+

" Maps {{{1
" ====
syn keyword vimMap unm[ap] nun[map] vu[nmap] xu[nmap] sunm[ap] ou[nmap] iu[nmap] lu[nmap] cu[nmap] skipwhite nextgroup=vimMapBang,vimMapMod,vimMapLhs

" Let {{{1
" ===
syn clear vimLet
syn keyword vimLet unl[et] skipwhite nextgroup=vimVar
syn keyword vimLet let     skipwhite nextgroup=vimVar,vimEnvvar,vimRegvar,vimOptvar

" Var {{{1
" ===
syn match vimRegvar	   '@[-"0-9a-zA-Z=*+~_/]\%(\%([^-"0-9a-zA-Z=*+~_/]\)\@=\|$\)' display

syn match vimOptvar    '&\I\%(:\|\I\)\@!' contains=vimOptvarErr display
syn match vimOptvar    '&\I\I\+\>'        contains=vimOptvarErr display
syn match vimOptvar    '&[a-z]\?:\I\+\>'  contains=vimOptvarErr display

syn match vimOptvarErr '&[^lg]\?:\I\+\>' display
syn match vimOptvarErr '\%(&\)\@<=\I\%(:\|\I\)\@!' display
syn match vimOptvarErr '\%(&[lg]:\)\@<=\I\+' contains=vimOption display
syn match vimOptvarErr '\%(&\)\@<=\I\I\+'    contains=vimOption display

" Highlighting Settings {{{1
" ====================
hi link vimRegvar    PreProc
hi link vimOptvar    PreProc
hi link vimOptvarErr Error

" Menus {{{1
" =====
syn match vimMenuCommand '\%(\%(^\s*\d\+\)\@<=\|\<\)\%(am\%[enu]\|an\%[oremenu]\|aun\%[menu]\|cme\%[nu]\|cnoreme\%[nu]\|cunme\%[nu]\|ime\%[nu]\|inoreme\%[nu]\|iunme\%[nu]\|me\%[nu]\|nme\%[nu]\|nnoreme\%[nu]\|noreme\%[nu]\|nunme\%[nu]\|ome\%[nu]\|onoreme\%[nu]\|ounme\%[nu]\|unme\%[nu]\|vme\%[nu]\|vnoreme\%[nu]\|vunme\%[nu]\)\>' skipwhite nextgroup=@vimMenuList

hi link vimMenuCommand vimCommand

" Synchronizing {{{1
" =============
if !exists("g:vimsyn_minlines")
  syn sync minlines=100
endif

" vim: set fdm=marker : {{{1
