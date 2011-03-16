" FileExplorer.vim
" Last Modified: 2010-09-02 05:45:13
"        Author: Frank Chang <frank.nevermind AT gmail.com>
"
" A tree view file browser.

" Load Once {{{
if exists('loaded_FileExplorer_plugin')
  finish
endif
let loaded_FileExplorer_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"========================================================
" Variables {{{
let s:INDENT = 2
let s:MSWIN  = has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')
"}}}
" Options {{{
let s:DEFAULT_OPTION = {
    \   'WinWidth'          : 24,
    \   'Max_Create_Level'  : 1,
    \   'Filter'            : '',
    \   'FilterInv'         : 0,
    \   'Arrange_Options'   : { 'sorted' : 1, 'ascending' : 1, 'sortedBy' : 'name' },
    \   'Hidden_Files'      : 0,
    \   'Use_Right_Window'  : 0,
    \   'OpenHandler'       : '',
    \   'Encoding'          : '',
    \ }

let s:OPT_PREFIX = 'FileExplorer_'
function! s:GetOption(opt, ...) " ... = always_get_global_opt {{{
  let scopes = (a:0 == 0 || a:1 == 0) ? ['b:', 'g:'] : ['g:']
  for scope in scopes
    if exists(scope . s:OPT_PREFIX . a:opt)
      return copy({scope}{s:OPT_PREFIX}{a:opt})
    endif
  endfor
  return copy(s:DEFAULT_OPTION[a:opt])
endfunction
"}}}
function! s:SetOption(opt, val, ...) " ... = global {{{
  let scope = (a:0 == 0 || a:1 == 0) ? 'b:' : 'g:'
  let {scope}{s:OPT_PREFIX}{a:opt} = a:val
endfunction
"}}}
"}}}
" Commands {{{
command! -nargs=? -bar -count=0 -complete=dir -bang FileExplorer call s:FileExplorer(<q-args>, <count>, <q-bang> == '!')
"}}}
" Utilities {{{
function! s:ShowMessage(mesg) "{{{
  echohl ErrorMsg | echom a:mesg | echohl None
endfunction
"}}}
function! s:GetFilename(node) "{{{
  return s:MSWIN ? get(a:node.attributes, 'link', a:node.nodeValue) : a:node.nodeValue
endfunction
"}}}
function! s:Resolve(filename) "{{{
	let encoding = s:GetOption('Encoding')
	if encoding == '' || encoding == &enc
		return resolve(a:filename)
	else
		return iconv(resolve(iconv(a:filename, &enc, encoding)), encoding, &enc)
	endif
endfunction
"}}}
function! s:Basename(path) "{{{
  let path = substitute(a:path, '\([\\/]\)[\\/]*', '\1', 'g')
  if path =~ '^[\\/]$'
    return path
  endif
  let path = substitute(path, '[\\/]$', '', 'g')
  return matchstr(path, '[^\\/]\+$')
endfunction
"}}}
function! s:Dirname(path) "{{{
  if match(a:path, '^\%([a-zA-Z]:[\\/]*\|[\\/]\+\)[^\\/]*[\\/]*$') != -1
    return matchstr(a:path, '^\%([a-zA-Z]:\|[\\/]\)')
  elseif match(a:path, '^[^\\/]\+[\\/]*$') != -1
    return '.'
  endif
  
  return substitute(a:path, '[\\/]\+[^\\/]\+[\\/]*$', '', 'g')
endfunction
"}}}
function! s:Fullpath(path) "{{{
  let path = a:path
  if s:MSWIN && path =~ '^[A-Za-z]:$'
    let path .= '/'
  endif
  let path = fnamemodify(path, ':p')
  if path =~ '[^\\/][\\/]\+$'
    return substitute(path, '[\\/]\+$', '', 'g')
  else
    return path
  endif
endfunction
"}}}
"}}}
" BuildFileTree(dir[, max_level]) {{{
if s:MSWIN
  function! s:GetLink(file) "{{{
    return a:file =~ '\.lnk$' ? s:Resolve(a:file) : ''
  endfunction
  "}}}
else
  function! s:GetLink(file) "{{{
    return getftype(a:file) == 'link' ? s:Resolve(a:file) : ''
  endfunction
  "}}}
endif
function! s:CreateNode(name, file) "{{{
  let file = substitute(a:file, '/$', '', '')
  
  let attributes = { 'foldclosed': 0, 'expanded': 0 }
  
  let link = s:GetLink(file)
  if link != ''
    let attributes.link = link
  endif

  return Node#New({ 'nodeName': a:name, 'nodeValue': file, 'attributes': attributes })
endfunction
"}}}
function! s:GetFiles(dir) "{{{
  if s:MSWIN && a:dir =~ '^[a-zA-Z]:$'
    let dir = a:dir . '/'
  else
    let dir = fnamemodify(a:dir, ':p')
  endif
  let files = split(glob(dir . '*'), '\n')
  let filter = s:GetOption('Filter')

  let op = s:GetOption('FilterInv') ? '!~' : '=~'
	let cmp = '(v:val ' . op . ' filter)'
  if s:GetOption('Hidden_Files')
    let hidden_files = split(glob(dir . '.*'), '\n')
    call filter(hidden_files, 'v:val !~ ''[\\/]\.\.\?$''')
    let files += hidden_files
  endif

	call map(files, 'fnamemodify(v:val, '':p'')')
  call filter(files, cmp)
  call sort(files, 's:FileCompare')

  return files
endfunction
"}}}
if s:MSWIN
  function! s:Isdirectory(directory) "{{{
    return isdirectory(a:directory =~ '\.lnk$' ? s:Resolve(a:directory) : a:directory)
  endfunction
  "}}}
else
  let s:Isdirectory = function('isdirectory')
endif
function! s:BuildFileTree(dir, ...) " ... = max_level {{{
  let max_level = (a:0 == 0 || (a:1+0) == 0) ? s:GetOption('Max_Create_Level') : (a:1+0)

  if !exists('b:_FileExplorer_node_foldclosed')
    let b:_FileExplorer_node_foldclosed = {}
  endif

  call s:SetupArrange(s:GetOption('Arrange_Options'))
  if Node#IsNode(a:dir) 
    let node = a:dir
  else
    let node = s:CreateNode('root', s:Fullpath(a:dir))
    call s:SetNodeFoldClosed(node, 0)
  endif
  call garbagecollect()

  " Each file can only be visited once.
  " If file is a link to its parent directory, then it could be revisited.
  let visited = {} 
  try
    return s:BuildFileTreeIntra(node, 0, max_level, visited)
  catch /^Vim:Interrupt$/
    return node
  endtry
endfunction
"}}}
function! s:BuildFileTreeIntra(node, current_level, max_level, visited) "{{{
  if get(a:node.attributes, 'expanded', 1) == 1
    return a:node
  endif

  if a:max_level > 0 && a:current_level >= a:max_level 
        \   && get(b:_FileExplorer_node_foldclosed, a:node.nodeValue, 1) == 1
    let a:node.attributes['foldclosed'] = 1
    return a:node
  endif

  if has_key(a:visited, a:node.nodeValue)
    let a:node.attributes['foldclosed'] = 1
    return a:node
  endif

  let dir = s:GetFilename(a:node)
  let a:node.attributes['expanded'] = 1
  let a:visited[a:node.nodeValue] = 1

  for file in s:GetFiles(dir)
    if s:Isdirectory(file)
      let node = s:CreateNode('node', file)
      let tree = s:BuildFileTreeIntra(node, a:current_level + 1, a:max_level, a:visited)
      call Node#AppendChild(a:node, tree)
    else
      let node = s:CreateNode('leaf', file)
      call Node#AppendChild(a:node, node)
    endif
  endfor

  return a:node
endfunction
"}}}
" SetupArrange(options) {{{
"
" options: 
"    { 
"       'ascending': [0|1],
"       'sorted'   : [0|1],
"       'sortedBy' : [name|size|date|type],
"    }
"
function! s:FileCompare_Name(i1, i2) "{{{
  let flag = 2 * isdirectory(a:i1) + isdirectory(a:i2)
  return flag == 1 
        \ ? 1
        \ : flag == 2
        \   ? -1
        \   : a:i1 >? a:i2 
        \     ? s:ascending
        \     : a:i1 <? a:i2 
        \       ? -s:ascending 
        \       : 0
endfunction
"}}}
function! s:FileCompare_Size(i1, i2) "{{{
  let flag = 2 * isdirectory(a:i1) + isdirectory(a:i2)
  if flag == 1
    return 1
  endif

  if flag == 2
    return -1
  endif

  if flag == 3
    return a:i1 >? a:i2 ? s:ascending : a:i1 <? a:i2 ? -s:ascending : 0
  endif

  if has_key(s:CompareCache, a:i1)
    let size1 = s:CompareCache[a:i1]
  else
    let size1 = getfsize(a:i1)
    let s:CompareCache[a:i1] = size1
  endif

  if has_key(s:CompareCache, a:i2)
    let size2 = s:CompareCache[a:i2]
  else
    let size2 = getfsize(a:i2)
    let s:CompareCache[a:i2] = size2
  endif

  return size1 > size2 ? s:ascending : size1 < size2 ? -s:ascending : 0
endfunction
"}}}
function! s:FileCompare_Date(i1, i2) "{{{
  if has_key(s:CompareCache, a:i1)
    let date1 = s:CompareCache[a:i1]
  else
    let date1 = getftime(a:i1)
    let s:CompareCache[a:i1] = date1
  endif

  if has_key(s:CompareCache, a:i2)
    let date2 = s:CompareCache[a:i2]
  else
    let date2 = getftime(a:i2)
    let s:CompareCache[a:i2] = date2
  endif

  return date1 > date2 ? s:ascending : date1 < date2 ? -s:ascending : 0
endfunction
"}}}
function! s:FileCompare_Type(i1, i2) "{{{
  let flag = 2 * isdirectory(a:i1) + isdirectory(a:i2)
  if flag == 1
    return 1
  endif

  if flag == 2
    return -1
  endif

  if has_key(s:CompareCache, a:i1)
    let type1 = s:CompareCache[a:i1]
  else
    let type1 = matchstr(a:i1, '\.\zs[^.]\+$')
    let s:CompareCache[a:i1] = type1
  endif

  if has_key(s:CompareCache, a:i2)
    let type2 = s:CompareCache[a:i2]
  else
    let type2 = matchstr(a:i2, '\.\zs[^.]\+$')
    let s:CompareCache[a:i2] = type2
  endif

  return type1 >? type2 ? s:ascending : type1 <? type2 ? -s:ascending : 0
endfunction
"}}}
function! s:FileCompare_Default(i1, i2) "{{{
  return 0
endfunction
"}}}
function! s:FileCompare(i1, i2) "{{{
  return s:FileCompareFunc(a:i1, a:i2)
endfunction
"}}}
function! s:SetupArrange(options) "{{{
  let s:CompareCache = {}
  if get(a:options, 'sorted', 1) == 1
    let s:ascending = get(a:options, 'ascending', 0) ? 1 : -1
    let type = get(a:options, 'sortedBy', 'name')
    
    if type == 'name'
      let s:FileCompareFunc = function('s:FileCompare_Name')
      return
    elseif type == 'size'
      let s:FileCompareFunc = function('s:FileCompare_Size')
      return
    elseif type == 'date'
      let s:FileCompareFunc = function('s:FileCompare_Date')
      return
    elseif type == 'type'
      let s:FileCompareFunc = function('s:FileCompare_Type')
      return
    endif
  endif
  let s:FileCompareFunc = function('s:FileCompare_Default')
endfunction
"}}}
call s:SetupArrange(s:GetOption('Arrange_Options'))
" }}}
" }}}
" functions: folds related {{{
function! s:SetNodeFoldClosed(node, closed) "{{{
  let a:node.attributes['foldclosed'] = a:closed
  let b:_FileExplorer_node_foldclosed[a:node.nodeValue] = a:closed
endfunction
"}}}
function! s:OpenFold(node) "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  if Node#IsNullNode(a:node)
    return
  endif

  let node = a:node.nodeName == 'leaf' ? node.parentNode : a:node

  if node.attributes['foldclosed'] == 1
    call s:SetNodeFoldClosed(node, 0)
    if node.attributes['expanded'] == 0
      call s:BuildFileTree(node, 1)
    endif

    call s:ShowTree(b:_FileExplorer_root, get(node.attributes, 'line', 1))
  endif
endfunction
"}}}
function! s:CloseFold(node) "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  if Node#IsNullNode(a:node)
    return
  endif

  let node = a:node.nodeName == 'leaf' 
        \ ? a:node.parentNode 
        \ : a:node.attributes['foldclosed'] == 1
        \   ? a:node.parentNode
        \   : a:node

  if Node#IsNullNode(node)
    return
  endif

  if node.attributes['foldclosed'] == 0
    call s:SetNodeFoldClosed(node, 1)
    call s:ShowTree(b:_FileExplorer_root, get(node.attributes, 'line', 1))
  endif
endfunction
"}}}
function! s:ToggleFold(node) "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  if Node#IsNullNode(a:node)
    return
  endif
  
  if a:node.attributes['foldclosed']
    call s:OpenFold(a:node)
  else
    call s:CloseFold(a:node)
  endif
endfunction
"}}}
function! s:CloseAllFolds(node) "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  let node = a:node
  if node.nodeName != 'root'
    while !Node#IsNullNode(node.parentNode) && node.parentNode.nodeName != 'root'
      let node = node.parentNode
    endwhile
  endif

  if Node#IsNullNode(node)
    return
  endif

  let line = get(node.attributes, 'line', 1)

  if node.nodeName != 'root' && node.attributes['foldclosed'] == 0
    call s:SetNodeFoldClosed(node, 1)
  endif

  let childs = copy(node.childNodes)
  while !empty(childs)
    let node = remove(childs, 0)
    if node.nodeName == 'node' && node.attributes['foldclosed'] == 0
      call s:SetNodeFoldClosed(node, 1)
      if Node#HasChildNodes(node)
        call extend(childs, node.childNodes)
      endif
    endif
  endwhile
  call s:ShowTree(b:_FileExplorer_root, line)
endfunction
"}}}
function! s:OpenAllFolds(node, ...) " ... = max_level {{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  if !Node#IsNode(a:node)
    return
  endif

  let node = a:node.nodeName == 'leaf' ? a:node.parentNode : a:node
  let line = get(node.attributes, 'line', 1)

  let max_level = a:0 && (a:1+0) > 0 ? (a:1+0) : -1
  if node is b:_FileExplorer_root
    call s:ShowTree(s:BuildFileTree(node.nodeValue, max_level), line)
    return
  endif

  if Node#IsNullNode(node.parentNode)
    return
  endif

  let new_node = s:BuildFileTree(s:CreateNode(node.nodeName, node.nodeValue), max_level)
  call Node#ReplaceChild(node.parentNode, new_node, node)
  call s:ShowTree(b:_FileExplorer_root, line)
endfunction
"}}}
function! s:MoveBetweenFolds(forward, cnt) "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  let cnt = a:cnt
  let inc = a:forward ? 1 : -1
  let line = line('.') + inc
  let total = line('$')
  while line > 0 && line <= total
    let node = s:GetNode(line)
    if !Node#IsNullNode(node) && (node.nodeName == 'node' || node.nodeName == 'root')
      if node.attributes.line > 0
        if exists('b:_FileExplorer_help_endlnum')
          call cursor(node.attributes.line + b:_FileExplorer_help_endlnum, 1)
        else
          call cursor(node.attributes.line, 1)
        endif
      endif
      let cnt -= 1
      if cnt <= 0
        return
      endif
    endif
    let line += inc
  endwhile
endfunction
"}}}
function! s:MoveBetweenSameLevelFolds(forward, cnt) "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  if a:cnt == 0
    return
  endif

  let line = line('.')
  let node = s:GetNode(line)

  if Node#IsNullNode(node) || node.nodeName == 'root'
    return
  endif

  if node.nodeName == 'leaf'
    let node = node.parentNode
  endif

  if Node#IsNullNode(node) || node.nodeName == 'root'
    return
  endif

  let parent_node = node.parentNode

  if Node#IsNullNode(parent_node)
    return
  endif

  let childNodes = parent_node.childNodes

  let index = 0
  for child in childNodes
    if child is node
      break
    endif
    let index += 1
  endfor

  let lnum = -1
  let cnt = a:cnt

  while 1
    if a:forward
      let index += 1
      if index >= len(childNodes)
        break
      endif
    else
      let index -= 1
      if index < 0
        break
      endif
    endif

    let node = childNodes[index]

    if node.nodeName == 'node'
      let lnum = node.attributes.line
      let cnt -= 1
      if cnt <= 0
        break
      endif
    endif
  endwhile

  if lnum == -1
    return
  endif

  if exists('b:_FileExplorer_help_endlnum')
    let lnum += b:_FileExplorer_help_endlnum
  endif

  call cursor(lnum, 1)
endfunction
"}}}
"}}}
" functions: history related {{{
function! s:PushHistory(...) "{{{
  if a:0 == 0 && !exists('b:_FileExplorer_root')
    return
  endif

  if !exists('b:_FileExplorer_history')
    let b:_FileExplorer_history = []
  endif

  call add(b:_FileExplorer_history, a:0 == 0 ? b:_FileExplorer_root : a:1)
endfunction
"}}}
function! s:PopHistory() "{{{
  if !exists('b:_FileExplorer_history') || empty(b:_FileExplorer_history)
    return Node#NullNode()
  endif

  return remove(b:_FileExplorer_history, -1)
endfunction
"}}}
"}}}
function! s:GetIcon(name, foldclosed) "{{{
  return a:name != 'node' ? '' : a:foldclosed ? '+' : '-'
endfunction
"}}}
function! s:GetDescription(node) "{{{
  if has_key(a:node.attributes, 'link')
		let link = a:node.attributes['link']
    let description = s:Basename(a:node.nodeValue)
    let link = ' -> ' . substitute(link, '[\\/]$', '', '')
    if s:MSWIN
      if exists('+shellslash') && &ssl
        let link = substitute(link, '\\', '/', 'g')
      endif
      let description = substitute(description, '\.lnk$', '', '')
    endif
    return description . link
  elseif a:node.nodeName == 'root'
    return a:node.nodeValue
  else
    return s:Basename(a:node.nodeValue)
  endif
endfunction
"}}}
" BuildLines(root) {{{
function! s:BuildLines(root) "{{{
  let lines = []
  try
    call s:BuildLinesIntra([a:root], lines, 0)
	catch /^Vim:Interrupt$/
  endtry
  return lines
endfunction
"}}}
function! s:BuildLinesIntra(nodes, lines, level) "{{{
  for node in a:nodes
    let line = { 'level': a:level, 'description': s:GetDescription(node), 'node': node }
    call add(a:lines, line)
    let line.node.attributes['line'] = len(a:lines)
    if node.attributes['foldclosed'] == 0
      call s:BuildLinesIntra(node.childNodes, a:lines, a:level + 1)
    endif
  endfor
endfunction
"}}}
"}}}
function! s:ShowTree(root, ...) " ... = lnum (put cursor on line 'lnum') or filename {{{
  let pos = getpos('.')

  if a:0 > 0 && type(a:1) == type('')
    let nodeValue = a:1
  else
    let node = s:GetNode(pos[1])
    let nodeValue = Node#IsNullNode(node) ? '' : node.nodeValue
  endif

  let prev_root = exists('b:_FileExplorer_root') ? b:_FileExplorer_root : Node#NullNode()
  let b:_FileExplorer_root = a:root
  let b:_FileExplorer_lines = s:BuildLines(b:_FileExplorer_root)
  
  setlocal ma
  silent %d _

  call s:ShowHelp(b:_FileExplorer_show_help)
  let begin_lnum = 1
  if exists('b:_FileExplorer_help_endlnum')
    let begin_lnum += b:_FileExplorer_help_endlnum
  endif

  let first = 1
  let lnum  = 0

  for line in b:_FileExplorer_lines
    let node = line['node']
    if prev_root isnot b:_FileExplorer_root && node is prev_root
      let lnum = first ? begin_lnum : (line('$')+1)
    endif
    let indent = s:INDENT * line['level']
    if indent > 0 && node.nodeName == 'node'
      let indent -= 1
    endif
    if node.nodeValue == nodeValue
      let lnum = first ? begin_lnum : (line('$') + 1)
    endif
    let output = repeat(' ', indent) 
          \ . s:GetIcon(node.nodeName, node.attributes['foldclosed'])
          \ . line['description']
    if first
      call setline(begin_lnum, output)
      let first = 0
    else
      call append(line('$'), output)
    endif
  endfor

  setlocal noma

  if a:0 > 0 && type(a:1) == type(0) && a:1 > 0
    if exists('b:_FileExplorer_help_endlnum')
      let pos[1] = a:1 + b:_FileExplorer_help_endlnum
    else
      let pos[1] = a:1
    endif
  elseif lnum > 0
    let pos[1] = lnum
  endif
  call setpos('.', pos)

  if exists('b:_FileExplorer_root')
    exec 'lcd ' . s:Fnameescape(s:GetFilename(b:_FileExplorer_root))
  endif
endfunction
"}}}
function! s:OpenFile(file, type, focus) " focus on new file window {{{
  let curwin = winnr()
  let curtabpage = tabpagenr()

  " type: 
  "   0: open in previous window
  "   1: open in split window
  "   2: open in new tabpage
  let file = escape(a:file, ' ')
  if a:type == 2
    tabnew
    exec (has('gui') ? 'drop' : 'hide edit') . ' ' . file
    if a:focus
      FileExplorer
      wincmd p
    endif
  elseif a:type
    wincmd p
    exec 'split  ' . file
  else
    wincmd p
    exec (has('gui') ? 'drop' : 'hide edit') . ' ' . file
  endif

  if !a:focus
    exe 'tabn 'curtabpage 
    exe curwin . 'wincmd w'
  endif
endfunction
"}}}
function! s:OnClick(node, type, focus) " ... = jump_to_prev_window {{{
  if Node#IsNullNode(a:node)
    return
  endif

  if a:node.nodeName == 'root'
    call s:GoUp()
  elseif a:node.nodeName == 'leaf'
    let openHandler = s:GetOption('OpenHandler', 1)
    if !empty(openHandler)
      if (type(openHandler) != type('') || type(openHandler) != type('type'))
        call s:ShowMessage('FileExplorer: OpenHandler mush be String or Funcref')
      elseif (type(openHandler) == type('') && !exists('*'.openHandler))
        call s:ShowMessage('FileExplorer: OpenHandler function "' . openHandler . '" doesn''t exist')
      else
        if call(openHandler, [s:GetFilename(a:node)])
          return
        endif
      endif
    endif

    call s:OpenFile(s:GetFilename(a:node), a:type, a:focus)
  else
    call s:ToggleFold(a:node)
  endif
endfunction
"}}}
function! s:GoUp() "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  let root = b:_FileExplorer_root
  if !Node#IsNullNode(b:_FileExplorer_root.parentNode)
    call s:MakeRoot(b:_FileExplorer_root.parentNode)
  else
    let file = b:_FileExplorer_root.nodeValue 
    let dir = s:Dirname(file)

    if dir == b:_FileExplorer_root.nodeValue
      return
    endif
    call s:ShowTree(s:BuildFileTree(dir, 0), file)
  endif
  call s:PushHistory(root)
endfunction
"}}}
function! s:GoBack() "{{{
  call s:MakeRoot(s:PopHistory())
endfunction
"}}}
function! s:MakeRoot(node) " {{{
  if Node#IsNullNode(a:node)
    return
  endif

  if !exists('b:_FileExplorer_root')
    return
  endif

  let node = a:node
  if node.nodeName == 'leaf'
    let node =  node.parentNode
  endif

  if node is b:_FileExplorer_root
    return
  endif

  let b:_FileExplorer_root.nodeName = 'node'
  let node.nodeName = 'root'

  call s:ShowTree(node)

  " Alway open one fold
  call s:OpenFold(node)
endfunction
"}}}
function! s:FileCheck(file) "{{{
  if a:file =~ '^\s*$'
    return 1
  endif

  let file = s:Resolve(a:file)
  if isdirectory(file)
    return 0
  elseif filereadable(file)
    call s:ShowMessage(a:file . ': Not a directory')
    return 1
  endif
  call s:ShowMessage(a:file . ': No such directory')
  return 1
endfunction
"}}}
function! s:GetBufname() "{{{
  let name = '_FileExplorer_<%d>'
  let name_pat = '^_FileExplorer_<\d\+>$'
  for bufnr in tabpagebuflist()
    let bufname = bufname(bufnr)
    if bufname =~ name_pat
      return [bufname, bufwinnr(bufnr)]
    endif
  endfor

  let i = 0
  for bufnr in range(1, bufnr('$'))
    if bufexists(bufnr)
      let bufname = bufname(bufnr)
      if bufname =~ name_pat
        let i += 1
        if !bufloaded(bufnr)
          return [bufname, -1]
        endif
      endif
    endif
  endfor

  return [printf(name, i+1), -1]
endfunction
"}}}
function! s:FileExplorer(dir, ...) " ... = max_level [0:Max_Create_Level], otherside {{{
  let [bufname, winnum] = s:GetBufname()

  let filename = ''
  if a:dir == ''
    if winnum != -1
      try
        exe winnum . 'wincmd w'
        wincmd c
      catch /^Vim\%((\a\+)\)\=:E444/
        echohl ErrorMsg
        echom  substitute(v:exception, '^Vim\%((\a\+)\)\=:E444:\s*', '', '')
        echohl None
      endtry
      return
    endif
    if &ft == 'netrw' && exists('b:netrw_curdir')
      let path = b:netrw_curdir
      let filename = path
    else
      let path = expand('%:p:h')
      let filename = substitute(expand('%:p'), '/$', '', '')
    endif
  elseif a:dir =~ '^//' && exists('*Bookmarks_GetPath') 
    let id = substitute(a:dir, '^//', '', '')
    let path = substitute(Bookmarks_GetPath(id), '[\\/]$', '', '') 
    let filename = path
  else
    let path = substitute(fnamemodify(simplify(a:dir), ':p'), '[\\/]$', '', '')
    let filename = path
  endif

  if s:FileCheck(path)
    return
  endif

  if winnum != -1
    if winnr() != winnum
			exe winnum . 'wincmd w'
    endif
  else
    let split = s:GetOption('Use_Right_Window', 1) ? 1 : 0
    if a:0 > 1 && a:2 == 1
      let split = 1 - split
    endif
    exe 'silent vertical ' . ['topleft', 'botright'][split] . ' new'
    silent setlocal bt=nofile bh=delete noswf nobl
    exe 'silent f '. bufname

    exe 'vertical resize ' . s:GetOption('WinWidth')
    setlocal cul nonu nowrap

    if !exists('b:_FileExplorer_show_help')
      let b:_FileExplorer_show_help = 0
    endif

    " Add support for Bookmark.vim
    if exists('*Bookmarks_Bookmark') && !exists('*s:Bookmark')
      function! s:Bookmark(force, args) 
        if empty(a:args)
          let node = s:GetNode(line('.'))
          if !Node#IsNullNode(node)
            return Bookmarks_Bookmark(a:force, [node.nodeValue])
          endif
        endif
        return Bookmarks_Bookmark(a:force, a:args)
      endfunction
    endif

    call s:InitCommands()
    call s:InitMappings()
    call s:InitHighlight()
  endif
  
  setlocal wfw
  call s:ShowTree(s:BuildFileTree(path, (a:0 > 0 ? a:1 : 0)), filename)
endfunction
"}}}
function! s:Refresh(...) "{{{
  let max_level = a:0 == 0 ? 0 : (a:1+0)
  if exists('b:_FileExplorer_root')
    call s:ShowTree(s:BuildFileTree(b:_FileExplorer_root.nodeValue, max_level))
  endif
endfunction
"}}}
function! s:ShowHelp(...)  " ... = show [0:don't show|1:show|-1(default)] {{{
  let file_explorer_show_help = a:0 == 0 || a:1 == -1 ? (1-b:_FileExplorer_show_help) : a:1 == 1 ? 1 : 0

  let ma_old = &l:ma
  setlocal ma
  if exists('b:_FileExplorer_help_endlnum') && b:_FileExplorer_help_endlnum != 0 && b:_FileExplorer_help_endlnum <= line('$')
    exec 'silent 1,' . b:_FileExplorer_help_endlnum . 'd_'
  endif

  let usage = ''
  if file_explorer_show_help
    let usage .= "\" Mappings:\n"
    let usage .= "\"  o|<CR>|<2-LeftMouse> : Open file in previous window and focus\n"
    let usage .= "\"  go|g<CR> : Open file in previous window\n"
    let usage .= "\"  <Tab> : Open file in new window and focus\n"
    let usage .= "\"  g<Tab> : Open file in new window\n"
    let usage .= "\"  t : Open file in new tabpage and focus\n"
    let usage .= "\"  T : Open file in new tabpage\n"
    let usage .= "\"  F : Fine file in previous window\n"
    let usage .= "\"  zc : Close one fold\n"
    let usage .= "\"  zo : Open one fold\n"
    let usage .= "\"  za : Toggle one fold\n"
    let usage .= "\"  zM : Close all folds\n"
    let usage .= "\"  [N]zR : Open N level folds (default is highest level)\n"
    let usage .= "\"  zC : Close all folds under the cursor\n"
    let usage .= "\"  [N]zO : Open N level folds under the cursor (default is highest level)\n"
    let usage .= "\"  zj : Move downwards to the next fold\n"
    let usage .= "\"  zk : Move upwards to the previous fold\n"
    let usage .= "\"  zJ|J : Move downwards to the next fold of same level\n"
    let usage .= "\"  zK|K : Move upwards to the previous fold of same level\n"
    let usage .= "\"  z<CR> : Refresh and goto root line\n"
    let usage .= "\"  r : Refresh\n"
    let usage .= "\"  R : Make root\n"
    let usage .= "\"  u : Goto parent dir\n"
    let usage .= "\"  p : Goto previous root\n"
    let usage .= "\"  i : File info\n"
    let usage .= "\"  I : Filetype (use program 'file')\n"
    let usage .= "\"  q : Quit\n"
    let usage .= "\"  <F1> : Toggle help\n"
    let usage .= "\"\n"
    let usage .= "\" Commands:\n"
    let usage .= "\"  :Refresh\n"
    let usage .= "\"  :ArrangeBy|:SortBy"
		if exists('s:sort_settings') && type(s:sort_settings) == type([])
			let usage .= ' [' . join(s:sort_settings, '|') . ']*'
		endif
		let usage .= "\n"
    let usage .= "\"  :SetFilter[!] [pattern]: Inverted filter if !. Show current setting if ! and no pattern is set.\n"
    let usage .= "\"  :ShowHiddenFiles[!]: Toggle if !\n"
    let usage .= "\"  :Cd|:Chdir {dir}: Change root\n"
		let usage .= "\" \n"
    let usage .= "\" --\n"
    let usage .= "\" " . s:GetFilterInfo() . "\n"
    let usage .= "\" " . s:GetArrangeInfo() . "\n"
    let usage .= "\n"

    let b:_FileExplorer_show_help = 1
  else
    let usage  = "\" Press <F1> for Help\n\n"

    let b:_FileExplorer_show_help = 0
  endif

  silent 0put! =usage
  let b:_FileExplorer_help_endlnum = len(split(usage, "\n"))
  let &l:ma = ma_old
endfunction
"}}}
function! s:InitCommands() "{{{
  command! -buffer -count=0 Refresh call s:Refresh(<count>)

  command! -buffer -nargs=* -complete=custom,s:ListSortSettings ArrangeBy 
        \ call s:ArrangeBy(<q-args>)
  command! -buffer -nargs=* -complete=custom,s:ListSortSettings SortBy
        \ call s:ArrangeBy(<q-args>)
  command! -buffer -bang -nargs=? SetFilter call s:SetFilter(<q-args>, <q-bang> == '!')
  command! -buffer -bang ShowHiddenFiles call s:ShowHiddenFiles(<q-bang> == '!')

  command! -buffer -nargs=? -complete=dir Cd    call s:Chdir(<q-args>)
  command! -buffer -nargs=? -complete=dir Chdir call s:Chdir(<q-args>)

  command! -buffer Info echo s:GetNodeInfo(s:GetNode(line('.')))

  command! -buffer -nargs=0 Cwd call s:Cwd(s:GetNode(line('.')))

  command! -buffer -nargs=? -complete=file FindFile call s:FindFile(<q-args>)

  if exists('*s:Bookmark')
    command! -buffer -nargs=* -bang -complete=file 
          \ Bookmark call s:Bookmark(<q-bang> == '!', <q-args>)
  endif

  au BufLeave <buffer> setlocal nocul
  au BufEnter <buffer> setlocal cul

  " When FileExplorer is the only window left in the current tabpage, quit this window
  au BufEnter <buffer> if winnr() == winnr('$')|q|endif
endfunction

if exists('*fnameescape')
  let s:Fnameescape = function('fnameescape')
else
  function! s:Fnameescape(string) 
    let fname = escape(a:string, " \t\n*?[{`$\\%#'\"|!<")
    if fname =~ '^[\-+]\|^-$'
      let fname = '\' . fname
    endif
    return fname
  endfunction
endif

function! s:Cwd(node) "{{{
  if Node#IsNullNode(a:node)
    return
  endif

  let node = a:node
  if node.nodeName == 'leaf'
    let node = node.parentNode
  endif

  if Node#IsNullNode(node)
    return
  endif

  exec 'cd! ' . s:Fnameescape(node.nodeValue)

  echohl WarningMsg
  echo 'FileExplorer: Change the current working directory to ' . node.nodeValue
  echohl None
endfunction
"}}}
function! s:GetArrangeInfo() "{{{
  let arrange_options = s:GetOption('Arrange_Options')

  if arrange_options['sorted'] == 0
    return 'Unsorted'
  else
    return 'Sorted by ' . substitute(arrange_options['sortedBy'], '^\(.\)\(.*\)', '\u\1\L\2', '')
          \ . ', ' . (arrange_options['ascending'] ? 'ascending' : 'descending')
  endif
endfunction
"}}}
function! s:ArrangeBy(options) "{{{
  if a:options =~? '\<default\>'
    call s:SetOption('Arrange_Options', s:GetOption('Arrange_Options', 1))
    Refresh
    return
  endif

  let arrange_options = s:GetOption('Arrange_Options')

  if a:options == ''
    echo s:GetArrangeInfo()
    return
  endif

  if a:options =~? '\<unsorted\>'
    let arrange_options['sorted'] = 0
  endif

  if a:options =~? '\<sorted\>'
    let arrange_options['sorted'] = 1
  endif

  if a:options =~? '\<ascending\>'
    let arrange_options['ascending'] = 1
  endif

  if a:options =~? '\<descending\>'
    let arrange_options['ascending'] = 0
  endif

  if a:options =~? '\<type\>'
    let arrange_options['sortedBy'] = 'type'
  endif

  if a:options =~? '\<date\>'
    let arrange_options['sortedBy'] = 'date'
  endif

  if a:options =~? '\<size\>'
    let arrange_options['sortedBy'] = 'size'
  endif

  if a:options =~? '\<name\>'
    let arrange_options['sortedBy'] = 'name'
  endif

  call s:SetOption('Arrange_Options', arrange_options)
  Refresh
endfunction
"}}}
let s:sort_settings = ['default', 'unsorted', 'sorted', 'ascending', 'descending', 'name', 'size', 'date', 'type']
function! s:ListSortSettings(A, L, P) "{{{
  return join(s:sort_settings, "\n")
endfunction
"}}}
function! s:GetFilterInfo() "{{{
    return 'Filter pattern' . (s:GetOption('FilterInv') ? ' [!]' : '') . ': ' . s:GetOption('Filter')
endfunction
"}}}
function! s:SetFilter(filter, ...) " ... = inv {{{
  if a:0 && a:1 == 1 && a:filter == ''
    echom s:GetFilterInfo()
    return
  endif
  call s:SetOption('FilterInv', a:0 && a:1 == 1)
  call s:SetOption('Filter', a:filter)
  Refresh
endfunction
"}}}
function! s:ShowHiddenFiles(inv) "{{{
  if a:inv == !s:GetOption('Hidden_Files')
        \ || !a:inv == s:GetOption('Hidden_Files')
    return
  endif
  call s:SetOption('Hidden_Files', !a:inv)
  Refresh
endfunction
"}}}
function! s:Chdir(dir) "{{{
  let path = fnamemodify((a:dir == '' ? '~' : a:dir), ':p')

  if s:FileCheck(path)
    return
  endif
  
  call s:PushHistory()
  call s:FileExplorer(path)
endfunction
"}}}
function! s:GetNodeFiletype(node) "{{{
  if Node#IsNullNode(a:node)
    return ''
  endif

  let file = a:node.nodeValue
  return s:GetFiletype(file)
endfunction
"}}}
function! s:GetFiletype(file) "{{{
  if !executable('file')
    call s:ShowMessage('FileExplorer: The program "file" must be installed')
    return ''
  endif

  let file = fnamemodify(a:file, ':p')
  if glob(file) == ''
    return ''
  endif

  return substitute(system('file ' . mylib#Shellescape(file)), '\n\+$', '', '')
endfunction
"}}}
function! s:GetNodeInfo(node) "{{{
  if Node#IsNullNode(a:node)
    return ''
  endif

  let file = a:node.nodeValue
  return s:GetFileInfo(file)
endfunction
"}}}
function! s:GetFileInfo(file) "{{{
  let file = fnamemodify(a:file, ':p')
  if glob(file) == ''
    return ''
  endif

  let name = file
  let perm = getfperm(file)
  let size = s:SizeRepr(getfsize(file))

  let type = matchstr(getftype(file), '^.')
  if type == 'f' || type == ''
    let type = '-'
  endif

  let time = strftime('%Y-%m-%d %H:%M', getftime(file))

  return printf("%s%s %s %s %s", type, perm, size, time, file)
endfunction
"}}}
function! s:SizeRepr(size) "{{{
  if a:size < 1024
    return a:size
  endif

  let size = a:size
  for unit in ['K', 'M', 'G', 'T']
    let i = size / 1024
    let f = size % 1024 * 1000 / 1024 
    let f = f / 10 + (f % 10 >= 5 ? 1 : 0)
    if i < 1024 || unit == 'T'
      return printf('%d.%02d%s', i, f, unit)
    endif
    let size = size / 1024
  endfor

  return a:size
endfunction
"}}}
"}}}
function! s:GetRootLnum() "{{{
  return !exists('b:_FileExplorer_help_endlnum') ? 1 : (b:_FileExplorer_help_endlnum + 1)
endfunction
"}}}
function! s:GotoRootLine() "{{{
  exec 'normal! ' . s:GetRootLnum() . 'G'
endfunction
"}}}
function! s:InitMappings() "{{{
  nnoremap <buffer> <silent> o      :<C-U>call <SID>OnClick(<SID>GetNode(line('.')), 0, 1)<CR>
  nnoremap <buffer> <silent> go     :<C-U>call <SID>OnClick(<SID>GetNode(line('.')), 0, 0)<CR>
  nnoremap <buffer> <silent> <Tab>  :<C-U>call <SID>OnClick(<SID>GetNode(line('.')), 1, 1)<CR>
  nnoremap <buffer> <silent> g<Tab> :<C-U>call <SID>OnClick(<SID>GetNode(line('.')), 1, 0)<CR>
  nnoremap <buffer> <silent> t      :<C-U>call <SID>OnClick(<SID>GetNode(line('.')), 2, 1)<CR>
  nnoremap <buffer> <silent> T      :<C-U>call <SID>OnClick(<SID>GetNode(line('.')), 2, 0)<CR>

  nnoremap <buffer> <silent> F      :<C-U>call <SID>FindFile('')<CR>

  if exists('*s:Bookmark')
    nnoremap <buffer> <silent> gb :<C-U>call <SID>Bookmark(v:count, '')<CR>
  endif

  nmap     <buffer> <silent> <CR> o
  nmap     <buffer> <silent> g<CR> go
  nmap     <buffer> <silent> <2-LeftMouse> o

  " Folds
  nnoremap <buffer> <silent> zc :<C-U>call <SID>CloseFold(<SID>GetNode(line('.')))<CR>
  nnoremap <buffer> <silent> zo :<C-U>call <SID>OpenFold(<SID>GetNode(line('.')))<CR>
  nnoremap <buffer> <silent> za :<C-U>call <SID>ToggleFold(<SID>GetNode(line('.')))<CR>
  nnoremap <buffer> <silent> zM :<C-U>call <SID>CloseAllFolds(<SID>GetNode(<SID>GetRootLnum()))<CR>
  nnoremap <buffer> <silent> zR :<C-U>call <SID>OpenAllFolds(<SID>GetNode(<SID>GetRootLnum()), v:count)<CR>
  nnoremap <buffer> <silent> zC :<C-U>call <SID>CloseAllFolds(<SID>GetNode(line('.')))<CR>
  nnoremap <buffer> <silent> zO :<C-U>call <SID>OpenAllFolds(<SID>GetNode(line('.')), v:count)<CR>
  nnoremap <buffer> <silent> zj :<C-U>call <SID>MoveBetweenFolds(1, v:count1)<CR>
  nnoremap <buffer> <silent> zk :<C-U>call <SID>MoveBetweenFolds(0, v:count1)<CR>
  nnoremap <buffer> <silent> zJ :<C-U>call <SID>MoveBetweenSameLevelFolds(1, v:count1)<CR>
  nnoremap <buffer> <silent> zK :<C-U>call <SID>MoveBetweenSameLevelFolds(0, v:count1)<CR>
  nnoremap <buffer> <silent> J  :<C-U>call <SID>MoveBetweenSameLevelFolds(1, v:count1)<CR>
  nnoremap <buffer> <silent> K  :<C-U>call <SID>MoveBetweenSameLevelFolds(0, v:count1)<CR>

  nnoremap <buffer> <silent> z<CR> :<C-U>exec v:count . 'Refresh'<CR>:call <SID>GotoRootLine()<CR>
  nnoremap <buffer> <silent> r     :<C-U>exec v:count . 'Refresh'<CR>

  nnoremap <buffer> <silent> R :<C-U>call <SID>PushHistory()<CR>:call <SID>MakeRoot(<SID>GetNode(line('.')))<CR>:call <SID>GotoRootLine()<CR>
  nnoremap <buffer> <silent> u :<C-U>call <SID>GoUp()<CR>
  nnoremap <buffer> <silent> p :<C-U>call <SID>GoBack()<CR>
  nnoremap <buffer> <silent> i :<C-U>echo <SID>GetNodeInfo(<SID>GetNode(line('.')))<CR>
  nnoremap <buffer> <silent> I :<C-U>echo <SID>GetNodeFiletype(<SID>GetNode(line('.')))<CR>
  nnoremap <buffer> <silent> q <C-W>c

  nnoremap <buffer> <silent> <F1> :<C-U>call <SID>ShowHelp()<CR>
endfunction

function! s:GetNode(line) "{{{
  if !exists('b:_FileExplorer_lines')
    return Node#NullNode()
  endif

  let line = a:line
  if exists('b:_FileExplorer_help_endlnum')
    let line -= b:_FileExplorer_help_endlnum
  endif
  
  let idx = line - 1
  if idx >= 0 && idx < len(b:_FileExplorer_lines)
    return b:_FileExplorer_lines[idx]['node']
  endif

  return Node#NullNode()
endfunction
"}}}
"}}}
function! s:InitHighlight() "{{{
  let prefix_space = printf('^%s\%%(%s\)*', repeat(' ', s:INDENT-1), repeat(' ', s:INDENT))

  syntax clear
  syntax match TreeLeaf '^.*'
  exe 'syntax match TreeNode ''' . prefix_space . '[-+].*'' contains=TreeIcon'

  syntax match TreeRoot '[^ ].*'

  syntax match FileExplorerHelp '^".*'
  exe 'syntax match TreeIcon contained ''\%(' . prefix_space . '\)\@<=[-+]'''

  exe 'syntax match FileSymlink contained ''\%(' . prefix_space . '[-+]\)\@<=.\{-1,}\%( ->\)\@='' containedin=TreeNode,TreeRoot,TreeLeaf'

  exe 'syntax match FileSymlink contained ''\%(^\%(' . repeat(' ', s:INDENT) . '\)\+\)\@<=[^ ].\{-}\%( ->\)\@='' containedin=TreeNode,TreeRoot,TreeLeaf'

	highlight default link TreeRoot Define
	highlight default link TreeNode Label
  " highlight default link TreeLeaf Normal
  highlight default link TreeIcon Comment
  highlight default link FileSymlink Function
  highlight default link FileExplorerHelp Comment
endfunction
"}}}
function! s:FindFile(path) "{{{
  if !exists('b:_FileExplorer_root')
    return
  endif

  let root_path = b:_FileExplorer_root.nodeValue

  if (empty(a:path))
    let curwin = winnr()
    wincmd p
    let path = s:Fullpath(expand('%'))
    exe curwin . 'wincmd w'
  else
    let path = s:Fullpath(a:path)
  endif

  let index = matchend(path, '^\V' . escape(root_path, '\'))
  if index == -1
    call s:ShowMessage('FileExplorer: Cannot find file under current root')
    return
  endif

  let tail = path[index : ]

  let node = b:_FileExplorer_root
  let path = root_path

  for term in split(tail, '/')
    let path .= '/' . term

    let found = 0
    for child in node.childNodes
      if child.nodeValue == path
        if child.nodeName == 'leaf'
          let pos = getpos('.')
          let pos[1] = get(child.attributes, 'line', 1)
          if exists('b:_FileExplorer_help_endlnum')
            let pos[1] += b:_FileExplorer_help_endlnum
          endif
          call setpos('.', pos)
          return
        endif

        call s:OpenFold(child)
        let node = child
        let found = 1
        break
      endif
    endfor

    if found == 0
      call s:ShowMessage('FileExplorer: Cannot show given path (nonexistent or hidden)')
      return
    endif
  endfor
endfunction
"}}}
"========================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
