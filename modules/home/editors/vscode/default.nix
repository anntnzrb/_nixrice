{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  cfg = config.liberion.editors.vscode;

in
{
  options.liberion.editors.vscode = {
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
