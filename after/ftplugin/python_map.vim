" -*- vim -*-
" FILE: python_map.vim
" LAST MODIFICATION: 2008-08-31 03:09:31
" (C) Copyright 2001-2005 Mikael Berthe <bmikael@lists.lilotux.net>
" Version: 1.13+

" ATTENTION: This script has been modified by Frank Chang.
"            ( frank.nevermind <AT> gmail.com )

" USAGE:
"
" Just source this script when editing Python files.
" Example: au FileType python source ~me/.vim/scripts/python.vim
" You can set the global variable "g:py_select_leading_comments" to 0
" if you don't want to select comments preceding a declaration (these
" are usually the description of the function/class).
" You can set the global variable "g:py_select_trailing_comments" to 0
" if you don't want to select comments at the end of a function/class.
" If these variables are not defined, both leading and trailing comments
" are selected.
" Example: (in your .vimrc) "let g:py_select_leading_comments = 0"
" You may want to take a look at the 'shiftwidth' option for the
" shift commands...
"
" REQUIREMENTS:
" vim (>= 7)
"
" Shortcuts:
"   ]t       -- Jump to beginning of block
"   ]e       -- Jump to end of block
"   ]<       -- Shift block to left
"   ]>       -- Shift block to right
"   ]c / [c  -- Jump next/previous class
"   ]f / [f  -- Jump next/previous function
"   ]<Up>    -- Jump to previous line with the same/lower indentation
"   ]<Down>  -- Jump to next line with the same/lower indentation
"   aB       -- Select a Block    (visual mode)
"   aF       -- Select a Function (visual mode)
"   aC       -- Select a Class    (visual mode)

" Only do this when not done yet for this buffer
if exists("b:loaded_py_ftplugin")
  finish
endif
let b:loaded_py_ftplugin = 1

" Mappings {{{
nmap <silent> <buffer> ]t  :PBoB<CR>
vmap <silent> <buffer> ]t  :<C-U>PBoB<CR>m'gv``
nmap <silent> <buffer> ]e  :PEoB<CR>
vmap <silent> <buffer> ]e  :<C-U>PEoB<CR>m'gv``

nmap <silent> <buffer> ]v  ]tV]e
nmap <silent> <buffer> ]<  ]tV]e<
vmap <silent> <buffer> ]<  <
nmap <silent> <buffer> ]>  ]tV]e>
vmap <silent> <buffer> ]>  >

vmap <silent> <buffer> aB  <C-\><C-N>]tV]e
vmap <silent> <buffer> aC  <ESC>:<C-U>call <SID>PythonSelectObject("class")<CR>
vmap <silent> <buffer> aF  <ESC>:<C-U>call <SID>PythonSelectObject("function")<CR>

nmap <silent> <buffer> ]<Up>    :call <SID>PythonNextLine(-1)<CR>
nmap <silent> <buffer> ]<Down>  :call <SID>PythonNextLine(1)<CR>
" You may prefer use <S-Up> and <S-Down>... :-)

" jump to next/previous class
nmap <silent> <buffer> ]c  :call <SID>PythonDec("class", 1)<CR>
nmap <silent> <buffer> [c  :call <SID>PythonDec("class", -1)<CR>

" jump to next/previous function
nmap <silent> <buffer> ]f  :call <SID>PythonDec("function", 1)<CR>
nmap <silent> <buffer> [f  :call <SID>PythonDec("function", -1)<CR>
"}}}

if exists('g:ft_python_menu')
  finish
endif
let g:ft_python_menu = 1

" Commands {{{
com! PBoB execute "normal ".PythonBoB(line('.'), -1, 1)."G"
com! PEoB execute "normal ".PythonBoB(line('.'), 1, 1)."G"
com! PyUpdateMenu call s:UpdateMenu()
"}}}
" Menu entries {{{
function! s:CreateMenu()
  nmenu <silent> &Python.Update\ IM-Python\ Menu 
      \:call <SID>UpdateMenu()<CR>
  nmenu &Python.-Sep1- :
  nmenu <silent> &Python.Beginning\ of\ Block<Tab>]t 
      \]t
  nmenu <silent> &Python.End\ of\ Block<Tab>]e 
      \]e
  nmenu &Python.-Sep2- :
  nmenu <silent> &Python.Shift\ Block\ Left<Tab>]< 
      \]<
  vmenu <silent> &Python.Shift\ Block\ Left<Tab>]< 
      \]<
  nmenu <silent> &Python.Shift\ Block\ Right<Tab>]> 
      \]>
  vmenu <silent> &Python.Shift\ Block\ Right<Tab>]> 
      \]>
  nmenu &Python.-Sep3- :
  nmenu <silent> &Python.Next\ Class<Tab>]c 
      \]c
  nmenu <silent> &Python.Previous\ Class<Tab>[c 
      \[c
  nmenu <silent> &Python.Next\ Function<Tab>]f 
      \]f
  nmenu <silent> &Python.Previous\ Function<Tab>[f 
      \[f
  nmenu &Python.-Sep4- :
  vmenu <silent> &Python.Select\ Block<Tab>aB 
      \aB
  vmenu <silent> &Python.Select\ Function<Tab>aF 
      \aF
  vmenu <silent> &Python.Select\ Class<Tab>aC 
      \aC
  nmenu &Python.-Sep5- :
  nmenu <silent> &Python.Previous\ Line\ wrt\ indent<Tab>]<up> 
      \]<Up>
  nmenu <silent> &Python.Next\ Line\ wrt\ indent<Tab>]<Down> 
      \]<Down>
endfunction

call s:CreateMenu()
"}}}

" Go to a block boundary (-1: previous, 1: next)
" If force_sel_comments is true, 'g:py_select_trailing_comments' is ignored
function! PythonBoB(line, direction, force_sel_comments) "{{{
  let ln = a:line
  let ind = indent(ln)
  let mark = ln
  let indent_valid = strlen(getline(ln))
  let ln = ln + a:direction
  if (a:direction == 1) && (!a:force_sel_comments) && 
      \ exists("g:py_select_trailing_comments") && 
      \ (!g:py_select_trailing_comments)
    let sel_comments = 0
  else
    let sel_comments = 1
  endif

  while((ln >= 1) && (ln <= line('$')))
    if  (sel_comments) || (match(getline(ln), "^\\s*#") == -1)
      if (!indent_valid)
        let indent_valid = strlen(getline(ln))
        let ind = indent(ln)
        let mark = ln
      else
        if (strlen(getline(ln)))
          if (indent(ln) < ind)
            break
          endif
          let mark = ln
        endif
      endif
    endif
    let ln = ln + a:direction
  endwhile

  return mark
endfunction
"}}}

" Go to previous (-1) or next (1) class/function definition
function! s:PythonDec(obj, direction) "{{{
  if (a:obj == "class")
    let objregexp = "^\\s*class\\s\\+[a-zA-Z0-9_]\\+"
        \ . "\\s*\\((\\([a-zA-Z0-9_,. \\t\\n]\\)*)\\)\\=\\s*:"
  else
    let objregexp = "^\\s*def\\s\\+[a-zA-Z0-9_]\\+\\s*(\\_[^:#]*)\\s*:"
  endif
  let flag = "W"
  if (a:direction == -1)
    let flag = flag."b"
  endif
  let res = search(objregexp, flag)
endfunction
"}}}

" Select an object ("class"/"function")
function! s:PythonSelectObject(obj) "{{{
  " Go to the object declaration
  normal $
  call s:PythonDec(a:obj, -1)
  let beg = line('.')

  if !exists("g:py_select_leading_comments") || (g:py_select_leading_comments)
    let decind = indent(beg)
    let cl = beg
    while (cl>1)
      let cl = cl - 1
      if (indent(cl) == decind) && (getline(cl)[decind] == "#")
        let beg = cl
      else
        break
      endif
    endwhile
  endif

  if (a:obj == "class")
    let eod = "\\(^\\s*class\\s\\+[a-zA-Z0-9_]\\+\\s*"
            \ . "\\((\\([a-zA-Z0-9_,. \\t\\n]\\)*)\\)\\=\\s*\\)\\@<=:"
  else
   let eod = "\\(^\\s*def\\s\\+[a-zA-Z0-9_]\\+\\s*(\\_[^:#]*)\\s*\\)\\@<=:"
  endif
  " Look for the end of the declaration (not always the same line!)
  call search(eod, "")

  " Is it a one-line definition?
  if match(getline('.'), "^\\s*\\(#.*\\)\\=$", col('.')) == -1
    let cl = line('.')
    execute ":".beg
    execute "normal V".cl."G"
  else
    " Select the whole block
    execute "normal \<Down>"
    let cl = line('.')
    execute ":".beg
    execute "normal V".PythonBoB(cl, 1, 0)."G"
  endif
endfunction
"}}}

" Jump to the next line with the same (or lower) indentation
" Useful for moving between "if" and "else", for example.
function! s:PythonNextLine(direction)"{{{
  let ln = line('.')
  let ind = indent(ln)
  let indent_valid = strlen(getline(ln))
  let ln = ln + a:direction

  while((ln >= 1) && (ln <= line('$')))
    if (!indent_valid) && strlen(getline(ln)) 
        break
    else
      if (strlen(getline(ln)))
        if (indent(ln) <= ind)
          break
        endif
      endif
    endif
    let ln = ln + a:direction
  endwhile

  execute "normal ".ln."G"
endfunction
"}}}

function! s:UpdateMenu() "{{{
  " delete menu if it already exists, then rebuild it.
  " this is necessary in case you've got multiple buffers open
  " a future enhancement to this would be to make the menu aware of
  " all buffers currently open, and group classes and functions by buffer
  if exists("g:menuran")
    aunmenu IM-Python
  endif
  let restore_fe = &foldenable
  set nofoldenable
  " preserve disposition of window and cursor
  let cline=line('.')
  let ccol=col('.') - 1
  norm H
  let hline=line('.')
  " create the menu
  call s:MenuBuilder()
  " restore disposition of window and cursor
  exe "norm ".hline."Gzt"
  let dnscroll=cline-hline
  exe "norm ".dnscroll."j".ccol."l"
  let &foldenable = restore_fe
endfunction
"}}}

function! s:MenuBuilder() "{{{
  norm gg0
  let currentclass = -1
  let classlist = []
  let parentclass = ""
  while line(".") < line("$")
    " search for a class or function
    if match ( getline("."), '^\s*class\s\+[_a-zA-Z].*\|^\s*def\s\+[_a-zA-Z].*' ) != -1
      norm ^
      let linenum = line('.')
      let indentcol = col('.')
      norm "nye
      let classordef=@n
      norm w"nywge
      let objname=@n
      let parentclass = s:FindParentClass(classlist, indentcol)
      if classordef == "class"
        call s:AddClass(objname, linenum, parentclass)
      else " this is a function
        call s:AddFunction(objname, linenum, parentclass)
      endif
      " We actually created a menu, so lets set the global variable
      let g:menuran = 1
      call s:RebuildClassList(classlist, [objname, indentcol], classordef)
    endif " line matched
    norm j
  endwhile
endfunction
"}}}

" classlist contains the list of nested classes we are in.
" in most cases it will be empty or contain a single class
" but where a class is nested within another, it will contain 2 or more
" this function adds or removes classes from the list based on indentation
function! s:RebuildClassList(classlist, newclass, classordef) "{{{
  let i = len(a:classlist) - 1
  while i > -1
    if a:newclass[1] <= a:classlist[i][1]
      call remove(a:classlist, i)
    endif
    let i = i - 1
  endwhile
  if a:classordef == "class"
    call add(a:classlist, a:newclass)
  endif
endfunction
"}}}

" we found a class or function, determine its parent class based on
" indentation and what's contained in classlist
function! s:FindParentClass(classlist, indentcol) "{{{
  let i = 0
  let parentclass = ""
  while i < len(a:classlist)
    if a:indentcol <= a:classlist[i][1]
      break
    else
      if len(parentclass) == 0
        let parentclass = a:classlist[i][0]
      else
        let parentclass = parentclass.'\.'.a:classlist[i][0]
      endif
    endif
    let i = i + 1
  endwhile
  return parentclass
endfunction
"}}}

" add a class to the menu
function! s:AddClass(classname, lineno, parentclass) "{{{
  if len(a:parentclass) > 0
    let classstring = a:parentclass.'\.'.a:classname
  else
    let classstring = a:classname
  endif
  exe 'menu IM-Python.classes.'.classstring.' :call <SID>JumpToAndUnfold('.a:lineno.')<CR>'
endfunction
"}}}

" add a function to the menu, grouped by member class
function! s:AddFunction(functionname, lineno, parentclass) "{{{
  if len(a:parentclass) > 0
    let funcstring = a:parentclass.'.'.a:functionname
  else
    let funcstring = a:functionname
  endif
  exe 'menu IM-Python.functions.'.funcstring.' :call <SID>JumpToAndUnfold('.a:lineno.')<CR>'
endfunction
"}}}
function! s:JumpToAndUnfold(line) "{{{
  " Go to the right line
  execute 'normal '.a:line.'gg'
  " Check to see if we are in a fold
  let lvl = foldlevel(a:line)
  if lvl != 0
    " and if so, then expand the fold out, other wise, ignore this part.
    execute 'normal 15zo'
  endif
endfunction
"}}}

"" This one will work only on vim 6.2 because of the try/catch expressions.
" function! s:JumpToAndUnfoldWithExceptions(line)
"  try 
"    execute 'normal '.a:line.'gg15zo'
"  catch /^Vim\((\a\+)\)\=:E490:/
"    " Do nothing, just consume the error
"  endtry
"endfunction

" vim:set et sts=2 sw=2 fdm=marker:
