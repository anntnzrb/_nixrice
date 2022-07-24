" visual.vim

let s:MAX_LINE_CHARS = 80

set cursorline " show horizontal ruler on cursor
let &colorcolumn = s:MAX_LINE_CHARS
let &textwidth   = s:MAX_LINE_CHARS
set list
set listchars=trail:-,tab:<->,nbsp:%
set number
set relativenumber
set showmatch " highlight matching brace

" find & replace
set hlsearch   " highlight all search results
set ignorecase " always case-insensitive
set infercase
