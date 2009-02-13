" vim configuration file
"===================================================================
" Settings {{{1
"-------------------------------------------------------------------
setlocal sw=2 ts=2
setlocal isk+=_
" }}}1
"===================================================================
" Commands {{{1
"-------------------------------------------------------------------
command! -range -nargs=0 Eval call <SID>EvalLine(<line1>, <line2>)
" }}}1
"===================================================================
" Key Mappings {{{1
"-------------------------------------------------------------------
if exists('*CompleteParenMap')
  call CompleteParenMap('([', '[''"]\|\w')
endif

if exists('*MoveToMap')
  call MoveToMap('[}\])]')
endif

if exists('*StripSurrounding')
  nnoremap <silent> <buffer> <Leader>sf :call <SID>StripFunc()<CR>
endif
" }}}1
"===================================================================
" Functions {{{1
"-------------------------------------------------------------------
" StripFunc() "{{{2
if exists('*StripSurrounding')
  if !exists('*s:StripFunc')
    function! s:StripFunc()
      let [lnum, col] = StripSurrounding('\<[a-zA-Z_{}][a-zA-Z0-9_{}]*\s*(', '', ')')
      if [lnum, col] == [0, 0]
        return
      endif

      let prefix_pat = '\%(\<[bwtglsav]:\|<[sS][iI][dD]>\)'
      let var_pat    = '\%([a-zA-Z0-9_]\+\.\)\+'
      let pat = printf('\%(%s\|%s\)', (prefix_pat . '\=' . var_pat), prefix_pat)
      let pos = searchpos(pat . (col == col('$') ? '$' : '\%#'), 'b')
      if pos != [0, 0]
        let pat_sav = @/
        exe 's/' . '\%#' . substitute(pat, '/', '\\/', 'g') . '//'
        let @/ = pat_sav
        call cursor(pos)
      endif
    endfunction
  endif
endif
" }}}2
" Eval() {{{2
if !exists('s:Eval')
  function! s:Eval(expr) "{{{
    if empty(a:expr)
      return
    endif

    " Because ':so FILE' will create a slot for sourced FILE (see
    " |:scriptname|), and we don't want to create too many temp script file
    " slots, we always use this temp script file to execute Ex command.
    if !exists('s:script_file')
      let s:script_file = tempname()
      au VimLeave * call delete(s:script_file)
    endif

    let expr = type(a:expr) == type([]) ? a:expr : split(a:expr, '\n')
    try
      call writefile(expr, s:script_file)
      exec 'so' s:script_file
    catch
      echohl ErrorMsg | echo v:exception | echohl None
    endtry
  endfunction
  "}}}
endif
if !exists('s:EvalLine')
  function! s:EvalLine(line1, ...) " ... = line2 (default: line1) {{{
    let [line1, line2] = [a:line1, (a:0 > 0 ? a:1 : a:line2)]
    let lines = []
    for line in getline(line1, line2)
      if match(line, '^\s*"') != -1
        continue
      endif

      if match(line, '^\s*\\') != -1
        if ! empty(lines)
          let lines[-1] .= substitute(line, '^\s*\\', '', '')
        endif
        continue
      endif

      call add(lines, line)
    endfor

    call s:Eval(lines)
  endfunction
  " }}}
endif
" }}}2
" TeXJumperCallback "{{{2
" For snippetsEmu.vim (my own version)
if !exists('*VimJumperCallback')
  let g:JumperCallback_vim = 'VimJumperCallback'
  function! VimJumperCallback() "{{{
    if has('syntax_items')
          \ && synIDattr(synID(line('.'), col('.'), 0), 'name') =~? 'string\|comment'
      return 0
    endif

    let lnum = line('.')
    let line = col('.') <= 2 ? '' : getline(lnum)[ : col('.') - 2]
    while line =~ '^\s*\\' && lnum > 2
      let lnum -= 1
      let line = getline(lnum) . substitute(line, '^\s*\\', '', '')
    endwhile

    if line == ''
      return 0
    endif

    let command_state = 0
    let option_state  = 1
    let value_state   = 2

    let set_pat  = '^[:|[:blank:]]*\%(se\%[t]\|setl\%[ocal]\)\s\+'
    let opt_pat0 = '^\w\+\%(\%(\s\)\@=\|$\)'
    let opt_pat1 = '^\w\+[-+]\?='
    let val_pat  = '^\%([^ \\|",]\+\|\%(\\[ \\|",]\)\+\)\+'

    let [opt, val] = ['', '']

    let state = command_state
    
    " Parse command-line {{{
    "
    " Only :set and :setlocal are recognized.
    " If there are mutiple commands in one line (separated by '|'),
    " all commands until reaching the cursor position must be 
    " either :set or :setlocal.
    while 1
      " echom 'state: <' . get({'0': 'command', '1': 'option', '2': 'value'}, state, 'command') . '>'
      " echom '[opt, val]:' string([opt, val])
      " echom 'line: |' . line . '|'
      " echom '--'

      if empty(line)
        break
      elseif state == command_state
        let [opt, val] = ['', '']
        if line =~ set_pat
          let state = option_state
          let line = substitute(line, set_pat, '', '')
        else
          break
        endif
      elseif state == option_state
        let val  = ''
        if line =~ opt_pat0
          let state = option_state
          let opt  = matchstr(line, opt_pat0)
          let line = substitute(line, opt_pat0, '', '')
          if line =~ '^\s\+'
            let opt = ''
            let line = substitute(line, '^\s\+', '', '')
          endif
        elseif line =~ opt_pat1
          let state = value_state
          let opt = substitute(matchstr(line, opt_pat1), '[-+]\?=$', '', '')
          let line = substitute(line, opt_pat1, '', '')
        else
          break
        endif
      elseif state == value_state
        if line =~ val_pat
          let state = value_state
          let val  = matchstr(line, val_pat)
          let line = substitute(line, val_pat, '', '')
        elseif line =~ '^\s*|'
          let state = command_state
          let [opt, val] = ['', '']
          let line = substitute(line, '^\s*|', '', '')
        elseif !empty(line) && line[0] == ','
          let state = value_state
          let val  = ''
          let line = substitute(line, '^,', '', '')
        elseif line =~ '^\s\+'
          let state = option_state
          let [opt, val] = ['', '']
          let line = substitute(line, '^\s\+', '', '')
        else
          break
        endif
      else
        break
      endif
    endwhile
    " }}}

    if state == option_state
      let startcol = col('.') - strlen(opt)
      if s:CompleteOpts(startcol, opt)
        return [1, '']
      endif
    elseif state == value_state
      let startcol = col('.') - strlen(val)
      if s:CompleteOptVals(startcol, opt, val)
        return [1, '']
      endif
    endif
  endfunction
  " }}}
  function! s:CompleteOptVals(startcol, opt, val) "{{{
    let val_pat = '^\V' . escape(a:val, '\')
    let vals = []
    try 
      if s:HasGetOptVals == 1
        let vals = myutils#GetOptVals(a:opt)
      endif
    catch
      let s:HasGetOptVals = 0
      let vals = []
    endtry

    let vals = filter(vals, 'v:val =~ val_pat')
    if empty(vals)
      return 0
    endi

    call complete(a:startcol, vals)
    return 1
  endfunction
  "}}}
  function! s:CompleteOpts(startcol, opt) "{{{
    let opt_pat = '^\V' . escape(a:opt, '\')
    let options = []
    for opt in s:GetOptions()
      if opt =~ opt_pat
        call add(options, opt)
      endif
    endfor

    call complete(a:startcol, options)
    return 1
  endfunction
  "}}}
  function! s:GetOptions() "{{{
    if exists('s:VimOptions')
      return s:VimOptions
    endif

    let s:VimOptions = []

    " copy from syntaxcomplete.vim
    let saveL = @l
    
    redir @l
    silent! exec 'syntax list vimOption'
    redir END

    let syntax_full = @l
    let @l = saveL

    if syntax_full =~ 'E28' 
                \ || syntax_full =~ 'E411'
                \ || syntax_full =~ 'E415'
                \ || syntax_full =~ 'No Syntax items'
        return s:VimOptions
    endif

    let syntax_full = substitute(syntax_full, '^vimOption\s\+xxx\s\+', '', '')
    call substitute(syntax_full, "contained\\s\\+[^\n]\\+", '\=s:AddOption(s:VimOptions, submatch(0))', 'g')
    call sort(s:VimOptions)

    return s:VimOptions
  endfunction
  "}}}
  function! s:AddOption(options, line) "{{{
    let line = substitute(a:line, '^\s*contained\s\+', '', '')
    call extend(a:options, split(line, '\s\+'))
    return ''
  endfunction
  "}}}
  let s:HasGetOptVals = 1
endif
" }}}2
" VimExpandTagCallback "{{{
if !exists('*VimExpandTagCallback')
  function! VimExpandTagCallback(col) "{{{
    let line = a:col > 1 ? getline('.')[0 : a:col-1] : ''
    if line !~ '^\s*\w\+\c$'
      return 0
    endif

    return -1
  endfunction
  "}}}
endif
let g:ExpandTagCallback_{&ft} = 'VimExpandTagCallback'
"}}}
" }}}1
"===================================================================
" vim: fdm=marker :
