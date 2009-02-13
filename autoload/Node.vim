" Node.vim
" Last Modified: 2008-03-30 11:05:41
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_Node_plugin')
  finish
endif
let loaded_Node_plugin = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}
"========================================================
" Variables {{{
let s:NullNode = {}
let s:Default = { 
        \   'parentNode' : s:NullNode,
        \   'attributes' : {},
        \   'nodeType'   : 0,
        \   'nodeName'   : '',
        \   'nodeValue'  : '',
        \   'childNodes' : [],
        \   'handler'    : '',
        \ }
"}}}
"========================================================
function! Node#NullNode() "{{{
  return s:NullNode
endfunction
"}}}
function! Node#IsNullNode(node) "{{{
  return a:node is s:NullNode
endfunction
"}}}
function! Node#IsNode(node) "{{{
  if type(a:node) != type({})
    return 0
  endif

  for key in keys(s:Default)
    if !has_key(a:node, key)
      return 0
    endif
  endfor

  return 1
endfunction
"}}}
function! Node#New(node) "{{{
  let self = {}
  let isDict = type(a:node) == type({})
  for key in keys(s:Default) 
    let self[key] = (isDict && has_key(a:node, key)) ? a:node[key]: s:Default[key]
    if self[key] isnot s:NullNode
      let self[key] = copy(self[key])
    endif
  endfor
  return self
endfunction
"}}}
function! Node#ClondeNode(self, deep) "{{{
  let node = Node#New(a:self)
  let node.handler = ''
  if a:deep
    let childs = []
    for child in node.childNodes
      call add(childs, Node#ClondeNode(childs, 1))
    endfor
    let node.childNodes = childs
  else
    let node.childNodes = copy(node.childNodes)
  endif
  return node
endfunction
"}}}
function! Node#ReplaceChild(self, newChild, oldChild) "{{{
  if Node#IsNullNode(a:oldChild) || a:oldChild.parentNode isnot a:self.parentNode
    return s:NullNode
  endif

  let childs = a:self.childNodes
  for idx in range(len(childs))
    if childs[idx] is a:oldChild
      let childs[idx] = a:newChild
      let a:newChild.parentNode = a:self
      let a:oldChild.parentNode = s:NullNode
      return a:oldChild
    endif
  endfor
  return s:NullNode
endfunction
"}}}
function! Node#HasChildNodes(self) "{{{
  return !empty(a:self.childNodes)
endfunction
"}}}
function! Node#AppendChild(self, newChild) "{{{
  call s:Node_RemoveNode(a:self, a:newChild)
  call add(a:self.childNodes, a:newChild)
  let a:newChild.parentNode = a:self
  return a:newChild
endfunction
"}}}
function! Node#InsertBefore(self, newChild, refChild) "{{{
  if Node#IsNullNode(a:refChild) || a:refChild.parentNode isnot a:self.parentNode
    return a:Node_AppendChild(a:self, a:newChild)
  endif

  let childs = a:self.childNodes
  for idx in range(len(childs))
    if childs[idx] is a:refChild
      call s:Node_RemoveNode(a:self, a:newChild)
      call insert(childs, a:newChild, idx)
      let a:newChild.parentNode = a:self
      return a:newChild
    endif
  endfor
endfunction
"}}}
function! Node#RemoveChild(self, oldChild) "{{{
  if Node#IsNullNode(a:oldChild) || a:oldChild.parentNode isnot a:self.parentNode
    return a:oldChild
  endif

  for node in a:self.childNodes
    if node is a:oldChild
      call s:Node_RemoveNode(node)
      let a:oldChild.parentNode = s:NullNode
      return a:oldChild
    endif
  endfor
endfunction
"}}}
function! s:Node_RemoveNode(self, ...) " ... must be in the same tree {{{
  if a:0 > 0
    if a:self is a:1
      let node = a:1
    else
      if Node#IsNullNode(a:1) || Node#IsNullNode(a:1.parentNode)
        return
      endif

      let root1 = s:GetRootNode(a:self)
      let root2 = s:GetRootNode(a:1)

      if root1 isnot root2
        return
      else
        let node = a:1
      endif
    endif
  else
    let node = a:self
  endif

  let parent = node['parentNode']
  if Node#IsNullNode(parent)
    return
  endif

  let siblings = parent['childNodes']
  for idx in range(len(siblings))
    if siblings[idx] is node
      call remove(siblings, idx)
      let siblings[idx].parentNode = s:NullNode
      break
    endif
  endfor
endfunction
"}}}
function! s:GetRootNode(node) "{{{
  let parent = a:node
  while !Node#IsNullNode(parent.parentNode)
    let parent = parent.parentNode
  endwhile
  return parent
endfunction
"}}}
"========================================================
" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
