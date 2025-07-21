{ lib, namespace, ... }:
let
  inherit (lib.${namespace}.module) on;
in
{
  ${namespace} = {
    shells = {
      sessionVariables = {
        EDITOR = "nvim";
      };
      preliminaryMessage.disable = true;

      bash = {
        enable = true;
        prompt.starship = on;
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
  };
}
