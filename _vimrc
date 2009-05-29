" .vimrc
"
" Author:        Frank Chang <frank.nevermind AT gmail.com>
" Last Modified: 2009-05-29 20:33:16
"
" Prerequisite:  Vim >= 7.0
"
" Some definitions of the functions and key mappings are modified from
" others' scripts. Many thanks to them!
"
" Reference:
"   - $VIMRUNTIME/vimrc_example.vim
"   - $VIMRUNTIME/gvimrc_example.vim
"   - $VIMRUNTIME/mswin.vim
"   - http://macromates.com/svn/Bundles/trunk/Bundles/
"   - http://mysite.verizon.net/astronaut/vim/index.html
"   - http://www.tpope.us/cgi-bin/cvsweb/tpope/.vimrc
"
"   - $VIMRUNTIME/mswin.vim
"   - $VIMRUNTIME/gvimrc_example.vim
"
set nocompatible
"============================================================{{{1
" Global, Script, and Environment Variables
"================================================================
" g:USER_INFO {{{
let g:USER_INFO = {
      \   'name' : 'Frank Chang',
      \   'ref'  : 'FC',
      \   'email': 'frank.nevermind AT gmail.com',
      \ }
"}}}
" s:MSWIN {{{
let s:MSWIN = has('win32') || has('win32unix') || has('win64')
          \ || has('win95') || has('win16')
"}}}
" s:RUNTIME_DIR {{{
let s:RUNTIME_DIR = s:MSWIN ? ($VIM  . '/vimfiles') : ($HOME . '/.vim')
let $MYVIMRUNTIME = s:RUNTIME_DIR
let $V = s:RUNTIME_DIR
"}}}
" Environment Variables {{{
function! s:SetEnv() 
  function! s:GetPath(dirs, sep, ...) "{{{
    let path_list = []
    for dir in a:dirs
      let path = globpath(&rtp, dir)
      if path != ''
        call extend(path_list, split(path, '\n'))
      endif
    endfor
    if a:0 > 0 && a:1 != ''
      call map(path_list, 'call(a:1, [v:val])')
    endif
    return join(path_list, a:sep)
  endfunction
  "}}}
  function! s:Cygpath(path) "{{{
    let path = tr(a:path, '\', '/')
    let path = substitute(path, '^\([a-zA-Z]\):', '/cygdrive/\u\1', '')
    return path
  endfunction
  "}}}
  " $PATH {{{
  let sep = s:MSWIN ? ';' : ':'
  let path = s:GetPath(['bin', (s:MSWIN ? 'bin/win' : 'bin/linux')], sep)
  if path != ''
    let $PATH = path . ($PATH == '' ? '' : (sep . $PATH))
  endif
  "}}}
  " $RUBYLIB {{{
  let cyg_ruby = 1
  " if s:MSWIN
  "   let ruby_path = globpath(tr($PATH, ';', ','), 'ruby.exe')
  "   if ruby_path != ''
  "     let ruby_path = split(ruby_path, '\n')[0]
  "   endif
  "   if ruby_path =~ '\<cygwin[/\\]bin\>'
  "     let cyg_ruby = 1
  "   endif
  " endif

  let sep = (s:MSWIN && !cyg_ruby) ? ';' : ':'
  let path = s:GetPath(['lib/ruby'], sep, (cyg_ruby ? 's:Cygpath' : ''))
  if path != ''
    let $RUBYLIB = path . ($RUBYLIB == '' ? '' : (sep . $RUBYLIB))
  endif
  "}}}
  " $PYTHONPATH {{{
  let path = s:GetPath(['lib/python'], sep)
  if path != ''
    let $PYTHONPATH = path . ($PYTHONPATH == '' ? '' : (sep . $PYTHONPATH))
  endif
  "}}}
  " $PERL5LIB {{{
  let cyg_perl = 1
  let sep = (s:MSWIN && !cyg_perl) ? ';' : ':'
  let path = s:GetPath(['lib/perl'], sep, (cyg_perl ? 's:Cygpath' : ''))
  if path != ''
    let $PERL5LIB = path . ($PERL5LIB == '' ? '' : (sep . $PERL5LIB))
  endif
  "}}}
  delfunction s:GetPath
  delfunction s:Cygpath
endfunction

call s:SetEnv()
delfunction s:SetEnv
"}}}
"}}}1
"============================================================{{{1
" Remove ALL autocommands in group Vimrc.
"================================================================
augroup Vimrc
  au!
augroup END
"}}}1
"============================================================{{{1
" Settings
"================================================================
" let did_install_default_menus = 1
let did_install_syntax_menu = 1
let no_buffers_menu = 1

let s:do_resize_window = 1

if &term == 'screen'
  set term=xterm
  let s:do_resize_window = 0
endif

" Encoding {{{
set encoding=utf-8
if has('win32') || &term == 'cygwin'
  set fileformats=unix,dos
  if !has('gui_win32')
    set termencoding=cp950
    set encoding=cp950
    set fileencoding=utf-8
  endif
else
  language zh_TW.UTF-8
endif
language messages C
language time C
set fileencodings=ucs-bom,utf-8,big5,latin1
"}}}
" Size of the Vim window {{{
if s:do_resize_window
  let s:default_size = [42, 120]

  if &lines < s:default_size[0]
    let &lines = s:default_size[0]
  endif

  if &columns < s:default_size[1]
    let &columns = s:default_size[1]
  endif

  unlet s:default_size
endif
unlet s:do_resize_window
"}}}
" 'backup' settings {{{
set backup
set backupext=~
let s:backupdir = exists('g:backupdir') ? g:backupdir : ($HOME . '/.backup/vim')
if filewritable(s:backupdir) == 2
  let &backupdir = s:backupdir
endif
unlet s:backupdir
"}}}

" Enable file type detection.
filetype plugin indent on

" set guioptions-=m         " Exclude Menu bar.
set guioptions-=M         " Do NOT source system menu
set guioptions-=T         " Exclude Toolbar.
set guioptions-=e         " Non-GUI tab pages
set shortmess+=I          " Don't give the intro message when starting Vim
set formatoptions=tcroqnB " See |fo-table|
set ambiwidth=double      " Handle the width of the CJK font
set backspace=2           " Allow backspacing over everything in insert mode
set ruler                 " Show the cursor position all the time
set showcmd               " Display incomplete commands
set incsearch             " Do incremental searching
set number
set history=100
set cino=>s,e0,n0,f0,{0,}0,^0,:s,=s,l1,b0,g0,hs,ps,t0,is,+s,c3,C0,/0,(2s,us,U0,w0,W0,m0,j0,)20,*30
set matchpairs=(:),{:},[:],<:>
set whichwrap+=<,>,[,]
set updatetime=2500
set selection=exclusive
set listchars=eol:$,tab:>-,trail:-,precedes:<,extends:>,nbsp:%
set winaltkeys=no
set complete+=k
set laststatus=2
set pumheight=20
set winminheight=0
set scrolloff=1
set sidescroll=1
set showbreak=>
set diffopt+=vertical
set display=lastline

" If you run VIM in GNU SCREEN, be sure to set timeout set by the SCREEN 
" command 'maptimeout' smaller then the option 'ttimeoutlen', otherwise the
" key code will be recognized within the time set by 'maptimeout', not
" 'ttimeoutlen'.
set timeout timeoutlen=1000 ttimeoutlen=30

" Automatically reread the file which is changed outside of Vim
set autoread

" A buffer becomes hidden when it is abandoned when I edit multiple files at
" the same time, I may move to other buffer without saving the original file,
" then I can redo the operation when I come back to this file.
set hidden

" Convert <Tab> to 4 real spaces
set tabstop=4
set shiftwidth=4
set expandtab

" Round indent to multiple of 'shiftwidth'
set shiftround

if s:MSWIN
  set keywordprg=man
endif

if !has('gui_running')
  set mouse=a
endif

" Use menu in console mode |console-menus| {{{
if !exists("did_install_default_menus")
  so $VIMRUNTIME/menu.vim
endif
set wildmenu
set cpo-=<
set wcm=<C-Z>
map <F10> :<C-U>emenu <C-Z>
"}}}

" I want to load 'Highlighting matching parens' plugin but would disable
" it first until i need it.
" augroup Vimrc
"   autocmd VimEnter * NoMatchParen
" augroup END

" Set Doxygen syntax highlighting when editing C, CPP, or IDL file.
let g:load_doxygen_syntax = 1

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" Also don't do it when the mark is in the first line, that is the default
" position when opening a file. ($VIMRUNTIME/vimrc_example.vim)
augroup Vimrc
  autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   exe "normal! g`\"" |
        \ endif
augroup END

" Set 'statusline' & 'titlestring' {{{
command! -bar -bang TitleShowLoginInfo let g:title_show_login_info = <q-bang> != '!'
let g:title_show_login_info = s:MSWIN ? 0 : 1
function! s:GetLoginInfo() "{{{
  let user = s:MSWIN ? $USERNAME : $USER
  let hostname = hostname()
  if hostname =~ '^localhost\>'
    let hostname = 'localhost'
  endif
  return user.'@'.hostname
endfunction
"}}}
function! s:GetCwd() "{{{
  " let cwd = expand('%:p:~:h')
  let cwd = substitute(getcwd(), '^\V' . escape(expand('~'), '\'), '~', '')
  if strlen(cwd) > max([30, &columns/4])
    if exists('*pathshorten')
      let cwd = pathshorten(cwd)
    else
      let cwd = substitute(cwd, '\([~.]*[^:/]\)\%([^:/]\)*/', '\1/', 'g')
    endif
  endif
  return cwd
endfunction
"}}}
function! s:OptTabInfo() "{{{
  return printf('%s:%d:%d%s', (&et?'spaces':'tabs'), &sw, &ts, (&sts?':'.&sts:''))
endfunction
"}}}
function! OptInfo() "{{{
  let info  = g:title_show_login_info ? (s:GetLoginInfo().':') : ''
  let info .= s:GetCwd()
  return '['.info.']'
endfunction
"}}}
function! OptModifiedFlag(type) "{{{
  if a:type == 0  " title
    if !&ma
      return '-'
    endif
    return (&ro ? '=' : '') . (&mod && &bt != 'nowrite' && &bt != 'nofile' ? '+' : '')
  else " statusline
    return &mod && &bt != 'nowrite' && &bt != 'nofile' ? '[+]' : ''
  endif
  return ''
endfunction
"}}}
function! OptSetInfo() "{{{
  let info = [s:OptTabInfo()]
  for opt in ['spell', 'paste']
    let val = eval('&'.opt)
    if type(val) == type(0) && val == 1
      call add(info, opt)
    endif
  endfor

  for opt in ['wrap', 'hls', 'backup']
    let val = eval('&'.opt)
    if type(val) == type(0) && val == 0
      call add(info, 'no'.opt)
    endif
  endfor

  return '('.join(info, ',').')'
endfunction
"}}}
" Used by Man.vim (My works)
function! ManBufInfo() "{{{
  if exists('b:man_buf_info') && !empty(b:man_buf_info)
    return '[' . (type(b:man_buf_info) == type('') ? b:man_buf_info : string(b:man_buf_info)) . ']'
  else
    return ''
  endif
endfunction
"}}}
set title
if !s:MSWIN
  let &titleold  = s:GetLoginInfo().':'.expand('%:p:~:h')
endif
let &titlestring = '%t%( %{OptModifiedFlag(0)}%)%( %{OptInfo()}%h%)'
if has('clientserver')
  let &titlestring .= '%( - %{v:servername}%)'
endif

" let &statusline = '%<%f%( %{OptModifiedFlag(1)}%y%w%r%)%=%-16.( %l/%L,%c%V%) '
let &statusline = '%<%f%( %{OptModifiedFlag(1)}%{ManBufInfo()}%y%w%r%)'
      \ . '%( %{OptSetInfo()}%) %=%-14.( %l/%L,%c%V%) '
"}}}
" Make <M-...> almost work in xterm {{{
" 
" In xterm, the key code of '<A-j>' is '<ESC>j', but if you map '<ESC>j'
" directly, then Vim needs to wait 'timeoutlen' milliseconds for the following
" keys after you type '<ESC>' to recognize the possible key mappings.
"
" Furthermore, if you accidentally type '<ESC>j' too fast (within 'timeoutlen'
" milliseconds), Vim still treats '<ESC>j' as a key mapping but not two
" independent keys, and execute the defined mapping command. It may be not what
" you want.
"
" That's why we need to set key code directly |term.txt|, and set 'ttimeoutlen'
" to a small number, which is the time that Vim recognizes the key code (not
" key mapping). Please refer to Vim Tip 1272 (Ref) for details.
"
" We cannot set <A-...> directly to <ESC>... (e.g. set <A-j>=j)
" See Ref Troubleshooting 3a.
"
" Ref: Vim Tip 1272: http://vim.wikia.com/wiki/VimTip1272 
if !has('gui_running') && &term == 'xterm'
  function! s:Keycodes_Setup() "{{{
    let keycodes = map(range(13, 37), '"<F" . v:val . ">"')
    call extend(keycodes, map(range(13, 37), '"<S-F" . v:val . ">"'))

    " There are not enough unused key codes to be assigned to all alt-keys
    " Only (37 - 13 + 1) * 2 = 50 key codes can be assigned.
    let altkeys = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    let i = 0
    let altkeys_len = strlen(altkeys)
    for code in keycodes
      if i >= altkeys_len
        break
      endif
      let ch = altkeys[i]
      exec  'set ' . code . '='  . ch
      exec  'map ' . code . ' <M-' . ch . '>'
      exec 'imap ' . code . ' <M-' . ch . '>'
      exec 'cmap ' . code . ' <M-' . ch . '>'
      let i += 1
    endfor
  endfunction
  "}}}
  call s:Keycodes_Setup()
  delfunction s:Keycodes_Setup
endif
"}}}
" Settings for GVIM {{{

" Switch syntax highlighting on, when the terminal has colors.
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has('gui_running')
  if !exists('syntax_on')
    syntax on
  endif
  set hlsearch
  set background=dark
endif

if has('gui_running')
  for s:color in [
        \          ['wombat2'],
        \          ['oceandeep2'],
        \          ['dusk'],
        \          ['desertedocean'],
        \          ['moria', 'let moria_style = "dark"'],
        \          ['desert'],
        \        ]
    if globpath(&rtp, 'colors/' . s:color[0] . '.vim') != ''
      for s:setting in s:color[1 : -1]
        exec s:setting
      endfor
      unlet! s:setting
      exec 'colors ' . s:color[0]
      break
    endif
  endfor
  unlet! s:color
  if has('gui_win32')
    silent! set guifont=Consolas:h9:w5,courier_new:h10:w6
    " silent! set guifont=Monaco:h7.5:w5,courier_new:h10:w6
  else
    silent! set guifont=Consolas\ 12,Courier\ 10\ Pitch\ 12
  endif
elseif &t_Co > 2
  if &t_Co < 16
    set t_Co=16
  endif
  " Changed the colors of grounps Pmenu and PmenuSel
  silent! colors default2
  set bg=dark
  augroup Vimrc
    au VimLeave * hi clear
  augroup END
endif
"}}}
"}}}1
"============================================================{{{1
" Keymappings and Commands
"================================================================
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
" *Special Note* {{{
"
" I use SharpKeys <http://www.randyrants.com/2006/07/sharpkeys_211.html> in
" MS Windows to make following keys on a keyboard act like other keys to speed
" up typing:
"
"   [ ] Caps Lock     -> Escape     (<ESC>)
"   [v] Caps Lock     -> Left Ctrl  (<C-...>)
"   [ ] Left Shift    -> Escape     (<ESC>)
"   [ ] Left Windows  -> Left Shift (<S-...>)
"
"   [v] Right Windows -> Left Alt   (<M-...>)
"        Since the Right Alt key doesn't work in putty, I use Right Windows key 
"        to act like Left Alt key instead.
"
" }}}
" Map: Motion Commands {{{
"
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

" Open fold and move to right when the cursor is in a fold {{{
"
" I always like to type 'l' to open the fold which the cursor is in, but if the
" cursor is on the end of line, it won't open the fold, because the cursor
" doesn't move (see |'foldopen'| for hor). I remap 'l' so it will open the fold
" anyway.
if maparg('l', 'n') =~ "MotionCmd('l')"
  function! s:MoveRight()
    call s:MotionCmd('l')
    return (foldclosed(line('.')) != -1) ? 'zol' : 'l'
  endfunction
else
  function! s:MoveRight()
    return (foldclosed(line('.')) != -1) ? 'zol' : 'l'
  endfunction
endif
nnoremap <silent> <expr> l <SID>MoveRight()
"}}}
"}}}
" Map: <Leader>* {{{
nnoremap <Leader>t8 :<C-U>set ts=8 sw=8<CR>
nnoremap <Leader>t4 :<C-U>set ts=4 sw=4<CR>
nnoremap <Leader>t2 :<C-U>set ts=2 sw=2<CR>

nnoremap <silent> <Leader>rd :<C-U>redraw!<CR>

nnoremap <silent> <Leader>V  0v$

nnoremap <silent> <Leader>/  :<C-U>exec 'cc' (v:count == 0 ? '' : v:count)<CR>
nnoremap <silent> <Leader>,  :<C-U>cN<CR>
nnoremap <silent> <Leader>.  :<C-U>cn<CR>

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

inoremap <silent> <Leader>tif <C-R>=strftime('%Y-%m-%d %H:%M:%S')<CR>
inoremap <silent> <Leader>tid <C-R>=strftime('%Y-%m-%d')<CR>
inoremap <silent> <Leader><BS><BS> <C-G>u<C-O>0<C-O>"_D<BS>

" Maximize window {{{
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
"}}}

" Escaping Emacs key bindings
" <id=EscapingEmacsKeyBindings>
inoremap <Leader><C-A> <C-A>
inoremap <Leader><C-E> <C-E>
inoremap <Leader><C-K> <C-K>

cnoremap <Leader><C-A> <C-A>
"}}}
" Map: <M-*> {{{
nnoremap <M-q> gqap

" Shortcut to moving to buffer 1 to 9: <M-#> -> :b#
for s:i in range(1, 9)
  exe 'nnoremap <silent> <M-'. s:i . '>  :<C-U>silent! ' . s:i . 'b<CR>'
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

if s:MSWIN
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
"}}}
" Map: <C-*> {{{
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

" For vimsh: pseudo-terminal emulator
if !empty(globpath(&rtp, 'vimsh/vimsh.vim'))
  nmap <C-W>e :<C-U>ru vimsh/vimsh.vim<CR>
endif

" Use CTRL-Q to do what CTRL-V used to do
noremap <C-Q> <C-V>

inoremap <C-^> <C-\><C-O>:call <SID>MoveBetweenBraces()<CR>

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
"}}}
" Map: <F*> {{{
" Quick save & quit <id=Save> <id=Quit>
map  <silent> <F2> :<C-U>up<Bar>call histdel(':', -1)<CR>
imap <silent> <F2> <C-\><C-O>:up<Bar>call histdel(':', -1)<CR>
map  <silent> <F4> :<C-U>q<CR>
imap <silent> <F4> <C-\><C-O>:q<CR>

" Quick save all & quit all
map  <silent> <S-F2> :<C-U>wa<CR>
imap <silent> <S-F2> <C-\><C-O>:wa<CR>
map  <silent> <S-F4> :<C-U>qa<CR>
imap <silent> <S-F4> <C-\><C-O>:qa<CR>

" Wipe out the highlight of the matching strings. <id=Search>
imap <silent> <F11> <C-\><C-O>:let @/ = ''<Bar>call histdel(':', -1)<CR>
nmap <silent> <F11> :<C-U>let @/ = ''<Bar>call histdel(':', -1)<CR>

" Toggle Spellcheck <id=Spell>
map  <silent> <F12> :<C-U>setlocal spell! spelllang=en_us<Bar>setlocal spell?<CR>
imap <silent> <F12> <C-\><C-O>:setlocal spell! spelllang=en_us<Bar>setlocal spell?<CR>

"}}}
" Map: Others {{{
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
function! s:Enter()
  " Open a new line without changing '', '. and '^ marks,
  " so some commands such as 'gi' will work as usual.
  return &ma ? ":keepjumps normal o\<CR>" : "\<CR>"
endfunction

nnoremap <silent> <S-CR> O<ESC>

" When adding the new line, don't insert the current comment leader.
nnoremap <silent> go o<ESC>"_S
nnoremap <silent> gO O<ESC>"_S
inoremap <silent> <Leader>go <ESC>:call append('.', matchstr(getline('.'), '^\s*'))<CR>jA

nnoremap <silent> <Leader>go o<ESC>"_S<ESC>
nnoremap <silent> <Leader>gO O<ESC>"_S<ESC>

nnoremap <PageDown> <C-]>
nnoremap <PageUp>   <C-T>

" Map arrow keys to display line movements
nnoremap <silent> <Up>   gk
nnoremap <silent> <Down> gj
inoremap <silent> <Up>   <C-\><C-O>gk
inoremap <silent> <Down> <C-\><C-O>gj

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
"}}}
" Commands {{{

" Wiki-related commands (rst)
let g:rst_wiki = 1
let g:WikiHomeDir = s:MSWIN ? 'E:/Wiki/Notes' : ($HOME . '/wiki')
command! -bang -nargs=? -complete=custom,s:ListWikiLinks Wiki call s:Wiki(<q-bang> == '!', <q-args>)
function! s:ListWikiLinks(A, L, P) "{{{
  if !exists('g:WikiHomeDir')
    return ''
  endif

  let links = split(globpath(g:WikiHomeDir, '*.rst'), "\n")
  if empty(links)
    return ''
  endif

  let pat = '^\V' . escape(g:WikiHomeDir, '\') . '\%(\[\\/]\)\?\|\.rst\$'
  echom pat
  call map(links, 'substitute(v:val, pat, "", "g")')
  return join(links, "\n")
endfunction
"}}}
function! s:Wiki(newtab, link) "{{{
  if a:link =~ '^[A-Za=z]:|^[\\/]'
    echohl ErrorMsg | echo 'Wiki: link cannot be fullpath' | echohl None
    return
  endif

  let link = simplify(g:WikiHomeDir . '/' . (empty(a:link) ? 'index' : a:link))
  if link !~ '\.rst$'
    let link .= '.rst'
  endif

  if isdirectory(link)
    echohl ErrorMsg | echo 'Wiki: link is directory' | echohl None
    return
  endif

  exec (a:newtab ? 'tabe' : 'e') fnameescape(link)
  exec 'lcd!' fnameescape(g:WikiHomeDir)
endfunction
"}}}

" Change working directory to the directory of current file
nnoremap <silent> <Leader>cd :<C-U>Cwd<CR>
command! -bang -bar Cwd exe (<q-bang> == '!' ? 'l' : '') . 'cd ' . expand('%:p:h')

command! -bang Q  q<bang>
command! -bang Qa qa<bang>

command! -nargs=* Set  set  <args>
command! -nargs=1 Setf setf <args>

exe 'command! UpdateDoc helptags ' . s:RUNTIME_DIR . '/doc'

command! -complete=buffer -nargs=? Tbuffer tab sb <args>
command! -nargs=? Tball tab sball <args>
command! CountWords %s/\i\+/&/gn<Bar>let @/=''
command! -bang ShowSyntaxName
      \ echo synIDattr(synID(line('.'), col('.'), (<q-bang> != '!' ? 0 : 1)), 'name')

if exists('*synstack')
  command! ShowSyntaxStack
        \ echo map(synstack(line('.'), col('.')), "synIDattr(v:val, 'name')")
endif

command! -nargs=* -complete=file Tedit tabedit <args>

" http://www.tpope.us/cgi-bin/cvsweb/tpope/.vimrc
command! -bar -nargs=* -bang -complete=file Rename 
      \ let v:errmsg = '' |
      \ saveas<bang> <args> |
      \ if v:errmsg == '' |
      \   call delete(expand('#')) |
      \   bw # |
      \ endif

command! -nargs=1 RFC call s:RFC(<q-args>)
function! s:RFC(number) "{{{
  if a:number !~ '^\d\+$'
    echohl ErrorMsg | echo 'RFC: invalid number' | echohl None
    return
  endif
  exec printf('e http://www.ietf.org/rfc/rfc%04d.txt', a:number)
endfunction
"}}}

if exists("*mkdir")
  command! -nargs=1 -bang Mkdir call mkdir(<q-args>, <q-bang> == '!' : 'p' ? '')
endif

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
endif

" Tools {{{
for s:script in [
      \          'Ar30',
      \          'ImageBrowser',
      \          'JpPronunciation',
      \          'AutoCorrect',
      \          'eclim',
      \          'ropevim',
      \ ]
  if globpath(&rtp, printf('macros/%s.vim', s:script)) != ''
    exec printf('command! Load%s ru macros/%s.vim', substitute(s:script, '^.', '\u&', ''), s:script)
  endif
endfor
unlet! s:script
"}}}

let s:PIM_Dir              = s:MSWIN   ? 'D:/Frank/' : '~/private/'
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
" Add-on functions (Most functions are moved to $MYVIMRUNTIME/plugin/myutils.vim)
"================================================================
  "----------------------------------------------------------{{{2
  " UpdateModifiedTime()
  "--------------------------------------------------------------
  let g:UpdateModifiedTime = 0
  augroup Vimrc
    au FileType    * let b:UpdateModifiedTime = 0
    au BufWritePre * call <SID>UpdateModifiedTime()
  augroup END
  command! InsertModifiedTime call <SID>InsertModifiedTime()
  command! UpdateModifiedTime call <SID>UpdateModifiedTime(1)

  let s:timeformat = '%Y-%m-%d %H:%M:%S'
  let s:modifiedLabel = ['Last Modified:', 'Last Change:']

  function! s:InsertModifiedTime() "{{{
    let modifiedLabel = ''
    if type(s:modifiedLabel) == type([]) && !empty(s:modifiedLabel)
      let modifiedLabel = s:modifiedLabel[0]
    else
      let modifiedLabel = s:modifiedLabel
    endif
    exe 'normal! i' . modifiedLabel . ' ' . strftime(s:timeformat, getftime(expand("%:p")))
  endfunction
  "}}}
  function! s:UpdateModifiedTime(...) "{{{
    let force = a:0 > 0 ? !empty(a:1) : 0

    if !force && !exists('b:UpdateModifiedTime')
      let b:UpdateModifiedTime = exists('g:UpdateModifiedTime') ? g:UpdateModifiedTime : 0
    endif

    if force || (&mod && b:UpdateModifiedTime)
      let modifiedLabel = ''
      if type(s:modifiedLabel) == type([]) && !empty(s:modifiedLabel)
        let modifiedLabel = '\%(' . join(s:modifiedLabel, '\|') . '\)'
      else
        let modifiedLabel = s:modifiedLabel
      endif

      let checklines = &modelines < 10 ? 10 : &modelines
      let modifiedLabel_pat = '\<\('.substitute(modifiedLabel,'\s\+','\\s\\+','g').'\s*\)'

      " Consider all '%x's to be numbers.
      let timeformat_pat = substitute(s:timeformat,   '%\w', '\\d\\+', 'g')
      let timeformat_pat = substitute(timeformat_pat, '\s\+', '\\s\\+', 'g')

      let pattern = modifiedLabel_pat . timeformat_pat
      let timestamp = escape(strftime(s:timeformat), '\&~')

      for i in [0, 1]  " forward and backward searching
        if i == 0
          if (2 * checklines) > line('$')
            let lnums = range(1, line('$'))
          else
            let lnums = range(1, checklines)
          endif
        else
          if (2 * checklines) > line('$')
            return
          else
            let lnums = range(line('$') - checklines + 1, line('$'))
          endif
        endif

        for lnum in lnums
          let col = match(getline(lnum), pattern) + 1
          if col == 0 | continue | endif

          " if has('syntax_items')
          "   let name = synIDattr(synID(lnum, col, 0), 'name')
          "   if name != '' && name !~? 'comment'
          "     continue
          "   endif
          " endif

          let line = getline(lnum)
          call setline(lnum, (col - 2 < 0 ? '' : line[: (col-2)])
                \ . substitute(line[(col-1) :], pattern, '\1' . timestamp, 'g'))
        endfor
      endfor
    endif
  endfunction
  "}}}
  "}}}2
  "----------------------------------------------------------{{{2
  " Buffer-related Functions
  "--------------------------------------------------------------
  " Move to the next or previous modifiable buffer. <id=MoveToBuf>
  nnoremap <silent> gb        :<C-U>call <SID>MoveToBuf(1, v:count)<CR>
  nnoremap <silent> gB        :<C-U>call <SID>MoveToBuf(0, v:count)<CR>
  nnoremap <silent> <M-Right> :<C-U>call <SID>MoveToBuf(1)<CR>
  nnoremap <silent> <M-Left>  :<C-U>call <SID>MoveToBuf(0)<CR>
  nnoremap <silent> <M-l>     :<C-U>call <SID>MoveToBuf(1)<CR>
  nnoremap <silent> <M-h>     :<C-U>call <SID>MoveToBuf(0)<CR>

  function! <SID>MoveToBuf(forward, ...) " {{{
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
  " }}}

  " Don't close window, when deleting a buffer
  " Ref: http://www.amix.dk/vim/vimrc.html
  command! -bang Bclose call <SID>BufcloseCloseIt(<q-bang> == '!')
  command! -bang Bd call <SID>BufcloseCloseIt(<q-bang> == '!')

  function! <SID>BufcloseCloseIt(...) " ... = wipeout {{{
    let currentBufNum = bufnr('%')
    let alternateBufNum = bufnr('#')

    if buflisted(alternateBufNum)
      buffer #
    else
      bnext
    endif

    if bufnr('%') == currentBufNum
      new
    endif

    if buflisted(currentBufNum)
      if a:0 > 0 && !empty(a:1)
        exe 'bwipeout! ' . currentBufNum
      else
        exe 'bdelete!  ' . currentBufNum
      endif
    endif
  endfunction
  " }}}

  " Clean unused buffers
  command! CleanUnusedBuffers call <SID>CleanUnusedBuffers()

  function! s:CleanUnusedBuffers() "{{{
    let output = ''
    redir => output
    silent buffers!
    redir END
    for buf in split(output, '\n')
      let m = matchlist(buf, '^\s*\(\d\+\)[u ][%# ][h ]')
      if empty(m)
        continue
      endif
      let bufnr = m[1] + 0
      if getbufvar(bufnr, '&bt') ==? 'help'
            \ || match(buf, '\s\s"\[No Name\]"') != -1
        exe bufnr . 'bw!'
      endif
    endfor
  endfunction
  "}}}
  "}}}2
" }}}1
"============================================================{{{1
" FileType Settings
"================================================================
  "----------------------------------------------------------{{{2
  " *
  "--------------------------------------------------------------
  if (s:MSWIN && executable('makeprg.bat')) || executable('makeprg')
    augroup Vimrc
      au FileType * call <SID>SetMakeprgFT(expand('<amatch>'))
    augroup END
    command! -nargs=? SetMakeprg call SetMakeprg(<q-args>)

    function! s:SetMakeprgFT(ft) "{{{
      if empty(a:ft)
        return
      endif

      let func = 'b:set_makeprg_' . a:ft
      if exists(func)
        call call(eval(func), [])
      else
        call SetMakeprg()
      endif
    endfunction
    "}}}

    function! SetMakeprg(...) "{{{
      let args = a:0 > 0 ? a:1 : ''
      if args !~ '^\s*$'
        let args = escape(' ' . args, ' \|"')
      endif
      exec 'setlocal makeprg=makeprg\ -t\ '''.&ft.'''\ ''%:p''' . args
    endfunction
    "}}}
  endif

  if has('autocmd') && exists('+omnifunc')
    augroup Vimrc
      au Filetype *
            \	if &omnifunc == '' |
            \		setlocal omnifunc=syntaxcomplete#Complete |
            \	endif
    augroup END
  endif

  " Modified from a.vim <http://www.vim.org/scripts/script.php?script_id=31>
  " function ExpandAlternatePath()
  function! s:ExpandAlternatePath(pathSpec, sfPath) "{{{
    let prfx = strpart(a:pathSpec, 0, 4)
    if prfx == 'wdr:' || prfx == 'abs:'
      let path = strpart(a:pathSpec, 4)
    elseif prfx == 'reg:'
      let re     = strpart(a:pathSpec, 4)
      let sep    = strpart(re, 0, 1)
      let patend = match(re, sep, 1)
      let pat    = strpart(re, 1, patend - 1)
      let subend = match(re, sep, patend + 1)
      let sub    = strpart(re, patend + 1, subend - patend - 1)
      let flag   = strpart(re, strlen(re) - 2)
      if (flag == sep)
        let flag = ''
      endif
      let path = substitute(a:sfPath, pat, sub, flag)
      "call confirm('PAT: [' . pat . '] SUB: [' . sub . ']')
      "call confirm(a:sfPath . ' => ' . path)
    else
      let path = a:pathSpec
      if (prfx == 'sfr:')
        let path = strpart(path, 4)
      endif
      let path = a:sfPath . '/' . path
    endif
    return path
  endfunction
  "}}}

  " Modified from a.vim <http://www.vim.org/scripts/script.php?script_id=31>
  " function FindFileInSearchPathEx()
  function! s:FindFileInSearchPathEx(fileName, pathList, relPathBase, count) "{{{
    let spath = ''

    if !empty(a:pathList)
      let items = split(a:pathList, ',')
      if !empty(items)
        let spath = join(map(items, 'escape(s:ExpandAlternatePath(v:val, a:relPathBase), '' \,'')'), ',')
      endif
    endif

    if !empty(&path)
      if !empty(spath)
        let spath .= ','
      endif
      let spath .= &path
    endif

    return findfile(a:fileName, spath, a:count)
  endfunction
  "}}}
  function! IncludeExpr(fname) "{{{
    if !exists('g:alternateSearchPath')
      return a:fname
    endif

    let currentPath = expand('%:p:h')
    let openCount = 1

    let fileName = s:FindFileInSearchPathEx(a:fname, g:alternateSearchPath, currentPath, openCount)
    return empty(fileName) ? a:fname : fileName
  endfunction
  "}}}
  function! SetIncludeExpr() "{{{
    if empty(&includeexpr)
      setlocal includeexpr=IncludeExpr(v:fname)
    endif
  endfunction
  "}}}
  function! s:IncludeExprInit() "{{{
    if !exists('g:loaded_alternateFile')
      delfunction SetIncludeExpr
      return
    endif

    augroup Vimrc
      au FileType * call SetIncludeExpr()
    augroup END
    call SetIncludeExpr()
  endfunction
  "}}}
  augroup Vimrc
    au VimEnter * call <SID>IncludeExprInit()|delfunction <SID>IncludeExprInit
  augroup END

  "}}}2
  "----------------------------------------------------------{{{2
  " *.m
  "--------------------------------------------------------------
  let filetype_m = 'matlab'
  augroup Vimrc
    au BufRead,BufNewFile *.m setl suffixesadd+=.m
  augroup END
  "}}}2
  "----------------------------------------------------------{{{2
  " .vimrc, .gvimrc
  "--------------------------------------------------------------
  command! -bang Vimrc  if <q-bang> == '!'|tabe $V/_vimrc |else|e $V/_vimrc |endif

  augroup Vimrc
    au BufRead,BufNewFile .vimrc,_vimrc,.gvimrc,_gvimrc let b:UpdateModifiedTime = 1
    au BufRead,BufNewFile .vimrc,_vimrc setlocal foldmethod=marker foldtext=VimrcTOCFoldLine()
  augroup END
  function! VimrcTOCFoldLine() "{{{
    let isHeadline = match(getline(v:foldstart), '^\s*"\s*[^{]\+{\{3}\d\+\s*$')
    if isHeadline == -1
      return foldtext()
    endif
    let line = getline(v:foldstart+1)
    return v:folddashes.substitute(line,'^\s*"\s*','> ', 'g')
  endfunction
  "}}}
  "}}}2
  "----------------------------------------------------------{{{2
  " c
  "--------------------------------------------------------------
  " let g:c_comment_strings	= 1
  "}}}2
  "----------------------------------------------------------{{{2
  " changelog
  "--------------------------------------------------------------
  let g:changelog_username = printf('%s  <%s>', g:USER_INFO.name, 
        \ substitute(g:USER_INFO.email, '\s*\<AT\>\s*', '@', ''))
  augroup Vimrc
    au FileType changelog nnoremap <buffer> <F6> :<C-U>NewChangelogEntry<CR>
  augroup END
  "}}}2
  "----------------------------------------------------------{{{2
  " help
  "--------------------------------------------------------------
  augroup Vimrc
    au FileType help nnoremap <buffer> <CR> <C-]>
    au FileType help nnoremap <buffer> <BS> <C-T>
  augroup END
  "}}}2
  "----------------------------------------------------------{{{2
  " shell
  "--------------------------------------------------------------
  " Set for the cygwin version of bash.
  " New version of bash seems only accept the unix newline format.
  augroup Vimrc
    au FileType sh set fileformat=unix
  augroup END
  let g:is_bash = 1
  "}}}2
  "----------------------------------------------------------{{{2
  " tex
  "--------------------------------------------------------------
	let g:tex_flavor = 'latex'
  "}}}2
  "----------------------------------------------------------{{{2
  " perl
  "--------------------------------------------------------------
  let g:perl_want_scope_in_variables = 1
  let g:perl_extended_vars = 1
  "}}}2
  "----------------------------------------------------------{{{2
  " ruby
  "--------------------------------------------------------------
  let g:rct_completion_use_fri = 0
  let g:rct_completion_info_max_len = 20
  let g:rct_use_python = 1
  "}}}2
  "----------------------------------------------------------{{{2
  " python
  "--------------------------------------------------------------
  let python_highlight_numbers           = 1
  let python_highlight_builtins          = 1
  let python_highlight_exceptions        = 1
  let python_highlight_string_formatting = 1
  "}}}2
" }}}1
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
  " fuzzyfinder.vim
  " <http://www.vim.org/scripts/script.php?script_id=1984>
  "--------------------------------------------------------------
  let g:FuzzyFinderOptions = { 'Base'      :{}, 'Buffer':{}, 'File'    :{}, 'Dir':{},
        \                      'MruFile'   :{}, 'MruCmd':{}, 'Bookmark':{}, 'Tag':{}, 
        \                      'TaggedFile':{}, 'CallbackFile':{}, 'CallbackItem':{} }
  let g:FuzzyFinderOptions.Base.abbrev_map  = {}
  nnoremap <silent> <Leader>fb :<C-U>FuzzyFinderBuffer<CR>
  nnoremap <silent> <Leader>ff :<C-U>exec v:count == 0 ? 'FuzzyFinderFile' : v:count == 1 ? 'FuzzyFinderFileWithFullCwd' : 'FuzzyFinderFileWithCurrentBufferDir'<CR>
  nnoremap <silent> <Leader>fd :<C-U>exec v:count == 0 ? 'FuzzyFinderDir' : v:count == 1 ? 'FuzzyFinderDirWithFullCwd' : 'FuzzyFinderDirWithCurrentBufferDir'<CR>
  nnoremap <silent> <Leader>fmf :<C-U>FuzzyFinderMruFile<CR>
  nnoremap <silent> <Leader>fmc :<C-U>FuzzyFinderMruCmd<CR>
  nnoremap <silent> <Leader>ft :<C-U>exec v:count == 0 ? 'FuzzyFinderTag' : v:count == 1 ? 'FuzzyFinderTagWithCursorWord' : 'FuzzyFinderTaggedFile'<CR>
  nnoremap <silent> <Leader>fk :<C-U>FuzzyFinderBookmark<CR>
  nnoremap <silent> <Leader>fak :<C-U>FuzzyFinderAddBookmark<CR>
  vnoremap <silent> <Leader>fak :FuzzyFinderAddBookmarkAsSelectedText<CR>
  "}}}2
  "----------------------------------------------------------{{{2
  " HTML.vim
  " <http://www.vim.org/scripts/script.php?script_id=453>
  "--------------------------------------------------------------
  let g:no_html_toolbar   = 1

  let g:html_template_dir = s:RUNTIME_DIR . '/templates/html'
  " Type '<Leader><Tab>' to move to the next insert point.
  let g:no_html_tab_mapping = 1
  let g:html_tag_case     = 'lowercase'
  let g:html_template     = g:html_template_dir . '/xhtml-strict.html'
  let g:html_authorname   = g:USER_INFO['name']
  let g:html_authoremail  = g:USER_INFO['email']
  "}}}2
  "----------------------------------------------------------{{{2
  " EnhCommentify.vim
  " <http://www.vim.org/scripts/script.php?script_id=23>
  "--------------------------------------------------------------
  let g:EnhCommentifyRespectIndent  = 'Yes'
  let g:EnhCommentifyPretty         = 'Yes'
  let g:EnhCommentifyUseBlockIndent = 'Yes'
  let g:EnhCommentifyUserBindings   = 'Yes'
  let g:EnhCommentifyUseSyntax      = 'Yes'

  nmap <silent> <Leader>z <Esc><Plug>Traditional
  vmap <silent> <Leader>z <Esc><Plug>VisualTraditional

  " let g:EnhCommentifyMultiPartBlocks = 'Yes'
  augroup Vimrc
    au FileType * call s:ECInit(expand('<amatch>'))
  augroup END

  function! s:ECInit(ft) "{{{
    if a:ft != '' && exists('b:ECdidBufferInit')
      unlet b:ECdidBufferInit
      call EnhancedCommentifyInitBuffer()

      " Detect embedded code
      " See |EnhComm-Options| g:EnhCommentifyUseSyntax
      if a:ft =~ '^\(vim\|html\)$'
        let b:ECuseSyntax = 1
      endif
    endif
  endfunction "}}}

  let g:EnhCommentifyCallbackExists = 1
  function! EnhCommentifyCallback(ft) "{{{
    if a:ft ==? 'octave'
      let b:ECcommentOpen = '%'
      let b:ECcommentClose = ''
    elseif a:ft ==? 'dosbatch'
      let b:ECcommentOpen = 'REM'
      let b:ECcommentClose = ''
    elseif a:ft ==? 'ruby'
      let b:ECcommentOpen = '#'
      let b:ECcommentClose = ''
    endif
  endfunction "}}}
  "}}}2
  "----------------------------------------------------------{{{2
  " DrawIt.vim
  " <http://www.vim.org/scripts/script.php?script_id=40>
  "--------------------------------------------------------------
  let g:DrChipTopLvlMenu = '&Plugin.'
  "}}}2
  "----------------------------------------------------------{{{2
  " |pi_netrw.txt|
  "--------------------------------------------------------------
  let g:netrw_home = $HOME
  let g:netrw_winsize = 24
  let g:netrw_silent  = 1
  let g:netrw_cygwin = 1
  "}}}2
  "----------------------------------------------------------{{{2
  " imap.vim (Part of Latex-Suite)
  "--------------------------------------------------------------
  let g:Imap_PlaceHolderStart = '<'.'+'
  let g:Imap_PlaceHolderEnd   = '+'.'>'
  imap <C-F> <Plug>IMAP_JumpForward
  vmap <C-F> <Plug>IMAP_JumpForward
  " vmap <C-F> <Plug>IMAP_DeleteAndJumpForward
  imap <C-B> <Plug>IMAP_JumpBack
  vmap <C-B> <Plug>IMAP_JumpBack
  " vmap <C-B> <Plug>IMAP_DeleteAndJumpBack
  "}}}2
  "----------------------------------------------------------{{{2
  " OmniCppComplete
  " <http://www.vim.org/scripts/script.php?script_id=1520>
  "--------------------------------------------------------------
  let g:OmniCpp_GlobalScopeSearch   = 1
  let g:OmniCpp_NamespaceSearch     = 2
  let g:OmniCpp_DisplayMode         = 0
  let g:OmniCpp_ShowScopeInAbbr     = 0
  let g:OmniCpp_ShowPrototypeInAbbr = 1
  let g:OmniCpp_ShowAccess          = 1
  let g:OmniCpp_MayCompleteDot      = 0
  let g:OmniCpp_MayCompleteArrow    = 0
  let g:OmniCpp_MayCompleteScope    = 0
  let g:OmniCpp_SelectFirstItem     = 0
  let g:OmniCpp_LocalSearchDecl     = 0
  "}}}2
  "----------------------------------------------------------{{{2
  " taglist.vim
  " <http://www.vim.org/scripts/script.php?script_id=273>
  "--------------------------------------------------------------
	let g:Tlist_WinWidth = 24
  let g:Tlist_Enable_Fold_Column = 0
  let g:Tlist_Ctags_Cmd = 'ctags'
  "}}}2
  "----------------------------------------------------------{{{2
  " CRefVim
  " <http://www.vim.org/scripts/script.php?script_id=614>
  "--------------------------------------------------------------
  map <silent> <Leader>ci  <Plug>CRV_CRefVimInvoke
  map <silent> <Leader>caa <Plug>CRV_CRefVimAsk
  "}}}2
  "----------------------------------------------------------{{{2
  " stlrefvim
  " <http://www.vim.org/scripts/script.php?script_id=2353>
  "--------------------------------------------------------------
  map <silent> <Leader>ti  <Plug>StlRefVimInvoke
  map <silent> <Leader>taa <Plug>StlRefVimAsk
  "}}}2
  "----------------------------------------------------------{{{2
  " surround.vim
  " <http://www.vim.org/scripts/script.php?script_id=1697>
  "--------------------------------------------------------------
  if exists(":xmap")
    xmap vs <Plug>Vsurround
  else
    vmap vs <Plug>Vsurround
  endif
  if exists(":xmap")
    xmap vS <Plug>VSurround
  else
    vmap vS <Plug>VSurround
  endif
  "}}}2
  "----------------------------------------------------------{{{2
  " project.vim (Slight modification)
  " <http://www.vim.org/scripts/script.php?script_id=69>
  "--------------------------------------------------------------
  let g:proj_flags = 'istLv'
  let g:proj_window_width = 24

  " My own setting:

  " The width of the fold column shown at the side of the project 
  " window.
  " (default: 0)
  let g:proj_foldcolumn = 2

  " The default project filename in current directory.
  " (default: .vimproject)
  "
  " If you invoke :Project without specifying the filename, Project uses the
  " file named by the variable 'g:proj_filename' in the current directory if it
  " exists, otherwise $HOME/.vimprojects is used.
  let g:proj_filename = '.vimproject'
  "}}}2
  "----------------------------------------------------------{{{2
  " dbext.vim
  " <http://www.vim.org/scripts/script.php?script_id=356>
  "--------------------------------------------------------------
  let g:dbext_sql_history = $HOME.'/dbext_sql_history.txt'
  let g:dbext_default_menu_mode = 3
  "}}}2
  "----------------------------------------------------------{{{2
  " xmledit
  " <http://www.vim.org/scripts/script.php?script_id=301>
  "--------------------------------------------------------------
  let g:xml_jump_string = ''
  "}}}2
  "----------------------------------------------------------{{{2
  " vcscommand.vim
  " <http://www.vim.org/scripts/script.php?script_id=90>
  "--------------------------------------------------------------
  let VCSCommandDisableMappings = 1
  let VCSCommandDeleteOnHide    = 1

  if s:MSWIN
    " I use cygwin version of Mercurial
    if filereadable('C:/cygwin/bin/python.exe')
          \ && filereadable('C:/cygwin/bin/hg')
      let VCSCommandHGExec = 'C:/cygwin/bin/python C:/cygwin/bin/hg'
    endif
  endif

  let VCSCommandMapPrefix = '<Leader>v'
  "}}}2
  "----------------------------------------------------------{{{2
  " camelcasemotion.vim <#r=CamelCaseMotion>
  " <http://www.vim.org/scripts/script.php?script_id=1905>
  "--------------------------------------------------------------
  "}}}2
  "----------------------------------------------------------{{{2
  " bufexplorer.vim <id=BufExplorer>
  " <http://www.vim.org/scripts/script.php?script_id=42>
  "--------------------------------------------------------------
  nnoremap <silent> <F3> :<C-U>exec v:count == 0 ? 'BufExplorer' : v:count == 1 ? 'HSBufExplorer' : 'VSBufExplorer'<CR>
  "}}}2
  "----------------------------------------------------------{{{2
  " editexisting.vim -> $VIMRUNTIME/macros/editexisting.vim
  "--------------------------------------------------------------
  if has('gui_running') && has('clientserver')
    silent! ru macros/editexisting.vim
  endif
  "}}}2
  "----------------------------------------------------------{{{2
  " LaTeX-Suite (Slight modification)
  " <http://www.vim.org/scripts/script.php?script_id=475>
  "--------------------------------------------------------------
  " Add option '-file-line-error' to command 'latex', and add
  "
  "    setlocal efm+=%E%f:%l:\ %m
  "
  " to compiler/tex.vim, so 'efm' can easily identify the file
  " containing the error.
  "
  " See: http://article.gmane.org/gmane.comp.editors.vim.latex.devel/172

  let g:Tex_MenuPrefix = 'Te&X.'
  let g:Tex_GotoError = 0
  let g:Tex_ShowErrorContext = 0

  " IMPORTANT: win32 users will need to have 'shellslash' set so that latex
  " can be called correctly.
  set shellslash
  " let g:Tex_DefaultTargetFormat  = 'ps'
  let g:Tex_DefaultTargetFormat  = 'pdf'

  let g:Tex_CompileRule_dvi = 'latex -file-line-error -interaction=batchmode $*'
  let g:Tex_CompileRule_pdf = 'pdflatex -file-line-error -interaction=batchmode $*'

  let g:Tex_FormatDependency_pdf = 'pdf'
  let g:Tex_FormatDependency_ps  = 'dvi,ps'

  let g:Tex_PromptedEnvironments =
        \ 'eqnarray*,eqnarray,equation,equation*,\[,$$,align,align*'
        \ .',enumerate,itemize,thebibliography'

  " IMPORTANT: grep will sometimes skip displaying the file name if you
  " search in a singe file. This will confuse latex-suite. Set your grep
  " program to alway generate a file-name.
  set grepprg=grep\ -nH\ $*

  if s:MSWIN
    let g:Tex_ViewRule_ps =  'gsview32'
    let g:Tex_ViewRule_pdf = 'AcroRd32'
  endif
  "}}}2
  "----------------------------------------------------------{{{2
  " supertab.vim <id=SuperTab>
  " <http://www.vim.org/scripts/script.php?script_id=1643>
  "
  " BUG FIX: Vim command completion |compl-vim| doesn't work 
  "          using '<C-R>=' |i_CTRL-R|.
  "          (Fixed in version 0.48)
  "--------------------------------------------------------------
  " let g:SuperTabDefaultCompletionType = '<C-N>'
  let g:SuperTabRetainCompletionType  = 2

  if globpath(&rtp, 'plugin/supertab.vim') != ''
    imap <F3>   <C-N>
    imap <S-F3> <C-P>
  endif
  "}}}2
  "----------------------------------------------------------{{{2
  " snipMate.vim (Slight modification)
  " <http://www.vim.org/scripts/script.php?script_id=2540>
  "--------------------------------------------------------------
  let g:snips_author = g:USER_INFO['name']
  let g:snippets_dir = s:RUNTIME_DIR . '/snippets/'
  au BufRead,BufNewFile *.snippet exec 'set ft='.expand('<afile>:p:h:t')
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
  "----------------------------------------------------------{{{2
  " FileExplorer.vim (My works)
  "--------------------------------------------------------------
  function! FileExplorer_OpenFunc(file) 
		if a:file =~? '\.\%(jpg\|bmp\|png\|gif\)$'
			if exists('*ShowImage') && ShowImage(a:file, 1) == 0
				return 1
			elseif exists('*myutils#OpenFile') && myutils#OpenFile(a:file) == 0
				return 1
			endif
		elseif exists('*myutils#OpenFile') && a:file =~? '\.\%(pdf\|docx\?\|xls\|odt\)$'
			call myutils#OpenFile(a:file)
			return 1
		endif
  endfunction
  let g:FileExplorer_OpenHandler = 'FileExplorer_OpenFunc'
	if s:MSWIN
		let g:FileExplorer_Encoding  = 'big5'
	endif
  "}}}2
  "----------------------------------------------------------{{{2
  " Dict.vim (My works)
  "--------------------------------------------------------------
  if !s:MSWIN && $USER == 'root'
    let g:loaded_Dict_plugin = 1
  endif
  "}}}2
  "----------------------------------------------------------{{{2
  " FlyMake.vim (My works)
  "--------------------------------------------------------------
  let g:flymake_compiler = { 'python': 'py-compile' }
  let g:flymake_ballooneval = 1
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
  " Bookmarks.vim (My works, modified for NavMenu.vim)
  "--------------------------------------------------------------
  let g:Bookmarks_menu = 0
  "}}}2
  "----------------------------------------------------------{{{2
  " eclim.vim
  " <http://eclim.sourceforge.net/>
  "--------------------------------------------------------------
  " Currently Eclipse is intalled only on MSWIN
  if !s:MSWIN
    let g:EclimDisabled = 1
  endif

  let g:EclimBaseDir = escape(substitute(s:RUNTIME_DIR, '\\', '/', 'g'), ' ')

  let g:taglisttoo_disabled = 1
  let g:EclimTemplatesDisabled = 1
  let g:EclimBrowser = 'firefox'
  let g:EclimShowQuickfixSigns = 0

  let g:EclimShowCurrentError = 0
  let g:EclimShowCurrentErrorBalloon = 0
  let g:EclimMakeLCD = 0
  let g:EclimMakeQfFilter = 0

  let g:EclimAntValidate = 0
  let g:EclimCssValidate = 0
  let g:EclimDtdValidate = 0
  let g:EclimHtmlValidate = 0
  let g:EclimJavaSrcValidate = 0
  let g:EclimJavascriptValidate = 0
  let g:EclimLog4jValidate = 0
  let g:EclimPhpValidate = 0
  let g:EclimPythonValidate = 0
  let g:EclimWebXmlValidate = 0
  let g:EclimWsdlValidate = 0
  let g:EclimXmlValidate = 0
  let g:EclimXsdValidate = 0
  "}}}2
" }}}1
"============================================================{{{1
" Misc
"================================================================
  "----------------------------------------------------------{{{2
  " Handle some cygwin filepath (/cygdrive/*,/home/*) in WIN32 version of vim
  "
  " ATTENTION: Vim sometimes treats WIN32 filepath as '/home/...' 
  " (without disk numbers) and it matches the autocmd pattern in 
  " autocmd group 'Cygpath'. If you happened to have directory named 
  " 'C:/home' or 'C:/cygdrive' (or with other disk number), the 
  " following code may open files in that directory using cygpath.
  "--------------------------------------------------------------
  if s:MSWIN && !has('win32unix') && executable('cygpath.exe')
    function! s:Cygpath(path) "{{{
      if a:path == ''
        return ''
      endif

      if !exists('b:prev_cygpath')
        let b:prev_cygpath = ['', '']
      endif

      if b:prev_cygpath[0] == a:path
        return b:prev_cygpath[1]
      endif
      let l:path = substitute(system('cygpath -m ' . shellescape(a:path)), '\n', '', 'g')
      if v:shell_error == 0
        let b:prev_cygpath = [a:path, l:path]
      else
        let l:path = ''
      endif

      return l:path
    endfunction
    "}}}
    function! s:Getpath() "{{{
      let path = expand('<amatch>')
      if filereadable(path)
        return path
      endif

      return s:Cygpath(expand('<amatch>:s?^[a-zA-Z]:??'))
    endfunction
    "}}}
    function! s:EditFile(path) "{{{
      if isdirectory(a:path)
        silent! call netrw#LocalBrowseCheck(a:path)
      else
        set noswf
        exe 'silent doau BufReadPre ' . a:path
        if filereadable(a:path)
          try
            let ul = &ul
            setl ul=-1
            silent %d _ | exe '1r '. a:path | silent 1d _
          finally
            let &l:ul = ul
          endtry
        endif
        exe 'silent doau BufReadPost ' . a:path
      endif
    endfunction
    "}}}
    augroup Cygpath
      au!
      au BufReadCmd   /cygdrive/*,/home/* call s:EditFile(s:Getpath())

      au FileReadCmd  /cygdrive/*,/home/* 
            \ exe 'silent doau FileReadPre '.s:Getpath() |
            \ exe 'r '.s:Getpath() |
            \ exe 'silent doau FileReadPost '.s:Getpath()

      au BufWriteCmd  /cygdrive/*,/home/* 
            \ exe 'silent doau BufWritePre '.s:Getpath() |
            \ exe 'w! '.s:Getpath() |
            \ set nomod |
            \ exe 'silent doau BufWritePost '.s:Getpath()

      au FileWriteCmd /cygdrive/*,/home/* 
            \ exe 'silent doau FileWritePre '.s:Getpath() |
            \ exe "'[,']w! ".s:Getpath() |
            \ exe 'silent doau FileWritePost '.s:Getpath()

    augroup END
  endif
  " }}}2
  "----------------------------------------------------------{{{2
  " The usage of cscope
  "--------------------------------------------------------------
  if has('cscope')
    set csprg=cscope
    set csto=0
    "set cst
    set nocsverb
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
    nmap <C-_>t :<C-U>cs find t <C-R>=expand('<cword>')<CR><CR>
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
    nmap <C-\>t :<C-U>scs find t <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\>e :<C-U>scs find e <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\>f :<C-U>scs find f <C-R>=expand('<cfile>')<CR><CR>
    nmap <C-\>i :<C-U>scs find i ^<C-R>=expand('<cfile>')<CR>$<CR>
    nmap <C-\>d :<C-U>scs find d <C-R>=expand('<cword>')<CR><CR>

    " Hitting 'CTRL-\' *twice* before the search type does a vertical
    " split instead of a horizontal one

    nmap <C-\><C-\>s :<C-U>vert scs find s <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\><C-\>g :<C-U>vert scs find g <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\><C-\>c :<C-U>vert scs find c <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\><C-\>t :<C-U>vert scs find t <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\><C-\>e :<C-U>vert scs find e <C-R>=expand('<cword>')<CR><CR>
    nmap <C-\><C-\>i :<C-U>vert scs find i ^<C-R>=expand('<cfile>')<CR>$<CR>
    nmap <C-\><C-\>d :<C-U>vert scs find d <C-R>=expand('<cword>')<CR><CR>
  endif
  " }}}2
  "----------------------------------------------------------{{{2
  " Use :Man in Vim (use ManPageView <http://www.vim.org/scripts/script.php?script_id=489> instead)
  "--------------------------------------------------------------
  " ru ftplugin/man.vim
  " }}}2
  "----------------------------------------------------------{{{2
  " Highlight complete items in preview window
  "--------------------------------------------------------------
  function! s:HighlightCompleteItems() "{{{
    if &previewwindow && &bt == 'nofile' && pumvisible()
      syn match Label '^\w\+:'he=e-1
    endif
  endfunction
  "}}}
  augroup Vimrc
    autocmd BufWinEnter * call s:HighlightCompleteItems()
  augroup END
  " }}}2
" }}}1
"============================================================{{{1
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
noremap  <C-V> "+gP
cnoremap <C-V> <C-R>+

" Pasting blockwise and linewise selections is not possible in Insert and
" Visual mode without the +virtualedit feature.  They are pasted as if they
" were characterwise instead.
" Uses the paste.vim autoload script.

exe 'inoremap <script> <C-V>' paste#paste_cmd['i']
exe 'vnoremap <script> <C-V>' paste#paste_cmd['v']

imap <S-Insert> <C-V>
vmap <S-Insert>	<C-V>

" For CTRL-V to work autoselect must be off.
" On Unix we have two selections, autoselect can be used.
if !has("unix")
  set guioptions-=a
endif
" }}}1
" vim: ts=2 : sw=2 :
