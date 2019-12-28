" =============================================================================
" Filename: autoload/lightline/colorscheme/ChocolateLiquor.vim
" Author: cxanes
" License: MIT License
" Last Change: 2019/12/12 19:07:01.
" =============================================================================

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}
let s:p.normal.left = [ ['black', 'cyan', 'black', 'cyan', 'bold'], ['white', 'blue', 'white', 'blue'] ]
let s:p.normal.right = [ ['black', 'darkcyan', 'black', 'darkcyan'], ['gray', 'darkgray', 'gray', 'darkgray'] ]
let s:p.inactive.right = [ ['black', 'gray', 'black', 'gray'], ['gray', 'darkgray', 'gray', 'darkgray'] ]
let s:p.inactive.left = [ s:p.normal.left[0], ['white', 'darkgray', 'white', 'darkgray'] ]
let s:p.insert.left = [ ['black', 'green', 'black', 'green', 'bold'] ] + s:p.normal.left[1:]
let s:p.insert.right = s:p.normal.right
let s:p.replace.left = [ ['white', 'red', 'white', 'red', 'bold'] ] + s:p.normal.left[1:]
let s:p.visual.left = [ ['black', 'yellow', 'black', 'yellow', 'bold'] ] + s:p.normal.left[1:]
let s:p.normal.middle = [ ['black', 'brown', 'black', 'brown'] ]
let s:p.inactive.middle = [ ['black', 'gray', 'black', 'gray'] ]
let s:p.insert.middle = s:p.normal.middle
let s:p.replace.middle = s:p.normal.middle
let s:p.replace.right = s:p.normal.right
let s:p.normal.error = [ ['darkgray', 'red', 'darkgray', 'red'] ]
let s:p.normal.warning = [ ['darkgray', 'yellow', 'darkgray', 'yellow'] ]

let g:lightline#colorscheme#ChocolateLiquor#palette = lightline#colorscheme#fill(s:p)
