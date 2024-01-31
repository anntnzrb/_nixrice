{ config
, lib
, ...
}:
let
  cfg = config.liberion.desktop.window-managers.xorg;
in
{
  options.liberion.desktop.window-managers.xorg = with lib.liberion; with lib.types; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    xsession = {
      enable = true;
      windowManager.command = lib.mkForce "";
    };
  };
}
