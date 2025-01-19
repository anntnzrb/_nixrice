{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.editors.vscode;

in
{
  options.${namespace}.editors.vscode = with lib.${namespace}; {
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
