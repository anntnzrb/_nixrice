{
  lib,
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
      enable = true;

      # extensions can be installed or updated manually
      mutableExtensionsDir = true;
    };
  };
}
