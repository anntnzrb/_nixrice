import ../../../toggle.nix "common.xorg" (
  { lib, pkgs, ... }:
  let
    inherit (lib.liberion.module) on;
  in
  {
    services.xserver = {
      enable = true;
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
  }
)
