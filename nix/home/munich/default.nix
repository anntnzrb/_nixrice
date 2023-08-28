{ self
, me
, hostInfo
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
    "desktop/discord"
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

  imports = sharedImports ++ [
    #
  ];
in
{
  inherit imports;

  home.stateVersion = "23.05";

  nixpkgs = {
    overlays = [ ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = "${hostInfo.user}";
    homeDirectory = "/home/${hostInfo.user}";
  };

  # let home-manager handle itself
  programs.home-manager.enable = true;

  # reload services on switch
  systemd.user.startServices = "sd-switch";
}
