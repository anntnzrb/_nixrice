{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  liberion = {
    shells = {
      sessionVariables.EDITOR = "nvim";
      prompt.starship = on;

      bash = on;
    };

    cli = {
      git = on // {
        lazygit = on;
      };

      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      tldr = on;
      yazi = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors.neovim = on;
  };
}
