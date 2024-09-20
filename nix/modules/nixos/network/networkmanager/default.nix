{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.liberion.network.networkmanager;
in
{
  options.liberion.network.networkmanager = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = false;

    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  };
}
