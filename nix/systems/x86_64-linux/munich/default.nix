{ lib
, ...
}: {
  imports = [ ./hardware ];

  liberion = with lib.liberion; {
    nixos = {
      user = {
        name = "annt";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

      time = {
        timeZone = "America/Guayaquil";
        hardwareClockInLocalTime = true; # dual-boot
      };

      user.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoPWVoRBmvoWF445a0vTnV2ASk+5Gy/XDTEPPjEDd8/ git"
      ];
    };

    boot.bootloader.grub = on;

    hardware = {
      audio.pipewire = on;
      keyboard.keyd = on;
    };

    network = {
      ssh = on;
      networkmanager = on;
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
}
