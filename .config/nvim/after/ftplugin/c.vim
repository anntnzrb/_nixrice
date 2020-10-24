"   █████
"  ██░░░██
" ░██  ░░
" ░██   ██
" ░░█████
"  ░░░░░

" .h files ac C instead of cpp
au BufRead,BufNewFile *.h set filetype=c

" [scrooloose/nerdcommenter]
let g:NERDCustomDelimiters = { 'c': { 'left': '/*','right': '*/' } }

" [dense-analysis/ale]
let g:ale_fixers = {'c': ['uncrustify']}

" [majutsushi/tagbar]
au BufEnter * TagbarToggle
