if !exists('g:loaded_snips') || exists('s:did_vim_snips')
	fini
en
let s:did_vim_snips = 1
let snippet_filetype = 'vim'

" snippets for making snippets :)
exe 'Snipp snip exe "Snipp ${1:trigger}"${2}'
exe "Snipp snipp exe 'Snipp ${1:trigger}'${2}"
exe 'Snipp bsnip exe "BufferSnip ${1:trigger}"${2}'
exe "Snipp bsnipp exe 'BufferSnip ${1:trigger}'${2}"
exe 'Snipp gsnip exe "GlobalSnip ${1:trigger}"${2}'
exe "Snipp gsnipp exe 'GlobalSnip ${1:trigger}'${2}"
exe "Snipp guard if !exists('g:loaded_snips') || exists('s:did_".
	\ "${1:`substitute(expand(\"%:t:r\"), \"_snips\", \"\", \"\")`}_snips')\n\t"
	\ "finish\nendif\nlet s:did_$1_snips = 1\nlet snippet_filetype = '$1'${2}"

exe "Snipp func function! ${1:function_name}(${2}) \n\t${3}\nendfunction"
exe "Snipp for for ${1:i} in ${2:list}\n\t${3}\nendfor"
exe "Snipp wh while ${1:condition}\n\t${2}\nendwhile"
exe "Snipp if if ${1:condition}\n\t${2}\nendif"
exe "Snipp el else\n\t${1}"
exe "Snipp elif elseif ${1:condition}\n\t${2}"
exe "Snipp let let ${1} = ${2}"

exe "Snipp end `snippets#vim#__init__#EndCompl('end', 1)`"
