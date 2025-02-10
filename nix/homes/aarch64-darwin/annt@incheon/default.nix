{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  home.packages = with pkgs; [
    aldente
    czkawka
  ];

  liberion = {
    secrets.sops.enable = true;

    shells = {
      sessionVariables.EDITOR = "nvim";

      zsh = {
        enable = true;
        prompt.starship = on;
      };
      preliminaryMessage.disable = true;

      zellij = on;
    };

    cli = {
      git = {
        enable = true;
        lazygit = on;
      };

      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      omnix = on;
      tldr = on;
      yazi = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors.neovim = on;

    desktop = {
      terminal-emulators.ghostty = {
        enable = true;
        package = null; # use brew. darwin pkg is broken
        font = {
          size = 15;
        };
      };

      browsers.firefox.enable = true;
    };
  };
}
