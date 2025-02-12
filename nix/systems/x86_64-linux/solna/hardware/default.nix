{
  lib,
  inputs,
  modulesPath,
  ...
}:
let
  inherit (inputs.nixos-hardware.nixosModules)
    common-pc-laptop
    common-pc-laptop-ssd
    ;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-pc-laptop
    common-pc-laptop-ssd
  ] ++ lib.snowfall.fs.get-non-default-nix-files ./.;

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
    memoryPercent = 50; # ~4GB
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };
}
