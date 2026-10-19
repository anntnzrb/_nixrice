{ config, ... }:
let
  cfg = config.liberion.shells;
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    autosuggestion.enable = true;
    # Widgets defined after startup stay unwrapped until _zsh_autosuggest_bind_widgets runs.
    localVariables.ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
    syntaxHighlighting.enable = true;

    completionInit = ''
      autoload -Uz compinit bashcompinit
      zmodload -F zsh/stat b:zstat
      () {
        local dump=$ZDOTDIR/.zcompdump
        local -a dirs=(''${^''${fpath:A}:#/nix/store/*}(N/)) mtimes
        (( $#dirs )) && zstat -A mtimes +mtime -- $dirs
        local key="$ZSH_VERSION ''${fpath:A} $mtimes"
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
      ignorePatterns = cfg.historyIgnore;
    };
  };
}
