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
      codex = on;
      crush = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      gemini = on;
      mods = on;
      opencode = on;
      qwen = on;
      tldr = on;
      uv = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };
  };
}
