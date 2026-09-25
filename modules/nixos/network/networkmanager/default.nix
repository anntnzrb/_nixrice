{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled';

  cfg = config.liberion.network.networkmanager;
in
{
  options.liberion.network.networkmanager = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = false;

    networking.networkmanager = { inherit (cfg) enable; };
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  };
}
