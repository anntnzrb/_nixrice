{ inputs, ... }: {
  imports = [
    ./hardware
    inputs.self.nixosModules.systemd-boot
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
