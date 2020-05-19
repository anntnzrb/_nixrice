"           ██
"          ░░
"  ██    ██ ██ ██████████
" ░██   ░██░██░░██░░██░░██
" ░░██ ░██ ░██ ░██ ░██ ░██
"  ░░████  ░██ ░██ ░██ ░██
"   ░░██   ░██ ███ ░██ ░██
"    ░░    ░░ ░░░  ░░  ░░

let mapleader =","

if ! filereadable(expand('~/.config/nvim/autoload/plug.vim'))
	echo "downloading vim-plug plugin manager..."
	silent !mkdir -p ~/.config/nvim/autoload/
	silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ~/.config/nvim/autoload/plug.vim
	autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.config/nvim/plugged')
Plug 'PotatoesMaster/i3-vim-syntax'
Plug 'ap/vim-css-color'
Plug 'bling/vim-airline'
Plug 'dense-analysis/ale'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install'  }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'
Plug 'kovetskiy/sxhkd-vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'preservim/nerdtree'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline-themes'
"" themes
Plug 'franbach/miramare'
Plug 'morhetz/gruvbox'
call plug#end()

set go=a
set mouse=a
set nohlsearch
set clipboard+=unnamedplus

"" miramare
set termguicolors
colorscheme miramare
set background=dark

"" general:
	syntax on
	filetype plugin on
	nnoremap c "_c
    set hidden
    set noswapfile
	set encoding=utf-8
	set nocompatible
	set number relativenumber
	set tabstop=4 softtabstop=0 expandtab shiftwidth=4 smarttab
    set colorcolumn=80

" shortcutting split navigation
	map <C-h> <C-w>h
	map <C-j> <C-w>j
	map <C-k> <C-w>k
	map <C-l> <C-w>l

" this allows to jump thru these: '+===+'
	nnoremap <Space><Space> <Esc>/+===+<CR>"_c5l

" force reload buffer
	nmap <F5> :edit!<CR>

" swap `ex mode` from Q to gq (probably most retarded default keybind in vim)
	map Q gq

" autocompletion
	set wildmode=longest,list,full

" disable auto commenting on \n
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" spell-check set to <leader>o, 'o' for 'orthography'
	map <leader>o :setlocal spell! spelllang=en_us,es<CR>

" splits open at the bottom and right
	set splitbelow splitright

" replace all aliased to `S`
	nnoremap S :%s//g<Left><Left>

" auto delete trailing whitespace and \n's at end of file on save
	autocmd BufWritePre * %s/\s\+$//e
	autocmd BufWritepre * %s/\n\+\%$//e

" airline
    let g:airline#extensions#tabline#enabled = 1
    let g:airline_theme='solarized_flood'

" Goyo
	map <leader>g :Goyo \| set bg=light \| set linebreak<CR>

" limelight
	" colors
	let g:limelight_conceal_ctermfg = 'gray'
	" goyo integration
	autocmd! User GoyoEnter Limelight
	autocmd! User GoyoLeave Limelight!

" markdown
	" live preview
	nmap <leader>md <Plug>MarkdownPreviewToggle
	" refresh when save or leave insert mode
	let g:mkdp_refresh_slow = 1

" Nerd tree
	map <leader>n :NERDTreeToggle<CR>
    let NERDTreeShowHidden=1

" coc
	nmap <leader>gd <Plug>(coc-definition)
	nmap <leader>gr <Plug>(coc-references)

" fzf
	map <leader>f :Files<CR>

" ALE

" F11 checks errors
  nmap <F11> <Plug>(ale_lint)

" F12 fixes errors
  nmap <F12> <Plug>(ale_fix)

" linters
let g:ale_linters = {
\   'c': ['clang'],
\   'java': ['javac'],
\   'python': ['flake8'],
\   'sh': ['shellcheck'],
\}

" fixers
let g:ale_fixers = {
\   'c': ['uncrustify'],
\   'java': ['uncrustify'],
\   'python': ['black'],
\   'sh': ['shfmt'],
\   'markdown': ['prettier'],
\}

"" file specific:
" compile document
	map <leader>c :w! \| :10new \| :term compiler <c-r>%<CR>

" save file as sudo
	cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

" source xrdb whenever Xdefaults / Xresources are updated.
	autocmd BufWritePost *Xresources,*Xdefaults !xrdb %

" source sxhkd whenever Xdefaults / Xresources is updated
	autocmd BufWritePost *sxhkdrc !pkill -USR1 sxhkd

"" source external configs
let cfgs = [
\  "languages",
\]
for file in cfgs
	let x = expand("~/.config/nvim/lib/".file.".vim")
        if filereadable(x)
		execute 'source' x
	endif
endfor
