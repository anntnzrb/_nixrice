"   █████
"  ██░░░██
" ░██  ░░
" ░██   ██
" ░░█████
"  ░░░░░

let current_compiler = 'c'
CompilerSet errorformat=%E%f:%l%c:%m

if ! empty(expand(glob("[Mm]akefile")))
  CompilerSet makeprg=make
else
  CompilerSet makeprg=cc\ -std=c99\ -pedantic\ -Wall\ -Wno-deprecated-declarations\ %
endif
