" Project.vim
" Last Modified: 2011-01-20 21:27:02
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_Project')
  finish
endif
let loaded_autoload_Project = 1
let s:save_cpo = &cpo
set cpo&vim
"}}}
function! Project#AddSyntax(syn_file, ft) 
  let syn_file = substitute(a:syn_file, '[\/\\]\+%', '', '')

  if filereadable(syn_file)
    let syn_file = fnameescape(fnamemodify(syn_file, '%:p'))
  elseif isdirectory(syn_file)
    let syn_file = glob(syn_file . '/*.vim')
    if empty(syn_file)
      return
    endif
    let syn_file = join(map(split(syn_file, '\n'), 'fnameescape(v:val)'), ' ')
  else
    echohl ErrorMsg | echo printf('Syntax file not found: %s"', a:syn_file) | echohl None
    return
  endif

  if a:ft !~ '^\w\+\%(,\w\+\)*$'
    echohl ErrorMsg | echo printf('Invalid filetype: %s"', a:ft) | echohl None
    return
  endif

  augroup ProjectSyntax
    exec 'au Syntax' a:ft 'silent! so' syn_file
  augroup END
endfunction

function! Project#Open(proj_name) 
  let proj_name = empty(a:proj_name) ? '.' : substitute(a:proj_name, '[\/\\]\+%', '', '')

  if filereadable(proj_name)
    let proj_dir  = fnamemodify(proj_name, ":p:h")
    let proj_name = fnamemodify(proj_name, ":p:t")
  elseif isdirectory(a:proj_name)
    let proj_dir = a:proj_name
    let proj_name = 'project.vim'
  else
    echohl ErrorMsg | echo printf('Project not found: %s"', proj_name) | echohl None
    return
  endif

  exec 'cd' fnameescape(proj_dir)
  FileExplorer .
  winc p
  if filereadable('cscope.out')
    silent! cscope add cscope.out
  endif
  exec 'silent! so' proj_name
endfunction
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
