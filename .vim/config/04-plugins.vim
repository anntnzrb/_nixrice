""" plugins.vim --- plugin manager & configurations

" NOTE: some plugins (if not all) need their settings to be set before loading
" them (hence the downloading/loading part at the very end)

" -----------------------------------------------------------------------------
" airline (+themes)
" -----------------------------------------------------------------------------

let g:airline#extensions#tabline#enabled = 1 " enable airline tabs
let g:airline_powerline_fonts = 1            " enable fancy symbols
let g:airline_theme = 'deus'                 " set theme

" -----------------------------------------------------------------------------
" plugin manager (Vim-Plug)
" -----------------------------------------------------------------------------
" this section should go after setting the plugin's settings

" if plugins not installed, install them
if ! filereadable(expand("$RTP/autoload/plug.vim"))
    echo 'downloading vim-plug plugin manager & plugins...'
    sil !mkdir -p "$RTP/autoload/"
    sil !curl -Ss 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' > "$RTP/autoload/plug.vim"
    au VimEnter * PlugInstall
endif

call plug#begin("$RTP/plugged")
"" utilities
Plug 'tpope/vim-surround'

"" aesthetics
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()
