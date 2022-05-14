""" keybinds.vim --- binding configurations

" -----------------------------------------------------------------------------
" utilities
" -----------------------------------------------------------------------------

map <C-s> :write<CR>      " save file with 'Ctrl-s'
vmap <silent><Leader>S :'<,'>sort<CR>  " sort in alphabetical order
" shortcut to replace all matches
nmap S :%s//g<Left><Left>

" -----------------------------------------------------------------------------
" miscellaneous
" -----------------------------------------------------------------------------

nmap <silent><Esc><Esc> :nohl<CR> " clears screen after search highlighting
nmap <silent><Leader><F5> :redraw!<CR> " force screen re-draw
" write buffer with elevated priviledges
cno w!! w !sudo tee % >/dev/null

" disable the 'Ex-mode' keybind
map Q <Nop>
