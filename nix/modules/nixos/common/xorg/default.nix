{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module) mkOptDisabled' on;

  cfg = config.${namespace}.common.xorg;
in
{
  options.${namespace}.common.xorg = {
    enable = mkOptDisabled';
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      inherit (cfg) enable;
      autorun = false;
      excludePackages = with pkgs; [
        xorg.iceauth
        xorg.setxkbmap
        xorg.xset
        xorg.xsetroot
        xorg.xprop
        xterm
      ];

      displayManager.startx = on;
    };
  };
}
