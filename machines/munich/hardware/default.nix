{
  lib,
  inputs,
  modulesPath,
  ...
}:
let
  inherit (lib.liberion.module) on;
  inherit (lib.liberion.fs) getModuleFiles;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ../../hardware-common.nix
  ]
  ++ getModuleFiles { path = ./.; };

  fileSystems."/".options = [
    "commit=120"
    "discard=async"
    "noatime"
    "space_cache=v2"
    "ssd"
  ];

  zramSwap = on // {
    algorithm = "zstd";
    memoryPercent = 40; # ~12GB
  };
}
