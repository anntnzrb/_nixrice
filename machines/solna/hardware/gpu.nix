{ inputs, lib, ... }:
let
  inherit (lib.liberion.module) on;
in
{
  imports = [ inputs.nixos-hardware.nixosModules.common-gpu-intel ];

  hardware.graphics = on;
}
