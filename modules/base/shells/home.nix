{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.liberion.module) mkOpt';
  inherit (lib.types) listOf str;

  ripgrep = pkgs.ripgrep.override { withPCRE2 = true; };
in
{
  imports = [ ./aliases.nix ];

  options.liberion.shells = {
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
    home = {
      sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];

      sessionVariables.NIX_SHELL_PRESERVE_PROMPT = "1";

      # disable "Last Login..." preliminary message
      file.".hushlogin".text = "";

      # grep => rg, the same PCRE2 build that lands on PATH
      shellAliases.grep = "${lib.getExe ripgrep} --color=auto --column --hidden --ignore-case --line-number --with-filename";

      packages = with pkgs; [
        dust
        fd
        ripgrep
      ];
    };
  };
}
