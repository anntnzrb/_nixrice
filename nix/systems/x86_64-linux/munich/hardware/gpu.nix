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

      # this enables having an external nvidia-card-connected display on the
      # nvidia card; also enables the mobo-connected display
      prime = {
        sync.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };
}
