" Use vim-plug to manage plugins
" <https://github.com/junegunn/vim-plug>

call plug#begin('~/.vim-plugged')

Plug 'ervandew/supertab'
Plug 'hari-rangarajan/CCTree', { 'on': ['CCTreeAutoLoadDB', 'CCTreeLoadDB', 'CCTreeLoadXRefDB', 'CCTreeLoadXRefDBFromDisk'], 'for': ['c', 'cpp' ] }
Plug 'will133/vim-dirdiff', { 'on': 'DirDiff' }
Plug 'mattn/calendar-vim', { 'on': ['Calendar', 'CalendarH'] }
Plug 'jlanzarotta/bufexplorer'
Plug 'Shougo/unite.vim'
Plug 'bkad/CamelCaseMotion'
Plug 'hrp/EnhancedCommentify'
Plug 'sjl/gundo.vim'
Plug 'jreybert/vim-largefile'
Plug 'dimasg/vim-mark'
Plug 'mtth/scratch.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer' }

Plug 'taglist.vim'
Plug 'DrawIt'
Plug 'Align'
Plug 'Visincr'
Plug 'CRefVim', { 'for': ['c', 'cpp' ] }

call plug#end()

ru macro/matchit.vim

"--------------------------------------------------------------
" EnhCommentify.vim
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
endfunction
"}}}

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
  elseif a:ft ==? 'glsl'
    let b:ECcommentOpen = '//'
    let b:ECcommentClose = ''
  endif
endfunction
"}}}
"--------------------------------------------------------------
" DrawIt.vim
"--------------------------------------------------------------
let g:DrChipTopLvlMenu = '&Plugin.'
"--------------------------------------------------------------
" |pi_netrw.txt|
"--------------------------------------------------------------
let g:netrw_home = $HOME
let g:netrw_winsize = 24
let g:netrw_silent  = 1
let g:netrw_cygwin = 1
let g:netrw_liststyle = 3
"--------------------------------------------------------------
" taglist.vim
"--------------------------------------------------------------
  let g:Tlist_WinWidth = 24
let g:Tlist_Enable_Fold_Column = 0
let g:Tlist_Ctags_Cmd = 'ctags'
let g:Tlist_Show_One_File = 1
let Tlist_Use_Right_Window = 1
"--------------------------------------------------------------
" surround.vim
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
"--------------------------------------------------------------
" camelcasemotion.vim <#r=CamelCaseMotion>
"--------------------------------------------------------------
"--------------------------------------------------------------
" bufexplorer.vim <id=BufExplorer>
"--------------------------------------------------------------
let g:bufExplorerFindActive = 0
nnoremap <silent> <F3> :<C-U>exec v:count == 0 ? 'BufExplorer' : v:count == 1 ? 'BufExplorerHorizontalSplit' : 'BufExplorerVerticalSplit'<CR>
"--------------------------------------------------------------
" cctree.vim
"--------------------------------------------------------------
command! -nargs=? CTLoadDB exec 'CCTreeLoadDB' (empty(<q-args>) ? 'cscope.out' : <q-args>)
let g:CCTreeWindowWidth = 24

au BufRead,BufNewFile CCTree-View 
      \ nnoremap <silent> <buffer> <Leader>h :<C-U>CCTreeOptsToggle DynamicTreeHiLights<CR>

highlight CCTreeMarkers guifg=DarkGray ctermfg=DarkGray
highlight link CCTreeHiMarkers PmenuSel
let g:CCTreeKeyHilightTree = '<F3>'
"--------------------------------------------------------------
" DirDiff.vim
"--------------------------------------------------------------
let g:DirDiffExcludes = "*.class,*.exe,.*.sw?,*.py[cod]"
"--------------------------------------------------------------
" LargeFile.vim
"--------------------------------------------------------------
let g:LargeFile= 10
"--------------------------------------------------------------
" mark.vim
"--------------------------------------------------------------
  nmap <unique> <silent> <Leader>im <Plug>MarkRegex
  vmap <unique> <silent> <Leader>im <Plug>MarkRegex
  nmap <unique> <silent> <Leader>cm <Plug>MarkClear
"--------------------------------------------------------------
" editexisting.vim -> $VIMRUNTIME/macros/editexisting.vim
"--------------------------------------------------------------
if has('gui_running') && has('clientserver')
  silent! ru macros/editexisting.vim
else
  try
    au! SwapExists * let v:swapchoice = 'o'
  catch
    " Without SwapExists we don't do anything for ":edit" commands
  endtry
endif
"--------------------------------------------------------------
" LaTeX-Suite (Slight modification)
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
set grepprg=grep\ -nH\ -I\ --exclude-dir=.svn\ --exclude-dir=.git\ --exclude=cscope.out\ --exclude=tags\ $*

if g:MSWIN
  let g:Tex_ViewRule_ps =  'gsview32'
  let g:Tex_ViewRule_pdf = 'AcroRd32'
endif
"--------------------------------------------------------------
" supertab.vim <id=SuperTab>
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
"--------------------------------------------------------------
" FileExplorer.vim (My works)
"--------------------------------------------------------------
function! FileExplorer_OpenFunc(file) "{{{
  	if a:file =~? '\.\%(jpg\|bmp\|png\|gif\)$'
    try
      if myutils#OpenFile(a:file) == 0
        return 1
      elseif myutils#ShowImage(a:file, 1) == 0
        return 1
      endif
    catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
    endtry
  	elseif a:file =~? '\.\%(pdf\|docx\?\|xls\|odt\)$'
    try
      call myutils#OpenFile(a:file)
      return 1
    catch /^Vim\%((\a\+)\)\=:E\%(117\|107\)/
    endtry
  	endif
endfunction
"}}}
let g:FileExplorer_OpenHandler = 'FileExplorer_OpenFunc'
if g:MSWIN
  let g:FileExplorer_Encoding  = 'big5'
endif
"--------------------------------------------------------------
" Dict.vim (My works)
"--------------------------------------------------------------
if !g:MSWIN && $USER == 'root'
  let g:loaded_Dict_plugin = 1
endif
"--------------------------------------------------------------
" FlyMake.vim (My works)
"--------------------------------------------------------------
let g:flymake_compiler = { 'python': 'py-compile' }
let g:flymake_ballooneval = 1
"--------------------------------------------------------------
" Bookmarks.vim (My works, modified for NavMenu.vim)
"--------------------------------------------------------------
let g:Bookmarks_menu = 0
"--------------------------------------------------------------
" calendar.vim
"--------------------------------------------------------------
inoremap <silent> <Leader>tic <C-\><C-O>:CalendarH<CR>

function! CalendarInsertDate(day, month, year, week, dir) "{{{
  let date = printf('%04d/%02d/%02d', a:year, a:month, a:day)
  exe "norm q"
  if col("'^") != col('$')
    exe "norm! i" . date
    exe "norm! l"
    startinsert
  else
    exe "norm! a" . date
    startinsert!
  endif
endfunction
"}}}
let g:calendar_action = "CalendarInsertDate"
"--------------------------------------------------------------
" YouCompleteMe
"--------------------------------------------------------------
let g:ycm_auto_trigger = 0
let g:ycm_key_list_select_completion = ['<Down>']
let g:ycm_key_list_previous_completion = ['<Up>']

" vim: fdm=marker : ts=2 : sw=2 :
