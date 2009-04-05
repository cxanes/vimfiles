" Autho: Frank Chang <frank DOT nevermind AT gmail DOT com>
" Version: 0.01
" Description:
"    Modified for FavMenu.vim 
"    <http://www.vim.org/scripts/script.php?script_id=161>.
"
" Installation: Drop it into your plugin directory
"
" {{{1 Load Once
if exists('loaded_Bookmarks_plugin')
  finish
endif
let loaded_Bookmarks_plugin = 1
let s:save_cpo = &cpo
set cpo&vim
" }}}1
" {{{1 Global Variables
if !exists('g:Bookmarks_fname')
  let g:Bookmarks_fname = $HOME. (has('unix') ? '/.vimbookmarks' : '\_vimbookmarks')
endif
" }}}1
" {{{1 Global Utilities
" {{{2 RefreshBookmarks()
function! RefreshBookmarks(...) " ... = reload
  let bookmarks = s:GetBookmarks()
  if a:0 > 0 && !empty(a:1)
    call bookmarks.Reload()
  endif
  call bookmarks.RefreshMenu()
endfunction
" }}}2
" {{{2 Bookmarks_GetPath()
function! Bookmarks_GetPath(id) 
  let bookmarks = s:GetBookmarks()
  let bookmark = bookmarks.Get(bookmarks.GetIndex(a:id, 0, 1))
  if empty(bookmark)
    return ''
  else
    return bookmark.fname
  endif
endfunction
" }}}2
" {{{2 Bookmarks_Bookmark()
function! Bookmarks_Bookmark(force, args)
  return s:Bookmark(a:force, a:args)
endfunction
" }}}2
" }}}1
" {{{1 Utilities
" {{{2 SID()
function! s:SID()
  if !exists('s:SID')
    let s:SID = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
  endif
  return s:SID
endfunction
" }}}2
" {{{2 GetBookmarks()
function! s:GetBookmarks() 
  if !exists('s:Bookmarks')
    if exists('g:Bookmarks_menu') && empty(g:Bookmarks_menu)
      let s:Bookmarks = s:NewBookmarks(g:Bookmarks_fname)
    else
      let s:Bookmarks = s:NewBookmarks(g:Bookmarks_fname, s:NewMenu())
    endif
  endif
  return s:Bookmarks
endfunction
" }}}2
" {{{2 IsValidBookmarks()
function! s:IsValidBookmarks() 
  return s:GetBookmarks().IsValid()
endfunction
" }}}2
" {{{2 SpWhenModified(fname)
function! s:SpWhenModified(fname)
  if isdirectory(a:fname)
    let fname = substitute(a:fname, '\/\+$', '', '')
    exe (&mod ? 'sp' : 'e') fname
    silent! call netrw#LocalBrowseCheck(fname)
  else
    exe (&mod ? 'sp' : 'e') a:fname
  endif
endfunction
" }}}2
" {{{2 SpWhenNamedOrModified(fname)
function! s:SpWhenNamedOrModified(fname)
  exe (!empty(bufname('')) || &mod ? 'sp' : 'e') a:fname
endfunction
" }}}2
" {{{2 OpenFile(fname, new_tab)
function! s:OpenFile(fname, new_tab)
  if empty(a:fname)
    return 1
  endif

  if a:new_tab
    tabnew
  endif

  if exists('g:Bookmarks_open_func') && type(g:Bookmarks_open_func) == type(function('tr'))
    call call(g:Bookmarks_open_func, a:fname)
  elseif exists('g:Bookmarks_open_func') && exists('*' . g:Bookmarks_open_func)
    call call(g:Bookmarks_open_func, a:fname)
  else
    call s:SpWhenModified(a:fname)
  endif
endfunction
" }}}2
" {{{2 OpenBookmark(index)
function! s:OpenBookmark(index, ...) " ... = new_tab
  if type(a:index) == type({})
    let bookmark = a:index
  else
    let bookmark = s:GetBookmarks().Get(a:index)
  endif

  if empty(bookmark)
    return
  endif

  let new_tab = a:0 > 0 && !empty(a:1)
  call s:OpenFile(bookmark.fname, new_tab)

  if !empty(bookmark.cmd)
    exec bookmark.cmd
  endif

  if !empty(bookmark.pos)
    call cursor(bookmark.pos)
  endif
endfunction
" }}}2
" {{{2 TruncPath(path)
function! s:TruncPath(path)
  let p = a:path
  let pathlen = strlen(p)
  if exists('g:Bookmarks_path_length_limit') && pathlen > g:Bookmarks_path_length_limit
    let cut = match(p, '[/\\]', pathlen - g:Bookmarks_path_length_limit)
    if cut > 0 && cut < pathlen
      let p = '\.\.\.' . strpart(p, cut)
    endif
  endif
  retu p
endfunction
" }}}2
" {{{2 Strip(str)
function! s:Strip(str) 
  return substitute(a:str, '^\s\+\|\s\+$', '', 'g')
endfunction
" }}}2
" {{{2 ShowMesg(group, format, ...)
function! s:ShowMesg(group, format, ...) 
  let mesg = call('printf', [('%s' . a:format), ''] + a:000)
  exec 'echohl' a:group
  echom 'Bookmarks: ' . mesg
  echohl None
endfunction
" }}}2
" {{{2 RefreshAll()
function! s:RefreshAll()
  if !has('clientserver')
    return
  endif

  for server in split(serverlist(), '\n')
    if v:servername != server
      silent! call remote_expr(server, 'RefreshBookmarks(1)')
    endif
  endfor
endfunction
" }}}2
" {{{2 ParseCmdArgs()
function! s:ParseCmdArgs(line)
  let qstr_pat  = '\%(''\%(\%(''''\)\+\|[^'']\+\)*''\)'
  let qqstr_pat = '\%("\%(\%(\\.\)\+\|[^"\\]\+\)*"\)'
  let cstr_pat  = '\%(\%(\%(\\[\\ \t]\)\+\|[^\\ \t]\+\)\+\)'
  let str_pat = printf('^\%%(%s\|%s\|%s\)', qstr_pat, qqstr_pat, cstr_pat)
  let line = substitute(a:line,  '^\s\+\|\s\+$', '', 'g')
  let args = []
  while !empty(line)
    let idx = matchend(line, str_pat)
    if idx == -1
      break
    endif
    let arg = line[ : (idx-1)]
    if stridx('''"', arg[0]) != -1
      let arg = eval(arg)
    else
      let arg = substitute(arg, '\\\([\\ \t]\)', '\1', 'g')
    endif
    call add(args, arg)
    let line = substitute(line[idx : ], '^\s\+', '', '')
  endwhile
  return args
endfunction
" }}}2
" {{{2 KeywordList()
function! s:KeywordList(A, L, P)
  return join(s:GetBookmarks().GetKeywords(), "\n")
endfunction
" }}}2
" {{{2 IsValidKeyword()
function! s:IsValidKeyword(keyword, ...) " ... = show_mesg
  let show_mesg = a:0 > 0 && !empty(a:1)
  if type(a:keyword) == type('') && (empty(a:keyword) || a:keyword =~ '^\h\w*$')
    return 1
  else
    if show_mesg
      call s:ShowMesg('ErrorMsg', '%s: Invalid keyword', a:keyword)
    endif
    return 0
  endif
endfunction
" }}}2
" }}}1
" {{{1 Class: Menu
" Public  Method: Ctor {{{2
function! s:NewMenu() 
  let self = {
        \ 'Class': 'Menu',
        \ 'Add'  : function('s:Menu_Add'),
        \ 'Clear': function('s:Menu_Clear')
        \ }
  call self.Clear()
  return self
endfunction
" }}}2
" Public  Method: Add {{{2
function! s:Menu_Add(index, fname, cmd) 
  if a:index == 0
    silent! aun Book&marks.&Remove.Dummy
  endif

  " path => dir/base
  let path = fnamemodify(a:fname,':p')
  let dir  = s:TruncPath(escape(fnamemodify(path,':p:h'), '\. #%'))
  let base = escape(fnamemodify(path,':p:t'),'\. #%')

  let item = printf('[&%d]\ \ %s<Tab>%s', a:index, (empty(base) ? '<DIR>' : base), dir)
  exe printf('amenu <silent>      Book&marks.%s         :call <SID>OpenBookmark(%d)<CR>',   item, a:index)
  exe printf('amenu <silent> 65.2 Book&marks.&Remove.%s :call <SID>RemoveBookmark(%d)<CR>', item, a:index)
endfunction
" }}}2
" Public  Method: Clear {{{2
function! s:Menu_Clear() 
  silent! aun Book&marks
  amenu <silent> 65.1 Book&marks.&Add\ current\ file :call <SID>Bookmark(1, '')<CR>
  amenu <silent> 65.2 Book&marks.&Remove.Dummy       <Nop>
  amenu <silent> 65.3 Book&marks.&Edit\ bookmarks    :call <SID>BookmarkEdit(0)<CR>
  amenu <silent> 65.4 Book&marks.Re&fresh            :call RefreshBookmarks()<CR>
  amenu <silent> 65.5 Book&marks.-sep-               <Nul>
endfunction
" }}}2
" }}}1
" {{{1 Class: Bookmarks
" Public  Method: Ctor {{{2
function! s:NewBookmarks(fname, ...) " ... = menu
  let self = {
        \ 'Class'        : 'Bookmarks',
        \ 'Load'         : function('s:Bookmarks_Load'),
        \ 'Reload'       : function('s:Bookmarks_Reload'),
        \ 'Save'         : function('s:Bookmarks_Save'),
        \ 'Add'          : function('s:Bookmarks_Add'),
        \ 'Get'          : function('s:Bookmarks_Get'),
        \ 'GetIndex'     : function('s:Bookmarks_GetIndex'),
        \ 'Remove'       : function('s:Bookmarks_Remove'),
        \ 'SetKeyword'   : function('s:Bookmarks_SetKeyword'),
        \ 'RemoveKeyword': function('s:Bookmarks_RemoveKeyword'),
        \ 'IsValid'      : function('s:Bookmarks_IsValid'),
        \ 'Size'         : function('s:Bookmarks_Size'),
        \ 'Exists'       : function('s:Bookmarks_Exists'),
        \ 'Show'         : function('s:Bookmarks_Show'),
        \ 'RefreshMenu'  : function('s:Bookmarks_RefreshMenu'),
        \ 'GetKeywords'  : function('s:Bookmarks_GetKeywords'),
        \ 'Select'       : function('s:Bookmarks_Select'),
        \ 'SelectIndex'  : function('s:Bookmarks_SelectIndex'),
        \ 'IsValidIndex' : function('s:Bookmarks_IsValidIndex'),
        \ 'List_'        : function('s:Bookmarks_List'),
        \ 'ValidateFile_': function('s:Bookmarks_ValidateFile'),
        \ 'fname'        : '',
        \ 'bookmarks'    : [],
        \ 'isValid'      : 0,
        \ 'keywords'     : {},
        \ 'fnames'       : '',
        \ 'menu'         : a:0 > 0 ? a:1 : {}
        \ }

  call self.Load(a:fname)
  return self
endfunction
" }}}2
" Public  Method: Reload {{{2
function! s:Bookmarks_Reload() dict
  if !self.IsValid() | return | endif
  call self.Load(self.fname)
endfunction
" }}}2
" Public  Method: Load {{{2
function! s:Bookmarks_Load(fname) dict
  let fname = expand(a:fname, ':p')

  let self.fname     = fname
  let self.bookmarks = []
  let self.isValid   = 0
  let self.keywords  = {}
  let self.fnames    = {}

  if empty(self.fname)
    return
  endif

  if !filereadable(fname)
    let self.isValid = 1
    call self.RefreshMenu()
    return
  endif

  if !self.ValidateFile_(fname)
    call s:ShowMesg('ErrorMsg', '%s: Invalid file format', fname)
    let self.fname = ''
    return
  endif

  let self.isValid = 1

  let lnum = 0
  let bookmark = {}
  let lines = readfile(fname)
  call remove(lines, 0)

  for line in lines
    let lnum += 1

    if line =~ '^\s*$' | continue | endif

    "" (old version)
    " let group = matchlist(line, 
    "       \ '^\([^:]*\)\s*:\s*\(\%(\a:\)\?[^:]*\):\s*\(\d\+\s*,\s*\d\+\)\?\s*:\(.*\)\?$')
    " if empty(group)
    "   call s:ShowMesg('ErrorMsg', 'line %d: Invalid format', lnum)
    "   continue
    " else
    "   if empty(group[3])
    "     let pos = []
    "   else
    "     let pos = matchlist(group[3], '\(\d\+\)\s*,\s*\(\d\+\)')
    "     if !empty(pos)
    "       let pos = [pos[1]+0, pos[2]+0]
    "     endif
    "   endif

    "   let bookmark = { 'keyword': group[1], 'fname': s:Strip(group[2]), 'pos': pos, 'cmd': group[4] }
    " endif

    try
      let bookmark = eval(line)
      let bookmark = {
            \ 'keyword': get(bookmark, 'keyword', ''),
            \ 'fname'  : get(bookmark, 'fname'  , ''),
            \ 'pos'    : get(bookmark, 'pos'    , []),
            \ 'cmd'    : get(bookmark, 'cmd'    , '')
            \ }

      if type(bookmark.pos) != type([]) && len(bookmark.pos) != 2
        let bookmark.pos = []
      endif
    catch
      call s:ShowMesg('ErrorMsg', 'line %d: Invalid format: %s', lnum, 
            \ substitute(v:exception, '^Vim(\a\+):E\d\+:', '', ''))
      continue
    endtry

    if empty(bookmark.fname)
      call s:ShowMesg('ErrorMsg', 'line %d: Invalid format: No fname', lnum)
      continue
    endif

    if !empty(bookmark.keyword)
      if !s:IsValidKeyword(bookmark.keyword, 1)
        continue
      endif

      if has_key(self.keywords, bookmark.keyword)
        call s:ShowMesg('ErrorMsg', '%s: Duplicate keyword', bookmark.keyword)
        continue
      endif
    endif

    if has_key(self.fnames, bookmark.fname)
      call s:ShowMesg('ErrorMsg', '%s: Duplicate filename', bookmark.fname)
      continue
    endif

    if !empty(bookmark.keyword)
      let self.keywords[bookmark.keyword] = 1
    endif
    let self.fnames[bookmark.fname] = 1

    call add(self.bookmarks, bookmark)
  endfor

  call self.RefreshMenu()
endfunction
" }}}2
" Public  Method: Save {{{2
function! s:Bookmarks_Save() dict
  if !self.IsValid() | return | endif

  if empty(self.fname)
    call s:ShowMesg('ErrorMsg', 'No bookmarks file name')
    return
  endif

  "" (old version)
  " let lines = ['vimbookmarks']
  " for bk in self.bookmarks
  "   if empty(bk.pos)
  "     call add(lines, printf('%s:%s::%s', bk.keyword, bk.fname, bk.cmd))
  "   else
  "     call add(lines, printf('%s:%s:%d,%d:%s', bk.keyword, bk.fname, bk.pos[0], bk.pos[1], bk.cmd))
  "   endif
  " endfor
  " call writefile(lines, self.fname)

  let lines = ['vimbookmarks']
  for bk in self.bookmarks
    let bookmarks = { 'fname': '' }
    for key in ['keyword', 'fname', 'pos', 'cmd']
      if !empty(bk[key])
        let bookmarks[key] = bk[key]
      endif
    endfor

    if !empty(bookmarks.fname)
      call add(lines, string(bookmarks))
    endif
  endfor

  call writefile(lines, self.fname)
endfunction
" }}}2
" Public  Method: Add {{{2
function! s:Bookmarks_Add(fname, cmd, keyword, pos) dict
  if empty(a:fname)
    return 1
  endif

  if !s:IsValidKeyword(a:keyword, 1)
    return 1
  endif

  let fname = expand(a:fname, ':p')
  call self.RemoveKeyword(a:keyword)

  if !empty(a:keyword)
    let self.keywords[a:keyword] = 1
  endif

  if has_key(self.fnames, fname)
    for bookmark in self.bookmarks
      if bookmark.fname == fname
        let bookmark.keyword = a:keyword
        let bookmark.fname   = fname
        let bookmark.cmd     = a:cmd
        let bookmark.pos     = a:pos

        call self.RefreshMenu()
      endif
    endfor
  else
    call add(self.bookmarks, { 'keyword': a:keyword, 'fname': fname, 'cmd': a:cmd, 'pos': a:pos })
    let self.fnames[fname] = 1

    if !empty(self.menu)
      call self.menu.Add(self.Size()-1, fname, a:cmd)
    endif
  endif
endfunction
" }}}2
" Public  Method: IsValidIndex {{{2
function! s:Bookmarks_IsValidIndex(index, ...) dict " ... = show_mesg
  let show_mesg = a:0 > 0 && !empty(a:1)
  if type(a:index) != type(0)
    if show_mesg
      call s:ShowMesg('ErrorMsg', '%s: Invalid index', a:index)
    endif
    return 0
  endif

  if a:index < 0 || len(self.bookmarks) <= a:index
    if show_mesg
      call s:ShowMesg('ErrorMsg', '%s: Index out of range', a:index)
    endif
    return 0
  endif

  return 1
endfunction
" }}}2
" Public  Method: GetIndex(id, is_fname, ...) {{{2
function! s:Bookmarks_GetIndex(id, is_fname, ...) dict " ... = show_mesg
  if !self.IsValid() | return -1 | endif
  let show_mesg = a:0 > 0 && !empty(a:1)

  if type(a:id) == type(0)
    call self.IsValidIndex(a:id, show_mesg)
    return a:id
  endif

  if type(a:id) != type('') || a:id =~ '^\s*$'
    if show_mesg
      call s:ShowMesg('ErrorMsg', '%s: Invalid index', a:id)
    endif
    return -1
  endif

  if a:id =~ '^\d\+$'
    call self.IsValidIndex(a:id+0, show_mesg)
    return a:id + 0
  endif

  if a:is_fname
    if !has_key(self.fnames, a:id)
      if show_mesg
        call s:ShowMesg('ErrorMsg', '%s: File name not present in bookmarks', a:id)
      endif
      return -1
    endif

    let i = 0
    for bookmark in self.bookmarks
      if bookmark.fname == a:id
        return i
      endif
      let i += 1
    endfor

    return -1
  else
    if a:id !~ '^\h\w*$'
      if show_mesg
        call s:ShowMesg('ErrorMsg', '%s: Invalid keyword', a:id)
      endif
      return -1
    endif

    if !has_key(self.keywords, a:id)
      if show_mesg
        call s:ShowMesg('ErrorMsg', '%s: Keyword not present in bookmarks', a:id)
      endif
      return -1
    endif

    let i = 0
    for bookmark in self.bookmarks
      if bookmark.keyword == a:id
        return i
      endif
      let i += 1
    endfor
  endif

  return -1
endfunction
" }}}2
" Public  Method: Get {{{2
function! s:Bookmarks_Get(index) dict 
  if !self.IsValidIndex(a:index) | return {} | endif
  return self.bookmarks[a:index]
endfunction
" }}}2
" Public  Method: Remove {{{2
function! s:Bookmarks_Remove(index) dict
  if !self.IsValidIndex(a:index) | return {} | endif

  let bookmark = self.bookmarks[a:index]
  if !empty(bookmark.keyword)
    call remove(self.keywords, bookmark.keyword)
  endif

  if !empty(bookmark.fname)
    call remove(self.fnames, bookmark.fname)
  endif

  call remove(self.bookmarks, a:index)
  call self.RemoveKeyword(bookmark.keyword)
  call self.RefreshMenu()

  return bookmark
endfunction
" }}}2
" Public  Method: SetKeyword {{{2
function! s:Bookmarks_SetKeyword(index, keyword) dict
  if !self.IsValidIndex(a:index)
    return 1
  endif

  if !s:IsValidKeyword(a:keyword, 1)
    return 1
  endif
  
  call self.RemoveKeyword(a:keyword)
  let self.bookmarks[a:index]['keyword'] = a:keyword
  let self.keywords[a:keyword] = 1
endfunction
" }}}2
" Public  Method: RemoveKeyword {{{2
function! s:Bookmarks_RemoveKeyword(keyword, ...) dict " ... = show_mesg
  let show_mesg = a:0 > 0 && !empty(a:1)
  if !s:IsValidKeyword(a:keyword, show_mesg)
    return 1
  endif

  if empty(a:keyword)
    return 1
  endif

  if has_key(self.keywords, a:keyword)
    for bookmark in self.bookmarks
      if bookmark.keyword == a:keyword
        let bookmark.keyword = ''
        call remove(self.keywords, a:keyword)
        return 0
      endif
    endfor
  endif

  if show_mesg
    call s:ShowMesg('ErrorMsg', '%s: keyword doesn''t exist', a:keyword)
  endif
  return 1
endfunction
" }}}2
" Public  Method: IsValid {{{2
function! s:Bookmarks_IsValid() dict
  return self.isValid
endfunction
" }}}2
" Public  Method: Size {{{2
function! s:Bookmarks_Size() dict
  return len(self.bookmarks)
endfunction
" }}}2
" Public  Method: RefreshMenu {{{2
function! s:Bookmarks_RefreshMenu() dict
  if empty(self.menu)
    return
  endif

  call self.menu.Clear()
  let index = 0
  for bookmark in self.bookmarks
    call self.menu.Add(index, bookmark.fname, bookmark.cmd)
    let index += 1
  endfor
endfunction
" }}}2
" Public  Method: Exists {{{2
function! s:Bookmarks_Exists(id, is_fname) dict
  return self.IsValidIndex(self.GetIndex(a:id, a:is_fname, 0))
endfunction
" }}}2
" Public  Method: Show {{{2
function! s:Bookmarks_Show() dict
  echo join(['Bookmarks:'] + self.List_(), "\n")
endfunction
" }}}2
" Public  Method: SelectIndex {{{2
function! s:Bookmarks_SelectIndex(prompt) dict
  let list = ['Selet bookmark to ' . a:prompt . ': '] + self.List_() 
        \ + ['Type number or keyword and <Enter> (empty cancel): ']
  call inputsave()
  let id = input(join(list, "\n"), '', 'custom,<SNR>'.s:SID().'_KeywordList')
  call inputrestore()

  if id =~ '^\s*$'
    throw 'Bookmarks:Cancel'
  endif

  return self.GetIndex(id, 0, 1)
endfunction
" }}}2
" Public  Method: Select {{{2
function! s:Bookmarks_Select(prompt) dict
  let index = self.SelectIndex(a:prompt)
  return self.Get(index)
endfunction
" }}}2
" Public  Method: GetKeywords {{{2
function! s:Bookmarks_GetKeywords() dict
  return sort(copy(keys(self.keywords)))
endfunction
" }}}2
" Private Method: List {{{2
function! s:Bookmarks_List() dict
  let list = []

  let i = 0
  for bookmark in self.bookmarks
    let index = printf('%d.', i)
    let cmd   = empty(bookmark.cmd) ? '' : (' @:' . bookmark.cmd)
    if empty(bookmark.keyword)
      call add(list, printf('%5s %s%s', index, bookmark.fname, cmd))
    else
      call add(list, printf('%5s [%s] %s%s', index, bookmark.keyword, bookmark.fname, cmd))
    endif
    let i += 1
  endfor

  return list
endfunction
" Private Method: Validate {{{2
function! s:Bookmarks_ValidateFile(fname) dict
  if !filereadable(a:fname)
    return 0
  endif

  if readfile(a:fname, 1)[0] == 'vimbookmarks'
    return 1
  endif

  return 0
endfunction
" }}}1
" {{{ Commands
command! -nargs=0 BookmarkShow  call <SID>GetBookmarks().Show()
command! -nargs=0 ShowBookmarks call <SID>GetBookmarks().Show()

command! -nargs=* -bang -complete=file 
      \ Bookmark call <SID>Bookmark(<q-bang> == '!', <q-args>)

command! -nargs=? -complete=custom,s:KeywordList 
      \ BookmarkRemove call <SID>BookmarkRemove(<q-args>)
command! -nargs=? -complete=custom,s:KeywordList 
      \ RemoveBookmark call <SID>BookmarkRemove(<q-args>)

command! -nargs=? -bang -complete=custom,s:KeywordList 
      \ BookmarkOpen call <SID>BookmarkOpen(<q-args>, <q-bang> == '!')
command! -nargs=? -bang -complete=custom,s:KeywordList 
      \ OpenBookmark call <SID>BookmarkOpen(<q-args>, <q-bang> == '!')

command! -nargs=0 -bang 
      \ BookmarkEdit call <SID>BookmarkEdit(<q-bang> == '!')
command! -nargs=0 -bang 
      \ EditBookmark call <SID>BookmarkEdit(<q-bang> == '!')

command! -nargs=* -bang -complete=custom,s:KeywordList 
      \ BookmarkSetKeyword call <SID>BookmarkSetKeyword(<q-bang> == '!', <q-args>)
command! -nargs=* -bang -complete=custom,s:KeywordList 
      \ SetBookmarkKeyword call <SID>BookmarkSetKeyword(<q-bang> == '!', <q-args>)

command! -nargs=1 -complete=custom,s:KeywordList 
      \ BookmarkRemoveKeyword call <SID>BookmarkRemoveKeyword(<q-args>)
command! -nargs=1 -complete=custom,s:KeywordList 
      \ RemoveBookmarkKeyword call <SID>BookmarkRemoveKeyword(<q-args>)
" }}}
" {{{1 Command Utilities
" {{{2 BookmarkGetIndex(id, prompt)
function! s:BookmarkGetIndex(id, prompt) 
  if !s:IsValidBookmarks() | return | endif
  let bookmarks = s:GetBookmarks()
  if a:id =~ '^\s*$'
    return bookmarks.SelectIndex(a:prompt)
  else
    return bookmarks.GetIndex(a:id, 0, 1)
  endif
endfunction
" }}}2
" {{{2 Bookmark(force, args)
function! s:Bookmark(force, args)
  if !s:IsValidBookmarks() | return | endif

  if type(a:args) == type([])
    let args = a:args
  else
    let args = s:ParseCmdArgs(a:args)
  endif

  if len(args) == 0 || args[0] == '^\s*$'
    let pos = getpos('.')[1:2]
    let fname = expand('%:p')
  else
    let pos = []
    let fname = fnamemodify(args[0], ':p')
  endif

  if empty(fname)
    call s:ShowMesg('ErrorMsg', 'No file name')
    return
  endif

  if !(filereadable(fname) || isdirectory(fname))
    call s:ShowMesg('ErrorMsg', '%s: File is not regular or directory', fname)
    return
  endif

  let keyword = len(args) > 1 ? args[1] : ''
  let cmd     = len(args) > 2 ? args[2] : ''

  if !s:IsValidKeyword(keyword)
    return 1
  endif

  let bookmarks = s:GetBookmarks()
  if !empty(keyword) && bookmarks.Exists(keyword, 0) && !a:force
    call s:ShowMesg('ErrorMsg', '%s: Keyword exists (add ! to override)', keyword)
    return
  endif

  if bookmarks.Exists(fname, 1) && !a:force
    call s:ShowMesg('ErrorMsg', '%s: File exists (add ! to override)', fname)
    return
  endif

  if bookmarks.Add(fname, cmd, keyword, pos) == 0
    call bookmarks.Save()
    call s:RefreshAll()
    call s:ShowMesg('WarningMsg', '%s: Bookmark Added', fname)
    return
  endif
endfunction
" }}}2
" {{{2 BookmarkRemove(args)
function! s:BookmarkRemove(args)
  if !s:IsValidBookmarks() | return | endif
  let args = s:ParseCmdArgs(a:args)
  let id = empty(args) || args[0] =~ '^\s*$' ? '' : args[0]
  try 
    let bookmarks = s:GetBookmarks()
    let bookmark  = bookmarks.Remove(s:BookmarkGetIndex(id, 'remove'))
    if !empty(bookmark)
      call bookmarks.Save()
      call s:RefreshAll()
      call s:ShowMesg('WarningMsg', '%s: Bookmark removed', bookmark.fname)
    endif
  catch /^Bookmarks:Cancel$/
  endtry
endfunction
" }}}2
" {{{2 BookmarkOpen(args, new_tab)
function! s:BookmarkOpen(args, new_tab)
  if !s:IsValidBookmarks() | return | endif
  let args = s:ParseCmdArgs(a:args)
  let id = empty(args) || args[0] =~ '^\s*$' ? '' : args[0]
  try 
    call s:OpenBookmark(s:BookmarkGetIndex(id, 'open'), a:new_tab)
  catch /^Bookmarks:Cancel$/
  catch
    call s:ShowMesg('ErrorMsg', v:exception)
  endtry
endfunction
" }}}2
" {{{2 BookmarkEdit()
function! s:BookmarkEdit(new_tab)
  if s:OpenFile(g:Bookmarks_fname, a:new_tab) == 0
    au BufWritePost <buffer> call RefreshBookmarks(1)|call s:RefreshAll()
  endif
endfunction
" }}}2
" {{{2 BookmarkSetKeyword(force, args)
function! s:BookmarkSetKeyword(force, args)
  if !s:IsValidBookmarks() | return | endif

  let args = s:ParseCmdArgs(a:args)
  let bookmarks = s:GetBookmarks()
  if empty(args)
    try 
      let index = bookmarks.SelectIndex('set keyword')
    catch /^Bookmarks:Cancel$/
      return
    endtry
  else
    let index = bookmarks.GetIndex(args[0], 0, 1)
  endif

  if !bookmarks.IsValidIndex(index)
    return
  endif

  if len(args) < 2
    call inputsave()
    let keyword = input(printf('[%s] Keyword: ', index))
    call inputrestore()
  else
    let keyword = args[1]
  endif

  if !s:IsValidKeyword(keyword, 1)
    return
  endif

  if bookmarks.Exists(keyword, 0) && !a:force
    call s:ShowMesg('ErrorMsg', '%s: keyword exists (add ! to override)', keyword)
    return
  endif

  if bookmarks.SetKeyword(index, keyword) == 0
    call bookmarks.Save()
    call s:RefreshAll()
    call s:ShowMesg('WarningMsg', '[%s] %s: keyword set', index, keyword)
  endif
endfunction
" }}}2
" {{{2 BookmarkRemoveKeyword(keyword)
function! s:BookmarkRemoveKeyword(keyword) 
  if !s:IsValidBookmarks() | return | endif
  let bookmarks = s:GetBookmarks()
  if bookmarks.RemoveKeyword(a:keyword) == 0
    call bookmarks.Save()
    call s:RefreshAll()
    call s:ShowMesg('WarningMsg', '%s: keyword removed', a:keyword)
  endif
endfunction
" }}}2
" }}}1
call RefreshBookmarks()
" Restore {{{1
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
