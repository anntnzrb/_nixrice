{ config
, lib
, ...
}:
let
  cfg = config.liberion.network.dhcp;
in
{
  options.liberion.network.dhcp = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = true;
  };
}
