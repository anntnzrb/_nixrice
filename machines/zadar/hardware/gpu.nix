{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;

    nvidia = {
      open = false;
      nvidiaSettings = false;
      modesetting.enable = true;
    };
  };
}
