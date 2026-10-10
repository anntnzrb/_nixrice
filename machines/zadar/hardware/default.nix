{ inputs, ... }:
let
  inherit (inputs.nixos-hardware.nixosModules)
    common-pc-laptop
    common-pc-laptop-hdd
    ;
in
{
  imports = [
    common-pc-laptop
    common-pc-laptop-hdd
  ]
  ++ [
    ./cpu.nix
    ./gpu.nix
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  powerManagement.enable = true;
}
