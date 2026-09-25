{
  lib,
  inputs,
  modulesPath,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
  inherit (lib.${namespace}.fs) getModuleFiles;
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
