{ lib
, inputs
, modulesPath
, ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    inputs.nixos-hardware.nixosModules.common-pc-ssd

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
        options = [ "commit=120" "discard=async" "noatime" "space_cache=v2" "ssd" ];
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
