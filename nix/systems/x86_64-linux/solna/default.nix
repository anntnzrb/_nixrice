{ lib
, ...
}:

{
  imports = [ ./hardware ];

  liberion = with lib.liberion; {
    nixos = {
      user = {
        name = "annt";
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

      time.timeZone = "America/Guayaquil";

      user.authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoPWVoRBmvoWF445a0vTnV2ASk+5Gy/XDTEPPjEDd8/ git"
      ];
    };

    boot.bootloader.systemd-boot = on;

    hardware = {
      audio.pipewire = on;
      keyboard.keyd = on;
    };

    network = {
      networkmanager = on;
      ssh = on;
      syncthing = on;
    };

    common = {
      xorg = on;
      desktop = on;
    };
  };
}
