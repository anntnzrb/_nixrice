{ config
, lib
, ...
}:
let
  cfg = config.liberion.common.xorg;
in
{
  options.liberion.common.xorg = with lib.liberion; with lib.types; {
    enable = mkOptBool';
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      autorun = false;
      displayManager.startx.enable = true;
    };
  };
}
