{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.shells.zsh;
in
{
  options.${namespace}.shells.zsh = with lib.${namespace}; {
    enable = mkOptBool';

    prompt = {
      starship.enable = mkOptBool';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      dotDir = ".config/zsh";

      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
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

    ${namespace}.cli.starship.enable = cfg.prompt.starship.enable;
  };
}
