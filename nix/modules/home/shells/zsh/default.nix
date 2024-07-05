{ config
, lib
, namespace
, ...
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
      enableCompletion = true;
      enableVteIntegration = true;
      dotDir = ".config/zsh";

      autosuggestion = {
        enable = true;
        highlight = "fg=#ff00ff,bg=cyan,bold,underline";
      };

      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
        ];
      };

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
