" Ref: http://code2.0beta.co.uk/moose/svn/Moose-TM_bundle/trunk/Moose.tmbundle/Syntaxes/Moose.tmLanguage
if search('\<use\s\+Moose\>', 'nw')
  syn match perlMooseAttribute        '\<\%(has\)\>'
  syn match perlMooseRole             '\<\%(with\)\>'
  syn match perlMooseExtends          '\<\%(extends\)\>'
  syn match perlMooseMethodModifiers  '\<\%(before\|around\|after\)\>'
  syn match perlMooseMethodOverride   '\<\%(override\|super\)\>'
  syn match perlMooseMethodAugment    '\<\%(augment\|inner\)\>'
  syn match perlMooseType             '\<\%(type\|subtype\|enum\|class_type\)\>'
  syn match perlMooseTypeModifiers    '\<\%(as\|where\)\>'
  syn match perlMooseTypeCoercion     '\<\%(coerce\)\>'
  syn match perlMooseTypeCoercionModifiers '\<\%(via\|from\)\>'
  syn match perlMooseRoleRequires     '\<\%(requires\)\>'
  syn match perlMooseRoleExcludes     '\<\%(excludes\)\>'

  hi link perlMooseKeyword            Operator
  hi link perlMooseAttribute          perlMooseKeyword
  hi link perlMooseRole               perlMooseKeyword
  hi link perlMooseExtends            perlMooseKeyword
  hi link perlMooseMethodModifiers    perlMooseKeyword
  hi link perlMooseMethodOverride     perlMooseKeyword
  hi link perlMooseMethodAugment      perlMooseKeyword
  hi link perlMooseType               perlMooseKeyword
  hi link perlMooseTypeModifiers      perlMooseKeyword
  hi link perlMooseTypeCoercion       perlMooseKeyword
  hi link perlMooseTypeCoercionModifiers  perlMooseKeyword
  hi link perlMooseRoleRequires       perlMooseKeyword
  hi link perlMooseRoleExcludes       perlMooseKeyword
endif
