" html configuration file
"===================================================================
" Settings {{{
"-------------------------------------------------------------------
if !exists('b:html_template_dir')
  if !exists('g:html_template_dir')
    let b:html_template_dir = g:html_template_dir
  else
    let b:html_template_dir = ''
    let dir = globpath(&rtp, 'templates/html')
    if !empty(dir)
      let b:html_template_dir = split(dir, '\n')[0]
    endif
  endif
endif
"}}}
"===================================================================
" Commands {{{
"-------------------------------------------------------------------
if exists('*Utl_AddressScheme_http')
  command! -buffer LaunchBrowser if !empty(expand('%:p'))|call Utl_AddressScheme_http('"file:///'.expand('%:p').'"')|endif
elseif has('win16') || has('win32') || has('win64') || has('win32unix') || has('win95')
  " from HTML.vom <http://www.infynity.spodzone.com/vim/HTML/>
  command! -buffer LaunchBrowser exe 'silent! !start RunDll32.exe shell32.dll,ShellExec_RunDLL ' . expand('%:p')
endif
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
try
  call mapping#MoveTo('>')
catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
endtry

inoremap <silent> <buffer> <CR> <C-R>=<SID>HtmlEnter()<CR>
"}}}
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
if !exists('*s:HtmlEnter') "{{{
  function! s:HtmlEnter()
    let line = getline('.')
    if line[col('.')-1] != '<'
      return "\<CR>"
    endif

    let bkTag = searchpos('<[^/>]\+>', 'bnc', line('.'))
    if bkTag == [0, 0] || bkTag[1] == col('.')
      return "\<CR>"
    endif
    let fdTag = searchpos('</[^>]\+>', 'nc', line('.'))
    if fdTag == [0, 0]
      return "\<CR>"
    endif

    let bkTagName = matchlist(line, '<\([^/>]\+\)>', bkTag[1]-1)[1]
    let fdTagName = matchlist(line, '</\([^>]\+\)>', fdTag[1]-1)[1]

    if bkTagName !=? fdTagName
      return "\<CR>"
    endif

    return "\<CR>\<ESC>ko"
  endfunction
endif
"}}}
"}}}
"===================================================================
" vim: fdm=marker :
