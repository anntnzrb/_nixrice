# Makefile --- GNU Makefile

# variables
apps := alacritty \
	awesome \
	bash \
	bin \
	defaults \
	dunst \
	emacs \
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
	scripts \
	shell \
	sxhkd \
	vim \
	xorg \
	zathura \
	zsh

stow_cmd := stow --dir=. --target="${HOME}"

#------------------------------------------------------------------------------

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
