# config.fish --- Fish shell configurations
#
# Code:

# exit if session is not interactive
not status is-interactive; and exit

# ------------------------------------------------------------------------------
# Settings
# ------------------------------------------------------------------------------

# disable greeting
set -U fish_greeting 

# ------------------------------------------------------------------------------
# Package Manager (fisher)
# ------------------------------------------------------------------------------

function fisher_install_pkg
    not functions -q $argv[1]; and fisher install $argv[2]
end

set fisher_file $__fish_config_dir/functions/fisher.fish

# source fisher.fish if exists, else download & source
if test -f $fisher_file
    source $fisher_file
else
    curl -sL 'https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish' \
        | source
    fisher install jorgebucaran/fisher
end

# ------------------------------------------------------------------------------
# Plugins
# ------------------------------------------------------------------------------

## bass <https://github.com/edc/bass>
# use bash/POSIX scripts in fish
fisher_install_pkg bass edc/bass

# ------------------------------------------------------------------------------
# Sourcing
# ------------------------------------------------------------------------------

test -f $HOME/.config/sh/profile && bass source $HOME/.config/sh/profile
test -f $SH_DIR/aliasrc && bass source $SH_DIR/aliasrc
test -f $SH_DIR/functionrc && bass source $SH_DIR/functionrc

# ------------------------------------------------------------------------------

# rtx
command -q 'rtx'; and rtx activate fish | source

# ------------------------------------------------------------------------------
# Prompt
# ------------------------------------------------------------------------------

# keep at last
set -x STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
starship init fish | source
