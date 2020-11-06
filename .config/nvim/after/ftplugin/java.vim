"     ██
"    ░░
"     ██  ██████   ██    ██  ██████
"    ░██ ░░░░░░██ ░██   ░██ ░░░░░░██
"    ░██  ███████ ░░██ ░██   ███████
"  ██░██ ██░░░░██  ░░████   ██░░░░██
" ░░███ ░░████████  ░░██   ░░████████
"  ░░░   ░░░░░░░░    ░░     ░░░░░░░░

" [scrooloose/nerdcommenter]
let g:NERDAltDelims_java = 1

" [dense-analysis/ale]
let g:ale_fixers = {'java': ['uncrustify']}

" [neoclide/coc.nvim]
let g:coc_global_extensions = ['coc-java']

" [majutsushi/tagbar]
au BufEnter * TagbarToggle
