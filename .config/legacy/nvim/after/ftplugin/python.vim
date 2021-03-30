""" python.vim --- configurations for the Python programming language

let b:LANG = 'python'

" -----------------------------------------------------------------------------
" ALE
" -----------------------------------------------------------------------------

let b:ale_linters = { b:LANG : ['flake8']}
let b:ale_fixers  = { b:LANG : ['black']}
let g:ale_python_black_options = '--line-length 79'
