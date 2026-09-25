{ inputs, ... }: {
  imports = [
    ./hardware
    # no dual-boot. systemd-boot suffices
    inputs.self.nixosModules.systemd-boot
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
