" template.vim Insert Template using snippetsEmu.vim
" Last Modified: 2008-03-13 22:37:15
"        Author: Frank Chang <frank.nevermind AT gmail.com>
" Load Once {{{
if exists('loaded_template_autoload_plugin')
  finish
endif
let loaded_template_autoload_plugin = 1

if !exists('loaded_snippet')
  echom 'Template.vim requires snippetsEmu.vim plugin (modified verson)'
  finish
endif

let s:save_cpo = &cpo
set cpo&vim
"}}}
function! s:TemplateDir(ft) "{{{
  if a:ft == ''
    return ''
  endif

  if exists('g:template_dir')
    let dir = g:template_dir
  else
    let dir = globpath(&rtp, 'templates')
    if dir != ''
      let dir = split(dir, '\n')[0]
    endif
  endif

  if dir == ''
    return ''
  endif

  let dir .= '/' . &ft
  if !isdirectory(dir)
    return ''
  endif

  return dir
endfunction
"}}}
function! Template#ListTemplates(A,L,P) "{{{
  let dir = s:TemplateDir(&ft)
  if dir == ''
    return ''
  endif

  let templates = split(glob(dir . '/*.snip'), '\n')
  let templates = map(templates, 'fnamemodify(v:val, ":p:t:r")')
  return join(templates, "\n")
endfunction

function! s:IsFullPath(path)
  if a:path =~ '^\%(\w:\)\?/'
    return 1
  else
    return 0
  endif
endfunction
"}}}
function! Template#InsertTemplate(path) "{{{
  if &ft == ''
    echohl ErrorMsg
    echomsg "Please specify the filetype first."
    echohl None
    return
  endif

  let path = a:path
  if ! s:IsFullPath(path)
    let path = s:TemplateDir(&ft) . printf('/%s.snip', a:path)
  endif

  if !filereadable(path)
    echohl ErrorMsg
    echomsg "Unable to insert template file: " . path
    echomsg "Either it doesn't exist or it isn't readable."
    echohl None
    return
  endif

  let template = join(readfile(path), '<CR>')
  call SnippetInsert(template)
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
