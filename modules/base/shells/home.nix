{
  config,
  lib,
  pkgs,
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

      file.".hushlogin".text = "";

      shellAliases.grep = "${lib.getExe pkgs.gnugrep} --color=auto --ignore-case --line-number --with-filename";

      packages = with pkgs; [
        dust
        fd
        jq
        ripgrep
        yq-go
      ];
    };

    # sessionPath reaches login shells only. systemd user services, and every
    # process they start, read environment.d; ordering after NixOS's
    # 50-systemd-path.conf keeps its PATH assignment from discarding ours.
    xdg.configFile."environment.d/60-local-bin.conf" =
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        { text = "PATH=${config.home.homeDirectory}/.local/bin:\${PATH}\n"; };
  };
}
