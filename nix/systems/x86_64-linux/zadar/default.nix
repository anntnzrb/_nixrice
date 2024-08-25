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
      syncthing = on;
      vpn.mullvad = on;
    };
  };

  console.font = "${pkgs.terminus_font}/share/fonts/consolefonts/ter-v8n.psf.gz";

  networking = {
    defaultGateway = "192.168.100.1";
    enableIPv6 = false;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    interfaces =
      let
        commonCfg = {
          mtu = 1500;
          ipv4.addresses = [
            {
              address = "192.168.100.202";
              prefixLength = 24;
            }
          ];
        };
      in
      {
        enp4s0 = commonCfg;
        wlp3s0 = commonCfg;
      };
  };
}
