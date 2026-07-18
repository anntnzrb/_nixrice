{ lib, namespace, ... }:
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
    };
  };
}
