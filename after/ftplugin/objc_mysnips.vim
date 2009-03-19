if !exists('loaded_snips') || exists('s:did_objc_snips')
	fini
en
let s:did_objc_snips = 1
let snippet_filetype = 'objc'

" #import <...>
exe 'Snipp imp #import <${1:Cocoa/Cocoa.h}>${2}'
" #import "..."
exe 'Snipp Imp #import "${1:`Filename()`.h}"${2}'
" @selector(...)
exe 'Snipp sel @selector(${1:method}:)${3}'
" NSLog(...)
exe 'Snipp log NSLog(@"${1}"${2});${3}'
" Class
exe "Snipp objc @interface ${1:`Filename('', 'object')`} : ${2:NSObject}\n{\n}\n@end\n\n@implementation $1\n- (id) init\n{\n\tif (self = [super init])"
\."\n\t{${3}\n\t}\n\treturn self\n}\n@end"
" Class Interface
exe "Snipp clh @interface ${1:ClassName} : ${2:NSObject}\n{${3}\n}\n${4}\n@end"
exe 'Snipp ibo IBOutlet ${1:NSSomeClass} *${2:$1};'
" Category
exe "Snipp cat @interface ${1:NSObject} (${2:Category})\n@end\n\n@implementation $1 ($2)\n${3}\n@end"
" Category Interface
exe "Snipp cath @interface ${1:NSObject} (${2:Category})\n${3}\n@end"
" NSArray
exe 'Snipp array NSMutableArray *${1:array} = [NSMutable array];${2}'
" NSDictionary
exe 'Snipp dict NSMutableDictionary *${1:dict} = [NSMutableDictionary dictionary];${2}'
" NSBezierPath
exe 'Snipp bez NSBezierPath *${1:path} = [NSBezierPath bezierPath];${2}'
" Method
exe "Snipp m - (${1:id})${2:method}\n{\n\t${3:return self;}\n}"
" Method declaration
exe "Snipp md - (${1:id})${2:method};${3}"
" Class Method
exe "Snipp M + (${1:id})${2:method}\n{${3}\n\treturn nil;\n}"
" Sub-method (Call super)
exe "Snipp sm - (${1:id})${2:method}\n{\n\t[super $2];${3}\n\treturn self;\n}"
" Method: Initialize
exe "Snipp I + (void) initialize\n{\n\t[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWIthObjectsAndKeys:\n\t\t${1}@\"value\", @\"key\",\n\t\tnil]];\n}"
" Accessor Methods For:
" Object
exe "Snipp objacc - (${1:id})${2:thing}\n{\n\treturn $2;\n}\n\n- (void) set$2:($1)\n{\n\t$1 old$2 = $2;\n\t$2 = [aValue retain];\n\t[old$2 release];\n}"
exe "Snipp forarray unsigned int\t${1:object}Count = [${2:array} count];\n\nfor (unsigned int index = 0; index < $1Count; index++)\n{\n\t${3:id}\t$1 = [$2 $1AtIndex:index];\n\t${4}\n}"
" IBOutlet
" @property (Objective-C 2.0)
exe "Snipp prop @property (${1:retain}) ${2:NSSomeClass} *${3:$2};${4}"
" @synthesize (Objective-C 2.0)
exe "Snipp syn @synthesize ${1:NSSomeClass};${2}"
" [[ alloc] init]
exe 'Snipp alloc [[${1:foo} alloc] init]${2};${3}'
" retain
exe 'Snipp ret [${1:foo} retain];${2}'
" release
exe 'Snipp rel [${1:foo} release];${2}'

" C snippets
" ====================================================================== 
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
