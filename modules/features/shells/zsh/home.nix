{ config, ... }:
let
  shellsCfg = config.liberion.shells;
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.xdg.dataHome}/zsh_history";
      extended = true;
      size = 5000;
      ignorePatterns = shellsCfg.historyIgnore;
    };
  };
}
