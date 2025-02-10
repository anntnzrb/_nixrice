{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled';

  cfg = config.${namespace}.network.networkmanager;
in
{
  options.${namespace}.network.networkmanager = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = false;

    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  };
}
