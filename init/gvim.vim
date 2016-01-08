"===============================================================
" GVim Only
"
" Reference:
"   + $VIMRUNTIME/mswin.vim
"   - $VIMRUNTIME/gvimrc_example.vim
"================================================================
if !has('gui_running')
  finish
endif

" set 'selection', 'selectmode', 'mousemodel' and 'keymodel' for MS-Windows
behave mswin

" Hide the mouse when typing text
set mousehide		

" CTRL-X is Cut
vnoremap <C-X> "+x

" CTRL-C is Copy
vnoremap <C-C> "+y

" CTRL-V is Paste
" noremap  <C-V> "+gP
" cnoremap <C-V> <C-R>+

" Pasting blockwise and linewise selections is not possible in Insert and
" Visual mode without the +virtualedit feature.  They are pasted as if they
" were characterwise instead.
" Uses the paste.vim autoload script.

" exe 'inoremap <script> <C-V>' paste#paste_cmd['i']
" exe 'vnoremap <script> <C-V>' paste#paste_cmd['v']

" imap <S-Insert> <C-V>
" vmap <S-Insert>	<C-V>

" For CTRL-V to work autoselect must be off.
" On Unix we have two selections, autoselect can be used.
if !has("unix")
  set guioptions-=a
endif

" vim: fdm=marker : ts=2 : sw=2 :
