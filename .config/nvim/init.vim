"          ░░
"  ██    ██ ██ ██████████
" ░██   ░██░██░░██░░██░░██
" ░░██ ░██ ░██ ░██ ░██ ░██
"  ░░████  ░██ ░██ ░██ ░██
"   ░░██   ░██ ███ ░██ ░██
"    ░░    ░░ ░░░  ░░  ░░

" leader key
let $LEADER_KEY=","
let mapleader =$LEADER_KEY

" -----------------------------------------------------------------------------
" general settings
" -----------------------------------------------------------------------------

" generals
let $RTP=split(&runtimepath, ',')[0]
let $RC="$RTP/init.vim"
set updatetime=750
set nocompatible
set hidden
set go=a
set mouse=a
syntax on
filetype plugin indent on
set noswapfile
set encoding=utf-8
set nohlsearch
set autoindent smartindent
set backspace=start,eol,start

" console settings
set cmdheight=2

""line settings
set number relativenumber
set colorcolumn=80
set cursorline
set list listchars=tab:<->,nbsp:%

" tab settings
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
    sil !mkdir -p $RTP/autoload/
    sil !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > $RTP/autoload/plug.vim
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
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-surround'

" == themes
Plug 'gruvbox-community/gruvbox'
Plug 'vim-airline/vim-airline-themes'
call plug#end()

" == theming/appearance
" gruvbox
colorscheme gruvbox
set background=dark
let g:gruvbox_contrast_dark = 'hard'

" airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='powerlineish'

" == which key
nn <silent><leader> :WhichKey $LEADER_KEY<CR>
nn <silent><Space> :WhichKey ''<CR>

" timeout
set timeoutlen=200

" separator
let g:which_key_sep = '::'

" hide statusline
au! FileType which_key
au  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

" no floating window
let g:which_key_use_floating_win = 0

" == nerdcommenter
" add space delimiter
let g:NERDSpaceDelims = 1

" keybinds
map <leader>/ <Plug>NERDCommenterToggle

" == fugitive (git)
nm <leader>gs  :G<CR>
nm <leader>gc  :Gcommit<CR>
nm <leader>gl  :Glog<CR>
nm <leader>gps :Gpush<CR>
nm <leader>gpl :Gpull<CR>

" == fzf
nn <C-p> :Files<CR>

" == tagbar
nm <F7> :TagbarToggle<CR>

" == UltiSnips
" <Tab> unavailable if using YCM
let g:UltiSnipsExpandTrigger="<Tab>"
let g:UltiSnipsJumpForwardTrigger="<Tab>"
let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
let g:UltiSnipsEditSplit="vertical"

" == ALE
" only run linters specified at 'ale_linters'
let g:ale_linters_explicit = 1
let g:ale_fixers = {'*': ['remove_trailing_lines', 'trim_whitespace']}

" F12 fixes errors
nm <F9> <Plug>(ale_fix)

" == C.O.C
nm <leader><F2>  <Plug>(coc-rename)
nm <leader><F12> <Plug>(coc-definition)

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
