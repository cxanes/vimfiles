" P4Diff.vim
" Last Modified: 2012-07-09 14:49:30
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_p4_diff')
  finish
endif
let loaded_autoload_p4_diff= 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

let g:p4_diff_opts_default = ['-f', '-se']
let g:p4_prog = 'p4'

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function! s:P4RunCmd(args)
  let args = a:args
  call map(args, 'shellescape(v:val)')
  let cmd = g:p4_prog . ' ' . join(args, ' ')
  let result = system(cmd)
  if v:shell_error
    echohl ErrorMsg | echom 'Shell error: ' . cmd | echohl None
  endif
  return result
endfunction

function! s:GetDiffFiles(opts, file)
  let result = s:P4RunCmd([ 'diff' ] + a:opts + [ a:file ])
  if v:shell_error
    echohl ErrorMsg | echo 'Shell error: ' . cmd | echohl None
    return []
  endif

  let files = split(result, '\n')
  call filter(files, '!empty(v:val)')

  if !empty(files)
    let cwd_pat = printf('^\V%s/', escape(getcwd(), '\'))
    call map(files, 'substitute(v:val, cwd_pat, "", "g")')
  endif

  return files
endfunction

function! s:GetRevision(file)
  return matchstr(a:file, '[#@][^#@]\+$')
endfunction

function! s:GetNumRevision(file)
  let result = s:P4RunCmd([ 'filelog', '-m', '1', (a:file . t:_p4_diff_rev) ])
  if v:shell_error
    return ''
  endif
  let m = matchlist(result, '\n\.\.\.\s*#\(\d\+\)')
  if empty(m)
    return ''
  endif
  return m[1]
endfunction

function! s:ParseDiffArgs(args)
  let opts = []
  let file = ''

  for arg in a:args
    if len(arg) == 0
      continue
    elseif arg !~ '^-'
      let opts = add(opts, arg)
    else
      if len(arg) != 0
        echohl WarningMsg | echo 'Can specify only one file' | echohl None
        return [ opts, file ]
      endif
      let file = arg
    endif
  endfor

  if empty(opts)
    let opts = copy(g:p4_diff_opts_default)
  endif

  if len(file) == 0
    let file = '...#have'
  endif

  return [opts, file]
endfunction

function! s:GotoOtherWindow()
  let s:curwinnum = winnr()
  wincmd p
  if winnr() != s:curwinnum && &buftype != 'nofile'
    return
  endif
  let winnum = winnr('$')
  for i in range(1, winnum)
    let bufnr = winbufnr(i)
    if bufnr != -1 && getbufvar(bufnr, '&bufnr') != 'nofile'
      exec i 'wincmd w'
      return
    endif
  endfor

  " no window found, create a new one
  new
endfunction

function s:P4DiffOff()
  silent! diffoff!

  if exists('t:_p4_diff_bufnr') && bufexists(t:_p4_diff_bufnr)
    exec t:_p4_diff_bufnr 'bw'
    if exists('t:_p4_diff_file') && !empty(t:_p4_diff_file)
      silent! call delete(t:_p4_diff_file)
      let t:_p4_diff_file = ''
    endif
  endif
endfunction

function! s:OpenFile()
  let file = getline('.')
  call s:P4DiffOff()
  call s:GotoOtherWindow()
  exec 'e' fnameescape(file)
endfunction

function! s:DiffFile()
  let file = getline('.')
  let diff_file = tempname()

  let result = s:P4RunCmd([ 'print' , '-o', diff_file, (file . t:_p4_diff_rev) ])
  if v:shell_error
    echohl ErrorMsg | echo 'Shell error: ' . cmd | echohl None
    return
  endif

  call s:P4DiffOff()
  call s:GotoOtherWindow()

  silent exec 'e' fnameescape(file)
  try
    silent exec 'diffsplit' fnameescape(diff_file)
    let rev = s:GetNumRevision(file)
    if empty(rev)
      let rev = 'head'
    endif
    let statusline = empty(&l:statusline) ? &g:statusline : &l:statusline
    let &l:statusline = substitute(statusline, '%f', substitute(printf('%s#%s', file, rev), '%', '%%', 'g'), '')
    let t:_p4_diff_bufnr = bufnr('%')
    let t:_p4_diff_file = diff_file
    silent! wincmd x
  catch
    echohl ErrorMsg | echo v:exception | echohl None
  endtry
endfunction

function! s:P4(redir, ...)
  let file = getline('.')
  if empty(file)
    return
  endif
  let file = escape(file, '\')

  let args = copy(a:000)
  call map(args, 'substitute(v:val, ''%\(:[reth]\)*'', ''\=fnamemodify(file, submatch(1))'', "g")')

  let result = s:P4RunCmd(args)
  if !a:redir
    echo result
    return
  endif

  let curwinnum = winnr()
  let winnum = CreateTempBuffer('_P4_Output_')
  exe winnum . 'wincmd w'
  silent %d _
  call setline(1, split(result, '\n'))
  exe curwinnum . 'wincmd w'
endfunction

function! s:P4Update()
  if exists('t:_p4_diff_cur_args')
    call call('s:P4Diff', t:_p4_diff_cur_args)
  else
    call s:P4Diff()
  endif
endfunction

function! s:P4Confirm(prompt)
  call inputsave()
  let confirm = input(a:prompt . ' (y/N) ', 'N')
  return confirm =~ '^[Yy]'
endfunction

function! s:P4DoRevert(files)
  let files = a:files
  call filter(files, '!empty(v:val)')
  if empty(files)
    return
  endif
  call map(files, 'v:val . t:_p4_diff_rev')
  call s:P4RunCmd([ 'sync', '-f' ] + files)
  call s:P4Update()
endfunction

function! s:P4Revert()
  let file = getline('.')
  if empty(file) || !s:P4Confirm('Do you want to revert "' .  file . '"?')
    return
  endif
  call s:P4DoRevert([ file ])
endfunction

function! s:P4RevertAll()
  if !s:P4Confirm('Do you want to revert all files?')
    return
  endif
  call s:P4DoRevert(getline(1, line('$')))
endfunction

function! s:P4RevertSel(...)
  if a:0 == 0
    return
  endif

  let files = copy(a:000)

  for file in files
    if file !~ '^\d\+$'
      echohl ErrorMsg | echom 'Invalid args (' . file .'): only accept numbers' | echohl None
      return
    endif
  endfor

  call map(files, 'getline(v:val)')
  call filter(files, '!empty(v:val)')
  if empty(files)
    return
  endif

  if !s:P4Confirm(join(files, "\n") . "\nDo you want to revert above files?")
    return
  endif

  call s:P4DoRevert(files)
endfunction

function! s:FileWindowInit()
  setl nu
  setl cursorline
  setl nowrap
  setl noma

  let winheight = max([ &lines / 3, &winheight ])
  exec winheight 'wincmd _'

  nnoremap <buffer> <silent> <CR> :<C-U>call <SID>OpenFile()<CR>
  nnoremap <buffer> <silent> d    :<C-U>call <SID>DiffFile()<CR>
  nnoremap <buffer> <silent> r    :<C-U>call <SID>P4Revert()<CR>
  nnoremap <buffer> <silent> u    :<C-U>call <SID>P4Update()<CR>

  nmap     <buffer> <silent> <2-LeftMouse> <CR>

  command! -nargs=+ -buffer -bang PF    call s:P4(<q-bang> == '!', <f-args>)
  command! -nargs=0 -buffer PFRevert    call s:P4Revert()
  command! -nargs=0 -buffer PFRevertAll call s:P4RevertAll()
  command! -nargs=+ -buffer PFRevertSel call s:P4RevertSel(<f-args>)
endfunction

function! s:ShowFileWindow(files, rev)
  let s:curwinnum = winnr()
  let winnum = CreateTempBuffer('_P4_File_', 'botright', '<SNR>'.s:SID().'_FileWindowInit')
  exe winnum . 'wincmd w'

  let &l:statusline = '%<%f rev:' . a:rev

  let t:_p4_diff_rev = a:rev

  setl ma
  silent %d _
  call setline(1, a:files)
  setl noma
endfunction

function! s:StripOpts(args)
  let file
  return substitute(a:args, '\b)
endfunction

function! s:P4Diff(...)
  let args = copy(a:000)
  let [opts, file]  = s:ParseDiffArgs(a:000)
  if len(file) == 0
    return
  endif

  redraw
  echohl WarningMsg | echo 'Processing...' | echohl None
  let files = s:GetDiffFiles(opts, file)
  if empty(files)
    echohl WarningMsg | echo 'No modified files found' | echohl None
    return
  endif

  let rev = s:GetRevision(file)

  call s:ShowFileWindow(files, rev)
  redraw
  echo ''
  let t:_p4_diff_cur_args = args
endfunction

" XXX When command is defined as P4Diff, the completion doesn't work.
command! -nargs=* -complete=file PFDiff call s:P4Diff(<f-args>)
command! -nargs=0 PFUpdate  call s:P4Update()
command! -nargs=0 PFDiffOff call s:P4DiffOff()

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
