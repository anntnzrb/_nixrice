" mappings
nn <silent><leader> :WhichKey mapleader<CR>
nn <silent><Space>  :WhichKey ''<CR>

" separator
let g:which_key_sep = '::'

" hide statusline
au! FileType which_key
au  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler

" no floating window
let g:which_key_use_floating_win = 0
