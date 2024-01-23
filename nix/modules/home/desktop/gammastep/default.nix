{ lib
, config
, ...
}:
let
  cfg = config.liberion.desktop.gammastep;
in
{
  options.liberion.desktop.gammastep = with lib; {
    enable = mkEnableOption "gammastep";

    latitude = with types; mkOption {
      type = (nullOr float);
      default = (-2.0);
    };

    longitude = with types; mkOption {
      type = (nullOr float);
      default = (-81.0);
    };

    tray = mkEnableOption "use system tray?";
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
