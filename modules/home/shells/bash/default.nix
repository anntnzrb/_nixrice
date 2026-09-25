{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.shells.bash;
  shellsCfg = config.liberion.shells;
in
{
  options.liberion.shells.bash = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      inherit (cfg) enable;

      enableCompletion = true;
      shellOptions = [
        "cdspell"
        "checkwinsize"
        "cmdhist"
      ];

      historyControl = [
        "erasedups"
        "ignoredups"
        "ignorespace"
      ];
      historyFile = "${config.xdg.dataHome}/bash_history";
      historyFileSize = 1000 * 1000;
      historySize = 100 * 100;
      inherit (shellsCfg) historyIgnore;
    };
  };
}
