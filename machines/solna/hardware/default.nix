{
  lib,
  inputs,
  modulesPath,
  ...
}:
let
  inherit (lib.liberion.module) on;
  inherit (lib.liberion.fs) getModuleFiles;
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
    ../../hardware-common.nix
  ]
  ++ getModuleFiles { path = ./.; };

  fileSystems."/".options = [
    "commit=120"
    "noatime"
  ];

  zramSwap = on // {
    algorithm = "zstd";
    memoryPercent = 50; # ~4GB
  };

  powerManagement = on // {
    cpuFreqGovernor = "performance";
  };
}
