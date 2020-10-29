" launch startify (obliterates current buffer)
nm <leader>www :bd\|Startify<CR>

" use unicode
let g:startify_fortune_use_unicode = 1

" lists
let g:startify_lists = [
    \ { 'type': 'bookmarks', 'header': ['   Bookmarks'] },
    \ { 'type': 'files',     'header': ['   Recent']    },
    \ { 'type': 'commands',  'header': ['   Commands']  },
    \ ]

" bookmarks
let g:startify_bookmarks = [
    \ { 'v': '' . fnamemodify(expand("$RTP"), ':~') },
    \ { 'z': '' . fnamemodify(expand("$ZDOTDIR/.zshrc"), ':~') },
    \ ]
