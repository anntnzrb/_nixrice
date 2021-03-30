""" plugins.vim --- plugin manager & configurations

" -----------------------------------------------------------------------------
" ALE
" -----------------------------------------------------------------------------

let g:ale_lint_delay = 750
let g:ale_linters_explicit = 1 " only run explicititely configured linters
let g:ale_echo_msg_error_str   = 'Err'
let g:ale_echo_msg_warning_str = 'Warn'
let g:ale_echo_msg_format      = '[%linter%] %s [%severity%]'
let g:ale_disable_lsp = 1 " disable LSP features as CoC is being used

"" keybinds
" navigate thru issues
nmap <silent><C-k> <Plug>(ale_previous_wrap)
nmap <silent><C-j> <Plug>(ale_next_wrap)

" format
nmap <silent><Leader>cf <Plug>(ale_fix)

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
    echo "downloading vim-plug plugin manager & plugins..."
    sil !mkdir -p "$RTP/autoload/"
    sil !curl "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" > "$RTP/autoload/plug.vim"
    au VimEnter * PlugInstall
endif

call plug#begin("$RTP/plugged")
"" development
Plug 'dense-analysis/ale'

"" utilities
Plug 'tpope/vim-surround'

"" aesthetics
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()
