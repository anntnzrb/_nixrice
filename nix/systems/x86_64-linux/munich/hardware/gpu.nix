{ pkgs
, ...
}:
{
  hardware.opengl = {
    enable = true;
  };

  # driver for both Xorg and Wayland
  #services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;

    # NOTE: match the kernel
    package = pkgs.linuxPackages_xanmod_latest.nvidia_x11;

    modesetting.enable = true;
  };
}
