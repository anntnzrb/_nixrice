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

      tmux = on;
    };

    cli = {
      git = {
        enable = true;
        gh = on;
        lazygit = on;
      };

      btop = on;
      claude = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      opencode = on;
      tldr = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };
  };
}
