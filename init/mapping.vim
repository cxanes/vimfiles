" Summary: (<Leader>gu to id |utl_usr.txt|)
"   <F1>      Help
"   <F2>      Save                              <#r=Save>
"
"   <F3>      SuperTab    (insert)              <#r=SuperTab>
"   <F3>      BufExplorer (normal)              <#r=BufExplorer>
"
"   <F4>      Quit                              <#r=Quit>
"   <F7>      Filter                            <#r=Filter>
"   <F8>      Open Scratch 
"              <http://www.vim.org/scripts/script.php?script_id=389>
"   <F9>      Dictionary (sdcv)                 <#r=Dictionary>
"   <F11>     Remove last search pattern |@/|   <#r=Search>
"   <F12>     Toggle spell checking |spell|     <#r=Spell>
"--------------------------------------------------------------

" Map: Motion Commands
" ';' and ',' will repeat the previous motion command (with count) 
nnoremap <silent> ; :<C-U>call <SID>RepeatMotion(';', 0)<CR>
nnoremap <silent> , :<C-U>call <SID>RepeatMotion(',', 1)<CR>

function! s:MotionCmd(cmd) "{{{
  " Only multiple h,j,k,l motions will be recorded.
  if stridx('hjkl', a:cmd) != -1 && v:count1 <= 1
    return a:cmd
  endif

  let b:last_motion_cmd = [v:count1, a:cmd]
  return a:cmd
endfunction
"}}}
function! s:RepeatMotion(cmd, inv) "{{{
  if !exists('b:last_motion_cmd') 
        \ || stridx('ftFT', b:last_motion_cmd[1]) != -1
        \ || !has_key(s:inv_motion_cmd, b:last_motion_cmd[1])
    exec 'normal! ' . v:count1 . a:cmd
    return
  endif

  if v:count != 0
    let b:last_motion_cmd[0] = v:count
  endif

  let cmd = a:inv ? get(s:inv_motion_cmd, b:last_motion_cmd[1], '') : b:last_motion_cmd[1]
  if cmd != ''
    if stridx(cmd, "\<Plug>CamelCaseMotion_") == -1
      exec 'normal! ' . b:last_motion_cmd[0] . cmd
    else
      silent exec 'normal ' . b:last_motion_cmd[0] . cmd
    endif
  endif
endfunction
"}}}
let s:inv_motion_cmd = {'w': 'b' , 'b': 'w' , 'W': 'B', 'B': 'W', ')': '(' , '(': ')' , '}': '{', '{': '}',
      \                 'j': 'k' , 'k': 'j' , 'h': 'l', 'l': 'h', 'f': 'F' , 'F': 'f' , 't': 'T', 'T': 't',
      \                 'e': 'ge', 'E': 'gE', 
      \                 "\<Plug>CamelCaseMotion_w": "\<Plug>CamelCaseMotion_b",
      \                 "\<Plug>CamelCaseMotion_b": "\<Plug>CamelCaseMotion_w",
      \                 "\<Plug>CamelCaseMotion_e": '',
      \                }
function! s:MotionMappings() "{{{
  for cmd in keys(s:inv_motion_cmd)
    exec printf('nnoremap <expr> %s <SID>MotionCmd(''%s'')', cmd, cmd)
  endfor
endfunction
"}}}
call s:MotionMappings()
delfunction s:MotionMappings

" <id=CamelCaseMotion>
" camelcasemotion.vim: http://vim.sourceforge.net/scripts/script.php?script_id=1905
function! s:CamelCaseMotionMappings() "{{{
  let lhs_fmt = '<M-%s>'

  for motion in ['w', 'b', 'e']
    let lhs = printf(lhs_fmt, motion) 
    exec printf('nmap <silent> <expr> %s <SID>MotionCmd(''%s'')', lhs, 
          \ ('<Plug>CamelCaseMotion_' . motion))
  endfor

  for mode in ['o', 'v']
    for motion in ['w', 'b', 'e']
      let lhs = printf(lhs_fmt, motion) 
      exec mode . 'map <silent> '  . lhs . ' ' . '<Plug>CamelCaseMotion_' . motion
      exec mode . 'map <silent> i' . lhs . ' ' . '<Plug>CamelCaseMotion_i'. motion
    endfor
  endfor
endfunction
"}}}
call s:CamelCaseMotionMappings()
delfunction s:CamelCaseMotionMappings

" Open fold and move to right when the cursor is in a fold
"
" I always like to type 'l' to open the fold which the cursor is in, but if the
" cursor is on the end of line, it won't open the fold, because the cursor
" doesn't move (see |'foldopen'| for hor). I remap 'l' so it will open the fold
" anyway.
if maparg('l', 'n') =~ "MotionCmd('l')"
  function! s:MoveRight() "{{{
    call s:MotionCmd('l')
    return (foldclosed(line('.')) != -1) ? 'zol' : 'l'
  endfunction
  "}}}
else
  function! s:MoveRight() "{{{
    return (foldclosed(line('.')) != -1) ? 'zol' : 'l'
  endfunction
  "}}}
endif
nnoremap <silent> <expr> l <SID>MoveRight()

" Map: <Leader>*
nnoremap <Leader>t8 :<C-U>set ts=8 sw=8<CR>
nnoremap <Leader>t4 :<C-U>set ts=4 sw=4<CR>
nnoremap <Leader>t2 :<C-U>set ts=2 sw=2<CR>

nnoremap <silent> <Leader>rd :<C-U>redraw!<CR>

nnoremap <silent> <Leader>V  0v$

nnoremap <silent> <Leader>'  :<C-U>exec 'cc' (v:count == 0 ? '' : v:count)<CR>
nnoremap <silent> <Leader>,  :<C-U>exec v:count1 . 'cN'<CR>
nnoremap <silent> <Leader>.  :<C-U>exec v:count1 . 'cn'<CR>

nnoremap <silent> <Leader>[   :<C-U>exec v:count1 . 'tN'<CR>
nnoremap <silent> <Leader>]   :<C-U>exec v:count1 . 'tn'<CR>
nnoremap <silent> <Leader>tj  :<C-U>tj<CR>

nnoremap <silent> <Leader>cw :<C-U>exec 'cwindow' (v:count ? v:count : '')<CR>
nnoremap <silent> <Leader>co :<C-U>exec 'copen'   (v:count ? v:count : '')<CR>
nnoremap <silent> <Leader>cc :<C-U>cclose<CR>

nnoremap <silent> <Leader>lw :<C-U>exec 'lwindow' (v:count ? v:count : '')<CR>
nnoremap <silent> <Leader>lo :<C-U>exec 'lopen'   (v:count ? v:count : '')<CR>
nnoremap <silent> <Leader>lc :<C-U>lclose<CR>

" Join lines in comment, otherwise works just like 'J'
nnoremap <silent> <Leader>jj :<C-U>call <SID>JoinLines(v:count1)<CR>
function! s:JoinLines(cnt) "{{{
  let cnt = a:cnt <= 0 ? 1 : a:cnt
  if !has('syntax_items')
        \ || synIDattr(synID(line('.'), col('.'), 0), 'name') !~? 'string\|comment'
    exec 'normal! ' . cnt . 'J'
    return
  endif

  let sav_opt = [&l:fo, &l:tw]

  try
    " http://en.wikipedia.org/wiki/Limits.h
    " INT_MAX -> 2147483647
    let &l:tw = 2147483647
    setlocal fo+=q

    let line = getline('.')
    exec 'normal! gw' . cnt . 'j'
    if line != getline('.')
      call cursor(line('.'), strlen(line) + 1)
    endif
  finally
    let [&l:fo, &l:tw] = sav_opt
  endtry
endfunction
"}}}

" Toggle options
nnoremap <silent> <Leader>et :<C-U>set et!     <Bar>set et?<CR>
nnoremap <silent> <Leader>pa :<C-U>set paste!  <Bar>set paste?<CR>
nnoremap <silent> <Leader>hl :<C-U>set hls!    <Bar>set hls?<CR>
nnoremap <silent> <Leader>wp :<C-U>set wrap!   <Bar>set wrap?<CR>
nnoremap <silent> <Leader>nu :<C-U>set nu!     <Bar>set nu?<CR>
nnoremap <silent> <Leader>ba :<C-U>set backup! <Bar>set backup?<CR>
nnoremap <silent> <Leader>lt :<C-U>set list!   <Bar>set list?<CR>
nnoremap <silent> <Leader>ssl :<C-U>set ssl!   <Bar>set ssl?<CR>

nnoremap <silent> <Leader>a<Space> :<C-U>call <SID>AddChar('<Leader>a<Space>', ' ', v:count1)<CR>
function! s:AddChar(map, ch, cnt) "{{{
  if a:cnt <= 0 || strlen(a:ch) > 1 || a:ch !~ '\p'
    return
  endif
  let sav_a = @a
  let @a = repeat(a:ch, a:cnt)
  normal! "agP
  let @a = sav_a
  silent! call repeat#set(a:map, a:cnt)
endfunction
"}}}
inoremap <silent> <Leader>tif <C-R>=strftime('%Y/%m/%dT%H:%M')<CR>
inoremap <silent> <Leader>tid <C-R>=strftime('%Y/%m/%d')<CR>
inoremap <silent> <Leader><BS><BS> <C-G>u<C-O>0<C-O>"_D<BS>

" Maximize window
nnoremap <silent> <Leader>x :<C-U>call <SID>MaximizeWindow(v:count)<CR>
command! DoMaximizeWindow call <SID>DoMaximizeWindow(1)
command! NoMaximizeWindow call <SID>DoMaximizeWindow(0)

let g:maxmize_window_type = 0
function! s:DoMaximizeWindow(start) "{{{
  if a:start
    call <SID>MaximizeWindow()
    augroup MaximizeWindow
      au!
      au WinEnter * call <SID>MaximizeWindow()
    augroup END
  else
    augroup MaximizeWindow
      au!
    augroup END
  endif
endfunction
"}}}
function! s:MaximizeWindow(...) "{{{
  if winnr('$') == 1
    return
  endif

  if a:0
    let type = a:1
  else
    if exists('g:maxmize_window_type')
      let type = g:maxmize_window_type
    else
      let type = 0
    endif
  endif

  if type == 0
    exec "normal! \<C-W>_"
  elseif type == 1
    exec "normal! \<C-W>|"
  else
    exec "normal! \<C-W>_\<C-W>|"
  endif
endfunction
"}}}

" Escaping Emacs key bindings
" <id=EscapingEmacsKeyBindings>
inoremap <Leader><C-A> <C-A>
inoremap <Leader><C-E> <C-E>
inoremap <Leader><C-K> <C-K>

cnoremap <Leader><C-A> <C-A>

" Map: <M-*>
nnoremap <M-q> gqap

" Shortcut to moving to buffer/tabpage 1 to 9: <M-#> -> :b#
function! <SID>SelectBufOrTab(nr) "{{{
  if tabpagenr('$') > 1
    exec "tabnext" a:nr
  else
    exec "buffer" a:nr
  endif
endfunction
"}}}

for s:i in range(1, 9)
  exe 'nnoremap <silent> <M-'. s:i . '>  :<C-U>call <SID>SelectBufOrTab(' . s:i . ')<CR>'
endfor
unlet! s:i

" Some normal commands in insert mode
let s:normal_key = 'uohlwebdf'
for s:key in split(s:normal_key, '\s*')
  exe printf('inoremap <silent> <M-%s> <C-\><C-O>%s', s:key, s:key)
endfor
unlet! s:key s:normal_key

inoremap <silent> <M-j> <C-\><C-O>gj
inoremap <silent> <M-k> <C-\><C-O>gk

" For ult.vim |utl_usr.txt|
if globpath(&rtp, 'plugin/utl.vim') != ''
  nmap <silent> <M-g> <Leader>gu
  vmap <silent> <M-g> <Leader>gu
endif

if g:MSWIN
  nnoremap <silent> <M-x>     :<C-U>simalt ~x<CR>
  nnoremap <silent> <M-n>     :<C-U>simalt ~n<CR>
  nnoremap <silent> <M-r>     :<C-U>simalt ~r<CR>
  nnoremap <silent> <M-Space> :<C-U>simalt ~<CR>
endif

" http://tech.groups.yahoo.com/group/vimdev/message/51320
cnoremap <M-w> <C-\>e RemoveLastPathComponent()<CR>
function! RemoveLastPathComponent() "{{{
  return substitute(getcmdline(), '\%(\\ \|[\\/]\@!\f\)\+[\\/]\=$\|.$', '', '')
endfunction
"}}}
cnoremap <M-i> <C-\>e <SID>InsertLastSearchPattern()<CR>
function! <SID>InsertLastSearchPattern() "{{{
  let cmd = getcmdline()
  let pos = getcmdpos()
  let pattern = substitute(getreg('/'),'^\\<\|\\>$','','g')
  if pos == 1
    let cmd = pattern . cmd
  elseif strlen(cmd) + 1 == pos
    let cmd = cmd . pattern
  else
    let cmd = cmd[0 : pos-2] . pattern . cmd[pos-1 : ]
  endif

  call setcmdpos(pos + strlen(pattern))
  return cmd
endfunc
"}}}

" Map: <C-*>
" Navigate between windows
augroup Vimrc
  autocmd VimEnter * nnoremap <silent> <C-J> :<C-U>call <SID>MoveToWindow('j', v:count1)<CR>
  autocmd VimEnter * nnoremap <silent> <C-K> :<C-U>call <SID>MoveToWindow('k', v:count1)<CR>
  autocmd VimEnter * nnoremap <silent> <C-H> :<C-U>call <SID>MoveToWindow('h', v:count1)<CR>
  autocmd VimEnter * nnoremap <silent> <C-L> :<C-U>call <SID>MoveToWindow('l', v:count1)<CR>
augroup END

function! s:MoveToWindow(motion, cnt) "{{{
  let opposite = { 'j': 'k' , 'k': 'j', 'h': 'l', 'l': 'h' }
  let tabpage  = { 'l': 'gt', 'h': 'gT' }

  if !has_key(opposite, a:motion)
    return
  endif

  let cnt = a:cnt
  while cnt > 0
    let curwin = winnr()

    exec 'wincmd' a:motion
    if curwin == winnr()
      if has_key(tabpage, a:motion) && tabpagenr('$') > 1
        exec 'normal!' tabpage[a:motion]
      endif

      exec winnr('$') 'wincmd' opposite[a:motion]
    endif

    let cnt -= 1
  endwhile
endfunction
"}}}

" Move between tabpages
nnoremap <silent> <C-Right> gt
nnoremap <silent> <C-Left>  gT

" Open new line in insert mode
inoremap <silent> <C-J> <C-\><C-O>o

" Move to the end of the line
inoremap <silent> <C-L> <C-\><C-O>$

" Use CTRL-Q to do what CTRL-V used to do
noremap <C-Q> <C-V>

inoremap <Leader><C-^> <C-\><C-O>:call <SID>MoveBetweenBraces()<CR>

function! s:PosCmp(pos1, pos2) "{{{
  if a:pos1 == a:pos2
    return 0
  endif

  if (a:pos1[0] > a:pos2[0] || (a:pos1[0] == a:pos2[0] && a:pos1[1] > a:pos2[1]))
    return 1
  endif

  return -1
endfunction
"}}}
function! s:MoveBetweenBraces() "{{{
  let cur_pos = [line('.'), col('.')]

  let next_pos = [line('$'), col('$')]
  let prev_pos = cur_pos

  for [left, right] in [['{', '}'], ['\[', '\]'], ['(', ')']]
    let pos = searchpos('\%(' . left .'\)\@<=[ \r\n\t]*' . right, 'wn')
    if s:PosCmp(pos, cur_pos) > 0 && s:PosCmp(pos, next_pos) < 0
      let next_pos = pos
    elseif s:PosCmp(pos, cur_pos) < 0 && s:PosCmp(pos, prev_pos) < 0
      let prev_pos = pos
    endif
  endfor

  if next_pos != [line('$'), col('$')]
    call cursor(next_pos)
    return
  endif

  if prev_pos != cur_pos
    call cursor(prev_pos)
    return
  endif
endfunction
"}}}

" Emacs style key bindings
" Precede mapped key with <Leader> to use original command <#r=EscapingEmacsKeyBindings>
inoremap <C-A> <C-\><C-O>^
inoremap <C-E> <End>
inoremap <C-K> <C-\><C-O>D
cnoremap <C-A> <Home>

" CTRL-Z is Undo; not in cmdline though
" ($VIMRUNTIME/mswin.vim)
noremap  <C-Z> u
inoremap <C-Z> <C-\><C-O>u

" Map: <F*>
" Quick save & quit <id=Save> <id=Quit>
noremap  <silent> <F2> :<C-U>up<CR>
imap     <silent> <F2> <C-\><C-O><F2>
noremap  <silent> <F4> :<C-U>q<CR>
imap     <silent> <F4> <C-\><C-O><F4>

" Quick save all & quit all
noremap  <silent> <S-F2> :<C-U>wa<CR>
imap     <silent> <S-F2> <C-\><C-O><S-F2>
noremap  <silent> <S-F4> :<C-U>qa<CR>
imap     <silent> <S-F4> <C-\><C-O><S-F4>

" Wipe out the highlight of the matching strings. <id=Search>
nnoremap <silent> <F11> :<C-U>let @/ = ''<CR>
imap <silent> <F11> <C-\><C-O><F11>

" Toggle Spellcheck <id=Spell>
noremap  <silent> <F12> :<C-U>setlocal spell! spelllang=en_us<Bar>setlocal spell?<CR>
imap <silent> <F12> <C-\><C-O><F12>

" Map: Others
" Don't use Ex mode, use Q for formatting
" use 'Q' for formatting (from $VIMRUNTIME/vimrc_example.vim)
nnoremap Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
" (from $VIMRUNTIME/vimrc_example.vim)
inoremap <C-U> <C-G>u<C-U>

" Insert new-line after or before the current line
" without entering the insert mode.
nnoremap <silent> <expr> <CR> <SID>Enter()

" Some special buffer use <CR> for special usage.
" e.g. quickfix
function! s:Enter() "{{{
  " Open a new line without changing '', '. and '^ marks,
  " so some commands such as 'gi' will work as usual.
  return &ma ? ":keepjumps normal o\<CR>" : "\<CR>"
endfunction
"}}}

nnoremap <silent> <S-CR> O<ESC>

" When adding the new line, don't insert the current comment leader.
nnoremap <silent> go o<ESC>"_S
nnoremap <silent> gO O<ESC>"_S
inoremap <silent> <Leader>go <ESC>:call append('.', matchstr(getline('.'), '^\s*'))<CR>jA

nnoremap <silent> <Leader>go o<ESC>"_S<ESC>
nnoremap <silent> <Leader>gO O<ESC>"_S<ESC>

" nnoremap <PageDown> <C-]>
" nnoremap <PageUp>   <C-T>

" Map arrow keys to display line movements
nnoremap <silent> <Up>   gk
nnoremap <silent> <Down> gj
imap     <silent> <Up>   <C-\><C-O><Up>
imap     <silent> <Down> <C-\><C-O><Down>

nnoremap <silent> gK     :<C-U>exec 'help '.expand('<cword>')<CR>
nnoremap <silent> <Leader>tn :<C-U>tabnew<CR>
nnoremap <silent> <Leader>tc :<C-U>tabclose<CR>

" backspace in Visual mode deletes selection
vnoremap <BS> d

" matchit.vim maps % in select mode, which leads to wrong behavior.
augroup Vimrc
  autocmd VimEnter * silent! sunmap %
augroup END

" Indent All (<S-=>)
" nnoremap <silent> + ggVG=

" http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock
set imsearch=-1
set keymap=capslock
set iminsert=0

"--------------------------------------------------------------
" Buffer/Tabpage-related Functions
"--------------------------------------------------------------
" Move to the next or previous modifiable buffer. <id=MoveToBuf>
nnoremap <silent> gb        :<C-U>call <SID>MoveToBuf(1, v:count)<CR>
nnoremap <silent> gB        :<C-U>call <SID>MoveToBuf(0, v:count)<CR>
nnoremap <silent> <M-Right> :<C-U>call <SID>MoveToBuf(1)<CR>
nnoremap <silent> <M-Left>  :<C-U>call <SID>MoveToBuf(0)<CR>

nnoremap <silent> <M-l>     :<C-U>call <SID>MoveToBufOrTab(1)<CR>
nnoremap <silent> <M-h>     :<C-U>call <SID>MoveToBufOrTab(0)<CR>

nnoremap <silent> g6        :<C-U>call <SID>MoveToPrevTab()<CR>

augroup Vimrc
  autocmd TabLeave * silent! let g:prev_tabpage = tabpagenr()
augroup END

function! <SID>MoveToPrevTab() "{{{
  if exists('g:prev_tabpage')
    exec "tabnext" g:prev_tabpage
  endif
endfunction
"}}}
function! <SID>MoveToBuf(forward, ...) "{{{
  if a:0 > 0 && a:1 > 0
    exec 'buffer' a:1
    return
  endif

  let cmd = a:forward == 1 ? 'bnext' : 'bprevious'
  exe cmd
  let bufnum = bufnr('$')
  let i = 0
  while i < bufnum && &modifiable == 0
    exe cmd
    let i += 1
  endwhile
endfunction
"}}}
function! <SID>MoveToBufOrTab(forward) "{{{
  if tabpagenr('$') > 1
    let cmd = a:forward == 1 ? 'tabnext' : 'tabprevious'
    exe cmd
  else
    call <SID>MoveToBuf(a:forward)
  endif
endfunction
"}}}
"--------------------------------------------------------------
" The usage of cscope
"--------------------------------------------------------------
if has('cscope')
  command! -nargs=+ CFind cs find <args>

  nnoremap <Leader>cf :<C-U>cs find 
  inoremap <Leader>cf <C-C>:<C-U>cs find 

  set csprg=cscope\ -C
  set csto=0
  " set cst
  set nocsverb

  " use quickfix window
  set csqf=s-,c-,d-,i-,t-,e-,g-

  " add any database in current directory
  if filereadable('cscope.out')
      silent! cs add cscope.out
  " else add database pointed to by environment
  elseif $CSCOPE_DB != '' && filereadable($CSCOPE_DB)
      silent! cs add $CSCOPE_DB
  endif
  set csverb

  nmap <C-_>s :<C-U>cs find s <C-R>=expand('<cword>')<CR><CR>
  nmap <C-_>g :<C-U>cs find g <C-R>=expand('<cword>')<CR><CR>
  nmap <C-_>c :<C-U>cs find c <C-R>=expand('<cword>')<CR><CR>
  nmap <C-_>t :<C-U>cs find t <C-R>=tolower(expand('<cword>'))<CR><CR>
  nmap <C-_>e :<C-U>cs find e <C-R>=expand('<cword>')<CR><CR>
  nmap <C-_>f :<C-U>cs find f <C-R>=expand('<cfile>')<CR><CR>
  nmap <C-_>i :<C-U>cs find i ^<C-R>=expand('<cfile>')<CR>$<CR>
  nmap <C-_>d :<C-U>cs find d <C-R>=expand('<cword>')<CR><CR>

  " Using 'CTRL-\' then a search type makes the vim window
  " split horizontally, with search result displayed in
  " the new window.

  nmap <C-\>s :<C-U>scs find s <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\>g :<C-U>scs find g <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\>c :<C-U>scs find c <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\>t :<C-U>scs find t <C-R>=tolower(expand('<cword>'))<CR><CR>
  nmap <C-\>e :<C-U>scs find e <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\>f :<C-U>scs find f <C-R>=expand('<cfile>')<CR><CR>
  nmap <C-\>i :<C-U>scs find i ^<C-R>=expand('<cfile>')<CR>$<CR>
  nmap <C-\>d :<C-U>scs find d <C-R>=expand('<cword>')<CR><CR>

  " Hitting 'CTRL-\' *twice* before the search type does a vertical
  " split instead of a horizontal one

  nmap <C-\><C-\>s :<C-U>vert scs find s <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\><C-\>g :<C-U>vert scs find g <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\><C-\>c :<C-U>vert scs find c <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\><C-\>t :<C-U>vert scs find t <C-R>=tolower(expand('<cword>'))<CR><CR>
  nmap <C-\><C-\>e :<C-U>vert scs find e <C-R>=expand('<cword>')<CR><CR>
  nmap <C-\><C-\>i :<C-U>vert scs find i ^<C-R>=expand('<cfile>')<CR>$<CR>
  nmap <C-\><C-\>d :<C-U>vert scs find d <C-R>=expand('<cword>')<CR><CR>
endif

" vim: fdm=marker : ts=2 : sw=2 :
