# Makefile --- GNU Makefile wrapper for ./.files/' Makefile

all:
	printf 'make install --- installs .files\n'
	printf 'make clean   --- removes .files\n'
	printf 'make reload  --- updates .files (re-links)\n'

install:
	@printf 'installing .files...\n'
	make -C './.files/' install

reload:
	@printf 'reloading .files...\n'
	make -C './.files/' reload

clean:
	@printf 'cleaning .files...\n'
	make -C './.files/' clean

.PHONY: all install reload clean
