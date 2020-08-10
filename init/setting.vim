if !has('gui_running')
  let did_install_default_menus = 1
endif
let did_install_syntax_menu = 1
let no_buffers_menu = 1

if &term == 'screen'
  set term=xterm
elseif &term == 'screen-256color'
  set term=xterm
  set t_Co=256
endif

" Encoding
set encoding=utf-8
if has('win32') || &term == 'cygwin'
  set fileformats=unix,dos
  if !has('gui_win32')
    set termencoding=cp950
    set encoding=cp950
    set fileencoding=utf-8
  endif
else
  try
    language zh_TW.UTF-8
  catch /^Vim\%((\a\+)\)\=:E197/
    language C
  endtry
endif
language messages C
language time C
set fileencodings=ucs-bom,utf-8,big5,latin1

" Size of the Vim window
if has('gui_win32')
  let s:default_size = [42, 120]

  if &lines < s:default_size[0]
    let &lines = s:default_size[0]
  endif

  if &columns < s:default_size[1]
    let &columns = s:default_size[1]
  endif

  unlet s:default_size
endif

" 'backup' settings
set backup
set backupext=~
let s:backupdir = exists('g:backupdir') ? g:backupdir : ($HOME . '/.backup/vim')
if filewritable(s:backupdir) == 2
  let &backupdir = s:backupdir
  let &viewdir   = s:backupdir
  if version >= 703
    let &undodir = s:backupdir
  endif
endif
unlet s:backupdir

" set guioptions-=m         " Exclude Menu bar.
set guioptions-=M         " Do NOT source system menu
set guioptions-=T         " Exclude Toolbar.
set guioptions-=e         " Non-GUI tab pages
set shortmess+=I          " Don't give the intro message when starting Vim
set formatoptions=tcroqnB " See |fo-table|
"set ambiwidth=double      " Handle the width of the CJK font
set backspace=2           " Allow backspacing over everything in insert mode
set ruler                 " Show the cursor position all the time
set showcmd               " Display incomplete commands
set incsearch             " Do incremental searching
set number
set history=100
set cino=>s,e0,n0,f0,{0,}0,^0,:s,=s,l1,b0,g0,hs,ps,t0,is,+s,c3,C0,/0,(2s,us,U0,w0,W0,m0,j0,)20,*30
set matchpairs=(:),{:},[:],<:>
set whichwrap+=<,>,[,]
set updatetime=500
set selection=exclusive
set listchars=tab:\|-,trail:-,precedes:<,extends:>,nbsp:%
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
set list
set cmdheight=2

if exists('g:vim_resources_dir') && !empty(g:vim_resources_dir)
  let &tags .= printf(',%s/tags', g:vim_resources_dir)
  if has('emacs_tags')
    let &tags .= printf(',%s/TAGS', g:vim_resources_dir)
  endif
  let &grepprg = 'grep -nH -I --exclude-dir=.svn --exclude-dir=.git --exclude=cscope.out --exclude=tags --exclude-dir=' . g:vim_resources_dir . ' $*'
else
  set grepprg=grep\ -nH\ -I\ --exclude-dir=.svn\ --exclude-dir=.git\ --exclude=cscope.out\ --exclude=tags\ $*
endif

" Enable file type detection.
filetype plugin indent on

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

if g:MSWIN
  set keywordprg=man
endif

if !has('gui_running')
  set mouse=a
endif

" Use menu in console mode |console-menus|
if !exists("did_install_default_menus")
  so $VIMRUNTIME/menu.vim
endif
set wildmenu
set cpo-=<
set wcm=<C-Z>
map <F10> :<C-U>emenu <C-Z>

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

" Set 'statusline' & 'titlestring'
command! -bar -bang TitleShowLoginInfo let g:title_show_login_info = <q-bang> != '!'
let g:title_show_login_info = g:MSWIN ? 0 : 1
function! s:GetLoginInfo() "{{{
  let user = g:MSWIN ? $USERNAME : $USER
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

  if !exists('g:opt_trim_path')
    let g:opt_trim_path = 1
  endif

  if g:opt_trim_path != 0
    if strlen(cwd) > max([30, &columns/4])
      if exists('*pathshorten')
        let cwd = pathshorten(cwd)
      else
        let cwd = substitute(cwd, '\([~.]*[^:/]\)\%([^:/]\)*/', '\1/', 'g')
      endif
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
  for opt in ['spell', 'paste', 'list']
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

" for myutils#CloseAllOtherWindows()
function! MyCloseAllOtherWindowsReserveHandler() "{{{
  let fname = expand('%')
  if fname == '__vista__' || ('' == fname && &ft == 'yggdrasil')
    return 1
  else
    " fallback to default handler
    return -1
  endif
endfunction
"}}}
let g:CloseAllOtherWindowsReserveHandler = 'MyCloseAllOtherWindowsReserveHandler'

set title
if !g:MSWIN
  let &titleold  = s:GetLoginInfo().':'.expand('%:p:~:h')
endif
let &titlestring = '%t%( %{OptModifiedFlag(0)}%)%( %{OptInfo()}%h%)'
if has('clientserver')
  let &titlestring .= '%( - %{v:servername}%)'
endif

" let &statusline = '%<%f%( %{OptModifiedFlag(1)}%y%w%r%)%=%-16.( %l/%L,%c%V%) '
let &statusline = '%<%f%( %{OptModifiedFlag(1)}%{ManBufInfo()}%y%w%r[%{&fenc!=#""?&fenc:&enc}][%{&ff}]%)'
      \ . '%( %{OptSetInfo()}%) %k%=%-14.( %l/%L,%c%V%) '

" Set 'tabline'
function! GetTabLabel(n) "{{{
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)
  let bufnr = buflist[winnr - 1]
  let label = bufname(bufnr)
  let buftype = getbufvar(bufnr, '&buftype')

  if label == ''
    if buftype  == 'quickfix'
      let label = '[Quickfix List]'
    elseif buftype == 'nofile'
      let label = '[Scratch]'
    else
      let label = '[No Name]'
    endi
  else
    if buftype == 'help'
      let label = fnamemodify(label, ':t')
    else
      if exists('*pathshorten')
        let label = pathshorten(label)
      else
        let label = substitute(label, '\([~.]*[^:/]\)\%([^:/]\)*/', '\1/', 'g')
      endif
    endif
  endif
  return label
endfunction
"}}}
function! ShowTabLine() "{{{
  let s = ''

  for i in range(1, tabpagenr('$'))
    " select the highlighting
    if i == tabpagenr()
      let hl = '%#TabLineSel#'
    else
      let hl = '%#TabLine#'
    endif

    let s .= hl

    " set the tab page number (for mouse clicks)
    let s .= '%' . i . 'T'

    " the label is made by GetTabLabel()
    let s .= ' %1*' . i . hl . ' %{GetTabLabel(' . i . ')} '
  endfor

  " after the last tab fill with TabLineFill and reset tab page nr
  let s .= '%#TabLineFill#%T'

  " right-align the label to close the current tab page
  if tabpagenr('$') > 1
    let s .= '%=%#TabLine#%999XX'
  endif

  return s
endfunction
"}}}
let &tabline = '%!ShowTabLine()'

" Make <M-...> almost work in xterm
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
  elseif has('gui_running')
    silent! set guifont=Monaco\ 10
  else
    " silent! set guifont=Consolas\ 12,Courier\ 10\ Pitch\ 12
    silent! set guifont=Courier\ 10\ Pitch\ 10,Monospace\ 10
  endif
elseif &t_Co > 2
  if &t_Co < 16
    set t_Co=16
  endif
  " Changed the colors of grounps Pmenu and PmenuSel
  if &term == 'win32'
    silent! colors default2
  else
    silent! colors ChocolateLiquor2
  endif
  set bg=dark
  augroup Vimrc
    au VimLeave * hi clear
  augroup END
endif

" vim: fdm=marker : ts=2 : sw=2 :
