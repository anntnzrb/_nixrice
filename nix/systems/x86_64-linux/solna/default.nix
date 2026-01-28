{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ ./hardware ];

  ${namespace} = {
    user = on;

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;

    hardware = {
      audio.pipewire = on;
      keyboard.keyd = on;
    };

    network = {
      networkmanager = on;
      ssh = on;
      syncthing = on;
      vpn.mullvad = on;
    };

    common = {
      xorg = on;
      desktop = on;
    };
  };
}
