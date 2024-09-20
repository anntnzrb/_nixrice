{ lib, config, ... }:
let
  cfg = config.liberion.desktop.gammastep;
in
{
  options.liberion.desktop.gammastep =
    with lib.liberion;
    with lib.types;
    {
      enable = mkOptBool';

      latitude = mkOpt' (nullOr float) (-2.0);
      longitude = mkOpt' (nullOr float) (-81.0);
      tray = mkOptBool';
    };

  config = lib.mkIf cfg.enable {
    services.gammastep = {
      enable = true;

      inherit (cfg) latitude longitude tray;

      provider = "manual";
      temperature = {
        day = 5700;
        night = 3500;
      };
    };
  };
}
