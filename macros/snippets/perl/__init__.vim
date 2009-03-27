if exists('b:load_perl_snippets') | finish | endif
let b:load_perl_snippets = 1
ru syntax/snippet.vim

"=================================================
" Functions {{{
"-------------------------------------------------
function! snippets#perl#__init__#Select(trigger, replaced, prompt, choices) "{{{
	let [line, col] = [line('.'), col('.')]
	if col >= col('$')
		let col = col('$') - 1
	endif

	if has('syntax_items') 
			 \ && synIDattr(synID(line, col, 0), 'name') =~? 'string\|comment'
		return a:trigger . SnippetReturnKey()
	else
		let tag = SetLocalTagVars()
		if empty(a:replaced)
			let [pre_replaced, post_replaced] = [a:trigger, '']
		elseif type(a:replaced) == type([])
			let [pre_replaced, post_replaced] = [get(a:replaced, 0, a:trigger), get(a:replaced, 1, '')]
		else
			let [pre_replaced, post_replaced] = [string(a:replaced), '']
		endif

		return pre_replaced . SnippetSelect(a:prompt, a:choices) . post_replaced . tag[0] . tag[2]
	endif
endfunction
"}}}
function! snippets#perl#__init__#FileTest(trigger) "{{{
  let choices = 
        \ [
        \     ['(-r) File is readable by effective uid/gid.'                            ,'-r'],
        \     ['(-w) File is writable by effective uid/gid.'                            ,'-w'],
        \     ['(-x) File is executable by effective uid/gid.'                          ,'-x'],
        \     ['(-o) File is owned by effective uid.'                                   ,'-o'],
        \     ['(-R) File is readable by real uid/gid.'                                 ,'-R'],
        \     ['(-W) File is writable by real uid/gid.'                                 ,'-W'],
        \     ['(-X) File is executable by real uid/gid.'                               ,'-X'],
        \     ['(-O) File is owned by real uid.'                                        ,'-O'],
        \     ['(-e) File exists.'                                                      ,'-e'],
        \     ['(-z) File has zero size (is empty).'                                    ,'-z'],
        \     ['(-s) File has nonzero size (returns size in bytes).'                    ,'-s'],
        \     ['(-f) File is a plain file.'                                             ,'-f'],
        \     ['(-d) File is a directory.'                                              ,'-d'],
        \     ['(-l) File is a symbolic link.'                                          ,'-l'],
        \     ['(-p) File is a named pipe (FIFO), or Filehandle is a pipe.'             ,'-p'],
        \     ['(-S) File is a socket.'                                                 ,'-S'],
        \     ['(-b) File is a block special file.'                                     ,'-b'],
        \     ['(-c) File is a character special file.'                                 ,'-c'],
        \     ['(-t) Filehandle is opened to a tty.'                                    ,'-t'],
        \     ['(-u) File has setuid bit set.'                                          ,'-u'],
        \     ['(-g) File has setgid bit set.'                                          ,'-g'],
        \     ['(-k) File has sticky bit set.'                                          ,'-k'],
        \     ['(-T) File is an ASCII text file (heuristic guess).'                     ,'-T'],
        \     ['(-B) File is a "binary" file (opposite of -T).'                         ,'-B'],
        \     ['(-M) Script start time minus file modification time, in days.'          ,'-M'],
        \     ['(-A) Same for access time.'                                             ,'-A'],
        \     ['(-C) Same for inode change time (Unix, may differ for other platforms)' ,'-C'],
        \ ]

	return snippets#perl#__init__#Select(a:trigger, ['', ' '], 'Select File Test: ', choices)
endfunction
"}}}
"}}}
"=================================================
" vim: set fdm=marker :
