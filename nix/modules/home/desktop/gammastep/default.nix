{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.module)
    mkOpt'
    mkOptBool'
    ;
  inherit (lib.types)
    nullOr
    float
    ;

  cfg = config.${namespace}.desktop.gammastep;
in
{
  options.${namespace}.desktop.gammastep = {
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
