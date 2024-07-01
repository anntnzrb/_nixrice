{ pkgs
, lib
, ...
}:

with lib.liberion; {
  liberion = {
    shells = {
      defaults = on;
      altCoreUtils = on;
      bash = on;
    };

    cli = {
      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      git = on;
      starship = on;
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
