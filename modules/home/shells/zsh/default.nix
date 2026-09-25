{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.shells.zsh;
  shellsCfg = config.liberion.shells;
in
{
  options.liberion.shells.zsh = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      inherit (cfg) enable;
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
  };
}
