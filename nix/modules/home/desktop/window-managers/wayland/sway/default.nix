{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.wayland.sway;
in
{
  options.liberion.desktop.window-managers.wayland.sway = {
    enable = lib.mkEnableOption "sway";
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;
      xwayland = true; # mandatory
    };
  };
}
