{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOptBool';

  cfg = config.${namespace}.editors.vscode;

in
{
  options.${namespace}.editors.vscode = {
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
