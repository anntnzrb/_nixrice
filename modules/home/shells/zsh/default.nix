{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.shells.zsh;
  shellsCfg = config.${namespace}.shells;
in
{
  options.${namespace}.shells.zsh = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      inherit (cfg) enable;
      dotDir = "${config.xdg.configHome}/zsh";

      enableCompletion = true;
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
