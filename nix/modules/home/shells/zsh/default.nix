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

    zellij = {
      enable = mkOptBool';
      enableZshIntegration = mkOptEnabled';
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

      zellij = {
        inherit (cfg.zellij) enable enableZshIntegration;
      };
    };
  };
}
