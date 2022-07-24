" editing.vim

" identation
let s:NUM_SPACES_TABS = 4
set expandtab " always spaces instead of tabs
set smartindent
let &softtabstop = s:NUM_SPACES_TABS
let &shiftwidth  = s:NUM_SPACES_TABS
let &tabstop     = s:NUM_SPACES_TABS
