let g:p4_prog = 'p4'

let t:_p4_diff_cur_args = []
let t:_p4_diff_rev = ''

function! s:GetFiles()
  call filter(files, '!empty(v:val)')
endfunction

function! s:P4DiffFile()
  if statline =~ '%f'
  endif
endfunction

function! s:P4Diff(...)
  let args = a:000

  let t:_p4_diff_cur_args = args
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

function! s:P4(redir, ...)
  let file = getline('.')
  if empty(file)
    return
  endif
  let file = escape(file, '\')

  let args = a:000
  call map(args, 'substitute(v:val, "%", file, "g")')

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
  call call('s:P4Diff', t:_p4_diff_cur_args)
endfunction

function! s:P4Confirm(prompt)
  call inputsave()
  let confirm = input(a:prompt, 'N')
  return confirm =~ '^[Yy]'
endfunction

function! s:P4DoRevert(files)
  let files = a:files
  call filter(files, '!empty(v:val)')
  if empty(files)
    return
  endif
  call map(files, 'v:val . t:_p4_diff_rev')
  call s:P4RunCmd(['sync'] + files)
  call s:P4Update()
endfunction

function! s:P4Revert()
  let file = getline('.')
  if empty(file) || !s:P4Confirm('Do you want to revert "' .  file . '"? (y/N)')
    return
  endif
  call s:P4DoRevert([ getline('.') ])
endfunction

function! s:P4RevertAll()
  if !s:P4Confirm('Do you want to revert all files? (y/N)')
    return
  endif
  call s:P4DoRevert(getline(1, line('$')))
endfunction

function! s:P4RevertSel(...)
  if a:0 == 0
    return
  endif

  let files = a:000

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

  if !s:P4Confirm("Do you want to revert following files? (y/N)\n" . join(files, "\n"))
    return
  endif

  call s:P4DoRevert(files)
endfunction

function! s:FileWindowInit()
  setl nu

  noremap <buffer> <silent> r :<C-U>call <SID>P4Revert()<CR>
  noremap <buffer> <silent> u :<C-U>call <SID>P4Update()<CR>

  command! -nargs=+ -bang P4          call s:P4(<q-bang> == '!', <f-args>)
  command! -nargs=0 -bang P4Update    call s:P4Update()
  command! -nargs=0 -bang P4Revert    call s:P4Revert()
  command! -nargs=0 -bang P4RevertAll call s:P4RevertAll()
  command! -nargs=+ -bang P4RevertSel call s:P4RevertSel(<f-args>)
endfunction

" XXX When command is defined as P4Diff, the completion doesn't work.
command! -nargs=* -bang -complete=file PFDiff call s:P4Diff(<f-args>)
