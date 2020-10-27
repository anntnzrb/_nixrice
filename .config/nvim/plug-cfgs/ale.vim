" mappings
nm <F9> <Plug>(ale_fix)

" only run linters specified at 'ale_linters'
let g:ale_linters_explicit = 1

" fixer settings
let g:ale_fixers = {'*': ['remove_trailing_lines', 'trim_whitespace']}
