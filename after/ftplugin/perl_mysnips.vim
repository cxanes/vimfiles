if !exists('loaded_snips') || exists('s:did_perl_snips')
	fini
en
let s:did_perl_snips = 1
let snippet_filetype = 'perl'

" #!/usr/bin/perl
exe "Snipp #! #!/usr/bin/perl\n"
" Hash Pointer
exe 'Snipp .  =>'
" Function
exe "Snipp sub sub ${1:function_name}\n{\n\t${2:#body ...}\n}"
" Conditional
exe "Snipp if if (${1}) {\n\t${2:# body...}\n}"
" Conditional else
exe "Snipp el else {\n\t${1}\n}"
" Conditional elsif
exe "Snipp elif elsif (${1}) {\n\t${2:# body...}\n}"
" Conditional One-line
exe 'Snipp xif ${1:expression} if ${2:condition};${3}'
" Unless conditional
exe "Snipp unless unless (${1}) {\n\t${2:# body...}\n}"
" Unless conditional One-line
exe 'Snipp xunless ${1:expression} unless ${2:condition};${3}'
" Try/Except
exe "Snipp eval eval {\n\t${1:# do something risky...}\n};\nif ($@) {\n\t${2:# handle failure...}\n}"
" While Loop
exe "Snipp wh while (${1}) {\n\t${2:# body...}\n}"
" While Loop One-line
exe "Snipp xwh ${1:expression} while ${2:condition};${3}"
" For Loop
exe "Snipp for for (my $${3:var} = ${2:0}; $$3 < ${1:count}; ${4:++}$$3) {\n\t${5:# body...}\n}"
" Foreach Loop
exe "Snipp fore foreach my $${1:x} (@${2:array}) {\n\t${3:# body...}\n}"
" Foreach Loop One-line
exe 'Snipp xfore ${1:expression} foreach @${2:array};${3}'
" Package
exe "Snipp cl package ${1:ClassName};\n\nuse base qw(${2:ParentClass});\n\nsub new {\n\tmy $class = shift;\n\t$class = ref $class if ref $class;\n\tmy $self = bless {}, $class;\n\t$self;\n}\n\n1;${3}"
" Read File
exe "Snipp slurp my $${1:var};\n{ local $/ = undef; local *FILE; open FILE, \"<${2:file}\"; $$1 = <FILE>; close FILE }${2}"
exe "Snipp head #!/usr/bin/perl\n\nuse warnings;\nuse strict;\n${1}"
exe "Snipp headn #!/usr/bin/perl\n\nuse 5.010;\nuse warnings;\nuse strict;\n${1}"