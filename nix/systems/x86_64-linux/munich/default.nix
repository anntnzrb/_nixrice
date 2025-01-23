{
  lib,
  namespace,
  ...
}:
{
  imports = [ ./hardware ];

  time = {
    timeZone = "America/Guayaquil";
    hardwareClockInLocalTime = true; # dual-boot
  };

  ${namespace} = with lib.${namespace}; {
    # GRUB because of dual-boot
    boot.bootloader.grub = on;

    hardware = {
      audio.pipewire = on;
      keyboard.keyd = on;
    };

    network = {
      networkmanager = on;
      syncthing = on;
      vpn.mullvad = on;
    };

    virtualisation = {
      docker = on;
      virtualbox = off;
      virt-manager = on;
    };

    common = {
      xorg = on;
      desktop = on;
    };
  };

  networking = {
    defaultGateway = "192.168.100.1";
    enableIPv6 = false;
    nameservers = [
      "216.199.54.9"
      "207.170.7.6"
    ];
    interfaces.enp4s0 = {
      mtu = 1500;
      ipv4.addresses = [
        {
          address = "192.168.100.110";
          prefixLength = 24;
        }
      ];
    };
  };
}
