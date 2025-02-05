{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.shells.bash;
in
{
  options.${namespace}.shells.bash = {
    enable = mkOptBool';

    prompt.starship.enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;

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
      historyIgnore = [
        "&"
        "ls"
        "cd"
        "cd -"
        "pwd"
        "exit"
        "clear"
        "history"
        "*password*"
        "*secret*"
        "*token*"
      ];
    };

    ${namespace}.shells = {
      starship = {
        inherit (cfg.prompt.starship) enable;
      };
    };
  };
}
