" codeintel.vim
" Last Modified: 2009-03-06 13:00:39
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_codeintel')
  finish
endif
let loaded_autoload_codeintel = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"==========================================================
" Required vim compiled with +python {{{
if !has('python')
  echohl ErrorMsg
  echom "codeintel: error: Required vim compiled with +python"
  echohl None

  let &cpo = s:save_cpo
  unlet s:save_cpo
  finish
endif
"}}}
" Import codeintelvim python module {{{
let s:import_error = 0
py << PY_EOF
try:
  import vim
  import codeintelvim
except Exception, e:
  vim.command("let s:import_error = 1")
  vim.command('echohl ErrorMsg')
  vim.command("let g:codeintel_errmsg = '%s'" % (str(e).replace("'", "''"), ))
  vim.command("echom 'codeintel: error: ' . g:codeintel_errmsg")
  vim.command('echohl None')
PY_EOF
if s:import_error
  finish
endif
"}}}
"==========================================================
function! codeintel#ScanAllBuffers() "{{{
  py codeintelvim.scan_vimbufs()
endfunction
"}}}
function! codeintel#ScanCurrentBuffer() "{{{
  py codeintelvim.scan_vimbuf()
endfunction
"}}}
function! codeintel#ShowCalltips() "{{{
    py codeintelvim.get_calltips('calltips')
    if empty(calltips)
      echohl WarningMsg
      echo 'codeintel: no calltips are found'
      echohl None
      return
    endif

    if exists('*CreateTempBuffer')
      let curwinnum = winnr()
      let winnum = CreateTempBuffer('__codeintel_calltips__')
      exe winnum . 'wincmd w'
      silent %d_
      silent 1put =calltips
      silent 1d_
      exe curwinnum . 'wincmd w'
    else
      echo calltips
    endif
endfunction
"}}}
function! codeintel#Complete(findstart, base) "{{{
  if a:findstart
    let b:start = -1
    py codeintelvim.get_trg_chars('trg_chars')

    if empty(trg_chars)
      return b:start
    endif

    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && stridx(trg_chars, line[start - 1]) == -1
      let start -= 1
    endwhile
    if start > 0
      let b:start = start
    endif
    return b:start
  else
    if b:start == -1
      return []
    endif

    py codeintelvim.get_cplns('cplns')
    if empty(cplns)
      return []
    endif

    let res = []
    let pattern = '^\V' . escape(a:base, '\') 
    for [type, word] in cplns
      if word =~ pattern
        if type ==? 'function'
          let word .= '('
        endif
        let item = { 'word': word, 'kind': strlen(type) ? type[0] : ' ' }
        call add(res, item)
      endif
    endfor
    return res
  endif
endfunction
"}}}
"==========================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
