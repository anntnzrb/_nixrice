{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.liberion.common.xorg;
in
{
  options.liberion.common.xorg = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      autorun = false;
      excludePackages = with pkgs; [
        xorg.iceauth
        xorg.setxkbmap
        xorg.xset
        xorg.xsetroot
        xorg.xprop
        xterm
      ];

      displayManager.startx.enable = true;
    };
  };
}
