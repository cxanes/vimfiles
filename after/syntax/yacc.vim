" Yacc after syntax file
"
syn region yaccInclude matchgroup=yaccSep start="^%{" end="%}" contains=ALLBUT,@yaccActionGroup
syn region yaccSection1 transparent matchgroup=yaccSectionSep start='^[ \t]*%%' end='\%$' contains=TOP
syn region yaccSection2 transparent contained containedin=yaccSection1 matchgroup=yaccSectionSep start='^[ \t]*%%' end='\%$' contains=TOP,yaccSection1

syn match	yaccKey	"^\s*%\(debug\|defines\|destructor\|file-prefix\|locations\|name-prefix\|no-parser\|no-lines\|output\|pure-parser\|require\|token-table\|verbose\|yacc\)\>"

syn cluster	yaccUnionGroup add=cPreCondit,cInclude,cDefine,cPreProc	
