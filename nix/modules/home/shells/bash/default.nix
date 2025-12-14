{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.shells.bash;
  shellsCfg = config.${namespace}.shells;
in
{
  options.${namespace}.shells.bash = {
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
