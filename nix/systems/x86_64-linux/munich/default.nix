{ lib, ... }:
{
  imports = [ ./hardware ];

  liberion = with lib.liberion; {
    nixos = {
      user = {
        name = "annt";
        isNormalUser = true;
        extraGroups = [ "wheel" ];

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoPWVoRBmvoWF445a0vTnV2ASk+5Gy/XDTEPPjEDd8/ git"
        ];
      };

      time = {
        timeZone = "America/Guayaquil";
        hardwareClockInLocalTime = true; # dual-boot
      };
    };

    # GRUB because of dual-boot
    boot.bootloader.grub = on;

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
