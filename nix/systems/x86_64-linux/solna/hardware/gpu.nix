{ inputs
, ...
}: {
  imports = [ inputs.nixos-hardware.nixosModules.common-gpu-intel ];

  hardware.opengl = {
    enable = true;
  };
}
