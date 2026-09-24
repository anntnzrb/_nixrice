{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.node;
in
{
  options.${namespace}.cli.node.enable = mkOptDisabled';

  config = lib.mkIf cfg.enable { home.packages = [ pkgs.nodejs ]; };
}
