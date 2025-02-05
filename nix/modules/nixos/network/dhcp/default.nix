{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.network.dhcp;
in
{
  options.${namespace}.network.dhcp = {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable { networking.useDHCP = true; };
}
