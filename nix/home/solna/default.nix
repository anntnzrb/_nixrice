{ me
, ...
}:
let
  sharedImports = map (m: "${me.nixHomes}/shared/${m}") [
    "nix"

    "cli/direnv"
    "cli/git"
    "cli/neofetch"
    "cli/rust-utils"
    "cli/starship"

    "desktop/alacritty"
    "desktop/awesome"
    "desktop/chromium"
    "desktop/firefox"
    "desktop/mpv"
    "desktop/pcmanfm"
    "desktop/rofi"
    "desktop/sxhkd"
    "desktop/themes"
    "desktop/xorg"

    "editors/emacs"
    "editors/neovim"
    "editors/vscode"

    "graphics/xorg"

    "global/aliases"

    "fonts"

    "shell/bash"
    "shell/fish"

    # common env
    "env"
  ];
in
{
  imports = [
    ../default.nix
  ] ++ sharedImports;
}
