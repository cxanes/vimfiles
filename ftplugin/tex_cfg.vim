" TeX configuration file
"===================================================================
" Settings {{{
"------------------------------------------------------------
setlocal tw=78
if !exists('*Tex_PutEnvironment')
  ru ftplugin/tex_latexSuite.vim
endif

if exists('*mylib#AddOptFiles')
  call mylib#AddOptFiles('dict', 'keywords/tex')
  call mylib#AddOptFiles('dict', split(globpath(&rtp, 'keywords/tex_*'), "\n"))
  set complete+=k
endif

function! SetMakePrgTeX() 
  if exists('*SetMakeprg') && exists('g:Tex_DefaultTargetFormat')
    if !empty(glob('Makefile'))
      return
    endif
    call SetMakeprg('-' . g:Tex_DefaultTargetFormat) 
  endif
endfunction

unlet! b:set_makeprg_tex
let b:set_makeprg_tex = 'SetMakePrgTeX'
" }}}
"===================================================================
" Functions {{{
"------------------------------------------------------------
" StripCommand() "{{{2
if exists('*mylib#StripSurrounding') && !exists('*s:StripCommand')
  function! s:StripCommand()
    call mylib#StripSurrounding('\\\w\+\s*{', '', '}')
  endfunction
endif
" }}}2
" InsertEnvironment() "{{{2
if exists('*Tex_PutEnvironment') && !exists('*s:InsertEnvironment')
  function! s:InsertEnvironment(mode)
    let keepa = @a
    if a:mode ==? 'v'
      normal! gv"ay
    else
      normal! "ayiW
    endif
    let env = @a
    let @a = keepa
    let len = strlen(substitute(env, '.', 'x', 'g'))
    return repeat("\<Del>", len) . Tex_PutEnvironment(env)
  endfunction
endif
"}}}2
" TeXPreview() "{{{2
if !exists('*s:TeXPreview') && executable('tex2img')
  function! s:GetPreamble()
    let s_save = @s
    try
      silent 1,/^\s*\\begin{document}/-1y s
      let preamble = @s
    catch
      let preamble = ''
    endtry
    let @s = s_save
    return preamble
  endfunction

  function! s:TeXPreview()
    let s_save = @s
    silent normal! gv"sy
    let tex = @s
    let @s = s_save
    if tex =~ '^\s*$'
      return
    endif

    let preamble = s:GetPreamble()
    let b:preamble = preamble == '' ? '' : (preamble . "\n\\pagestyle{empty}")

    if b:preamble != ''
      let preamble_file = tempname()
      exe 'redir! > ' . preamble_file
      silent! echo b:preamble
      redir END
    else
      let preamble_file = ''
    endif

    if exists('*mylib#GetPos')
      let pos = mylib#GetPos()
    else
      let pos = { 'x': getwinposy(), 'y': getwinposy() }
    endif

    let tex_file = tempname()
    exe 'redir! > ' . tex_file
    silent! echo tex
    redir END

    " exec 'silent !'.escape(printf('tex2img -l "%d+%d" %s "%s"', pos.x, pos.y, 
    "       \ (preamble_file == '' ? '' : ('-p "' . preamble_file . '"')), tex_file), '\!')
    call system(printf('tex2img -l "%d+%d" %s "%s"', pos.x, pos.y, 
          \ (preamble_file == '' ? '' : ('-p "' . preamble_file . '"')), tex_file))
    let error = v:shell_error

    call delete(tex_file) 
    if preamble_file != ''
      call delete(preamble_file) 
    endif
    " redraw!
    if error
      echohl ErrorMsg | echo 'TeXPreview: The image cannot be rendered.' | echohl None
    endif
  endfunction
endif
"}}}2
" TeXCheck() "{{{2
" lacheck <http://www.ctan.org/tex-archive/support/lacheck/>
if executable('lacheck') && !exists('*s:TeXCheck')
  function! s:TeXCheck()
    if &ft != 'tex'
      return
    endif
    let makeprg_sav = &makeprg
    let efm_sav = &l:efm
    set makeprg=lacheck\ %
    setlocal efm=\"%f\"\\,\ line\ %l:\ %m
    make
    let &l:efm = efm_sav
    let &makeprg = makeprg_sav
  endfunction
endif
"}}}2
" TeXDoc() "{{{2
if !exists('*TeXPackageComplete')
  function! TeXPackageComplete(A, L, P)
    let pos = getpos('.')
    call cursor(1, 1)
    let lnum = search('\\begin{document}', 'cnW')
    call setpos('.', pos)
    if lnum == 0
      return ''
    endif
    let packages = []
    for i in range(1, lnum)
      let str = matchstr(getline(i), '\\usepackage\%(\[.*\]\)\?{\zs[^}]\+\ze}')
      let str = substitute(str, '^\s\+\|\s\+$', '', 'g')
      for package in split(str, '\s*,\s*')
        if index(packages, package) == -1
          call add(packages, package)
        endif
      endfor
    endfor
    return join(packages, "\n")
  endfunction
endif

if executable('texdoc') && !exists('*s:TeXDoc')
  command! -nargs=1 -buffer -complete=custom,TeXPackageComplete 
        \ TeXDoc call s:TeXDoc(<q-args>)

  function! s:TeXDoc(package)
    let info = system('texdoc "' . a:package . '"')
    let info = substitute(info, '\r\?\n$', '', 'g')
    if info != ''
      echohl ErrorMsg | echo info | echohl None
    endif
  endfunction
endif
" }}}2
" TeXSymbolSelector: lss <http://clay.ll.pl/lss/> {{{2
if !exists('s:LssCmd') && has('gui_running') && has('clientserver')
  function s:LssSetup()
    let s:LssCmd = ''
    if !executable('lss')
      return
    endif
    let is_mswin = has('win32') || has('win64') || has('win16') || has('win95')

    " NOTE: I add the option '-s' to specify the servername, this option
    "       doesn't exist in original version of lss.
    if is_mswin
      let s:LssCmd = 'silent ! START /MIN "" lss -s '''.v:servername.''' --display :0 && exit'
    else
      let s:LssCmd = 'silent !lss -s '''.v:servername.''' &'
    endif

    command! TeXSymbolSelector exec s:LssCmd|startinsert
  endfunction

  call s:LssSetup()
endif
" }}}2
" TeXJumperCallback "{{{2
" For snippetsEmu.vim (my own version)
if !exists('*TeXJumperCallback')
  let g:JumperCallback_tex = 'TeXJumperCallback'
  function! TeXJumperCallback() "{{{
    if exists('*Tex_Complete')
      let [slnum, scol] = searchpos('\\\w\{-}\%(\[.\{-}\]\)\?{\w*\%#', 'n')
      if [slnum, scol] == [0, 0]
        let [slnum, scol] = searchpos('\\\w\{-}\%(\[.\{-}\]\)\?\%#{', 'n')
        if [slnum, scol] == [0, 0]
          return
        endif
      endif

      if getline('.')[col('.')-1] =~ '\w'
        return
      endif

      let pos = getpos('.')
      call cursor(slnum, scol)

      let curline = getline(slnum)[scol-1 : ]
      let type = matchstr(curline, '^\\\zs\w\{-}\ze\%(\[.\{-}\]\)\?{')
      let close = search('}', 'cn', line('.')) == 0
      let [lnum, col] = searchpos('\\\w\{-}\%(\[.\{-}\]\)\?{', 'cen', line('.'))
      let icol = col == 0 ? col('.') : col('$') == col + 1 ? col('$') : col + 1

      call setpos('.', pos)
      let prefix = icol > col('.') ? '' : getline('.')[icol-1 : col('.')-1]

      if type =~ '^\%(ref\|cite\)$'
        call Tex_Complete('default', 'text')
        return [1, "\<ESC>"]
      elseif type =~ '^\%(includegraphics\|psfig\)$'
        call complete(icol, s:GetFile('.', '*.{pdf,ps,pdf,png,jpg}', '', 1, close, prefix))
        return [1, '']
      elseif type =~ '^bibliography$'
        call complete(icol, s:GetFile('.', '*.bib', '', 0, close, prefix))
        return [1, '']
      elseif type =~ '^include\%(only\)\?$'
        call complete(icol, s:GetFile('.', '*.t??', '', 0, close, prefix))
        return [1, '']
      elseif type =~ '^input$'
        call complete(icol, s:GetFile('.', '*', '', 1, close, prefix))
        return [1, '']
      endif
    endif
  endfunction
  " }}}
  function! s:GetFile(dir, accept, reject, ext, close, prefix) "{{{
    let prefix = '^' . substitute(a:prefix, '}$', '', '')
    let files = []
    for file in map(split(globpath(a:dir, a:accept), "\n"), 'fnamemodify(v:val, ":p:t")')
      if (a:reject == '' || file !~ a:reject) && file =~ prefix
        call add(files, file)
      endif
    endfor

    let complete = []
    for file in files
      let root = fnamemodify(file, ':r')
      let ext  = '.' . fnamemodify(file, ':e')
      call add(complete, 
            \ { 
            \   'word': root . (a:ext ? ext : '') . (a:close ? '}' : ''),
            \   'abbr': root . (a:ext ? ext : ''),
            \   'menu': file,
            \ })
    endfor
    return complete
  endfunction
  " }}}
endif
"}}}2
if has('python') && !exists('g:texvim_py_loaded')
  py <<END_PY
import vim
import subprocess
import os
try:
  import texvim
  vim.command('let g:texvim_py_loaded = 1')
except ImportError:
  vim.command('let g:texvim_py_loaded = 0')
END_PY
end

if g:texvim_py_loaded
  if !exists('*s:TeXToc')
    function! s:TeXToc(filename) "{{{
      if empty(a:filename)
        py texvim.Outline(vim.current.buffer).show()
      else
        py texvim.Outline(vim.eval("fnamemodify(a:filename, ':p')")).show()
      endif
    endfunction
    "}}}
  end

  " Add SyncTeX support in MSWIN with Sumatra PDF viewer
  " 
  " References:
  "
  "   http://william.famille-blum.org/blog/static.php?page=static081010-000413
  "   http://william.famille-blum.org/blog/index.php?entry=entry080515-065447
  "   http://william.famille-blum.org/blog/index.php?entry=entry081007-214408
  "   http://sourceforge.net/apps/mediawiki/skim-app/index.php?title=TeX_and_PDF_Synchronization
  if !exists('*s:TeXSync') "{{{
    function! s:GuessPDFFile() "{{{ 
      let file = expand('%:p')
      if !empty(file)
        let pdf_file = fnamemodify(file, ':r') . '.pdf'
        if filereadable(pdf_file)
          return pdf_file
        end
      end
      return ''
    endfunction
    "}}}
    function! s:TeXSync(...) "{{{
      let setfocus = a:0 && a:1

      let TeX_PDF_File = ''
      if exists('b:TeX_PDF_File')
        let TeX_PDF_File = b:TeX_PDF_File
      elseif exists('g:TeX_PDF_File')
        let TeX_PDF_File = g:TeX_PDF_File
      else
        let TeX_PDF_File = s:GuessPDFFile()
      end

      if empty(TeX_PDF_File)
        echohl ErrorMsg
        echo "TeXSync: The variable TeX_PDF_File (b: or g:) doesn't exist or is empty."
        echohl None
        return
      end

      if has('clientserver')
        let servername = v:servername
      else
        let servername = ''
      end

      let pdf_viewer = ['C:\My_Tools\SumatraPDF\SumatraPDF.exe', '-inverse-search', 'pythonw "C:\Program Files\Vim\vimfiles\bin\tex-open-vim.py" "%f" %l %c' . (empty(servername)?'': (' ' . servername)), '-reuse-instance']
      py subprocess.Popen(vim.eval('pdf_viewer'))

      let TeX_PDF_File = fnamemodify(TeX_PDF_File, ':p')

      let ssl_sav = &ssl
      let &ssl = 0
      py subprocess.Popen(["pythonw", r"C:\Program Files\Vim\vimfiles\bin\dde-sumatra-pdf.py", "ForwardSearch" , vim.eval('TeX_PDF_File'), vim.eval("expand('%:p')") , vim.eval("line('.')"), vim.eval("col('.')"), '0', vim.eval("setfocus")])
      let &ssl = ssl_sav
    endfunction
    "}}}
    function! s:TeXSetPDF(pdf_file, ...) "{{{
      let isbuf = a:0 && a:1
      let {['g:','b:'][isbuf]}TeX_PDF_File = a:pdf_file
    endfunction
    "}}}
  end
  "}}}
endif
" }}}
"===================================================================
" Keymappings and Commnads {{{
"------------------------------------------------------------
if exists('*s:TeXPreview')
  vnoremap <silent> <buffer> <Leader>v :<C-U>call <SID>TeXPreview()<CR>
endif

if exists('*s:InsertEnvironment')
  vnoremap <silent> <buffer> <Leader>ie "_yi<C-R>=<SID>InsertEnvironment('v')<CR>
  nnoremap <silent> <buffer> <Leader>ie "_yiwi<C-R>=<SID>InsertEnvironment('n')<CR>
endif

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[}\]]')
endif

if exists('*s:StripCommand')
  nnoremap <silent> <buffer> <Leader>sc :call <SID>StripCommand()<CR>
endif

if exists('*s:TeXCheck')
  command! -buffer TeXCheck call s:TeXCheck()
endif

command! -nargs=* -bang -buffer MakeXeTeX make<bang> -e "UseXeTeX()" <args>

if exists('*s:TeXToc')
  command! -nargs=? -complete=file -buffer TeXToc call <SID>TeXToc(<q-args>)
endif

if exists('*s:TeXSync')
  command! -nargs=0 -bang -buffer TeXSync call <SID>TeXSync(<q-bang> == '!')
  nnoremap <silent> <buffer> <Leader>ss :<C-U>call <SID>TeXSync(v:count)<CR>

  command! -nargs=1 -complete=file -buffer TeXSetPDF call <SID>TeXSetPDF(<q-args>, <q-bang> == '!')
end
" }}}
"===================================================================
" vim: fdm=marker :
