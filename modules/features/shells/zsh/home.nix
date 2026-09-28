{ config, ... }:
let
  shellsCfg = config.liberion.shells;
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    autosuggestion.enable = true;
    localVariables.ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
    syntaxHighlighting.enable = true;

    completionInit = ''
      autoload -Uz compinit bashcompinit
      () {
        local dump=$ZDOTDIR/.zcompdump key="$ZSH_VERSION ''${fpath:A}"
        if [[ -r $dump.key && "$(<$dump.key)" == "$key" ]]; then
          compinit -C -d $dump
        else
          rm -f $dump $dump.zwc
          compinit -d $dump
          zcompile $dump
          print -r -- $key >| $dump.key
        fi
      }
      bashcompinit
    '';

    history = {
      path = "${config.xdg.dataHome}/zsh_history";
      extended = true;
      size = 5000;
      ignorePatterns = shellsCfg.historyIgnore;
    };
  };
}
