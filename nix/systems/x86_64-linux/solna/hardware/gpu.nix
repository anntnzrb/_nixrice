{
  inputs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  imports = [ inputs.nixos-hardware.nixosModules.common-gpu-intel ];

  hardware.graphics = on;
}
