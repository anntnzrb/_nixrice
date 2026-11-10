{ config, lib, ... }:
let
  waybar = lib.getExe config.programs.waybar.package;
in
{
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "hyprland/window" ];
      modules-right = [
        "tray"
        "clock"
      ];
      "clock" = {
        format = "{:%H:%M}  ";
        format-alt = "{:%A; %B %d, %Y (%R)}  ";
        actions.on-click-right = "mode";
      };
      "hyprland/workspaces" = {
        active-only = false;
        all-outputs = true;
      };
    };
  };

  wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [ waybar ];
}
