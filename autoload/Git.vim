" Git.vim
"
" Last Modified: 2009-03-15 21:03:12
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" Most source codes are modified from git-vim <http://github.com/motemen/git-vim>

" Load Once {{{
if exists('loaded_autoload_Git')
  finish
endif
let loaded_autoload_Git = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"======================================================================
" +python {{{
let s:has_python = 0
if has('python') && (has('win32') || has('win32unix') || has('win64') || has('win95') || has('win16'))
  let s:has_python = 1
python <<EOF
import vim, subprocess
def GitListArgs(comp_words, comp_cword):
  try:
    f = subprocess.Popen(['bash', 'git-compl.sh', comp_words, comp_cword], 
                         shell=True, stdout=subprocess.PIPE).stdout
    lines = f.readlines()
    if len(lines) == 0:
      vim.command("let completion = ''")
    else:
      vim.command("let completion = '%s'" % (''.join(lines).replace("'", "''"), ))
    retcode = f.close()
    vim.command('let s:shell_error = 0')
    if retcode is not None:
      vim.command('let s:shell_error = ' + str(retcode))
  except IOError:
    vim.command('let s:shell_error = 1')

def GitSystem(cmdline):
  try:
    f = subprocess.Popen(cmdline, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = f.stdout.readlines()
    vim.command("let output = '%s'" % (''.join(lines).replace("'", "''"), ))
    f.poll()
    retcode = f.returncode
    vim.command('let s:shell_error = 0')
    if retcode is not None:
      vim.command('let s:shell_error = ' + str(retcode))
  except IOError:
    vim.command('let s:shell_error = 1')
EOF
function! s:GitSystem(cmdline) 
  py GitSystem(vim.eval('a:cmdline'))
  return output
endfunction

let s:system = function('s:GitSystem')
else
let s:system = function('system')
endif
"}}}
if executable('bash') && executable('git-compl.sh') && exists('*mylib#ParseCmdArgs')
  if exists('g:git_completion')
    let $GIT_COMPL = g:git_completion
  endif
  function! Git#ListArgs(ArgLead, CmdLine, CursorPos) "{{{
    let line = a:CmdLine[ : a:CursorPos-1]
    let words = mylib#ParseCmdArgs(line)
    if !empty(words) && words[0] =~ '^GitHelp$'
      let words = ['git', 'help'] + (len(words) > 1 ? words[1:] : [])
    endif
    let comp_cword = len(words)
    if a:CmdLine[a:CursorPos-1] !~ '\s' && comp_cword
      let comp_cword -= 1
    endif
    let comp_words = join(words, ' ')
    if empty(comp_words)
      return ''
    endif

    if s:has_python
      py GitListArgs(vim.eval('comp_words'), vim.eval('comp_cword'))
    else
      let srr_sav = &srr
      let tmpfile = tempname()
      let &srr= '>%s 2>' . tmpfile
      let completion = s:system(printf('bash git-compl.sh ''%s'' %d', comp_words, comp_cword))
      let error = s:ShellError()
      let &srr = srr_sav
      call delete(tmpfile)
    endif

    if empty(completion)
      return glob('*')
    else
      return substitute(completion, '\n\+$', '', '')
    endif
  endfunction
  "}}}
else
  function! Git#ListArgs(ArgLead, CmdLine, CursorPos) "{{{
  endfunction
  "}}}
endif

if !exists('g:git_command_edit')
  let g:git_command_edit = 'new'
endif

if !exists('g:git_bufhidden')
  let g:git_bufhidden = ''
endif

" Ensure b:git_dir exists.
function! s:GetGitDir() "{{{
  if !exists('b:git_dir')
    let b:git_dir = finddir('.git', escape(expand('%:p:h'), ' ') . ';/')
    if strlen(b:git_dir)
      let b:git_dir = fnamemodify(b:git_dir, ':p')
    endif
  endif
  return b:git_dir
endfunction
"}}}
" Returns current git branch.
" Call inside 'statusline' or 'titlestring'.
function! Git#Branch() "{{{
  let git_dir = s:GetGitDir()

  if strlen(git_dir) && filereadable(git_dir . 'HEAD')
    let lines = readfile(git_dir . 'HEAD')
    return len(lines) ? matchstr(lines[0], '[^/]*$') : ''
  else
    return ''
  endif
endfunction
"}}}
" List all git local branches.
function! Git#ListBranches(arg_lead, cmd_line, cursor_pos) "{{{
  let branches = split(s:system('git branch'), '\n')
  if s:ShellError()
    return []
  endif

  return map(branches, 'matchstr(v:val, ''^[* ] \zs.*'')')
endfunction
"}}}
" List all git commits.
function! Git#ListCommits(arg_lead, cmd_line, cursor_pos) "{{{
  let commits = split(s:system('git log --pretty=format:%h'))
  if s:ShellError()
    return []
  endif

  let commits = ['HEAD'] + Git#ListBranches(a:arg_lead, a:cmd_line, a:cursor_pos) + commits

  if a:cmd_line =~ '^GitDiff'
    " GitDiff accepts <commit>..<commit>
    if a:arg_lead =~ '\.\.'
      let pre = matchstr(a:arg_lead, '.*\.\.\ze')
      let commits = map(commits, 'pre . v:val')
    endif
  endif

  return filter(commits, 'match(v:val, ''\v'' . a:arg_lead) == 0')
endfunction
"}}}
" Show diff.
function! Git#Diff(args) "{{{
  let git_output = s:system('git diff ' . a:args . ' -- ' . s:Expand('%'))
  if !strlen(git_output)
    echo "No output from git command"
    return
  endif

  call s:OpenGitBuffer('diff', git_output)
  setlocal filetype=git-diff
endfunction
"}}}
" Show Status.
function! Git#Status() "{{{
  let git_output = s:system('git status')
  call s:OpenGitBuffer('status', git_output)
  setlocal filetype=git-status
  nnoremap <silent> <buffer> <CR> :<C-U>call <SID>GitAddFile()<CR>
  nnoremap <silent> <buffer> -    :<C-U>call <SID>GitUnstageFile()<CR>
endfunction
"}}}
function! s:GitAddFile() "{{{
  let file = expand('<cfile>')
  if has('syntax_items') && synIDattr(synID(line('.'), col('.'), 0), 'name') !~? '^gitStatus.*File$'
    echohl WarningMsg
    echo 'git: ' . file . ': not file'
    echohl None
    return
  endif

  call Git#Add(file)
  call s:RefreshGitStatus()
endfunction
"}}}
function! s:GitUnstageFile() "{{{
  let file = expand('<cfile>')
  if has('syntax_items') && synIDattr(synID(line('.'), col('.'), 0), 'name') !~? '^gitStatusSelectedFile$'
    echohl WarningMsg
    echo 'git: ' . file . ': not selected file'
    echohl None
    return
  endif

  call Git#DoCommand('reset HEAD -- ' . file)
  call s:RefreshGitStatus()
endfunction
"}}}
function! s:RefreshGitStatus() "{{{
  let pos_save = getpos('.')
  call Git#Status()
  call setpos('.', pos_save)
endfunction
"}}}
" Show Log.
function! Git#Log(args, all) "{{{
  if a:all
    let git_output = s:system('git log ' . a:args)
  else
    let git_output = s:system('git log ' . a:args . ' -- ' . s:Expand('%'))
  endif
  call s:OpenGitBuffer('log', git_output)
  setlocal filetype=git-log
endfunction
"}}}
" Add file to index.
function! Git#Add(expr) "{{{
  let file = s:Expand(strlen(a:expr) ? a:expr : '%')

  call Git#DoCommand('add -v ' . file)
endfunction
"}}}
" Commit.
function! Git#Commit(args) "{{{
  let git_dir = s:GetGitDir()

  if a:args =~ '\%(^\|\s\)-m\%(\s\|$\)'
    call Git#DoCommand('commit ' . a:args)
    return
  endif

  " Create COMMIT_EDITMSG file
  let editor_save = $EDITOR
  let $EDITOR = ''
  call s:system('git commit ' . a:args)
  let $EDITOR = editor_save

  exec printf('%s %sCOMMIT_EDITMSG', g:git_command_edit, git_dir)
  setlocal filetype=gitcommit bufhidden=wipe
  augroup GitCommit
    autocmd BufWritePre <buffer> g/^#/d | setlocal fileencoding=utf-8
    exec printf("autocmd BufWritePost <buffer> call Git#DoCommand('commit %s -F ''' . expand('%%') . '''') | bw | autocmd! GitCommit * <buffer>", a:args)
  augroup END
endfunction
"}}}
" Checkout.
function! Git#Checkout(args) "{{{
  call Git#DoCommand('checkout ' . a:args)
endfunction
"}}}
" Show commit, tree, blobs.
function! Git#CatFile(file) "{{{
  let file = s:Expand(a:file)
  "let file_type  = s:system('git cat-file -t ' . file)
  let git_output = s:system('git cat-file -p ' . file)
  if !strlen(git_output)
    echo "No output from git command"
    return
  endif

  call s:OpenGitBuffer('catfile', git_output)
endfunction
"}}}
function! Git#DoCommand(args) "{{{
  let git_output = s:system('git ' . a:args)
  let git_output = substitute(git_output, '\n*$', '', '')
  if s:ShellError()
    echohl Error
    echo git_output
    echohl None
  else
    echo git_output
  endif
endfunction
"}}}
" Show vimdiff for merge. (experimental)
function! Git#VimDiffMerge() "{{{
  let file = s:Expand('%')
  let filetype = &filetype
  let t:git_vimdiff_original_bufnr = bufnr('%')
  let t:git_vimdiff_buffers = []

  topleft new
  setlocal buftype=nofile
  file `=':2:' . file`
  call add(t:git_vimdiff_buffers, bufnr('%'))
  exec 'silent read!git show :2:' . file
  0d
  diffthis
  let &filetype = filetype

  rightbelow vnew
  setlocal buftype=nofile
  file `=':3:' . file`
  call add(t:git_vimdiff_buffers, bufnr('%'))
  exec 'silent read!git show :3:' . file
  0d
  diffthis
  let &filetype = filetype
endfunction
"}}}
function! Git#VimDiffMergeDone() "{{{
  if exists('t:git_vimdiff_original_bufnr') && exists('t:git_vimdiff_buffers')
    if getbufline(t:git_vimdiff_buffers[0], 1, '$') == getbufline(t:git_vimdiff_buffers[1], 1, '$')
      exec 'sbuffer ' . t:git_vimdiff_original_bufnr
      0put=getbufline(t:git_vimdiff_buffers[0], 1, '$')
      normal! jdG
      update
      exec 'bdelete ' . t:git_vimdiff_buffers[0]
      exec 'bdelete ' . t:git_vimdiff_buffers[1]
      close
    else
      echohl ErrorMsg
      echo 'There still remains conflict'
      echohl None
    endif
  endif
endfunction
"}}}
" Show help.
function! Git#ShowHelp(cmd) "{{{
  if exists(':ManMan')
    exec 'ManMan git-' . a:cmd
  else
    let git_output = s:system('man git-' . a:cmd)
    call s:OpenGitBuffer('help', git_output)
    setlocal modifiable
    silent! %s/’/'/ge
    silent! %s/−/-/ge
    silent! %s/‐$/-/e
    silent! %s/‘/`/ge
    silent! %s/‐/-/ge
    silent! %s/.\b//ge
    setlocal nomodifiable
    setlocal filetype=man
  endif
endfunction
"}}}
" Utilities.
function! s:OpenGitBuffer(bufname, content) "{{{
  let bufname = printf('__git_%s__', a:bufname)

  if exists('*CreateSharedTempBuffer')
    let winnum = CreateSharedTempBuffer(bufname)
    exe winnum . 'wincmd w'
  else
    if exists('b:is_git_msg_buffer') && b:is_git_msg_buffer
      enew!
    else
      exec g:git_command_edit
    endif
    exec 'file ' . bufname
  endif

  setlocal buftype=nofile readonly modifiable
  exec 'setlocal bufhidden=' . g:git_bufhidden

  silent %d _
  silent put=a:content
  silent keepjumps 0d
  setlocal nomodifiable

  let b:is_git_msg_buffer = 1
endfunction
"}}}
function! s:Expand(expr) "{{{
  if has('win32')
    return substitute(expand(a:expr), '\', '/', 'g')
  else
    return expand(a:expr)
  endif
endfunction
"}}}
function! s:ShellError() "{{{
  if exists('s:shell_error')
    return s:shell_error
  else
    return v:shell_error
  endif
endfunction
"}}}
"======================================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
