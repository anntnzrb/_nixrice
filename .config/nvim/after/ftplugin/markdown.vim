""" markdown.vim --- configurations for the Markdown markup language

let b:LANG = 'markdown'

" -----------------------------------------------------------------------------
" ALE
" -----------------------------------------------------------------------------

let b:ale_linters = { b:LANG : ['markdownlint']}
let b:ale_fixers  = { b:LANG : ['prettier']}
