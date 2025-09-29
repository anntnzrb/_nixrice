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

      bash = on // {
        prompt.starship = on;
      };

      tmux = on;
    };

    cli = {
      git = on // {
        gh = on;
        lazygit = on;
      };

      btop = on;
      bun = on;
      claude = on;
      codex = on;
      crush = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      gemini = on;
      husky = on;
      mods = on;
      opencode = on;
      qwen = on;
      repomix = on;
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
