" Omni.vim
" Last Modified: 2010-01-12 22:40:37
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_perl_omni')
  finish
endif
let loaded_autoload_perl_omni = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
" Constants {{{
let s:PAT_KEYWORD = '[a-zA-Z_][_a-zA-Z0-9]*'
let s:PAT_CLASS   = '\%(\%(' . s:PAT_KEYWORD . '\)\(::' . s:PAT_KEYWORD . '\)*\)'

let s:KEY_PRAGMAS = ['attributes','attrs','autodie','autouse','base','bigint','bignum','bigrat','blib','bytes','charnames','constant','diagnostics','encoding','feature','fields','filetest','if','integer','less','lib','locale','mro','open','ops','overload','overloading','parent','re','sigtrap','sort','strict','subs','threads','threads::shared','utf8','vars','vmsish','warnings','warnings::register']

let s:KEY_BUILTIN = ['BEGIN','UNITCHECK','CHECK','INIT','END ','__DATA__','__END__','__PACKAGE__','abs','accept','alarm','and','atan2','bind','binmode','bless','break','caller','chdir','chmod','chomp','chop','chown','chr','chroot','close','closedir','connect','continue','cos','crypt','dbmclose','dbmopen','defined','delete','die','do','dump','each','endgrent','endhostent','endnetent','endprotoent','endpwent','endservent','eof','eq ne cmp','eval','exec','exists','exit','exp','fcntl','fileno','flock','fork','format','formline','getc','getgrent','getgrgid','getgrnam','gethostbyaddr','gethostbyname','gethostent','getlogin','getnetbyaddr','getnetbyname','getnetent','getpeername','getpgrp','getppid','getpriority','getprotobyname','getprotobynumber','getprotoent','getpwent','getpwnam','getpwuid','getservbyname','getservbyport','getservent','getsockname','getsockopt','glob','gmtime','goto','grep','hex','import','index','int','ioctl','join','keys','kill','last','lc','lcfirst','length','link','listen','local','localtime','lock','log','lstat','lt','gt','le','ge','map','mkdir','msgctl','msgget','msgrcv','msgsnd','my','next','no','not','oct','open','opendir','or','ord','our','pack','package','pipe','pop','pos','print','printf','prototype','push','qq','qr','quotemeta','qw','qx','rand','read','readdir','readline','readlink','readpipe','recv','redo','ref','rename','require','reset','return','reverse','rewinddir','rindex','rmdir','say','scalar','seek','seekdir','select','semctl','semget','semop','send','setgrent','sethostent','setnetent','setpgrp','setpriority','setprotoent','setpwent','setservent','setsockopt','shift','shmctl','shmget','shmread','shmwrite','shutdown','sin','sleep','socket','socketpair','sort','splice','split','sprintf','sqrt','srand','stat','state','study','sub','substr','symlink','syscall','sysopen','sysread','sysseek','system','syswrite','tell','telldir','tie','tied','time','times','tr','truncate','uc','ucfirst','umask','undef','unlink','unpack','unshift','untie','use','utime','values','vec','wait','waitpid','wantarray','warn','write','xor']
" }}}

let s:module_cached_list = {}
let s:include_path = []

function! Perl#Omni#Complete(findstart, base) "{{{
  if a:findstart
    let s:compl_type = ''

    let line = col('.') == 1 ? '' : getline('.')[0 : col('.')-2]
    if line =~ '^\s*use\s\+' . s:PAT_CLASS . '\?\%(::\)\?$'
      let s:compl_type = 'use'
      let prefix = strlen(matchstr(line, s:PAT_CLASS . '\?\%(::\)\?$'))

    elseif line =~ '^\s*no\s\+\w*$'
      let s:compl_type = 'no'
      let prefix = strlen(matchstr(line, '\w*$'))

    elseif line =~ '\%(^\|\s\)' . s:PAT_CLASS . '\?::\w*$'
      let s:compl_type = 'sub'
      let prefix = strlen(matchstr(line, '\w*$'))

    elseif line =~ '\w->\w*$'
      let s:compl_type = 'method'
      let prefix = strlen(matchstr(line, '\w*$'))

    elseif line =~ '\w*$'
      let s:compl_type = 'builtin'
      let prefix = strlen(matchstr(line, '\w*$'))

    else
      return -1
    endif

    return col('.') - prefix - 1
  else
    if s:compl_type == 'use'
      let candidates = copy(s:KEY_PRAGMAS)
      let candidates += s:GetModules()

    elseif s:compl_type == 'no'
      let candidates = copy(s:KEY_PRAGMAS)

    elseif s:compl_type == 'sub'
      let candidates = s:GetSubs()

    elseif s:compl_type == 'method'
      let candidates = s:GetMethods()

    elseif s:compl_type == 'builtin'
      let candidates = copy(s:KEY_BUILTIN)

    else
      return []
    endif

    let pat = '^\V' . escape(a:base, '\')
    return filter(candidates, 'v:val =~ pat')
  endif

endfunction
"}}}
function! Perl#Omni#AddPath(...) "{{{
  for path in a:000
    let full_path = fnamemodify(path, ':p')
    if index(s:include_path, full_path) < 0
      call add(s:include_path, full_path)
    endif
  endfor
endfunction
"}}}
function! Perl#Omni#RemovePath(...) "{{{
  for path in a:000
    let full_path = fnamemodify(path, ':p')
    let index = index(s:include_path, full_path)
    if index >= 0
      call remove(s:include_path, index)
      
      if has_key(s:module_cached_list, full_path)
        call remove(s:module_cached_list, full_path)
      endif
    endif
  endfor
endfunction
"}}}
function! Perl#Omni#RefreshModuleList(...) "{{{
  if a:0 == 0 || a:1 < 1
    let g:refresh_module_list = 1
  endif

  if a:0 && a:1 >= 1
    let g:refresh_installed_module_list = 1
  endif
endfunction
"}}}
function! Perl#Omni#Setting() "{{{
  setlocal omnifunc=Perl#Omni#Complete
  command -buffer -nargs=+ PerlOmniAddPath call Perl#Omni#AddPath(<f-args>)
  command -buffer -nargs=+ PerlOmniRemovePath call Perl#Omni#RemovePath(<f-args>)
  command -buffer -bang -nargs=0 PerlOmniRefreshModuleList call Perl#Omni#RefreshModuleList(<q-bang> == '!')
endfunction
"}}}

function! s:GetModules() "{{{
  if !exists('g:refresh_installed_module_list')
    let g:refresh_installed_module_list = 1
  endif

  if !exists('g:refresh_module_list')
    let g:refresh_module_list = 1
  endif

  if !exists('s:installed_module_list') || g:refresh_installed_module_list
    let cmd = 'perl -MMy::Devel::Installed -e "show_installed"'
    let s:installed_module_list = s:SystemList(cmd)
    let g:refresh_installed_module_list = 0
  endif

  let all_modules = copy(s:installed_module_list)

  if !empty(s:include_path)
    if g:refresh_module_list
      let include_path = s:include_path
      let g:refresh_module_list = 0
    else
      let include_path = filter(copy(s:include_path), '!has_key(s:module_cached_list, v:val)')
    endif

    if !empty(include_path)
      for path in include_path
        let cmd = 'perl -MMy::Devel::Installed -e "show(\*STDIN)"'
        let modules = s:SystemList(cmd, path)
        let s:module_cached_list[path] = modules
      endfor
    endif

    let modules = []
    for path in s:include_path
      call extend(modules, s:module_cached_list[path])
    endfor
    let all_modules = modules + all_modules
  endif

  return all_modules
endfunction
"}}}
function! s:ContentSub2Method() "{{{
  let buf = []

  if line('.') > 1
    let buf += getline(1, line('.')-1)
  endif

  let line = col('.') == 1 ? '' : getline('.')[0 : col('.')-2]
  if line == ''
    call add(buf, getline('.'))
  else
    let line = substitute(line, '::\(\w*\)$', '->\1', '')
    let line .= getline('.')[col('.')-1 : ]
    call add(buf, line)
  endif

  if line('.') < line('$')
    let buf += getline(line('$'), line('$')+1)
  endif

  return buf
endfunction
"}}}
function! s:GetSubs() "{{{
  return s:GetMethods(s:ContentSub2Method())
endfunction
"}}}
function! s:GetMethods(...) "{{{
  let lnum = line('.')
  let col = col('.')
  let filename = expand("%")

  let cmd = "perl -MMy::Devel::IntelliPerl::Editor -e run"
  let buf = [lnum, col, filename] + (a:0 ? a:1 : getline(1, '$'))

  let methods = s:System(cmd, join(buf, "\n"))
  return s:SystemList(cmd, buf)
endfunction
"}}}

let s:loaded_python = 0
if has('python') "{{{
py << END_PY
try:
  import vim
  import subprocess

  vim.command("let s:loaded_python = 1")
except Exception, e:
  vim.command('echohl ErrorMsg')
  vim.command("echom 'error: %s'" % (str(e).replace("'", "''"), ))
  vim.command('echohl None')
END_PY
endif
"}}}
function! s:System(expr, ...) "{{{
  if s:loaded_python == 0
    return a:0 > 0 ? system(a:expr, a:1) : system(a:expr)
  endif

  let output = ''
py << END_PY
try:
  if int(vim.eval('a:0')) > 0:
    vim.command("let output = '%s'" % (subprocess.Popen(vim.eval('a:expr'), stdout=subprocess.PIPE, stdin=subprocess.PIPE, shell=True).communicate(vim.eval('a:1'))[0].replace("'", "''"), ))
  else:
    vim.command("let output = '%s'" % (subprocess.Popen(vim.eval('a:expr'), stdout=subprocess.PIPE, stdin=subprocess.PIPE, shell=True).communicate()[0].replace("'", "''"), ))
except OSError, e:
  vim.command('echohl ErrorMsg')
  vim.command("echom 'error: %s'" % (str(e).replace("'", "''"), ))
  vim.command('echohl None')
END_PY
  return output
endfunction
"}}}
function! s:SystemList(expr, ...) "{{{
  if a:0 == 0
    let output = s:System(a:expr)
  else
    let input = type(a:1) == type([]) ? join(a:1, "\n") : a:1
    let output = s:System(a:expr, input)
  endif

  return split(output, '\r\?\n')
endfunction
"}}}
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
