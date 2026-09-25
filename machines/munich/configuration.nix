{ inputs, ... }: {
  imports = with inputs.self.nixosModules; [
    ./hardware
    # GRUB because of dual-boot
    grub
    docker
    virt-manager
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  time.hardwareClockInLocalTime = true; # dual-boot

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
