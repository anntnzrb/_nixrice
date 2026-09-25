{ lib, config, ... }:
let
  inherit (lib.liberion.module) mkOpt' mkOptDisabled';
  inherit (lib.types) nullOr float;

  cfg = config.liberion.desktop.gammastep;
in
{
  options.liberion.desktop.gammastep = {
    latitude = mkOpt' (nullOr float) (-2.0);
    longitude = mkOpt' (nullOr float) (-81.0);
    tray = mkOptDisabled';
  };

  config = {
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
