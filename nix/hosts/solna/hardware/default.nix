{ inputs
, lib
, modulesPath
, ...
}: {
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")

      inputs.nixos-hardware.nixosModules.common-pc-laptop
      inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd

      ./cpu.nix
      ./gpu.nix
      ./kernel.nix
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  fileSystems =
    let
      bootLabel = "NIX-BOOT";
      rootLabel = "NIX-ROOT";
    in
    {
      "/" = {
        device = "/dev/disk/by-label/${rootLabel}";
        label = "${rootLabel}";
        fsType = "btrfs";
        options = [ "commit=120" "noatime" ];
      };

      "/boot" = {
        device = "/dev/disk/by-label/${bootLabel}";
        label = "${bootLabel}";
        fsType = "vfat";
      };
    };

  swapDevices = [ ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };
}
