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

      fish = on;
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
      bun = on;
      direnv = on;
      fzf = on;
      tldr = on;
      uv = on;
      yazi = on;
      yt-dlp = on;
      zoxide = on;

      # AI
      chutes = on;
      claude = on;
      codex = on;
      crush = on;
      mods = on;
      opencode = on;
      qwen = on;
    };

    editors.neovim = on;

    desktop = {
      browsers.zen = on;
      terminal-emulators.ghostty = on;
    };
  };
}
