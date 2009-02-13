if exists('b:load_c_snippets')
  finish
endif
let b:load_c_snippets = 1

ru syntax/snippet.vim

"=================================================
" Snippets {{{
"-------------------------------------------------
Snippet inc #include "<{}>"<{}>
Snippet Inc #include <<{}>><{}>
"}}}
"=================================================
" Functions {{{
"-------------------------------------------------
function! snippets#c#__init__#Count(haystack, needle)
  let counter = 0
  let index = match(a:haystack, a:needle)
  while index > -1
    let counter = counter + 1
    let index = match(a:haystack, a:needle, index+1)
  endwhile
  return counter
endfunction

function! snippets#c#__init__#CArgList(count)
  " This returns a list of empty tags to be used as 
  " argument list placeholders for the call to printf
	let [st, delim, et] = SetLocalTagVars()
  if a:count == 0
    return ""
  else
    return repeat(', '.st.et, a:count)
  endif
endfunction
"}}}
"=================================================
" vim: set fdm=marker :
