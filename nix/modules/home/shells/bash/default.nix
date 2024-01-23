{ config
, lib
, ...
}:
let
  cfg = config.liberion.shells.bash;
in
{
  options.liberion.shells.bash = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      enable = true;

      enableCompletion = true;
      shellOptions = [ "cdspell" "checkwinsize" "cmdhist" ];

      historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
      historyFile = "${config.xdg.dataHome}/bash_history";
      historyFileSize = 1000 * 1000;
      historyIgnore = [ "&" "bg" "fg" "exit" "cd" "ls" ];
      historySize = 100 * 100;
    };
  };
}
