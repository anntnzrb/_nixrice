""" c.vim --- configurations for the C programming language

let b:LANG = 'c'

" -----------------------------------------------------------------------------
" ALE
" -----------------------------------------------------------------------------

let b:ale_linters = { b:LANG : ['cc']}
let b:ale_fixers  = { b:LANG : ['uncrustify']}
let g:ale_c_cc_options = '-std=c99 -pedantic -Wall -Wno-deprecated-declarations -Os'
