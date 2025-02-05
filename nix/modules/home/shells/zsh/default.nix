{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.shells.zsh;
in
{
  options.${namespace}.shells.zsh = {
    enable = mkOptBool';

    prompt.starship.enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      dotDir = ".config/zsh";

      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        path = "${config.xdg.dataHome}/zsh_history";
        extended = true;
        size = 5000;
        ignorePatterns = [
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
    };

    ${namespace}.shells = {
      starship = {
        inherit (cfg.prompt.starship) enable;
      };
    };
  };
}
