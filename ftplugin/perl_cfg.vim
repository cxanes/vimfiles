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

if exists('*AddOptFiles')
  call AddOptFiles('dict', 'keywords/perl')
  if search('\<use\s\+Moose\>', 'nw')
    call AddOptFiles('dict', 'keywords/perl_moose')
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
" }}}
"===================================================================
" Key Mappings {{{
"-------------------------------------------------------------------
if exists('*CompleteParenMap')
  call CompleteParenMap('([{',  '[$@%&*]\|\w')
endif

if exists('*MoveToMap')
  call MoveToMap('[}\])]')
endif

if exists('*EnterMap')
  call EnterMap('{', '}')
endif

if exists('*CNewLine')
  inoremap <silent> <buffer> <C-J> <C-R>=CNewLine()<CR>
endif

if exists('*IndentForComment#IndentForCommentMapping')
  call IndentForComment#IndentForCommentMapping(['#'], [30, 45, 60])
endif

if exists('*StripSurrounding')
  nnoremap <silent> <buffer> <Leader>sf :call <SID>StripFunc()<CR>
  function! s:StripFunc()
    call StripSurrounding('\<\%(->\|::\)\@<!\%([a-zA-Z_{}][a-zA-Z0-9_{}]*\)\%(\%(->\|::\)[a-zA-Z_{}][a-zA-Z0-9_{}]*\)*\s*(', '', ')')
  endfunction
endif
" }}}
"===================================================================
" vim: fdm=marker :
