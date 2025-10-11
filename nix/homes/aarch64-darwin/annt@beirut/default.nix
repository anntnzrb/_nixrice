{
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  home.packages = with pkgs; [
    aldente
  ];

  liberion = {
    shells = {
      sessionVariables.EDITOR = "nvim";

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
      direnv = on;
      fastfetch = on;
      fzf = on;
      omnix = on;
      tldr = on;
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

    desktop.terminal-emulators.ghostty = on;
  };
}
