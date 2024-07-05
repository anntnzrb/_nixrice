{ lib
, ...
}:

with lib.liberion; {
  liberion = {
    shells = {
      defaults = on;
      altCoreUtils = on;
      zsh = {
        enable = true;
        prompt.starship = on;
      };
    };

    cli = {
      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      git = on;
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

      terminal-emulators.alacritty = on;
    };
  };
}
