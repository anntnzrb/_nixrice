{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.editors.vscode;

in
{
  options.liberion.editors.vscode = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode-fhs;

      # extensions can be installed or updated manually
      mutableExtensionsDir = true;
    };
  };
}
