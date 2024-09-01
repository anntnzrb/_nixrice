{ lib
, pkgs
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

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHoPWVoRBmvoWF445a0vTnV2ASk+5Gy/XDTEPPjEDd8/ git"
        ];
      };

      time.timeZone = "America/Guayaquil";
    };

    # no dual-boot. systemd-boot suffices
    boot.bootloader.systemd-boot = on;

    hardware = {
      keyboard.keyd = on;
    };

    network = {
      networkmanager = on;
      ssh = on;
    };
  };

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";
}
