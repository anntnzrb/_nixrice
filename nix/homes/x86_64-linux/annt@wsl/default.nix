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
      prompt.starship = on;

      bash = on;

      tmux = on;
    };

    cli = {
      git = on // {
        gh = on;
        lazygit = on;
      };

      btop = on;
      bun = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      husky = on;
      repomix = on;
      tldr = on;
      uv = on;
      yt-dlp = on;
      zoxide = on;

      llmAgents = {
        chutes = on;
        claude-code = on;
        codex = on;
        crush = on;
        gemini = on;
        mods = on;
        opencode = on;
        qwen = on;
      };
    };

    editors = {
      neovim = on;
    };
  };
}
