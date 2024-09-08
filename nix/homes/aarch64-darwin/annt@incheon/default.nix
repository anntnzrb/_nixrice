{ lib
, pkgs
, inputs
, namespace
, ...
}:

{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  home.packages = with pkgs; [
    aldente
    czkawka
  ];

  liberion = with lib.${namespace}; {
    shells = {
      defaults = on;
      altCoreUtils = on;
      zsh = {
        enable = true;
        prompt.starship = on;
        zellij = {
          enable = true;
          enableZshIntegration = false;
        };
      };
    };

    cli = {
      git = {
        enable = true;
        lazygit = on;
      };

      aider-chat = on;
      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };

    desktop = {
      terminal-emulators.alacritty = on;
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
