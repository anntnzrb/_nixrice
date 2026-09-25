{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.liberion.module) mkOptDisabled' on;

  cfg = config.liberion.common.xorg;
in
{
  options.liberion.common.xorg = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      inherit (cfg) enable;
      autorun = false;
      excludePackages = with pkgs; [
        iceauth
        setxkbmap
        xset
        xsetroot
        xprop
        xterm
      ];

      displayManager.startx = on;
    };
  };
}
