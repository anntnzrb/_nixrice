{ lib
, namespace
, ...
}:

with lib.${namespace}; {
  liberion = {
    shells = {
      defaults = on;
      altCoreUtils = on;
      zsh = {
        enable = true;
        prompt.starship = on;
        zellij = on;
      };
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
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };

    desktop = {
      ui = {
        fonts = on;
      };

      browsers.firefox = {
        enable = true;
        package.install = false;
      };

      terminal-emulators.alacritty = {
        enable = true;
        package.install = false;
      };
    };
  };
}
