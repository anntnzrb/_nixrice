{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.network.networkmanager;
in
{
  options.liberion.network.networkmanager = {
    enable = lib.mkEnableOption "NetworkManager";
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = false;

    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  };
}
