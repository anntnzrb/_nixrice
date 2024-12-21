{ inputs, ... }:
{
  imports = [ inputs.nixos-hardware.nixosModules.common-gpu-intel ];

  hardware.graphics.enable = true;

}
