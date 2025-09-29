{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) on;
in
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics = on;

    nvidia = {
      open = false;
      nvidiaSettings = true;
      modesetting = on;

      # this enables having an external nvidia-card-connected display on the
      # nvidia card; also enables the mobo-connected display
      prime = {
        sync = on;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };
}
