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
      claude = on;
      codex = on;
      crush = on;
      direnv = on;
      fastfetch = on;
      fzf = on;
      mods = on;
      omnix = on;
      opencode = on;
      qwen = on;
      tldr = on;
      yazi = on;
      yt-dlp = on;
      zoxide = on;
    };

    editors = {
      neovim = on;
    };

    desktop.terminal-emulators.ghostty = on;
  };
}
