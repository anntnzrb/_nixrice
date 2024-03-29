{ lib
, ...
}:

with lib.liberion; {
  liberion = {
    shells = {
      defaults = on;
      altCoreUtils = on;

      sessionVariables = {
        EDITOR = "nvim";
      };

      bash = on;
    };

    cli = {
      btop = on;
      direnv = on;
      fzf = on;
      git = on;
      fastfetch = on;
      starship = on;
      tldr = on;
      yt-dlp = on;
    };

    editors = {
      emacs = {
        enable = true;
        pgtk = false;
      };

      neovim = on;
    };
  };
}
