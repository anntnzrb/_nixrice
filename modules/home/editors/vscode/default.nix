{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  cfg = config.${namespace}.editors.vscode;

in
{
  options.${namespace}.editors.vscode = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      inherit (cfg) enable;

      package = if isDarwin then null else pkgs.vscode;

      # extensions can be installed or updated manually
      mutableExtensionsDir = true;
    };

    home.packages = [ pkgs.victor-mono ];
  };
}
