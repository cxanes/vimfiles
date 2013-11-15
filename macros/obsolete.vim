"============================================================{{{1
" Keymappings and Commands
"================================================================
" Commands {{{
if s:MSWIN
  " Update runtime files: "{{{
  " Ref: http://www.vim.org/runtime.php
  function! s:UpdateRuntimeFiles() 
    cd $VIMRUNTIME
    !rsync -avzcP ftp.nluug.nl::Vim/runtime/dos/ .
    cd -
  endfunction
  command! UpdateRuntimeFiles call s:UpdateRuntimeFiles()
  "}}}

  " Set transparent background "{{{
  " Ref: http://www.vim.org/scripts/script.php?script_id=687
  function! s:SetAlpha(value) 
    if empty(a:value)
      silent! call libcallnr('vimtweak.dll', 'SetAlpha', 255)
    else
      let value = a:value + 0
      if value == 0 || value > 255
        let value = 255
      endif
      silent! call libcallnr('vimtweak.dll', 'SetAlpha', value)
    endif
  endfunction
  command! -nargs=? SetAlpha call s:SetAlpha(<q-args>)
  "}}}
endif

let s:PIM_Dir              = !s:MSWIN  ? '~/private/' : isdirectory('D:/Private/') ? 'D:/Private/' : 'D:/Frank/'
let g:PIM_Account_Glob     = s:PIM_Dir . 'Account/*.account'
let g:PIM_Account          = s:PIM_Dir . printf('Account/%s.account', strftime('%Y'))
let g:PIM_Account_Category = s:PIM_Dir . 'Account/category'
let g:PIM_Log              = s:PIM_Dir . '/Log/log'
let g:PIM_Log_Category     = s:PIM_Dir . 'Log/category'
unlet! s:PIM_Dir

command! -nargs=? -complete=file -bang Account call PIM#Account#Open((empty(<q-args>) ? g:PIM_Account : <q-args>), <q-bang> == '!', g:PIM_Account_Category)
command! -nargs=? -complete=file -bang Log  call PIM#Log#Open((empty(<q-args>) ? g:PIM_Log : <q-args>), <q-bang> == '!', g:PIM_Log_Category)
"}}}
"}}}1
"============================================================{{{1
" Plugin configuration
" <http://www.vim.org/scripts/index.php>
"================================================================
  "----------------------------------------------------------{{{2
  " bash.vim (obsolete)
  " <http://www.vim.org/scripts/script.php?script_id=365>
  "--------------------------------------------------------------
  let g:BASH_LoadMenus  = 'no'
  let g:BASH_AuthorName = g:USER_INFO['name']
  let g:BASH_AuthorRef  = g:USER_INFO['ref']
  let g:BASH_Email      = g:USER_INFO['email']
  let g:BASH_Company    = ''
  "}}}2
  "----------------------------------------------------------{{{2
  " c.vim (obsolete)
  " <http://www.vim.org/scripts/script.php?script_id=213>
  "--------------------------------------------------------------
  let g:C_LoadMenus      = 'no'
  let g:C_AuthorName     = g:USER_INFO['name']
  let g:C_AuthorRef      = g:USER_INFO['ref']
  let g:C_Email          = g:USER_INFO['email']
  let g:C_Company        = ''
  let g:C_BraceOnNewLine = 'no'

  if s:MSWIN
    let s:plugin_dir  = $VIM.'\vimfiles\'
    let s:escfilename = ' '
  else
    let s:plugin_dir  = $HOME.'/.vim/'
    let s:escfilename = ' \%#[]'
  endif
  let s:plugin_dir = escape(s:plugin_dir, s:escfilename)

  if !exists("g:C_Dictionary_File")
    let g:C_Dictionary_File = s:plugin_dir.'c-support/wordlists/c-c++-keywords.list,'
    "        \                   .s:plugin_dir.'c-support/wordlists/k+r.list,'
    "        \                   .s:plugin_dir.'c-support/wordlists/stl_index.list'
  endif
  "}}}2
  "----------------------------------------------------------{{{2
  " perl.vim (obsolete)
  " <http://www.vim.org/scripts/script.php?script_id=556>
  "--------------------------------------------------------------
  let g:Perl_LoadMenus  = 'no'
  let g:Perl_AuthorName = g:USER_INFO['name']
  let g:Perl_AuthorRef  = g:USER_INFO['ref']
  let g:Perl_Email      = g:USER_INFO['email']
  let g:Perl_Company    = ''
  "}}}2
  "----------------------------------------------------------{{{2
  " codeintel.vim (My works)
  "
  " Codeintel is a sub-system used in Komodo Edit 
  " <http://www.activestate.com/komodo_edit> for 
  " autocomplete and calltips.
  "--------------------------------------------------------------
  if s:MSWIN
    let g:codeintel_dir = 'C:\My_Tools\codeintel\source\src\codeintel\lib'
    if !isdirectory(g:codeintel_dir)
      unlet g:codeintel_dir
    else
      let g:use_codeintel = 1
    endif
  endif
  "}}}2
  "----------------------------------------------------------{{{2
  " NoteManager.vim (My works) (obsolete: use WipidPad <http://wikidpad.sourceforge.net/> instead)
  "--------------------------------------------------------------
  " Load NoteManager.vim only when we need it.

  if globpath(&rtp, 'macros/NoteManager.vim') != ''
    command! LoadNoteManager call <SID>LoadNoteManager()

    function! s:LoadNoteManager() 
      let g:NoteManager_PySqlite = 1
      ru macros/NoteManager.vim

      " My own note-taking configuration
      if s:MSWIN && filereadable('E:/Notes/rc/nmrc')
        so E:/Notes/rc/nmrc
      endif
    endfunction
  endif
  "}}}2
"}}}1
