_: {
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;

    nvidia = {
      open = false;
      nvidiaSettings = true;
      modesetting.enable = true;
    };
  };
}
