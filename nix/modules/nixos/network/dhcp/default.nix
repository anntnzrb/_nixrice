{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.network.dhcp;
in
{
  options.${namespace}.network.dhcp = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable { networking.useDHCP = true; };
}
