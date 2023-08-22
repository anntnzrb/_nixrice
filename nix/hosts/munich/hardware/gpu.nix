{ pkgs, ... }:
{
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    nvidia = {
      package = pkgs.linuxKernel.packages.linux_zen.nvidia_x11;
      open = false;
      modesetting.enable = true;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
