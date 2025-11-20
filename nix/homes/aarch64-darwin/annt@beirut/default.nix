{
  lib,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  liberion = {
    shells = {
      sessionVariables.EDITOR = "nvim";

      fish = on // {
        prompt.starship = on;
      };
      zsh = on // {
        prompt.starship = on;
      };
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
      fastfetch = on;
      fzf = on;
      omnix = on;
      tldr = on;
      uv = on;
      yazi = on;
      yt-dlp = on;
      zoxide = on;

      # AI
      claude = on;
      codex = on;
      crush = on;
      mods = on;
      opencode = on;
      qwen = on;
    };

    editors.neovim = on;

    desktop = {
      terminal-emulators.ghostty = on;
      browsers.firefox = on;
    };
  };
}
