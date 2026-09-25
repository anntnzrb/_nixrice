{ config, lib, ... }:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.network.dhcp;
in
{
  options.liberion.network.dhcp = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable { networking.useDHCP = true; };
}
