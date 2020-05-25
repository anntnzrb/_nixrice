"   █████
"  ██░░░██
" ░██  ░░
" ░██   ██
" ░░█████
"  ░░░░░

" .h files ac C instead of cpp
autocmd BufRead,BufNewFile *.h set filetype=c

" printf()
autocmd FileType c inoremap !printf printf("\n", +===+);<ESC>F\i

"     ██
"    ░░
"     ██  ██████   ██    ██  ██████
"    ░██ ░░░░░░██ ░██   ░██ ░░░░░░██
"    ░██  ███████ ░░██ ░██   ███████
"  ██░██ ██░░░░██  ░░████   ██░░░░██
" ░░███ ░░████████  ░░██   ░░████████
"  ░░░   ░░░░░░░░    ░░     ░░░░░░░░

" System.out.printf()
autocmd FileType java inoremap !printf System.out.printf("%n", +===+);<ESC>F%i

"Scanner scanf = new Scanner(System.in)
autocmd FileType java inoremap !scanner Scanner scanf = new Scanner(System.in);

"           ██
"          ░░
"  ██    ██ ██ ██████████
" ░██   ░██░██░░██░░██░░██
" ░░██ ░██ ░██ ░██ ░██ ░██
"  ░░████  ░██ ░██ ░██ ░██
"   ░░██   ░██ ███ ░██ ░██
"    ░░    ░░ ░░░  ░░  ░░

" comment/uncomment in vim
autocmd FileType vim nnoremap <leader>/ <Esc>I"<Space><ESC>
autocmd FileType vim nnoremap <leader>? <Esc>:s/"\s<Esc>

"              ██
"             ░░
"  ██████████  ██  ██████  █████
" ░░██░░██░░██░██ ██░░░░  ██░░░██
"  ░██ ░██ ░██░██░░█████ ░██  ░░
"  ░██ ░██ ░██░██ ░░░░░██░██   ██
"  ███ ░██ ░██░██ ██████ ░░█████
" ░░░  ░░  ░░ ░░ ░░░░░░   ░░░░░

" script that cleans build files whenever vim buffer is closed
autocmd VimLeave *.tex,*.java !clean-build %

" comment/uncomment in c*/java
autocmd FileType c,cpp,java nnoremap <leader>/ <Esc>I/*<Space><ESC>A<Space>*/<Esc>
autocmd FileType c,cpp,java nnoremap <leader>? <Esc>:s/\/\*\s<Esc>:s/\s\*\/<Esc>

" comment/uncomment in shell/python
autocmd FileType sh,zsh,python nnoremap <leader>/ <Esc>I#<Space><ESC>
autocmd FileType sh,zsh,python nnoremap <leader>? <Esc>:s/#\s<Esc>
