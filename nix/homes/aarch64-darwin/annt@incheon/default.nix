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

      zsh = on;
      preliminaryMessage.disable = true;

      tmux = on;
    };

    cli = {
      git = on // {
        gh = on;
        lazygit = on;
      };

      btop = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      omnix = on;
      tldr = on;
      yazi = on;

      llmAgents = {
        claude-code = on;
        codex = on;
        crush = on;
        droid = on;
        gemini = on;
        goose = on;
        kilo = on;
        opencode = on;
        qwen = on;
      };
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };

    desktop.terminal-emulators.ghostty = on;
  };
}
