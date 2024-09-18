{ ...
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
    };
  };
}

