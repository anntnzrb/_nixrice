"   █████
"  ██░░░██
" ░██  ░░
" ░██   ██
" ░░█████
"  ░░░░░

" general
compiler c

" [scrooloose/nerdcommenter]
let g:NERDCustomDelimiters = { 'c': { 'left': '/*','right': '*/' } }

" [dense-analysis/ale]
let g:ale_fixers = {'c': ['uncrustify']}

" [majutsushi/tagbar]
au BufEnter * TagbarToggle
