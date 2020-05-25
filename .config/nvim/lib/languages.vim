"   █████
"  ██░░░██
" ░██  ░░
" ░██   ██
" ░░█████
"  ░░░░░

" .h files ac C instead of cpp
au BufRead,BufNewFile *.h set filetype=c

" printf()
au FileType c ino !printf printf("\n", +===+);<ESC>F\i

"     ██
"    ░░
"     ██  ██████   ██    ██  ██████
"    ░██ ░░░░░░██ ░██   ░██ ░░░░░░██
"    ░██  ███████ ░░██ ░██   ███████
"  ██░██ ██░░░░██  ░░████   ██░░░░██
" ░░███ ░░████████  ░░██   ░░████████
"  ░░░   ░░░░░░░░    ░░     ░░░░░░░░

" System.out.printf()
au FileType java ino !printf System.out.printf("%n", +===+);<ESC>F%i

"Scanner scanf = new Scanner(System.in)
au FileType java ino !scanner Scanner scanf = new Scanner(System.in);

"           ██
"          ░░
"  ██    ██ ██ ██████████
" ░██   ░██░██░░██░░██░░██
" ░░██ ░██ ░██ ░██ ░██ ░██
"  ░░████  ░██ ░██ ░██ ░██
"   ░░██   ░██ ███ ░██ ░██
"    ░░    ░░ ░░░  ░░  ░░

" comment/uncomment in vim
au FileType vim nn <leader>/ <Esc>I"<Space><ESC>
au FileType vim nn <leader>? <Esc>:s/"\s<Esc>

"              ██
"             ░░
"  ██████████  ██  ██████  █████
" ░░██░░██░░██░██ ██░░░░  ██░░░██
"  ░██ ░██ ░██░██░░█████ ░██  ░░
"  ░██ ░██ ░██░██ ░░░░░██░██   ██
"  ███ ░██ ░██░██ ██████ ░░█████
" ░░░  ░░  ░░ ░░ ░░░░░░   ░░░░░

" script that cleans build files whenever vim buffer is closed
au VimLeave *.tex,*.java !clean-build %

" comment/uncomment in c*/java
au FileType c,cpp,java nn <leader>/ <Esc>I/*<Space><ESC>A<Space>*/<Esc>
au FileType c,cpp,java nn <leader>? <Esc>:s/\/\*\s<Esc>:s/\s\*\/<Esc>

" comment/uncomment in shell/python
au FileType sh,zsh,python nn <leader>/ <Esc>I#<Space><ESC>
au FileType sh,zsh,python nn <leader>? <Esc>:s/#\s<Esc>
