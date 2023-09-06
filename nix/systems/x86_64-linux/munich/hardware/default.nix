{
  modulesPath,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    inputs.nixos-hardware.nixosModules.common-pc-ssd

    ./kernel.nix
    ./cpu.nix
    ./gpu.nix
    ./display.nix
  ];

  fileSystems = let
    bootLabel = "NIX-BOOT";
    rootLabel = "NIX-ROOT";
  in {
    "/" = {
      device = "/dev/disk/by-label/${rootLabel}";
      label = "${rootLabel}";
      fsType = "btrfs";
      options = ["commit=120" "discard=async" "noatime" "space_cache=v2" "ssd"];
    };

    "/boot" = {
      device = "/dev/disk/by-label/${bootLabel}";
      label = "${bootLabel}";
      fsType = "vfat";
    };
  };
}
