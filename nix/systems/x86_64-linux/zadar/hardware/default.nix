{ modulesPath, inputs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-laptop-hdd

    ./kernel.nix
    ./cpu.nix
    ./gpu.nix
  ];

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
        options = [
          "commit=120"
          "noatime"
        ];
      };

      "/boot" = {
        device = "/dev/disk/by-label/${bootLabel}";
        label = "${bootLabel}";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };
    };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # ~6GB
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };
}
