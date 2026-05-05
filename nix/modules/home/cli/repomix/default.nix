{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.repomix;
in
{
  options.${namespace}.cli.repomix = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases.repomix = "${lib.getExe pkgs.bun} x repomix@latest --";
  };
}
