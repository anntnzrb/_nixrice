import ../../../toggle.nix "shells.bash" (
  { config, ... }:
  let
    shellsCfg = config.liberion.shells;
  in
  {
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
      inherit (shellsCfg) historyIgnore;
    };
  }
)
