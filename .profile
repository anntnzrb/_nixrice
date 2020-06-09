# runs on login
# environmental variables are set here.

# adds `~/.local/bin` to $PATH
export PATH="$PATH:$(du "$HOME/.local/bin/" | cut -f2 | paste -sd ':')"

#◦◝◟∘◞◜◦ default programs
export EDITOR="nvim"
export TERMINAL="st"
export BROWSER="brave"
export READER="zathura"
export FILE="pcmanfm"

#◦◝◟∘◞◜◦ ~/ clean-up
export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc-2.0"
export LESSHISTFILE="-"
export INPUTRC="$HOME/.config/inputrc"
export ZDOTDIR="$HOME/.config/zsh"

#◦◝◟∘◞◜◦ other settings
export SUDO_ASKPASS="$HOME/.local/bin/dmenupass"
export _JAVA_AWT_WM_NONREPARENTING=1 # Java apps fix for dwm
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::") &&
    export PATH=$JAVA_HOME/bin:$PATH
# start graphical server on tty1 if not already running.
#[ "$(tty)" = "/dev/tty1" ] && ! pgrep -x Xorg >/dev/null && exec startx
