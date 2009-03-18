" template.vim Insert Template using (modified) snippetsEmu.vim or (modified) snipMate.vim
" Last Modified: 2008-03-13 22:37:15
"        Author: Frank Chang <frank.nevermind AT gmail.com>
" Load Once {{{
if exists('loaded_template_autoload_plugin')
  finish
endif
let loaded_template_autoload_plugin = 1

let s:snippets_sys = []

if exists('loaded_snippet')
  call add(s:snippets_sys, 'snippetsEmu')
endif

if exists('loaded_snips') && exists('*SnipMateInsertSnippet')
  call add(s:snippets_sys, 'snipMate')
endif

if empty(s:snippets_sys)
  echom 'Template.vim needs snippetsEmu.vim (modified verson) or snipMate.vim plugin.'
  finish
end

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

  let templates = []
  if index(s:snippets_sys, 'snippetsEmu') != -1
    let new_templates = split(glob(dir . '/*.snip'), '\n')
    let new_templates = map(new_templates, 'fnamemodify(v:val, ":p:t:r")')
    let templates += new_templates
  endif

  if index(s:snippets_sys, 'snipMate') != -1
    let new_templates = split(glob(dir . '/*.snippet'), '\n')
    let new_templates = map(new_templates, 'fnamemodify(v:val, ":p:t:r")')
    let templates += new_templates
  endif

  if empty(templates)
    return ''
  endif

  let new_templates = []
  let cache = {}
  for template in templates
    if !empty(template)
      if !has_key(cache, template)
        let cache[template] = 1
        call add(new_templates, template)
      endif
    endif
  endfor

  return join(new_templates, "\n")
endfunction

function! s:IsFullPath(path)
  if a:path =~ '^\%(\w:\)\?/'
    return 1
  else
    return 0
  endif
endfunction

function! s:GetFullPath(path, ext)
  let path = a:path
  if ! s:IsFullPath(path)
    let path = s:TemplateDir(&ft) . printf('/%s.%s', path, a:ext)
  endif

  if !filereadable(path)
    echohl ErrorMsg
    echomsg "Unable to insert template file: " . path
    echomsg "Either it doesn't exist or it isn't readable."
    echohl None
    return ''
  endif

  return path
endfunction

"}}}
function! Template#InsertTemplate(path) "{{{
  if &ft == ''
    echohl ErrorMsg
    echomsg "Please specify the filetype first."
    echohl None
    return
  endif

  if index(s:snippets_sys, 'snipMate') != -1
    let path = s:GetFullPath(a:path, 'snippet')
    if empty(path)
      return
    endif

    let template = join(readfile(path), "\n")
    call SnipMateInsertSnippet(template)
    return
  endif

  if index(s:snippets_sys, 'snippetsEmu') != -1
    let path = s:GetFullPath(a:path, 'snip')
    if empty(path)
      return
    endif

    let template = join(readfile(path), '<CR>')
    call SnippetInsert(template)
    return
  endif
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
