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
      ssh = on;
      networkmanager = on;
    };

    # refer to hm
    common = {
      xorg = {
        enable = true;
        keyboard = {
          variant = "altgr-intl";
        };
      };

      displays = on;
    };
  };
}
