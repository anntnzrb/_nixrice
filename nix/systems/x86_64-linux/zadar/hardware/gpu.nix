_: {
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    opengl.enable = true;

    nvidia = {
      open = false;
      nvidiaSettings = true;
      modesetting.enable = true;
    };
  };
}
