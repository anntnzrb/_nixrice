{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.network.networkmanager;
in {
  options.liberion.network.networkmanager = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    networking.networkmanager.enable = true;

    environment.systemPackages = [pkgs.networkmanagerapplet];
  };
}
