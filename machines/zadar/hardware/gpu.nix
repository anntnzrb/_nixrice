{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;

    nvidia = {
      open = false;
      nvidiaSettings = false; # GUI tool; no desktop here
      modesetting.enable = true;
    };
  };
}
