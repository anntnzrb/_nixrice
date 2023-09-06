{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.liberion) mkOptBool';

  cfg = config.liberion.desktop.xserver;
in {
  options.liberion.desktop.xserver = {
    enable = mkOptBool' false;
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      autorun = false;
      displayManager.startx.enable = true;
      excludePackages = [pkgs.xterm];

      libinput = {
        enable = true;
        mouse = {
          accelProfile = "flat";
          accelSpeed = null;
        };
      };
    };

    environment.systemPackages = [pkgs.xclip];
  };
}
