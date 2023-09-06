{
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib.liberion) on;
in {
  home.stateVersion = "23.05";

  liberion = {
    user.username = "annt";

    desktop = {
      discord = on;
      feh = on;
      flameshot = on;
      fonts = on;
      mpv = on;
      pcmanfm = on;
      picom = on;
      redshift = on;
      rofi = on;
      sxhkd = on;
      window-manager.awesome = on;

      browser = {
        firefox = on;
      };

      themes = {
        enable = true;
      };
    };

    shell = {
      bash = on;
      fish = on;
    };

    cli = {
      direnv = on;
      neofetch = on;
      rust-utils = on;
      starship = on;
    };

    editor = {
      emacs = on;
      neovim = on;
      vscode = on;
    };
  };
}
