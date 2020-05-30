"     ██
"    ░░
"     ██  ██████   ██    ██  ██████
"    ░██ ░░░░░░██ ░██   ░██ ░░░░░░██
"    ░██  ███████ ░░██ ░██   ███████
"  ██░██ ██░░░░██  ░░████   ██░░░░██
" ░░███ ░░████████  ░░██   ░░████████
"  ░░░   ░░░░░░░░    ░░     ░░░░░░░░

" System.out.printf()
ino !printf System.out.printf("%n", +===+);<ESC>F%i

"Scanner scanf = new Scanner(System.in)
ino !scanner Scanner scanf = new Scanner(System.in);

" [scrooloose/nerdcommenter]
"TODO
let g:NERDCustomDelimiters = { 'java': { 'left': '/* ' } }

" [dense-analysis/ale]
let g:ale_linters = {'java': ['javac']}
let g:ale_fixers = {'java': ['uncrustify']}

" [neoclide/coc.nvim]
let g:coc_global_extensions = ['coc-java']

" [majutsushi/tagbar]
au BufEnter * TagbarToggle
