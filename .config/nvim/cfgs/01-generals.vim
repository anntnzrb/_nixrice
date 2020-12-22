""" generals.vim --- global configurations

" -----------------------------------------------------------------------------
" identation
" -----------------------------------------------------------------------------

let g:NUM_SPACES_TABS = 4
set autoindent smartindent smarttab
set expandtab " always spaces instead of tabs
set cindent   " 'C' style indenting
let &shiftwidth  = NUM_SPACES_TABS
let &softtabstop = &shiftwidth

" -----------------------------------------------------------------------------
" visual settings
" -----------------------------------------------------------------------------

let g:MAX_LINE_CHARS = 80
set cursorline " show horizontal ruler on cursor
let &colorcolumn = MAX_LINE_CHARS
let &textwidth   = &colorcolumn
set list listchars=trail:-,tab:<->,nbsp:%
set number relativenumber
set showmatch " Highlight matching brace
" auto-wrapping
autocmd BufEnter * setlocal formatoptions=jqlt

" -----------------------------------------------------------------------------
" find & replace
" -----------------------------------------------------------------------------

set hlsearch   " highlight all search results
set ignorecase " always case-insensitive
set smartcase
set infercase

" -----------------------------------------------------------------------------
" completion
" -----------------------------------------------------------------------------

set omnifunc=syntaxcomplete#Complete " enable omnicompletion
set completeopt=menuone,longest,preview
set shortmess+=c " reduce verbosity on cmd when completing

" -----------------------------------------------------------------------------
" miscellaneous
" -----------------------------------------------------------------------------

set scrolljump=-20         " lines to scroll when cursor gets off screen
set mouse=a                " enable normie mouse
set path+=**               " extend path
set clipboard+=unnamedplus " clipboard integration for all operations
set autochdir              " automatically cd to opened file's directory
set visualbell             " visual bell over beeping preferred
" delete trailing whitespaces & newlines on save
au BufWritePre * %s/\s\+$//e | %s/\n\+\%$//e
set noswapfile
filetype plugin indent on
syntax on
