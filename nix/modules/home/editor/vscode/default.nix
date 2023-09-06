{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.editor.vscode;
in {
  options.liberion.editor.vscode = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode-fhs; # non-free

      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;
      # whether extensions can be installed or updated manually or by visual studio code.
      mutableExtensionsDir = true;
    };
  };
}
