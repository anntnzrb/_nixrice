{ pkgs
, ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    nvidia = {
      open = false;
      nvidiaSettings = true;
      modesetting.enable = true;

      # NOTE: match the kernel
      package = pkgs.linuxPackages_xanmod_latest.nvidia_x11;
    };
  };
}

