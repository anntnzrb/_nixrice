{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.network.networkmanager;
in
{
  options.${namespace}.network.networkmanager = with lib.${namespace}; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = false;

    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  };
}
