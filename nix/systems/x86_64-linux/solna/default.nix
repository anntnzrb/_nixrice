{
  lib,
  namespace,
  ...
}:
{
  imports = [ ./hardware ];

  time.timeZone = "America/Guayaquil";

  ${namespace} = with lib.${namespace}; {
    user = {
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoPWVoRBmvoWF445a0vTnV2ASk+5Gy/XDTEPPjEDd8/ git"
      ];
    };

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
