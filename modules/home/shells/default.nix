{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.liberion.fs) getModuleFiles;
  inherit (lib.types) attrsOf listOf str;

  cfg = config.liberion.shells;
in
{
  imports = getModuleFiles { path = ./.; };

  options.liberion.shells = {
    sessionVariables = mkOpt' (attrsOf str) { };
    preliminaryMessage.disable = mkOptDisabled';

    prompt.starship.enable = mkOptDisabled';

    # shared history ignore patterns (used by bash/zsh)
    historyIgnore = mkOpt' (listOf str) [
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

  config = {
    liberion.shells.starship = { inherit (cfg.prompt.starship) enable; };

    home = {
      sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

      sessionVariables = {
        NIX_SHELL_PRESERVE_PROMPT = "1";
      }
      // cfg.sessionVariables;

      # disable "Last Login..." preliminary message
      file.".hushlogin" = lib.mkIf cfg.preliminaryMessage.disable { text = ""; };

      packages = with pkgs; [
        dust
        fd
        (ripgrep.override { withPCRE2 = true; })
      ];
    };
  };
}
