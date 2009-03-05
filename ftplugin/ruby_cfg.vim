" ruby configuration file
"===================================================================
" Settings {{{1
"-------------------------------------------------------------------
function! RunCommandRuby() 
  return ['ruby', expand('%:p')]
endfunction

" Avoid E705: Variable name conflicts with existing function.
unlet! b:run_command_ruby
let b:run_command_ruby = function('RunCommandRuby')

setlocal sw=2 ts=2
let &l:isk .= ',?,!,='
" }}}1
"===================================================================
" Functions {{{1
"-------------------------------------------------------------------
if !exists('s:load_ruby_cfg_func')
  let s:load_ruby_cfg_func = 1
  " xmpfilter <http://eigenclass.org/hiki/xmpfilter>
  if executable('xmpfilter')
    function! s:RubyXmpFilter(line1, line2, argv) "{{{
      let pos = getpos('.')
      exec printf('silent %d,%d!%s %s', a:line1, a:line2, 'xmpfilter', a:argv)

      " Since we use cygwin version of Ruby, the format of newline is '\n'.
      if &fileformat == 'dos'
        exec printf('silent %d,%ds///ge', a:line1, a:line2)
        call histdel('search', -1)
        let @/ = histget('search', -1)
      endif
      call setpos('.', pos)
    endfunction
    "}}}
    function! s:RubyRemoveEval(line1, line2) "{{{
      let pos = getpos('.')
      execute 'silent ' . a:line1 . ',' . a:line2 . 's/\s*# \(=>\|!>\).*$//e'
      call histdel('search', -1)
      let @/ = histget('search', -1)
      call setpos('.', pos)
    endfunction
    "}}}
  endif
  function! s:SID() "{{{
    if !exists('s:SID')
      let s:SID = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
    endif
    return s:SID
  endfunction
  "}}}
  function! s:GetOption(name, default) "{{{
    for scope in ['w:', 'b:', 'g:']
      if exists(scope . a:name)
        return eval(scope . a:name)
      endif
    endfor
    return a:default
  endfunction
  "}}}
  " rcodetools <http://eigenclass.org/hiki/rcodetools>
  " Modified from rcodetools/rcodetools.vim
  if executable('rct-complete') && executable('rct-doc')
    let [s:last_test_file, s:last_test_lineno] = ['', 0]

    let s:rct_tmpfile = ''
    let s:rct_completion_col = 0
    let s:rct_use_python = 0

    if !exists('g:rct_use_python') 
      let g:rct_use_python = 0
    endif

  " Python related functions {{{
    if has('python') && g:rct_use_python
      let s:rct_use_python = 1
      python import os, vim, re

  python <<EOF
def RCT_RubyComplete(command): #{{{
  f = os.popen(command)
  data = f.readlines()
  f.close()
  if len(data) == 0 or data[0] == "\n":
    return
  for dline in data:
    name, selector = dline.split("\t")
    vim.command("let l:item = {'word': '%s', 'menu': s:RCT_get_class('%s')}" % (name.replace("'", "''"), selector.replace("'", "''")))
    if (re.search(r'\bpreview\b', vim.eval('&completeopt'))
         and int(vim.eval("s:GetOption('rct_completion_use_fri', 0)")) 
         and int(vim.eval("s:GetOption('rct_completion_info_max_len', 20)")) >= len(data)):
      f = os.popen('fri -f plain "%s"' % selector.replace("'", "''"))
      fri_data = ''.join(f.readlines())
      f.close()
      if fri_data != '':
        vim.command("let l:item['info'] = '%s'" % fri_data.replace("'", "''"))
    vim.command("call complete_add(l:item)")
    if int(vim.eval('complete_check()')):
      break
#}}}
def RCT_Command(command): #{{{
  f = os.popen(command)
  data = f.readlines()
  f.close()
  return ''.join(data).strip()
#}}}
EOF
    endif
    "}}}
    function! s:RCT_system(command) "{{{
      let result = ''
      if g:rct_use_python && s:rct_use_python
        python <<EOF
try:
  vim.command("let result = '%s'" % RCT_Command(vim.eval('a:command')).replace("'", "''"))
except:
  pass
EOF
      else
        let result = system(a:command)
        if v:shell_error
          let result = ''
        endif
      endif
      return result
    endfunction
    "}}}
    function! s:RCT_command_with_test_options(cmd) "{{{
      if s:last_test_file != ""
        return a:cmd . printf(" --filename='%s' -t '%s@%d' ", 
              \ expand('%:p'), s:last_test_file, s:last_test_lineno)
      endif
      return a:cmd
    endfunction
    "}}}
    function! s:RCT_get_prototype(ri_data) "{{{
      let lbeg = stridx(a:ri_data, "\n")
      if lbeg == -1
        return ''
      endif
      let lend = stridx(a:ri_data, "\n", lbeg + 1)
      let line = a:ri_data[lbeg+1 : lend]
      return matchstr(line, '^\s*\zs[^( \t]\+\%(([^)]*)\)\?\%(\s*{[^}]*}\)\?')
    endfunction
    "}}}
    function! s:RCT_get_class(selector) "{{{
      let class = substitute(a:selector, '\n\|\s', '', 'g')
      let class = substitute(class, '\%([.#]\|::\).\+$', '', '')
      return class
    endfunction
    "}}}
    function! s:RCT_complete(command) "{{{
      if g:rct_use_python && s:rct_use_python
        python RCT_RubyComplete(vim.eval('a:command'))
      else
        let data = split(system(a:command), '\n')
        if empty(data)
          return
        endif

        for dline in data
          let parts    = split(dline, "\t")
          let name     = get(parts, 0)
          let selector = get(parts, 1)
          let item     = {'word': name, 'menu': s:RCT_get_class(selector)}
          if &completeopt =~ '\<preview\>' 
                \ && s:GetOption('rct_completion_use_fri', 0) 
                \ && s:GetOption('rct_completion_info_max_len', 20) >= len(data)
            let fri_data = system(printf("fri -f plain '%s' 2>/dev/null", selector))
            if fri_data != ''
              let item['info'] = fri_data
            endif
          endif
          call complete_add(item)
          if complete_check()
            break
          endif
        endfor
      endif
    endfunction
    "}}}
    function! s:RCT_completion(findstart, base) "{{{
      if a:findstart
        let s:rct_completion_col = col('.') - 1
        let s:rct_tmpfile = 'tmp-rcodetools' . strftime('Y-%m-%d-%H-%M-%S.rb')
        call writefile(getline(1, line('$')), s:rct_tmpfile)
        return strridx(getline('.'), '.', col('.')) + 1
      else
        let line    = line('.')
        let column  = s:rct_completion_col

        let command = printf('rct-complete --completion-class-info --dev --fork '
              \ . '--line=%d --column=%d ', line, column)
        let command = s:RCT_command_with_test_options(command) . s:rct_tmpfile
        call s:RCT_complete(command) 

        call delete(s:rct_tmpfile)
        return []
      endif
    endfunction
    "}}}
    function! s:RCT_get_method_name() "{{{
      let tmpfile = 'tmp-rcodetools' . strftime('Y-%m-%d-%H-%M-%S.rb')
      call writefile(getline(1, line('$')), tmpfile)
      let command = printf('rct-doc --line=%d --column=%d ', line('.'), col('.')-1)
      let command = s:RCT_command_with_test_options(command) . tmpfile
      let method  = s:RCT_system(command)
      call delete(tmpfile)
      return method =~ '\s' ? '' : method
    endfunction
    "}}}
    function! s:ManInput() 
      call inputsave()
      let name = input('method or class name: ', s:RCT_get_method_name())
      call inputrestore()
      return name
    endfunction
    function! s:RCT_ruby_toggle() "{{{
      let curr_file = expand('%:p')
      let cmd = 'ruby -S ruby-toggle-file ' . curr_file
      if match(curr_file, '\v_test|test_') != -1
        let s:last_test_file = curr_file
        let s:last_test_lineno = line('.')
      endif
      let dest = s:RCT_system(cmd)
      silent exec 'w'
      exec 'e ' dest
      silent! normal g;
    endfunction
    "}}}
  endif
endif
" }}}1
"===================================================================
" Commands {{{1
"-------------------------------------------------------------------
if exists('*s:RubyXmpFilter')
  command! -buffer -range=% -nargs=* RubyXmpFilter call <SID>RubyXmpFilter(<line1>, <line2>, <q-args>)
endif
if exists('*s:RubyRemoveEval')
  command! -buffer -range=% RubyRemoveEval call <SID>RubyRemoveEval(<line1>, <line2>)
endif
if exists('*s:RCT_get_method_name')
  let b:man_setting_ruby = { 'input': '<SNR>'.s:SID().'_ManInput' }
endif
" }}}1
"===================================================================
" Key Mappings {{{1
"-------------------------------------------------------------------
if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping(['#'], [30, 45, 60])
endif

if exists('*CompleteParenMap')
  call CompleteParenMap('([{')
endif

if exists('*MoveToMap')
  call MoveToMap('[{}\])]')
endif

if exists('*EnterMap')
  call EnterMap('{', '}')
endif

if exists('*AddOptFiles')
  call AddOptFiles('dict', 'keywords/ruby')
  set complete+=k
endif


if exists('g:use_codeintel') && g:use_codeintel
  setlocal completefunc=codeintel#Complete
else
  exec 'setlocal completefunc='.'<SNR>'.s:SID().'_RCT_completion'
endif

exec 'nnoremap <buffer> <silent>' . s:GetOption('RCT_toggle_binding', '<Leader>rt')
      \ . ' :call <SID>RCT_ruby_toggle()<CR>'
" }}}1
"===================================================================
" vim: fdm=marker :
