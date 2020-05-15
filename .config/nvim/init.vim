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
	echo "Downloading junegunn/vim-plug to manage plugins..."
	silent !mkdir -p ~/.config/nvim/autoload/
	silent !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > ~/.config/nvim/autoload/plug.vim
	autocmd VimEnter * PlugInstall
endif

call plug#begin('~/.config/nvim/plugged')
Plug 'dense-analysis/ale'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app & yarn install'  }
Plug 'junegunn/limelight.vim'
Plug 'junegunn/goyo.vim'
Plug 'scrooloose/nerdtree'
Plug 'ap/vim-css-color'
Plug 'kovetskiy/sxhkd-vim'
Plug 'PotatoesMaster/i3-vim-syntax'
Plug 'tpope/vim-surround'
Plug 'vimwiki/vimwiki'
Plug 'bling/vim-airline'
Plug 'lukesmithxyz/vimling'
call plug#end()

set bg=light
set go=a
set mouse=a
set nohlsearch
set clipboard+=unnamedplus

"" general:
	nnoremap c "_c
	set nocompatible
	filetype plugin on
	syntax on
	set encoding=utf-8
	set number relativenumber

" swap `ex mode` from Q to gq (probably most retarded default keybind in vim)
	map Q gq

" autocompletion
	set wildmode=longest,list,full

" disable auto commenting on \n
	autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" spell-check set to <leader>o, 'o' for 'orthography'
	map <leader>o :setlocal spell! spelllang=en_us<CR>

" splits open at the bottom and right
	set splitbelow splitright

" Goyo
	map <leader>f :Goyo \| set bg=light \| set linebreak<CR>

" limelight
	" colors
	let g:limelight_conceal_ctermfg = 'gray'
	" goyo integration
	autocmd! User GoyoEnter Limelight
	autocmd! User GoyoLeave Limelight!

" Markdown
	" live preview
	nmap <leader>md <Plug>MarkdownPreviewToggle
	" refresh when save or leave insert mode
	let g:mkdp_refresh_slow = 1

" Nerd tree
	map <leader>n :NERDTreeToggle<CR>
	autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" vimling:
	nm <leader>d :call ToggleDeadKeys()<CR>
	imap <leader>d <esc>:call ToggleDeadKeys()<CR>a
	nm <leader>i :call ToggleIPA()<CR>
	imap <leader>i <esc>:call ToggleIPA()<CR>a
	nm <leader>q :call ToggleProse()<CR>

" shortcutting split navigation
	map <C-h> <C-w>h
	map <C-j> <C-w>j
	map <C-k> <C-w>k
	map <C-l> <C-w>l

" replace all aliased to `S`
	nnoremap S :%s//g<Left><Left>

" copy selected text to system clipboard
	vnoremap <C-c> "+y
	map <C-p> "+P

" compile document
	map <leader>c :w! \| !compiler <c-r>%<CR>

" auto delete trailing whitespace and \n's at end of file on save
	autocmd BufWritePre * %s/\s\+$//e
	autocmd BufWritepre * %s/\n\+\%$//e

"" file specific:
" save file as sudo
	cnoremap w!! execute 'silent! write !sudo tee % >/dev/null' <bar> edit!

" source xrdb whenever Xdefaults / Xresources are updated.
	autocmd BufWritePost *Xresources,*Xdefaults !xrdb %

" source sxhkd whenever Xdefaults / Xresources is updated
	autocmd BufWritePost *sxhkdrc !pkill -USR1 sxhkd

"" ALE

" F12 fixes errors
  nmap <F12> <Plug>(ale_fix)

" F11 fixes errors
  nmap <F11> <Plug>(ale_lint)

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
