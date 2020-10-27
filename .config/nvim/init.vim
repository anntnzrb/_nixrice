"          ░░
"  ██    ██ ██ ██████████
" ░██   ░██░██░░██░░██░░██
" ░░██ ░██ ░██ ░██ ░██ ░██
"  ░░████  ░██ ░██ ░██ ░██
"   ░░██   ░██ ███ ░██ ░██
"    ░░    ░░ ░░░  ░░  ░░

" leader key
let mapleader=","

" -----------------------------------------------------------------------------
" theme/appearance
" -----------------------------------------------------------------------------

" == gruvbox
" set background=dark
" colorscheme gruvbox
" let g:gruvbox_contrast_dark='gray'
" 
" " enable italic text
" let g:gruvbox_italic=1
" 
" " enable italic for strings
" let g:gruvbox_italicize_strings=1

" == nord
" colorscheme nord
" set background=dark
" 
" " active cursor line number background
" let g:nord_cursor_line_number_background=1
" 
" " bold vertical split
" let g:nord_bold_vertical_split_line=1
" 
" " enable italics
" let g:nord_italic=1
" 
" " comments in italics
" let g:nord_italic_comments=1

" == vulpo
set background=dark
colorscheme vulpo

" -----------------------------------------------------------------------------
" general settings
" -----------------------------------------------------------------------------

" generals
let $RTP=split(&runtimepath, ',')[0]
let $RC=expand("$RTP/init.vim")
set path+=**
set updatetime=750
set timeoutlen=200
set encoding=utf-8
set go=a
set mouse=a
syntax on
filetype plugin indent on
set hidden
set noswapfile
set nohlsearch
set nocompatible
set backspace=start,eol,start

" disable mapping for 'Ex-mode' (best setting by far)
map Q <Nop>

" console settings
set cmdheight=2

""line settings
set number relativenumber
set colorcolumn=80
set cursorline
set list listchars="tab:<->,nbsp:%"

" tab/indent settings
set autoindent smartindent
set expandtab shiftwidth=4 tabstop=4 softtabstop=4

" searching
set ignorecase
set smartcase
set infercase

" accelerated scrolling
set scrolljump=-20

" split navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" redraw screen
nn <leader><F5> :sil redraw!\|:mode\|echo "Screen re-drawn..."<CR>

" save
map <C-s> :w<CR>

" splits open at the bottom and right
set splitbelow splitright

" share clipboard [out/in]side vim
set clipboard+=unnamedplus

" spell checking
map <leader>scen :setlocal spell! spelllang=en_us<CR>
map <leader>sces :setlocal spell! spelllang=es<CR>
map <leader>sct :setlocal spell! spelllang=<CR>

" replace all aliased to `S`
map S :%s//g<Left><Left>

" sort in alphabetical order
vn <leader>S :'<,'>!sort -f<CR>

" disable auto commenting on \n
au FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
" -----------------------------------------------------------------------------
" plugins & settings
" -----------------------------------------------------------------------------

" if plugins not installed, install them
if ! filereadable(expand('$RTP/autoload/plug.vim'))
    echo "downloading vim-plug plugin manager & plugins..."
    sil !mkdir -p "$RTP/autoload/"
    sil !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > "$RTP/autoload/plug.vim"
    au VimEnter * PlugInstall
endif

call plug#begin('$RTP/plugged')
" == syntax highlighting
Plug 'neovimhaskell/haskell-vim'
Plug 'ap/vim-css-color'
Plug 'PotatoesMaster/i3-vim-syntax'
Plug 'kovetskiy/sxhkd-vim'

" == lsp/intellisense/completion/whatever
Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" == git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" == tools
Plug 'SirVer/ultisnips'
Plug 'bling/vim-airline'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'liuchengxu/vim-which-key'
Plug 'machakann/vim-highlightedyank'
Plug 'majutsushi/tagbar'
Plug 'mhinz/vim-startify'
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-surround'

" == themes
Plug 'vim-airline/vim-airline-themes'
call plug#end()

" == source file configurations
let $PLUG_CFGS=expand("$RTP/plug-cfgs/")
for f in split(expand("$PLUG_CFGS/*"))
    exe 'source' f
endfor

" -----------------------------------------------------------------------------
" file specific
" -----------------------------------------------------------------------------

" compile file
nn <leader>c :make<CR>

" open preview .pdf/.html
map <leader>p :!opout <c-r>%<CR><CR>

" save file as sudo
cno w!! exe 'sil write !sudo tee % >/dev/null'\|edit!

" source sxhkd whenever Xdefaults / Xresources is updated
au BufWritePost *sxhkdrc !pkill -USR1 sxhkd
