{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.shells.bash;
in
{
  options.${namespace}.shells.bash = with lib.${namespace}; {
    enable = mkOptBool';

    prompt = {
      starship.enable = mkOptBool';
    };
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

    ${namespace}.cli.starship.enable = cfg.prompt.starship.enable;
  };
}
