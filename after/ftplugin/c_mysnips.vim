if !exists('loaded_snips') || exists('s:did_c_snips')
	fini
en
let s:did_c_snips = 1
let snippet_filetype = 'c'

" main()
exe "Snipp main int\nmain (int argc, char* argv[])\n{\n\t${1}\n\treturn 0;\n}"
" #include <...>
exe 'Snipp Inc #include <${1:stdio.h}>${2}'
" #include "..."
exe 'Snipp inc #include "${1:`Filename("$1.h")`}"${2}'
" #ifndef ... #define ... #endif
exe "Snipp def #ifndef $1\n#define ${1:SYMBOL} ${2:value}\n#endif${3}"
" Header Include-Guard
exe "Snipp once #ifndef ${1:`toupper(substitute(expand(\"%:t:r\"), '\\W\+\\|\\([a-z]\\)\\@<=\\([A-Z]\\)', '_&', 'g')) . \"_H\"`}\n"
	\ ."#define $1\n\n${2}\n\n#endif /* $1 */"
" If Condition
exe "Snipp if if (${1:/* condition */}) {\n\t${2:/* code */}\n}"
exe "Snipp el else {\n\t${1}\n}"
" Tertiary conditional
exe 'Snipp t ${1:/* condition */} ? ${2:a} : ${3:b}'
" Do While Loop
exe "Snipp do do {\n\t${2:/* code */}\n}\nwhile (${1:/* condition */});"
" While Loop
exe "Snipp wh while (${1:/* condition */}) {\n\t${2:/* code */}\n}"
" For Loop
exe "Snipp for for (${3:i} = ${2:0}; $3 < ${1:count}; ${4:++}$3) {\n\t${5:/* code */}\n}"
" Function
exe "Snipp func ${1:void}\n${2:function_name}(${3})\n{\n\t${4:/* code */}\n}"
" Typedef
exe 'Snipp td typedef ${1:int} ${2:MyCustomType};'
" Struct
exe "Snipp st struct ${1:`Filename('$1_t', 'name')`} {\n\t${2:/* data */}\n}${3: /* optional variable list */};${4}"
" Typedef struct
exe "Snipp tds typedef struct ${2:$1 }{\n\t${3:/* data */}\n} ${1:`Filename('$1_t', 'name')`};"
" printf
" unfortunately version this isn't as nice as TextMates's, given the lack of a
" dynamic `...`
exe 'Snipp pr printf("${1:%s}\n"${2});${3}'
" fprintf (again, this isn't as nice as TextMate's version, but it works)
exe 'Snipp fpr fprintf(${1:stderr}, "${2:%s}\n"${3});${4}'
