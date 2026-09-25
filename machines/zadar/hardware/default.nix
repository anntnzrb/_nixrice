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
  inherit (inputs.nixos-hardware.nixosModules)
    common-pc-laptop
    common-pc-laptop-hdd
    ;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    common-pc-laptop
    common-pc-laptop-hdd
    ../../hardware-common.nix
  ]
  ++ getModuleFiles { path = ./.; };

  fileSystems."/".options = [
    "commit=120"
    "noatime"
  ];

  zramSwap = on // {
    algorithm = "zstd";
    memoryPercent = 50; # ~6GB
  };

  powerManagement = on // {
    cpuFreqGovernor = "performance";
  };
}
