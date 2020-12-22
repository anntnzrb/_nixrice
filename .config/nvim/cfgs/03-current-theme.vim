""" current-theme.vim --- theme configurations

" -----------------------------------------------------------------------------
" gruvbox
" -----------------------------------------------------------------------------

let g:gruvbox_contrast_dark = 'gray'
let g:gruvbox_italic = 1 " enable italic text
let g:gruvbox_italicize_strings = 1 " enable italic for strings

" -----------------------------------------------------------------------------
" global configuration
" -----------------------------------------------------------------------------
" should be at last as the configs need to be set first

set background=dark
colorscheme gruvbox " preferred theme
