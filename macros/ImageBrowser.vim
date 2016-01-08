" File: ImageBrowser.vim
" Author: Frank Chang (frank.nevermind AT gmail.com)
" Version: 1.0
" Last Modified: 2008-01-29 12:37:29
"
" Launch image browser with given directory in Firefox and insert the selected
" image filename in Vim.
"
" Command:
"   ImageBrowser {dir}
"
" The main component is modified from ImageBrowser Bundle of Textmate, and is
" put in the directory 'ImageBrowser'.
" The javascript 'FF-Send-Key-to-Vim.js' (in 'js') is used to send text to Vim.
"
" Reference:
"   http://macromates.com/svn/Bundles/trunk/Bundles/ImageBrowser.tmbundle/
" 
" ImageBrowser requires Vim to have +clientserver supports.
if !has('clientserver')
  echohl ErrorMsg | echo 'This script require +clientserver feature.' | echohl None
  finish
endif

command! -nargs=1 -complete=dir ImageBrowser call <SID>ImageBrowser(<q-args>)

function! s:ImageBrowser(root)
  let root = fnamemodify(expand(a:root), ':p')
  if !isdirectory(root)
    echohl ErrorMsg | echo "'" . root "' is not a directory." | echohl None
    return
  endif

  let browser = globpath(&rtp, 'tools/ImageBrowser/browser.rb')
  if empty(browser)
    echohl ErrorMsg | echo "This script needs browser.rb (modified from http://macromates.com/svn/Bundles/trunk/Bundles/ImageBrowser.tmbundle/) to create image panel." | echohl None
    return
  endif

  let browser = split(browser, '\n')[0]
  if has('win32')
    let browser = 'ruby ' . shellescape(browser)
    let firefox = 'C:\Program Files\Mozilla Firefox\firefox.exe'
  else
    let browser = shellescape(browser)
    let firefox = system('which firefox')
    if v:shell_error
      let firefox = ''
    endif
  endif

  if !executable(firefox)
    echohl ErrorMsg | echo "This script needs Firefox to launch the browser." | echohl None
    return
  endif

  let resource = system(browser . ' ' . shellescape(root) . ' ' . v:servername)

  if has('win32')
    let shellslash = &shellslash
    set noshellslash
  endif

  let tmpfile = tempname()
  call writefile(split(resource, '\n'), tmpfile)
  let tmpfile = 'file:///' . substitute(tmpfile, '\\', '/', 'g')

  if has('win32')
    exec 'silent !start ' . shellescape(firefox) . ' ' . shellescape(tmpfile)
    let &shellslash = shellslash
  else
    exec 'silent !' . shellescape(firefox) . ' ' . shellescape(tmpfile)
  endif
endfunction
