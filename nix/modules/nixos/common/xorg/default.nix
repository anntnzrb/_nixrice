{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptBool';

  cfg = config.${namespace}.common.xorg;
in
{
  options.${namespace}.common.xorg = {
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
