{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.wayland.river;
in
{
  options.liberion.desktop.window-managers.wayland.river = with lib.liberion; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.river ];
  };
}
