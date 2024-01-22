{ config
, lib
, ...
}:
let
  cfg = config.liberion.network.dhcp;
in
{
  options.liberion.network.dhcp = {
    enable = lib.mkEnableOption "dhcp";
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = true;
  };
}
