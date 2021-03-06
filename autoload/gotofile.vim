" GoToFile.vim
" Last Modified: 2011-12-31 21:57:26
"        Author: Frank Chang <frank.nevermind AT gmail.com>

" Load Once {{{
if exists('loaded_autoload_GoToFile') && !has('python')
  finish
endif
let loaded_autoload_GoToFile = 1

let s:save_cpo = &cpo
set cpo&vim
"}}}

python3 << EOF

import re
import os
import vim
import fzfinder
import finder
import flist

def gotofile_open_file(f, t):
  if t == 1 :
    edit = 'split'
  else:
    if vim.eval('has("gui")') == '1':
      edit = 'drop'
    else:
      edit = 'hide edit'
    if t == 2 : edit = 'tab ' + edit

  vim.command("exec '%s' fnameescape('%s')" % (edit, re.sub(r"'", r"''", f)))


def gotofile_set_items(win):
  if vim.eval("exists('g:flist_name') && filereadable(g:flist_name)") != '0':
    filelist = flist.Flist(vim.eval('g:flist_name'))
    win.set_items(filelist.get())
    if vim.eval("exists('g:gotofile_flist_auto_update') && g:gotofile_flist_auto_update") != '0':
      filelist.dump('filelist')
    vim.command('let g:_goto_file_window_filelist_mtime = getftime(g:flist_name)')
  else:
    win.set_items(flist.Flist().get())

class GoToFileWindow:
    def __init__(self, items = [], option = {}, finder = fzfinder.FzFinder, 
                 open_handler = gotofile_open_file, filter_pattern = []):
        self.buffer = None
        self.bufnr = -1
        self.items = items
        self.option = option
        self.abbrev = None
        self.matched_items = None
        self.open_handler = open_handler
        self.filter_enabled = False
        self.filter = flist.Flist(option = {'search_dot_files': '1'})
        self.filter.add_pattern(filter_pattern)
        self.finder = finder(self._filter(self.items), self.option)
        self.highlight = True

    def enable_filter(self):
        self.filter_enabled = True
        self.finder.set_items(self._filter(self.items))

    def disable_filter(self):
        self.filter_enabled = False
        self.finder.set_items(self._filter(self.items))

    def toggle_highlight(self):
        self.highlight = not self.highlight

    def toggle_filter(self):
        self.filter_enabled = not self.filter_enabled
        self.finder.set_items(self._filter(self.items))

    def _filter(self, items):
        if self.filter_enabled and self.filter.get_pattern():
          return [item for item in items if self.filter.match(item)]
        else:
          return items

    def set_buffer(self):
        if vim.eval("has('conceal')") == "1":
            vim.command('setl conceallevel=3 concealcursor=nvic')
            if int(vim.eval("v:version")) < 704:
              vim.command(r'syn match GoToFilePlaceHolder "\%x00" conceal')
              vim.command(r'syn match GoToFileHighlight "\%x00\@<=[^\x00]"')
            else:
              vim.command(r'syn match GoToFilePlaceHolder "\%#=1\%x00" conceal')
              vim.command(r'syn match GoToFileHighlight "\%#=1\%x00\@<=[^\x00]"')

        self.buffer = vim.current.buffer
        self.bufnr = int(vim.eval("bufnr('%')"))

    def get_filter_pattern(self):
      return self.filter.get_pattern()

    def set_filter_pattern(self, filter_pattern):
        self.filter_enabled = True
        can_skip = lambda line: re.match(r"\s*#|\s*$", line) != None
        filter_pattern = [pattern for pattern in filter_pattern if not can_skip(pattern)]
        self.filter.add_pattern(filter_pattern, False)
        self.finder.set_items(self._filter(self.items))

    def set_items(self, items):
        self.items = items
        self.finder.set_items(self._filter(self.items))

    def set_finder(self, finder):
        self.finder = finder(self._filter(self.items), self.option)

    def set_option(self, option):
        self.finder.set_option(option)

    if vim.eval("has('conceal')") == "1":
        def _highlight(self, name, pos):
            if not self.highlight or not pos:
              return name
            return "\0".join(name[start : end] for start, end in zip([0] + pos, pos + [len(name)]))
    else:
        def _highlight(self, name, pos):
            return name

    def search(self, abbrev, force = False):
        if not self.buffer or (not force and self.abbrev == abbrev):
          return

        if abbrev is None:
          abbrev = self.abbrev

        vim.command("call setbufvar(%d, '&ma', 1)" % (self.bufnr, ))
        self.matched_items = self.finder.search(abbrev)
        self.buffer[:] = [ self._highlight(item.name, item.pos) for item in self.matched_items ]
        vim.command("call setbufvar(%d, '&ma', 0)" % (self.bufnr, ))

        if self.filter_enabled:
          filter_enabled = 'on'
        else:
          filter_enabled = 'off'
        vim.command("call setbufvar(%d, 'gotofile_status', '%d file(s) found [filter:%s]')" \
                    % (self.bufnr, len(self.matched_items), filter_enabled))
        self.abbrev = abbrev

    def open(self, file_indexes, open_type):
      if not self.matched_items:
        return

      for index in file_indexes:
        try:
          self.open_handler(self.matched_items[index].private, open_type)
        except IndexError:
          pass

_goto_file_window = GoToFileWindow()

EOF

if !exists('g:gotofile_flist_auto_update')
  let g:gotofile_flist_auto_update = 1
endif

if !exists('g:gotofile_preserve_abbrev')
  let g:gotofile_preserve_abbrev = 1
endif

let s:gotofile_abbrev = ""

function! gotofile#get_status_string()
  return exists('b:gotofile_status') ? b:gotofile_status : ''
endfunction

function! s:SID()
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction

function s:ResultWindowUpdate(force)
  let s:gotofile_abbrev = getline('.')
  py3 if _goto_file_window: _goto_file_window.search(vim.eval("s:gotofile_abbrev"), int(vim.eval('a:force')))
endfunction

function! s:EnterQueryWindow(motion, append)
  let bufnum = s:gotofile_bufnr['query']
  if bufnum == -1 | return | endif

  let winnum = bufwinnr(bufnum)
  if winnum == -1 | return | endif

  exec winnum . "wincmd w"

  if len(a:motion) | exec "normal" a:motion | endif

  if a:append
    startinsert!
  else
    startinsert
  endif
endfunction

function! s:EnterResultWindow()
  let bufnum = s:gotofile_bufnr['result']
  if bufnum == -1 | return | endif

  let winnum = bufwinnr(bufnum)
  if winnum == -1 | return | endif

  call feedkeys(printf("%d\<C-W>\<C-W>", winnum), 'n')
endfunction

let s:gotofile_bufnr = { 'result': -1, 'query': -1 }

function! s:CloseGoToFileWindow()
  for [type, bufnum] in items(s:gotofile_bufnr)
    if bufnum == -1
      continue
    endif

    let s:gotofile_bufnr[type] = -1

    if bufnr('%') == bufnum
      continue
    endif

    let winnum = bufwinnr(bufnum)
    if winnum != -1
      exe winnum . 'wincmd w'
      silent! close!
    endif
  endfor

  if exists("g:_goto_file_window_opt_paste")
    let &paste = g:_goto_file_window_opt_paste
  endif
endfunction

" type:
"   0: open in current window
"   1: open in splitted window
"   2: open in new tabpage
function! s:OpenFile(type) range
  " Close GoToFileWindow first
  close!

  if g:_goto_file_window_prev_buf != -1
    let winnum = bufwinnr(g:_goto_file_window_prev_buf)
    if winnum != -1
      exe winnum . 'wincmd w'
    endif
  end

  py3 if not _goto_file_window: vim.command('return')
  py3 _goto_file_window.open(range(int(vim.eval('a:firstline'))-1, int(vim.eval('a:lastline'))), int(vim.eval('a:type')))
endfunction

function s:QueryWindowInit()
  resize 1
  setl nonu
  setl wfh
  setl nowrap

  "setl statusline=[Go\ to\ File]

  if has("signs")
    sign define go_to_file_prompt text=: texthl=Label
    exe "sign place 1 line=1 name=go_to_file_prompt buffer=" . bufnr('%')
  endif

  inoremap <buffer> <silent> <CR>  <C-C>:<C-U>call <SID>OpenFile(0)<CR>
  nnoremap <buffer> <silent> <CR>  :<C-U>call <SID>OpenFile(0)<CR>

  inoremap <buffer> <silent> <F3>  <C-C>:<C-U>call <SID>ShowFilterWindow()<CR>
  nnoremap <buffer> <silent> <F3>  :<C-U>call <SID>ShowFilterWindow()<CR>
  inoremap <buffer> <silent> <F2>  <C-C>:<C-U>call <SID>ToggleFilter(1)<CR>
  nnoremap <buffer> <silent> <F2>  :<C-U>call <SID>ToggleFilter(1)<CR>
  inoremap <buffer> <silent> <F5>  <C-C>:<C-U>call <SID>ToggleHighlight(1)<CR>
  nnoremap <buffer> <silent> <F5>  :<C-U>call <SID>ToggleHighlight(1)<CR>

  inoremap <buffer> <silent> <C-A> <Home>
  inoremap <buffer> <silent> <C-E> <End>

  augroup GoToFileQueryWindow
    au!
    if exists('*lightline#update')
      au CursorMovedI <buffer> call s:ResultWindowUpdate(0) | call lightline#update()
    else
      au CursorMovedI <buffer> call s:ResultWindowUpdate(0)
    endif
    au BufWinLeave <buffer> call s:CloseGoToFileWindow()
    au InsertLeave <buffer> call s:EnterResultWindow()
  augroup END
endfunction

function s:ResultWindowInit()
  py3 _goto_file_window.set_buffer()

  setl nu
  setl cursorline
  setl nowrap
  setl noma

  hi default link GoToFileHighlight Underlined

  nnoremap <buffer> <silent> a        :<C-U>call <SID>EnterQueryWindow("l", 0)<CR>
  nnoremap <buffer> <silent> A        :<C-U>call <SID>EnterQueryWindow("",  1)<CR>
  nnoremap <buffer> <silent> <insert> :<C-U>call <SID>EnterQueryWindow("",  0)<CR>
  nnoremap <buffer> <silent> i        :<C-U>call <SID>EnterQueryWindow("",  0)<CR>
  nnoremap <buffer> <silent> I        :<C-U>call <SID>EnterQueryWindow("^", 0)<CR>
  nnoremap <buffer> <silent> gI       :<C-U>call <SID>EnterQueryWindow("0", 0)<CR>
  nnoremap <buffer> <silent> gi       :<C-U>call <SID>EnterQueryWindow("",  0)<CR>
  nnoremap <buffer> <silent> o        :<C-U>call <SID>EnterQueryWindow("0", 0)<CR>
  nnoremap <buffer> <silent> O        :<C-U>call <SID>EnterQueryWindow("0", 0)<CR>

  nnoremap <buffer> <silent> <F3>     :<C-U>call <SID>ShowFilterWindow()<CR>
  nnoremap <buffer> <silent> <F2>     :<C-U>call <SID>ToggleFilter(0)<CR>
  nnoremap <buffer> <silent> <F5>     :<C-U>call <SID>ToggleHighlight(0)<CR>

  nnoremap <buffer> <silent> <CR>          :<C-U>call <SID>OpenFile(0)<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :<C-U>call <SID>OpenFile(0)<CR>
  nnoremap <buffer> <silent> <Tab>         :<C-U>call <SID>OpenFile(1)<CR>
  nnoremap <buffer> <silent> t             :<C-U>call <SID>OpenFile(2)<CR>

  augroup GoToFileResultWindow
    au!
    au BufWinLeave <buffer> call s:CloseGoToFileWindow()
  augroup END
endfunction

let g:_goto_file_window_cwd = ''
let g:_goto_file_window_prev_buf = -1
let g:_goto_file_window_filelist_mtime = -1

function! s:ToggleFilter(query_window) 
  py3 _goto_file_window.toggle_filter()
  py3 _goto_file_window.search(None, True)
  if a:query_window
    silent call s:EnterQueryWindow('', 1)
  endif
endfunction

function! s:ToggleHighlight(query_window) 
  py3 _goto_file_window.toggle_highlight()
  py3 _goto_file_window.search(None, True)
  if a:query_window
    silent call s:EnterQueryWindow('', 1)
  endif
endfunction

function! s:FilterWindowUpdate()
  py3 _goto_file_window.set_filter_pattern(vim.current.buffer[:])
  py3 _goto_file_window.search(None, True)
  setl nomodified
  " silent call s:EnterResultWindow()
endfunction

function! s:FilterWindowInit()
  setlocal bt=acwrite
  py3 vim.current.buffer[:] = _goto_file_window.get_filter_pattern()
  startinsert

  augroup GoToFileFilterWindow
    au!
    au BufWriteCmd <buffer> call s:FilterWindowUpdate()
  augroup END
endfunction

function! s:ShowFilterWindow() 
  let s:curwinnum = winnr()
  let winnum = CreateSharedTempBuffer('[GoToFile Filter]', 'topleft', '<SNR>'.s:SID().'_FilterWindowInit')
  exe winnum . 'wincmd w'
endfunction

function! gotofile#CreateGoToFileWindow() 
  let curbuf = bufnr('%')
  if curbuf != s:gotofile_bufnr['result'] && curbuf != s:gotofile_bufnr['query']
    let g:_goto_file_window_prev_buf = curbuf
  endif

  let curwinnum = winnr()
  let winnum = CreateSharedTempBuffer('[GoToFile Result]', '<SNR>'.s:SID().'_ResultWindowInit')
  exe winnum . 'wincmd w'

  let cwd = getcwd()
  if g:_goto_file_window_cwd != cwd
    py3 gotofile_set_items(_goto_file_window)
    let g:_goto_file_window_cwd = cwd
  elseif exists('g:flist_name') && filereadable(g:flist_name) && getftime(g:flist_name) > g:_goto_file_window_filelist_mtime
    py3 gotofile_set_items(_goto_file_window)
  endif

  let s:gotofile_bufnr['result'] = winbufnr(winnum)

  let curwinnum = winnr()
  let winnum = CreateSharedTempBuffer('[GoToFile]', '<SNR>'.s:SID().'_QueryWindowInit')
  exe winnum . 'wincmd w'

  let s:gotofile_bufnr['query'] = winbufnr(winnum)

  if g:gotofile_preserve_abbrev
    call setline(1, s:gotofile_abbrev)
  else
    call setline(1, '')
  endif
  call s:ResultWindowUpdate(1)

  let g:_goto_file_window_opt_paste = &paste

  " the option 'paste' must be turned off, otherwise all user mappings in insert mode would not work
  let &paste = 0

  startinsert!
endfunction

" Restore {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" vim: fdm=marker :
