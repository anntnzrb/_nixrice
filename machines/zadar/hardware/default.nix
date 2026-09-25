{ inputs, modulesPath, ... }:
let
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
  ++ [
    ./cpu.nix
    ./gpu.nix
    ./kernel.nix
  ];

  fileSystems."/".options = [
    "commit=120"
    "noatime"
  ];

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
