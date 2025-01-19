{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.gammastep;
in
{
  options.${namespace}.desktop.gammastep =
    with lib.${namespace};
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
