" mappings
nm <F9> <Plug>(ale_fix)

" disable ALE's LSP as we are using CoC
let g:ale_disable_lsp = 1

" only run linters specified at 'ale_linters'
let g:ale_linters_explicit = 1

" fixer settings
let g:ale_fixers = {'*': ['remove_trailing_lines', 'trim_whitespace']}
