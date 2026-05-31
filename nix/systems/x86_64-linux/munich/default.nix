{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on off;
in
{
  imports = [ ./hardware ];

  time.hardwareClockInLocalTime = true; # dual-boot

  ${namespace} = {
    suites.desktop = on;

    # GRUB because of dual-boot
    boot.bootloader.grub = on;

    virtualisation = {
      docker = on;
      virtualbox = off;
      virt-manager = on;
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
