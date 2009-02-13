"        File: snippetsEmu.vim
"      Author: Felix Ingram
"              ( f.ingram.lists <AT> gmail.com )
" Description: An attempt to implement TextMate style Snippets. Features include
"              automatic cursor placement and command execution.
"     Version: 1.2 (modified)
"
" This file contains some simple functions that attempt to emulate some of the 
" behaviour of 'Snippets' from the OS X editor TextMate, in particular the
" variable bouncing and replacement behaviour.
"
" Ref: http://en.wikipedia.org/wiki/Code_snippets
" {{{1 *ATTENTION* This script has been modified by Frank Chang.
"                     ( frank.nevermind <AT> gmail.com )
"       BUG FIXED:
"         1. When command contains input-like function (e.g. inputlist),
"             the script doesn't work properly (e.g. the tag cannot be
"             replaced). The problem may be caused by the 'paste' option.
"           => ':redraw' the screen before returning from the function.
"
"       NEW FEATURES:
"         1. Empty tag with command: <{:command}>
"           => The command will be executed immediately and replace its tag. It 
"              is different from |snip-snippet-commands|, which is executed
"              before the snippet is inserted.
"
"              It has the same effect as {"\<C-R>=" . command} in insert mode.
"
"         2. Tag with default value: <{{default}}>
"           => If the tag name has the format like '{tag}', it will be taken as
"              the default value of this tag but not a named-tag, which means
"              other '{tag}'s will not be replaced when user presses <Tab>.
"
"              It also can be followed by a command: <{{default}:command}>.
"
"         3. Anonymous function in 'command': <{tag:{expr}}>
"           => If command has the format '{...}', it treats all text between
"              braces to be the content of the anonymous function.
"         
"         4. Anonymous function in |snip-snippet-commands|: ``{expr}``
"           => If command has the format '{...}', it treats all text between
"              braces to be the content of the anonymous function.
"
"         5. Provide some new utility functions:
"            (1) SnippetSelect(list, ...): Create a inputlist and return the 
"                  selected one.
"
"            (2) SnippetQuery(prompt, ...): Query the string from the user.
"
"            (3) If2(x, y): empty(x) ? y : x
"
"            (4) SnippetSetCommand(key, fn, type):
"                  ref: TextMate variable: TM_SELECTED_TEXT
"
"            (5) SnippetInsert(snippet): Directly insert a snippet.
"
"            (6) SnippetInTag: Check whether we're in a tag
"
"            Please refer to the comments of these functions for details.
"
"         6. Provide some new commands:
"
"            (1) ShowSnippet & ShowIabbr:
"                 Show specific snippet or create new snippet in buffer.
"
"            (2) ShowSnippetInit & ShowIabbrInit:
"                 Show specific initial file in buffer.
"
"            (3) LoadSnippets & LoadIabbr: 
"                 Load all snippets in the with the same 'filetype'.
"
"            (4) UnloadSnippets & UnloadIabbr:
"                 Unload all snippets in the with the same 'filetype'.
"
"            (5) ToggleSnippetsMenu: Toggle Snippets Menu
"
"         7. Add new map: <S-Tab>
"           => It doesn't expand the tag.
"              (The mapping key can be customized by the variable 
"               g:snippetsEmu_noexp_key.)
"
"         8. Add some new global variable:
"            (1) g:snippetsEmu_setup_menu (0|[1]|"menu_level"): Let user decide whether
"                  to setup the snippet menu or not.
"
"            (2) g:snippetsEmu_autoload ([0]|1): The filetype-related
"                  snippets will be loaded when the file is edited.
"
"            (3) g:snippetsEmu_load_dir ("snippets"):
"                  The directory under 'runtimepath', which contains all 
"                  snippets.
"
"            (4) g:snippetsEmu_noexp_key ("<S-Tab>"): Map to <SID>Jumper 
"                  which doesn't expand the tag.
"
"            (5) g:snippetsEmu_special_vars, b:snippetsEmu_special_vars: 
"                  Define your own |snip-special-vars|.
"                  The type is Dictionary, each key is a variable (pattern),
"                  and it will be replaced by the value (expansion).
"
"                  e.g. let g:snippetsEmu_special_vars = 
"                         \ { '\<SNIP_FILE_NAME\>' : 'expand("%")' }
"
"            (6) g:snippetsEmu_trigger_in_word ([0]|1):
"                 Expand the trigger even just meet the last part of the word.
"
"            (7) g:snippetsEmu_break_undo_sequences ([1]|0)
"                 When insert new snippet, break undo sequence first.
"                 See |i_CTRL-G_u|.
"
"         9. Add 'snippetsEmu_JumperCallback' function handler:
"
"            If you have define a 'JumperCallback()' function and assign this
"            function name to g:snippetsEmu_JumperCallback, then the 
"            'JumperCallback()' function will be executed when you 
"            press <Tab>. If the return value is [1, '...'], the string 
"            part will be returned.
"
"        10. Add 'snippetsEmu_ExpandTagCallback' function handler:
"
"            If you have define a 'ExpandTagCallback()' function and assign this
"            function name to g:snippetsEmu_ExpandTagCallback, then the 
"            'ExpandTagCallback()' function will be executed when you press <Tab>. 
"
"            If it returns 1 the tag will be expanded, and 0 means don't expand 
"            the tag; -1 falls back to its default action.
"
"            The prototype of function 'ExpandTagCallback()' is: ExpandTagCallback(col)
"            col is the column of the cursor.
" }}}1
" {{{1 USAGE:
"
" Place the file in your plugin directory.
" Define snippets using the Snippet command.
" Snippets are best defined in the 'after' subdirectory of your Vim home
" directory ('~/.vim/after' on Unix). Filetype specific snippets can be defined
" in '~/.vim/after/ftplugin/<filetype>_snippets.vim. Using the <buffer> argument will
" By default snippets are buffer specific. To define general snippets available
" globally use the 'Iabbr' command.
"
" Example One:
" Snippet fori for <{datum}> in <{data}>:<CR><{datum}>.<{}>
"
" The above will expand to the following (indenting may differ):
" 
" for <{datum}> in <{data}>:
"   <{datum}>.<{}>
" 
" The cursor will be placed after the first '<{' in insert mode.
" Pressing <Tab> will 'tab' to the next place marker (<{data}>) in
" insert mode.  Adding text between <{ and }> and then hitting <{Tab}> will
" remove the angle brackets and replace all markers with a similar identifier.
"
" Example Two:
" With the cursor at the pipe, hitting <Tab> will replace:
" for <{MyVariableName|datum}> in <{data}>:
"   <{datum}>.<{}>
"
" with (the pipe shows the cursor placement):
"
" for MyVariableName in <{data}>:
"   MyVariableName.<{}>
" 
" Enjoy.
"
" For more information please see the documentation accompanying this plugin.
"
" Additional Features:
"
" Commands in tags. Anything after a ':' in a tag will be run with Vim's
" 'execute' command. The value entered by the user (or the tag name if no change
" has been made) is passed in the @z register (the original contents of the
" register are restored once the command has been run).
"
" Named Tags. Naming a tag (the <{datum}> tag in the example above) and changing
" the value will cause all other tags with the same name to be changed to the
" same value (as illustrated in the above example). Not changing the value and
" hitting <Tab> will cause the tag's name to be used as the default value.
"
" Test tags for pattern matching:
" The following are examples of valid and invalid tags. Whitespace can only be
" used in a tag name if the name is enclosed in quotes.
"
" Valid tags
" <{}>
" <{tagName}>
" <{tagName:command}>
" <{"Tag Name"}>
" <{"Tag Name":command}>
"
" Invalid tags, random text
" <{:}>
" <{:command}>
" <{Tag Name}>
" <{Tag Name:command}>
" <{"Tag Name":}>
" <{Tag }>
" <{OpenTag
"
" Here's our magic search term (assumes '<{',':' and '}>' as our tag delimiters:
" <{\([^[:punct:] \t]\{-}\|".\{-}"\)\(:[^}>]\{-1,}\)\?}>
" }}}1

" {{{1 This script requires Vim 7.0 (or later)
if v:version < 700
  echom 'snippetsEmu plugin requires Vim version 7 or later'
  finish
endif
" }}}1
" {{{1 Load Once
let s:debug = 0

if (exists('loaded_snippet') || &cp) && !s:debug
  finish
endif
let loaded_snippet = 1
let s:save_cpo = &cpo
set cpo&vim
" }}}1
" {{{1 Old Version Detection
if globpath(&rtp, 'plugin/snippetEmu.vim') != ''
  call confirm("It looks like you've got an old version of snippetsEmu installed. "
        \ . "Please delete the file 'snippetEmu.vim' from the plugin directory. "
        \ . "Note lack of 's'")
endif

let s:Disable = 0
" }}}1
" {{{1 Global Settings
let g:snippetsEmu_start_tag       = '<{'
let g:snippetsEmu_end_tag         = '}>'
let g:snippetsEmu_elem_delim      = ':'
let g:snippetsEmu_key             = '<Tab>'
let g:snippetsEmu_noexp_key       = '<S-Tab>'
let g:snippetsEmu_exp_in_tag      = 0
let g:snippetsEmu_setup_menu      = 0
let g:snippetsEmu_autoload        = 1
let g:snippetsEmu_load_dir        = 'snippets'
let g:snippetsEmu_trigger_in_word = 0
let g:snippetsEmu_break_undo_sequences = 1
let g:snippetsEmu_IMAP_Jumpfunc   = 1

" For original version
let g:snip_start_tag  = g:snippetsEmu_start_tag
let g:snip_end_tag    = g:snippetsEmu_end_tag
let g:snip_elem_delim = g:snippetsEmu_elem_delim
" }}}1
" {{{1 Menu Support
function! LoadSnippetsMenu(toplevel) " {{{
  if exists('g:snippetsEmu_menu') && g:snippetsEmu_menu == 1
    exec 'silent! nunmenu '.a:toplevel.'Snippets'
    exec 'silent! iunmenu '.a:toplevel.'Snippets'
    let g:snippetsEmu_menu = 0
  else
    let dirs = split(globpath(&rtp, simplify(g:snippetsEmu_load_dir . '/*')), '\n')
    call filter(dirs, 'isdirectory(v:val)')
    call map(dirs, "fnamemodify(v:val, ':t')")

    let global_idx = index(dirs, 'global', 0, 1)
    if global_idx != -1
      let ft = dirs[global_idx]
      call remove(dirs, global_idx)
      exec 'nmenu <silent> .100 '.a:toplevel."Snippets.Iabbr :call <SID>LoadSnippets('g:', '".ft."')<CR>"
      exec 'imenu <silent> .100 '.a:toplevel."Snippets.Iabbr <C-O>:call <SID>LoadSnippets('g:', '".ft."')<CR>"
      exec 'nmenu <silent> .100 '.a:toplevel.'Snippets.-Sep- :'
    endif

    for ft in dirs
      exec 'nmenu <silent> '.a:toplevel.'Snippets.'.ft." :call <SID>LoadSnippets('b:', '".ft."')<CR>"
      exec 'imenu <silent> '.a:toplevel.'Snippets.'.ft." <C-O>:call <SID>LoadSnippets('b:', '".ft."')<CR>"
    endfor
    let g:snippetsEmu_menu = 1
  endif
endfunction
" }}}
if type(g:snippetsEmu_setup_menu) == 0 && g:snippetsEmu_setup_menu != 0
  call LoadSnippetsMenu('')
elseif type(g:snippetsEmu_setup_menu) == 1
  call LoadSnippetsMenu(g:snippetsEmu_setup_menu)
endif
" }}}1
" {{{1 Autoload Snippets Support
if !empty(g:snippetsEmu_autoload)
  augroup snippetsEmu
    au!
    au FileType * 
          \ if exists('loaded_snippet') |
          \   if exists('b:snippetsEmu_filetype') |
          \     call s:UnloadSnippets('b:', b:snippetsEmu_filetype) |
          \   endif |
          \   let b:snippetsEmu_filetype = expand('<amatch>') |
          \   call s:LoadSnippets('b:', expand('<amatch>')) |
          \ endif
    au VimEnter *
          \ if exists('loaded_snippet') |
          \   call s:LoadSnippets('g:', 'global') |
          \ endif
  augroup END
endif
" }}}1
" {{{1 Sort out supertab
function! s:GetSuperTabSNR() " {{{
  let a_sav = @a
  redir @a
  exec 'silent function'
  redir END
  let funclist = @a
  let @a = a_sav
  let func = split(split(matchstr(funclist,'.SNR.\{-}SuperTab(command)'),'\n')[-1])[1]
  return matchlist(func, '\(.*\)S')[1]
endfunction
" }}}
function! s:SetupSupertab() " {{{
  if !exists('s:supInstalled')
    let s:supInstalled = 0
  endif
  if s:supInstalled == 1 || globpath(&rtp, 'plugin/supertab.vim') != ''
    let s:supInstalled = 1
  endif
endfunction
" }}}
" }}}1
" {{{1 Default Mappings
function! s:SnipMapKeys() " {{{
  call s:SetupSupertab()
  if (!hasmapto('<Plug>Jumper', 'i'))
    if s:supInstalled == 1
      exec 'imap ' . g:snippetsEmu_key       . ' <Plug>Jumper'
      exec 'imap ' . g:snippetsEmu_noexp_key . ' <Plug>NoExpJumper'
    else
      exec 'imap <unique> ' . g:snippetsEmu_key       . ' <Plug>Jumper'
      exec 'imap <unique> ' . g:snippetsEmu_noexp_key . ' <Plug>NoExpJumper'
    endif
  endif

  if (!hasmapto( 'i<BS>'.g:snippetsEmu_key, 's'))
    exec 'smap <unique> ' . g:snippetsEmu_key       . ' i<BS>' . g:snippetsEmu_key
    exec 'smap <unique> ' . g:snippetsEmu_noexp_key . ' i<BS>' . g:snippetsEmu_noexp_key
  endif
endfunction
" }}}
call s:SnipMapKeys()
imap <silent> <script> <Plug>Jumper      <C-R>=<SID>Jumper()<CR>
imap <silent> <script> <Plug>NoExpJumper <C-R>=<SID>Jumper(1)<CR>
" }}}1
" {{{1 Command Definitions 
"   Set up the 'Iabbr' and 'Snippet' related commands
"
command! -complete=custom,s:ListGlobalSnippets -nargs=*
      \ Iabbr               call <SID>SetCom(<q-args>, 'g:')
command! -complete=custom,s:ListBufferSnippets -nargs=* -bang
      \ Snippet             call <SID>SetCom(<q-args>, 'b:', expand('<bang>'))

command! -complete=custom,s:ListBufferSnippets2 -nargs=+ -bang
      \ DelSnippet          call <SID>DelSnippet(<q-bang> == '!', 'b:', <f-args>)
command! -complete=custom,s:ListGlobalSnippets -nargs=+ -bang
      \ DelIabbr            call <SID>DelSnippet(<q-bang> == '!', 'g:', <f-args>)

command! -complete=custom,s:ListBufferSnippets2 -nargs=+ -bang
      \ ShowSnippet         call <SID>ShowSnippet(0, expand('<bang>'), 'b:', <f-args>)
command! -complete=custom,s:ListGlobalSnippets -nargs=+ -bang
      \ ShowIabbr           call <SID>ShowSnippet(0, expand('<bang>'), 'g:', <q-args>)

command! -complete=custom,s:ListLoadedFileType -nargs=? -bang
      \ ShowSnippetInit     call <SID>ShowSnippet(1, expand('<bang>'), 'b:', '', <q-args>)
command! -nargs=0 -bang
      \ ShowIabbrInit       call <SID>ShowSnippet(1, expand('<bang>'), 'g:', '')

command! -complete=custom,s:ListAvailableFileType -nargs=1
      \ LoadSnippets        call <SID>LoadSnippets('b:', <q-args>)
command! -nargs=0
      \ LoadIabbr           call <SID>LoadSnippets('g:', 'global')

command! -complete=custom,s:ListLoadedFileType -nargs=?
      \ UnloadSnippets      call <SID>UnloadSnippets('b:', <q-args>)
command! -nargs=0
      \ UnloadIabbr         call <SID>UnloadSnippets('g:', expand('<bang>'))

command! -nargs=0 
      \ ToggleSnippetsMenu  call LoadSnippetsMenu()
command! -range 
      \ CreateSnippet       <line1>,<line2>call s:CreateSnippet()
command! -range 
      \ CreateBundleSnippet <line1>,<line2>call s:CreateBundleSnippet()

command! -complete=custom,s:ListAvailableFileType -nargs=1
      \ BrowseSnippets      call <SID>BrowseSnippets(<q-args>)
command! -nargs=0
      \ BrowseIabbr         call <SID>BrowseSnippets('global')
" }}}1
" {{{1 Class: SnippetStorage
" All snippets defined in files will be stroed here.
" Public  Method: ctor {{{2
function! s:NewSnippetStorage() 
  return  { 
        \   'storage': {},
        \   'Add'    : function('s:SnippetStorage_Add'),
        \   'Get'    : function('s:SnippetStorage_Get'),
        \   'Delete' : function('s:SnippetStorage_Delete'),
        \ }
endfunction
" }}}2
" Public  Method: Add {{{2
function! s:SnippetStorage_Add(trigger, filetype, ...) dict
  if a:filetype =~ '^\s*$'
    return
  endif

  if !has_key(self.storage, a:filetype)
    let self.storage[a:filetype] = {}
  endif

  if !has_key(self.storage[a:filetype], a:trigger)
    let self.storage[a:filetype][a:trigger] = [0, '']
  else
    let reload = a:0 > 1 && a:1 != 0
    if reload
      let self.storage[a:filetype][a:trigger][1] = ''
    else
      let self.storage[a:filetype][a:trigger][0] += 1
    endif
  endif
endfunction
" }}}2
" Public  Method: Get {{{2
function! s:SnippetStorage_Get(trigger, filetype) dict
  if !has_key(self.storage, a:filetype)
    return ''
  elseif !has_key(self.storage[a:filetype], a:trigger)
    return ''
  elseif self.storage[a:filetype][a:trigger][1] != ''
    return self.storage[a:filetype][a:trigger][1]
  endif

  let file = s:GetSnipFile(a:filetype, a:trigger)
  if file == ''
    return ''
  endif

  let snip = join(readfile(file), '<CR>')
  if snip == ''
    return ''
  endif

  let snip = s:TextProc(snip)
  let self.storage[a:filetype][a:trigger][1] = snip
  return snip
endfunction
" }}}2
" Public  Method: Delete {{{2
function! s:SnippetStorage_Delete(delete_file, trigger, filetype) dict
  if !has_key(self.storage, a:filetype)
    return
  elseif !has_key(self.storage[a:filetype], a:trigger)
    return
  elseif self.storage[a:filetype][a:trigger][0] > 0
    let self.storage[a:filetype][a:trigger][0] -= 1
  endif

  if !empty(a:delete_file)
    let self.storage[a:filetype][a:trigger][0] = 0
    let file = s:GetSnipFile(a:filetype, a:trigger)
    if file != ''
			let choice = confirm(printf("Delete Snippet/Iabbr '%s' permanently?", a:trigger), "&Yes\n&No", 1)
      if choice == 1
        call delete(file)
      endif
    endif
  endif

  if self.storage[a:filetype][a:trigger][0] <= 0
    unlet self.storage[a:filetype][a:trigger]
  endif
endfunction
" }}}2
" }}}1
" {{{1 Class: Snippet
" Public  Method: ctor {{{2
function! s:NewSnippet(...) 
  let self = {
        \   'snippet' : {' ' : {}},
        \   'filetype': [' '],
        \   'Add'     : function('s:Snippet_Add'),
        \   'Delete'  : function('s:Snippet_Delete'),
        \   'Get'     : function('s:Snippet_Get'),
        \   'Show'    : function('s:Snippet_Show'),
        \   'Exists'  : function('s:Snippet_Exists'),
        \ }
  if a:0 == 0
    if !exists('g:snippetsEmu_SnippetStorage')
      let g:snippetsEmu_SnippetStorage = s:NewSnippetStorage()
    endif
    let self['storage'] = g:snippetsEmu_SnippetStorage
  else
    let self['storage'] = a:1
  endif
  return self
endfunction
" }}}2
" Public  Method: Add {{{2
function! s:Snippet_Add(trigger, snippet, filetype) dict
  " filetype == ' ' always has the highest priority.
  let filetype = a:filetype == '' ? ' ' : a:filetype
  if !has_key(self.snippet, filetype)
    let self.snippet[filetype] = {}
    call insert(self.filetype, filetype, 1)
  endif
  
  " The snippet is defined in the file.
  if a:snippet == ''
    if has_key(self.snippet[filetype], a:trigger)
      " The a:trigger has been set, reload the snippet
      call self.storage.Add(a:trigger, filetype, 1)
    else
      call self.storage.Add(a:trigger, filetype)
    endif
  endif

  let self.snippet[filetype][a:trigger] = s:TextProc(a:snippet)
endfunction
" }}}2
" Public  Method: Get {{{2
function! s:Snippet_Get(trigger, ...) dict " ...=filetype
  let filetypes = a:0 > 0 ? [a:1] : self.filetype
  for ft in filetypes
    if ft != '' && has_key(self.snippet, ft) 
          \ && a:trigger != '' && has_key(self.snippet[ft], a:trigger)
          \ && self.snippet[ft][a:trigger] != ''
      return a:0 > 0 ? self.snippet[ft][a:trigger] : [self.snippet[ft][a:trigger], ft]
    endif
  endfor

  if a:0 > 0
    return self.storage.Get(a:trigger, a:1)
  endif

  for ft in self.filetype
    let snippet = self.storage.Get(a:trigger, ft)
    if snippet != ''
      return [snippet, ft]
    endif
  endfor

  return []
endfunction
" }}}2
" Public  Method: Delete {{{2
function! s:Snippet_Delete(delete_file, trigger, filetype, ...) dict " ...=select
  if a:trigger == '' && a:filetype == ''
    if a:0 == 0 || a:1 == 0
      return 0
    else  " delete all snippets
      for ft in self.filetype
        for trig in self.snippet[ft]
          call self.storage.Delete(a:delete_file, trig, ft)
        endfor
      endfor

      let self.snippet  = {' ': {}}
      let self.filetype = [' ']
      return 0
    endif
  elseif a:trigger != '' && a:filetype != ''
    if has_key(self.snippet, a:filetype)
          \ && has_key(self.snippet[a:filetype], a:trigger)
      unlet self.snippet[a:filetype][a:trigger]
      call self.storage.Delete(a:delete_file, a:trigger, a:filetype)
      return 0
    else
      return 1
    endif
  elseif a:filetype != ''
    if has_key(self.snippet, a:filetype)
      let idx = a:filetype =~ '^\s\+$' ? -1 : index(self.filetype, a:filetype)
      if idx != -1
        call remove(self.filetype, idx)
      endif
      for trig in keys(self.snippet[a:filetype])
        call self.storage.Delete(a:delete_file, trig, a:filetype)
      endfor
      if a:filetype !~ '^\s\+$'
        unlet self.snippet[a:filetype]
      endif
      return 0
    else
      return 1
    endif
  else " a:trigger != ''
    let has_trigger = 0
    let delete_one = (a:0 > 0 && a:1 == 1)
    for ft in self.filetype
      if has_key(self.snippet[ft], a:trigger)
        unlet self.snippet[ft][a:trigger]
        call self.storage.Delete(a:delete_file, a:trigger, ft)
        let has_trigger = 1
        if delete_one
          break
        endif
      endif
    endfor
    return has_trigger ? 0 : 1
  endif
endfunction
" }}}2
" Public  Method: Show {{{2
function! s:Snippet_Show(trigger, filetype, ...) dict " ...=select
  if a:trigger == '' && a:filetype == ''
    if a:0 == 0 || a:1 == 0
      return self.filetype
    else
      let triggers = []
      for ft in self.filetype
        for trig in sort(keys(self.snippet[ft]))
          call add(triggers, [trig, ft])
        endfor
      endfor
      return triggers
    endif
  elseif a:trigger != '' && a:filetype != ''
    if has_key(self.snippet, a:filetype)
          \ && has_key(self.snippet[a:filetype], a:trigger)
      return self.snippet[a:filetype][a:trigger]
    endif
  elseif a:filetype != ''
    if has_key(self.snippet, a:filetype)
      " triggers
      return sort(keys(self.snippet[a:filetype]))
    endif
  else " a:trigger != ''
    let snippets = []
    for ft in self.filetype
      if has_key(self.snippet[ft], a:trigger)
        call add(snippets, [self.Get(a:trigger, ft), ft])
      endif
    endfor
    return snippets
  endif
endfunction
" }}}2
" Public  Method: Exists {{{2
function! s:Snippet_Exists(trigger, filetype) dict
  if a:trigger == '' && a:filetype == ''
    return 0
  elseif a:trigger != '' && a:filetype != ''
    return  has_key(self.snippet, a:filetype)
          \ && has_key(self.snippet[a:filetype], a:trigger)
  elseif a:filetype != ''
    return has_key(self.snippet, a:filetype)
  else " a:trigger != ''
    for ft in self.filetype
      if has_key(self.snippet[ft], a:trigger)
        return 1
      endif
    endfor
    return 0
  endif
endfunction
" }}}2
" }}}1
" {{{1 Utility Functions: Debugging
function! s:Debug(func, text)
  if exists('s:debug') && s:debug == 1
    echom 'snippetsEmu: '.a:func.': '.a:text
  endif
endfunction
" }}}1
" {{{1 Utility Functions: Local
" {{{2 ShowMesg()
function! s:ShowMesg(mesg) 
  echohl ErrorMsg | echom 'snippetsEmu: ' . a:mesg | echohl None
endfunction
" }}}2
" {{{2 TextProc()
function! s:TextProc(text)
  if a:text == ''
    return ''
  endif

  let text = substitute(a:text, 
        \ '\c<CR>\|<Esc>\|<Tab>\|<BS>\|<Space>\|<C-G>\|<Bar>\|"\|\\\|<lt>', '\\&', 'g')
  " let text = substitute(text, '\r$', '', '')
  exec 'return "'.text.'"'
endfunction
" }}}2
" {{{2 GetSnipLoadDir() - Strip leading or following '/' in g:snippetsEmu_load_dir.
function! s:GetSnipLoadDir()
  return substitute(g:snippetsEmu_load_dir, '^[\\/]\+\|[\\/]\+$', '', 'g')
endfunction
" }}}2
" {{{2 GetSnipLoadDir()
function! s:GetSnipFile(filetype, trigger)
  let snip_load_dir = s:GetSnipLoadDir()
  for pattern in ['%s/%s/%s.snip.*', '%s/%s/%s.snip']
    let files = globpath(&rtp, printf(pattern, 
          \ snip_load_dir, a:filetype, s:Hash(a:trigger)))
    if files != ''
      return split(files, "\n")[0]
    endif
  endfor

  return ''
endfunction
" }}}2
" {{{2 s:Hash() - Encode the special characters.
"   s:Hash allows the use of special characters in snippets
"   This function is lifted straight from the imaps.vim plugin. Please let me know
"   if this is against licensing.
"
function! s:Hash(text)
	return substitute(a:text, '\([^a-zA-Z0-9]\)',
				\ '\="_".char2nr(submatch(1))."_"', 'g')
endfunction
" }}}2
" {{{2 s:UnHash() - Decode the special characters.
" s:UnHash allows the use of special characters in snippets
" This function is lifted straight from the imaps.vim plugin. Please let me know
" if this is against licensing.
"
function! s:UnHash(text)
	return substitute(a:text, '_\(\d\+\)_', '\=nr2char(submatch(1))', 'g')
endfunction
" }}}2
" {{{2 ChopTags() - Chops tags from any text passed to it
function! s:ChopTags(text)
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()
  return a:text[strlen(snip_start_tag):-strlen(snip_end_tag)-1]
endfunction
" }}}2
" {{{2 StrLen() - The length of the string containing multi-byte characters.
"   This function ensures we measure string lengths correctly
"
function! s:StrLen(str)
  return strlen(substitute(a:str, '.', 'x', 'g'))
endfunction
" }}}2
" {{{2 LiteralPattern()
function! s:LiteralPattern(pat)
  return '\V'.escape(a:pat, '\').(&magic ? '\m' : '\M')
endfunction
" }}}2
" {{{2 SID() - Get the SID for the current script
function! s:SID()
  if !exists('s:SID')
    let s:SID = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
  endif
  return s:SID
endfun
" }}}2
" {{{2 Indent(text)
function! s:Indent(text)
  let indent_text = matchstr(getline('.'), '^\s\+')
  return substitute(a:text, "\<CR>", '&'.indent_text, 'g')
endfunction
" }}}2
" }}}1
" {{{1 Utility functions: Global
" {{{2 If2(x, y) := empty(x) ? y : x
function! If2(x, y)
  return empty(a:x) ? a:y : a:x
endfunction
" }}}2
" {{{2 D(): This function will just return what's passed to it unless a change has been made
function! D(text)
  return (exists('s:CHANGED_VAL') && s:CHANGED_VAL == 1) ? @z : a:text
endfunction
" }}}2
" {{{2 SnippetSelect(): Create a inputlist and let user select item. (ref: |inputlist|)
"
"   SnippetSelect([item1, item2, ...])
"   SnippetSelect([[abbr1, item1], [abbr2, item2], ...])
"   SnippetSelect(prompt, ...)
"
"   e.g. <{:SnippetSelect(["yes", "no"])}>
"
function! SnippetSelect(list, ...)
  if a:0 > 0
    let prompt = a:list
    let list = a:1
  else
    let prompt = 'Select: '
    let list = a:list
  endif

  if type(list) != type([])
    return ''
  endif

  let brief = [prompt]
  let full  = ['']
  let idx = 1
  for item in list
    if (type(item) == 3 && len(item) > 1)
      call add(brief, printf('%d. %s', idx, item[0]))
      call add(full , item[1])
    else
      call add(brief, printf('%d. %s', idx, item))
      call add(full , item)
    endif
    let idx += 1
  endfor
  redraw
  call inputsave()
  let idx = inputlist(brief)
  call inputrestore()
  if idx <= 0 || idx >= len(brief)
    return ''
  endif
  return full[idx]
endfunction
" }}}2
" {{{2 SnippetQuery(): Query the replaced string (ref: |input|)
"
"   e.g. <{:SnippetQuery("Any question? ", "no")}>
"
function! SnippetQuery(prompt, ...)
  redraw
  call inputsave()
  if a:0 > 0
    if a:0 > 1
      let res = input(a:prompt, a:1, a:2)
    else
      let res = input(a:prompt, a:1)
    endif
  else
    let res = input(a:prompt)
  endif
  call inputrestore()
  return res
endfunction
" }}}2
" {{{2 SnippetSetCommand()
"   mode := [lsw]+
function! SnippetSetCommand(key, fn, mode) " {{{
  if type(a:mode) != 1 || !exists('*'.a:fn)
    if !exists('*'.a:fn)
      call s:ShowMesg('SnippetSetCommand: The function '''.a:fn.''' doesn''t exist.')
    endif
    return
  endif

  let fn = substitute(a:fn, "'", "''", 'g')
  " Selected text
  "  's': whole
  "  'l': line by line
  for mode in ['s', 'l']
    if stridx(a:mode, mode) != -1
      exec 'vnoremap <silent> <buffer> '.a:key
        \ .' :<C-U>call '
        \ ."<SID>GetSelectedText('".mode."', function('".fn."'))<CR>"
        \ .'<C-R>=<SID>Jumper(0, 1, 1)<CR>'
    endif
  endfor

  " Word
  if stridx(a:mode, 'w') != -1
    exec 'inoremap <silent> <buffer> '.a:key
      \ ." <C-R>=<SID>GetWord(function('".fn."'))<CR>"
      \ .'<C-R>=<SID>Jumper(0, 1, 1)<CR>'
  endif
endfunction
" }}}
" {{{3 GetSelectedText()
"   mode: 's'|'' (whole), 'l' (line by line)
function! s:Identity(v) " {{{
  return a:v
endfunction
" }}}
function! s:GetSelectedText(mode, cmd) " {{{
  let s:snip_save = @z
  let s_save = @s
  let @z = ''
  let type = visualmode()

  " For KillRing.vim, which uses @" to detect all deleted and pasted text.
  let qq_save = @"
  normal! gv"sd
  let @" = qq_save
  let text = @s
  try
    " Block-wise Visual Mode
    if type == "\<C-V>"
      let cs = getpos("'<")[2]-2
      let slen = cs + 1

      let [ls, le] = [getpos("'<")[1], getpos("'>")[1]]

      let Func = a:mode == 'l' ? function('s:Identity') : a:cmd
      let lines = split(Func(text), '\n', 1)
      let Func = a:mode != 'l' ? function('s:Identity') : a:cmd

      let line = getline(ls)
      let @z = Func(lines[0]).line[cs+1:]
      call setline(ls, strpart(line, 0, slen))

      for lnum in range(ls+1, le-1)
        let line = getline(ls+1)
        let len = strlen(line)
        if len < slen
          let @z = @z."\n".line.repeat(' ', slen-len).Func(lines[lnum-ls])
        else
          let @z = @z."\n".strpart(line, 0, slen).Func(lines[lnum-ls]).line[cs+1:]
        endif
        call setline(ls+1, '')
        normal! gJ
      endfor

      if (ls != le)
        let line = getline(ls+1)
        let @z = @z."\n".strpart(line, 0, slen).Func(lines[le-ls])
        call setline(ls+1, line[cs+1:])
        normal! gJ
      endif
    " Visual mode linewise (line by line)
    elseif type == 'V' && a:mode == 'l'
      let lines = split(text, '\n', 1)
      call remove(lines, -1)
      call map(lines, 'a:cmd(v:val)')
      if line("'[") != line('.')
        let @z = "\n".join(lines, "\n")
        startinsert!
      else
        let @z = join(lines, "\n").(line('.') == line('$') ? '' : "\n")
        startinsert
      endif
    " Visual mode linewise (whole)
    elseif type == 'V' && a:mode == 's'
      if line("'[") != line('.')
        let @z = "\n".a:cmd(text)
        startinsert!
      else
        let @z = a:cmd(text)
        startinsert
      endif
    " Ohter modes
    else
      let @z = a:cmd(text)
    endif
  catch
    call s:ShowMesg('Selected Text Filter: '.string(a:cmd).': '.v:exception)
    let @z = text
  finally
    let @s = s_save
  endtry
  silent! normal! `[
  if col("'<") == col('.')
    startinsert
  else
    startinsert!
  endif
endfunction
" }}}
" }}}3
" {{{3 GetWord()
function! s:GetWord(cmd)
  let word = matchstr(strpart(getline('.'), 0, col('.')-1), '\w*$')
  let delWord = repeat("\<BS>", s:StrLen(word))
  let s:snip_save = @z
  try
    let @z = a:cmd(word)
  catch
    call s:ShowMesg('Get Word Filter: '.string(a:cmd).': '.v:exception)
    let @z = word
  endtry
  return delWord
endfunction
" }}}3
" }}}2
" {{{2 SnippetInsert()
function! SnippetInsert(snippet)
  call s:SetSearchStrings()
  let s:snip_save = @z
  let @z = s:TextProc(a:snippet)
  exec "normal! i\<C-R>=\<SID>Jumper(0, 1)\<CR>"
  if col('.') + 1 == col('$')
    startinsert!
  elseif col('.') == col('$')
    startinsert
  else
    normal! l
    startinsert
  endif
endfunction
" }}}2
" {{{ SnippetReturnKey() - Return our mapped key or Supertab key
function! SnippetReturnKey(...)  " ... = feedkeys
  if ! (pumvisible() && s:supInstalled)
    if exists('b:snippetsEmu_IMAP_Jumpfunc')
      let snippetsEmu_IMAP_Jumpfunc = b:snippetsEmu_IMAP_Jumpfunc
    else
      let snippetsEmu_IMAP_Jumpfunc = g:snippetsEmu_IMAP_Jumpfunc
    endif

    if exists('*IMAP_Jumpfunc') && snippetsEmu_IMAP_Jumpfunc != 0
      let imap_jump = IMAP_Jumpfunc('', 0)
      if !empty(imap_jump)
        return imap_jump
      endif
    endif
  endif

  if s:supInstalled
    if a:0 > 0 && a:1 != 0
      " In CTRL-X mode, the key "\<C-N>" is not mapped, since it's valid key 
      " (see Notes following |complete_CTRL-Y|), so we can't call the function
      " SuperTab() directly with the assumption of "\<C-N>" being always mapped
      " in insert mode (CTRL-X mode is a sub-mode of insert mode).
      "
      " The expression of "\<C-R>=" will not be remapped, which means
      " "\<C-N>" serves as the original command |i_CTRL-N| but not the command
      " SuperTab provides, so we use function |feedkeys()| to enter the key.
      "
      " Be careful of using function feedkeys(): Because it adds given keys to
      " the END of the typeahead buffer, the command execution order may be
      " different as you expect.
      "
      " Example:
      "    function! One()
      "      call feedkeys('1')
      "      return ''
      "    endfunction
      "
      "    In insertmode:
      "
      "    <C-R>=One() . '2'
      "
      "    gives '21' in buffer.
      "
      call feedkeys("\<C-N>")
      return ''
    else
      if !exists('s:SupSNR')
        let s:SupSNR = s:GetSuperTabSNR()
      endif
      return "\<C-R>=".s:SupSNR."SuperTab('n')\<CR>"
    endif
  endif

  " We need this hacky line as the one below doesn't seem to work.
  " Patches welcome
  exe 'return "'.substitute(g:snippetsEmu_key, '^<', '\\<', '').'"'
endfunction
" }}}
" {{{ SnippetInTag() - Check whether we're in a tag
function! SnippetInTag() 
  return s:CheckForInTag()
endfunction
" }}}
" {{{ SnippetHash() - Encode the special characters.
function! SnippetHash(text)
	return s:Hash(a:text)
endfunction
" }}}
" {{{ SnippetUnHash() - Decode the special characters.
function! SnippetUnHash(text)
	return s:UnHash(a:text)
endfunction
" }}}
" }}}1
" {{{1 Functions: Environment setting
" {{{ SetLocalTagVars()
function! SetLocalTagVars()
  if exists('b:snippetsEmu_end_tag') && exists('b:snippetsEmu_start_tag') && exists('b:snippetsEmu_elem_delim')
        \ && b:snippetsEmu_end_tag != '' && b:snippetsEmu_start_tag != '' && b:snippetsEmu_elem_delim != ''
    return [b:snippetsEmu_start_tag, b:snippetsEmu_elem_delim, b:snippetsEmu_end_tag]
  else
    return [g:snippetsEmu_start_tag, g:snippetsEmu_elem_delim, g:snippetsEmu_end_tag]
  endif
endfunction
" }}}
" {{{ SetSearchStrings() - Set the search string. Checks for buffer dependence
function! s:SetSearchStrings()
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()
  let g:search_str = snip_start_tag.
        \ '\([^'.snip_start_tag.snip_end_tag.
        \ '[:punct:] \t]\{-}\|".\{-}"\|\[.\{-}\]\|{.\{-}}\)\('.
        \ snip_elem_delim.
        \ '\_.\{-}\)\?'.snip_end_tag
endfunction
" }}}
" }}}1
" {{{1 Functions: Jumper-related
" {{{ RestoreSearch()
"   Restores hlsearch and @/ if there are no more tags in the scope.
function! s:RestoreSearch()
  if !search(b:search_str, 'n', s:GetSnipScope()[1])
    if exists('b:hl_on') && b:hl_on == 1
      setlocal hlsearch
    endif
    if exists('b:search_sav')
      let @/ = b:search_sav
      unlet b:search_sav
    endif
  endif
endfunction
" }}}
" {{{ SetUpTags()
function! s:SetUpTags()
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()
  if (strpart(getline('.'), col('.')+strlen(snip_start_tag)-1, strlen(snip_end_tag)) == snip_end_tag) " Found an empty tag
    let b:tag_name = ''
    call s:RestoreSearch()
    redraw
    return repeat("\<Del>", s:StrLen(snip_start_tag) + s:StrLen(snip_end_tag))
  else
    " Not on an empty tag so it must be a normal tag
    let b:tag_name = s:ChopTags(matchstr(getline('.'), b:search_str, col('.')-1))

    let start_skip = repeat("\<Right>", s:StrLen(snip_start_tag)+1)
    if col('.') == 1
      " We're at the start of the line so don't need to skip 
      " the first char of start tag
      let start_skip = start_skip[strlen("\<Right>"):]
    endif
    if s:IsEmptyTag(b:tag_name)
      let end_skip = &selection == 'exclusive' ? 'i' : 'a'
      let key = "\<C-\>\<C-O>".'"_d/'.snip_end_tag."/e\<CR>\<C-\>\<C-N>"
            \ . end_skip."\<C-R>=<SNR>".s:SID()."_ChangeVals(0)\<CR>"
            \ . "\<C-R>=<SNR>".s:SID()."_Jumper()\<CR>" 
    else
      " Check for exclusive selection mode. If exclusive is not set then we need to
      " move back a character.
      let end_skip = &selection == 'exclusive' ? '' : 'h'
      let key = "\<Esc>".start_skip.'v/'.snip_end_tag."\<CR>"
            \ .end_skip."\<C-G>" 
    endif
    " redraw
    return key
  endif
endfunction
" }}}
" {{{ NextHop() - Jump to the next tag if one is available
function! <SID>NextHop()
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()

  let [start, end] = s:GetSnipScope()
  if exists('b:snippetsEmu_scope_isset') 
        \ && b:snippetsEmu_scope_isset == 1
        \ && end - 1 > start
    let b:snippetsEmu_scope_isset = 0
    call s:SetSnipScope(0, end-1)
  endif

  " First check to see if we have any tags on lines above the current one
  let pos = getpos('.')
  call cursor(start, 1)
  let tag_pos = searchpos(b:search_str, 'cn', end-1)
  call setpos('.', pos)

  if tag_pos != [0, 0]
    " We have previous tags, so we'll jump to the start
    call call('cursor', tag_pos)
  endif

  " If the first match is after the current cursor position or not on this
  " line...
  if match(getline('.'), b:search_str) >= col('.')-1 
        \ || match(getline('.'), b:search_str) == -1
    " Perform a search to jump to the next tag
    if search(b:search_str, 'c') != 0
      redraw
      return s:SetUpTags()
    else
      " there are no more matches
      " Restore hlsarch and @/
      call s:RestoreSearch()
      call s:ResetEmptyTag()
      redraw
      return ''
    endif
  else
    " The match on the current line is on or before the cursor, so we need to
    " move the cursor back
    while col('.') > match(getline('.'), b:search_str) + 1
      normal! h
    endwhile
    " Now we just set up the tag as usual
    redraw
    return s:SetUpTags()
  endif
endfunction
" }}}
" {{{ RunCommand() - Execute commands stored in tags
function! s:RunCommand(command, z)
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()
  let command = substitute(a:command, '\%(^\_s\+\)\|\%(\_s\+$\)', '', 'g')
  if command == ''
    return a:z
  endif
  " Save current value of 'z'
  let [snip_save, @z] = [@z, a:z]
  try 
    " Anonymous function
    if command =~ '^{\_.\+}$'
      let command = substitute(substitute(command[1:-2], "\<CR>", "\n", 'g'), '\n\s*\\', '', 'g')
      exec "func! s:SnipAnonymousFunc()\n".command."\nendfunc"
      let ret = s:SnipAnonymousFunc()
    else
      " Call the command
      exec 'let ret = '. command
    endif
  catch
    call s:ShowMesg('<'.b:tag_name.'> Command: '.command.': '.v:exception)
    let ret = ''
  finally
    " Replace the value
    let @z = snip_save
  endtry
  return s:TextProc(ret)
endfunction
" }}}
" {{{ ChangeVals() - Set up values for MakeChanges()
function! s:ChangeVals(changed)
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()

  let s:CHANGED_VAL = a:changed == 1 ? 1 : 0

  let elem_match = match(s:line, snip_elem_delim, s:curCurs)

  let tagstart = searchpos(s:LiteralPattern(snip_start_tag), 'bnW')
  let tagstart[1] = tagstart[1] -1 + strlen(snip_start_tag)

  try
    let commandToRun = b:command_dict[b:tag_name][0]
    unlet b:command_dict[b:tag_name][0]
  catch
    " E175: Could not find this key in the dict
    let commandToRun = ''
  endtry

  let endPos = [s:curLine, s:curCurs]
  if s:CHANGED_VAL
    " The value has changed so we need to grab our current position back
    " to the start of the tag

    if strpart(getline(s:curLine), s:curCurs, strlen(snip_end_tag)) != snip_end_tag
      let pos = searchpos(s:LiteralPattern(snip_end_tag), 'nW')
      if pos != [0, 0]
        let pos[1] = pos[1] - 1
        let endPos = pos
      endif
    endif

    if tagstart[0] == endPos[0]
      let replaceVal = strpart(getline('.'), tagstart[1], endPos[1]-tagstart[1])
    else
      let lines = getline(tagstart[0], endPos[0])
      let lines[0] = strpart(lines[0], tagstart[1])
      let lines[-1] =  strpart(lines[-1], 0, endPos[1])
      let replaceVal = join(lines, "\n")
    endif
    let tagmatch = replaceVal
    exec 'normal! '.s:StrLen(tagmatch)."\<Left>"
  else
    " The value hasn't changed so it's just the tag name
    " without any quotes that are around it
    let replaceVal = b:tag_name
    if (match(b:tag_name, '^".*"$') != -1)
      let replaceVal = substitute(b:tag_name, '\m^"\(.*\)"$', '\1', '')
    elseif (match(b:tag_name, '\m^{.*}$') != -1)
      let replaceVal = substitute(b:tag_name, '\m^{\(.*\)}$', '\1', '')
    elseif (s:IsEmptyTag(b:tag_name))
      let replaceVal = ''
    endif
    let tagmatch = ''
  endif

  if s:IsEmptyTag(b:tag_name)
    let s:replaceVal = replaceVal
    unlet s:CHANGED_VAL
    call inputsave()
    let output = s:RunCommand(commandToRun, replaceVal)
    call inputrestore()
    return output
  endif

  let tagmatch = s:LiteralPattern(snip_start_tag.tagmatch.snip_end_tag)
  call cursor(tagstart[0], tagstart[1] - strlen(snip_start_tag) + 1)
  let tagsubstitution = escape(s:RunCommand(commandToRun, replaceVal), '\&~')

  let lines = tagstart[0] == endPos[0]
        \ ? split(substitute(getline(tagstart[0]), 
        \   tagmatch, tagsubstitution, ''), "\\n\\|\<CR>", 1)
        \ : split(substitute(join(getline(tagstart[0], endPos[0]), "\n"), 
        \   tagmatch, tagsubstitution, ''), "\\n\\|\<CR>", 1)

  for i in range(endPos[0] - tagstart[0])
    normal! gJ
  endfor
  if len(lines) > 0
    call setline('.', remove(lines, 0))
    call append('.', lines)
  endif
  call cursor(tagstart[0], tagstart[1])
  " We use replaceVal instead of tagsubsitution as otherwise the command
  " result will be passed to subsequent tags
  let s:replaceVal = replaceVal
  call s:MakeChanges()
  unlet s:CHANGED_VAL
endfunction
" }}}
" {{{ MakeChanges() - Search the document making all the changes required
"   Change all the tags with the same name and no commands defined
function! s:MakeChanges()
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()

  if !exists('b:tag_name') || b:tag_name == '' | return | endif

  let tagmatch = s:LiteralPattern(snip_start_tag.b:tag_name.snip_end_tag)

  if match(b:tag_name, '^{.\{-}}$') == -1
    let ind = 0
    while search(tagmatch, 'w', s:GetSnipScope()[1]) > 0
      try
        let commandResult = s:RunCommand(b:command_dict[b:tag_name][0], s:replaceVal)
      catch
        " E175: Could not find this key in the dict
        let commandResult = s:replaceVal
      endtry
      let lines = split(substitute(getline('.'), tagmatch, 
            \ escape(commandResult, '\&~'), ''), "\<CR>\\|\n")
      if len(lines) > 1
        call setline('.', lines[0])
        call append('.', lines[1:])
        let end = line('.') + len(lines) - 1
        if end > s:GetSnipScope()[1]
          call s:SetSnipScope(0, end)
        endif
      else
        call setline('.', lines)
      endif
      try
        unlet b:command_dict[b:tag_name][0]
      catch /E\%(175\|121\)/
        " Could not find this key in the dict
      endtry
    endwhile
  endif
endfunction
" }}}
" {{{ CheckForInTag() - Check whether we're in a tag
function! s:CheckForInTag()
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()
  if s:GetSnipScope() == [0, 0]
    return 0
  endif
  if snip_start_tag != snip_end_tag
    " The tags are different so we can check to see whether the
    " end tag comes before a start tag
    let s:startMatch = match(s:line, s:LiteralPattern(snip_start_tag), s:curCurs)
    let s:endMatch = match(s:line, s:LiteralPattern(snip_end_tag), s:curCurs)

    if s:endMatch != -1 && ((s:endMatch < s:startMatch) || s:startMatch == -1)
      " End has come before start so we're in a tag.
      return 1
    else
      return 0
    endif
  else
    " Start and end tags are the same so we need do tag counting to see
    " whether we're in a tag.
    let s:count = 0
    let s:curSkip = s:curCurs
    while match(strpart(s:line,s:curSkip),snip_start_tag) != -1 
      if match(strpart(s:line,s:curSkip),snip_start_tag) == 0
        let s:curSkip = s:curSkip + 1
      else
        let s:curSkip = s:curSkip + 1 + match(strpart(s:line,s:curSkip),snip_start_tag)
      endif
      let s:count = s:count + 1
    endwhile
    if (s:count % 2) == 1
      " Odd number of tags implies we're inside a tag.
      return 1
    else
      " We're not inside a tag.
      return 0
    endif
  endif
endfunction
" }}}
" {{{ SubSpecialVars(text)
function! s:SubSpecialVars(text)
  let text = a:text

  if exists('b:snippetsEmu_special_vars') && type(b:snippetsEmu_special_vars) == 4
    let snippetsEmu_special_vars = b:snippetsEmu_special_vars
  elseif exists('g:snippetsEmu_special_vars') && type(g:snippetsEmu_special_vars) == 4
    let snippetsEmu_special_vars = g:snippetsEmu_special_vars
  else
    let snippetsEmu_special_vars = {
      \ '\<SNIP_FILE_NAME\>': "expand('%')", 
      \ '\<SNIP_ISO_DATE\>' : "strftime('%Y-%m-%d')" }
  endif

  for [var, value] in items(snippetsEmu_special_vars)
    let text = substitute(text, var, escape(eval(value), '\&~'), 'g')
  endfor

  return text
endfunction
" }}}
" {{{ SubCommandOutput(text)
function! s:SubCommandOutput(text)
  let search = '``\_.\{-}``'
  let text = a:text
  while match(text, search) != -1
    let command_match = matchstr(text, search)
    let command = command_match[2:-3]
    try 
      " Anonymous function
      if command =~ '^{\_.\+}$'
        let command = substitute(substitute(command[1:-2], "\<CR>", "\n", 'g'), '\n\s*\\', '', 'g')
        exec "func! s:SnipAnonymousFunc()\n".command."\nendfunc"
        let output = s:SnipAnonymousFunc()
      else
        " Call the command
        exec 'let output = '. command
      endif
    catch
      call s:ShowMesg('Command: '.command
            \ .': '.substitute(v:throwpoint, '^\%(.\{-}\.\.\)*', '', '')
            \ .': '.v:exception)
      let output = ''
    endtry
    let output = escape(s:TextProc(output), '\&~')
    let text = substitute(text, s:LiteralPattern(command_match), output, '')
  endwhile
  let text = substitute(text, '\\`\\`\(.\{-}\)\\`\\`','``\1``','g')
  return text
endfunction
" }}}
" {{{ RemoveAndStoreCommands(text)
function! s:RemoveAndStoreCommands(text)
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()

  let text = a:text
  if !exists('b:command_dict')
    let b:command_dict = {}
  endif

  let tmp_command_dict = {}
  try
    let ind = match(text, b:search_str)
  catch /E55: Unmatched \\)/
    call confirm("SnippetsEmu has caught an error while performing a search. This is most likely caused by setting the start and end tags to special characters. Try setting the 'fileencoding' of the file in which you defined them to 'utf-8'.\n\nThe plugin will be disabled for the remainder of this Vim session.")
    let s:Disable = 1
    return ''
  endtry
  while ind > -1
    let tag = matchstr(text, b:search_str, ind)
    let commandToRun = matchstr(tag, snip_elem_delim.'.*'.snip_end_tag)

    if commandToRun != ''
      let tag_name = strpart(tag, strlen(snip_start_tag), match(tag,snip_elem_delim)-strlen(snip_start_tag))
      if tag_name == ''
        let tag_name = s:GetEmptyTag()
        let empty_ind = ind+strlen(snip_start_tag)-1
        let text = text[:empty_ind].tag_name.text[empty_ind+1:]
      endif

      if has_key(tmp_command_dict, tag_name)
        call add(tmp_command_dict[tag_name], commandToRun[strlen(snip_elem_delim):-strlen(snip_end_tag)-1])
      else
        let tmp_command_dict[tag_name] = [commandToRun[strlen(snip_elem_delim):-strlen(snip_end_tag)-1]]
      endif

      let text = substitute(text, s:LiteralPattern(commandToRun),
            \ escape(snip_end_tag, '\&~'), '')
    else
      let tag_name = s:ChopTags(tag)
      if tag_name != ''
        if has_key(tmp_command_dict, tag_name)
          call add(tmp_command_dict[tag_name], '')
        else
          let tmp_command_dict[tag_name] = ['']
        endif
      endif
    endif
    let ind = match(text, b:search_str, ind+strlen(snip_end_tag))
  endwhile

  for key in keys(tmp_command_dict)
    if has_key(b:command_dict, key)
      for item in reverse(tmp_command_dict[key])
        call insert(b:command_dict[key], item)
      endfor
    else
      let b:command_dict[key] = tmp_command_dict[key]
    endif
  endfor
  return text
endfunction
" }}}
" {{{ FindSnippet(word)
function! s:FindSnippet(word)
  let word = a:word
  if a:word == ''
        \ || (!exists('b:snippetsEmu_triggers') 
        \     && !exists('g:snippetsEmu_triggers'))
    return [a:word, '']
  endif

  for scope in ['b:', 'g:']
    try
      let snippet = eval(scope.'snippetsEmu_triggers').Get(a:word)
      if !empty(snippet)
        return [a:word, snippet[0]]
      endif
    catch
    endtry
  endfor

  " Check using keyword boundary
  let word = matchstr(a:word, '\k\+$')
  if word != ''
    for scope in ['b:', 'g:']
      try
        let snippet = eval(scope.'snippetsEmu_triggers').Get(word)
        if !empty(snippet)
          return [word, snippet[0]]
        endif
      catch
      endtry
    endfor
  endif

  if !empty(g:snippetsEmu_trigger_in_word)
    for scope in ['b:', 'g:']
      try
        let snippetsEmu_triggers = eval(scope.'snippetsEmu_triggers')
        let triggers = snippetsEmu_triggers.Show('', '', 1)
        for [trigger, fileytpe] in triggers
          let index = strridx(a:word, trigger)
          if index != -1 && index + strlen(trigger) == strlen(a:word)
            return [trigger, snippetsEmu_triggers.Get(trigger, fileytpe)]
          endif
        endfor
      catch
      endtry
    endfor
  endif

  return [a:word, '']
endfunction
" }}}
" {{{ Jumper()
" We need to rewrite this function to reflect the new behaviour. Every jump
" will now delete the markers so we need to allow for the following conditions
" 1. Empty tags e.g. "<{}>".  When we land inside then we delete the tags.
"  "<{}>" is now an invalid tag (use "<{}>" instead) so we don't need to check for
"  this
" 2. Tag with variable name.  Save the variable name for the next jump.
" 3. Tag with command. Tags no longer have default values. Everything after the
" centre delimiter until the end tag is assumed to be a command.
" 
" Jumper is performed when we want to perform a jump.  If we've landed in a
" 1. style tag then we'll be in free form text and just want to jump to the
" next tag.  If we're in a 2. or 3. style tag then we need to look for whether
" the value has changed and make all the replacements.   If we're in a 3.
" style tag then we need to replace all the occurrences with their command
" modified values.
" 
function! s:ResetPrevInfo() 
  let [s:prevLine, s:prevCurs] = [0, 0]
  let s:prevOrigword = ''
endfunction

au BufEnter * call s:ResetPrevInfo()

let [s:curLine, s:curCurs] = [0, 0]

function! <SID>Jumper(...) " ... = (a:1, a:2) = (noExpandTag?, snippet, join_undo)
  redraw
  if pumvisible() && exists('b:tag_name') && s:IsEmptyTag(b:tag_name)
    let b:tag_name = ''
    return ''
  endif

  if s:Disable == 1 || pumvisible()
    return SnippetReturnKey(1)
  endif

  if exists('g:snippetsEmu_JumperCallback')
    try
      let ret = call(g:snippetsEmu_JumperCallback, [])
      if type(ret) == type([]) && len(ret) > 1 && !empty(ret[0])
        if ret[0] == -1
          return SnippetReturnKey(1)
        else
          return ret[1]
        endif
      endif
    catch
      call s:ShowMesg('Exception from' . v:throwpoint . "\n" . v:exception)
    endtry
  endif

  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()

  " Set up some mapping in case we got called before Supertab
  if s:supInstalled == 1
    call s:SnipMapKeys()
  endif

  if !exists('b:search_str')
    if exists('g:search_str')
      let b:search_str = g:search_str
    else
      return SnippetReturnKey(1)
    endif
  endif
   
  let [s:prevLine, s:prevCurs] = [s:curLine, s:curCurs]
  let [s:curLine, s:curCurs] = [line('.'), col('.') - 1]
  let s:line = getline('.')
  let s:replaceVal = ''

  let rhs = ''
   
  if a:0 > 1 && a:2 == 1 && exists('s:snip_save')
    " We already have a snippet stored in @z. Just use it.
    let [rhs, @z] = [@z, s:snip_save]
    let origword = ''
  else
    " First we'll check that the user hasn't just typed a snippet to expand
    let origword = matchstr(strpart(getline('.'), 0, s:curCurs), '\S\{-}$')

    let isExpandTag = -1
    if exists('g:snippetsEmu_ExpandTagCallback')
      let isExpandTag = call(g:snippetsEmu_ExpandTagCallback, [s:curCurs+1])
    endif

    if isExpandTag == -1
      let isInTag = s:CheckForInTag()
      let isNonWhiteChar = match(getline('.')[s:curCurs], '\S') != -1
      let inSpecialPos = isInTag || isNonWhiteChar

      " let isSpecilChar = match(getline('.')[s:curCurs], '^$\|\|\s\|[\]\^\-\\{}<>()$]') == -1
      " let inSpecialPos = isInTag || isSpecilChar

      let isExpandTag = (a:0 == 0 || a:1 != 1)

      if inSpecialPos && !g:snippetsEmu_exp_in_tag
        let isExpandTag = !isExpandTag
      endif
    endif

    if isExpandTag
      let [origword, rhs] = s:FindSnippet(origword)
    endif
  endif

  if s:prevLine == s:curLine && s:prevCurs == s:curCurs && s:prevOrigword == origword
    let rhs = ''
  endif

  let s:prevOrigword = origword

  if rhs != ''
    " Save the value of hlsearch
    if &hls
      setlocal nohlsearch
      let b:hl_on = 1
    else
      let b:hl_on = 0
    endif
    " Save the last search value
    let b:search_sav = @/

    if !exists('b:snippetsEmu_mark_scope')
      let b:snippetsEmu_mark_scope = 0
      delmarks se
    endif

    " If this is a mapping, then erase the previous part of the map
    " by returning a number of backspaces.
    let bkspc = substitute(origword, '.', "\<BS>", 'g')
    let delEndTag = ''
    if s:CheckForInTag()  " We're doing a nested tag
      if b:tag_name != ''
        try
          unlet b:command_dict[b:tag_name][0]
        catch /E175/
          " Could not find this key in the dict 
        endtry
      endif
      let bkspc = bkspc.substitute(snip_start_tag, '.', "\<BS>", "g")
      let delEndTag = substitute(snip_end_tag, '.', "\<Del>", "g")
    endif
    
    " We've found a mapping so we'll substitute special variables
    let rhs = s:SubSpecialVars(rhs)
    let rhs = s:SubCommandOutput(rhs) " ``command``
    " Now we'll chop out the commands from tags
    let rhs = s:RemoveAndStoreCommands(rhs)
    if s:Disable == 1
      return SnippetReturnKey(1)
    endif

    let rhs = s:Indent(rhs)

    " Set scope of the snippet
    let [start, end] = [line('.'), line('.')+1]
    if b:snippetsEmu_mark_scope == 0
      let b:snippetsEmu_mark_scope = 1
      let b:snippetsEmu_scope_isset = 1
      call s:SetSnipScope(start, end)
    else
      let [old_start, old_end] = s:GetSnipScope()
      if start < old_start || start >= old_end
        let b:snippetsEmu_scope_isset = 1
        call s:SetSnipScope(start, end)
      endif
    endif

    " Save the value of 'backspace'
    let bs_save = &backspace
    set backspace=indent,eol,start
    redraw
    set paste
    if a:0 > 2 && a:3 != 0
      let bus = ''
    else
      let bus = g:snippetsEmu_break_undo_sequences ? "\<C-G>u" : ''
    endif
    return bus.bkspc.delEndTag.rhs
          \ ."\<Esc>:set nopaste backspace=".bs_save
          \ ."\<CR>a\<C-R>=<SNR>".s:SID()."_NextHop()\<CR>"
  else
    " No definition so let's check to see whether we're in a tag
    if s:CheckForInTag() " No mapping and we're in a tag
      " We're in a tag so we need to do processing
      if strpart(s:line, s:curCurs - strlen(snip_start_tag), strlen(snip_start_tag)) == snip_start_tag
        call s:ChangeVals(0) " Value not changed
      else
        call s:ChangeVals(1) " Value changed
      endif
      return "\<C-R>=<SNR>".s:SID()."_NextHop()\<CR>"
    else
      " We're not in a tag so we'll see whether there are more tags
      let [start, end] = s:GetSnipScope()
      let findTag = 0

      " Only search the tag pattern in the scope.
      if start != 0 && start <= line('.') && line('.') <= end
        let pos = getpos('.')
        call cursor(start, 1)
        let findTag = search(b:search_str, 'n', end) != 0
        call setpos('.', pos)
      endif

      if findTag
        " More tags so let's perform nexthop
        let s:replaceVal = ''
        return "\<C-R>=<SNR>".s:SID()."_NextHop()\<CR>"
      else
        " No more tags so let's return a Tab after restoring hlsearch and @/
        call s:RestoreSearch()
        call s:ResetEmptyTag()
        let b:snippetsEmu_mark_scope = 0
        if exists('b:command_dict')
          unlet b:command_dict
        endif
        if exists('b:tag_name') && s:IsEmptyTag(b:tag_name)
          let b:tag_name = ''
          return ''
        endif
        return SnippetReturnKey(1)
      endif
    endif
  endif
endfunction
" }}}
" {{{2 Functions: SnipScope-related
" {{{ SetSnipScope(start, end)
function! s:SetSnipScope(start, end)
  let start = a:start
  let end = a:end < start ? start : a:end
  if start > 0
    call setpos("'s", [0, start, 1, 0])
  endif
  if end > 0
    call setpos("'e", [0, end, 1, 0])
  endif
endfunction
" }}}
" {{{ GetSnipScope()
function! s:GetSnipScope()
  return [getpos("'s")[1], getpos("'e")[1]]
endfunction
" }}}
" }}}2
" {{{2 Functions: EmptyTag-related
" {{{ GetEmptyTag()
fun! s:GetEmptyTag()
  if !exists('s:empty_tag_num')
    let s:empty_tag_num = 0
  endif
  let tag = '['.s:empty_tag_num.']'
  let s:empty_tag_num = s:empty_tag_num + 1
  return tag
endfun
" }}}
" {{{ IsEmptyTag()
function! s:IsEmptyTag(tag)
  return match(a:tag, '^\[\d\+\]$') != -1
endfunction
" }}}
" ResetEmptyTag() {{{
function! s:ResetEmptyTag()
  let s:empty_tag_num = 0
endfunction
" }}}
" }}}2
" }}}1
" {{{1 Functions: Snippet management
" {{{2 SetCom() - Set command function
"   filetype = ' ', which means the triggers will already be searched first.
"
function! <SID>SetCom(text, scope, ...) " ...=in_filetype
  if s:supInstalled == 1 | call s:SnipMapKeys() | endif

  if !exists(a:scope.'snippetsEmu_triggers')
    exec 'let '.a:scope.'snippetsEmu_triggers = s:NewSnippet()'
  endif

  let snippetsEmu_triggers = eval(a:scope.'snippetsEmu_triggers')

  " tokens = [ \0, \1, \2 ]
  let tokens = matchlist(a:text, '^\s*\(\S\+\)\s\?\(.*\)$')
  if empty(tokens)
    let output = join(s:ListSnippets(a:scope) , "\n")
    if output == ''
      echohl Title | echo 'No snippets defined' | echohl None
    else
      echohl Title | echo 'Defined snippets:' | echohl None
      echo output
    endif
  " NOTE - cases such as ":Snippet if  " will intentionally(?) be parsed as a
  " snippet named "if" with contents of " "
  elseif tokens[2] == ''
    let snippet = snippetsEmu_triggers.Show(tokens[1], '')
    if !empty(snippet)
      " FIXME - is there a better approach?
      " echo doesn't handle ^M correctly
      let pretty = substitute(snippet[0][0], '\r', '\n', 'g')
      echo pretty
    else
      call s:ShowMesg('Undefined snippet: '.snip)
    endif
  else
    call s:SetSearchStrings()
    if a:scope == 'b:' && (a:0 == 0 || a:1 != '!')
      call snippetsEmu_triggers.Add(tokens[1], tokens[2], &ft == '' ? ' ' : &ft)
    else
      call snippetsEmu_triggers.Add(tokens[1], tokens[2], ' ')
    endif
  endif
endfunction
" }}}2
" {{{2 SetSnippet()
function! s:SetSnippet(trigger, snippet, scope, ...) " ...=[filetype[, bufnr]]
  if s:supInstalled == 1 | call s:SnipMapKeys() | endif
  let bufnr = a:0 > 1 ? a:2 : bufnr('%')
  let curbufnr = bufnr('%')
  if curbufnr != bufnr
    let bh = &bh | setlocal bh=hide | exec bufnr.'b'
  endif

  if !exists(a:scope.'snippetsEmu_triggers')
    exec 'let '.a:scope.'snippetsEmu_triggers = s:NewSnippet()'
  endif

  let snippetsEmu_triggers = eval(a:scope.'snippetsEmu_triggers')
  call s:SetSearchStrings()
  call snippetsEmu_triggers.Add(a:trigger, a:snippet, 
        \ a:scope == 'g:' ? 'global' : (a:0 > 0 ? a:1 : &ft))

  if curbufnr != bufnr
    exec curbufnr.'b' | exec 'setlocal bh='.bh
  endif
endfunction
" }}}2
" {{{2 DelSnippet() - Delete a snippet.
function! s:DelSnippet(delete_file, scope, trigger, ...) " ...=filetype
  if a:trigger == ''
    return 
  endif
  let filetype = a:0 == 0 ? '' : a:1
  if exists(a:scope.'snippetsEmu_triggers')
        \ && !eval(a:scope.'snippetsEmu_triggers').Delete(a:delete_file, a:trigger, filetype, 1)
    return
  endif

  call s:ShowMesg('The '.(a:scope == 'b:' ? 'Snippet' : 'Iabbr')." for '".a:trigger."'"
        \ .(filetype != '' ? ' ('.filetype.')' : '')
        \. " doesn't exist.")
endfunction
" }}}2
" {{{2 UnloadSnippets() - Unload snippets with the same filetype.
function! s:UnloadSnippets(scope, filetype)
  if !exists(a:scope.'snippetsEmu_triggers')
    return
  endif
  let filetype = a:scope == 'b:'
        \          ? (a:filetype == ''  ? ' ' : a:filetype)
        \          : (a:filetype == '!' ? ' ' : 'global'  )
  if exists('b:load_' . filetype . '_snippets')
    exec 'unlet! ' . 'b:load_' . filetype . '_snippets'
  endif
  call eval(a:scope.'snippetsEmu_triggers').Delete(0, '', filetype)
endfunction
" }}}2
" {{{2 LoadSnippet() - Load specific snippet file.
"
"   Since some snippets are pretty complicated and are not readable when
"   directly applying 'Snippet' to those snippets (We need to deal with
"   many <CR>s and <Tab>s), we can put them in separated files.
"
function! s:LoadSnippet(snip_file, ...) " ... = is_global (0|1)
  if !filereadable(a:snip_file)
    call s:ShowMesg("The file '".a:snip_file."' doesn't exist.")
    return
  endif

  let trigger = fnamemodify(a:snip_file, ':p:t')
  if trigger ==? '__init__.vim'
    exec 'so ' . a:snip_file
    return
  endif

  let pat = '\.snip\%(\.[^.]\+\)\?$'
  if match(trigger, pat) == -1
    " call s:ShowMesg("The trigger '".trigger."' doesn't exist.")
    return
  endif

  let trigger = s:UnHash(trigger[:strridx(trigger, '.snip')-1])
  call s:SetSnippet(trigger, '',
        \ ((a:0 > 0 && a:1 == 1) ? 'g:' : 'b:'), 
        \ tolower(fnamemodify(a:snip_file, ':p:h:t')))
endfunction
" }}}2
" {{{2 LoadSnippets() - Load all snippet files with the same filetype.
"
"   Each type of the file corresponds to one directory named by the file type
"   (e.g. c). Each file in this directory contains the snippet and the filename 
"   is the trigger word of this specific snippet.
"   
"   All directories mentioned above are put in the root directory called
"   'snippets' (can be specified by g:snippetsEmu_load_dir).
"
"   Example:                (filetype)  (trigger word) (snippet)
"     snippets --+ c --------+ main --------> +-------------+
"                |             for            | int         |
"                |             ...            | main()      |
"                + html -----+ table          | {           |
"                |             ul             |   <{}>      |
"                |             ...            |   return 0; |
"                |                            | }           |
"                |                            +-------------+
"                + python ---+ __init__.vim   (init script)
"
"   The special file '__init__.vim' contains all predefined variables and
"   functions.
"
"   The idea comes from 'msf-abbrev.el'.
"     <http://www.bloomington.in.us/~brutt/msf-abbrev.html>
"
function! s:LoadSnippets(scope, filetype)
  if a:filetype =~ '^\s*$'
    call s:ShowMesg('Please specify the filetype.')
    return
  endif

  let files = globpath(&rtp, s:GetSnipLoadDir().'/'.a:filetype.'/*')
  if files == ''
    return
  endif

  call s:ResetPrevInfo()

  let snip_files = split(files, "\n")
  let init_idx = match(snip_files, '\c\<__init__\.vim$')
  if init_idx != -1
    call s:LoadSnippet(remove(snip_files, init_idx))
  endif

  let isglobal = a:scope ==? 'g:' ? 1 : 0
  for snip_file in snip_files
    call s:LoadSnippet(snip_file, isglobal)
  endfor
endfunction
" }}}2
" {{{2 UpdateSnippet() - Update specific snippet.
function! s:UpdateSnippet(snip_file, ...) " ...=isglobal[, bufnr]
  if !filereadable(a:snip_file)
    return
  endif

  call s:ResetPrevInfo()

  let isglobal = (a:0 > 0 && a:1 == 1) ? 1 : 0
  let bufnr = a:0 > 1 ? a:2 : bufnr('%')
  let curbufnr = bufnr('%')
  if curbufnr != bufnr
    let bh = &bh | setlocal bh=hide | exec bufnr.'b'
  endif

  let snip_dir = fnamemodify(a:snip_file, ':p:h')
  let filetype = tolower(fnamemodify(a:snip_file, ':p:h:t'))
  if snip_dir.'/__init__.vim' ==? a:snip_file
    try
      exec 'unlet b:load_'.filetype.'_snippets'
		catch /^Vim\%((\a\+)\)\=:E108/
    endtry
    call s:LoadSnippet(a:snip_file)
  else
    call s:LoadSnippet(a:snip_file, isglobal)
  endif

  if curbufnr != bufnr
    exec curbufnr.'b' | exec 'setlocal bh='.bh
  endif
endfunction
" }}}2
" {{{2 CreateSnippetInit() - Create '__init__.vim' in specific directory.
function! s:CreateSnippetInit(dir)
  if !isdirectory(a:dir)
    return
  endif
  let init_file = simplify(a:dir . '/__init__.vim')
  if glob(init_file) != ''
    return 0
  endif
  let filetype = tolower(fnamemodify(a:dir, ':p:h:t'))
  if filetype =~ '^\s*$'
    call s:ShowMesg('The filetype for snippet must be given.')
    return 1
  endif
  let init_vim = [
        \ 'if exists(''b:load_'.filetype.'_snippets'') | finish | endif',
        \ 'let b:load_'.filetype.'_snippets = 1',
        \ 'ru syntax/snippet.vim']
  if writefile(init_vim, init_file) == -1
    call s:ShowMesg("The initial file in '".a:dir."' can't be created.")
    return 1
  endif
  return 0
endfunction
" }}}2
" {{{2 CreateSnippetDir() - Create directory for specific filetype.
function! s:CreateSnippetDir(dir, force)
  if isdirectory(a:dir)
    return s:CreateSnippetInit(a:dir)
  elseif glob(a:dir) != ''
    call s:ShowMesg("The file '".a:dir."' has already existed.")
    return 1
  endif

  if a:force == 0
    call s:ShowMesg("The directory '".a:dir."' doesn't exist (add ! to create).")
    return 1
  endif

  try
    call mkdir(a:dir)
  catch /^Vim\%((\a\+)\)\=:E739/
    call s:ShowMesg("The directory '".a:dir."' can't be created.")
    return 1
  endtry

  return s:CreateSnippetInit(a:dir)
endfunction
" }}}2
" {{{2 CreateTempSnippet() - Create temporary snippet buffer.
function! s:CreateTempSnippet(trigger, snippet, scope, filetype)
  if a:trigger == ''
    return
  endif
  " let tmpfile = tempname()
  " call writefile(split(a:snippet, '\n'), tmpfile)

  let curbufnr = bufnr('%')
  " exec 'bo new '.tmpfile
  bo new
  call setline(1, split(a:snippet, '\n'))
  " exec printf('au snippetsEmuEdit BufWritePost <buffer> call s:SetSnippet('
  exec printf('au snippetsEmuEdit BufWriteCmd <buffer> call s:SetSnippet('
        \ ."'%s', "
        \ .'join(getline(1, "$"), "\n"), '
        \ ."'%s', "
        \ ."' ', "
        \ ."%d)|set nomod", a:trigger, a:scope, curbufnr)
        " \ ."%d)", a:trigger, a:scope, curbufnr)
  " au snippetsEmuEdit BufWipeout <buffer> call delete(expand('<afile>'))

  if a:filetype !~ '^\s*$'
    exec 'setf '.a:filetype
  endif
  silent! setlocal bt=acwrite bh=wipe nobl noswf noet
  " silent! setlocal bh=wipe nobl noet
  file __temp__
  ru syntax/snippet-edit.vim
  exec 'inoremap <silent> <buffer> <Leader>, '
        \ .g:snippetsEmu_start_tag.g:snippetsEmu_end_tag
        \ .repeat('<Left>', s:StrLen(g:snippetsEmu_end_tag))
  let b:bufname = a:trigger . ' ['.(a:scope == 'b:' ? 'Snippet' : 'Iabbr').']'
	setlocal statusline=%<%{b:bufname}\ %h%m%r%=%-14.(%l,%c%V%)\ %P
  " setlocal nobk
endfunction
" }}}2
" {{{2 ShowSnippet() - Show or create specific snippet.
function! s:ShowSnippet(init, force, scope, trigger, ...) " ...=filetype
  let filetype = a:0 == 0 ? &ft : (a:1 == '' ? &ft : a:1)
  let force = a:force == '!'

  " In Windows you cannot rename a file to "PRN", because it points to the
  " DOS/Windows default printer.'
  if has('win16') || has('win32') || has('win64') || has('win32un')
    if a:trigger =~? '^prn\%(\..*\)*$'
      let filetype = ''
    endif
  endif

  if a:init == 0 && exists(a:scope.'snippetsEmu_triggers') && a:0 == 0
    let snippets = eval(a:scope.'snippetsEmu_triggers').Show(a:trigger, '')
    if !empty(snippets)
      let filetype = snippets[0][1]
    endif
  endif

  if filetype =~ '^\s*$'
    if a:init == 0
      if exists(a:scope.'snippetsEmu_triggers')
            \ && eval(a:scope.'snippetsEmu_triggers').exists(a:trigger, ' ')
        call s:CreateTempSnippet(a:trigger, 
              \ b:snippetsEmu_triggers.Get(a:trigger, ' '), a:scope, filetype)
      elseif force " Temparory snippet for current buffer.
        call s:SetSnippet(a:trigger, '', a:scope, ' ')
        call s:CreateTempSnippet(a:trigger, '', a:scope, filetype)
      else
        call s:ShowMesg("The trigger '".a:trigger."' doesn't exist (add ! to create).")
      endif
    else
      call s:ShowMesg('Please specify the filetype for initial file.')
    endif
    return
  endif

  let filetype = tolower(filetype)
  let snip_load_dir = globpath(&rtp, s:GetSnipLoadDir())
  if snip_load_dir == ''
    return
  endif

  let snip_load_dir = split(snip_load_dir, "\n")[0] . '/' . filetype
  if s:CreateSnippetDir(snip_load_dir, force)
    return
  endif

  let curbufnr = bufnr('%')
  if a:init == 1
    let snippet = snip_load_dir . '/__init__.vim' 
    let old_snippet = glob(snippet)
  else
    let snippet = snip_load_dir . '/' . s:Hash(a:trigger) . '.snip'
    let old_snippet = glob(snippet)
    if old_snippet == '' 
      let old_snippet = glob(snippet . '.*')
    endif
  endif

  if old_snippet != '' 
    exec 'bo new '.old_snippet
  else
    if a:init == 0
      if exists(a:scope.'snippetsEmu_triggers')
        let snippetsEmu_triggers = eval(a:scope.'snippetsEmu_triggers')
        if snippetsEmu_triggers.Exists(a:trigger, filetype)
          call writefile(split(snippetsEmu_triggers.Get(a:trigger, filetype), '\n'),
                \ snippet)
          let force = 1
        endif
      endif
    endif

    if force
      exec 'bo new '.snippet
    else
      if a:init == 0
        call s:ShowMesg("The trigger '".a:trigger."' doesn't exist (add ! to create).")
      else
        call s:ShowMesg("The initial file doesn't exist (add ! to create).")
      endif
      return 1
    endif
  endif

  exec 'au snippetsEmuEdit BufWritePost <buffer> call s:UpdateSnippet(expand("<afile>:p"), '
        \ .(a:scope == 'b:' ? 0 : 1). ', '.curbufnr.')'
  exec 'lcd '.snip_load_dir
  silent! setlocal bh=wipe nobl
  let b:bufname = filetype.'/'.a:trigger.' ['.(a:scope == 'b:' ? 'Snippet' : 'Iabbr').']'
	setlocal statusline=%<%{b:bufname}\ %h%m%r%=%-14.(%l,%c%V%)\ %P
endfunction
" }}}2
" {{{2 ListSnippets() - Return a list of snippets - Used for command completion.
function! s:ListSnippets(scope, ...) " ...=mode {{{
  try
    let snippetsEmu_triggers = eval(a:scope.'snippetsEmu_triggers')
  catch
    return []
  endtry
  let compl = []
  if a:scope == 'b:' && a:0 > 0 && a:1 == 1
    for [trigger, fileytpe] in snippetsEmu_triggers.Show('', '', 1)
      call add(compl, printf('[%6s] %s', fileytpe, trigger))
    endfor
  elseif a:0 > 0 && a:1 == 2
    for [trigger, fileytpe] in snippetsEmu_triggers.Show('', '', 1)
      call add(compl, printf('%s %s', trigger, fileytpe))
    endfor
  else
    for [trigger, fileytpe] in snippetsEmu_triggers.Show('', '', 1)
      if index(compl, trigger) == -1
        call add(compl, trigger)
      endif
    endfor
  endif
  return compl
endfunction
" }}}
function! s:ListBufferSnippets(ArgLead, CmdLine, CursorPos) " {{{
  return join(s:ListSnippets('b:'), "\n")
endfunction
" }}}
function! s:ListBufferSnippets2(ArgLead, CmdLine, CursorPos) " {{{
  return join(s:ListSnippets('b:', 2), "\n")
endfunction
" }}}
function! s:ListGlobalSnippets(ArgLead, CmdLine, CursorPos) " {{{
  return join(s:ListSnippets('g:'), "\n")
endfunction
" }}}
function! s:ListAvailableFileType(ArgLead, CmdLine, CursorPos) " {{{
  let filetypes = split(globpath(&rtp, s:GetSnipLoadDir().'/*'), '\n')
  " return join(filter(map(filetypes, 'fnamemodify(v:val, ":t")'), 'v:val !=? "global"'), "\n")
  return join(map(filetypes, 'fnamemodify(v:val, ":t")'), "\n")
endfunction
" }}}
function! s:ListLoadedFileType(ArgLead, CmdLine, CursorPos) " {{{
  if !exists('b:snippetsEmu_triggers')
    return ''
  endif
  return join(b:snippetsEmu_triggers.Show('', ''), "\n")
endfunction
" }}}
" }}}2
" {{{2 CreateSnippet() - Convert the selected range into a snippet.
function! s:CreateSnippet() range
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()
  let snip = ""
  if &expandtab
      let tabs = indent(a:firstline)/&shiftwidth
      let tabstr = repeat(' ',&shiftwidth)
  else
      let tabs = indent(a:firstline)/&tabstop
      let tabstr = '\t'
  endif
  let tab_text = repeat(tabstr,tabs)

  for i in range(a:firstline, a:lastline)
    "First chop off the indent
    let text = substitute(getline(i), tab_text, '', '')
    "Now replace 'tabs' with <Tab>s
    let text = substitute(text, tabstr, '<Tab>', 'g')
    "And trim the newlines
    let text = substitute(text, "\r", '', 'g')
    let snip = snip.text.'<CR>'
  endfor
  let tag = snip_start_tag.snip_end_tag
  let split_sav = &swb
  set swb=useopen
  if bufexists('Snippets')
    belowright sb Snippets
  else
    belowright sp Snippets
  endif
  resize 8
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  let @"=tag
  exe 'set swb='.split_sav
  let trig = inputdialog('Please enter the trigger word for your snippet: ', 'My_snippet')
  if trig == ''
    let trig = 'YOUR_SNIPPET_NAME_HERE'
  endif
  call append('$', 'Snippet '.trig.' '.snip)
  if getline(1) == ''
    normal! ggdd
  endif
  normal! G
endfunction
" }}}2
" {{{2 CreateBundleSnippet() - Convert the selected range into a snippet 
"   suitable for including in a bundle.
function! s:CreateBundleSnippet() range
  let [snip_start_tag, snip_elem_delim, snip_end_tag] = SetLocalTagVars()
  let snip = ""
  if &expandtab
      let tabs = indent(a:firstline)/&shiftwidth
      let tabstr = repeat(' ', &shiftwidth)
  else
      let tabs = indent(a:firstline)/&tabstop
      let tabstr = '\t'
  endif
  let tab_text = repeat(tabstr, tabs)

  for i in range(a:firstline, a:lastline)
    let text = substitute(getline(i), tab_text,'','')
    let text = substitute(text, tabstr, '<Tab>','g')
    let text = substitute(text, "\r$", '','g')
    let text = substitute(text, '"', '\\"','g')
    let text = substitute(text, '|', '<Bar>','g')
    let snip = snip.text.'<CR>'
  endfor
  let tag = '".st.et."'
  let split_sav = &swb
  set swb=useopen
  if bufexists("Snippets")
    belowright sb Snippets
  else
    belowright sp Snippets
  endif
  resize 8
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  let @"=tag
  exe 'set swb='.split_sav
  let trig = inputdialog('Please enter the trigger word for your snippet: ', 'My_snippet')
  if trig == ''
    let trig = 'YOUR_SNIPPET_NAME_HERE'
  endif
  call append('$', 'exe "Snippet '.trig.' '.snip.'"')
  if getline(1) == ''
    normal! ggdd
  endif
  normal! G
endfunction
" }}}
" {{{2 BrowseSnippets() - Show given Snippet directory in :Explorer.
function! s:BrowseSnippets(filetype)
  if a:filetype =~ '^\s*$'
    call s:ShowMesg('Please specify the filetype.')
    return
  endif

  let dirs = globpath(&rtp, s:GetSnipLoadDir().'/'.a:filetype)
  if dirs == ''
    return
  endif
  exec 'Hexplore '.split(dirs, '\n')[0]
  exec 'resize '.(&lines/3 < 10 ? 10 : &lines/3)
endfunction
" }}}2
" }}}1
" {{{1 Autocommands for Snippet File
augroup snippetsEmuEdit
  au!
  au BufRead,BufNewFile *.snip          exec 'setf '.expand('<afile>:p:h:t')
  au BufRead,BufNewFile *.snip,*.snip.* ru syntax/snippet.vim
  au BufRead,BufNewFile *.snip,*.snip.* ru syntax/snippet-edit.vim
  au BufRead,BufNewFile *.snip,*.snip.* set noet
  exec 'au BufRead,BufNewFile *.snip,*.snip.* inoremap <silent> <buffer> <Leader>, '
        \ .g:snippetsEmu_start_tag.g:snippetsEmu_end_tag
        \ .repeat('<Left>', s:StrLen(g:snippetsEmu_end_tag))
augroup END
" }}}1
" {{{1 Restore
let &cpo= s:save_cpo
unlet s:save_cpo
" vim: set tw=80 sw=2 ts=2 et fdm=marker :
