"   █████
"  ██░░░██
" ░██  ░░
" ░██   ██
" ░░█████
"  ░░░░░

" .h files ac C instead of cpp
au BufRead,BufNewFile *.h set filetype=c

" printf()
ino !printf printf("\n", +===+);<ESC>F\i

" [scrooloose/nerdcommenter]
"TODO
let g:NERDCustomDelimiters = { 'c': { 'left': '/* ' } }

" [dense-analysis/ale]
let g:ale_linters = {'c': ['clang']}
let g:ale_fixers = {'c': ['uncrustify']}

" [neoclide/coc.nvim]
let g:coc_global_extensions = ['coc-clangd']

" [majutsushi/tagbar]
au BufEnter * TagbarToggle
