function! s:SetEnv() 
  function! s:GetPath(dirs)
    let path_list = []
    for dir in a:dirs
      let path = globpath(&rtp, dir)
      if path != ''
        call extend(path_list, split(path, '\n'))
      endif
    endfor
    if g:MSWIN
      call map(path_list, 'tr(v:val, ''/'', ''\'')')
    endif
    return path_list
  endfunction

  function! s:PrependEnv(env, path, ...) " ... = is_cyg 
    let is_cyg = a:0 > 0 ? a:1 : 0
    if g:MSWIN && is_cyg >= 0
      try
        let is_cyg = g:MSWIN && a:0 > 0 && !empty(a:1)
        return Cygwin#PrependEnv(a:env, a:path, is_cyg)
      catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
      endtry
    endif

    let path_sep = g:MSWIN ? ';' : ':'
    if empty(a:path)
      return a:env
    endif
    return join(a:path, path_sep) . (empty(a:env) ? '' : (path_sep . a:env))
  endfunction

  if g:MSWIN
    ru plugin/RubyDist.vim 
    ru plugin/PythonDist.vim
    ru plugin/PerlDist.vim
    let cyg_ruby   = exists('*GetRubyDist')   ? GetRubyDist()   == 'cygwin' : 1
    let cyg_python = exists('*GetPythonDist') ? GetPythonDist() == 'cygwin' : 0
    let cyg_perl   = exists('*GetPerlDist')   ? GetPerlDist()   == 'cygwin' : 1
  else
    let cyg_ruby    = 0
    let cyg_python  = 0
    let cyg_perl    = 0
  end

  let $PATH       = s:PrependEnv($PATH,       s:GetPath(['bin', (g:MSWIN ? 'bin/win' : 'bin/linux'), 'local/bin']), -1)
  let $RUBYLIB    = s:PrependEnv($RUBYLIB,    s:GetPath(['lib/ruby']),   cyg_ruby)
  let $PYTHONPATH = s:PrependEnv($PYTHONPATH, s:GetPath(['lib/python']), cyg_python)
  let $PERL5LIB   = s:PrependEnv($PERL5LIB,   s:GetPath(['lib/perl']),   cyg_perl)

  if g:MSWIN && has('python')
    " python.dll is loaded before $PYTHONPATH is set
    py import sys, os, vim
    py sys.path = [v for v in vim.eval('$PYTHONPATH').split(os.pathsep) if len(v) != 0] + sys.path
  endif

  if g:MSWIN && exists('*SetPerlDist') && exists('*GetPerlDist')
    call SetPerlDist(GetPerlDist())
  endif

  delfunction s:GetPath
  delfunction s:PrependEnv
endfunction

call s:SetEnv()
delfunction s:SetEnv

" vim: fdm=marker : ts=2 : sw=2 :
