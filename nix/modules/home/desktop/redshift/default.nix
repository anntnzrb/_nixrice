{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.liberion) mkOpt' mkOptBool';

  cfg = config.liberion.desktop.redshift;
in {
  options.liberion.desktop.redshift = with lib.types; {
    enable = mkOptBool' false;

    latitude = mkOpt' (nullOr float) (-2.0);
    longitude = mkOpt' (nullOr float) (-81.0);

    tray = mkOptBool' true;
  };

  config = lib.mkIf cfg.enable {
    services.redshift = {
      enable = true;
      latitude = cfg.latitude;
      longitude = cfg.longitude;
      provider = "manual";
      tray = cfg.tray;
      temperature = {
        day = 5700;
        night = 3500;
      };
    };
  };
}
