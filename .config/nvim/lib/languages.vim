"   █████
"  ██░░░██
" ░██  ░░
" ░██   ██
" ░░█████
"  ░░░░░

" .h files ac C instead of cpp
autocmd BufRead,BufNewFile *.h set filetype=c

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
