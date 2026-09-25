{ lib, ... }:
let
  inherit (lib.liberion.module) on;
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
