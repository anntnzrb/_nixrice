{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime];

  hardware = {
    opengl = {
      enable = true;

      # accelerated OpenGL rendering (Direct Rendering Interface) [DRI]
      driSupport = true;
      driSupport32Bit = true;
    };

    nvidia = {
      # ensure pkg follows corresponding kernel
      package = pkgs.linuxKernel.packages.linux_zen.nvidia_x11;

      # do not use nouveau, use non-free driver
      open = false;
    };
  };
}
