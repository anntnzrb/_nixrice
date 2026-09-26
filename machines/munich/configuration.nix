{ inputs, config, ... }: {
  imports = with inputs.self.nixosModules; [
    ./hardware
    disko-xfs # whole NVMe; no more dual-boot
    docker
    essentials
    fish
    intel-cpu
    nvidia
    systemd-boot
    tailscale
    virt-manager
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "26.05";

  # GTX 1080 (Pascal): dropped by the default driver branch
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580;

  networking = {
    defaultGateway = {
      address = "192.168.100.1";
      interface = "enp4s0";
    };
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
