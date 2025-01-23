{
  lib,
  namespace,
  ...
}:
{
  imports = [ ./hardware ];

  time.timeZone = "America/Guayaquil";

  ${namespace} = with lib.${namespace}; {
    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;

    hardware = {
      audio.pipewire = on;
      keyboard.keyd = on;
    };

    network = {
      networkmanager = on;
      syncthing = on;
      vpn.mullvad = on;
    };

    common = {
      xorg = on;
      desktop = on;
    };
  };
}
