" perl configuration file
"===================================================================
" Functions {{{
"-------------------------------------------------------------------
if !exists('*s:NewLine')
  function! s:NewLine() "{{{
    let newline = "\<C-O>o"

    let ch = getline('.')[col('.')-2]
    if col('.') == 1 || (ch != ';' && ch != '0')
      return newline
    endif

    if has('syntax_items')
          \ && synIDattr(synID(line('.'), col('.'), 0), 'name') =~? 'string\|comment'
      return newline
    endif

    if ch == ';' && getline('.') =~ '\<for\s*('
      return newline
    endif


    return "\<BS>\<C-O>A;" . (ch == ';' ? "\<CR>" : '')
  endfunction
  "}}}
endif

if !exists('*s:ExtractSubroutine')
  function! s:ExtractSubroutine(subName, beg_lnum, end_lnum) range
    let z_sav = @z

    " old code is stored in g:perl_old_code
    " new code is stored in g:perl_new_code
    silent exec printf('%d,%dy z', a:beg_lnum, a:end_lnum)
    let [newSubCall, g:perl_new_code] = PerlRefactor#ExtractSubroutine(a:subName, @z)
    let g:perl_old_code = @z
    let @z = z_sav

    let append = a:lastline == line('$')
    
    silent exec printf('%d,%dd _', a:beg_lnum, a:end_lnum)
    if append
      call append(line('.'), newSubCall)
      silent normal! j==
    else
      call append(line('.')-1, newSubCall)
      silent normal! k==
    endif
  endfunction

  function! s:PutExtractedSubroutine(lnum, before) 
    if !exists('g:perl_new_code')
      return
    endif

    silent exec printf('%dput%s =g:perl_new_code', a:lnum, a:before ? '!' : '')
    silent normal! '[V']==
  endfunction
endif
" }}}
"===================================================================
" Setting {{{
"-------------------------------------------------------------------
function! RunCommandPerl() 
  return ['perl', expand('%:p')]
endfunction

" Avoid E705: Variable name conflicts with existing function.
unlet! b:run_command_perl
let b:run_command_perl = function('RunCommandPerl')

compiler perl
set complete-=i

if exists('*mylib#AddOptFiles')
  call mylib#AddOptFiles('dict', 'keywords/perl')
  if search('\<use\s\+Moose\>', 'nw')
    call mylib#AddOptFiles('dict', 'keywords/perl_moose')
  endif
  set complete+=k
endif

" Set my own 'perlpath', since I use cygwin version perl in win32 vim.
" ref: $VIMRUNTIME/ftplugin/perl.vim
if (has('win16') || has('win32') || has('win64') || has('win95'))
      \ && !has('perl') && !exists('perlpath') && executable('perl') && executable('cygpath')
  " I don't use $_ directly because of the different interpretations in 
  " different shells (e.g. cmd.exe or bash.exe)
  if &shellxquote != '"'
    let perlpath = system('perl -MShell=cygpath -e "print map { cygpath(q{-m}, join q{}, split /(.+)/) } @INC"')
  else
    let perlpath = system("perl -MShell=cygpath -e 'print map { cygpath(q{-m}, join q{}, split /(.+)/) } @INC'")
  endif
  let perlpath = join(map(split(perlpath, '\n'), 'substitute(v:val, ''\([ ,]\)'', ''\\\1'', ''g'')'), ',')
  let perlpath = substitute(perlpath,',.$',',,','')
endif

if exists('g:use_codeintel') && g:use_codeintel
  setlocal completefunc=codeintel#Complete
endif
" }}}
"===================================================================
" Key Mappings and Commands {{{
"-------------------------------------------------------------------
command! -range -buffer -nargs=1 ExtractSubroutine call <SID>ExtractSubroutine(<q-args>, <line1>, <line2>)
command! -range -buffer -bang    PutExtractedSubroutine call <SID>PutExtractedSubroutine(<count>, <q-bang> == '!')

command! -range -buffer -nargs=1 ExtractMehod call <SID>ExtractSubroutine(<q-args>, <line1>, <line2>)
command! -range -buffer -bang    PutExtractedMehod call <SID>PutExtractedSubroutine(<count>, <q-bang> == '!')

if exists('*mapping#CompleteParen')
  call mapping#CompleteParen('([{',  '[$@%&*]\|\w')
endif

if exists('*mapping#MoveTo')
  call mapping#MoveTo('[}\])]')
endif

if exists('*mapping#Enter')
  call mapping#Enter('{', '}')
endif

if exists('*mylib#CNewLine')
  inoremap <silent> <buffer> <C-J> <C-R>=mylib#CNewLine()<CR>
endif

if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping(['#'], [30, 45, 60])
endif

if exists('*mylib#StripSurrounding')
  nnoremap <silent> <buffer> <Leader>sf :call <SID>StripFunc()<CR>
  function! s:StripFunc()
    call mylib#StripSurrounding('\<\%(->\|::\)\@<!\%([a-zA-Z_{}][a-zA-Z0-9_{}]*\)\%(\%(->\|::\)[a-zA-Z_{}][a-zA-Z0-9_{}]*\)*\s*(', '', ')')
  endfunction
endif
" }}}
"===================================================================
" vim: fdm=marker :
