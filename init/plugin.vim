" Use vim-plug to manage plugins
" <https://github.com/junegunn/vim-plug>

let s:enable_coc = executable('node') && executable('ccls')
let s:root_pattern = ['.ccls', '.project', '.root', '.svn', '.git', '.hg', 'compile_commands.json']

call plug#begin('~/.vim-plug')

Plug 'itchyny/lightline.vim'

Plug 'ervandew/supertab'
Plug 'will133/vim-dirdiff'
Plug 'jlanzarotta/bufexplorer'
Plug 'sjl/gundo.vim'
Plug 'dimasg/vim-mark'
Plug 'mtth/scratch.vim'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'mhinz/vim-signify'
Plug 'jiangmiao/auto-pairs'
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
if g:MSWIN
  Plug 'junegunn/fzf'
else
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
endif
Plug 'junegunn/fzf.vim'
Plug 'Yggdroot/indentLine'
Plug 'hrp/EnhancedCommentify'
Plug 'skywind3000/asyncrun.vim'
Plug 'bkad/CamelCaseMotion'

Plug 'sheerun/vim-polyglot'
Plug 'lervag/vimtex'

if s:enable_coc
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'm-pilia/vim-ccls'
endif

Plug 'rhysd/vim-clang-format'
Plug 'dense-analysis/ale'
Plug 'ludovicchabant/vim-gutentags', { 'on': 'GutentagsToggleEnabled' }
Plug 'Shougo/echodoc.vim'

Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-indent'
Plug 'kana/vim-textobj-syntax'
Plug 'kana/vim-textobj-function', { 'for':['c', 'cpp', 'vim', 'java'] }
Plug 'sgur/vim-textobj-parameter'

Plug 'liuchengxu/vista.vim'
Plug 'vim-scripts/taglist.vim'
Plug 'vim-scripts/CRefVim', { 'for': ['c', 'cpp' ] }

" If you don't have nodejs and yarn
" use pre build, add 'vim-plug' to the filetype list so vim-plug can update this plugin
" see: https://github.com/iamcco/markdown-preview.nvim/issues/50
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

Plug 'preservim/nerdtree'
Plug 'dhruvasagar/vim-table-mode'

if has('nvim')
  " neovim removes cscope support in 0.9, so we need to bring it back
  if has('nvim-0.9')
    Plug 'dhananjaylatkar/cscope_maps.nvim' " cscope keymaps
  endif

  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-orgmode/orgmode'
  " my own fork form 3rd/image.nvim, which fixes some issues
  Plug 'cxanes/image.nvim'
  Plug 'mfussenegger/nvim-dap'
  Plug 'rcarriga/nvim-dap-ui'
  Plug 'theHamsta/nvim-dap-virtual-text'
endif

call plug#end()

if exists(':packadd') && !has('nvim')
  packadd! matchit
else
  ru macro/matchit.vim
endif

if exists(':packadd') && has('terminal')
  packadd termdebug
endif

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
  elseif a:ft ==? 'cuda'
    let b:ECcommentOpen = '//'
    let b:ECcommentClose = ''
  endif
endfunction
"}}}
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
let g:Tlist_WinWidth = 34
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
" DirDiff.vim
"--------------------------------------------------------------
let g:DirDiffExcludes = ".git,*.class,*.exe,.*.sw?,*.py[cod]"
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
  if exists(':packadd')
    packadd! editexisting
  else
    silent! ru macros/editexisting.vim
  endif
else
  try
    au! SwapExists * let v:swapchoice = 'o'
  catch
    " Without SwapExists we don't do anything for ":edit" commands
  endtry
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
let g:FileExplorer_WinWidth = 34
"--------------------------------------------------------------
" Dict.vim (My works)
"--------------------------------------------------------------
if !g:MSWIN && $USER == 'root'
  let g:loaded_Dict_plugin = 1
endif
"--------------------------------------------------------------
" Bookmarks.vim (My works, modified for NavMenu.vim)
"--------------------------------------------------------------
let g:Bookmarks_menu = 0
"--------------------------------------------------------------
" scratch.vim
"--------------------------------------------------------------
let g:scratch_autohide = 0
let g:scratch_insert_autohide = 0
let g:scratch_height = 0.25
let g:scratch_no_mappings = 1
nmap <F8> <plug>(scratch-insert-reuse)
xmap <F8> <plug>(scratch-selection-reuse)
"--------------------------------------------------------------
" lightline
"--------------------------------------------------------------
" mode is shown in statusline
set noshowmode
" g:lightline {{{
let g:lightline = {
  \   'colorscheme': has('gui_running') ? 'wombat' : &term == 'win32' ? 'default' : 'ChocolateLiquor',
  \   'active': {
  \     'left': [['mymode'], ['myfilename', 'readonly', 'mymodified']],
  \     'right': [['mylineinfo'], ['mysetinfo'], ['myplugininfo']]
  \   },
  \   'component': {
  \     'mylineinfo': '%4l/%L,%-5.(%c%V%)'
  \   },
  \   'component_function': {
  \     'mymode': 'LightlineMode',
  \     'myfilename': 'LightlineFilename',
  \     'mytabinfo': 'LightlineTabInfo',
  \     'mymodified': 'LightlineModified',
  \     'mysetinfo': 'LightlineSetInfo',
  \     'myplugininfo': 'LightlinePluginInfo',
  \     'mycocstatus': 'LightlineCocStatus',
  \   },
  \   'enable': { 'tabline': 0 },
  \ }
"}}}
if s:enable_coc
  call add(g:lightline.active.left[1], 'mycocstatus')
endif
let g:lightline.inactive = g:lightline.active
function! LightlineCocStatus() "{{{
  return g:actual_curbuf == bufnr("%") ? coc#status() : ''
endfunction
"}}}
function! LightlineFilename() "{{{
  if &buftype == 'quickfix'
    return exists('w:quickfix_title') ? w:quickfix_title : ''
  endif
  let fname = expand('%:t')
  if '' == fname
    return &ft == 'yggdrasil' ? '[TreeView]' : '[No Name]'
  elseif &buftype == 'nofile' && exists('b:tempbuffer_title')
    return lightline#concatenate([fname, b:tempbuffer_title], 0)
  else
    return fname == '_GoToFile_Result_' ? lightline#concatenate([fname, gotofile#get_status_string()], 0) : expand('%:~:.')
  endif
endfunction
"}}}
function! LightlineMode() "{{{
  if &buftype == 'quickfix'
    return getwininfo(win_getid(winnr()))[0].loclist != 0 ? 'Location List' : 'Quickfix List'
  endif
  return winwidth(0) < 40 || (!&ma && &bt != 'terminal') ? '' : lightline#mode()
endfunction
"}}}
function! LightlineTabInfo() "{{{
  return printf('%s:%d:%d%s', (&et?'spaces':'tabs'), &sw, &ts, (&sts?':'.&sts:''))
endfunction
"}}}
function! LightlineModified() "{{{
  return &mod && &bt != 'nowrite' && &bt != 'nofile' && &bt != 'terminal' ? '[+]' : ''
endfunction
"}}}
function! LightlineSetInfo() "{{{
  if winwidth(0) < 40 || !&ma
    return ''
  endif

  let info = []
  if &iminsert == 1
    if exists('b:keymap_name') && !empty(b:keymap_name)
      call add(info, printf('<%s>', b:keymap_name))
    elseif !empty(&keymap)
      call add(info, printf('<%s>', &keymap)
    else
      call add(info, '<lang>')
    endif
  endif

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

  call add(info, LightlineTabInfo())

  let enc = &fenc!=#""?&fenc:&enc
  if winwidth(0) < 100
    if &ff != 'unix'
      call add(info, &ff)
    endif

    if enc != 'utf-8'
      call add(info, enc)
    endif

    if &ft != ''
      call add(info, &ft)
    endif
  else
    call extend(info, [&ff, enc, &ft != '' ? &ft : 'no ft'])
  endif

  return lightline#concatenate(info, 1)
endfunction
"}}}
function! LightlinePluginInfo() "{{{
  if exists('*gutentags#statusline')
    return gutentags#statusline('[updating:',  ']')
  else
    return ''
  endif
endfunction
"}}}
"
if exists('*lightline#update')
  augroup Vimrc
    au FileType netrw call lightline#update()
  augroup END
endif
"--------------------------------------------------------------
" ultisnips
"--------------------------------------------------------------
let g:UltiSnipsListSnippets = "<Leader><Tab>"
"--------------------------------------------------------------
" gutentags
" reference: http://www.skywind.me/blog/archives/2084
"--------------------------------------------------------------
let g:gutentags_enabled = 0
let g:gutentags_modules = ['ctags', 'cscope']
let g:gutentags_project_root = s:root_pattern
let g:gutentags_exclude_filetypes = ['', 'vim', 'text']
let g:gutentags_file_list_command = 'gutentags_show_file_list'
if exists('g:vim_resources_dir') && !empty(g:vim_resources_dir)
  let $VIM_RESOURCE_DIR = g:vim_resources_dir
  let g:gutentags_cache_dir = expand(g:vim_resources_dir . '/tags')
endif
let g:gutentags_define_advanced_commands = 1
let g:gutentags_ctags_extra_args = ['--fields=+niazS', '--extra=+q']
let g:gutentags_ctags_extra_args += ['--c++-kinds=+px']
let g:gutentags_ctags_extra_args += ['--c-kinds=+px']
let g:gutentags_cscope_build_inverted_index = 1

if exists('*lightline#update')
  augroup MyGutentagsStatusLineRefresher
    autocmd!
    autocmd User GutentagsUpdating call lightline#update()
    autocmd User GutentagsUpdated call lightline#update()
  augroup END
endif
"--------------------------------------------------------------
" indentLine
"--------------------------------------------------------------
let g:indentLine_bufTypeExclude = ['help', 'terminal', 'prompt', 'popup']
let g:indentLine_bufNameExclude = ['[FileExplorer]<*>']
"--------------------------------------------------------------
" signify
"--------------------------------------------------------------
let g:signify_disable_by_default = 1
autocmd User SignifyAutocmds
      \ exe 'au! signify' | au signify BufWritePost * call sy#start()
"--------------------------------------------------------------
" ale
"--------------------------------------------------------------
let g:ale_linters_explicit = 1
let g:ale_linters = {
      \  'c': ['cppcheck'],
      \  'cpp': ['cppcheck'],
      \ }
" only run linters on save
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_enter = 0
let g:ale_c_cppcheck_options = '--enable=all'
let g:ale_cpp_cppcheck_options = '--enable=all'
"--------------------------------------------------------------
" asyncrun.vim
"--------------------------------------------------------------
let g:asyncrun_open = 6
let g:asyncrun_bell = 1
"--------------------------------------------------------------
" coc.nvim
"--------------------------------------------------------------
if s:enable_coc
	function! s:CocSetConfig()
    let languageserver = {
          \   "ccls": {
          \     "command": "ccls",
          \     "filetypes": ["c", "cpp", "objc", "objcpp"],
          \     "rootPatterns": s:root_pattern,
          \     "initializationOptions": {}
          \   }
          \ }
    if exists('g:vim_resources_dir') && !empty(g:vim_resources_dir)
      let languageserver.ccls.initializationOptions['cache'] = { "directory": expand(g:vim_resources_dir . '/ccls-cache') }
    endif
    " https://github.com/MaskRay/ccls/wiki/Install#clang-resource-directory
    let clang_resources = glob(g:MYVIMRUNTIME . '/local/lib/clang/*', 0, 1)
    if !empty(clang_resources)
      let languageserver.ccls.initializationOptions['clang'] = { "resourceDir": expand(clang_resources[0]) }
    endif
    call coc#config('languageserver', languageserver)
    call coc#config('suggest', { 'autoTrigger': 'trigger' })
    call coc#config('coc.preferences', { 'rootPatterns': s:root_pattern })
  endfunction

  call s:CocSetConfig()

  delfunction s:CocSetConfig

  highlight link CocUnderline Underlined
endif

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

function! CocSettingInit()
  if s:enable_coc
    inoremap <silent> <buffer> <expr> <Leader><Tab>
          \ pumvisible() ? "\<C-n>" :
          \ <SID>check_back_space() ? "\<Tab>" :
          \ coc#refresh()
    nmap <silent> <buffer> gd <Plug>(coc-definition)
    nmap <silent> <buffer> gD <Plug>(coc-declaration)
    nmap <silent> <buffer> gi <Plug>(coc-implementation)
    nmap <silent> <buffer> gy <Plug>(coc-type-definition)
    nmap <silent> <buffer> gr <Plug>(coc-references)
    nmap <silent> <buffer> gI <Plug>(coc-diagnostic-info)
    nmap <silent> <buffer> gn <Plug>(coc-diagnostic-next-error)
    nmap <silent> <buffer> gN <Plug>(coc-diagnostic-prev-error)
  endif
endfunction
"--------------------------------------------------------------
" vista.nvim
"--------------------------------------------------------------
let g:vista_default_executive = 'ctags'
if s:enable_coc
  let g:vista_executive_for = {
        \ 'cpp': 'coc',
        \ 'c': 'coc',
        \ 'python': 'coc',
        \ }
endif
let g:vista_icon_indent = ["+", ""]
let g:vista_fold_toggle_icons = ["+", "-"]
let g:vista_sidebar_width = 34
" ignore Unknown form COC
let g:vista_ignore_kinds = ['Unknown']
"--------------------------------------------------------------
" ccls
"--------------------------------------------------------------
let g:ccls_size = 15
let g:ccls_position = 'botright'
let g:ccls_orientation = 'horizontal'
augroup my_yggdrasil
  autocmd!
  autocmd FileType yggdrasil set cursorline
augroup END
"--------------------------------------------------------------
" fzf
"--------------------------------------------------------------
function! s:GetFindFileOpt(opts)
  if exists('g:fzf_disable_preview') && !empty(g:fzf_disable_preview)
    return a:opts
  else
    return fzf#vim#with_preview(a:opts)
  endif
endfunction

function! s:FindFile(opts, bang)
  if exists('g:flist_name') && filereadable(g:flist_name)
    let opts = copy(a:opts)
    let opts['source'] = printf('cat %s', g:flist_name)
    call fzf#run(fzf#wrap(opts), a:bang)
  else
    call fzf#vim#files('', a:opts, a:bang)
  endif
endfunction
command! -bang FindFile call <SID>FindFile(<SID>GetFindFileOpt({}), <bang>0)
let g:fzf_layout = { 'down': '~40%' }
nmap g<F9> <Plug>GoToFileWindow
imap g<F9> <ESC><Plug>GoToFileWindow
nmap <silent> <F9> :<C-U>FindFile<CR>
imap <silent> <F9> <ESC>:<C-U>FindFile<CR>
"--------------------------------------------------------------
" cscope_maps
"--------------------------------------------------------------
if has('nvim-0.9')
lua << EOF
function _G.has_cscope_maps()
  local ok, _ = pcall(require, "cscope_maps")
  return ok
end

local ok, cscope_maps = pcall(require, "cscope_maps")
if ok then
  cscope_maps.setup({
    disable_maps = false
  })
end
EOF
endif
"--------------------------------------------------------------
" Markdown Preview
"--------------------------------------------------------------
if exists('g:mkdp_host_ip') && executable('lemonade')
  function! g:OpenBrowser(url)
    silent exe '!lemonade --host=' . g:mkdp_host_ip 'open' a:url
  endfunction
  let g:mkdp_browserfunc = 'g:OpenBrowser'
endif
let g:mkdp_preview_options = {
    \ 'mkit': {},
    \ 'katex': {},
    \ 'uml': { 'server': (exists('g:mkdp_uml_server') ? g:mkdp_uml_server : ''), 'imageFormat': 'png' },
    \ 'maid': {},
    \ 'disable_sync_scroll': 0,
    \ 'sync_scroll_type': 'middle',
    \ 'hide_yaml_meta': 1,
    \ 'sequence_diagrams': {},
    \ 'flowchart_diagrams': {},
    \ 'content_editable': v:false,
    \ 'disable_filename': 0,
    \ 'toc': {}
    \ }

function! s:MarkdownPreviewToggle()
  MarkdownPreviewToggle
  sleep 1
  redraw!
endfunction

augroup my_mkdp_init
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <silent> <F6> :<C-U>call <SID>MarkdownPreviewToggle()<CR>
  autocmd FileType markdown imap <buffer> <silent> <F6> <C-\><C-O><F6>
augroup END
"--------------------------------------------------------------
" image.nvim
"--------------------------------------------------------------
if has('nvim')
lua << EOF
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua;"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"

local has_kitty_graphics_protocol_support = function()
  return vim.env.WEZTERM_EXECUTABLE ~= nil or vim.env.KITTY_PID ~= nil or
    (vim.env.KONSOLE_VERSION ~= nil and tonumber(vim.env.KONSOLE_VERSION) >= 220400)
end

if has_kitty_graphics_protocol_support() then
  local ok, image = pcall(require, "image")
  if ok then
    image.setup({
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          sizing_strategy = "auto",
          download_remote_images = true,
          clear_in_insert_mode = true,
        },
        neorg = {
          enabled = true,
          download_remote_images = true,
          clear_in_insert_mode = true,
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
      kitty_method = "normal",
      kitty_tmux_write_delay = 10, -- makes rendering more reliable with Kitty+Tmux
      window_overlap_clear_enabled = false, -- toggles images when windows are overlapped
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    })
  end
end
EOF
endif

" vim: fdm=marker : ts=2 : sw=2 :
