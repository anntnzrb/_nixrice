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
    secrets.sops.enable = true;
    shells = {
      sessionVariables.EDITOR = "nvim";

      bash = {
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
      fastfetch = on;
      fzf = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors.neovim = on;
  };
}
