"           ██
"          ░░
"  ██    ██ ██ ██████████
" ░██   ░██░██░░██░░██░░██
" ░░██ ░██ ░██ ░██ ░██ ░██
"  ░░████  ░██ ░██ ░██ ░██
"   ░░██   ░██ ███ ░██ ░██
"    ░░    ░░ ░░░  ░░  ░░

" leader key
let mapleader =","

"==============================================================================
" general settings
"==============================================================================

" generals
set nocompatible
set hidden
set go=a
set mouse=a
syntax on
filetype plugin on
set noswapfile
set encoding=utf-8
set nohlsearch
set autoindent
set backspace=indent,eol,start

""line settings
set number
set relativenumber
set colorcolumn=80
set cursorline
set list

" tab settings
set shiftwidth=4
set softtabstop=4
set tabstop=4
set expandtab

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

" save
map <C-s> :w<CR>
" `ex mode` Q -> gq (probably the most retarded default keybind in vim)
map Q gq

" splits open at the bottom and right
set splitbelow splitright

" share clipboard [out/in]side vim
set clipboard+=unnamedplus

" spell checking
map <leader>o :setlocal spell! spelllang=en_us,es<CR>

" this allows to jump thru these: '+===+'
nn <Space><Space> <Esc>/+===+<CR>"_c5l

" replace all aliased to `S`
nn S :%s//g<Left><Left>

" sort in alphabetical order
vnoremap <leader>S :'<,'>!sort -f<CR>

" disable auto commenting on \n
au FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

"==============================================================================
" plugins & settings
"==============================================================================

" if plugins no installed, then install
if ! filereadable(expand('~/.config/nvim/autoload/plug.vim'))
    echo "downloading vim-plug plugin manager & plugins..."
    sil !mkdir -p ~/.config/nvim/autoload/
    sil !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ~/.config/nvim/autoload/plug.vim
    au VimEnter * PlugInstall
endif

call plug#begin('~/.config/nvim/plugged')
Plug 'airblade/vim-gitgutter'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install'  }
Plug 'junegunn/fzf.vim'
Plug 'machakann/vim-highlightedyank'
Plug 'majutsushi/tagbar'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-surround'

" themes
Plug 'gruvbox-community/gruvbox'
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" syntax highlighting
Plug 'PotatoesMaster/i3-vim-syntax'
Plug 'ap/vim-css-color'
Plug 'kovetskiy/sxhkd-vim'

" LSP
Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

"" colorscheme
"" gruvbox
colorscheme gruvbox
set background=dark
let g:gruvbox_contrast_dark = 'hard'

"" airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='powerlineish'

"" nerdtree
map <leader>n :NERDTreeToggle<CR>
let NERDTreeShowHidden = 1
let NERDTreeMinimalUI = 1
au BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"" nerdcommenter
map <leader>/ <Plug>NERDCommenterNested
map <leader>? <Plug>NERDCommenterUncomment
"
" markdown
" live preview
nm <leader>md <Plug>MarkdownPreviewToggle
"refresh when save or leave insert mode
let g:mkdp_refresh_slow = 1

"" fzf
if executable('fzf')
    nn <C-p> :Files<CR>
endif

"" tagbar
nm <F7> :TagbarToggle<CR>

"" ALE
" F12 fixes errors
nm <F12> <Plug>(ale_fix)

"" COC
nmap <leader><F2> <Plug>(coc-rename)
nmap <leader>gd <Plug>(coc-definition)

"==============================================================================
" file specific
"==============================================================================

" compile document
map <leader>c :w! \| :10new \| :term compiler <c-r>%<CR>

" save file as sudo
cno w!! execute 'sil! write !sudo tee % >/dev/null' <bar> edit!

" source xrdb whenever its file is updated
au BufWritePost *Xresources,*Xdefaults !xrdb %

" source sxhkd whenever Xdefaults / Xresources is updated
au BufWritePost *sxhkdrc !pkill -USR1 sxhkd
