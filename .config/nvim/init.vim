""" init.vim --- main configuration file for [n]Vi[m]

" the leader key
let mapleader = ","

" set RTP to personal config (~/.config/nvim)
let $RTP=split(&runtimepath, ',')[0]

""" source vim files
"" this configuration is split in separate files, source '.vim' files

let g:CFG_FILES = globpath($RTP, 'cfgs/*.vim', 0, 1)
for cfgf in CFG_FILES | exe 'source' cfgf | endfor
