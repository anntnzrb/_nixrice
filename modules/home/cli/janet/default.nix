{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.janet;
in
{
  options.${namespace}.cli.janet = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { home.packages = [ pkgs.janet ]; };
}
