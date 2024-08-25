{ lib
, namespace
, ...
}:

with lib.${namespace}; {
  liberion = {
    shells = {
      defaults = on;
      altCoreUtils = on;

      sessionVariables = {
        EDITOR = "nvim";
      };

      bash = {
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
      simple-mtpfs = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };
  };
}
