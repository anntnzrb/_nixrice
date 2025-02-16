{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.editors.vscode;

in
{
  options.${namespace}.editors.vscode = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      inherit (cfg) enable;

      # extensions can be installed or updated manually
      mutableExtensionsDir = true;
    };

    home.packages = [ pkgs.victor-mono ];
  };
}
