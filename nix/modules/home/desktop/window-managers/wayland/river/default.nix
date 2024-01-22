{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.wayland.river;
in
{
  options.liberion.desktop.window-managers.wayland.river = {
    enable = lib.mkEnableOption "river";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.river ];
  };
}
