{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.network.dhcp;
in
{
  options.${namespace}.network.dhcp = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { networking.useDHCP = true; };
}
