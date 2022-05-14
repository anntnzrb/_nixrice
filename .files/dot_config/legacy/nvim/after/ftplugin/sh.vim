""" sh.vim --- configurations for the sh programming language

let b:LANG = 'sh'

" -----------------------------------------------------------------------------
" ALE
" -----------------------------------------------------------------------------

" linter
let b:ale_linters = { b:LANG : ['shellcheck']}
let g:ale_sh_shellcheck_options = "-ax -o 'all'"
let b:ale_sh_shellcheck_exclusions = 'SC2006'

" formatter
let b:ale_fixers  = { b:LANG : ['shfmt']}
let b:ale_sh_shfmt_options = "-s -p -bn -i '4'"
