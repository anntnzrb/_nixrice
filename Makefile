apps := alacritty \
	bash \
	defaults \
	dunst \
	emacs \
	fonts \
	git \
	htop \
	lib \
	libreoffice \
	mpv \
	neofetch \
	newsboat \
	onedrive \
	pcmanfm \
	picom \
	qutebrowser \
	redshift \
	resources \
	shell \
	sxhkd \
	vim \
	xorg \
	zathura \
	zsh

stow_cmd := stow --dir=. --target="${HOME}" 

all:
	printf 'make install --- installs .files\n'
	printf 'make clean   --- removes .files\n'
	printf 'make reload  --- updates .files (re-links)\n'

install: $(apps)
	@printf 'installing .files...\n'
	$(stow_cmd) -S $^

reload: $(apps)
	@printf 'reloading .files...\n'
	$(stow_cmd) -D $^
	$(stow_cmd) -S $^
	$(stow_cmd) -R $^

clean: $(apps)
	@printf 'cleaning .files...\n'
	$(stow_cmd) -D $^

.PHONY: all install reload clean
