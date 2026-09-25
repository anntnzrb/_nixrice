{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;

    nvidia = {
      open = false;
      nvidiaSettings = false; # GUI tool; zadar is headless
      modesetting.enable = true;
    };
  };
}
