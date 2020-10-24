"    ██                  
"   ░██                  
"  ██████  █████  ██   ██
" ░░░██░  ██░░░██░░██ ██ 
"   ░██  ░███████ ░░███  
"   ░██  ░██░░░░   ██░██ 
"   ░░██ ░░██████ ██ ░░██
"    ░░   ░░░░░░ ░░   ░░ 
" 

" ensure all tex files are read properly
au BufRead,BufNewFile *.tex set filetype=tex

" [dense-analysis/ale]
let g:ale_linters = {'tex': ['texlab']}

" [neoclide/coc.nvim]
let g:coc_global_extensions = ['coc-texlab']
