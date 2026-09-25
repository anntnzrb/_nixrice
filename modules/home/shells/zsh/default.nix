import ../../../toggle.nix "shells.zsh" (
  { config, lib, ... }:
  let
    inherit (lib.liberion.module) on;
    shellsCfg = config.liberion.shells;
  in
  {
    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      autosuggestion = on;
      syntaxHighlighting = on;

      history = {
        path = "${config.xdg.dataHome}/zsh_history";
        extended = true;
        size = 5000;
        ignorePatterns = shellsCfg.historyIgnore;
      };
    };
  }
)
