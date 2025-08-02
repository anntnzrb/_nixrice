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
    shells = {
      sessionVariables.EDITOR = "nvim";

      zsh = {
        enable = true;
        prompt.starship = on;
      };
      preliminaryMessage.disable = true;

      tmux = on;
    };

    cli = {
      git = {
        enable = true;
        gh = on;
        lazygit = on;
      };

      btop = on;
      claude = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      omnix = on;
      tldr = on;
      yazi = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };

    desktop.terminal-emulators.ghostty = on;
  };
}
