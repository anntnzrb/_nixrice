{ inputs, modulesPath, ... }:
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
    inputs.self.nixosModules.btrfs-labels
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
    memoryPercent = 50; # ~4GB
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };
}
