{ inputs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ../../hardware-common.nix
  ]
  ++ [
    ./cpu.nix
    ./gpu.nix
    ./kernel.nix
  ];

  fileSystems."/".options = [
    "commit=120"
    "discard=async"
    "noatime"
    "space_cache=v2"
    "ssd"
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 40; # ~12GB
  };
}
