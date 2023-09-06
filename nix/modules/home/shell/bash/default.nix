{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.shell.bash;
in {
  options.liberion.shell.bash = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      shellOptions = ["cdspell" "checkwinsize" "cmdhist"];

      historyControl = ["erasedups" "ignoredups" "ignorespace"];
      historyFile = "${config.xdg.dataHome}/bash_history";
      historyFileSize = 1000 * 1000;
      historyIgnore = ["&" "bg" "fg" "exit" "cd" "ls"];
      historySize = 100 * 100;
    };
  };
}
