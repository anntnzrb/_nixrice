{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.cli.chutes;
in
{
  options.${namespace}.cli.chutes = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.${namespace}.chutes ];
  };
}
