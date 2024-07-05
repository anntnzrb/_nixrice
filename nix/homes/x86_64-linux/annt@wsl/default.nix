{ lib
, namespace
, ...
}:

with lib.${namespace}; {
  ${namespace} = {
    shells = {
      defaults = on;
      altCoreUtils = on;

      sessionVariables = {
        EDITOR = "nvim";
      };

      bash = {
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
      emacs = {
        enable = true;
        pgtk = false;
      };

      neovim = on;
    };
  };
}
