{
  lib,
  inputs,
  modulesPath,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ]
  ++ lib.snowfall.fs.get-non-default-nix-files ./.;

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
          "discard=async"
          "noatime"
          "space_cache=v2"
          "ssd"
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

  zramSwap = on // {
    algorithm = "zstd";
    memoryPercent = 40; # ~12GB
  };
}
