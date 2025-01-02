{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:

{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  home.packages = with pkgs; [
    aldente
    czkawka
  ];

  liberion = with lib.${namespace}; {
    shells = {
      aliases.defaults = on;
      zsh = {
        enable = true;
        prompt.starship = on;
      };

      zellij = on;
    };

    cli = {
      git = {
        enable = true;
        lazygit = on;
      };

      btop = on;
      direnv = on;
      espanso = on;
      fastfetch = on;
      fzf = on;
      omnix = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
      zed = on;
    };

    desktop = {
      terminal-emulators = {
        alacritty = {
          enable = true;
          font.size = 14.0;
        };
        ghostty = {
          enable = true;
          font.size = 16;
        };
      };
      ui = {
        fonts = on;
      };

      browsers.firefox = {
        enable = true;
        package.install = false;
      };

      notesnook = on;
    };
  };
}
